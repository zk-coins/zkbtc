# Contributing

This repository’s main artifact is the zkBTC design specification. Contributing here mostly means proposing changes to [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md). There is no application code in this repository.

## Proposing changes

- Work on a feature branch and open a pull request into `main`.
- Keep each PR focused on one concern.
- The specification is the **single canonical file** for the whole token standard and bridge profile. That is deliberate: one file, all standards — consistent with a single-source-of-truth philosophy.
- Do not push directly to `main`.

## Spec-conformance rule

The specification establishes its own load-bearing invariants: the two-attack decomposition (Attack A / Attack B — private-fork mint settlement and Sybil-controlled operator epoch), the specific findings that close them, the gatekeeper-independent-exit requirement, and the three-class deployment taxonomy of the different operator-registration / gatekeeper combinations (**recommended** = Corner A / **materially weaker, not clean** = Corner B / **UNSOUND** = Corner C — §6.4).

- Any change to the trust model, or to a load-bearing invariant (a finding that closes one of the two attacks, the gatekeeper-independent-exit requirement, or the three-class deployment classification of a deployment profile), **must** be justified **explicitly in the specification itself** and **must** go through **adversarial review** — a human reviewer with a security background actively trying to find a way the change reopens a closed attack or weakens a stated guarantee. These invariants must never be silently weakened, softened, or dropped.
- A change that removes or loosens a normative MUST / MUST NOT, narrows a stated residual, or reclassifies a deployment profile between any of the three classes (recommended / materially-weaker / unsound) is a **security-relevant** change. Treat it with the same scrutiny as a change to a cryptographic protocol — not as an editorial tweak.
- Purely editorial changes (typos, formatting, clarifying prose that does not change normative meaning) do not need this level of scrutiny.

## How to approach this repository

Guidance for anyone approaching this repository for the first time:

1. **Read the full specification** before proposing any change, in particular the requirements, the construction decision and maturity gate, the trust matrix, and the gatekeeper model sections in [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md).
2. **Preserve normative keywords** MUST, MUST NOT, SHOULD, and MAY exactly as used in the specification (RFC 2119 usage). Do not soften or strengthen a normative keyword without an explicit, justified reason recorded in the specification’s own change log.
3. **Preserve finding-ID and requirement tags verbatim** (for example REQ-1 through REQ-4, and the lettered/numbered finding IDs used throughout the document). They are cross-referenced throughout the specification and in any future review; renaming or dropping one silently breaks that traceability.
4. **Update the specification’s own change log** for every substantive change, in the same pull request that makes the change.

## Commit and PR conventions

- Write clear English commit messages that describe the change **and its rationale** — not just “update spec”.
- Use signed commits.
- Do not push directly to `main`; all changes land via pull request.
