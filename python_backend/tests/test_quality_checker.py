"""
tests/test_quality_checker.py
Tests for the quality pre-check module.
"""

import sys
import os

import pytest
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from quality_checker import run_checks, CheckResult


def _make(w, h, mode="RGBA", alpha=255, rgb=(200, 200, 200)):
    """Create a simple solid-colour image for testing."""
    img = Image.new(mode, (w, h), rgb + (alpha,) if mode == "RGBA" else rgb)
    return img


class TestAspectRatioCheck:
    def test_normal_ratio_no_warning(self):
        img = _make(200, 200)
        result = run_checks(img)
        ratio_warnings = [w for w in result.warnings if "長寬比" in w]
        assert ratio_warnings == []

    def test_too_flat_warns(self):
        # width >> height → ratio > MAX_ASPECT_RATIO (4.0)
        img = _make(1000, 100)
        result = run_checks(img)
        assert any("過大" in w or "扁平" in w for w in result.warnings)

    def test_too_tall_warns(self):
        # height >> width → ratio < MIN_ASPECT_RATIO (0.25)
        img = _make(50, 500)
        result = run_checks(img)
        assert any("過小" in w or "細長" in w for w in result.warnings)


class TestColourBalanceCheck:
    def test_dark_image_no_colour_warning(self):
        img = _make(100, 100, rgb=(30, 30, 30), alpha=255)
        result = run_checks(img)
        colour_warnings = [w for w in result.warnings if "亮度" in w]
        assert colour_warnings == []

    def test_very_light_image_warns(self):
        # Near-white image → mean luminance > 200
        img = _make(100, 100, rgb=(250, 250, 250), alpha=255)
        result = run_checks(img)
        assert any("亮度" in w for w in result.warnings)


class TestTransparencyCheck:
    def test_non_rgba_warns(self):
        img = Image.new("RGB", (100, 100), (255, 0, 0))
        result = run_checks(img)
        assert any("透明通道" in w for w in result.warnings)

    def test_fully_opaque_rgba_warns(self):
        img = _make(100, 100, alpha=255, rgb=(255, 0, 0))
        result = run_checks(img)
        assert any("透明像素" in w for w in result.warnings)

    def test_image_with_transparency_passes_check(self):
        img = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        # Add some opaque content
        for x in range(10, 50):
            for y in range(10, 50):
                img.putpixel((x, y), (255, 0, 0, 255))
        result = run_checks(img)
        transparency_warnings = [
            w for w in result.warnings if "透明" in w
        ]
        assert transparency_warnings == []


class TestContentRatioCheck:
    def test_nearly_empty_image_warns(self):
        # Almost fully transparent → content ratio < 2%
        img = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        img.putpixel((50, 50), (255, 0, 0, 255))   # only 1 pixel
        result = run_checks(img)
        assert any("佔比" in w for w in result.warnings)

    def test_normal_content_no_warning(self):
        img = _make(100, 100, alpha=255, rgb=(255, 0, 0))
        # Set half the image transparent so it still has lots of content
        import numpy as np
        arr = np.array(img)
        arr[:50, :, 3] = 0
        img = Image.fromarray(arr)
        result = run_checks(img)
        ratio_warnings = [w for w in result.warnings if "佔比" in w]
        assert ratio_warnings == []


class TestCheckResultIntegration:
    def test_as_dict_structure(self):
        result = CheckResult(
            passed=True,
            warnings=["test warning"],
            errors=[],
        )
        d = result.as_dict()
        assert "passed" in d
        assert "warnings" in d
        assert "errors" in d
        assert d["passed"] is True
        assert d["warnings"] == ["test warning"]
