# site

A single static page for `zkbtc.com`.

## Why this exists

`https://zkbtc.com/` currently answers `301 → /white-paper/`, and that target is a PDF
(`content-type: application/pdf`). A PDF cannot carry Open Graph metadata, so every link to
this domain — on X, Telegram, LinkedIn, WhatsApp — renders without a preview. This page is an
entrance that carries the metadata and points to the paper.

## What is here

| File | Role |
| --- | --- |
| `index.html` | The page. Self-contained: CSS inline, SVG inline, no external requests, no JavaScript. |
| `og.png` | Open Graph preview card, 1200×630. |
| `fonts/` | IBM Plex Sans and IBM Plex Mono, subset to the four weights the page uses. |
| `fonts/LICENSE.txt` | SIL Open Font License 1.1, under which IBM Plex is distributed. |

Total: 312 KB.

## Where the text comes from

Every statement on the page and on the card is a verbatim quotation from
[`../whitepaper/zkbtc-whitepaper.typ`](../whitepaper/zkbtc-whitepaper.typ). Nothing is
paraphrased, summarised, or simplified, and no condition attached to a claim in the paper has
been dropped.

| Element | Source line | Note |
| --- | --- | --- |
| `<title>`, `og:title` | 6 | The paper's own title. |
| Kicker | 648–649 | `zkBTC is token standard 3 on the zkCoins transfer system` — the ordinal `3` is omitted, as it is an internal identifier (`issuance_version == 3`) and carries no meaning for a first-time reader. |
| First paragraph, and the card | 110–112 | Verbatim, including `would allow` — the paper's conditional phrasing is preserved. |
| Second paragraph | 150–151 | Verbatim. |
| Status line | 862–864 | Verbatim, including the citation marker `[8]`, which is rendered as a link to the normative specification. |
| `og:description`, `og:image:alt` | 110–112 | Same sentence as the card, so the alt text describes what the image actually shows. |

The two action labels are the only strings that are not quotations: `Whitepaper (PDF)` is a
file-type label, and `zkBTC Token Standard` is the reference title from line 896–897 in title
case.

## Verification

Measured with headless Chromium at the time of writing:

- The page fits without scrolling at 1440×900 and at 375×812.
- No horizontal overflow at 375, 768 or 1440 px.
- The card is exactly 1200×630, has no overflow, no text below 22 px, and keeps at least 64 px
  clear of every edge.
- All four outbound links answer `200`.

## Deployment

**Not wired up.** This directory is a build-free artifact: serving it means copying these files
to the web root of `zkbtc.com` and removing the `301` that currently sends `/` to the PDF. The
paper must stay reachable at `/white-paper/`, because that is where this page links.

No deployment workflow is included, deliberately: a workflow without credentials would pass
green without publishing anything, which is worse than no workflow at all.
