# zkBTC

**A trust-minimized Bitcoin-backed token standard on the zkCoins protocol, with free transfer and gatekeeper-independent redemption.**

**Status:** This repository holds a **design specification** only. There is no implementation code here, the design has not been externally audited, and it is **not production-ready**. The normative document is [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md).

## What zkBTC is

zkBTC is token standard 3 (`issuance_version == 3`) on the zkCoins protocol: an ordinary multi-asset zkCoins coin, verified by the same circuit and nullifier accumulator as every other zkCoins asset.

| Property | Description |
| --- | --- |
| Asset model | Ordinary zkCoins multi-asset coin (REQ-1); same circuit and nullifier accumulator as other zkCoins assets. |
| Free transfer | Once minted, any holder may send zkBTC to any other address without gatekeeper permission, signature, or online cooperation (REQ-2). |
| Permissionless issuance | Anyone may create a zkBTC-style asset and act as a minter. An asset may designate an optional gatekeeper whose per-mint approval is mandatory (REQ-3). Minting economic activity and gatekeeping are separate roles. |
| Reserve construction | BitVM2 — the mainnet-proven BitVM-family fraud-proof verifier (Bitlayer’s BitVM bridge live on mainnet since 2025-07; Citrea’s Clementine bridge live on mainnet since 2026-01). No federation-multisig; no dependency on not-yet-mainnet constructions. Glock, BitVM3, and Mosaic are retained only as possible **future** efficiency upgrades — not launch dependencies. |
| Operator registration | Open, permissionless, per-epoch: anyone may register (bond + pubkey) for a deposit epoch and serve exits, including a holder acting as their own exit agent. No fixed or privileged operator. |
| Optional gatekeeper | Per-asset quality authority at mint: source-of-funds / vault-legitimacy screening, canonical-chain anchor for mint settlement, and vouching for operator-set diversity at mint time. **No role in peg-out.** Cannot freeze circulating coins, block transfers or redemptions, redirect a mint to a different recipient, or unilaterally seize the vault (no gatekeeper key on vault spends). When it performs its R-04/R-08 checks honestly, it also cannot forge an unbacked mint; a compromised or negligent gatekeeper that skips those checks can enable a backing drain (Attack A/B — see "Trust model" below). |
| Redemption | Gatekeeper-independent, open-operator, liveness-bounded (REQ-4): every holder must be able to redeem for on-chain BTC without the gatekeeper’s permission or cooperation. Exit depends only on the liveness of at least one registered operator — never a fixed or privileged operator. No operator can steal under 1-of-N setup honesty, at least one honest, live challenger acting within the challenge window, and sound circuit/graph crypto (a critical soundness bug in the circuit or BitVM2 graph can instead enable theft — see "Costs, limitations, and residual risks"); worst case under those conditions is freeze/burn, not theft. |

## Trust model

A trust-minimized **pooled, cross-graph** zkBTC reserve faces two **independent** backing-drain attacks **at mint settlement** — closing one does not close the other. (These are the mint-side attacks a gatekeeper closes; the redeem side has its own safety conditions — an active honest challenger and the payout-canonicity residual — see "Costs, limitations, and residual risks" below and the specification's Trust matrix.)

| Attack | What goes wrong | How the recommended profile closes it |
| --- | --- | --- |
| **Attack A** — private-fork mint settlement | Nothing purely in-circuit binds a mint’s proof of confirmation to the verifier’s canonical Bitcoin view. A private-fork mint could otherwise be amortized against the shared reserve. | In gatekeeper mode, the gatekeeper acts as **canonical-chain anchor**: it withholds its mint-settlement signature until it has independently verified, on its own canonical Bitcoin view, that the backing transaction and the epoch’s operator-registration commitment are both confirmed. |
| **Attack B** — Sybil-controlled operator epoch | Under open, permissionless operator registration, the circuit alone cannot tell one party’s several keys apart from several independent parties. A single actor could register a self-controlled “epoch” of operators and drain the shared reserve via the ordinary redeem path. | In gatekeeper mode, the gatekeeper refuses to sign a mint unless it has **vouched** that the backing epoch’s operator set contains at least one independent, honest signer. |

**Conclusion the specification draws:** a trust-minimized pooled, cross-graph zkBTC reserve effectively **requires** a gatekeeper (or an equivalent canonical/diversity oracle) to close **both** attacks. That is the recommended zkBTC profile.

- Deploying a pooled, cross-graph reserve with open registration and **no** gatekeeper is explicitly **unsound** and must not be marketed as trust-minimized.
- A closed, genesis-enumerated operator set without a gatekeeper is a distinct, non-default profile: it closes the Sybil attack by construction but remains structurally weak against the private-fork attack. It is **materially weaker**, not a clean alternative.

**Residual in the recommended (gatekeeper-gated) profile:** exit never depends on the gatekeeper — only on at least one registered operator being **live, liquid, and willing to serve**. That operator cannot steal under 1-of-N setup honesty, at least one honest, live challenger actually acting within the challenge window, and sound circuit/graph crypto (see the full trust model in the specification's Trust matrix, and "Costs, limitations, and residual risks" below); the worst case is a freeze/burn of affected deposits (potentially irreversible without a future covenant upgrade — see specification §10.2), not theft. This is a **liveness** dependency on an open, permissionless operator set, not a custody dependency on any single party.

For the full argument, see the specification’s **Trust matrix** and **Gatekeeper model and compliance** sections in [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md).

## Costs, limitations, and residual risks

zkBTC is a design that states its residuals plainly rather than masking them. A fair reader should weigh all of the following before treating it as "just Bitcoin":

- **Conditional guarantees, not unconditional ones.** "No operator can steal" holds only under the full trust model: 1-of-N setup honesty, at least one honest challenger actually acting within each challenge window, and **sound circuit / BitVM2-graph crypto**. A critical soundness bug in the circuit or graph can enable **actual theft** (not just freeze) — which is why an external audit is a launch gate.
- **Operator liveness and cost.** Exit depends on at least one registered operator being live, liquid, and willing to front BTC within the holder's `max_fee`. "Open/permissionless" means anyone *may* serve, not that anyone *will* at a good price; operators lock capital and post bonds, so thin liquidity can make exit slow or expensive.
- **Burn-first redemption.** A redemption **burns the coin first**, then seeks an operator. There is no un-burn: if `max_fee` is set too low or no operator's economics clear it, the burned coin stays unservable until one serves. Set `max_fee` adequately.
- **Gatekeeper is a real trust concentration (in gated mode).** A compromised or negligent gatekeeper that skips its checks can enable a **backing drain of the whole pooled reserve** (Attack A/B), harming holders who never interacted with it — gatekeeper *integrity*, not just liveness, is load-bearing for backing safety. And a gatekeeper that withholds its mint signature **after** the backing transaction has fired can leave a depositor's already-vaulted BTC an irrevocable, consented reserve contribution — a **depositor-side loss-of-funds path** (the depositor's co-signature is what makes it consented).
- **Pooled contagion.** The reserve is pooled and the token is fungible, so a single drained, Sybil, or private-fork vault dilutes **all** holders — not just the counterparty of one deposit.
- **Supply audit is a conditional upper bound.** On-chain, anyone can bound circulating zkBTC by the public vault balance, but only **under** the reserve-safety assumptions above; a successful Attack A/B or an unchallenged fraudulent reimbursement breaks the bound. Exact 1:1 supply is an attestation property, not a pure chain-scan invariant.
- **Irreversibility.** With no security council and no admin keys, **under the trust model above (including sound circuit/graph crypto)** the worst case is a **freeze/burn** of affected deposits (a soundness bug is the separate theft case noted in the first bullet) — potentially **permanent** absent a future covenant soft-fork. "Not theft" does not mean "recoverable."
- **N-of-N minting fragility.** An N-of-N gatekeeper aggregate permanently disables minting of that asset if a single member key is lost (a threshold gatekeeper is recommended); a gatekeeper cannot be rotated in place (rotation = a new asset).
- **Boundary privacy.** Peg-in and peg-out are public Bitcoin events; amounts and timing at the boundary are observable and correlatable, even though internal transfers stay shielded.
- **Bitcoin-layer exposure.** The design assumes a Bitcoin adversary below ~45–50% hashrate over the challenge horizon, deep finality for backing transactions, and that time-sensitive challenge/payout transactions actually confirm in-window — L1 fee spikes, RBF/CPFP/pinning, or miner censorship/MEV that delay a challenge or a payout are an operational risk on the liveness/safety path. On the redeem side there is no external canonical anchor (the gatekeeper is absent from exit by design), so payout canonicity against a deep private fork depends on the challenge comparing most-work chains — an enforcement detail that is an open conversion/audit item, not yet demonstrated.
- **No registration-free exit today.** A holder who never registers as an operator relies on some registered operator to front and reclaim; registration-free unilateral self-reclaim from a pooled vault needs covenant soft-forks not yet on Bitcoin mainnet.
- **Not production-ready.** No implementation code exists, the design is unaudited, and three gates (predicate conversion, open-registration market, external audit) plus the REQ-4 gates must clear first.

## Status and maturity gate

This repository currently contains a design specification only. No implementation code exists here. The design has not been externally audited. It is **not** production-ready.

| Gate | Status |
| --- | --- |
| BitVM2 as the reserve construction | **Cleared.** BitVM2 is mainnet-proven (Bitlayer since 2025-07; Citrea Clementine since 2026-01). |
| (a) Compliance-predicate conversion | **Open.** Convert the zkCoins compliance predicate from its current proving system to a form BitVM2 can verify (a Groth16/SNARK conversion) — an integration engineering gate. |
| (b) Open operator-registration market | **Open.** Instantiate and harden open operator registration (bonding, anti-domination policy, registration ceremony) — a calibration/engineering gate. |
| (c) External audit | **Open.** External audit of the v2 circuit, BitVM2 graph, and pre-signed graphs, published before mainnet — addresses the circuit/graph-soundness class that could otherwise enable theft, before mainnet (sound circuit/graph crypto remains a standing trust assumption even after audit — see specification §4.5 / §5 / §4.6B). |

All three gates must clear before this is a build order. BitVM2 itself is mainnet-proven, and the remaining work — predicate conversion, open-registration hardening, and the external audit — is well-scoped engineering on proven components, not speculative research. That does not make this a build order yet: no code exists here, the design is unaudited, and it is not production-ready until the gates above clear.

Details are in the specification’s **Construction decision and maturity gate** section.

## Repository layout

| Path | Role |
| --- | --- |
| [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md) | **Canonical, single normative** specification for the zkBTC token standard and bridge profile. |
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
