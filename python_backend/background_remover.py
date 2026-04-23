"""
background_remover.py
~~~~~~~~~~~~~~~~~~~~~
AI-powered background removal using rembg (U2-Net deep learning model).

Provides one-click automatic background removal that converts any image
into a transparent-background PNG, fulfilling LINE's de-background requirement.
"""

from __future__ import annotations

import io
import logging

from PIL import Image

logger = logging.getLogger(__name__)

# rembg is an optional heavy dependency (requires ONNX Runtime).
# We import lazily so the rest of the system still works even if rembg
# is not installed.
try:
    from rembg import remove as _rembg_remove
    from rembg import new_session as _new_session

    _REMBG_AVAILABLE = True
    # Initialise the default U2-Net session once at module load to avoid
    # re-loading the model on every request.
    _SESSION = _new_session("u2net")
    logger.info("rembg 初始化成功，使用 u2net 模型。")
except Exception as exc:  # pragma: no cover
    _REMBG_AVAILABLE = False
    _SESSION = None
    logger.warning("rembg 無法載入 (%s)，自動去背功能將停用。", exc)


def is_available() -> bool:
    """回傳 rembg 是否可用。"""
    return _REMBG_AVAILABLE


def remove_background(image: Image.Image) -> Image.Image:
    """
    使用 U2-Net 模型一鍵自動去除圖片背景。

    Parameters
    ----------
    image : PIL.Image.Image
        任意色彩模式的輸入圖片。

    Returns
    -------
    PIL.Image.Image
        RGBA 模式、背景透明的去背圖片。

    Raises
    ------
    RuntimeError
        當 rembg 未安裝或初始化失敗時拋出。
    """
    if not _REMBG_AVAILABLE or _SESSION is None:
        raise RuntimeError(
            "rembg 未安裝或初始化失敗。請執行 `pip install rembg` 後重試。"
        )

    # 轉換為 bytes 供 rembg 處理
    buf_in = io.BytesIO()
    image.save(buf_in, format="PNG")
    input_bytes = buf_in.getvalue()

    output_bytes = _rembg_remove(input_bytes, session=_SESSION)

    result = Image.open(io.BytesIO(output_bytes)).convert("RGBA")
    return result
