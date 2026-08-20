# zkBTC

**A one-to-one Bitcoin-backed token on zkCoins. Effectively trustless: you are an operator. Nobody else is trusted with your bitcoin.**

**Status:** This repository holds a **design specification** only. There is no implementation code here, and it is **not production-ready**. The normative document is [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md).

## In plain terms

zkBTC lets you lock real Bitcoin and receive a private, freely transferable token backed one-for-one by that Bitcoin, and redeem it back into on-chain BTC.

**Effectively trustless — read this once, it does not change.** You do not trust a company, a federation, or a gatekeeper with your bitcoin. You register as an operator. The operator set only grows: new people can join, nobody is removed, and every new vault is signed by *all* current operators, including you. A thief cannot later open a private vault because you would have to co-sign it, and you will not sign a graph that lets them steal. You can also pay yourself out. Join before the first coin of the asset is minted — meaning before that vault's graph is presigned. That is the Attack-B close (a Sybil club draining the pool). Operators still cannot steal only under 1-of-N setup honesty, at least one honest live challenger acting in each window, and sound circuit/graph crypto. A gatekeeper, if an asset has one, only checks *new* deposits; it cannot freeze, seize, or block exit, and it is **not** what makes zkBTC trustless.

The remaining assumptions are listed under **Costs, limitations, and residual risks** below (Bitcoin itself, sound cryptography, a live challenger, and a private-fork mint residual that is the same class of attack as reversing a deeply confirmed Bitcoin payment). This repository is a **design specification** — not production-ready.

## What zkBTC is

zkBTC is token standard 3 (`issuance_version == 3`) on the zkCoins protocol: an ordinary multi-asset zkCoins coin, verified by the same circuit and nullifier accumulator as every other zkCoins asset.

| Property | Description |
| --- | --- |
| Asset model | Ordinary zkCoins multi-asset coin (REQ-1); same circuit and nullifier accumulator as other zkCoins assets. |
| Free transfer | Once minted, any holder may send zkBTC to any other address without gatekeeper permission, signature, or online cooperation (REQ-2). |
| Permissionless issuance | Anyone may create a zkBTC-style asset and act as a minter. An asset may designate an optional gatekeeper whose per-mint approval is mandatory (REQ-3). Minting economic activity and gatekeeping are separate roles. |
| Reserve construction | BitVM2 — the mainnet-proven BitVM-family fraud-proof verifier (Bitlayer’s BitVM bridge live on mainnet since 2025-07; Citrea’s Clementine bridge live on mainnet since 2026-01). No federation-multisig; no dependency on not-yet-mainnet constructions. Glock, BitVM3, and Mosaic are retained only as possible **future** efficiency upgrades — not launch dependencies. |
| Operator registration | Open, permissionless, **growth-only (R-09):** anyone may join the cumulative set S (bond + pubkey) and serve exits, including a holder acting as their own exit agent. Nobody leaves. Every new vault is N-of-N over the current full S. No fixed or privileged operator. Join before the first mint. |
| Optional gatekeeper | Per-asset quality authority at mint only: source-of-funds screening and, when designated, a canonical-chain check for mint settlement (Attack A). **Not the Attack-B close. Not what makes zkBTC trustless. No role in peg-out.** Cannot freeze circulating coins, block transfers or redemptions, redirect a mint, or seize the vault. |
| Redemption | Gatekeeper-independent, open-operator, liveness-bounded (REQ-4): every holder must be able to redeem for on-chain BTC without the gatekeeper’s permission. If you registered, you can front and reclaim your own exit. No operator can steal under 1-of-N setup honesty, at least one honest live challenger acting within the challenge window, and sound circuit/graph crypto; worst case under those conditions is freeze/burn, not theft. |

## How zkBTC is deployed

zkBTC runs as a **single self-contained software package** (one Docker module) that an operator runs alongside the zkCoins software. One-for-one backing is the **bridge** plus the **growth-only operator set (R-09)** — those jobs happen outside the private zkCoins ledger. A **gatekeeper**, if the asset designates one, is optional entry control only: it checks the source of *new* deposits. It is not one of the jobs that 1:1 backing needs, it has no say over coins that already exist, and it cannot freeze, seize, block a transfer, or block a redemption.

On the zkCoins side the package behaves like an ordinary wallet, talking to the same public interface every wallet uses. On the Bitcoin side it behaves like an ordinary Bitcoin service. It never reaches into the trustless zkCoins core: the part of the system that actually holds the balances stays behind that public interface, out of the package's reach, exactly as it does for every other participant.

The token itself is not a separate service: a zkBTC coin is an ordinary zkCoins coin (token standard 3), so what makes it mintable and redeemable lives in zkCoins' shared verification logic next to the other token standards, not in this package.

## Trust model

**Effectively trustless means this, and only this.** You are an operator in the cumulative, growth-only set S **before the first mint** of the asset. You refuse malicious graphs. Operators cannot steal under the conditions below. You can exit yourself. You do not trust a gatekeeper, a federation, or "some other operator" for **safety**.

A pooled, cross-graph zkBTC reserve faces two **independent** backing-drain attacks **at mint settlement** — closing one does not close the other.

| Attack | What goes wrong | How the product closes it |
| --- | --- | --- |
| **Attack B** — Sybil-controlled operator set | A thief registers a private operator club, mints against a real deposit, pre-signs a graph that pays the vault back to themselves, then redeems the fungible tokens against honest vaults. | **R-09.** There is one operator set S. It only grows. Every new vault is signed by all of current S. Once you are in S, a later Sybil club cannot form a vault without you, and you will not co-sign a steal-graph. Join before the first mint. Coins minted *before* you joined are an untrusted prefix (the token is fungible; there is no per-coin provenance). |
| **Attack A** — private-fork mint settlement | Nothing purely in-circuit binds a mint’s proof to the canonical Bitcoin chain. A private-fork mint could otherwise be amortized against the shared reserve. | Independent of R-09. Closed **cleanly** only if a gatekeeper is designated and checks the canonical chain at mint (R-04). Without a gatekeeper this is a **Bitcoin-class residual**, mitigated by ~2016-block deep confirmation — the same kind of attack as reversing a deeply confirmed Bitcoin payment. |

**Do not say:** "zkBTC needs a gatekeeper to be trustless." **Do not say:** "a holder who registered still has to trust some other operator for safety." **Do not ship** open registration + pooled backing **without** R-09 (that profile is unsound).

Exit never depends on a gatekeeper — only on at least one registered operator being **live, liquid, and willing to serve**, which can be you. That operator cannot steal under 1-of-N setup honesty, at least one honest live challenger actually acting within the challenge window, and sound circuit/graph crypto; the worst case is a freeze/burn of affected deposits (potentially irreversible without a future covenant upgrade — see specification §10.2), not theft. This is a **liveness** dependency, not a custody dependency.

For the full argument, see specification §1.1.1, the **Trust matrix**, and **R-09** in [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md).

## Costs, limitations, and residual risks

**When is zkBTC safe, in one sentence?** You joined the cumulative operator set before the first mint and refuse malicious graphs; at least one watchful party reports fraud in time; you (or some registered operator) can process redemptions; the cryptography and Bitcoin transaction graph are sound; and no attacker controls more than roughly half of Bitcoin's hash power (Bitcoin's own "51%" assumption) — if any one of these fails, backing can, in the worst case, be lost. A gatekeeper is not in that **product** sentence (Corner D). When a gatekeeper is designated (Corner A), honest R-04 is an extra Attack-A condition.

zkBTC is a design that states its residuals plainly rather than masking them. A fair reader should weigh all of the following before treating it as "just Bitcoin":

- **Conditional guarantees, not unconditional ones.** "No operator can steal" holds only under its operator-theft conditions: 1-of-N setup honesty, at least one honest challenger actually acting within each challenge window, and **sound circuit / BitVM2-graph crypto**. A critical soundness bug in the circuit or graph can enable **actual theft** (not just freeze). Sound circuit/graph crypto is a standing assumption.
- **Operator liveness and cost.** Exit depends on at least one registered operator being live, liquid, and willing to front BTC within the holder's `max_fee`. "Open/permissionless" means anyone *may* serve, not that anyone *will* at a good price; operators lock capital and post bonds, so thin liquidity can make exit slow or expensive.
- **Burn-first redemption.** A redemption **burns the coin first**, then seeks an operator. There is no un-burn: if `max_fee` is set too low or no operator's economics clear it, the burned coin stays unservable until one serves. Set `max_fee` adequately.
- **Join before the first mint.** If you join after coins already exist, those older coins are only as safe as whoever was already in S. If at least one honest operator (could have been you) has been in S since the first mint, monotonicity carries that honesty forward. If the first mint happened with an all-Sybil S, those prefix coins are fungible poison. Wallets must not construct a deposit unless your operator key is already in S.
- **Dead operators freeze new mints, not old coins.** Because S never shrinks, a lost key that cannot rotate in place stops **new** vaults from forming (N-of-N cannot complete). Coins in already-signed vaults remain exit-able via 1-of-N. Safety over mint liveness.
- **Gatekeeper is optional, and only about new mints.** A designated gatekeeper that skips its canonical-chain check can enable Attack A. It cannot directly forge a vault spend, freeze circulating coins, or block exit. Skipping R-04 can nevertheless enable an Attack-A backing drain. It is **not** the Attack-B close. A gatekeeper that withholds its mint signature **after** the backing transaction has fired can leave a depositor's already-vaulted BTC an irrevocable, consented reserve contribution.
- **Pooled contagion without R-09.** The reserve is pooled and the token is fungible. Without growth-only S, a single Sybil vault dilutes **all** holders. With R-09, that vault cannot be created after an honest operator has joined.
- **Supply audit is a conditional upper bound.** On-chain, anyone can bound circulating zkBTC by the public vault balance, but only **under** the reserve-safety assumptions above; a successful Attack A/B or an unchallenged fraudulent reimbursement breaks the bound. Exact 1:1 supply is an attestation property, not a pure chain-scan invariant.
- **Irreversibility.** With no security council and no admin keys, **under the trust model above (including sound circuit/graph crypto)** the worst case is a **freeze/burn** of affected deposits (a soundness bug is the separate theft case noted in the first bullet) — potentially **permanent** absent a future covenant soft-fork. "Not theft" does not mean "recoverable."
- **N-of-N minting fragility.** An N-of-N gatekeeper aggregate permanently disables minting of that asset if a single member key is lost (a threshold gatekeeper is recommended); a gatekeeper cannot be rotated in place (rotation = a new asset).
- **Boundary privacy.** Peg-in and peg-out are public Bitcoin events; amounts and timing at the boundary are observable and correlatable, even though internal transfers stay shielded.
- **Bitcoin-layer exposure.** The design assumes a Bitcoin adversary below ~45–50% hash power over the challenge/finality horizon. **This is Bitcoin's own base security assumption, inherited — not a zkBTC-specific weakness:** an attacker with majority hash power can already reverse *any* recently confirmed Bitcoin transaction (a deep reorg / the "51% attack"), which breaks Bitcoin payments in general, and zkBTC mitigates it with very deep confirmations (~2016 blocks ≈ two weeks) so the attack becomes **prohibitively costly and, for an attacker comfortably below that threshold, very unlikely to succeed** — deep confirmations lower the success probability and raise the expected cost, but the success probability **rises as the margin to 50% narrows** and the attack is not strictly impossible at a hash-power margin arbitrarily close to 50%. The design also assumes deep finality for backing transactions and that time-sensitive challenge/payout transactions actually confirm in-window — L1 fee spikes, RBF/CPFP/pinning, or miner censorship/MEV that delay a challenge or a payout are an operational risk on the liveness/safety path. On the redeem side there is no external canonical anchor (the gatekeeper is absent from exit by design), so payout canonicity against a deep private fork depends on the challenge comparing most-work chains — an enforcement detail that is an open conversion item, not yet demonstrated.
- **No registration-free exit today.** A holder who never registers as an operator relies on some registered operator to front and reclaim, **and** has no Attack-B guarantee of their own. Registration-free unilateral self-reclaim from a pooled vault needs covenant soft-forks not yet on Bitcoin mainnet. The effectively-trustless path is to register.
- **Not production-ready.** No implementation code exists, and two gates (predicate conversion, open-registration market) plus the REQ-4 gates must clear first.

## Status and maturity gate

This repository currently contains a design specification only. No implementation code exists here. It is **not** production-ready.

| Gate | Status |
| --- | --- |
| BitVM2 as the reserve construction | **Cleared.** BitVM2 is mainnet-proven (Bitlayer since 2025-07; Citrea Clementine since 2026-01). |
| (a) Compliance-predicate conversion | **Open.** Convert the zkCoins compliance predicate from its current proving system to a form BitVM2 can verify (a Groth16/SNARK conversion) — an integration engineering gate. |
| (b) Open operator-registration market | **Open.** Instantiate and harden open, **growth-only** operator registration (R-09: identity set, no leave, identity-bound epoch signing keys, bonding, anti-domination, ceremony) — a calibration/engineering gate. |

Both remaining gates must clear before this is a build order. BitVM2 itself is mainnet-proven, and the remaining work — predicate conversion and open-registration hardening — is well-scoped engineering on proven components, not speculative research. That does not make this a build order yet: no code exists here, and it is not production-ready until the gates above clear.

Details are in the specification’s **Construction decision and maturity gate** section. Holder self-registration before the first mint is the numbered procedure in specification **§4.1.3**; that section documents onboarding and does not claim the open-registration market is operational.

## Repository layout

| Path | Role |
| --- | --- |
| [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md) | **Canonical, single normative** specification for the zkBTC token standard and bridge profile. |
| [`whitepaper/zkbtc-whitepaper.pdf`](./whitepaper/zkbtc-whitepaper.pdf) | English whitepaper (nine pages) introducing zkBTC and the zkCoins transfer layer it builds on, structured after the Bitcoin whitepaper. **Informative only — not normative**: where it simplifies, the specification governs. Typst source: [`whitepaper/zkbtc-whitepaper.typ`](./whitepaper/zkbtc-whitepaper.typ) (`typst compile`). |
| [`whitepaper/zkbtc-whitepaper.de.pdf`](./whitepaper/zkbtc-whitepaper.de.pdf) | German translation of the same paper. Same status (informative only). Typst source: [`whitepaper/zkbtc-whitepaper.de.typ`](./whitepaper/zkbtc-whitepaper.de.typ). |
| [`CONTRIBUTING.md`](./CONTRIBUTING.md) | How to propose changes and the spec-conformance rules. |
| [`SECURITY.md`](./SECURITY.md) | Responsible disclosure for soundness issues. |
| [`LICENSE`](./LICENSE) | MIT license. |

## Related repositories

| Repository | URL | Relationship |
| --- | --- | --- |
| `zk-coins/docs` | https://github.com/zk-coins/docs | zkCoins protocol specification (shielded transfers over Bitcoin, nullifier accumulator, token-standard framework) that zkBTC, as token standard 3, builds on. |
| `zk-coins/research` | https://github.com/zk-coins/research | Protocol research: BitVM2 / BitVM3 / Glock / Citrea landscape analysis and prior zkBTC design drafts that this specification supersedes and cites. |

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to propose specification changes and the load-bearing conformance rules.

## Security

See [SECURITY.md](./SECURITY.md) for how to report soundness issues in this design specification.

## License

MIT — see the [`LICENSE`](./LICENSE) file.
