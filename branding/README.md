# zkBTC branding

The only logo master is the approved PNG copied to [`source/zkbtc-logo-master.png`](source/zkbtc-logo-master.png) (1774×887). SHA-256 `a4cf36c991f6458ef43f94077ff0c4d844855166df2a221715f79405cf3d5131`.

Every lockup, symbol, favicon, social tile, SVG, and PDF is derived from those pixels. Do not draw, trace, typeset, or reconstruct the mark.

The master sits on a **pure black** presentation canvas. The orange architectural Bitcoin-B/Z has two top and two bottom Bitcoin strokes and **subtle internal tonal variation**. That variation is binding. Do not treat the master as a flat-color mark.

Transparent, light-use, and mono files are derived conveniences, not masters. Light-use recolors only the BTC region (`x ≥ 980`): source-derived alpha ≥ 32 becomes near-black with that alpha preserved; alpha below 32 is zeroed as cleanup of subvisible black-canvas noise, not new geometry.

SVG and PDF files are **raster-backed containers**. They embed or place high-resolution PNG art. They are not editable path or vector artwork. PDF writers set invariant metadata so regeneration does not write wall-clock CreationDate/ModDate.

Preview-sheet labels are rendered with bundled Bitstream Vera Sans (`fonts/BitstreamVeraSans.ttf`). Licence: `fonts/LICENSE-BITSTREAM-VERA.txt`. The exporter does not probe system fonts; a missing or unreadable bundled font fails the export.

## Layout

| Path | Role |
| --- | --- |
| `source/` | Raster master |
| `logo/png/` `logo/webp/` | Lockups and symbols |
| `logo/svg/` `logo/pdf/` | Raster-backed containers |
| `favicon/` | ICO and platform icons |
| `social/` | Open Graph and avatars |
| `previews/` | 1600×1000 sheets |
| `fonts/` | Bundled Bitstream Vera Sans and licence |
| `zkbtc-brandbook.pdf` | Multi-page A4 brandbook |
| `asset-manifest.json` | SHA-256 for every generated file |
| `tokens/` | Palette tokens |
| `tools/` | Exporter and verifier |

## Rebuild

```
python3 branding/tools/export_branding.py
python3 branding/tools/verify_branding.py
```

## Honest limitation

Without a true vector master, SVG and PDF remain raster-backed containers. The approved PNG pixels define the artwork.
