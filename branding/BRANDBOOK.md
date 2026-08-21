# zkBTC brandbook (raster master)

## Master status

The approved PNG is the only logo master. Canonical file: `branding/source/zkbtc-logo-master.png` and `branding/logo/png/lockup/zkbtc-lockup-master-dark-bg.png`. Both are byte-for-byte copies of the approved input (1774×887). SHA-256 `a4cf36c991f6458ef43f94077ff0c4d844855166df2a221715f79405cf3d5131`. Byte diff 0. Decoded pixel diff 0.

Artwork: orange architectural Bitcoin-B/Z with two top and two bottom Bitcoin strokes; orange `zk`; white `BTC`; pure black canvas. Subtle internal tonal variation in the orange is part of the master. There is no flat-color or no-gradient rule on the master.

Do not invent construction coordinates. Geometry, spacing, antialiasing, and color come only from source pixels.

## Logo variants

Whole-canvas lockups at widths 320, 640, 1280, 1774, 2560 (aspect 1774:887). The 1774 dark file is the exact source bytes.

- Dark background: source pixels.
- Transparent dark-use: black converted to alpha (`alpha = max(R,G,B)`; straight RGB `round(channel×255/alpha)`). Full canvas, no crop. Recomposition over pure black matches the source within 1 channel value.
- Transparent light-use: same geometry. x < 980 is unchanged from dark-use (symbol + zk). In the BTC region (x ≥ 980), every pixel with source-derived alpha ≥ 32 is set to near-black RGB with that alpha kept exactly; alpha < 32 is zeroed (RGB and alpha). That cutoff is cleanup of subvisible black-canvas noise so it cannot speckle on warm paper. It is not new geometry.
- Light background: light-use composited on warm paper `#F7F3EA`.
- Mono black / white / orange: exact full-lockup alpha filled with `#0A0A0A`, `#FFFFFF`, `#F7931A`.

## Symbol and avatar

Symbol-only art is the source crop `(220, 180, 610, 715)` only. That box contains the full B/Z including antialiasing and no `zkBTC` wordmark (crop ends before x = 610). Black-to-alpha uses the same method. The crop is fitted proportionally, centered, into a square with 10% padding. Aspect ratio is never altered.

Sizes: 16, 32, 64, 128, 192, 256, 512, 1024. Variants: source-orange transparent, black transparent, white transparent, source-orange on black, source-orange on warm paper, black on warm paper, white on black.

Dark and light avatar tiles center the source-derived symbol.

## Color

| Token | Hex | Role |
| --- | --- | --- |
| Orange anchor | `#F7931A` | Support UI / mono orange |
| Near-black | `#0A0A0A` | Light-use BTC / mono black |
| White | `#FFFFFF` | Mono white |
| Warm paper | `#F7F3EA` | Light surfaces |
| Warm gray | `#D9D2C3` | Support UI |
| Master canvas | `#000000` | Approved presentation canvas |

The master is not a recolor of these swatches. Swatches support UI; the PNG remains authoritative.

## Clear space and minimum size

Keep at least 10% of lockup height empty on every side. Do not crowd the strokes. Prefer lockup width ≥ 320 px and symbol ≥ 32 px for UI; 16 px is favicon-only.

## Formats

PNG and lossless WebP (deterministic `lossless=True`, encoding method 4) for lockups and symbols. Favicon ICO (16, 32, 48, 64, 128, 256), PNG 16/32, Apple 180, Android 192/512. Social 1280×640, 640×320, avatars 1024 and 512. PDF containers use invariant metadata (fixed title/author/subject; no wall-clock dates). Preview `03-sizes-and-clearspace.png` shows 320 and 640 exports at native size and the 1280 export scaled into a labelled slot (`1280×640 export — scaled for sheet`) inside a 40 px outer margin. Preview-sheet labels use bundled Bitstream Vera Sans (`branding/fonts/BitstreamVeraSans.ttf`; licence `branding/fonts/LICENSE-BITSTREAM-VERA.txt`).

SVG wrappers embed a PNG data URI, have no external href, and state: `Raster-backed container; approved PNG master defines the artwork`. PDF logo files place high-resolution raster art. Documentation and `asset-manifest.json` label them `raster-backed-container`.

## Correct use

Use the supplied files. Keep proportions. Use dark lockup on black or very dark surfaces. Use light-bg or transparent-light-use on warm paper. Keep the two top and two bottom strokes visible.

## Incorrect use

Do not rotate, stretch, recolor, outline, add shadows, rearrange `zk`/`BTC`, crop the strokes, or reconstruct the B/Z as vectors. Do not treat SVG/PDF as editable path art. Preview `04-correct-incorrect-use.png` marks transformed prohibited samples.

## Technical verification

`branding/tools/verify_branding.py` asserts source name/hash/dimensions; no `draft`/`reference` filenames; required sizes; exact source/master byte and pixel equality; transparent recomposition max channel delta ≤ 1; real alpha; light-use BTC cutoff; light-bg paper (no dropped-pixel speckle); preview 03 margin and scaled-1280 label; PDF invariant metadata; symbol crop bound; SVG data URIs; manifest hashes; brandbook ≥ 6 pages; bundled Bitstream Vera Sans and licence SHA-256; exporter has no system-font lookup and no `ImageFont.load_default` fallback.

Honest limitation: without a true vector master, SVG and PDF are raster-backed containers.
