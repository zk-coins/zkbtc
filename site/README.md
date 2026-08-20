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
| `index.html` | 7,770 | The page. Self-contained: CSS inline, no images, no JavaScript, no external requests. |
| `og.png` | 244,397 | Open Graph preview card, 1200×630. |
| `fonts/*.woff2` | 67,824 | IBM Plex Sans 400 and IBM Plex Mono 400/600/700 — four files, three distinct weights. |
| `fonts/LICENSE.txt` | 4,429 | SIL Open Font License 1.1, under which IBM Plex is distributed. |
| `README.md` | this file | |

Total: 329,227 bytes (322 KiB), of which the card is 74 %.

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
| Highlighted block | lines 861–863 | Yes — two sentences that stand consecutively in the paper's conclusion, quoted as one block. |

### What the page does not say

The page carries **no statement about the maturity of the design**. It does not claim the design
is implemented, audited or in production, and it does not claim the opposite either. Both
documents it links to state their own status in their own opening: the whitepaper's conclusion
records that the design *"awaits implementation and external audit"*, and the specification's
first status line reads *"Design specification. No code."*

This is deliberate. It is worth knowing when reading the page, and worth re-examining if the
page ever gains a call to action — a page that asks a reader to do something with zkBTC would
need to state the stage the design is at.

### Strings that are **not** quotations

These are labels and navigation, and they are listed here so the claim above stays exact:

| String | Where it comes from |
| --- | --- |
| Kicker: `zkBTC is a token standard on the zkCoins transfer system` | Adapted from line 648, which reads `zkBTC is token standard 3 on the zkCoins transfer system`. Two edits: the ordinal `3` is dropped, and the article `a` is inserted to keep the sentence grammatical. The ordinal identifies the standard inside the zkCoins protocol and means nothing to a first-time reader arriving at the domain. This is an adaptation, not a quotation. |
| `zkBTC` (heading and card) | The product name. |
| `Whitepaper (PDF)` | File-type label. |
| `Read the specification` | Action label. It deliberately does **not** reuse the reference title `zkBTC token standard` from lines 898–899: that phrase reads like a ratified norm, while the document behind the link states `Design specification. No code.` in its own first line. The label describes the action, and the document states its own status. |
| `zkCoins protocol`, `Repository` | Footer link labels. |

## Verification

Measured with headless Chromium against this exact content:

- The page fits without scrolling at 1440×900 and at 375×812.
- No horizontal overflow at 375, 768 or 1440 px.
- The card is exactly 1200×630, has no overflow, no text below 22 px, and keeps at least 64 px
  clear of every edge.
- All four `@font-face` rules declare the weight their file actually contains.
- The card image was decoded and compared against `og:image:alt`; they describe the same text.
- The page contains four links: `/white-paper/` (same origin), the specification, `zkcoins.com`
  and the repository. All four answer `200`.
- `og.png` carries no text, EXIF or XMP chunks; no local paths appear in any file here.

## Deployment

**Not wired up.** This directory is a build-free artifact: serving it means copying these files
to the web root of `zkbtc.com` and removing the `301` that currently sends `/` to the PDF. The
paper must stay reachable at `/white-paper/`, because that is where this page links.

No deployment workflow is included, deliberately: a workflow without credentials would pass
green without publishing anything, which is worse than no workflow at all.
