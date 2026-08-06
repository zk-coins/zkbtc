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
| Redemption | Gatekeeper-independent, open-operator, liveness-bounded (REQ-4): every holder must be able to redeem for on-chain BTC without the gatekeeper’s permission or cooperation. Exit depends only on the liveness of at least one registered operator — never a fixed or privileged operator. No operator can steal under 1-of-N setup honesty plus at least one honest, live challenger acting within the challenge window; worst case is freeze/burn, not theft. |

## Trust model

A trust-minimized **pooled, cross-graph** zkBTC reserve faces two **independent** backing-drain attacks. Closing one does not close the other.

| Attack | What goes wrong | How the recommended profile closes it |
| --- | --- | --- |
| **Attack A** — private-fork mint settlement | Nothing purely in-circuit binds a mint’s proof of confirmation to the verifier’s canonical Bitcoin view. A private-fork mint could otherwise be amortized against the shared reserve. | In gatekeeper mode, the gatekeeper acts as **canonical-chain anchor**: it withholds its mint-settlement signature until it has independently verified, on its own canonical Bitcoin view, that the backing transaction and the epoch’s operator-registration commitment are both confirmed. |
| **Attack B** — Sybil-controlled operator epoch | Under open, permissionless operator registration, the circuit alone cannot tell one party’s several keys apart from several independent parties. A single actor could register a self-controlled “epoch” of operators and drain the shared reserve via the ordinary redeem path. | In gatekeeper mode, the gatekeeper refuses to sign a mint unless it has **vouched** that the backing epoch’s operator set contains at least one independent, honest signer. |

**Conclusion the specification draws:** a trust-minimized pooled, cross-graph zkBTC reserve effectively **requires** a gatekeeper (or an equivalent canonical/diversity oracle) to close **both** attacks. That is the recommended zkBTC profile.

- Deploying a pooled, cross-graph reserve with open registration and **no** gatekeeper is explicitly **unsound** and must not be marketed as trust-minimized.
- A closed, genesis-enumerated operator set without a gatekeeper is a distinct, non-default profile: it closes the Sybil attack by construction but remains structurally weak against the private-fork attack. It is **materially weaker**, not a clean alternative.

**Residual in the recommended (gatekeeper-gated) profile:** exit never depends on the gatekeeper — only on at least one registered operator being online. That operator cannot steal under 1-of-N setup honesty plus at least one honest, live challenger actually acting within the challenge window; the worst case is a freeze/burn of affected deposits (potentially irreversible without a future covenant upgrade — see specification §10.2), not theft. This is a **liveness** dependency on an open, permissionless operator set, not a custody dependency on any single party.

For the full argument, see the specification’s **Trust matrix** and **Gatekeeper model and compliance** sections in [`spec/ZKBTC_TOKEN.md`](./spec/ZKBTC_TOKEN.md).

## Status and maturity gate

This repository currently contains a design specification only. No implementation code exists here. The design has not been externally audited. It is **not** production-ready.

| Gate | Status |
| --- | --- |
| BitVM2 as the reserve construction | **Cleared.** BitVM2 is mainnet-proven (Bitlayer since 2025-07; Citrea Clementine since 2026-01). |
| (a) Compliance-predicate conversion | **Open.** Convert the zkCoins compliance predicate from its current proving system to a form BitVM2 can verify (a Groth16/SNARK conversion) — an integration engineering gate. |
| (b) Open operator-registration market | **Open.** Instantiate and harden open operator registration (bonding, anti-domination policy, registration ceremony) — a calibration/engineering gate. |
| (c) External audit | **Open.** External audit of the v2 circuit, BitVM2 graph, and pre-signed graphs, published before mainnet — closes the circuit/graph-soundness class that can otherwise enable theft (see specification §4.5 / §4.6B). |

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
