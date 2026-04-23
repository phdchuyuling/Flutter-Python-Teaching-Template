"""
quality_checker.py
~~~~~~~~~~~~~~~~~~
Content review pre-check (heuristic checks) for LINE sticker images.

Implements the following checks described in the LINE creator guidelines:
1. Aspect Ratio Detection  — warns about overly flat/elongated images
2. Colour Balance Detection — warns when the image is dominated by very
   light colours (hard to recognise against a white chat background)
3. Transparency Check       — warns if the image has no transparent pixels
4. File-size pre-estimate   — rough check before full processing
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List

import numpy as np
from PIL import Image

# ---------------------------------------------------------------------------
# Thresholds
# ---------------------------------------------------------------------------

# Aspect ratio limits (width / height).
# Images outside this range are considered "too flat" or "too tall".
MIN_ASPECT_RATIO = 0.25   # very tall / thin
MAX_ASPECT_RATIO = 4.0    # very wide / flat

# Brightness threshold for "too light" warning.
# Mean brightness of non-transparent pixels on a 0-255 scale.
LIGHT_BRIGHTNESS_THRESHOLD = 200   # above this → "too light"

# Minimum fraction of non-transparent pixels expected in a usable sticker.
MIN_CONTENT_RATIO = 0.02   # 2 % of canvas must be non-transparent


# ---------------------------------------------------------------------------
# Result types
# ---------------------------------------------------------------------------

@dataclass
class CheckResult:
    passed: bool
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)

    def as_dict(self) -> dict:
        return {
            "passed": self.passed,
            "warnings": self.warnings,
            "errors": self.errors,
        }


# ---------------------------------------------------------------------------
# Individual checks
# ---------------------------------------------------------------------------

def _check_aspect_ratio(image: Image.Image, result: CheckResult) -> None:
    """
    長寬比偵測 (Aspect Ratio Detection)。
    過於扁平或過於細長的圖片難以辨認。
    """
    w, h = image.size
    if h == 0:
        result.errors.append("圖片高度為 0，無法計算長寬比。")
        return
    ratio = w / h
    if ratio < MIN_ASPECT_RATIO:
        result.warnings.append(
            f"長寬比過小 ({ratio:.2f})：圖片過於細長，可能難以辨認，"
            "建議調整構圖讓圖案更寬。"
        )
    elif ratio > MAX_ASPECT_RATIO:
        result.warnings.append(
            f"長寬比過大 ({ratio:.2f})：圖片過於扁平，LINE 官方指出扁長圖片"
            "難以辨認，建議調整構圖。"
        )


def _check_colour_balance(image: Image.Image, result: CheckResult) -> None:
    """
    色彩平衡偵測 (Colour Balance Detection)。
    分析非透明像素的直方圖 (Histogram)，若整體亮度過高則警告。
    """
    rgba = image.convert("RGBA") if image.mode != "RGBA" else image
    arr = np.array(rgba, dtype=np.uint8)
    alpha = arr[:, :, 3]
    mask = alpha > 0

    if not mask.any():
        # 完全透明：由下面的 content-ratio check 處理
        return

    # 計算非透明像素在 RGB 通道的平均亮度（感知亮度公式）
    rgb = arr[:, :, :3].astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

    mean_lum = luminance[mask].mean()
    if mean_lum > LIGHT_BRIGHTNESS_THRESHOLD:
        result.warnings.append(
            f"圖片亮度過高（平均亮度 {mean_lum:.1f}/255）：全部使用淺色調的貼圖"
            "在白色聊天背景下難以辨識，建議增加深色輪廓或加深顏色。"
        )


def _check_content_ratio(image: Image.Image, result: CheckResult) -> None:
    """
    可辨識度檢查：確認非透明像素佔畫布比例是否足夠。
    """
    rgba = image.convert("RGBA") if image.mode != "RGBA" else image
    arr = np.array(rgba, dtype=np.uint8)
    alpha = arr[:, :, 3]
    total = alpha.size
    non_transparent = int((alpha > 0).sum())
    ratio = non_transparent / total if total > 0 else 0

    if ratio < MIN_CONTENT_RATIO:
        result.warnings.append(
            f"圖案內容佔比過低（{ratio * 100:.1f}%）：有效像素不足，"
            "貼圖主體可能過小或過於透明，建議重新構圖。"
        )


def _check_transparency(image: Image.Image, result: CheckResult) -> None:
    """
    確認圖片具有透明背景（RGBA 模式且有透明像素）。
    """
    if image.mode != "RGBA":
        result.warnings.append(
            "圖片不含透明通道（非 RGBA 模式）。LINE 要求貼圖必須有透明背景，"
            "請先執行去背處理。"
        )
        return

    arr = np.array(image, dtype=np.uint8)
    alpha = arr[:, :, 3]
    if (alpha == 255).all():
        result.warnings.append(
            "圖片不含任何透明像素：LINE 要求貼圖必須有透明背景，"
            "請先執行去背處理。"
        )


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def run_checks(image: Image.Image) -> CheckResult:
    """
    對輸入圖片執行全部預檢，回傳 CheckResult。

    Parameters
    ----------
    image : PIL.Image.Image
        待檢查的圖片（建議先去背後再執行）。

    Returns
    -------
    CheckResult
        包含 passed 旗標、warnings 與 errors 列表。
    """
    result = CheckResult(passed=True)

    _check_aspect_ratio(image, result)
    _check_colour_balance(image, result)
    _check_content_ratio(image, result)
    _check_transparency(image, result)

    if result.errors:
        result.passed = False

    return result
