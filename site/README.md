# site

A single static page for `zkbtc.com`.

## Why this exists

`https://zkbtc.com/` currently answers `301 → /white-paper/`, and that target is a PDF
(`content-type: application/pdf`). A PDF cannot carry Open Graph metadata, so every link to
this domain — on X, Telegram, LinkedIn, WhatsApp — renders without a preview. This page is an
entrance that carries the metadata and points to the paper.

## What is here

| File | Bytes | Role |
| --- | ---: | --- |
| `index.html` | 8,045 | The page. Self-contained: CSS inline, no images, no JavaScript, no external requests. |
| `og.png` | 244,397 | Open Graph preview card, 1200×630. |
| `fonts/*.woff2` | 67,824 | IBM Plex Sans 400 and IBM Plex Mono 400/600/700 — four files, three distinct weights. |
| `fonts/LICENSE.txt` | 4,429 | SIL Open Font License 1.1, under which IBM Plex is distributed. |
| `README.md` | this file | |

Total: 327,584 bytes (320 KiB), of which the card is 75 %.

## Where the text comes from

Every **statement** on the page and on the card is a verbatim quotation from
[`../whitepaper/zkbtc-whitepaper.typ`](../whitepaper/zkbtc-whitepaper.typ). Nothing is
paraphrased, and no condition the paper attaches to a claim has been dropped. Line numbers refer
to that file at commit `bb13a49`; the paper wraps sentences across lines, so a range is given
where a quotation spans several.

| Element | Source | Verbatim? |
| --- | --- | --- |
| `<title>`, `og:title` | line 6 | Yes — the paper's own title. |
| First paragraph, the card, `og:description`, `og:image:alt` | lines 110–112 | Yes, including the conditional `would allow`. |
| Second paragraph | lines 150–151 | Yes. |
| Status line | lines 863–866 | Yes, and it starts one sentence earlier than the obvious cut, at *"The guarantees are conditional on the enumerated assumptions"* — that sentence carries the qualification and is not dropped. The citation marker `[8]` is kept and rendered as a link to the normative specification, so it resolves instead of dangling. |

### Strings that are **not** quotations

These are labels and navigation, and they are listed here so the claim above stays exact:

| String | Where it comes from |
| --- | --- |
| Kicker: `zkBTC is a token standard on the zkCoins transfer system` | Adapted from line 648, which reads `zkBTC is token standard 3 on the zkCoins transfer system`. Two edits: the ordinal `3` is dropped, and the article `a` is inserted to keep the sentence grammatical. The ordinal identifies the standard inside the zkCoins protocol and means nothing to a first-time reader arriving at the domain. This is an adaptation, not a quotation. |
| `zkBTC` (heading and card) | The product name. |
| `Whitepaper (PDF)` | File-type label. |
| `zkBTC Token Standard` | The reference title at lines 898–899 (`"zkBTC token standard"`), in title case. Also used as the `title` and `aria-label` of the `[8]` link. |
| `zkCoins protocol`, `Repository` | Footer link labels. |

## Verification

Measured with headless Chromium against this exact content:

- The page fits without scrolling at 1440×900 and at 375×812.
- No horizontal overflow at 375, 768 or 1440 px.
- The card is exactly 1200×630, has no overflow, no text below 22 px, and keeps at least 64 px
  clear of every edge.
- All four `@font-face` rules declare the weight their file actually contains.
- The card image was decoded and compared against `og:image:alt`; they describe the same text.
- The page contains five links to four distinct targets: `/white-paper/` (same origin), the
  specification (twice — the action and the `[8]` marker), `zkcoins.com`, and the repository.
  All four targets answer `200`.
- `og.png` carries no text, EXIF or XMP chunks; no local paths appear in any file here.

## Deployment

**Not wired up.** This directory is a build-free artifact: serving it means copying these files
to the web root of `zkbtc.com` and removing the `301` that currently sends `/` to the PDF. The
paper must stay reachable at `/white-paper/`, because that is where this page links.

No deployment workflow is included, deliberately: a workflow without credentials would pass
green without publishing anything, which is worse than no workflow at all.
