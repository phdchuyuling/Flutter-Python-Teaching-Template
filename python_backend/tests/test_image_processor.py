"""
tests/test_image_processor.py
Tests for the core image processing module.
"""

import io
import sys
import os

import pytest
from PIL import Image

# Allow importing from parent directory
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from image_processor import (
    ensure_even_dimension,
    process_image,
    _detect_content_bbox,
    _center_of_mass,
    LINE_SPECS,
    PADDING_PX,
)


# ── ensure_even_dimension ────────────────────────────────────────────────────

class TestEnsureEvenDimension:
    def test_even_input_unchanged(self):
        assert ensure_even_dimension(240) == 240
        assert ensure_even_dimension(370) == 370
        assert ensure_even_dimension(96) == 96

    def test_odd_input_rounded_down(self):
        assert ensure_even_dimension(241) == 240
        assert ensure_even_dimension(1) == 0
        assert ensure_even_dimension(99) == 98

    def test_zero(self):
        assert ensure_even_dimension(0) == 0


# ── _detect_content_bbox ────────────────────────────────────────────────────

class TestDetectContentBbox:
    def _make_rgba(self, w, h, has_content=True):
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        if has_content:
            # Draw a 10x10 opaque square in the centre
            cx, cy = w // 2, h // 2
            for x in range(cx - 5, cx + 5):
                for y in range(cy - 5, cy + 5):
                    img.putpixel((x, y), (255, 0, 0, 255))
        return img

    def test_fully_transparent_returns_none(self):
        img = self._make_rgba(100, 100, has_content=False)
        assert _detect_content_bbox(img) is None

    def test_returns_bounding_box(self):
        img = self._make_rgba(100, 100, has_content=True)
        bbox = _detect_content_bbox(img)
        assert bbox is not None
        left, top, right, bottom = bbox
        # The 10x10 square centred at (50,50) → roughly (45,45,54,54)
        assert left < 55 and right > 44
        assert top < 55 and bottom > 44


# ── process_image ────────────────────────────────────────────────────────────

class TestProcessImage:
    def _make_image(self, w=200, h=200, with_content=True):
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        if with_content:
            # solid red square, slightly off-centre
            for x in range(30, 80):
                for y in range(20, 70):
                    img.putpixel((x, y), (255, 0, 0, 255))
        return img

    @pytest.mark.parametrize("spec_type", ["main", "sticker", "tab"])
    def test_output_size_matches_spec(self, spec_type):
        img = self._make_image()
        result = process_image(img, spec_type=spec_type)
        expected_w = ensure_even_dimension(LINE_SPECS[spec_type]["width"])
        expected_h = ensure_even_dimension(LINE_SPECS[spec_type]["height"])
        assert result.image.size == (expected_w, expected_h)

    def test_output_mode_is_rgba(self):
        img = self._make_image()
        result = process_image(img, spec_type="sticker")
        assert result.image.mode == "RGBA"

    def test_unknown_spec_raises(self):
        img = self._make_image()
        with pytest.raises(ValueError, match="未知規格類型"):
            process_image(img, spec_type="unknown")

    def test_empty_image_warns(self):
        img = self._make_image(with_content=False)
        result = process_image(img, spec_type="sticker")
        assert any("未偵測到非透明內容" in w for w in result.warnings)

    def test_padding_respected(self):
        """Content should not touch the canvas edge."""
        img = self._make_image()
        padding = 15
        result = process_image(img, spec_type="sticker", padding=padding)
        out = result.image

        # Check that the outermost `padding` pixels are fully transparent
        import numpy as np
        arr = __import__("numpy").array(out)
        alpha = arr[:, :, 3]

        # Top/bottom/left/right margins should be transparent
        assert alpha[:padding, :].max() == 0, "Top margin has opaque pixels"
        assert alpha[-padding:, :].max() == 0, "Bottom margin has opaque pixels"
        assert alpha[:, :padding].max() == 0, "Left margin has opaque pixels"
        assert alpha[:, -padding:].max() == 0, "Right margin has opaque pixels"


# ── _center_of_mass ──────────────────────────────────────────────────────────

class TestCenterOfMass:
    def test_uniform_image(self):
        img = Image.new("RGBA", (100, 100), (255, 0, 0, 255))
        cx, cy = _center_of_mass(img)
        assert abs(cx - 49.5) < 1
        assert abs(cy - 49.5) < 1

    def test_fully_transparent_returns_centre(self):
        img = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        cx, cy = _center_of_mass(img)
        assert cx == 50.0
        assert cy == 50.0
