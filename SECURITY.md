# Security

## Reporting a soundness issue

This repository holds a **design-stage specification**. There is no deployed code and no funds at risk today. The specification can still contain a soundness flaw worth reporting responsibly.

- **Contact:** security@zkcoins.app
- **Do not** open a public GitHub issue for an unpatched soundness flaw.
- **Include in the report:** description, reproduction / argument, and impact assessment.
- **Acknowledgment target:** within 48 hours.
- **Responsible disclosure (90-day policy):** after reporting: (1) confirm the issue within 48 hours, (2) develop and test a fix (here: a specification revision), (3) publish the fix — by default no later than 90 days after the report is acknowledged, or earlier once a specification revision is published, (4) credit the reporter unless they prefer anonymity.
- **Supported version:** only the latest revision on `main` is in scope for security response.

## Scope

| In scope | Out of scope |
| --- | --- |
| Soundness of this repository’s trust model and attack analysis (zkBTC token standard and bridge profile in [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md)). | Underlying **zkCoins protocol** (nullifier accumulator, shielded transfers, token-standard framework) — report to [`zk-coins/docs`](https://github.com/zk-coins/docs) instead. |
| | Underlying **BitVM2** construction itself — upstream of this specification, out of scope here. |

## Known residuals

The design’s own honest residuals and maturity gates are documented in the specification itself — see the **Trust matrix** section and the **Construction decision and maturity gate** section in [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md). This file does not duplicate that material.
