"""Cut the MED QR logo out of its white background and export app-ready PNGs.

Source is a flat logo photographed/rendered on white. Alpha is derived from how
far each pixel is from white, then the colour is un-premultiplied so edges stay
smooth on any background instead of keeping a white halo.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

SOURCE = Path(
    r"C:\Users\ACER\.cursor\projects\c-Users-ACER-med-Qr\assets"
    r"\c__Users_ACER_AppData_Roaming_Cursor_User_workspaceStorage_1b50eea8861b05a17da9ebdaba47469c"
    r"_images_image-5a01e0a1-564d-4ee8-9ea0-f763393dfed4.png"
)
ROOT = Path(r"c:\Users\ACER\med Qr")
CREAM = (255, 247, 240, 255)

# Pixels below FLOOR coverage are treated as paper, above SOLID as full ink.
FLOOR = 0.07
SOLID = 0.42
# The drop shadow is neutral grey while the logo is strongly teal, so weak
# pixels with almost no chroma are discarded outright.
GREY_CHROMA = 0.07
GREY_COVERAGE = 0.45


def cut_background(im: Image.Image) -> Image.Image:
    rgb = np.asarray(im.convert("RGB"), dtype=np.float32)
    coverage = 1.0 - rgb.min(axis=2) / 255.0
    chroma = (rgb.max(axis=2) - rgb.min(axis=2)) / 255.0
    alpha = np.clip((coverage - FLOOR) / (SOLID - FLOOR), 0.0, 1.0)
    alpha[(chroma < GREY_CHROMA) & (coverage < GREY_COVERAGE)] = 0.0

    safe = np.maximum(alpha, 1e-4)[..., None]
    fg = (rgb - (1.0 - safe) * 255.0) / safe
    fg = np.clip(fg, 0, 255)

    out = np.dstack([fg, alpha * 255.0]).astype(np.uint8)
    out[alpha < 0.004] = 0
    return Image.fromarray(out, "RGBA")


def trim(im: Image.Image, pad: int = 0) -> Image.Image:
    box = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if box is None:
        return im
    cropped = im.crop(box)
    if pad == 0:
        return cropped
    canvas = Image.new("RGBA", (cropped.width + pad * 2, cropped.height + pad * 2), (0, 0, 0, 0))
    canvas.alpha_composite(cropped, (pad, pad))
    return canvas


def split_mark_and_word(im: Image.Image) -> tuple[Image.Image, Image.Image]:
    """Find the blank band between the QR block and the wordmark."""
    rows = np.asarray(im.getchannel("A"), dtype=np.float32).sum(axis=1)
    active = rows > rows.max() * 0.01
    bands: list[tuple[int, int]] = []
    start: int | None = None
    for y, on in enumerate(active):
        if on and start is None:
            start = y
        elif not on and start is not None:
            bands.append((start, y))
            start = None
    if start is not None:
        bands.append((start, len(active)))
    bands = [b for b in bands if b[1] - b[0] > im.height * 0.03]
    if len(bands) < 2:
        return im, im
    mark = im.crop((0, bands[0][0], im.width, bands[0][1]))
    word = im.crop((0, bands[-1][0], im.width, bands[-1][1]))
    return trim(mark), trim(word)


def square(im: Image.Image, side: int, margin: float = 0.0) -> Image.Image:
    inner = int(side * (1 - margin * 2))
    scale = min(inner / im.width, inner / im.height)
    resized = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((side - resized.width) // 2, (side - resized.height) // 2))
    return canvas


def fit_width(im: Image.Image, width: int) -> Image.Image:
    scale = width / im.width
    return im.resize((width, max(1, round(im.height * scale))), Image.Resampling.LANCZOS)


def main() -> None:
    source = Image.open(SOURCE)
    cut = cut_background(source)
    full = trim(cut)
    mark, word = split_mark_and_word(full)

    mark_png = square(mark, 1024)
    full_png = fit_width(full, 1024)

    clinic = ROOT / "medical_qr_clinic" / "assets" / "brand"
    admin = ROOT / "medical_qr_admin" / "assets" / "brand"
    drawable = ROOT / "medical_qr_clinic" / "android" / "app" / "src" / "main" / "res" / "drawable"
    for folder in (clinic, admin, drawable):
        folder.mkdir(parents=True, exist_ok=True)

    splash = Image.new("RGBA", (1024, 1280), (0, 0, 0, 0))
    scaled = fit_width(full, 820)
    splash.alpha_composite(scaled, (102, (1280 - scaled.height) // 2))

    for folder in (clinic, admin):
        mark_png.save(folder / "logo_mark.png")
        full_png.save(folder / "logo_full.png")
        splash.save(folder / "logo_splash.png")
    square(mark, 512).save(drawable / "splash_logo.png")

    preview = Image.new("RGBA", (1100, 700), CREAM)
    preview.alpha_composite(square(mark, 420), (60, 140))
    preview.alpha_composite(fit_width(full, 420), (560, 60))
    x = 60
    for side in (32, 44, 64, 96):
        preview.alpha_composite(square(mark, side), (x, 600))
        x += side + 30
    preview.convert("RGB").save(ROOT / "tools" / "brand_preview.png")

    print("mark", mark.size, "word", word.size, "full", full.size)


if __name__ == "__main__":
    main()
