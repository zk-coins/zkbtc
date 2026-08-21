#!/usr/bin/env python3
"""Deterministic zkBTC raster-master brand exporter.

Never draws, traces, or reconstructs logo geometry. All artwork is derived
from branding/source/zkbtc-logo-master.png (byte copy of the approved PNG).
"""
from __future__ import annotations

import base64
import hashlib
import io
import json
import struct
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from PIL.PngImagePlugin import PngInfo
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas as pdfcanvas

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "branding"
SOURCE_IN = BRAND / "source" / "zkbtc-logo-master.png"
SOURCE_OUT = BRAND / "source" / "zkbtc-logo-master.png"
EXPECTED_SHA = "a4cf36c991f6458ef43f94077ff0c4d844855166df2a221715f79405cf3d5131"
EXPECTED_SIZE = (1774, 887)
SYMBOL_CROP = (220, 180, 610, 715)
SPLIT_X = 980
LIGHT_USE_ALPHA_CUTOFF = 32
LOCKUP_WIDTHS = (320, 640, 1280, 1774, 2560)
SYMBOL_SIZES = (16, 32, 64, 128, 192, 256, 512, 1024)
ICO_SIZES = (16, 32, 48, 64, 128, 256)
ORANGE = (247, 147, 26)
NEAR_BLACK = (10, 10, 10)
WHITE = (255, 255, 255)
WARM_PAPER = (247, 243, 234)
WARM_GRAY = (217, 210, 195)
BLACK = (0, 0, 0)
PREVIEW_SIZE = (1600, 1000)
PREVIEW_MARGIN = 40
PREVIEW_03_BG = (14, 14, 14)
PREVIEW_03_1280_LABEL = "1280×640 export — scaled for sheet"
PDF_TITLE = "Raster-backed container; approved PNG master defines the artwork"
PDF_AUTHOR = "zkBTC"
PDF_SUBJECT = "raster-backed"
PDF_CREATOR = "zkBTC branding exporter"
WEBP_LOSSLESS_METHOD = 4
BUNDLED_FONT = BRAND / "fonts" / "BitstreamVeraSans.ttf"

LOCKUP_VARIANTS = (
    "dark-bg",
    "light-bg",
    "transparent-dark-use",
    "transparent-light-use",
    "mono-black",
    "mono-white",
    "mono-orange",
)
SYMBOL_VARIANTS = (
    "source-orange-transparent",
    "black-transparent",
    "white-transparent",
    "source-orange-on-black",
    "source-orange-on-warm-paper",
    "black-on-warm-paper",
    "white-on-black",
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_dirs() -> None:
    for p in [
        BRAND / "source",
        BRAND / "logo" / "png" / "lockup",
        BRAND / "logo" / "webp" / "lockup",
        BRAND / "logo" / "png" / "symbol",
        BRAND / "logo" / "webp" / "symbol",
        BRAND / "logo" / "svg" / "lockup",
        BRAND / "logo" / "svg" / "symbol",
        BRAND / "logo" / "svg" / "avatar",
        BRAND / "logo" / "pdf" / "lockup",
        BRAND / "logo" / "pdf" / "symbol",
        BRAND / "favicon",
        BRAND / "social",
        BRAND / "previews",
        BRAND / "tokens",
    ]:
        p.mkdir(parents=True, exist_ok=True)


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=False, compress_level=9)
    path.write_bytes(buf.getvalue())


def save_webp(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    buf = io.BytesIO()
    img.save(
        buf,
        format="WEBP",
        lossless=True,
        method=WEBP_LOSSLESS_METHOD,
        quality=100,
    )
    path.write_bytes(buf.getvalue())


def copy_bytes(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    data = src.read_bytes()
    dst.write_bytes(data)


def to_rgba_straight_from_black(rgb: Image.Image) -> Image.Image:
    arr = np.asarray(rgb.convert("RGB"), dtype=np.uint16)
    alpha = arr.max(axis=2)
    out = np.zeros((arr.shape[0], arr.shape[1], 4), dtype=np.uint8)
    mask = alpha > 0
    a = alpha[mask].astype(np.float64)
    out[..., 3] = alpha.astype(np.uint8)
    for c in range(3):
        ch = np.zeros(alpha.shape, dtype=np.uint8)
        ch[mask] = np.round(arr[..., c][mask].astype(np.float64) * 255.0 / a).astype(np.uint8)
        out[..., c] = ch
    return Image.fromarray(out)


def light_use_from_transparent(src_rgb: Image.Image, trans: Image.Image) -> Image.Image:
    """BTC-region cleanup for light use. Does not change geometry.

    x < SPLIT_X is copied from the source-derived transparent lockup unchanged.
    For x >= SPLIT_X, pixels with source-derived alpha >= LIGHT_USE_ALPHA_CUTOFF
    keep that alpha and are set to near-black RGB. Pixels with alpha below the
    cutoff are zeroed (RGB and alpha) so subvisible black-canvas noise cannot
    appear on warm paper. The cutoff is cleanup, not new logo geometry.
    """
    del src_rgb  # alpha already derived from the approved master via trans
    out = np.array(trans.convert("RGBA"), copy=True)
    btc = out[:, SPLIT_X:, :]
    a = btc[:, :, 3]
    keep = a >= LIGHT_USE_ALPHA_CUTOFF
    drop = ~keep
    btc[keep, 0] = NEAR_BLACK[0]
    btc[keep, 1] = NEAR_BLACK[1]
    btc[keep, 2] = NEAR_BLACK[2]
    btc[drop, 0] = 0
    btc[drop, 1] = 0
    btc[drop, 2] = 0
    btc[drop, 3] = 0
    out[:, SPLIT_X:, :] = btc
    return Image.fromarray(out)


def composite_on(rgba: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    base = Image.new("RGB", rgba.size, bg)
    base.paste(rgba, mask=rgba.split()[3])
    return base


def fill_alpha(alpha_img: Image.Image, color: tuple[int, int, int]) -> Image.Image:
    if alpha_img.mode == "RGBA":
        a = alpha_img.split()[3]
    else:
        a = alpha_img
    out = Image.new("RGBA", alpha_img.size, (*color, 0))
    solid = Image.new("RGBA", alpha_img.size, (*color, 255))
    out.paste(solid, mask=a)
    # restore exact alpha channel
    r, g, b, _ = out.split()
    return Image.merge("RGBA", (r, g, b, a))


def resize_rgb(img: Image.Image, width: int) -> Image.Image:
    w, h = img.size
    nh = int(round(h * (width / w)))
    if (width, nh) == img.size:
        return img.copy()
    return img.resize((width, nh), Image.Resampling.LANCZOS)


def resize_rgba(img: Image.Image, width: int) -> Image.Image:
    w, h = img.size
    nh = int(round(h * (width / w)))
    if (width, nh) == img.size:
        return img.copy()
    return img.resize((width, nh), Image.Resampling.LANCZOS)


def fit_symbol_square(crop_rgba: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner = size * 0.80
    cw, ch = crop_rgba.size
    scale = min(inner / cw, inner / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = crop_rgba.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (size - nw) // 2
    y = (size - nh) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def embed_svg(png_path: Path, svg_path: Path, width: int, height: int) -> None:
    b64 = base64.b64encode(png_path.read_bytes()).decode("ascii")
    title = "Raster-backed container; approved PNG master defines the artwork"
    svg = (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img">\n'
        f"  <title>{title}</title>\n"
        f"  <metadata>{title}</metadata>\n"
        f'  <image width="{width}" height="{height}" '
        f'href="data:image/png;base64,{b64}"/>\n'
        f"</svg>\n"
    )
    svg_path.write_text(svg, encoding="utf-8")


def make_pdf_canvas(path: Path, pagesize) -> pdfcanvas.Canvas:
    c = pdfcanvas.Canvas(
        str(path),
        pagesize=pagesize,
        pageCompression=0,
        invariant=1,
    )
    c.setTitle(PDF_TITLE)
    c.setAuthor(PDF_AUTHOR)
    c.setSubject(PDF_SUBJECT)
    c.setCreator(PDF_CREATOR)
    return c


def raster_pdf(png_path: Path, pdf_path: Path, page_w: int, page_h: int) -> None:
    c = make_pdf_canvas(pdf_path, (page_w, page_h))
    img = ImageReader(str(png_path))
    c.drawImage(img, 0, 0, width=page_w, height=page_h, mask="auto")
    c.showPage()
    c.save()


def font(size: int) -> ImageFont.FreeTypeFont:
    if not BUNDLED_FONT.is_file():
        raise SystemExit(
            "missing bundled preview font: branding/fonts/BitstreamVeraSans.ttf"
        )
    try:
        return ImageFont.truetype(str(BUNDLED_FONT), size)
    except OSError as exc:
        raise SystemExit(
            "unreadable bundled preview font: branding/fonts/BitstreamVeraSans.ttf "
            f"({exc})"
        ) from exc


def draw_label(draw: ImageDraw.ImageDraw, xy, text, fill=(255, 255, 255), size=18):
    draw.text(xy, text, fill=fill, font=font(size))


def checkerboard(size, cell=16) -> Image.Image:
    w, h = size
    im = Image.new("RGB", size, (200, 200, 200))
    px = im.load()
    for y in range(h):
        for x in range(w):
            if ((x // cell) + (y // cell)) % 2 == 0:
                px[x, y] = (240, 240, 240)
            else:
                px[x, y] = (180, 180, 180)
    return im


def max_channel_delta(a: Image.Image, b: Image.Image) -> int:
    aa = np.asarray(a.convert("RGB"), dtype=np.int16)
    bb = np.asarray(b.convert("RGB"), dtype=np.int16)
    return int(np.abs(aa - bb).max())


def write_ico(images: list[Image.Image], path: Path) -> None:
    """Write a multi-size ICO from RGBA images (PNG-encoded entries)."""
    entries = []
    payloads = []
    for im in images:
        im = im.convert("RGBA")
        bio = io.BytesIO()
        im.save(bio, format="PNG", optimize=False, compress_level=9)
        data = bio.getvalue()
        w, h = im.size
        entries.append((w if w < 256 else 0, h if h < 256 else 0, len(data)))
        payloads.append(data)
    offset = 6 + 16 * len(entries)
    out = io.BytesIO()
    out.write(struct.pack("<HHH", 0, 1, len(entries)))
    for (w, h, size), _ in zip(entries, payloads):
        out.write(struct.pack("<BBBBHHII", w, h, 0, 0, 1, 32, size, offset))
        offset += size
    for data in payloads:
        out.write(data)
    path.write_bytes(out.getvalue())


def tree_files() -> list[Path]:
    files = []
    for p in sorted(BRAND.rglob("*")):
        if p.is_file():
            files.append(p)
    return files


def build_manifest(extra: dict) -> None:
    files = []
    for p in tree_files():
        rel = str(p.relative_to(ROOT)).replace("\\", "/")
        if rel.endswith("asset-manifest.json"):
            continue
        kind = "raster-derived"
        if rel == "branding/source/zkbtc-logo-master.png":
            kind = "raster-master"
        elif rel.endswith("zkbtc-lockup-master-dark-bg.png") or rel.endswith(
            "zkbtc-lockup-dark-bg-1774.png"
        ):
            kind = "raster-master"
        elif rel.endswith(".svg") or (rel.endswith(".pdf") and "/logo/pdf/" in rel):
            kind = "raster-backed-container"
        elif rel.endswith("zkbtc-brandbook.pdf"):
            kind = "raster-backed-container"
        elif (
            rel.startswith("branding/tools/")
            or rel.startswith("branding/fonts/")
            or rel.endswith(".md")
            or rel.endswith("tokens.json")
            or rel.endswith("tokens.css")
        ):
            kind = "support"
        files.append(
            {
                "path": rel,
                "sha256": sha256_file(p),
                "bytes": p.stat().st_size,
                "kind": kind,
            }
        )
    manifest = {
        "brand": "zkBTC",
        "masterKind": "raster-master",
        "limitation": (
            "Without a true vector master, SVG and PDF outputs are raster-backed "
            "containers. The approved PNG pixels define the artwork."
        ),
        "source": {
            "path": "branding/source/zkbtc-logo-master.png",
            "sha256": EXPECTED_SHA,
            "width": EXPECTED_SIZE[0],
            "height": EXPECTED_SIZE[1],
        },
        "files": files,
        **extra,
    }
    text = json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    (BRAND / "asset-manifest.json").write_text(text, encoding="utf-8")


def preview_00(master: Image.Image, trans: Image.Image, delta: int, sha: str) -> None:
    sheet = Image.new("RGB", (1600, 1000), (12, 12, 12))
    draw = ImageDraw.Draw(sheet)
    draw_label(draw, (40, 24), "00 — Master fidelity", size=28)
    draw_label(
        draw,
        (40, 64),
        f"Approved PNG SHA-256 {sha}",
        size=16,
        fill=(200, 200, 200),
    )
    draw_label(
        draw,
        (40, 92),
        "Canonical master is a byte-for-byte copy. Byte diff 0. Decoded pixel diff 0.",
        size=16,
        fill=(200, 200, 200),
    )
    left = master.resize((700, 350), Image.Resampling.LANCZOS)
    recon = composite_on(trans, BLACK).resize((700, 350), Image.Resampling.LANCZOS)
    sheet.paste(left, (40, 160))
    sheet.paste(recon, (860, 160))
    draw_label(draw, (40, 520), "Approved input / canonical master (identical)", size=18)
    draw_label(
        draw,
        (860, 520),
        f"Transparent derived recomposited on black  |  max channel delta = {delta}",
        size=18,
    )
    draw_label(
        draw,
        (40, 580),
        "Master canvas is pure black. Orange architectural B/Z carries subtle internal tonal variation.",
        size=16,
        fill=ORANGE,
    )
    draw_label(
        draw,
        (40, 620),
        "Transparent / light / mono variants are derived conveniences, not masters.",
        size=16,
        fill=(180, 180, 180),
    )
    save_png(sheet, BRAND / "previews" / "00-master-fidelity.png")


def preview_01(lockups: dict) -> None:
    sheet = Image.new("RGB", (1600, 1000), (18, 18, 18))
    draw = ImageDraw.Draw(sheet)
    draw_label(draw, (40, 20), "01 — Lockups (actual exports)", size=28)
    slots = [
        ("dark-bg", "Dark bg", (40, 70), (740, 200), BLACK),
        ("light-bg", "Light bg (warm paper)", (840, 70), (740, 200), WARM_PAPER),
        ("transparent-dark-use", "Transparent on checker", (40, 310), (500, 140), None),
        ("transparent-light-use", "Transparent light-use on paper", (560, 310), (500, 140), WARM_PAPER),
        ("mono-black", "Mono black", (1080, 310), (480, 140), WARM_PAPER),
        ("mono-white", "Mono white", (40, 500), (500, 140), BLACK),
        ("mono-orange", "Mono orange", (560, 500), (500, 140), BLACK),
        ("transparent-dark-use", "Transparent on dark", (1080, 500), (480, 140), BLACK),
    ]
    for key, label, xy, size, bg in slots:
        im = lockups[key]
        box = Image.new("RGB", size, bg if bg else (0, 0, 0))
        if bg is None:
            box = checkerboard(size)
            box.paste(im.resize(size, Image.Resampling.LANCZOS), (0, 0), im.resize(size, Image.Resampling.LANCZOS).convert("RGBA"))
        else:
            fitted = im.convert("RGBA").resize(size, Image.Resampling.LANCZOS)
            if fitted.mode == "RGBA":
                box.paste(fitted, mask=fitted.split()[3] if "A" in fitted.mode else None)
            else:
                box.paste(fitted.convert("RGB"))
            if im.mode == "RGBA":
                tmp = Image.new("RGBA", size, (*bg, 255))
                rsz = im.resize(size, Image.Resampling.LANCZOS)
                tmp.alpha_composite(rsz)
                box = tmp.convert("RGB")
            else:
                box = im.convert("RGB").resize(size, Image.Resampling.LANCZOS)
                if bg != BLACK:
                    pass
        sheet.paste(box, xy)
        draw_label(draw, (xy[0], xy[1] + size[1] + 6), label, size=16)
    save_png(sheet, BRAND / "previews" / "01-lockups.png")


def preview_02(symbols: dict) -> None:
    sheet = Image.new("RGB", (1600, 1000), (16, 16, 16))
    draw = ImageDraw.Draw(sheet)
    draw_label(draw, (40, 20), "02 — Symbol variants (crop 220,180,610,715)", size=28)
    draw_label(
        draw,
        (40, 56),
        "Architectural B/Z retains two top and two bottom Bitcoin strokes. Crop excludes zkBTC wordmark.",
        size=16,
        fill=(190, 190, 190),
    )
    names = list(SYMBOL_VARIANTS)
    for i, name in enumerate(names):
        col = i % 4
        row = i // 4
        x = 40 + col * 390
        y = 110 + row * 420
        tile = Image.new("RGB", (360, 360), BLACK if "black" in name and "warm" not in name else WARM_PAPER)
        if name.endswith("transparent") or name == "source-orange-transparent":
            tile = checkerboard((360, 360))
        im = symbols[name].resize((360, 360), Image.Resampling.LANCZOS)
        if im.mode == "RGBA":
            tile = tile.convert("RGBA")
            tile.alpha_composite(im)
            tile = tile.convert("RGB")
        else:
            tile = im.convert("RGB")
        sheet.paste(tile, (x, y))
        draw_label(draw, (x, y + 366), name, size=14)
    save_png(sheet, BRAND / "previews" / "02-symbols.png")


def preview_03(lock_dark: Image.Image, sym: Image.Image) -> None:
    sheet = Image.new("RGB", PREVIEW_SIZE, PREVIEW_03_BG)
    draw = ImageDraw.Draw(sheet)
    m = PREVIEW_MARGIN
    draw_label(draw, (m, m), "03 — Sizes and clear space", size=28)
    draw_label(
        draw,
        (m, m + 36),
        "Clear space: keep at least 10% of lockup height empty on every side. Do not invent construction coordinates.",
        size=16,
        fill=(190, 190, 190),
    )
    native_320 = resize_rgb(lock_dark, 320)
    native_640 = resize_rgb(lock_dark, 640)
    native_1280 = resize_rgb(lock_dark, 1280)
    y_lock = 110
    x = m
    sheet.paste(native_320, (x, y_lock))
    draw_label(draw, (x, y_lock + native_320.size[1] + 8), "320×160 export — native", size=16)
    x += native_320.size[0] + 24
    sheet.paste(native_640, (x, y_lock))
    draw_label(draw, (x, y_lock + native_640.size[1] + 8), "640×320 export — native", size=16)
    x += native_640.size[0] + 24
    slot_right = PREVIEW_SIZE[0] - m
    slot_w = slot_right - x
    slot_h = native_640.size[1]
    scale = min(slot_w / native_1280.size[0], slot_h / native_1280.size[1])
    sw = max(1, int(round(native_1280.size[0] * scale)))
    sh = max(1, int(round(native_1280.size[1] * scale)))
    scaled = native_1280.resize((sw, sh), Image.Resampling.LANCZOS)
    slot = Image.new("RGB", (slot_w, slot_h), (28, 28, 28))
    ox = (slot_w - sw) // 2
    oy = (slot_h - sh) // 2
    slot.paste(scaled, (ox, oy))
    sheet.paste(slot, (x, y_lock))
    draw.rectangle((x, y_lock, x + slot_w - 1, y_lock + slot_h - 1), outline=(90, 90, 90), width=1)
    draw_label(draw, (x, y_lock + slot_h + 8), PREVIEW_03_1280_LABEL, size=16)
    y = 500
    sx = m
    for s in (32, 64, 128, 256):
        im = fit_symbol_square(sym, s)
        pad = 10
        bg = Image.new("RGB", (s + pad * 2, s + pad * 2), (30, 30, 30))
        bg.paste(im, (pad, pad), im)
        sheet.paste(bg, (sx, y))
        draw_label(draw, (sx, y + s + pad * 2 + 8), f"{s}px symbol", size=14)
        sx += s + 56
    dest = BRAND / "previews" / "03-sizes-and-clearspace.png"
    dest.parent.mkdir(parents=True, exist_ok=True)
    meta = PngInfo()
    meta.add_text("preview03_1280_label", PREVIEW_03_1280_LABEL)
    buf = io.BytesIO()
    sheet.save(buf, format="PNG", optimize=False, compress_level=9, pnginfo=meta)
    dest.write_bytes(buf.getvalue())


def preview_04(master: Image.Image) -> None:
    sheet = Image.new("RGB", (1600, 1000), (20, 20, 20))
    draw = ImageDraw.Draw(sheet)
    draw_label(draw, (40, 20), "04 — Correct and incorrect use", size=28)
    ok = master.resize((520, 260), Image.Resampling.LANCZOS)
    sheet.paste(ok, (40, 80))
    draw_label(draw, (40, 350), "CORRECT — approved master pixels on black", size=16, fill=(120, 200, 120))

    # prohibited samples: clearly transformed, labeled
    rot = master.rotate(12, expand=True, fillcolor=BLACK).resize((520, 260), Image.Resampling.LANCZOS)
    sheet.paste(rot, (840, 80))
    draw.rectangle((840, 80, 1360, 340), outline=(220, 40, 40), width=4)
    draw_label(draw, (840, 350), "PROHIBITED SAMPLE — rotated (do not use)", size=16, fill=(220, 80, 80))

    squish = master.resize((520, 160), Image.Resampling.LANCZOS)
    pad = Image.new("RGB", (520, 260), (40, 40, 40))
    pad.paste(squish, (0, 50))
    sheet.paste(pad, (40, 420))
    draw.rectangle((40, 420, 560, 680), outline=(220, 40, 40), width=4)
    draw_label(draw, (40, 690), "PROHIBITED SAMPLE — stretched (do not use)", size=16, fill=(220, 80, 80))

    rec = Image.new("RGB", (520, 260), (0, 80, 180))
    rec.paste(master.resize((520, 260), Image.Resampling.LANCZOS))
    # overlay color wash
    wash = Image.new("RGB", (520, 260), (0, 90, 200))
    rec = Image.blend(rec, wash, 0.45)
    sheet.paste(rec, (840, 420))
    draw.rectangle((840, 420, 1360, 680), outline=(220, 40, 40), width=4)
    draw_label(draw, (840, 690), "PROHIBITED SAMPLE — recolored (do not use)", size=16, fill=(220, 80, 80))

    draw_label(
        draw,
        (40, 760),
        "Do not outline, add shadows, rearrange zk/BTC, crop the strokes, or reconstruct the B/Z in vectors.",
        size=16,
        fill=(200, 200, 200),
    )
    draw_label(
        draw,
        (40, 800),
        "Do not treat SVG/PDF as editable path art. They are raster-backed containers only.",
        size=16,
        fill=(200, 200, 200),
    )
    save_png(sheet, BRAND / "previews" / "04-correct-incorrect-use.png")


def preview_05() -> None:
    sheet = Image.new("RGB", (1600, 1000), (12, 12, 14))
    draw = ImageDraw.Draw(sheet)
    draw_label(draw, (40, 20), "05 — File map", size=28)
    lines = [
        "branding/source/zkbtc-logo-master.png          raster-master (exact approved pixels)",
        "branding/logo/png/lockup/                      dark, light, transparent, mono  ·  widths 320–2560",
        "branding/logo/webp/lockup/                     lossless WebP of the same lockups",
        "branding/logo/png/symbol/                      square symbol 16–1024  ·  7 variants",
        "branding/logo/svg/                             raster-backed containers (embedded PNG data URI)",
        "branding/logo/pdf/                             raster-backed PDF containers",
        "branding/favicon/                              ICO 16–256, favicon 16/32, Apple 180, Android 192/512",
        "branding/social/                               OG 1280×640 & 640×320, avatars 1024 & 512",
        "branding/previews/                             00–05 sheets at 1600×1000",
        "branding/zkbtc-brandbook.pdf                   raster-backed multi-page A4 brandbook",
        "branding/asset-manifest.json                   SHA-256 for every generated/distributed file",
        "No filename contains draft or reference.",
    ]
    y = 90
    for line in lines:
        draw_label(draw, (40, y), line, size=18, fill=(220, 220, 220))
        y += 52
    save_png(sheet, BRAND / "previews" / "05-file-map.png")


def build_brandbook_pdf(paths: dict, delta: int) -> None:
    out = BRAND / "zkbtc-brandbook.pdf"
    c = make_pdf_canvas(out, A4)
    W, H = A4
    footer_h = 16 * mm
    header_bottom = H - 32 * mm

    def header(title: str):
        c.setFillColorRGB(0.04, 0.04, 0.04)
        c.rect(0, 0, W, H, fill=1, stroke=0)
        c.setFillColorRGB(*[x / 255 for x in ORANGE])
        c.setFont("Helvetica-Bold", 16)
        c.drawString(16 * mm, H - 16 * mm, "zkBTC Brandbook")
        c.setFillColorRGB(1, 1, 1)
        c.setFont("Helvetica", 12)
        c.drawString(16 * mm, H - 24 * mm, title)
        c.setStrokeColorRGB(0.25, 0.25, 0.25)
        c.setLineWidth(0.4)
        c.line(16 * mm, H - 28 * mm, W - 16 * mm, H - 28 * mm)
        c.setFont("Helvetica", 8)
        c.setFillColorRGB(0.7, 0.7, 0.7)
        c.drawRightString(
            W - 16 * mm,
            10 * mm,
            "Raster-backed documentation. Approved PNG master defines the artwork.",
        )

    def sheet_image(path: Path, crop_bottom: int):
        with Image.open(path) as im:
            pw, _ph = im.size
            cropped = im.crop((0, 0, pw, crop_bottom)).convert("RGBA")
        top = header_bottom
        bottom = footer_h
        area_h = top - bottom
        area_w = W - 24 * mm
        cw, ch = cropped.size
        scale = min(area_w / cw, area_h / ch)
        draw_w = cw * scale
        draw_h = ch * scale
        x = 12 * mm + (area_w - draw_w) / 2
        y = top - draw_h
        buf = io.BytesIO()
        cropped.save(buf, format="PNG")
        buf.seek(0)
        c.drawImage(
            ImageReader(buf),
            x,
            y,
            width=draw_w,
            height=draw_h,
            mask="auto",
        )

    header("1  Master status")
    c.setFillColorRGB(1, 1, 1)
    c.setFont("Helvetica", 10)
    text = [
        "The only logo master is the approved PNG (1774×887).",
        f"SHA-256 {EXPECTED_SHA}",
        "Canonical lockup master is a byte-for-byte copy. Byte diff 0. Pixel diff 0.",
        "Presentation canvas is pure black. The orange architectural Bitcoin-B/Z has two top and",
        "two bottom Bitcoin strokes and subtle internal tonal variation. That variation is binding.",
        "Do not impose a flat-color or no-gradient rule on the master.",
        "Transparent, light-use, and mono files are derived conveniences, not masters.",
        "SVG and PDF are raster-backed containers, not editable vector art.",
        f"Transparent recomposition over black: measured max channel delta = {delta} (gate ≤ 1).",
        "No construction coordinates are invented. Geometry comes only from source pixels.",
    ]
    y = header_bottom - 6 * mm
    for line in text:
        c.drawString(16 * mm, y, line)
        y -= 5.2 * mm
    master_h = y - footer_h - 6 * mm
    master_w = W - 32 * mm
    c.drawImage(
        ImageReader(str(paths["master"])),
        16 * mm,
        footer_h + 4 * mm,
        width=master_w,
        height=master_h,
        preserveAspectRatio=True,
        mask="auto",
        anchor="c",
    )
    c.showPage()

    header("2  Logo variants")
    sheet_image(paths["preview01"], 700)
    c.showPage()

    header("3  Symbol and avatar")
    sheet_image(paths["preview02"], 950)
    c.showPage()

    header("4  Color")
    swatches = [
        ("Orange anchor", ORANGE, "#F7931A"),
        ("Near-black", NEAR_BLACK, "#0A0A0A"),
        ("White", WHITE, "#FFFFFF"),
        ("Warm paper", WARM_PAPER, "#F7F3EA"),
        ("Warm gray", WARM_GRAY, "#D9D2C3"),
        ("Master canvas", BLACK, "#000000"),
    ]
    cell_w = 58 * mm
    cell_h = 42 * mm
    origin_x = 16 * mm
    origin_y = header_bottom - 8 * mm - cell_h
    for i, (name, rgb, hexv) in enumerate(swatches):
        col = i % 3
        row = i // 3
        x = origin_x + col * (cell_w + 8 * mm)
        y = origin_y - row * (cell_h + 10 * mm)
        luminance = 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
        if luminance < 80:
            stroke = (247 / 255, 147 / 255, 26 / 255)
        else:
            stroke = (0.05, 0.05, 0.05)
        c.setFillColorRGB(*[v / 255 for v in rgb])
        c.setStrokeColorRGB(*stroke)
        c.setLineWidth(1.6)
        c.roundRect(x, y + 12 * mm, cell_w, 26 * mm, 3, fill=1, stroke=1)
        c.setFillColorRGB(1, 1, 1)
        c.setFont("Helvetica-Bold", 10)
        c.drawString(x, y + 6 * mm, name)
        c.setFont("Helvetica", 9)
        c.drawString(x, y + 1 * mm, hexv)
    c.setFont("Helvetica", 10)
    c.setFillColorRGB(1, 1, 1)
    y = origin_y - 2 * (cell_h + 10 * mm) + 4 * mm
    for line in [
        "Support UI uses the palette above.",
        "The master itself is not a flat-color lockup: orange regions contain source tonal variation.",
        "Light-use BTC (x ≥ 980): source-derived alpha ≥ 32 becomes near-black RGB with that alpha kept;",
        "alpha < 32 is zeroed as cleanup of subvisible black-canvas noise, not new geometry.",
        "Wordmark: orange zk, white BTC on the dark master.",
    ]:
        c.drawString(16 * mm, y, line)
        y -= 6 * mm
    c.showPage()

    header("5  Clear space and minimum size")
    sheet_image(paths["preview03"], 820)
    c.showPage()

    header("6  Formats")
    c.setFillColorRGB(1, 1, 1)
    c.setFont("Helvetica", 10)
    y = header_bottom - 8 * mm
    for line in [
        "PNG: lossless raster for lockups, symbols, favicons, social, previews.",
        "WebP: lossless companions of lockup and symbol PNGs (deterministic lossless encoding).",
        "SVG: raster-backed container with embedded data:image/png;base64, and no external href.",
        "PDF logo files: high-resolution raster art in a PDF container. Not path outlines.",
        "ICO: 16, 32, 48, 64, 128, 256. Favicon PNG 16/32. Apple 180. Android 192/512.",
        "All SVG/PDF metadata/title: Raster-backed container; approved PNG master defines the artwork.",
        "PDF writers use invariant metadata (fixed title/author/subject; no wall-clock dates).",
        "asset-manifest.json lists SHA-256 for every generated/distributed file. No timestamps.",
        "Kind labels: raster-master | raster-derived | raster-backed-container.",
    ]:
        c.drawString(16 * mm, y, line)
        y -= 8 * mm
    c.showPage()

    header("7  Correct and incorrect use")
    sheet_image(paths["preview04"], 880)
    c.showPage()

    header("8  Technical verification")
    c.setFillColorRGB(1, 1, 1)
    c.setFont("Helvetica", 10)
    y = header_bottom - 8 * mm
    for line in [
        "Verifier asserts source name, SHA-256, and 1774×887.",
        "No package filename contains draft or reference.",
        "Lockup master PNG is byte-identical and pixel-identical to the approved source.",
        "Transparent dark-use recomposed on black: max channel delta ≤ 1.",
        "Alpha is real (not a fake opaque rectangle).",
        "Light-use BTC cleanup uses alpha cutoff 32; x < 980 is unchanged from dark-use.",
        "Symbol crop ends before x=610 and cannot include wordmark pixels.",
        "SVGs embed data:image/png;base64, and contain no external URL.",
        "Manifest hashes match files on disk.",
        "Brandbook PDF has at least 6 pages (this document).",
        "Honest limitation: without a true vector master, SVG/PDF are raster-backed containers.",
    ]:
        c.drawString(16 * mm, y, line)
        y -= 7 * mm
    c.showPage()
    c.save()


def social_card(bg: tuple[int, int, int], lockup: Image.Image, size: tuple[int, int], dest: Path) -> None:
    card = Image.new("RGB", size, bg)
    # scale lockup to ~70% width
    tw = int(size[0] * 0.72)
    th = int(round(tw * lockup.size[1] / lockup.size[0]))
    im = lockup.convert("RGBA").resize((tw, th), Image.Resampling.LANCZOS)
    x = (size[0] - tw) // 2
    y = (size[1] - th) // 2
    if im.mode == "RGBA":
        card.paste(Image.new("RGB", (tw, th), bg), (x, y))
        tmp = Image.new("RGBA", size, (*bg, 255))
        tmp.paste(im, (x, y), im)
        card = tmp.convert("RGB")
    else:
        card.paste(im.convert("RGB"), (x, y))
    save_png(card, dest)


def avatar_tile(bg: tuple[int, int, int], symbol: Image.Image, size: int, dest: Path) -> Image.Image:
    tile = Image.new("RGBA", (size, size), (*bg, 255))
    inner = fit_symbol_square(symbol, size)
    tile.alpha_composite(inner)
    rgb = tile.convert("RGB")
    save_png(rgb, dest)
    return rgb


def main() -> None:
    ensure_dirs()
    font(16)
    if not SOURCE_IN.is_file():
        raise SystemExit(f"missing approved PNG: {SOURCE_IN}")
    data = SOURCE_IN.read_bytes()
    digest = sha256_bytes(data)
    if digest != EXPECTED_SHA:
        raise SystemExit(f"source SHA mismatch: {digest}")
    copy_bytes(SOURCE_IN, SOURCE_OUT)
    if sha256_file(SOURCE_OUT) != EXPECTED_SHA:
        raise SystemExit("source copy hash mismatch")

    master = Image.open(io.BytesIO(SOURCE_OUT.read_bytes())).convert("RGB")
    if master.size != EXPECTED_SIZE:
        raise SystemExit(f"size {master.size}")

    trans_dark = to_rgba_straight_from_black(master)
    trans_light = light_use_from_transparent(master, trans_dark)
    recon = composite_on(trans_dark, BLACK)
    delta = max_channel_delta(master, recon)

    lockup_master_path = BRAND / "logo" / "png" / "lockup" / "zkbtc-lockup-master-dark-bg.png"
    copy_bytes(SOURCE_OUT, lockup_master_path)

    lockups_full = {
        "dark-bg": master.convert("RGB"),
        "light-bg": composite_on(trans_light, WARM_PAPER),
        "transparent-dark-use": trans_dark,
        "transparent-light-use": trans_light,
        "mono-black": fill_alpha(trans_dark, NEAR_BLACK),
        "mono-white": fill_alpha(trans_dark, WHITE),
        "mono-orange": fill_alpha(trans_dark, ORANGE),
    }

    png_lockup = BRAND / "logo" / "png" / "lockup"
    webp_lockup = BRAND / "logo" / "webp" / "lockup"
    for variant, im in lockups_full.items():
        for width in LOCKUP_WIDTHS:
            if variant == "dark-bg" and width == 1774:
                dest = png_lockup / f"zkbtc-lockup-dark-bg-{width}.png"
                copy_bytes(SOURCE_OUT, dest)
                # webp still derived
                save_webp(master, webp_lockup / f"zkbtc-lockup-dark-bg-{width}.webp")
                continue
            if im.mode == "RGBA":
                r = resize_rgba(im, width)
            else:
                r = resize_rgb(im, width)
            save_png(r, png_lockup / f"zkbtc-lockup-{variant}-{width}.png")
            save_webp(r, webp_lockup / f"zkbtc-lockup-{variant}-{width}.webp")

    # crop symbol from source only
    crop_rgb = master.crop(SYMBOL_CROP)
    crop_rgba = to_rgba_straight_from_black(crop_rgb)

    symbols = {}
    for size in SYMBOL_SIZES:
        fitted = fit_symbol_square(crop_rgba, size)
        variants = {
            "source-orange-transparent": fitted,
            "black-transparent": fill_alpha(fitted, NEAR_BLACK),
            "white-transparent": fill_alpha(fitted, WHITE),
            "source-orange-on-black": composite_on(fitted, BLACK),
            "source-orange-on-warm-paper": composite_on(fitted, WARM_PAPER),
            "black-on-warm-paper": composite_on(fill_alpha(fitted, NEAR_BLACK), WARM_PAPER),
            "white-on-black": composite_on(fill_alpha(fitted, WHITE), BLACK),
        }
        if size == 1024:
            symbols = variants
        for name, im in variants.items():
            save_png(im, BRAND / "logo" / "png" / "symbol" / f"zkbtc-symbol-{name}-{size}.png")
            save_webp(im, BRAND / "logo" / "webp" / "symbol" / f"zkbtc-symbol-{name}-{size}.webp")

    # canonical SVGs (full-res lockups 1774 and symbols 1024, avatars 1024)
    svg_lock = BRAND / "logo" / "svg" / "lockup"
    for variant in LOCKUP_VARIANTS:
        if variant == "dark-bg":
            png = png_lockup / "zkbtc-lockup-dark-bg-1774.png"
        else:
            png = png_lockup / f"zkbtc-lockup-{variant}-1774.png"
        im = Image.open(png)
        w, h = im.size
        embed_svg(png, svg_lock / f"zkbtc-lockup-{variant}.svg", w, h)
        # PDF containers for canonical dark/light/mono
        if variant in ("dark-bg", "light-bg", "mono-black", "mono-white", "mono-orange"):
            raster_pdf(png, BRAND / "logo" / "pdf" / "lockup" / f"zkbtc-lockup-{variant}.pdf", w, h)

    svg_sym = BRAND / "logo" / "svg" / "symbol"
    for name in (
        "source-orange-transparent",
        "black-transparent",
        "white-transparent",
        "source-orange-on-black",
        "source-orange-on-warm-paper",
        "black-on-warm-paper",
        "white-on-black",
    ):
        png = BRAND / "logo" / "png" / "symbol" / f"zkbtc-symbol-{name}-1024.png"
        embed_svg(png, svg_sym / f"zkbtc-symbol-{name}.svg", 1024, 1024)
        if name in (
            "source-orange-transparent",
            "black-transparent",
            "white-transparent",
        ):
            raster_pdf(png, BRAND / "logo" / "pdf" / "symbol" / f"zkbtc-symbol-{name}.pdf", 1024, 1024)

    # favicons from dark tile
    ico_images = []
    for s in ICO_SIZES:
        tile = composite_on(fit_symbol_square(crop_rgba, s), BLACK)
        save_png(tile, BRAND / "favicon" / f"zkbtc-icon-{s}.png")
        ico_images.append(tile.convert("RGBA"))
    write_ico(ico_images, BRAND / "favicon" / "zkbtc.ico")
    write_ico(
        [composite_on(fit_symbol_square(crop_rgba, 16), BLACK).convert("RGBA"),
         composite_on(fit_symbol_square(crop_rgba, 32), BLACK).convert("RGBA")],
        BRAND / "favicon" / "favicon.ico",
    )
    save_png(composite_on(fit_symbol_square(crop_rgba, 16), BLACK), BRAND / "favicon" / "favicon-16.png")
    save_png(composite_on(fit_symbol_square(crop_rgba, 32), BLACK), BRAND / "favicon" / "favicon-32.png")
    save_png(composite_on(fit_symbol_square(crop_rgba, 180), BLACK), BRAND / "favicon" / "apple-touch-icon-180.png")
    save_png(composite_on(fit_symbol_square(crop_rgba, 192), BLACK), BRAND / "favicon" / "android-chrome-192.png")
    save_png(composite_on(fit_symbol_square(crop_rgba, 512), BLACK), BRAND / "favicon" / "android-chrome-512.png")

    # social
    social_card(BLACK, master, (1280, 640), BRAND / "social" / "zkbtc-og-dark-1280x640.png")
    social_card(WARM_PAPER, lockups_full["light-bg"], (1280, 640), BRAND / "social" / "zkbtc-og-light-1280x640.png")
    social_card(BLACK, master, (640, 320), BRAND / "social" / "zkbtc-og-dark-640x320.png")
    social_card(WARM_PAPER, lockups_full["light-bg"], (640, 320), BRAND / "social" / "zkbtc-og-light-640x320.png")

    avatar_tile(BLACK, crop_rgba, 1024, BRAND / "social" / "zkbtc-avatar-dark-1024.png")
    avatar_tile(BLACK, crop_rgba, 512, BRAND / "social" / "zkbtc-avatar-dark-512.png")
    avatar_tile(WARM_PAPER, crop_rgba, 1024, BRAND / "social" / "zkbtc-avatar-light-1024.png")
    avatar_tile(WARM_PAPER, crop_rgba, 512, BRAND / "social" / "zkbtc-avatar-light-512.png")
    embed_svg(
        BRAND / "social" / "zkbtc-avatar-dark-1024.png",
        BRAND / "logo" / "svg" / "avatar" / "zkbtc-avatar-dark.svg",
        1024,
        1024,
    )
    embed_svg(
        BRAND / "social" / "zkbtc-avatar-light-1024.png",
        BRAND / "logo" / "svg" / "avatar" / "zkbtc-avatar-light.svg",
        1024,
        1024,
    )

    preview_00(master, trans_dark, delta, EXPECTED_SHA)
    preview_01(lockups_full)
    preview_02(symbols)
    preview_03(master, crop_rgba)
    preview_04(master)
    preview_05()

    build_brandbook_pdf(
        {
            "master": lockup_master_path,
            "preview01": BRAND / "previews" / "01-lockups.png",
            "preview02": BRAND / "previews" / "02-symbols.png",
            "preview03": BRAND / "previews" / "03-sizes-and-clearspace.png",
            "preview04": BRAND / "previews" / "04-correct-incorrect-use.png",
        },
        delta,
    )

    extra = {
        "transparentRecompositeMaxChannelDelta": delta,
        "symbolCrop": list(SYMBOL_CROP),
        "wordmarkSplitX": SPLIT_X,
        "lightUseAlphaCutoff": LIGHT_USE_ALPHA_CUTOFF,
        "preview03_1280Label": PREVIEW_03_1280_LABEL,
        "webpLosslessMethod": WEBP_LOSSLESS_METHOD,
        "pdfInvariant": 1,
    }
    build_manifest(extra)


if __name__ == "__main__":
    main()
