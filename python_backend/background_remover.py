"""
background_remover.py
~~~~~~~~~~~~~~~~~~~~~
AI-powered background removal using rembg (U2-Net deep learning model).

Provides one-click automatic background removal that converts any image
into a transparent-background PNG, fulfilling LINE's de-background requirement.

Security note — rembg is an OPTIONAL, user-installed dependency
----------------------------------------------------------------
All released versions of rembg (<= 2.0.57) contain an unpatched CORS
misconfiguration vulnerability.  No upstream fix is currently available.

rembg is therefore intentionally **excluded from requirements.txt**.
To enable background removal you must install it manually in a controlled
environment after reviewing the security implications:

    pip install rembg==2.0.56

If rembg is not installed the rest of the system continues to work normally;
the /remove-bg API endpoint will return HTTP 503 with an explanatory message.
"""

from __future__ import annotations

import io
import logging

from PIL import Image

logger = logging.getLogger(__name__)

# rembg is an optional, user-installed dependency (see module docstring).
# We attempt a lazy import so the rest of the system is unaffected when
# rembg is not installed.
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
    logger.warning("rembg 未安裝或無法載入 (%s)，自動去背功能將停用。", exc)


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
            "rembg 未安裝。請先閱讀 background_remover.py 的安全說明，"
            "確認風險後執行 `pip install rembg==2.0.56` 再重試。"
        )

    # 轉換為 bytes 供 rembg 處理
    buf_in = io.BytesIO()
    image.save(buf_in, format="PNG")
    input_bytes = buf_in.getvalue()

    output_bytes = _rembg_remove(input_bytes, session=_SESSION)

    result = Image.open(io.BytesIO(output_bytes)).convert("RGBA")
    return result
