"""
tests/test_packager.py
Tests for the packaging module.
"""

import io
import sys
import os
import zipfile

import pytest
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from packager import build_package, _sticker_filename, PackageResult


def _make_sticker(w=370, h=320) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # Draw content in the inner quarter of the image (safe for any size)
    x0, y0 = w // 4, h // 4
    x1, y1 = max(x0 + 1, 3 * w // 4), max(y0 + 1, 3 * h // 4)
    for x in range(x0, x1):
        for y in range(y0, y1):
            img.putpixel((x, y), (0, 128, 255, 255))
    return img


class TestStickerFilename:
    def test_zero_padded(self):
        assert _sticker_filename(1) == "sticker01.png"
        assert _sticker_filename(9) == "sticker09.png"
        assert _sticker_filename(10) == "sticker10.png"
        assert _sticker_filename(40) == "sticker40.png"


class TestBuildPackage:
    def test_basic_package_contains_expected_files(self):
        main = _make_sticker(240, 240)
        tab = _make_sticker(96, 74)
        stickers = [_make_sticker() for _ in range(8)]

        result = build_package(main, stickers, tab)
        assert isinstance(result, PackageResult)
        assert len(result.zip_bytes) > 0

        # Verify ZIP contents
        with zipfile.ZipFile(io.BytesIO(result.zip_bytes)) as zf:
            names = zf.namelist()
        assert "main.png" in names
        assert "tab.png" in names
        for i in range(1, 9):
            assert _sticker_filename(i) in names

    def test_no_main_warns(self):
        stickers = [_make_sticker() for _ in range(8)]
        result = build_package(None, stickers, None)
        assert any("main image" in w or "主要圖片" in w for w in result.warnings)

    def test_no_tab_warns(self):
        stickers = [_make_sticker() for _ in range(8)]
        result = build_package(None, stickers, None)
        assert any("tab image" in w or "標籤圖片" in w for w in result.warnings)

    def test_wrong_sticker_count_warns(self):
        # 5 stickers: not in {8, 16, 24, 32, 40}
        stickers = [_make_sticker() for _ in range(5)]
        result = build_package(None, stickers, None)
        assert any("不符合" in w or "5" in w for w in result.warnings)

    def test_as_dict_structure(self):
        stickers = [_make_sticker() for _ in range(8)]
        result = build_package(None, stickers, None)
        d = result.as_dict()
        assert "zip_size_bytes" in d
        assert "file_manifest" in d
        assert "warnings" in d
        assert isinstance(d["file_manifest"], list)

    def test_no_compress_still_works(self):
        stickers = [_make_sticker() for _ in range(8)]
        result = build_package(None, stickers, None, compress=False)
        assert len(result.zip_bytes) > 0
