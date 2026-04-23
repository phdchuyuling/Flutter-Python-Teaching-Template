"""
image_processor.py
~~~~~~~~~~~~~~~~~~
Core image processing module for the LINE Sticker Processing System.

Handles:
- Dimension normalization (ensure_even_dimension)
- Resizing to LINE-spec dimensions
- Smart padding & centering using bounding-box detection
- File-size quality gate
"""

from __future__ import annotations

import io
from dataclasses import dataclass
from typing import Tuple

import cv2
import numpy as np
from PIL import Image

# ---------------------------------------------------------------------------
# LINE official sticker specifications
# ---------------------------------------------------------------------------

LINE_SPECS = {
    "main": {"width": 240, "height": 240},       # 主要圖片
    "sticker": {"width": 370, "height": 320},     # 貼圖圖片（最大）
    "tab": {"width": 96, "height": 74},           # 聊天室標籤圖片
}

STICKER_COUNTS = {8, 16, 24, 32, 40}   # 合法貼圖張數
DPI = 72                                 # 最低解析度
MAX_FILE_BYTES = 1 * 1024 * 1024        # 每張圖片最大 1 MB
PADDING_PX = 10                         # 最小留白 (px)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

@dataclass
class ProcessingResult:
    image: Image.Image
    file_size_bytes: int
    warnings: list[str]


def ensure_even_dimension(value: int) -> int:
    """
    偶數限制：LINE 要求貼圖寬高必須是偶數，否則縮小時會出現邊緣問題。
    若傳入奇數則無條件捨去，確保為偶數。
    """
    return value if value % 2 == 0 else value - 1


def _to_rgba(image: Image.Image) -> Image.Image:
    """統一轉成 RGBA，確保透明通道存在。"""
    if image.mode != "RGBA":
        return image.convert("RGBA")
    return image


def _detect_content_bbox(rgba: Image.Image) -> Tuple[int, int, int, int] | None:
    """
    使用 OpenCV 偵測圖片中「非透明像素」的最小包圍矩形 (Bounding Box)。

    Returns
    -------
    (left, top, right, bottom) 或 None（若圖片完全透明）
    """
    arr = np.array(rgba)
    alpha = arr[:, :, 3]

    # 找出非透明像素的行列
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)

    if not rows.any():
        return None

    top, bottom = int(np.argmax(rows)), int(len(rows) - 1 - np.argmax(rows[::-1]))
    left, right = int(np.argmax(cols)), int(len(cols) - 1 - np.argmax(cols[::-1]))
    return left, top, right, bottom


def _center_of_mass(rgba: Image.Image) -> Tuple[float, float]:
    """
    計算圖片「非透明像素」的重心座標（用於位置平衡對齊）。
    """
    arr = np.array(rgba)
    alpha = arr[:, :, 3].astype(np.float32)
    total = alpha.sum()
    if total == 0:
        h, w = arr.shape[:2]
        return w / 2, h / 2
    ys, xs = np.mgrid[0:alpha.shape[0], 0:alpha.shape[1]]
    cx = float((xs * alpha).sum() / total)
    cy = float((ys * alpha).sum() / total)
    return cx, cy


# ---------------------------------------------------------------------------
# Main processing pipeline
# ---------------------------------------------------------------------------

def process_image(
    image: Image.Image,
    spec_type: str = "sticker",
    padding: int = PADDING_PX,
) -> ProcessingResult:
    """
    將任意輸入圖片處理成符合 LINE 規格的圖片。

    Steps
    -----
    1. 轉 RGBA（保留透明背景）
    2. 偵測內容邊界（Bounding Box）
    3. 裁切出內容區域並縮放至目標尺寸（保留 padding 緩衝）
    4. 重心對齊置中於空白畫布
    5. 最終輸出為 PNG，並檢查檔案大小
    """
    warnings: list[str] = []

    if spec_type not in LINE_SPECS:
        raise ValueError(f"未知規格類型 '{spec_type}'，請使用 {list(LINE_SPECS)}")

    spec = LINE_SPECS[spec_type]
    target_w = ensure_even_dimension(spec["width"])
    target_h = ensure_even_dimension(spec["height"])

    rgba = _to_rgba(image)

    # Step 2: 偵測內容邊界
    bbox = _detect_content_bbox(rgba)
    if bbox is None:
        warnings.append("圖片中未偵測到非透明內容，將輸出空白畫布。")
        canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
        return _finalize(canvas, warnings)

    left, top, right, bottom = bbox
    content = rgba.crop((left, top, right + 1, bottom + 1))

    # Step 3: 計算縮放比例（保留 padding）
    avail_w = target_w - 2 * padding
    avail_h = target_h - 2 * padding
    avail_w = max(avail_w, 1)
    avail_h = max(avail_h, 1)

    content_w, content_h = content.size
    scale = min(avail_w / content_w, avail_h / content_h, 1.0)

    new_w = ensure_even_dimension(max(2, round(content_w * scale)))
    new_h = ensure_even_dimension(max(2, round(content_h * scale)))

    scaled = content.resize((new_w, new_h), Image.LANCZOS)

    # Step 4: 重心對齊 — 計算置中偏移
    # 理想位置：將縮放後圖片的重心對齊畫布中心
    cx_content, cy_content = _center_of_mass(scaled)
    canvas_cx = target_w / 2
    canvas_cy = target_h / 2

    paste_x = round(canvas_cx - cx_content)
    paste_y = round(canvas_cy - cy_content)

    # 確保圖案不超出畫布邊界
    paste_x = max(padding, min(paste_x, target_w - new_w - padding))
    paste_y = max(padding, min(paste_y, target_h - new_h - padding))

    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    canvas.paste(scaled, (paste_x, paste_y), scaled)

    return _finalize(canvas, warnings)


def _finalize(canvas: Image.Image, warnings: list[str]) -> ProcessingResult:
    """將畫布轉存為 PNG bytes 並檢查檔案大小限制。"""
    buf = io.BytesIO()
    # 輸出時保留 RGBA（透明背景），設定 72 dpi
    canvas.save(buf, format="PNG", dpi=(DPI, DPI))
    size = buf.tell()

    if size > MAX_FILE_BYTES:
        warnings.append(
            f"檔案大小 {size / 1024:.1f} KB 超過 LINE 限制 (1 MB)，"
            "請考慮使用更簡單的圖案或降低顏色複雜度。"
        )

    return ProcessingResult(image=canvas, file_size_bytes=size, warnings=warnings)


def image_to_png_bytes(image: Image.Image) -> bytes:
    """將 PIL Image 轉為 PNG bytes（含透明背景）。"""
    buf = io.BytesIO()
    image.save(buf, format="PNG", dpi=(DPI, DPI))
    return buf.getvalue()
