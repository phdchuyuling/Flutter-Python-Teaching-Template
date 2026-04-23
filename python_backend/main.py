"""
main.py
~~~~~~~
FastAPI REST API server for the LINE Sticker Processing System.

Endpoints
---------
POST /process          – Process a single image (resize + pad + center)
POST /remove-bg        – Remove background from an image (rembg / U2-Net)
POST /check            – Run quality pre-checks on an image
POST /package          – Upload multiple images, get back a ready-to-upload ZIP

Run
---
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

from __future__ import annotations

import io
import logging
from typing import Annotated, List, Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from PIL import Image

import background_remover
import image_processor as ip
import packager
import quality_checker as qc

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="LINE 貼圖自動化處理系統",
    description=(
        "自動將使用者上傳的圖片轉換為符合 LINE 官方規格的貼圖，"
        "支援去背、尺寸調整、智慧留白、品質預檢與自動打包功能。"
    ),
    version="1.0.0",
)

# Allow Flutter / web frontend to communicate with the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _load_image(upload: UploadFile) -> Image.Image:
    try:
        data = upload.file.read()
        return Image.open(io.BytesIO(data))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"無法讀取圖片：{exc}") from exc


def _image_response(image: Image.Image, filename: str = "output.png") -> StreamingResponse:
    """將 PIL Image 轉成 PNG 並以 StreamingResponse 回傳。"""
    buf = io.BytesIO()
    image.save(buf, format="PNG", dpi=(ip.DPI, ip.DPI))
    buf.seek(0)
    return StreamingResponse(
        buf,
        media_type="image/png",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/", summary="API 健康檢查")
def root() -> dict:
    return {
        "message": "LINE 貼圖自動化處理系統運作中",
        "rembg_available": background_remover.is_available(),
        "docs": "/docs",
    }


@app.post(
    "/process",
    summary="圖片尺寸調整與智慧留白",
    response_description="符合 LINE 規格的 PNG 圖片",
)
async def process_image(
    file: Annotated[UploadFile, File(description="待處理的圖片（PNG/JPG/WebP…）")],
    spec_type: Annotated[
        str,
        Form(description="規格類型：main | sticker | tab"),
    ] = "sticker",
    padding: Annotated[int, Form(description="最小留白像素數（預設 10）")] = ip.PADDING_PX,
) -> StreamingResponse:
    """
    將上傳圖片調整至 LINE 指定規格，並套用智慧留白與重心置中演算法。
    """
    image = _load_image(file)
    try:
        result = ip.process_image(image, spec_type=spec_type, padding=padding)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc

    headers: dict = {}
    if result.warnings:
        headers["X-Warnings"] = " | ".join(result.warnings)

    buf = io.BytesIO()
    result.image.save(buf, format="PNG", dpi=(ip.DPI, ip.DPI))
    buf.seek(0)
    return StreamingResponse(
        buf,
        media_type="image/png",
        headers={
            "Content-Disposition": f'attachment; filename="processed_{spec_type}.png"',
            **headers,
        },
    )


@app.post(
    "/remove-bg",
    summary="AI 自動去背（U2-Net / rembg）",
    response_description="去除背景後的透明 PNG",
)
async def remove_background(
    file: Annotated[UploadFile, File(description="待去背的圖片")],
) -> StreamingResponse:
    """
    使用深度學習模型（U2-Net）自動去除圖片背景，輸出透明背景 PNG。
    """
    if not background_remover.is_available():
        raise HTTPException(
            status_code=503,
            detail="rembg 模型未安裝，請在後端執行 `pip install rembg` 後重啟服務。",
        )

    image = _load_image(file)
    try:
        result = background_remover.remove_background(image)
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    return _image_response(result, "removed_bg.png")


@app.post(
    "/check",
    summary="圖片品質預檢",
    response_description="預檢結果（JSON）",
)
async def check_image(
    file: Annotated[UploadFile, File(description="待預檢的圖片")],
) -> JSONResponse:
    """
    執行內容審核預檢，包含長寬比偵測、色彩平衡分析、透明度檢查。
    """
    image = _load_image(file)
    result = qc.run_checks(image)
    return JSONResponse(result.as_dict())


@app.post(
    "/package",
    summary="自動打包所有規格圖片為 ZIP",
    response_description="符合 LINE 上傳規格的 ZIP 檔",
)
async def build_package(
    main_file: Annotated[
        Optional[UploadFile],
        File(description="主要圖片（240×240）"),
    ] = None,
    sticker_files: Annotated[
        Optional[List[UploadFile]],
        File(description="貼圖圖片清單（8/16/24/32/40 張）"),
    ] = None,
    tab_file: Annotated[
        Optional[UploadFile],
        File(description="標籤圖片（96×74）"),
    ] = None,
    auto_process: Annotated[
        bool,
        Form(description="是否自動套用尺寸調整與留白處理（預設 True）"),
    ] = True,
    compress: Annotated[
        bool,
        Form(description="是否自動壓縮超過 1MB 的圖片（預設 True）"),
    ] = True,
) -> StreamingResponse:
    """
    接收主圖、貼圖列表、標籤圖，自動依 LINE 規格處理後打包成 ZIP 檔。
    """

    def _process_or_load(upload: UploadFile, spec: str) -> Image.Image:
        img = _load_image(upload)
        if auto_process:
            result = ip.process_image(img, spec_type=spec)
            return result.image
        return img.convert("RGBA")

    main_image: Optional[Image.Image] = None
    if main_file is not None:
        main_image = _process_or_load(main_file, "main")

    sticker_images: List[Image.Image] = []
    if sticker_files:
        for sf in sticker_files:
            sticker_images.append(_process_or_load(sf, "sticker"))

    tab_image: Optional[Image.Image] = None
    if tab_file is not None:
        tab_image = _process_or_load(tab_file, "tab")

    pkg = packager.build_package(
        main_image=main_image,
        sticker_images=sticker_images,
        tab_image=tab_image,
        compress=compress,
    )

    headers: dict = {}
    if pkg.warnings:
        headers["X-Warnings"] = " | ".join(pkg.warnings)
    headers["X-File-Count"] = str(len(pkg.file_manifest))
    headers["X-Zip-Size-KB"] = str(round(pkg.zip_size_bytes / 1024, 1))

    return StreamingResponse(
        io.BytesIO(pkg.zip_bytes),
        media_type="application/zip",
        headers={
            "Content-Disposition": 'attachment; filename="line_stickers.zip"',
            **headers,
        },
    )
