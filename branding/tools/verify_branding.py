#!/usr/bin/env python3
"""Independent fail-loud verifier for the zkBTC raster-master brand package."""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFont

# Independent copies of exporter constants and derivation math.
# This module must not import export_branding.
LIGHT_USE_ALPHA_CUTOFF = 32
NEAR_BLACK = (10, 10, 10)
PREVIEW_03_1280_LABEL = "1280×640 export — scaled for sheet"
PREVIEW_03_BG = (14, 14, 14)
PREVIEW_MARGIN = 40
SPLIT_X = 980
WARM_PAPER = (247, 243, 234)
INVARIANT_PDF_DATE = b"D:20000101000000+00'00'"

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "branding"
SOURCE = BRAND / "source" / "zkbtc-logo-master.png"
EXPECTED_SHA = "a4cf36c991f6458ef43f94077ff0c4d844855166df2a221715f79405cf3d5131"
EXPECTED_SIZE = (1774, 887)
BUNDLED_FONT = BRAND / "fonts" / "BitstreamVeraSans.ttf"
BUNDLED_FONT_LICENSE = BRAND / "fonts" / "LICENSE-BITSTREAM-VERA.txt"
EXPECTED_FONT_SHA = "c4c45690b345435b2cba52ecabe275f05e49b389b39fe68ad03afbb551288d3d"
EXPECTED_FONT_LICENSE_SHA = "3361d054759a2fc686a2c058be82deaf9c2e6fe549be9004d7935a6c1736315d"
EXPORTER = BRAND / "tools" / "export_branding.py"
SYSTEM_FONT_NEEDLES = (
    "/System/Library/Fonts",
    "/Library/Fonts/",
    "/usr/share/fonts",
    "/usr/local/share/fonts",
    "C:\\Windows\\Fonts",
    "C:/Windows/Fonts",
    "Arial.ttf",
    "Helvetica.ttc",
)
SYMBOL_CROP = (220, 180, 610, 715)
LOCKUP_WIDTHS = (320, 640, 1280, 1774, 2560)
SYMBOL_SIZES = (16, 32, 64, 128, 192, 256, 512, 1024)
LOCKUP_VARIANTS = (
    "dark-bg",
    "light-bg",
    "transparent-dark-use",
    "transparent-light-use",
    "mono-black",
    "mono-white",
    "mono-orange",
)
ERRORS: list[str] = []


def err(msg: str) -> None:
    ERRORS.append(msg)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def require(path: Path) -> None:
    if not path.is_file():
        err(f"missing file: {path.relative_to(ROOT)}")


def pixel_equal(a: Image.Image, b: Image.Image) -> bool:
    if a.size != b.size:
        return False
    return np.array_equal(np.asarray(a.convert("RGB")), np.asarray(b.convert("RGB")))


def max_channel_delta(a: Image.Image, b: Image.Image) -> int:
    aa = np.asarray(a.convert("RGB"), dtype=np.int16)
    bb = np.asarray(b.convert("RGB"), dtype=np.int16)
    return int(np.abs(aa - bb).max())


def composite_on(rgba: Image.Image, bg: tuple[int, int, int]) -> Image.Image:
    base = Image.new("RGB", rgba.size, bg)
    base.paste(rgba, mask=rgba.split()[3])
    return base


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
    del src_rgb
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


def composite_on_black(rgba: Image.Image) -> Image.Image:
    return composite_on(rgba, (0, 0, 0))


def _pdf_info_date(raw: bytes, key: bytes) -> bytes | None:
    m = re.search(re.escape(key) + rb"\s*\(([^)]*)\)", raw)
    if not m:
        return None
    return m.group(1)


def pdf_has_wallclock_date(raw: bytes) -> bool:
    """True unless both /CreationDate and /ModDate equal the invariant stamp."""
    creation = _pdf_info_date(raw, b"/CreationDate")
    mod = _pdf_info_date(raw, b"/ModDate")
    return creation != INVARIANT_PDF_DATE or mod != INVARIANT_PDF_DATE


def main() -> int:
    # source
    if SOURCE.name != "zkbtc-logo-master.png":
        err(f"source name {SOURCE.name}")
    if not SOURCE.is_file():
        err("source missing")
        print("FAIL")
        return 1
    digest = sha256_file(SOURCE)
    if digest != EXPECTED_SHA:
        err(f"source sha {digest} != {EXPECTED_SHA}")
    src = Image.open(SOURCE)
    if src.size != EXPECTED_SIZE:
        err(f"source size {src.size}")

    # filenames
    for p in BRAND.rglob("*"):
        if p.is_file():
            name = p.name.lower()
            if "draft" in name or "reference" in name:
                err(f"forbidden filename: {p}")

    master = BRAND / "logo" / "png" / "lockup" / "zkbtc-lockup-master-dark-bg.png"
    require(master)
    if master.is_file():
        if master.read_bytes() != SOURCE.read_bytes():
            err("master-dark-bg is not byte-identical to source")
        if sha256_file(master) != EXPECTED_SHA:
            err("master sha mismatch")
        im = Image.open(master)
        if not pixel_equal(im, src):
            err("master decoded pixels differ from source")

    w1774 = BRAND / "logo" / "png" / "lockup" / "zkbtc-lockup-dark-bg-1774.png"
    require(w1774)
    if w1774.is_file() and w1774.read_bytes() != SOURCE.read_bytes():
        err("dark-bg-1774 is not exact source bytes")

    for variant in LOCKUP_VARIANTS:
        for w in LOCKUP_WIDTHS:
            h = int(round(887 * (w / 1774)))
            if variant == "dark-bg":
                png = BRAND / "logo" / "png" / "lockup" / f"zkbtc-lockup-dark-bg-{w}.png"
            else:
                png = BRAND / "logo" / "png" / "lockup" / f"zkbtc-lockup-{variant}-{w}.png"
            require(png)
            if png.is_file():
                im = Image.open(png)
                if im.size != (w, h):
                    err(f"{png.name} size {im.size} != {(w, h)}")
            webp = BRAND / "logo" / "webp" / "lockup" / f"zkbtc-lockup-{variant}-{w}.webp"
            require(webp)

    # transparent recomposition
    trans = BRAND / "logo" / "png" / "lockup" / "zkbtc-lockup-transparent-dark-use-1774.png"
    require(trans)
    if trans.is_file():
        t = Image.open(trans).convert("RGBA")
        extrema = t.getextrema()
        a_min, a_max = extrema[3]
        if a_min == 255 and a_max == 255:
            err("transparent lockup has no real alpha")
        if a_max == 0:
            err("transparent lockup fully transparent")
        recon = composite_on_black(t)
        d = max_channel_delta(src.convert("RGB"), recon)
        if d > 1:
            err(f"recomposite max channel delta {d} > 1")
        # independent recompute
        indep = to_rgba_straight_from_black(src)
        d2 = max_channel_delta(composite_on_black(indep), recon)
        if d2 > 1:
            err(f"independent alpha path delta {d2}")

        light_p = BRAND / "logo" / "png" / "lockup" / "zkbtc-lockup-transparent-light-use-1774.png"
        require(light_p)
        if light_p.is_file():
            light = Image.open(light_p).convert("RGBA")
            expected = light_use_from_transparent(src.convert("RGB"), t)
            if not np.array_equal(np.asarray(light), np.asarray(expected)):
                err("transparent-light-use-1774 does not match cutoff recolor")
            la = np.asarray(light)
            src_a = np.asarray(t)[:, :, 3]
            left = la[:, :SPLIT_X, :]
            right = la[:, SPLIT_X:, :]
            src_right_a = src_a[:, SPLIT_X:]
            if not np.array_equal(left, np.asarray(t)[:, :SPLIT_X, :]):
                err("light-use x<980 differs from transparent dark-use")
            low = src_right_a < LIGHT_USE_ALPHA_CUTOFF
            high = ~low
            if np.any(right[low][:, 3] != 0):
                err("light-use BTC alpha<32 not fully transparent")
            if np.any(right[low][:, :3] != 0):
                err("light-use BTC alpha<32 RGB not zero")
            if np.any(right[high][:, 3] != src_right_a[high]):
                err("light-use BTC alpha>=32 alpha changed")
            rgb_high = right[high][:, :3]
            if rgb_high.size and not np.all(rgb_high == np.array(NEAR_BLACK, dtype=np.uint8)):
                err("light-use BTC alpha>=32 RGB not near-black")

        light_bg_p = BRAND / "logo" / "png" / "lockup" / "zkbtc-lockup-light-bg-1774.png"
        require(light_bg_p)
        if light_bg_p.is_file() and light_p.is_file():
            bg = np.asarray(Image.open(light_bg_p).convert("RGB"))
            light_arr = np.asarray(Image.open(light_p).convert("RGBA"))
            paper = np.array(WARM_PAPER, dtype=np.uint8)
            drop = (light_arr[:, SPLIT_X:, 3] == 0)
            region = bg[:, SPLIT_X:, :]
            if np.any(region[drop] != paper):
                err("light-bg speckle: dropped BTC-region pixels are not warm paper")

    # symbol crop bound
    if SYMBOL_CROP[2] > 610:
        err("symbol crop right edge exceeds 610")
    if SYMBOL_CROP[2] > 980:
        err("symbol crop would include wordmark")
    crop = src.crop(SYMBOL_CROP)
    if crop.size[0] <= 0:
        err("empty crop")

    for size in SYMBOL_SIZES:
        for name in (
            "source-orange-transparent",
            "black-transparent",
            "white-transparent",
            "source-orange-on-black",
            "source-orange-on-warm-paper",
            "black-on-warm-paper",
            "white-on-black",
        ):
            png = BRAND / "logo" / "png" / "symbol" / f"zkbtc-symbol-{name}-{size}.png"
            require(png)
            if png.is_file():
                im = Image.open(png)
                if im.size != (size, size):
                    err(f"{png.name} size {im.size}")
            require(BRAND / "logo" / "webp" / "symbol" / f"zkbtc-symbol-{name}-{size}.webp")

    # SVG
    svgs = list((BRAND / "logo" / "svg").rglob("*.svg"))
    if len(svgs) < 16:
        err(f"expected >=16 svg, got {len(svgs)}")
    for svg in svgs:
        text = svg.read_text(encoding="utf-8")
        if "data:image/png;base64," not in text:
            err(f"{svg.name} missing embedded png data uri")
        if re.search(r'''(?:xlink:)?href=["']https?://''', text):
            err(f"{svg.name} contains external URL")
        if re.search(r'''(?:xlink:)?href=["'](?!data:)''', text):
            err(f"{svg.name} external href")
        if "editable" in text.lower() or "vector art" in text.lower():
            err(f"{svg.name} claims vector/editable art")
        if "Raster-backed container; approved PNG master defines the artwork" not in text:
            err(f"{svg.name} missing raster-backed title/metadata")

    # favicons
    for s in (16, 32, 48, 64, 128, 256):
        require(BRAND / "favicon" / f"zkbtc-icon-{s}.png")
    require(BRAND / "favicon" / "zkbtc.ico")
    require(BRAND / "favicon" / "favicon.ico")
    require(BRAND / "favicon" / "favicon-16.png")
    require(BRAND / "favicon" / "favicon-32.png")
    require(BRAND / "favicon" / "apple-touch-icon-180.png")
    require(BRAND / "favicon" / "android-chrome-192.png")
    require(BRAND / "favicon" / "android-chrome-512.png")

    # social
    for p in (
        "zkbtc-og-dark-1280x640.png",
        "zkbtc-og-light-1280x640.png",
        "zkbtc-og-dark-640x320.png",
        "zkbtc-og-light-640x320.png",
        "zkbtc-avatar-dark-1024.png",
        "zkbtc-avatar-light-1024.png",
        "zkbtc-avatar-dark-512.png",
        "zkbtc-avatar-light-512.png",
    ):
        fp = BRAND / "social" / p
        require(fp)
        if fp.is_file():
            im = Image.open(fp)
            if "1280x640" in p and im.size != (1280, 640):
                err(f"{p} {im.size}")
            if "640x320" in p and im.size != (640, 320):
                err(f"{p} {im.size}")
            if p.endswith("1024.png") and im.size != (1024, 1024):
                err(f"{p} {im.size}")
            if p.endswith("512.png") and im.size != (512, 512):
                err(f"{p} {im.size}")

    for p in (
        "00-master-fidelity.png",
        "01-lockups.png",
        "02-symbols.png",
        "03-sizes-and-clearspace.png",
        "04-correct-incorrect-use.png",
        "05-file-map.png",
    ):
        fp = BRAND / "previews" / p
        require(fp)
        if fp.is_file() and Image.open(fp).size != (1600, 1000):
            err(f"{p} not 1600x1000")
        if p == "03-sizes-and-clearspace.png" and fp.is_file():
            im = Image.open(fp)
            if im.info.get("preview03_1280_label") != PREVIEW_03_1280_LABEL:
                err("preview 03 missing scaled 1280 label metadata")
            arr = np.asarray(im.convert("RGB"))
            bg = np.array(PREVIEW_03_BG, dtype=np.uint8)
            h, w, _ = arr.shape
            m = PREVIEW_MARGIN
            outer = np.ones((h, w), dtype=bool)
            outer[m : h - m, m : w - m] = False
            if np.any(arr[outer] != bg):
                err("preview 03 has non-background pixels outside 40px margin")

    pdf = BRAND / "zkbtc-brandbook.pdf"
    require(pdf)
    if pdf.is_file():
        raw = pdf.read_bytes()
        pages = raw.count(b"/Type /Page") - raw.count(b"/Type /Pages")
        if pages < 6:
            # fallback: count page objects
            pages = len(re.findall(rb"/Type\s*/Page\b", raw))
        if pages < 6:
            err(f"brandbook pages {pages} < 6")
        if b"raster-backed" not in raw.lower() and b"Raster-backed" not in raw:
            err("brandbook missing raster-backed language")
        if pdf_has_wallclock_date(raw):
            err("brandbook PDF has wall-clock CreationDate/ModDate")
        if b"/Title" not in raw:
            err("brandbook PDF missing title metadata")

    for pdfp in sorted((BRAND / "logo" / "pdf").rglob("*.pdf")):
        rawp = pdfp.read_bytes()
        if pdf_has_wallclock_date(rawp):
            err(f"{pdfp.name} has wall-clock CreationDate/ModDate")
        if b"Raster-backed container" not in rawp:
            err(f"{pdfp.name} missing raster-backed title")

    for variant in ("dark-bg", "light-bg", "mono-black", "mono-white", "mono-orange"):
        require(BRAND / "logo" / "pdf" / "lockup" / f"zkbtc-lockup-{variant}.pdf")
    for name in (
        "source-orange-transparent",
        "black-transparent",
        "white-transparent",
    ):
        require(BRAND / "logo" / "pdf" / "symbol" / f"zkbtc-symbol-{name}.pdf")

    man_path = BRAND / "asset-manifest.json"
    require(man_path)
    if man_path.is_file():
        man = json.loads(man_path.read_text(encoding="utf-8"))
        files = {e["path"]: e for e in man["files"]}
        for p in BRAND.rglob("*"):
            if not p.is_file():
                continue
            rel = str(p.relative_to(ROOT)).replace("\\", "/")
            if rel.endswith("asset-manifest.json"):
                continue
            if rel not in files:
                err(f"manifest missing {rel}")
                continue
            got = sha256_file(p)
            if files[rel]["sha256"] != got:
                err(f"manifest hash mismatch {rel}")
        kinds = {e["kind"] for e in man["files"]}
        for k in ("raster-master", "raster-derived", "raster-backed-container"):
            if k not in kinds:
                err(f"manifest missing kind {k}")

    require(BRAND / "README.md")
    require(BRAND / "BRANDBOOK.md")
    require(BRAND / "tokens" / "tokens.json")
    require(BRAND / "tokens" / "tokens.css")

    require(BUNDLED_FONT)
    require(BUNDLED_FONT_LICENSE)
    if BUNDLED_FONT.is_file():
        font_digest = sha256_file(BUNDLED_FONT)
        if font_digest != EXPECTED_FONT_SHA:
            err(f"bundled font sha {font_digest} != {EXPECTED_FONT_SHA}")
        try:
            ImageFont.truetype(str(BUNDLED_FONT), 16)
        except OSError as exc:
            err(f"bundled font unreadable: {exc}")
    if BUNDLED_FONT_LICENSE.is_file():
        license_digest = sha256_file(BUNDLED_FONT_LICENSE)
        if license_digest != EXPECTED_FONT_LICENSE_SHA:
            err(
                f"bundled font licence sha {license_digest} != {EXPECTED_FONT_LICENSE_SHA}"
            )

    require(EXPORTER)
    if EXPORTER.is_file():
        exporter_src = EXPORTER.read_text(encoding="utf-8")
        if "ImageFont.load_default" in exporter_src:
            err("exporter contains ImageFont.load_default fallback")
        for needle in SYSTEM_FONT_NEEDLES:
            if needle in exporter_src:
                err(f"exporter contains system-font path {needle}")
        if "BitstreamVeraSans.ttf" not in exporter_src:
            err("exporter does not reference bundled BitstreamVeraSans.ttf")
        if "fonts/BitstreamVeraSans.ttf" not in exporter_src.replace("\\", "/"):
            err("exporter does not pin preview text to branding/fonts/BitstreamVeraSans.ttf")

    if ERRORS:
        print("FAIL")
        for e in ERRORS:
            print(" -", e)
        return 1
    print("PASS")
    print(f"source_sha={digest}")
    print("byte_diff=0")
    print("pixel_diff=0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
