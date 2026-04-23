"""
packager.py
~~~~~~~~~~~
Automated packaging & naming module for the LINE Sticker Processing System.

Responsibilities
----------------
- Accept a dict of spec-type → PIL Image mappings
- Name each file according to LINE's official upload requirements:
    main.png          (主要圖片)
    tab.png           (聊天室標籤圖片)
    sticker{N:02d}.png  (貼圖圖片, N = 01 … count)
- Bundle all files into a ZIP archive
- Enforce the 60 MB total ZIP size limit
- Optionally auto-compress individual files that exceed 1 MB

LINE naming convention reference:
  https://creator.line.me/en/guideline/animationsticker/
"""

from __future__ import annotations

import io
import logging
import zipfile
from dataclasses import dataclass, field
from typing import Dict, List, Optional

from PIL import Image

from image_processor import DPI, MAX_FILE_BYTES, image_to_png_bytes

logger = logging.getLogger(__name__)

MAX_ZIP_BYTES = 60 * 1024 * 1024   # 60 MB


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass
class PackageResult:
    zip_bytes: bytes
    zip_size_bytes: int
    file_manifest: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)

    def as_dict(self) -> dict:
        return {
            "zip_size_bytes": self.zip_size_bytes,
            "zip_size_kb": round(self.zip_size_bytes / 1024, 1),
            "file_manifest": self.file_manifest,
            "warnings": self.warnings,
        }


# ---------------------------------------------------------------------------
# Compression helper
# ---------------------------------------------------------------------------

def _compress_to_limit(image: Image.Image, max_bytes: int = MAX_FILE_BYTES) -> bytes:
    """
    在不低於 72 dpi 品質的前提下，嘗試將 PNG 壓縮至 max_bytes 以內。

    Strategy：PNG 是無損格式，因此我們採用逐步降低解析度（等比縮放）的方式
    來減少檔案大小，而非降低 DPI 設定（DPI 只是 metadata，不影響像素數量）。
    如果圖片已經小於限制則直接輸出。
    """
    raw = image_to_png_bytes(image)
    if len(raw) <= max_bytes:
        return raw

    logger.warning("圖片 %d bytes 超過限制，嘗試自動縮小…", len(raw))

    current = image.copy()
    for _ in range(8):   # 最多嘗試 8 次縮減
        w, h = current.size
        new_w = max(2, round(w * 0.9))
        new_h = max(2, round(h * 0.9))
        current = current.resize((new_w, new_h), Image.LANCZOS)
        raw = image_to_png_bytes(current)
        if len(raw) <= max_bytes:
            logger.info("縮小至 %dx%d 後檔案大小符合限制。", new_w, new_h)
            return raw

    logger.error("無法將圖片壓縮至 %d bytes 限制以內。", max_bytes)
    return raw   # 回傳最後一次嘗試的結果（可能仍超過限制）


# ---------------------------------------------------------------------------
# Naming helpers
# ---------------------------------------------------------------------------

def _sticker_filename(index: int) -> str:
    """回傳符合 LINE 命名規範的貼圖檔名，例如 sticker01.png。"""
    return f"sticker{index:02d}.png"


# ---------------------------------------------------------------------------
# Main packaging function
# ---------------------------------------------------------------------------

def build_package(
    main_image: Optional[Image.Image],
    sticker_images: List[Image.Image],
    tab_image: Optional[Image.Image],
    compress: bool = True,
) -> PackageResult:
    """
    將處理好的圖片打包成符合 LINE 規格的 ZIP 檔。

    Parameters
    ----------
    main_image      : 主要圖片 (240×240)
    sticker_images  : 貼圖圖片列表（8/16/24/32/40 張）
    tab_image       : 聊天室標籤圖片 (96×74)
    compress        : 是否自動壓縮超過 1 MB 的圖片

    Returns
    -------
    PackageResult 含 ZIP bytes 及統計資訊
    """
    warnings: list[str] = []
    manifest: list[str] = []

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:

        # ── main.png ────────────────────────────────────────────────────────
        if main_image is not None:
            data = _compress_to_limit(main_image) if compress else image_to_png_bytes(main_image)
            zf.writestr("main.png", data)
            manifest.append("main.png")
        else:
            warnings.append("未提供主要圖片 (main image)，ZIP 中不含 main.png。")

        # ── sticker{N:02d}.png ──────────────────────────────────────────────
        count = len(sticker_images)
        if count not in {8, 16, 24, 32, 40}:
            warnings.append(
                f"貼圖數量為 {count} 張，不符合 LINE 要求的 8/16/24/32/40 張。"
                "仍會打包現有圖片，但上傳時可能被退件。"
            )
        for idx, sticker in enumerate(sticker_images, start=1):
            fname = _sticker_filename(idx)
            data = _compress_to_limit(sticker) if compress else image_to_png_bytes(sticker)
            zf.writestr(fname, data)
            manifest.append(fname)

        # ── tab.png ─────────────────────────────────────────────────────────
        if tab_image is not None:
            data = _compress_to_limit(tab_image) if compress else image_to_png_bytes(tab_image)
            zf.writestr("tab.png", data)
            manifest.append("tab.png")
        else:
            warnings.append("未提供標籤圖片 (tab image)，ZIP 中不含 tab.png。")

    zip_bytes = buf.getvalue()
    zip_size = len(zip_bytes)

    if zip_size > MAX_ZIP_BYTES:
        warnings.append(
            f"ZIP 檔案大小 {zip_size / 1024 / 1024:.1f} MB 超過 LINE 限制 60 MB。"
            "請減少貼圖數量或簡化圖案複雜度。"
        )

    return PackageResult(
        zip_bytes=zip_bytes,
        zip_size_bytes=zip_size,
        file_manifest=manifest,
        warnings=warnings,
    )
