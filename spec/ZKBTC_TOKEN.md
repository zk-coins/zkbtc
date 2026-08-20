# zkBTC — Permissionless Deposit-Backed Redeemable BTC on zkCoins (Optional Gatekeeper)

**Status:** Design specification. No code. **Buildable on today's Bitcoin — no soft-fork.** The normative fraud-proof verifier is **BitVM2** (mainnet-proven; reference exemplar: Citrea Clementine, live since 2026-01; Bitlayer BitVM bridge mainnet since 2025-07). Remaining work is **three gates**: (a) the **Plonky2 → BitVM2 (SNARK/Groth16) conversion of the zkCoins compliance predicate** (§4.0 / §4.6B / G3), (b) instantiating and hardening the **open operator-registration market** (policy encoding, bond / anti-domination calibration, `reg_root_E` format, ceremony robustness — semantic requirements in §4.1.2; calibration still open per §11 / §4.6A), and (c) an **external audit of the v2 circuit, BitVM2 graph, and pre-signed graphs** (§4.6B). All three gates, plus §4.6A REQ-4 gates, **MUST** clear. zkBTC is a substantial engineering project (Citrea-class, order of months) built on **proven** components — not speculative research and not contingent on any not-yet-mainnet construction. Glock / BitVM3 / Mosaic are retained only as **§10 future efficiency upgrades** (BitVM3/Mosaic/Argo preserve permissionless challenge; Glock carries a designated-verifier trade-off — §10.1).

**Authoritative source for:** the zkBTC token standard (token standard 3, `issuance_version == 3`) and the zkBTC bridge profile (permissionless minting with optional gatekeeper quality control at peg-in; gatekeeper-independent peg-out).

**Audience:** protocol engineers and organisations evaluating zkBTC deployment (as minters, optional gatekeepers, or operators).

**Supersedes:**
- [`BRIDGE_MVP.md`](https://github.com/zk-coins/research/blob/develop/zkcoins-design/BRIDGE_MVP.md) (in `zk-coins/research`) §4 / §6.3 (separate `IssuanceProof` / `BurnProof` ProofTypes and global `peg_in_consumed_smt` / `burned_coins_smt` — incompatible with the post-#97 nullifier model, with specification.md §6.5's version-branch dispatch, and with specification.md §2.2's single-circuit rule);
- the `IssuanceTerms_v2_glock_bridged` sketch in [`bitvm-bridge-research.md`](https://github.com/zk-coins/research/blob/develop/bitvm-bridge-research.md) (in `zk-coins/research`; issuer-less, and `issuance_version == 2` is now the capped-supply standard in specification.md §6.5);
- the single-issuer framing of earlier drafts of this document (replaced by permissionless issuance with an optional mint gatekeeper — §1.1 REQ-3, §6).

**Note:** Written against zk-coins/docs `develop` @ e3b5d04 (post-#97 on-chain nullifier `(Pkᵢ, Rᵢ)`, half-aggregation, v1 freeze). Normative keywords (**MUST**, **MUST NOT**, **SHOULD**, **MAY**) follow RFC 2119. The June-2026 Glock-path decision recorded in [`bitvm-bridge-research.md`](https://github.com/zk-coins/research/blob/develop/bitvm-bridge-research.md) (in `zk-coins/research`) is **historical** and is superseded by the works-today BitVM2 decision (§4.0); Glock remains only as a §10.1 efficiency-upgrade option.

---

## 1. Requirements and scope

### 1.1 Product requirements

| ID | Requirement |
|----|-------------|
| **REQ-1** | zkBTC is a zkCoins asset: an ordinary multi-asset coin under the protocol's `asset_id` model, verified by the same circuit `C` and nullifier accumulator as every other asset. |
| **REQ-2** | Free transfer: once minted, any holder **MAY** send zkBTC to any other address without gatekeeper permission, signature, or online cooperation. |
| **REQ-3** | **Permissionless issuance with an optional mint gatekeeper.** Anyone **MAY** create a zkBTC-style asset and act as a **minter**. An asset **MAY** designate a **gatekeeper** whose per-mint approval is mandatory; when designated, the gatekeeper does entry quality control (source-of-funds), is the **canonical-chain anchor** for mint settlement covering **`MoveToBacked` and `reg_root_E`** (R-04 / Attack A), **MAY** additionally issue an **operator-set-diversity vouch** (R-08) as belt-and-suspenders, and represents the interests of the asset's existing holders (§3.2.1.1, §6.1). Minting economic activity and gatekeeping are separate roles. **Attack B is closed by R-09**, not by the gatekeeper: the asset's operator set is a single **cumulative, growth-only** set S (join permissionless, no leave, every new vault N-of-N over the current full S — §3.1.2 / §4.1.1). The **product default** is the **effectively-trustless self-operator** profile (§1.1.1): a holder who is in S **before the first mint** is the honest 1-of-N signer of every vault and trusts nobody else for Attack-B safety or operator-theft safety. The gatekeeper is **not** required to close Attack B and **MUST NOT** be described as the thing that makes zkBTC trustless. Open registration + pooled **without** R-09 is **Corner C / UNSOUND** and **MUST NOT** be presented as trust-minimized or as effectively trustless (§3.2.1.2, §5, §6.4). Attack A is **independent** of R-09 and is closed **cleanly only** by R-04 when a gatekeeper is designated. |
| **REQ-4** | **Gatekeeper-independent, open-operator, liveness-bounded redemption:** every holder **MUST** be able to redeem for on-chain BTC without the gatekeeper's permission or technical cooperation. The exit (peg-out) agent role is **open and permissionless** — anyone **MAY** register (bond + pubkey, §4.1.1) **into the cumulative set S** and serve exits, including a holder acting as **their own** exit agent. The effectively-trustless path (REQ-3 / §1.1.1) is exactly that self-registration into S **before the first mint**. Exit depends only on the liveness of **≥1 registered operator** (BitVM-family residual — §1.2, §4.3), never on a fixed or privileged operator, and no operator can steal (1-of-N setup honesty + ≥1 honest live challenger acting in-window — worst case freeze/burn (under sound circuit/BitVM2-graph crypto — a critical soundness bug can instead enable theft, §4.5); §5). High minimum denominations and multi-week wait windows are acceptable for emergency exit. |

### 1.1.1 Effectively trustless (normative product claim)

zkBTC is **effectively trustless** in the following precise sense, and **MUST** be explained this way wherever the claim is made (this specification, the README, the FAQ, the whitepaper). It does **not** mean "zero assumptions." It does **not** mean "trust a company, a federation, or a gatekeeper."

**You do not trust other operators with your bitcoin. You are an operator.**

1. **Join S.** Anyone **MAY** register as an operator. Registration is into one **cumulative, growth-only** operator set S per asset (**R-09** — §3.1.2 / §4.1.1). S never shrinks: new operators join; **nobody leaves**; a key **MAY** rotate in place only under a signature of the key being replaced. Every new vault is N-of-N pre-signed by the **current full S**. A new "pool" or epoch that omitted any already-admitted operator is **invalid** under policy P and **MUST NOT** mint.
2. **Join before the first mint.** If **you** (or another party you treat as the honest 1-of-N) are in S **before this asset's first mint**, then every vault of the asset includes you. "Before the first mint" means **before that vault's epoch presign**, not merely before mint settlement: a graph already N-of-N-signed by a then-all-Sybil S **MUST NOT** later settle a mint after an honest join (that vault is prefix). A later Sybil club **cannot** form a vault you do not co-sign. You **MUST NOT** sign a malicious graph. That is the cryptographic close of **Attack B** (a self-controlled operator set draining the pooled reserve via ordinary redemption). Coins minted **before** you joined are an **untrusted prefix**: because the token is fungible and `redeem_commitment` has no provenance field (§3.5.5), prefix coins minted against a then-all-Sybil S can dilute later honest vaults. Therefore the product asset **MUST NOT** mint until the intended honest operator is in S **and** was in S_E at presign of every vault that will back a mint. A wallet **MUST NOT** construct a deposit for an asset unless the user's operator key is already in current S. A wallet **SHOULD** refuse to treat an asset as Attack-B-safe if the user was not in S at the asset's first `MoveToBacked`, unless at least one operator the user treats as honest already was (monotonicity then carries that honesty forward into every later vault).
3. **Exit yourself.** Once in S, you **MAY** front and reclaim your own redemption. You do not depend on a stranger's willingness to serve for **safety**. A holder who **never** registers still depends on ≥1 registered operator for **liveness** (not custody — that operator cannot steal under the §5 conditions).
4. **Operators cannot steal** under 1-of-N setup honesty, ≥1 honest live challenger acting in-window, and sound circuit/graph crypto (REQ-4 / §5). Worst case under those assumptions is freeze, not theft. A critical soundness bug is the theft case, which is why an external audit gates mainnet.
5. **What this does not close.** **Attack A** (private-fork mint settlement) is independent of R-09 and of being an operator. It is closed **cleanly** only by a canonical-chain observer at mint (R-04, when a gatekeeper is designated). Without a gatekeeper it is a Bitcoin-class residual, mitigated by deep finality `D_mint` (~2016 blocks) — the same kind of attack as reversing a deeply confirmed Bitcoin payment. A gatekeeper, when designated, cannot freeze, seize, or block exit; it only gates **new mints**. Host-side re-checking of `MoveToBacked` at later hops is **not** a clean Attack-A close (the backing outpoint is not carried transitively through shielded transfers — §3.3.2 / §3.4).

**Forbidden framings (MUST NOT).** Do not say that pooled open-registration zkBTC requires a trusted gatekeeper to be safe against operator theft or Attack B. Do not say that a holder who registered as operator still has to trust some other operator for **safety**. Do not market open registration + pooled **without** R-09 as trust-minimized or as effectively trustless (**Corner C**). Do not call prefix coins Attack-B-safe for a holder who joined after they were minted unless at least one honest operator was already in S at those mints.

### 1.2 Honest impossibility statement

No currently deployed mechanism gives a fungible multi-holder BTC-backed token a pure third-party-free unilateral L1 exit the way a Lightning force-close or a statecoin backup does. Federated and threshold-signer pegs (Liquid, tBTC, sBTC, and similar) require a signer quorum to release BTC. BitVM-family bridges improve **safety** toward 1-of-N setup honesty with challenge games, but keep **withdrawal liveness** dependent on at least one rational operator who fronts funds. Statechains and Ark offer unilateral exit for discrete UTXO/VTXO claims, not for a free-transfer fungible multi-holder token. Covenant soft forks that would enable anyone-can-satisfy vault exits are not activated as of mid-2026.

**Open-operator resolution.** On today's Bitcoin the exit-agent role can be made fully **open and permissionless** — anyone **MAY** post a bond and register as an operator **into the cumulative set S** (§4.1.1 / R-09), so a holder can be **their own** exit agent and no operator set is a closed club. Combined with growth-only S, that same self-registration is also the Attack-B close and the effectively-trustless product claim (§1.1.1). What is NOT achievable without a covenant soft-fork is *registration-free* unilateral self-reclaim: a holder who never registers relies on ≥1 *registered* operator being online to front and reclaim (a liveness dependency, not custody — that operator cannot steal under 1-of-N + ≥1 honest live challenger acting in-window (under sound circuit/BitVM2-graph crypto — a critical soundness bug can instead enable theft, §4.5) (§5)). This design delivers the maximal open-operator property available on today's Bitcoin and states the registration-free residual plainly (§10) rather than masking it.

REQ-4 as stated demands **gatekeeper-independence** (and, more generally, independence from any mint-time quality authority), which this design achieves: the gatekeeper has no role in peg-out. Full **counterparty-freeness** (zero live third parties other than Bitcoin) is not achievable for a fungible multi-holder token on today's Bitcoin; that residual needs covenant soft forks (§10). This document states that residual plainly rather than masking it.

### 1.3 Mechanism-class → unilateral-exit verdict

Compressed from the mechanism-class comparison (sources: §12.4):

| Mechanism class | Unilateral exit (holder vs L1 vault) | Fit for REQ-4 |
|-----------------|--------------------------------------|---------------|
| BitVM2 / BitVM3 / Glock operator-fronted peg | **PARTIAL** — safety 1-of-N; liveness needs ≥1 operator | **Chosen path (works today; open operator registration §4.1.1):** BitVM2 is the normative works-today verifier; BitVM3/Glock are future efficiency variants (§10.1) |
| Federated / threshold (Liquid, tBTC, sBTC, Spiderchain) | **NO** — quorum releases BTC | Out |
| Mercury statechains | **YES** per UTXO, not fungible multi-holder | Poor fungibility fit |
| Ark / Arkade VTXO | **YES** / **PARTIAL** while unexpired; expiry liveness | Secondary rail, not reserve |
| Lightning channels | **YES** for channel parties; **N/A** as multi-holder peg | Not a shared-reserve token |
| Covenant vaults (CTV / CSFS / OP_CAT) | **YES** (design-space) after activation | Long-term registration-free-exit upgrade (§10.2) |
| Custodial mints (Fedimint / Cashu) | **NO** | Contrast only |

Sources for the matrix: the landscape references in §12.4; the BitVM2 bridge paper (`https://bitvm.org/bitvm_bridge.pdf`) and `https://bitvm.org/bitvm2`.

### 1.4 Scope boundaries

This document defines:

- the in-circuit token standard that makes mint and redeem statements machine-checkable;
- the off-circuit bridge profile that holds the BTC reserve and serves exits;
- the trust matrix, launch gates, gatekeeper/compliance model, and transitional naming lock;
- future efficiency and covenant upgrade paths as design optionality, not delivery dependencies.

This document does **not** define:

- operator runbooks, federation recruitment, or commercial SLAs beyond the transitional profile;
- concrete Plonky2 circuit gadgets (only the statements they must prove);
- mainnet parameter freezes (values marked `PROVISIONAL` until **BitVM2 launch-pin against live economics**);
- a roadmap sequencing commitment relative to zkCoins native-issuance work (ROADMAP treats a BTC peg as orthogonal).

### 1.5 Non-goals

- **No new v1 wire formats.** Token standard 3 lives on the v2 circuit surface (new digests, new lineages). The frozen v1 surface of specification.md §1.7.8 is not edited in place.
- **No peg-in/out L1-footprint privacy beyond §8.** Deposits and payouts are public Bitcoin events; internal transfers remain shielded.
- **No price or oracle logic.** zkBTC is a claim on BTC at 1:1 denomination amounts, not a synthetic or stablecoin with external price feeds.
- **No federation-multisig V0** as a product path. **BitVM2 is the normative verifier** (§4.0); BitVM3 / Glock / Mosaic are optional **future efficiency upgrades** only (§10), never launch dependencies.
- **No claim of zero third-party dependency at exit.** REQ-4 is gatekeeper-independence and operator-liveness-bounded exit; operator liveness remains a residual (§4.3, §5). Operators **cannot steal** vault BTC under 1-of-N setup honesty + ≥1 honest live challenger acting within every relevant challenge window — worst case is freeze/burn (under sound circuit/BitVM2-graph crypto — a critical soundness bug can instead enable theft, §4.5) (§4.1, §5 residual 3); else unchallenged-fraud drain (§3.6). The operator set is **open/permissionless** (§4.1.1), so the residual is *operator liveness*, not a privileged party.
- **No mandatory central mint authority at the protocol layer.** A gatekeeper is optional per asset (`gatekeeper = 0³²` is valid). When present, the gatekeeper is an entry quality filter and the **canonical-chain anchor** (R-04: `MoveToBacked` **and** `reg_root_E`) for mint settlement, and **MAY** additionally issue an R-08 diversity vouch (§3.2.1.1, §6.1). **Attack B is closed by R-09** (cumulative growth-only S — §1.1.1 / §3.1.2), not by the gatekeeper. Open registration + pooled **without** R-09 is **Corner C / UNSOUND** and **MUST NOT** be marketed as trust-minimized or as effectively trustless. Open registration + pooled **with** R-09 is the product default (effectively trustless self-operator). Attack A remains closed **cleanly only** by R-04 when a gatekeeper is designated; without a gatekeeper it is a Bitcoin-class residual mitigated by `D_mint` (§3.2.1.2, §5, §6.4).

---

## 2. Design summary

zkBTC has two normative halves:

1. **Token standard 3 (TS3)** — in-circuit rules inside the single PCD circuit `C` (`issuance_version == 3`). Every mint is bound to a unique confirmed **`MoveToBacked` transaction** that creates a **backing-only vault output** (N-of-N-authenticated, deep-finality, operator-set membership; no refund path on that output); every redeem is an ordinary holder transition that anchors a unique on-chain nullifier `(Pkᵢ, Rᵢ)` and a hiding `redeem_commitment`.
2. **zkBTC bridge profile** — off-circuit **BitVM2**-based (BitVM-family) construction that holds the BTC reserve. Peg-in is permissionless for minters, optionally gated by a per-asset gatekeeper that is entry quality filter and **canonical-chain anchor** (R-04 / Attack A) for mint settlement (REQ-3). **Attack B is closed by R-09** (cumulative growth-only operator set S — §1.1.1 / §3.1.2), not by the gatekeeper. Peg-out is gatekeeper-independent (REQ-4), operator-fronted (liveness only — operators **cannot steal** under 1-of-N + ≥1 honest live challenger acting in-window (§5) (under sound circuit/BitVM2-graph crypto — a critical soundness bug can instead enable theft, §4.5)), with **optimistic assert/challenge/disprove** reimbursement and **permissionless challenging** (BitVM2 core property; availability ≠ guaranteed action — §4.1 role-note (a)). The product path is the holder registering into S before the first mint and refusing malicious graphs.

Document order is deliberate: the token standard comes first (it defines the statements), the bridge second (it consumes them). The bridge never invents a parallel mint/burn semantics; it only materialises Bitcoin custody around statements the circuit already enforces.

### 2.1 Roles (minter and optional gatekeeper)

Two mint-time roles are separated. They **MUST NOT** be conflated with a single central "issuer."

| Role | Function | Authority |
|------|----------|-----------|
| **Minter** | Economic actor: locks BTC (for zkBTC), obtains a mint to a recipient it commits. **MAY** be any depositor (permissionless). | Business activity only; no protocol veto over other holders' coins |
| **Gatekeeper** (optional) | Designated blockchain address — an x-only BIP-340 key; **MAY** be a MuSig2/FROST **threshold** aggregate of a holder committee (still a single x-only key in-circuit). Per-mint approval is mandatory when designated. Performs **two load-bearing roles** when designated (§6.1, §3.2.1.1): (a) **source-of-funds / vault-legitimacy screening**, (b) **canonical-chain anchor (R-04)** — withholds the `Pk_mint` mint-settlement signature until **both** `MoveToBacked` **and** the epoch's `reg_root_E` are confirmed on the gatekeeper's **own canonical Bitcoin view** (closes R-04 / Attack A for both anchors). It **MAY** additionally issue an **operator-set-diversity vouch (R-08)** as belt-and-suspenders; **Attack B is closed by R-09** (cumulative growth-only S — §1.1.1 / §3.1.2), not by this vouch. | Entry filter + mint-settlement canonicity gate; **cannot mint without valid backing** (deposit + operator-set-legit clauses) and **cannot redirect another depositor's committed mint** (clause (g)); has no special minting privilege beyond any depositor; **cannot** freeze, claw back, or touch existing / circulating coins, and **cannot** block exit (REQ-4 intact). **When the gatekeeper performs R-04 honestly:** it cannot inflate; **cannot settle a mint against a non-canonical `MoveToBacked` or substituted `reg_root_E`**. A **compromised / negligent** gatekeeper that **skips** R-04 **can enable Attack A**; skipping optional R-08 does **not** reopen Attack B if R-09 holds. Gatekeeper **integrity** is a backing-safety dependency **for Attack A (and SoF) when designated** (§6.3); it **cannot** directly forge a vault spend, steal circulating coins, freeze, or block exit. The gatekeeper is **not** the reason zkBTC is effectively trustless. |

The asset **MAY** set `gatekeeper` to the all-zero sentinel (= no gatekeeper). Then minting is fully permissionless under depositor-anchored `Pk_mint` (§3.2) and structural operator-set legitimacy (§3.1), including **R-09**. **Honest limitation (R-04 / §6.4):** without a gatekeeper (or equivalent external canonical oracle) there is **no external canonical observer** at mint settlement (Attack A **not cleanly closed** — operator-oracle-only / `D_mint`; **R-09 does not close Attack A**). **Attack B is closed by R-09** in both gated and no-gatekeeper modes, provided S is the cumulative growth-only set and the intended honest operator (the user, for the product claim) is in S before the first mint (§1.1.1). No-gatekeeper + open registration + pooled **without** R-09 is **Corner C / UNSOUND**. No-gatekeeper + open registration + pooled **with** R-09 is the **product default** (effectively trustless self-operator). No-gatekeeper + closed enumerated set + pooled is **Corner B** (Attack B by enumeration rather than open join; Attack A still operator-oracle-only).

A gatekeeper **MAY** also act as a depositor/minter for the same asset, subject to the **same** mint clauses as any other depositor — it has no special minting privilege.

The **vault presigning / operator set** (identity keys in S plus the epoch signing keys that co-sign the pre-signed **BitVM2** graph at setup, whose aggregate `agg_key_E` is admitted by `operator_set_root`) **MUST** be **N-of-N** (MUST — NEW-01). All operators **MUST** sign the graph at setup, and all **MUST** delete their **epoch signing secrets** afterward — **not** their identity keys (next paragraph). Under 1-of-N setup honesty, **one honest epoch-secret deletion** prevents any further graph signing for that epoch — a `t < N` threshold would leave `N−1 ≥ t` epoch shares able to sign after one honest deletion and would **break** 1-of-N safety. A live `t-of-n` CHECKSIG on the vault is already forbidden (§3.1.1); the presigning set itself **MUST NOT** be threshold either.

**Identity keys vs epoch signing keys (MUST — NEW-01 / R-09).** S is a set of **identity keys**. They are **not** deleted. They prove membership across epochs, sign in-place rotation, and sign the PoP that binds a **fresh epoch signing key** to (identity, E). For each epoch E, every member of S_E **MUST** contribute a fresh epoch signing pubkey `pk_{E,i}` with a PoP signed by that member's identity key over a domain-tagged message binding `(identity_pubkey, E, pk_{E,i})`. `agg_key_E` is MuSig2 KeyAgg over `{pk_{E,i}}`, **not** over the identity keys. After E's presigning completes, each honest operator **MUST** irretrievably destroy the **epoch** secret for `pk_{E,i}` / `agg_key_E` — not the identity secret. A later epoch uses new epoch keys, so deletion for E does **not** freeze E+1. **During the pre-deletion window of E**, the full N-of-N of `{pk_{E,i}}` could still sign — safety **in that window** rests on no-full-collusion, not on 1-of-N. **After** E's presigning completes and **≥1 honest operator has deleted its epoch secret**, 1-of-N holds for E's graphs. A deposit arriving after deletion for E is routed to a later epoch. Identity-key loss is the dead-operator mint freeze of R-09 item 4; epoch-key deletion is the 1-of-N setup close.

**Operator role in one sentence:** the operator is a **1-of-N liveness / fronting role that CANNOT steal vault BTC** under 1-of-N setup honesty + **at least one honest, live challenger actually acting within every relevant challenge window** + **sound circuit/graph crypto** (§5 residual 3; a critical soundness bug can instead enable theft — §4.5), **and** — because S is cumulative and growth-only (R-09) — the honest operator (including the holder acting as themselves) is the party that **refuses a malicious graph**, which is the Attack-B close. **Permissionless challenge** (BitVM2 — anyone **MAY** challenge a fraudulent reimbursement) is what makes challenging *possible* for anyone; safety requires someone to actually *do* it (availability ≠ guaranteed action — §4.1 role-note (a)). A dishonest operator's bond is slashed when challenged; worst case under those assumptions (1-of-N setup honesty + ≥1 honest live challenger acting in-window + **sound circuit/BitVM2-graph crypto** — a critical soundness bug in the circuit or graph can instead enable theft, §4.5) is freeze/burn, never theft; if no honest challenger acts in-window, unchallenged fraudulent reimbursement can drain vault value (§3.6). The operator set is **open/permissionless and growth-only** (§4.1.1 / R-09): anyone **MAY** register into S and serve, including a holder as their own operator; nobody leaves.

**Threshold / FROST is allowed only for the gatekeeper key** (when designated): a gatekeeper **MAY** be a MuSig2/FROST threshold aggregate (still a single x-only key in-circuit). Its threshold affects **approval liveness** only. A gatekeeper that performs R-04 **honestly** **cannot** settle a private-fork mint (R-04 / Attack A). A **compromised / negligent** gatekeeper that **skips** R-04 **can** enable **Attack A**. Skipping optional R-08 does **not** reopen **Attack B** if R-09 holds. Gatekeeper **integrity** is a **backing-safety dependency for Attack A (and SoF) when designated**, not for Attack B. Threshold aggregation **does not** remove that Attack-A integrity dependency — it only distributes **liveness** of approval. **Warning (MUST state):** an **N-of-N** gatekeeper aggregate means loss of a single member key **permanently disables minting** of that asset (rotation of a bound gatekeeper = new asset); threshold (t-of-n) for the **gatekeeper only** is **RECOMMENDED** to avoid permanent disablement from a single key loss.

An organisation **MAY** also operate an ordinary operator node if and only if launch gate A(1) still holds (affiliated keys strictly under half). Membership as operator confers **no** special mint or redeem privilege beyond the ordinary operator role.

### 2.2 What the gatekeeper (and any minter) cannot do

| Action | Why it fails |
|--------|----------------|
| Block transfers of circulating zkBTC | Ordinary parent specification.md §2 sends; no gatekeeper/minter clause in holder transitions |
| Block redemptions | Peg-out path (§4.3) has no gatekeeper step; operators serve holders |
| Forge supply without real vault backing | Mint clauses (e)/(f)/(h): LCP `MoveToBacked` confirmation + N-of-N + recursive `operator_set_root` equality + R-09 + depth ≥ `D_mint`, one-shot `Pk_mint` uniqueness, `amount == vault-output amount`; in gatekeeper mode, private-fork mint further blocked by gatekeeper withholding `Pk_mint` until **canonical** confirmation (R-04) — **provided the gatekeeper performs R-04 honestly**; a compromised gatekeeper that skips R-04 can enable Attack A. Skipping optional R-08 does **not** reopen Attack B if R-09 holds (§6.3). |
| Redirect a mint to a different recipient | Clause (g) recipient binding from deposit taproot commitment |
| Unilaterally seize the vault | N-of-N presigned **BitVM2** graphs; no gatekeeper admin key on vault spends; operators themselves also cannot steal, under 1-of-N + ≥1 honest live challenger acting in-window (§4.1/§5) (under sound circuit/BitVM2-graph crypto — a critical soundness bug can instead enable theft, §4.5) |
| Quietly re-parameterise the asset | `vault_template`, `gatekeeper`, and `operator_set_root` are bound into `asset_id`; change implies a new asset. `refund_timelock` is a bridge-epoch parameter only (§4.4), not asset identity |
| Add, remove, or rotate the gatekeeper in place | `gatekeeper` is in `asset_id`; rotation = new asset (honest statement — §3.1, §6) |
| Substitute a self-controlled vault under an honest asset | Recursive `C_lcp.operator_set_root == IssuanceTerms_v3.operator_set_root` and membership under that root close the *foreign-root* substitution attack (§3.1, §3.3(e), §3.3.1). Under **R-09**, a self-controlled *in-set* vault under the correct policy root is also closed: every new vault is N-of-N over the cumulative S, so once an honest operator is in S they refuse a malicious graph (§3.1.2). Open registration **without** R-09 does **not** close Attack B (**Corner C / UNSOUND**). |

### 2.3 Three flows (ASCII)

```
  User/Minter          Gatekeeper (opt.)   Bridge operators           Bitcoin L1
   |                     |                        |                      |
   |-- deposit (denom amount; recipient + optional depositor_base commits) -->|
   |                     |                        |-- N-of-N presign graph -->|
   |  [co-sign gate:] depositor co-signs MoveToBacked (BOTH modes; INV-01);
   |                  + gatekeeper co-signs in gated mode (anti-griefing)
   |                     |                        |-- MoveToBacked ----->|
   |                     |                        |   (backing-only vault;
   |                     |                        |    no refund leaf)
   |                     |                        |                      |
   |  [if gatekeeper:] SoF/vault + CANONICAL view (MoveToBacked depth ≥ D_mint
   |                   AND reg_root_E on gatekeeper's canonical chain;
   |                   deposit not refunded)
   |                   gatekeeper withholds Pk_mint sig until R-04 holds;
   |                   then signs m_state under Pk_mint
   |  [if no gatekeeper:] depositor signs m_state under depositor-anchored Pk_mint
   |                      (no external canonical observer — Attack A residual;
   |                       Attack B closed by R-09 growth-only S — §1.1.1 / §3.1.2)
   |-- TS3 mint (LCP: MoveToBacked depth ≥ D_mint) ->|                   |
   |<-- zkBTC coin (to committed recipient) -------|                      |
   |                     |                        |                      |
   |==== free transfers among holders (gatekeeper offline) ==============|
   |                     |                        |                      |
   |-- redeem transition (anchors (Pkᵢ,Rᵢ)) ----->|                      |
   |-- open redeem + payout template ----------->|                      |
   |                     |                        |-- front BTC -------->|
   |                     |                        |-- claim/challenge -->|
   |                     |                        |-- reimburse ---------|
```

Operators are **open-registered into the cumulative growth-only set S** (R-09 / §4.1.1); every new vault is N-of-N over current S. The diagram is unchanged in structure.

### 2.4 How the halves interact

| Event | Token standard (in-circuit) | Bridge profile (off-circuit) |
|-------|----------------------------|------------------------------|
| Peg-in deposit lands | — | Deposit taproot (refund leaf) → co-signed `MoveToBacked` (extinguishes refund) → **backing-only** vault output (no depositor/cooperative refund; pre-signed reimbursement graph only); denomination check |
| Mint settles | Clauses (a)–(h); `(Pk_mint, R)`; LCP proves `MoveToBacked` confirmed at depth ≥ `D_mint` + N-of-N + recursive `operator_set_root` | Observes mint; backing-only vault UTXO is the settled backing (proven in-circuit; no host-side freshness re-check) |
| Holder transfer | Ordinary parent specification.md §2 | None |
| Redeem settles | `redeem_commitment` (incl. `max_fee`); `(Pkᵢ, Rᵢ)` | Accepts opening; fronts payout; claim/challenge with claim-marker `(Pkᵢ, Rᵢ, payout_txid, payout_vout)` (logical first-marker — NH-02) |
| Audit | Upper-bound circulating ≤ vault UTXOs **conditional on** the reserve-safety assumptions of §5 (1-of-N + R-09 + no successful Attack A (R-04 only when gated) + ≥1 honest challenger); a successful **Attack A**, **Attack B** (if R-09 is absent — Corner C — or via the prefix residual of R-09 item 6), **or** unchallenged fraudulent/duplicate reimbursement breaks it; exact needs published aggregate attestation | Public vault UTXO set + optional balance/aggregate attestations |

### 2.5 Competing tokens / market

Because `gatekeeper`, `operator_set_root`, and `H(vault_template)` are bound into `asset_id`, each (name/genesis, vault template, **operator-registration policy**, gatekeeper) combination is a **distinct asset**. `operator_set_root` commits the asset's operator-registration **policy** — **by default and for the product profile**, the **open, growth-only** permissionless-registration policy of §4.1.1 / R-09 (not a fixed key list, and not a per-epoch set that can drop members); a **closed genesis-enumerated** policy P′ is a distinct non-default alternative used only in the Corner-B profile (§3.1.2 / §3.2.1.2). So a "different operator set" means a different **registration policy**, not (under the default) a different frozen enumeration of keys — the concrete S grows, it does not restart. Anyone **MAY** deploy a competing zkBTC with their own gatekeeper, a different registration policy, or no gatekeeper. Wallets **MUST** key by `asset_id` (and circuit lineage), never by display name alone. Adoption decides which zkBTC wins. The asset model supports this natively.

### 2.6 Deployment and packaging (informative)

The off-circuit half of §2 is delivered as a **single operator package — one Docker module** — run beside a zkCoins node stack. That package bundles the **bridge** (reserve custody, peg-in and peg-out handling) and, when the asset designates one, the **gatekeeper** entry control (§2.1). On the zkCoins side the package is an ordinary wallet-class client of the public `/v1/` REST API (specification.md §7.5); on the Bitcoin side it drives `bitcoind` directly. It does **not** use the operator-internal kernel RPC (specification.md §7.8) and never reads or writes the node's value-bearing store — the trustless-core boundary of specification.md §6 is unchanged.

Bundling the two roles in one package is a **deployment convenience, not a change to the trust model.** The gatekeeper stays the mint-time entry control (§2.1), the vault's safety continues to rest on the same **1-of-N** basis (at least one honest, independent operator — §2.1, §4.1, §5), and the existing role and registration rules (§2.1, §4.1.1, §6) are unchanged; packaging grants neither role any power the specification does not already give it. The in-circuit half (token standard 3) is **not** part of this package: it is a version branch of the shared circuit `C` (§3), carried by the zkCoins node like every other token standard.

---

## 3. Token standard 3 — permissionless, deposit-backed, redeemable (`issuance_version == 3`)

Token standard 3 is a new issuance schema in the sense of specification.md §6.5. It is **not** an edit to frozen v1; it ships only as a version branch of the **v2 circuit surface**. Dispatch **MUST** be an in-circuit version branch of the same circuit `C` (specification.md §6.5 "Adding new token standards"): a separate per-version circuit would break cyclic recursion when an account lineage mixes standards.

### 3.1 IssuanceTerms_v3 schema

Denominations and `refund_timelock` are **not** part of the token terms. Values bound into `asset_id` freeze for the life of the asset; denomination economics and deposit-taproot CSV depend on BitVM2 mainnet cost reality and **MUST** remain adjustable per deposit epoch as bridge parameters (§4.4). Soundness needs `vault_template` and `operator_set_root` in the terms (cross-asset double-backing closure and vault-legitimacy binding) plus in-circuit `amount == vault-output amount` and operator-set membership.

```
IssuanceTerms_v3 = {
  asset_id          : field,     // = Hc("AssetIdV3", genesis_tag ‖ gatekeeper ‖ operator_set_root
                                 //      ‖ H(name) ‖ decimals ‖ issuance_version ‖ H(vault_template))
                                 //   genesis_tag reuses the v1 constant ASCII string "zkCoins/v1/genesis" (§3.7.2)
  gatekeeper        : 32 bytes,  // x-only BIP-340 pubkey of the optional quality authority;
                                 //   OR the all-zero 32-byte sentinel = "no gatekeeper"
  operator_set_root : 32 bytes,  // 32-byte commitment to the asset's **operator-registration policy**
                                 //   P. **Default and product** is the **open, growth-only** policy of
                                 //   §4.1.1 / R-09: the permissionless join RULE (anyone may join by
                                 //   bond + PoP), **no leave / no kick after admission**, the bond
                                 //   **class/tier** (not the exact sat amount), the **anti-domination /
                                 //   admissibility predicate**, the **KeyAgg + PoP** rule (§4.1.2),
                                 //   and the **superset `reg_root_E`** rule (every new vault N-of-N
                                 //   over current S). Under that default it is a **policy** root, NOT a
                                 //   frozen list of keys — S grows, it does not restart. **Alternative
                                 //   (non-default):** a *closed genesis-enumerated* policy P′ is a
                                 //   **distinct policy** / **distinct asset** (Corner B). Concrete
                                 //   registration-window length, epoch cadence, exact bond amount
                                 //   within the class, and setup-window deadline are **per-epoch bridge
                                 //   parameters** (§4.4) and do NOT change asset_id. Changing any
                                 //   identity-bound policy element above = new asset_id. Open
                                 //   registration **without** R-09 does NOT close Attack B (Corner C /
                                 //   UNSOUND — §3.1.2 / §6.4).
  issuance_version  : u8 = 3,
  name_hash         : digest,    // = H(name); name never on-chain (same rule as v1/v2)
  decimals          : u8,        // = 8 (satoshi); normative for zkBTC
  vault_template    : bytes,     // canonical parameterized vault tapleaf-set template (§3.1.1);
                                 //   holes for agg_key identity, epoch, CSV constants; NUMS internal key;
                                 //   pre-signed-graph leaves only (no live CHECKSIG; no depositor refund);
                                 //   MUST NOT embed asset_id as a free field — see instantiate below
  terms_hash        : field      // = Hc("IssuanceTermsV3", asset_id ‖ issuance_version
                                 //      ‖ gatekeeper ‖ operator_set_root ‖ H(vault_template))
}
```

**Transport.** Identical to specification.md §6.5 IssuanceTerms transport: terms travel as optional `asset_terms` inside `CoinProof` (or out-of-band). The receiver recomputes `asset_id` and rejects a mismatch. The human-readable `name` is never on-chain.

#### 3.1.1 `vault_template` canonical encoding and `instantiate` (normative — B-02)

`vault_template` is a **canonical byte template** for the vault's **script-path tapleaf set**. Parameter holes are filled only by `instantiate`:

| Hole | Width | Meaning |
|------|-------|---------|
| `AGG_KEY_HOLE` | 32 bytes | **N-of-N** (BitVM2) aggregate x-only public key **identity** of the vault instance — used to bind the instance to an `agg_key` admitted by `operator_set_root` and to label the pre-signed graph for this operator set. **MUST NOT** create a live `agg_key` CHECKSIG spend path (NEW-01). The vault presigning set is **N-of-N**, not a threshold (NEW-01 — §2.1). |
| `EPOCH_HOLE` | 8 bytes | Deposit-epoch identifier (`u64` big-endian); binds the instance to a bridge epoch |
| `CSV_OP_HOLE` | variable (BIP-68 encoded) | Operator / reimbursement / claim-connector-leaf CSV relative locktime; filled to the **BitVM2 assert/challenge/disprove CSV windows** of this epoch (B-06 / §4.4 — not a mint-window formula) |

There is **no** `CSV_REFUND_HOLE`, **no** depositor-refund leaf, and **no** cooperative-refund leaf on the **backing-only** vault output (R-01). The depositor's unilateral refund lives exclusively on the **deposit taproot** (§4.2) and is extinguished when `MoveToBacked` consumes that output.

All other script structure is fixed by the template. The template **MUST NOT** contain `asset_id` as a free field outside the asset/epoch binding leaf (that would be circular: `asset_id` depends on `H(vault_template)`).

**NUMS internal key (MUST — no key-path spend).** The vault taproot output **MUST** use an **unspendable NUMS internal key** — a point with no known discrete log — so there is **no key-path spend**. Using `agg_key` as the internal key is **forbidden**: a key-path spend by the operator set would bypass every CSV-locked leaf and every pre-signed reimbursement path.

**NUMS derivation (normative — NEW-03).** The internal key **MUST** be an unspendable nothing-up-my-sleeve point with no known discrete log, identical for every vault of every asset (**not** a secret and **not** asset-bound). Derivation rule:

1. Domain tag: the fixed ASCII string `zkCoins/v2/VaultNUMS`.
2. Let `domain_sep` be the consensus-fixed 32-byte all-zero string of the v2 release.
3. `NUMS_xonly := xonly(hash_to_curve(domain_tag ‖ domain_sep))`, where `hash_to_curve` is a consensus-pinned hash-to-curve into secp256k1 with unknown discrete log (BIP-340-compatible even-y lift).  
   **Rationale / relation to BIP-341:** this is the same class of construction as the BIP-341 example NUMS internal key `H` (lift of the SHA-256 midstate of the BIP-341 tagged hash of the curve generator); this profile pins a profile-specific domain tag so the point is unambiguous for zkCoins vaults.
4. The concrete 32-byte x-only NUMS value is a **launch pin** of the v2 release (one value, frozen with the circuit digests). Until that pin, the derivation rule above is normative; the byte value is marked `PROVISIONAL`.

**No live CHECKSIG on the vault (MUST — NEW-01; covenant-emulation core).** Every vault spend path **MUST** move funds **only along the pre-signed BitVM2 transaction graph** fixed at setup. The vault **presigning set MUST be N-of-N** (all sign; all delete the **epoch** secret — §2.1). After the **epoch's** presigning is complete (all admitted deposits' graphs signed — §2.1 epoch-wide pre-deletion window), each signer's **epoch signing secret** for `pk_{E,i}` / `agg_key_E` (the capability to produce **any new signature** under that epoch aggregate, not merely a MuSig2 nonce) **MUST** be **deleted** (NEW-01; identity keys are **not** deleted — §2.1). Under 1-of-N setup honesty, one honest epoch-secret deletion means no coalition can authorise a spend outside the approved graph.

- There is **no live signing path** on the vault output: a live threshold/`agg_key` CHECKSIG that any current coalition could use to sign an **arbitrary** vault spend is **forbidden**. The presigning set itself is N-of-N, not t-of-n (NEW-01).
- Operator / reimbursement / connector leaves **MUST** commit to **specific pre-signed graph transactions** (assert, challenge, disprove, payout connectors, reimbursement payout) — not to a free-form `agg_key` CHECKSIG. **No** cooperative-refund leaf on the backing-only vault (R-01 residual — §4.2).
- Each such spend is authorised only by signatures produced **once at setup** with **epoch signing keys** then deleted. A live CHECKSIG by the current identity-key holders is **forbidden**.
- This restores 1-of-N safety and makes the fraud statement / sequencing connectors the **only** paths that can move vault value after `MoveToBacked`.

**Canonical ordered tapleaf set and tree construction (MUST — NEW-03).** All spend paths are **tapleaves** (script path only; BIP-341 tapleaf version `0xc0` unless a later consensus parameter freezes another version). Sorting sibling hashes alone does **not** define the tree shape; this profile pins both **leaf order** and **tree shape**:

1. **Leaf multiset (semantic identities).** `instantiate` builds exactly the following ordered multiset (fixed semantic order key = the labels below, left-to-right):

| Order key | Semantic leaf | Encoding / role |
|-----------|---------------|-----------------|
| (a) | **Operator / reimbursement leaf** | Pre-signed-graph reimbursement entry: commits to the BitVM2 assert/reimbursement graph transaction(s) for this epoch (connector structure the graph requires). **CSV-timelocked to the BitVM2 assert/challenge/disprove window** of this epoch (B-06 / §4.4). **MUST NOT** be a live `agg_key` CHECKSIG. The filled `AGG_KEY_HOLE` identifies the operator-set aggregate bound into the graph; it does **not** authorise free-form spends. |
| (b) | **Claim / reimbursement / sequencing connector leaves** | The additional connector leaves the BitVM2 graph requires for assert/challenge/disprove serialisation and sequencing (exact scripts are graph-compiler artefacts — see launch-pin note below). Each leaf that can move vault value **MUST** be CSV-locked to the BitVM2 assert/challenge/disprove windows (B-06). |
| (c) | **Asset/epoch binding leaf** | An unspendable commit leaf (OP_RETURN-style / always-fail script path) whose data payload is exactly `asset_id_bytes (32) ‖ u64be(epoch) (8)`. |

   **No depositor refund leaf and no cooperative refund leaf** appear on the backing-only vault (R-01). Unilateral depositor reclaim exists only on the deposit taproot **before** `MoveToBacked` (§4.2).

2. **Fixed leaf ordering key.** Leaves are ordered first by the semantic order key `(a) < (b) < (c)`; within (b), by ascending `tapleaf_hash` of each connector leaf (deterministic secondary key). This produces a total order independent of insertion order.

3. **Tree-shape rule (canonical balanced binary combination).** Over the ordered leaf list `L[0..n-1]`, build a **left-complete balanced binary Merkle tree** as follows:
   - If `n = 1`, the Merkle root is that single `tapleaf_hash`.
   - Otherwise, pair consecutive leaves left-to-right into parent nodes; BIP-341 sibling lexicographic sort applies **only within each pair** (standard BIP-341: `parent = H_tapbranch(min(a,b) ‖ max(a,b))`).
   - If the current level has an odd count, the last unpaired hash is promoted unchanged to the next level (left-complete; no Huffman rebalancing, no free reordering of unpaired nodes).
   - Repeat until one root remains.
   This rule, together with the fixed leaf order and NUMS internal key, fully determines the tree bytes for a **fixed** leaf multiset.

4. **Launch-pin honesty for concrete connector bytes (`PROVISIONAL`).** The **semantic** construction (leaf roles, CSV bounds, no live CHECKSIG, no vault refund leaf, NUMS, order key, tree-shape rule) is normative now. The **concrete** connector-leaf script bytes emitted by the BitVM2 graph compiler are launch parameters: until the compiler template is frozen with the v2 circuit digests, byte-equality of `instantiate(…)` is defined **relative to the pinned template** once fixed, not claimed as fully determined by the prose alone. Implementations **MUST NOT** claim present-day absolute byte-determinism for the connector subset beyond the semantic pins above.

Define the concrete vault output by instantiation:

```
instantiate(vault_template, asset_id, agg_key, epoch) :=
  // 1. Fill holes deterministically:
  leaves := vault_template tapleaf set with
              AGG_KEY_HOLE     ← agg_key                    // 32-byte x-only identity (NOT live CHECKSIG)
              EPOCH_HOLE       ← u64be(epoch)               // 8-byte big-endian
              CSV_OP_HOLE      ← bip68_csv(assert_challenge_csv)  // BitVM2 assert/challenge/disprove window (B-06)
              asset/epoch leaf payload ← asset_id_bytes ‖ u64be(epoch)
              // NO CSV_REFUND_HOLE; NO depositor-refund leaf; NO cooperative-refund leaf
  // 2. Internal key := NUMS   // unspendable; NO key-path spend (MUST)
  // 3. Order leaves by semantic key (a)<(b)<(c), then within (b) by
  //    ascending tapleaf_hash; build left-complete balanced BIP-341 tree
  //    (tree-shape rule above).
  // 4. output_key := BIP341_tweak(NUMS, merkle_root(leaves))
  // 5. scriptPubKey := P2TR(output_key)   // 34-byte witness program
  // Return the exact scriptPubKey bytes (and, for LCP equality, the full
  // serialised output script as used on Bitcoin) relative to the pinned
  // vault_template / graph-compiler template at launch.
```

Normative properties:

- Instantiation is a pure function of `(vault_template, asset_id, agg_key, epoch)` together with the consensus NUMS point and the epoch's BitVM2 assert/challenge/disprove CSV constants (B-06 / §4.4). Two different `asset_id` values **MUST** produce different scriptPubKeys (via the asset/epoch binding leaf). `refund_timelock` is **not** an input to vault instantiation (it belongs only to the deposit taproot — §4.2 / §4.4). There is **no** mint-freshness window `W` and **no** `D_mint + S + W + 1` CSV term.
- At mint time, clause (e) **MUST** verify that the proven vault output's scriptPubKey is **byte-equal** to `instantiate(vault_template, this asset_id, agg_key, epoch)` for some `agg_key` admitted by `operator_set_root` and the epoch committed in the deposit path. Byte-equality is executable once the launch-pinned template (including connector-leaf bytes) and NUMS value are frozen; until then equality is relative to that pin (NEW-03 honesty).
- **Consequence (B-01 restored via MoveToBacked):** there is **no key-path bypass** and **no live free-form CHECKSIG**; the backing-only vault is spendable **only** via the BitVM2 assert/challenge/disprove pre-signed-graph leaves. One BTC outpoint can back at most one asset. A minter **cannot** omit the asset binding: an output that does not match the required instance fails the mint. Settled mint ↔ backing-only UTXO is proven **in-circuit** by confirming `MoveToBacked` (§3.3(e)); no host-side freshness re-check.
- **Consequence (R-01 / INV-01):** a depositor **cannot** mint against a vaulted output and later unilaterally refund the same BTC: the backing-only vault carries no depositor-refund leaf and no cooperative-refund leaf; unilateral reclaim exists only if `MoveToBacked` never happens (deposit-taproot refund). If `MoveToBacked` fires but the mint never settles, the vaulted BTC is an **irrevocable, consented contribution to the shared reserve** (cross-graph reimbursement may consume it for another holder's redeem — §3.4, §4.2), not merely frozen recoverable BTC.

#### 3.1.2 Operator-set legitimacy (normative — Part 2)

`operator_set_root` is a 32-byte commitment to this asset's **operator-registration policy** P (encoding of the policy tree is a launch parameter; the root value is frozen in `asset_id`). **Default and product** policy P is **open, permissionless, and growth-only (R-09)**: anyone **MAY** join S by posting the policy's bond and a pubkey with proof-of-possession (§4.1.2); there is **no allowlist and no admin approval**; **nobody leaves**. Under that default it is a **policy** root, **not** a frozen enumeration of operator keys — the concrete set S grows over time and **MUST** be the operator set of every new vault (§4.1.1). **Alternative (non-default):** a *closed genesis-enumerated* policy P′ (fixed key list + gate-A(1) diversity at launch) is a **distinct policy P** (distinct `operator_set_root` / `asset_id`) usable only in the Corner-B profile (§3.2.1.2 / §6.4) — it closes Attack B by enumeration but **abandons open registration** and does **not** cleanly close Attack A. Concrete registration-window length, epoch cadence, exact bond amount within the bond class, and setup-window deadline are **per-epoch bridge parameters** (§4.4) and do **not** change `asset_id`.

**R-09 — cumulative growth-only operator set (MUST — Attack B close).** Let S be the admitted operator set of this `asset_id`.

1. **One set per asset.** There is a single S, not a per-epoch club that can restart. Epochs exist only as **presign batches** over the current S (and any joiners admitted in that window). **Uniqueness (MUST):** there is exactly one admitted `reg_root` lineage per `asset_id`. A `reg_root_E` is valid only as the unique successor of the unique predecessor already used by this asset (genesis `reg_root_0`, then each later E). Sibling `reg_root` values that do not spend/extend that unique head are **invalid**. The byte encoding of that uniqueness is a launch pin (§4.1.2 item 7); the uniqueness rule is normative now.
2. **Join only (identity keys).** Anyone **MAY** add an **identity** key to S during a registration window (bond + PoP, §4.1.2). S **MUST NOT** shrink. The R-09 superset is over **identity-parties**, not over per-epoch signing keys and not over raw key bytes after an in-place rotation. A `reg_root_E` whose identity set omits any identity-party already in `reg_root_{E-1}` is **invalid** under P; mint clause (e) / two-level admission **MUST** reject it. Formation of `reg_root_E` **MUST** prove that every identity-party in `reg_root_{E-1}` is still represented in `reg_root_E` (same pubkey, or `pk_new` under a rotation signed by `pk_old` — item 4). S_E = rotate(S_{E-1}) ∪ J_E, J_E = new joiners; S_0 = J_0. Rotation is not leave.
3. **No leave, no kick after admission.** An already-admitted **identity** **MUST NOT** be excluded from S, including for Level-1/Level-2 griefing of a later epoch. Grief-default **MAY** slash the bond; it **MUST NOT** drop the identity. Exclusion **MAY** apply only to a joiner in J_E who has **not yet** been admitted to S (failed the current join round). Kick-after-admission re-opens Attack B (honest identities griefed out, then a Sybil-only vault).
4. **Key rotation in place (MAY).** An admitted operator **MAY** replace identity `pk_old` with `pk_new` iff `pk_old ∈ S` and `pk_old` signs the rotation. Cardinality of S is unchanged; the party remains. Rotation **without** the old identity key is **leave** and is **forbidden**. Lost **identity** keys are dead weight: new vaults cannot complete N-of-N until that party rotates or the mint of new vaults stays frozen. **Safety of existing coins over mint liveness.** Epoch signing keys are a different object: they are freshly generated per epoch and **deleted** after that epoch's presign (NEW-01) — that deletion **MUST NOT** be treated as leave.
5. **Every new vault is N-of-N over current S.** For epoch E, `agg_key_E` **MUST** be the MuSig2 KeyAgg of the **epoch signing keys** `{pk_{E,i}}` of exactly S_E, each bound to its identity by PoP (NEW-01 / §4.1.2). An honest member of S **MUST NOT** sign a malicious graph. Once ≥1 honest identity is in S, no later vault can have a malicious graph.
6. **First-mint rule (MUST — prefix residual).** Because redeem is cross-graph and `redeem_commitment` has no provenance field (§3.5.5), coins minted against a then-all-Sybil S are **fungible poison** against later honest vaults. Join-then-deposit protects new vaults as *sources*, not as *sinks*. Therefore: the product asset **MUST NOT** mint until the intended honest operator is in S. A wallet **MUST NOT** construct a deposit unless the user's operator key is already in current S. A wallet **SHOULD** refuse to treat an asset as Attack-B-safe if the user was not in S at the first `MoveToBacked`, unless at least one operator the user treats as honest already was (monotonicity then carries that honesty into every later vault). Isolation of prefix coins is **not constructible** without a provenance field (Option-3 / §3.5.5).

**Two-level admission (MUST):**

1. Each deposit epoch E publishes an on-chain **epoch registration commitment** `reg_root_E` = commitment to S_E under policy P (each member posted the required bond with PoP — formation and checks in §4.1.2), together with the **superset proof** against `reg_root_{E-1}` (item 2 of R-09). The epoch's N-of-N aggregate key `agg_key_E` is the MuSig2 KeyAgg of the **epoch signing keys** `{pk_{E,i}}` of exactly S_E, **not** of the identity keys (NEW-01 / §4.1.2).
2. The mint (clause (e)) **MUST** verify, via the recursive LCP, that `agg_key` (used in `instantiate`) is admitted by a chain of commitments rooted at the **asset-bound** policy root: `agg_key` is the MuSig2 KeyAgg of the **epoch signing keys** `{pk_{E,i}}` of exactly S_E (not the identity keys) whose `reg_root_E` was validly formed under P **and** is a growth-only successor of the previous admitted set, and the outer circuit checks `C_lcp.operator_set_root == IssuanceTerms_v3.operator_set_root` (policy-root equality — §3.3.1). A bare `operator_set_member_ok` boolean remains **INSUFFICIENT**.

**Two independent *mint-settlement* backing-drain attacks (normative).** These are the two backing-drain attacks that arise at **mint settlement**. They are **not** the only reserve-safety conditions: the **redeem/reimbursement** side additionally requires the §4.3.2 fraud statement + ≥1 honest active challenger (else unchallenged-fraud drain — §3.6) and carries the payout-canonicity residual (§5 residual 11). "Two" scopes the **mint-side** decomposition, not an exhaustive list of every reserve-safety condition. **They are closed by different mechanisms.**

- **Attack A — private-fork amortization.** Attacker mines a private fork, fires `MoveToBacked` only there, mints from the private-fork LCP, refunds the deposit on the canonical chain → unbacked. **Closed cleanly by R-04** (gatekeeper canonical-chain anchor: withholds `Pk_mint` until `MoveToBacked` **and** `reg_root_E` are confirmed on the gatekeeper's **own canonical Bitcoin view** — §3.2.1.1 / §3.3.2 / §3.4 / §4.1.2). **R-09 does not close Attack A.** Without a gatekeeper, Attack A is a Bitcoin-class residual mitigated by `D_mint`. Host-side re-checking of `MoveToBacked` at later hops is **not** a clean close (the backing outpoint is not carried transitively through shielded transfers — §3.3.2 / §3.4).
- **Attack B — self-controlled in-set vault → cross-graph drain.** Under **open permissionless registration without R-09**, an attacker registers a **Sybil epoch it fully controls** (all N keys its own — a per-epoch club the open policy would otherwise admit), makes a **real, canonical** deposit + mint (so it passes R-04 and clause (e)), and — because it controlled all N at setup, with **no honest signer to refuse** — pre-signs a **malicious graph** that pays the vault back to itself. It drains its own vault, leaving the minted zkBTC unbacked, then redeems that **fungible** zkBTC **cross-graph against honest vaults** (§4.3). Net: honest holders' backing is drained. **R-04 does NOT close Attack B** — every transaction is canonical. **Attack B is closed by R-09:** every new vault is N-of-N over the cumulative S, so once an honest operator (the user, for the product claim) is in S they refuse a malicious graph, and a later epoch **cannot** omit them. R-08 (gatekeeper identity/reputation vouch) is an optional belt-and-suspenders check in gated mode; it is **not** the Attack-B close and **MUST NOT** be described as the reason zkBTC is effectively trustless. R-08 does **not** touch exit (REQ-4 intact) and does **not** gatekeep who may register.

**Why this still closes the drain (load-bearing).** Without policy-root binding, an attacker could register itself as the entire N-of-N of a self-controlled epoch under a *foreign* root, deposit, mint, then cooperatively spend its own vault → unbacked-but-fungible zkBTC redeemed cross-graph against honest vaults (1-of-N honesty vacuous when the attacker supplies all N). Recursive `operator_set_root` equality closes that **foreign-root** substitution. Separately, **open registration without R-09** does **not** prevent an attacker from registering a solo self-controlled epoch *under the correct policy root* (**Attack B**). Therefore:

1. Policy P **MUST** encode R-09 (growth-only S, superset `reg_root_E`, no kick after admission, every new vault N-of-N over current S) **and** the launch-gate-A(1)-class economic anti-Sybil / anti-domination constraint (§4.6A): the admissibility predicate **MUST** require that no single party controls ≥ half of S (enforced economically by bond cost + the honest-registration assumption). Anti-domination is a **weaker, both-modes** defense and is **insufficient alone** against Attack B under pooled cross-graph reimbursement; R-09 is the close.
2. **R-09 is the Attack-B close in both gated and no-gatekeeper modes.** The product default is no-gatekeeper + open + pooled + R-09 (effectively trustless self-operator — §1.1.1), with the first-mint rule above. R-04 remains the Attack-A private-fork / canonical-anchor defense when a gatekeeper is designated.
3. In **no-gatekeeper + open registration + pooled without R-09** (**Corner C**), Attack B is open; the economic bond alone is insufficient; the combination is **UNSOUND** and **MUST NOT** be deployed or marketed as trust-minimized or as effectively trustless (§3.2.1.2 / §5 residual 9 / §6.4).
4. In **no-gatekeeper + closed genesis-enumerated set + pooled** (**Corner B**), Attack B is closed by genesis enumeration under launch gate A(1), but **Attack A is still only mitigated by operators-as-best-effort-oracle / `D_mint`** — and the profile **abandons open join**. Closing the operator set does **not** close Attack A.

**Honest cost of growth-only S:** a dead or grieving admitted operator freezes **new** mints (N-of-N cannot complete) until they rotate a live key; **existing** coins remain exit-able along that vault's already-presigned 1-of-N graph. That is the safety-over-mint-liveness trade-off and **MUST** be stated, not hidden. Attack A remains closed **cleanly only** by R-04 (gated mode) — independent of R-09.

Changing policy P produces a different `operator_set_root` and therefore a **different** `asset_id` (new asset).

#### 3.1.3 Binding rules

- `decimals` **MUST** equal `8` for the zkBTC asset (satoshi base units).
- `vault_template` is bound into `asset_id` via `H(vault_template)`. Changing the template produces a **different** `asset_id` (new asset).
- `gatekeeper` is bound into `asset_id` and `terms_hash`. Presence and identity are fixed and holder-visible. A gatekeeper **cannot** be added, removed, or rotated without producing a different asset (**rotation = new asset** — stated honestly).
- `operator_set_root` is bound into `asset_id` and `terms_hash` (same freeze discipline — changing the *policy* = new asset). Policy identity (join rule, **R-09 growth-only / no-leave**, bond class/tier, anti-domination predicate, KeyAgg+PoP rule, optional R-08 duty for gated deployments) is identity-bound; concrete registration-window length, epoch cadence, exact bond amount within class, and setup-window deadline are **not** identity-bound (§4.4).
- `refund_timelock` is a **per-deposit-epoch bridge parameter** only (§4.4). It governs the deposit-taproot refund leaf, not token identity, and is **not** in `IssuanceTerms_v3`, `AssetIdV3`, or `terms_hash`.
- Allowed deposit/payout denominations are **per-deposit-epoch bridge parameters** (§4.4). The circuit enforces only `amount == vault-output amount`, not membership of a frozen denomination set.

### 3.2 Mint key derivation and the one-shot mint account

#### 3.2.1 Additive-tweak mint key (`Pk_mint`)

The mint anchors to the **`MoveToBacked` vault outpoint** `(vault_txid, vault_vout)` — the backing-only N-of-N/BitVM2 vault UTXO created when `MoveToBacked` consumes the user's deposit output — **not** the user's original deposit outpoint. Write `vault_outpoint := vault_txid ‖ vault_vout` (32-byte txid ‖ 4-byte little-endian `vout`, matching Bitcoin outpoint serialisation).

For each such vault outpoint of this `asset_id`:

```
digest = Hc("zkCoins/v2/MintKey", asset_id ‖ vault_outpoint)
```

**Digest-to-scalar (normative, mirrors specification.md §3.2 BIP-340/S2C).** Let `n` be the secp256k1 group order.

1. Let `h_bytes` be the **32-byte serialization** of the Poseidon `Hc` digest (byte order per parent specification.md §1.7).
2. Interpret `h_bytes` as a **big-endian integer** and reduce **mod `n`** to obtain the scalar candidate `h`.
3. If the reduced value is `0`, **redraw** with a defined domain-tagged counter: recompute  
   `digest = Hc("zkCoins/v2/MintKey", asset_id ‖ vault_outpoint ‖ u32-be(counter))`  
   with `counter` starting at `1` and incremented until `h ≠ 0` (analogous to the parent redraw rule for exceptional S2C nonces). The unbiased reduction bias is ≈ `2⁻¹²⁸`, negligible.
4. **Even-y base normalisation (MUST — M-01).** Let `Pk_base` be the mode-dependent base key (§3.2.1.1 / §3.2.1.2). Before the additive tweak, `Pk_base` **MUST** be normalised to the **even-y lift** of its x-only encoding (parent specification.md §1.157):
   - Lift the 32-byte x-only encoding to the unique even-y curve point `P_base`.
   - Let `sk_base` be the corresponding secret for that even-y point (if the holder's raw secret produces the odd-y point, set `sk_base := n − sk_raw mod n` so that `sk_base · G = P_base` with even y).
   - All subsequent arithmetic uses this even-y `(P_base, sk_base)` pair.
5. Form the unnormalised point `P = P_base + h · G` on secp256k1.
6. If `P` is the point at infinity, **reject** and redraw with the next counter (same domain tag).
7. **BIP-340 x-only (even-y) normalisation of the result:**
   - if `y(P)` is odd: set `Pk_mint` to the even-y negation (`−P`) and  
     `sk_mint = n − (sk_base + h) mod n`;
   - else: set `Pk_mint = P` (x-only) and  
     `sk_mint = (sk_base + h) mod n`.

A pure hash-to-point construction (`Pk_mint = H_to_point(…)`) would be a NUMS point with no known discrete log — unusable as an account spend key. The additive-tweak form is deliberate: it keeps mint authority on the mode-dependent base secret while making each vault outpoint's key unique and outpoint-bound.

##### 3.2.1.1 Gatekeeper-gated mode (`gatekeeper ≠ 0³²`)

```
Pk_mint = BIP340_even_y( gatekeeper_pubkey_even_y + h · G )
sk_mint = sk_gk_even_y + h   (with parity/negation per step 7)
```

where `gatekeeper_pubkey` is the x-only key from `IssuanceTerms_v3.gatekeeper` (fixed in `asset_id`) and `h` derives from `vault_outpoint` as above. Only the gatekeeper knows `sk_mint = sk_gk + h` (after even-y normalisation).

Because the accumulator admits `(Pk_mint, R)` only under a BIP-340 signature over `m_state` by `Pk_mint` (parent specification.md §3.2), **producing that on-chain nullifier IS the gatekeeper's act of approval** ("I permit this mint") — zero extra circuit cost beyond the ordinary spent-key check. First-occurrence on the deterministic `Pk_mint` (fixed `gatekeeper_pubkey` from `asset_id`, `h` from `vault_outpoint`) makes **one mint per deposit**, even against a malicious gatekeeper.

**Approval semantics (normative).** The gatekeeper's signature over `m_state` vouches that, for this mint:

1. **Source-of-funds:** the public on-chain BTC feeding the deposit has passed the gatekeeper's screening (reject hack/tainted/sanctioned BTC at entry);
2. **Vault/operator-set legitimacy (MUST — R-09; optional R-08 belt-and-suspenders):** the vault instance is legitimately constituted under this asset's `operator_set_root` policy as a **growth-only successor of S** (R-09 — §3.1.2): `reg_root_E` omits nobody already admitted, and `agg_key` is KeyAgg of the **epoch signing keys** of that S (NEW-01). **Attack B is closed by R-09**, not by the gatekeeper. The gatekeeper **MAY** additionally refuse to sign unless it has independently vouched that S has **at least one independent honest signer (1-of-N-honest basis)** (optional **R-08** identity/reputation check). R-08 is mint/entry-time only; it does **not** gatekeep registration or exit (REQ-4 intact) and **MUST NOT** be described as the Attack-B close;
3. **Committed recipient and clean deposit-backing:** the mint's **witness / inputs** establish a real LCP-proven vault deposit (≥ depth, to the asset's instantiated vault), the committed recipient (clause (g)), and operator-set membership under the asset-bound root (clause (e));
4. **Canonical-chain anchor (MUST — closes R-04 / Attack A; covers `MoveToBacked` and `reg_root_E`).** On the gatekeeper's **own canonical Bitcoin view**: (i) the relevant `MoveToBacked` is confirmed to depth ≥ `D_mint` on the **canonical** chain, (ii) the deposit output was **not** refunded on the canonical chain, and (iii) the epoch's `reg_root_E` backing this mint is the **canonical** registration commitment (not a private-fork / substituted root) and satisfies R-09. The gatekeeper **MUST withhold** the `Pk_mint` signature until all hold. Because the mint cannot settle without the gatekeeper's `Pk_mint` signature (`sk_mint = sk_gk + h`; only the gatekeeper can produce it), a private-fork `MoveToBacked` or a substituted `reg_root_E` yields **no mint**. A co-signed `MoveToBacked` alone is **insufficient** as the sole canonicity gate — its N-of-N setup signature is valid on any fork; the gate is the gatekeeper withholding the **final** mint signature until canonical confirmation of both anchors. The gatekeeper is therefore the **canonical-chain anchor** for **both** `MoveToBacked` **and** `reg_root_E`, not only a source-of-funds / legitimacy check. R-04 closes **Attack A** only; it does **not** close Attack B.

**Signing order / mint-signing checklist (normative — R-03 / R-04 / R-09; MUST).** "Verify the full mint proof before signing" is **circular**: the completed proof `C` embeds the gatekeeper's BIP-340 signature over `m_state` (S2C over `H(ProofData)`), so the proof cannot exist before the signature. The correct order is:

1. The gatekeeper verifies the mint's witness/inputs — the LCP-proven vault deposit (real, ≥ depth, to the asset's `instantiate`d vault), the committed recipient, `operator_set_root` membership and **R-09 superset** against the asset-bound root, and its own source-of-funds / legitimacy policy — **NOT** a completed proof. Optional R-08 MAY be applied here as belt-and-suspenders.
2. **Canonical confirmation (MUST — R-04 / Attack A):** on the gatekeeper's **own canonical Bitcoin view**, confirm that (i) `MoveToBacked` is present at depth ≥ `D_mint` on the **canonical** chain, (ii) the deposit output was **not** refunded on the canonical chain, and (iii) `reg_root_E` is the canonical registration commitment for the epoch (same R-04 duty as `MoveToBacked` — §4.1.2). **Withhold** the mint signature until all hold.
3. **Operator-set growth-only (MUST — R-09 / Attack B):** confirm that `reg_root_E` is a valid growth-only successor of the previous admitted set (nobody already in S omitted). **Withhold** the mint signature if R-09 fails. Optional **R-08:** the gatekeeper **MAY** additionally withhold if it assesses S as a self-controlled Sybil set; this is belt-and-suspenders, not the close.
4. Only then does the gatekeeper produce the transition-authorization **signature** (`sk_mint` S2C over `m_state` committing `H(ProofData)`).
5. After that signature exists, the final proof `C` is constructed embedding it and settled.

**Caveat (MUST state).** Blind signing (signing without checking inputs, including without the canonical-chain check on `MoveToBacked`/`reg_root_E` or the R-09 superset check) cannot create an unbacked mint that the circuit alone rejects (backing is circuit-enforced against *some* header chain) — but it **does** re-open the private-fork amortization attack of R-04 (Attack A). It does **not** reopen Attack B if R-09 holds in-circuit. Skipping SoF may wave through a tainted mint. The gatekeeper checks all proof inputs, its own canonical Bitcoin view (both anchors), **and** R-09, signs only after those hold, then the proof is built (R-03).

##### 3.2.1.2 No-gatekeeper mode (`gatekeeper = 0³²`)

```
Pk_mint = BIP340_even_y( depositor_base_even_y + h · G )
```

where `depositor_base` is a key the depositor **commits in the deposit taproot** and the mint verifies in-circuit via the LCP leaf data (exactly like the recipient commitment of clause (g)). **WITHOUT** this in-circuit commitment, any prover could choose its own base and first-occurrence would give no one-mint-per-outpoint guarantee — so this commitment is **MANDATORY** in no-gatekeeper mode.

**Hard limitation (MUST state — R-04 / §6.4 / §3.1.2).** With `Pk_mint` anchored on the depositor's own key, the depositor produces the mint signature itself. There is therefore **no external canonical observer**:

- **Attack A (private-fork amortization)** is **not cleanly closed**: mine a private fork, fire co-signed `MoveToBacked` only there, mint from the private-fork LCP proof, refund the deposit on the canonical chain → unbacked zkBTC amortized over many deposits (R-04 absent). Without a gatekeeper, Attack A is mitigated by deep finality `D_mint` (~2016 blocks) and by operators refusing to treat a mint whose `MoveToBacked` is not on their canonical chain as good backing — a **Bitcoin-class residual**, not a trusted third party. **R-09 does NOT close Attack A** — a growth-only set has no external canonical observer either. Host-side re-checking of `MoveToBacked` at later hops is **not** a clean close (§3.3.2 / §3.4).
- **Attack B (self-controlled Sybil epoch → cross-graph drain)** **is closed by R-09** under open registration: every new vault is N-of-N over the cumulative S, so once an honest operator is in S they refuse a malicious graph, and a later epoch cannot omit them (§3.1.2 / §1.1.1). The economic anti-domination bond of policy P alone is **insufficient**. Open registration **without** R-09 leaves Attack B open (**Corner C / UNSOUND**). The **prefix residual** (coins minted before the intended honest operator joined) is stated in R-09 item 6 and is **not** a footnote.

**Two independent drain attacks (backbone — MUST).** A pooled cross-graph reserve requires **both** drain attacks be addressed. They are **independent** and closed by **different** mechanisms:

- **Attack A (private-fork amortization):** closed **cleanly only** by an external canonical observer at mint = the gatekeeper's **R-04** canonical anchor (covering `MoveToBacked` **and** `reg_root_E`). Without a gatekeeper, Attack A is a Bitcoin-class residual mitigated by `D_mint`. **Independent of R-09.**
- **Attack B (self-controlled Sybil vault):** closed by **R-09** (cumulative growth-only S, every new vault N-of-N over current S, first-mint rule). Optional R-08 is belt-and-suspenders in gated mode. Under **open registration without R-09**, there is **no 1-of-N-honest guarantee** → Attack B open → **UNSOUND**.

**Sound-deployment profiles (MUST — normative).**

| Corner | Properties | Verdict | Notes |
|--------|------------|---------|-------|
| **D (PRODUCT DEFAULT — effectively trustless self-operator)** | Open registration + pooled + **R-09** + no gatekeeper | **Attack B closed cryptographically** once the intended honest operator is in S before the first mint. **Attack A** not cleanly closed (Bitcoin-class / `D_mint`). | This **is** zkBTC's product claim (§1.1.1). The user is the honest 1-of-N. No trusted gatekeeper for Attack B or operator-theft safety. Prefix residual is load-bearing (R-09 item 6). |
| **A** | Open registration + pooled + **R-09** + a gatekeeper | **Attack B closed by R-09.** **Attack A closed cleanly by R-04** conditional on an honest gatekeeper. SoF screening in addition. | Gated deployment when canonical-mint and source-of-funds checks are wanted. The gatekeeper is **not** the Attack-B close and **MUST NOT** be described as what makes zkBTC trustless. A compromised gatekeeper can re-open Attack A, not Attack B (if R-09 holds). |
| **B** | No gatekeeper + pooled + a **closed, genesis-enumerated, gate-A(1)** operator set (gives up open registration; R-09-equivalent by enumeration) | Attack B closed by enumeration; **Attack A** operator-oracle / `D_mint`; abandons open join | Distinct closed-enumeration policy P′. **NOT** the product. |
| **C (FORBIDDEN)** | Open registration + pooled **without** R-09 (with or without a gatekeeper's R-08 as the *only* Attack-B story) | **UNSOUND** | A per-epoch club that can omit honest operators re-opens Attack B. No constructible provenance defense (§3.5.5). **MUST NOT** be deployed or marketed as trust-minimized or as effectively trustless. |

**Bottom line (MUST state):** zkBTC is **effectively trustless** as the self-operator profile (Corner D): you join S before the first mint, you refuse malicious graphs, operators cannot steal under the §5 conditions, and you can exit yourself. A gatekeeper is **optional** and closes Attack A cleanly plus SoF when designated; it is **not** required for Attack B. Open registration + pooled **without** R-09 is **UNSOUND**. Cross-refs: §1.1.1, §5 residual 9, §6.4, §6.6. **Scope note:** this table concerns the two **mint-settlement** drain attacks (A/B); the **full** reserve-safety conditions — 1-of-N setup honesty, an active honest challenger acting in-window, sound circuit/graph crypto, and the redeem-side payout-canonicity residual — are stated in the §5 trust matrix and summarised in the README's "When is zkBTC safe" statement.

```
depositor_base_commitment = H("zkCoins/v2/DepositorBase", depositor_base ‖ db_blind)
```

carried as committed leaf data in the deposit taproot beside the recipient commitment and refund leaf. Clause (b) opens it and checks `Pk_mint` derivation against the opened `depositor_base` (even-y normalised per M-01).

#### 3.2.2 One-shot mint account (consumed-key uniqueness)

Every vaulted deposit spawns a fresh **one-shot mint account** whose genesis key is `Pk₀ = Pk_mint`. The TS3 mint **MUST** be that account's genesis transition:

- `prev_account_state.send_counter == 0`
- `prev_account_state.current_pubkey == Pk_mint`

The mint consumes `Pk_mint` and publishes `(Pk_mint, R)` as its on-chain nullifier. First-occurrence on `Pk_mint` (specification.md §3.6 / §3.7) makes a second settled mint against the same vault outpoint impossible — the exact token-standard-2 genesis mechanism (specification.md §6.5 clause (f)) reused **per vault outpoint**.

**Naked-aux-key gap (normative rationale).** A design that merely "additionally publishes" an auxiliary key without consuming it would **not** be checked by any compliance-predicate clause. A second mint could still settle under a different consumed key. That is why the mint key **MUST BE** the consumed key of the mint transition, not a naked auxiliary object.

**Front-running.**

- **Gatekeeper-gated:** a third party **cannot** burn the `Pk_mint` slot: accumulator admission requires a BIP-340 signature over `m_state` by `Pk_mint`, and only the gatekeeper knows `sk_mint`.
- **No-gatekeeper:** only the holder of `depositor_base` knows `sk_mint`; the in-circuit commitment of `depositor_base` prevents a stranger from choosing a different base for the same outpoint.

### 3.3 Mint clauses (normative, in-circuit)

When `asset_issuance` is present and `issuance_version == 3`, the **v2 circuit surface** of `C` **MUST** verify all of the following (style parallel to specification.md §6.5 (a)–(g)). Clause numbering (a)–(h) is local to this standard; it hooks into specification.md §2.1 clause 3 the same way standards 1 and 2 do.

- **(a)** `issuance_version == 3` — this branch accepts only TS3 mints.
- **(b) Base + vault-outpoint binding.** The mint account's `owner` equals `H(Pk_mint ‖ nk_commit)`. The circuit verifies in-circuit the full §3.2.1 derivation:

  ```
  Pk_mint == BIP340_even_y( Pk_base + h · G )
  ```

  where `h` is the mod-`n` reduction of `Hc("zkCoins/v2/MintKey", asset_id ‖ vault_outpoint)` (with the §3.2.1 redraw/counter rules and even-y base normalisation), and `Pk_base` is:

  - **Gatekeeper-gated:** the even-y lift of `gatekeeper` from `asset_id`;
  - **No-gatekeeper:** the even-y lift of `depositor_base` opened from the deposit-taproot commitment (LCP leaf data).

  This simultaneously binds the mint to the **mode base** and to the **vault outpoint**.
- **(c)** `asset_id` recomputation per §3.1 (`AssetIdV3` preimage including `gatekeeper`, `operator_set_root`, `H(vault_template)`; no `refund_timelock`).
- **(d)** `terms_hash` recomputation per §3.1 (`gatekeeper`, `operator_set_root`, `H(vault_template)`).
- **(e) Vault-backing reality (LCP sub-proof).** Recursively verify a Bitcoin light-client sub-proof — normatively a **separate recursive Plonky2 circuit** whose root is verified inside `C` (the BRIDGE_MVP.md §3.2 recursive-LCP decision remains valid; inlining SHA-256d header chains into the main compliance budget is not required). The LCP statement **MUST** establish all of:
  1. **Header chain.** A chain of Bitcoin headers from a **pinned checkpoint** (checkpoint value is a circuit / S2C consensus parameter of the v2 release — §3.7.2, §11); each header is PoW-valid and links to its predecessor; cumulative work is computed.
  2. **`MoveToBacked` vault outpoint (not the user's deposit outpoint).** The proven UTXO is the **backing-only vault output** `(vault_txid, vault_vout)` created by a confirmed **`MoveToBacked`** transaction — the N-of-N/BitVM2 vault UTXO that consumes the user's deposit output. `Pk_mint` derivation uses this same vault outpoint (§3.2.1).
  3. **N-of-N witness proof (MUST — closes the drain-class private-fork hole).** The LCP **MUST** prove that the `MoveToBacked` transaction spent the user's deposit output through the **vault leaf under the N-of-N (BitVM2 aggregate) signature** produced at setup — i.e. the spend is authenticated by the operator set's pre-signed graph path, not by the user's refund leaf.  
     **Rationale:** without this, an attacker could, in a private fork, spend their own deposit via the refund leaf into a look-alike `vault_descriptor` output and fabricate unlimited unbacked "MoveToBacked"s with no operator, amortising one discarded fork over unlimited fake mints. Requiring the N-of-N witness makes forging a `MoveToBacked` require full operator collusion, which the 1-of-N setup-honesty assumption excludes.
  4. **Vault script instance byte-equality + operator-set membership (MUST — B-02 + Part 2; two-level admission).** Output `vault_vout` pays exactly `amount` sats to a script that is **byte-equal** to `instantiate(vault_template, this asset_id, agg_key, epoch)` (§3.1.1 — NUMS internal key + ordered BitVM2 assert/challenge/disprove tapleaf set; **no** depositor or cooperative refund leaf), **and** `agg_key` is admitted via the **two-level** chain rooted at this asset's `operator_set_root` **policy**: `agg_key` is the aggregate of the epoch's **epoch signing keys** whose `reg_root_E` was validly formed under policy P **and satisfies R-09** (identity-set superset of the previous epoch), membership proven **against the root exposed by `C_lcp`**, and the outer circuit `C` **MUST** check `C_lcp.operator_set_root == IssuanceTerms_v3.operator_set_root` (asset-bound **policy-root** equality — §3.3.1). How `reg_root_E` / `agg_key_E` are formed and validated (identity keys, epoch signing keys, bond, PoP, MuSig2 KeyAgg, ceremony, canonicity) is specified in **§4.1.2**: in-circuit the LCP establishes PoW-valid commitment of `reg_root_E` at adequate depth (same LCP power as `MoveToBacked` — **not** canonicity); canonicity of `reg_root_E` is the gatekeeper's **R-04** duty when designated (same anchor as `MoveToBacked`); **Attack-B safety rests on R-09** (identity-set completeness of already-admitted keys is **safety**; completeness of *new* joiners is a liveness residual — §4.1.2). Optional R-08 is not the close. A free-standing boolean `operator_set_member_ok` is **not** sufficient. The recipient commitment of clause (g) (and, in no-gatekeeper mode, the `depositor_base` commitment) is carried as committed leaf data consistent with the deposit → vault path (§4.2).  
     **Attack closed:** without recursive root binding, an attacker proves membership of a self-controlled `agg_key` under an **attacker-chosen** root, a bare `operator_set_member_ok = true` passes, and the outer circuit cannot tell — enabling a foreign-root self-controlled vault drain under an honest asset. Exposing and equating `operator_set_root` makes that *foreign-root* attack fail. **Note:** under open registration this does **not** alone close **Attack B** (self-controlled *in-set* vault under the correct policy root) — that requires **R-09** (§3.1.2).
  5. **`MoveToBacked` confirmation depth (MUST — R-01 / R-04 inverted binding).** Confirmations of the `MoveToBacked` block below the proven tip satisfy  
     `depth ≥ D_mint`  
     (and, when an upper slack is configured, `depth ∈ [D_mint, D_mint + S]`),  
     where `D_mint` and optional `S` are normative `PROVISIONAL` parameters (§4.4; on the order of the bridge security horizon, e.g. `D_mint ≈ 2016` blocks — long finality is acceptable per REQ-4).  
     **The mint proves "`MoveToBacked` confirmed at depth ≥ `D_mint`"** — not "vault output unspent in a host-side window." Because the backing-only output `MoveToBacked` creates has **no refund path** (neither depositor nor cooperative — §3.1.1 / §4.2), a settled mint corresponds to a permanent backing-only vault UTXO. That correspondence is proven **in-circuit** and is recursively inherited by every later transition; downstream holders need **no** host-side re-check of Bitcoin vault state or mint freshness. There is **no** in-circuit non-spend-to-tip proof, **no** host-side freshness rule, **no** `tip_height` ProofData field, and **no** mint-window CSV race against a refund leaf (there is none).
- **(f) Genesis binding / uniqueness.** `prev_account_state.send_counter == 0` **and** `prev_account_state.current_pubkey == Pk_mint` (see §3.2). Combined with first-occurrence on `Pk_mint`, a second settled mint against the same vault outpoint is impossible.
- **(g) Recipient binding.** The deposit taproot commits

  ```
  recipient_commitment = H("zkCoins/v2/DepositRecipient", recipient ‖ rc_blind)
  ```

  in the taproot tree beside the refund leaf (placement is bridge detail, §4.2). The circuit verifies that the minted output coin's `recipient` opens that commitment. Neither the gatekeeper nor any minter can redirect a mint to a different address after the user has deposited; the circuit **MUST** reject any minted coin whose `recipient` does not open the deposit commitment (custody-class protection; same lesson as out-intent / blind-signing findings in the main specification's history).
- **(h) Amount discipline.** `amount == vault-output amount` exactly — the **only** in-circuit amount rule. Denomination membership is bridge-side (§4.4). Emission mirrors token-standard-2 clause (g): for the minted asset `a`, `Out(a) == Mint(a) == amount`, `In(a) == 0`; the mint **MUST NOT** self-credit into balances, `received_coins[]`, or this transition's coin-history; credit only via a later clause-10 receive.

**Dispatch.** TS3 is one more branch of the **same** circuit `C`. The v2 circuit ships standards 1, 2, and 3 as branches so the new lineage universe is complete from genesis (§3.7). Adding the branch extends the version dispatch of specification.md §2.1 clause 3, which today accepts only `issuance_version == 1` or `2` on the v1 surface; on the v2 surface the accepted set is `{1, 2, 3}`.

#### 3.3.1 LCP sub-proof interface (normative sketch)

The recursive LCP is a separate circuit `C_lcp` (name provisional) whose public outputs feed the TS3 mint branch. Minimum public interface:

```
LCP_Public = {
  checkpoint_hash,          // pinned Bitcoin header hash (circuit / S2C parameter of the v2 release)
  tip_hash,                 // proven tip
  cumulative_work,          // total work from checkpoint to tip
  vault_txid,               // 32-byte MoveToBacked txid (the vault outpoint, NOT the user deposit)
  vault_vout,               // u32
  vault_amount,             // u64 sats
  vault_script_bytes,       // exact scriptPubKey of the backing-only vault output
  agg_key,                  // 32-byte N-of-N aggregate key used in instantiate (presigning set is N-of-N)
  epoch,                    // u64 deposit epoch used in instantiate
  operator_set_root,        // 32-byte **policy** root proved against (open-registration policy;
                            //   agg_key admitted via epoch registration commitment under this policy)
                            //   (MUST — R-02)
  reg_root,                 // 32-byte epoch registration commitment reg_root_E (two-level chain §3.1.2);
                            //   commits the set of operators validly registered for this epoch under policy P;
                            //   formed and checked per §4.1.2 (bond, PoP, Merkle commitment, KeyAgg);
                            //   in-circuit: PoW-valid commitment at adequate depth (same LCP power as
                            //   MoveToBacked — canonicity NOT established in-circuit; gatekeeper R-04
                            //   is the canonicity anchor for reg_root_E as for MoveToBacked)
  n_of_n_witness_ok,        // boolean / bit: MoveToBacked spent the deposit via the N-of-N vault leaf
  recipient_commitment,     // as in clause (g)
  depositor_base_commitment,// present / opened in no-gatekeeper mode; zero sentinel otherwise
  depth                     // confirmations of MoveToBacked below tip; MUST be ≥ D_mint
                            //   (optionally ≤ D_mint + S when upper slack is configured)
}
```

**Recursive operator-set root binding (MUST — closes self-controlled-root attack).** `C_lcp` **MUST** expose the `operator_set_root` it proved membership against as a public output; the two-level admission proof inside `C_lcp` is against **that** policy root (policy root → epoch `reg_root` → `agg_key`). The outer mint circuit `C` **MUST** verify

```
C_lcp.operator_set_root == IssuanceTerms_v3.operator_set_root
```

(equality with the asset-bound **policy** root). `C` **MUST NOT** rely on a free-standing `operator_set_member_ok` boolean: such a boolean can be `true` under an attacker-chosen root while the outer circuit only sees the bit. Equivalently, `C` **MAY** verify the membership Merkle path directly against the asset-bound `IssuanceTerms_v3.operator_set_root` (same root equality, no bare boolean).

**Attack closed (foreign-root).** Without this binding an attacker proves membership of a self-controlled `agg_key` under an **attacker root**, sets `operator_set_member_ok = true`, and the outer circuit cannot distinguish that from membership under the honest asset root → unbacked mint under a foreign-root self-controlled vault, redeemable cross-graph against honest vaults (drain). Root equality makes the *foreign-root* attack fail: a foreign root does not equal `IssuanceTerms_v3.operator_set_root`. Under open registration this does **not** alone close **Attack B** (self-controlled *in-set* vault) — that requires **R-09** (§3.1.2).

The mint branch **MUST** check equality of `vault_amount` with `asset_issuance.amount`, **byte-equality** of `vault_script_bytes` with `instantiate(vault_template, this asset_id, agg_key, epoch)`, `C_lcp.operator_set_root == IssuanceTerms_v3.operator_set_root`, `n_of_n_witness_ok == true`, depth ≥ `D_mint` (and ≤ `D_mint + S` when upper slack is configured), equality of `recipient_commitment` with the opening used for the minted coin's `recipient`, and (in no-gatekeeper mode) opening of `depositor_base_commitment` consistent with clause (b). The exact bit-encoding of the N-of-N witness check and operator-set membership proof is a BitVM2-graph / launch-parameter detail; the **semantic** requirements (operator-set authentication of the `MoveToBacked` spend; two-level admission of `agg_key` under the **asset-bound** policy `operator_set_root`) are normative here.

#### 3.3.2 Binding via MoveToBacked (normative — R-01 / R-04; replaces host-side freshness)

Host-side mint freshness is **not** a security source under this design. There is **no** `tip_height` ProofData field, **no** inscription-height rule `h_inscr < tip_height + W`, **no** freshness window `W`, and **no** mint-window CSV term `D_mint + S + W + 1`.

Soundness of settled mint ↔ permanent backing rests on:

1. **`MoveToBacked` is a fixed pre-signed graph transaction** (content fixed at setup → txid fixed → the downstream reimbursement graph stays pre-signable). It is nullifier-free and ordinary on Bitcoin. It **consumes** the depositor-refundable deposit output and **creates** the backing-only vault output (§4.2).
2. **Firing requires a co-sign gate (consent + anti-griefing — MUST; INV-01).** `MoveToBacked` **MUST** require the **depositor's co-signature in both modes** (gatekeeper and no-gatekeeper) — so the contribution to the shared reserve is **consented**, not imposed. In **gatekeeper mode**, the **gatekeeper's co-signature is additionally required** (anti-griefing: a third party cannot fire after a gatekeeper refusal). Implementation: a co-sign tapleaf or additional required signature(s) on the pre-signed `MoveToBacked` path.
3. **The mint LCP proves `MoveToBacked` confirmed at depth ≥ `D_mint`** (clause (e) point 5) on *some* header chain. Because the backing-only output has **no** refund path, that confirmation is a permanent commitment of the deposited BTC to the vault graph **on the proven chain**.
4. **Canonical-chain anchor at mint settlement (MUST — R-04; gatekeeper mode; covers `MoveToBacked` and `reg_root_E`).** The LCP alone does **not** bind the proven header chain to the verifier's **canonical** Bitcoin view — neither for `MoveToBacked` nor for `reg_root_E` (same LCP limit; §4.1.2). In gatekeeper mode, the gatekeeper **withholds** the final `Pk_mint` signature until it has verified, on its **own canonical Bitcoin view**, that (i) `MoveToBacked` is confirmed at depth ≥ `D_mint` on the canonical chain and the deposit was not refunded there, **and** (ii) the epoch's `reg_root_E` is the canonical registration commitment for that epoch (§3.2.1.1 / §4.1.2). Co-signed `MoveToBacked` alone is insufficient (setup signatures are valid on any fork). In no-gatekeeper mode this external Attack-A anchor is absent (Bitcoin-class residual / `D_mint`). Attack B remains closed by R-09. Open registration + pooled **without** R-09 remains **Corner C / UNSOUND** (§3.2.1.2, §6.4).
5. **No host-side re-check for downstream holders.** Downstream CoinProof receivers inherit the in-circuit statement recursively; they **MUST NOT** be required to re-check Bitcoin vault unspentness or mint inscription freshness. (The gatekeeper's canonical check is a **mint-time** observer role, not a transitive holder duty.)

### 3.4 Deep-finality canonicity (normative)

The LCP proves `MoveToBacked` at depth ≥ `D_mint` on a PoW-valid header chain (deep enough that private-fork mining for the mint value is prohibitively costly and very unlikely to succeed for a miner comfortably below 50%, with the success probability rising as the margin to 50% narrows, as a pure mining attack) **and** the N-of-N witness (clause (e) point 3) **and** operator-set membership (clause (e) point 4), including that `reg_root_E` is committed on a PoW-valid chain at adequate depth. That is **necessary but not sufficient** to bind the mint to the **canonical** Bitcoin chain: the LCP proves confirmation on *some* header chain, not that that chain is the verifier's canonical tip — for **either** `MoveToBacked` **or** `reg_root_E`.

**Gatekeeper mode (closes R-04).** Canonical binding is supplied by the **gatekeeper as canonical-chain anchor** (§3.2.1.1): mint settlement requires the gatekeeper's `Pk_mint` signature, and the gatekeeper issues it **only after** confirming on its **own canonical Bitcoin view** that (i) `MoveToBacked` (depth ≥ `D_mint`, deposit not refunded) is canonical **and** (ii) `reg_root_E` is the canonical registration commitment for the epoch (not a private-fork / substituted root). Private-fork `MoveToBacked` or a substituted `reg_root_E` therefore cannot settle a mint. Downstream CoinProof receivers **MUST NOT** be required to re-check Bitcoin deposit/vault canonicity: the vault outpoint and its canonicity opening are **not** transitively available through later transfers (parent specification.md deliberately lets a verifier validate the latest proof without fetching prior transitions), and under the deep-finality + N-of-N + operator-set + backing-only + **gatekeeper canonical-anchor** construction they are **no longer needed** for later holders.

**No-gatekeeper mode (R-04 not closed; Attack B closed by R-09).** With depositor-anchored `Pk_mint`, there is **no external canonical observer** (Attack A not cleanly closed; no anchor for `MoveToBacked` or `reg_root_E` — Bitcoin-class residual / `D_mint`). **Attack B is closed by R-09** provided S is growth-only and the intended honest operator is in S before the first mint (§1.1.1 / §3.1.2). Open registration + pooled **without** R-09 is **Corner C / UNSOUND** — see §3.2.1.2 and §6.4. This mode **with** R-09 **is** the product default and **MUST** be presented as effectively trustless in the sense of §1.1.1, not as "requires a gatekeeper."

Soundness source:

- The LCP binds the mint to a confirmed **`MoveToBacked`** that created a **backing-only** vault UTXO (no depositor refund, no cooperative refund), not a historical user-deposit inclusion and not a "vault still unspent" host-side claim.
- Depth ≥ `D_mint` makes pure private-fork fabrication of `MoveToBacked` prohibitively costly and, for a miner comfortably below 50%, very unlikely to succeed at the mint value (the success probability rises as the margin to 50% narrows); the N-of-N witness excludes refund-leaf private-fork forgeries without full operator collusion at setup. **Neither alone binds the proven chain to the canonical tip** — that is the gatekeeper's mint-signing duty (R-04) **when a gatekeeper is designated**, covering **both** `MoveToBacked` **and** `reg_root_E`. Without a gatekeeper, Attack A is Bitcoin-class / `D_mint` (Corner D).
- NUMS internal key + pre-signed-graph-only leaves (no live free-form CHECKSIG) keep vault spends on the BitVM2 assert/challenge/disprove graph only.
- `C_lcp.operator_set_root == IssuanceTerms_v3.operator_set_root` excludes attacker-supplied self-controlled operator sets under a *foreign* root (membership is against the exposed, asset-bound policy root — not a bare boolean). Under open registration this does **not** alone close **Attack B** (self-controlled *in-set* vault); that requires **R-09** (§3.1.2). Registration completeness of *new joiners* in `reg_root_E` is a **liveness/fairness** residual; completeness of already-admitted keys is **safety** — Attack-B safety is R-09 (§4.1.2).
- There is **no** host-side freshness machinery and **no** refund-vs-mint-window CSV race (backing-only has no refund leaf).

**Optional first-recipient check (SHOULD).** The first recipient of a TS3-minted coin (who holds the vault data out-of-band with the mint delivery) **SHOULD** additionally confirm that `(vault_txid, vault_vout)` is present at depth ≥ `D_mint` in **its own** canonical chain view. This is a defence-in-depth hygiene check, not a soundness requirement for later holders (and does not replace the gatekeeper's mint-time canonical-anchor duty for `MoveToBacked` and `reg_root_E` **when a gatekeeper is designated**).

**Residual (accepted, D-16 class).** A reorg deeper than `D_mint` that orphans the proven `MoveToBacked` is a bounded accepted finality boundary (risks.md D-16 class). It is not closed by transitive canonicity transport.

**Residual (accepted, consented irrevocable reserve contribution — R-01 / INV-01).** If `MoveToBacked` fires but the mint never settles, the vaulted BTC is **not** merely frozen recoverable BTC: because reimbursement is cross-graph (any same-asset in-set vault can back a redeem), it becomes an **irrevocable, consented contribution to the shared reserve** and **MAY** be consumed by another holder's redeem. Firing requires the **depositor's co-signature in both modes** (§3.3.2 / §4.2), so the contribution is **consented**, not imposed. The depositor's unilateral escape for the "never processed / never `MoveToBacked`" case remains the pre-`MoveToBacked` deposit refund leaf.

### 3.5 Redeem transition (normative)

A redeem is an ordinary holder transition on the **v2 circuit surface**, not a separate ProofType and not a global SMT insertion.

#### 3.5.1 Balance shape

- `In(zkBTC) == redeem_amount`
- `Out(zkBTC) == 0` (no outputs of the asset; the difference is burned by conservation no-inflation — intentional value destruction for peg-out)
- `redeem_amount` **MUST** be an available payout denomination of the current bridge epoch (bridge rule §4.4). In-circuit, only the commitment binds the amount; denomination membership is enforced by the bridge when accepting a redemption request.

#### 3.5.2 ProofData field (v2 layout)

The v2 `ProofData` layout is the six v1 fields plus one new field (exact serialization pin in §3.7.2):

```
redeem_commitment = Hc("zkCoins/v2/RedeemCommit",
                       asset_id ‖ redeem_amount ‖ btc_recipient ‖ max_fee ‖ redeem_blind)
```

- Hiding: chain observers see only the field digest inside `H(ProofData)`, not the opening of `redeem_commitment`.
- `btc_recipient` is a 32-byte x-only taproot key; the payout output is P2TR to it.
- **`max_fee` (MUST — NH-03):** a `u64` satoshi ceiling on the operator's fee, committed inside `redeem_commitment`. The commitment **MUST** satisfy `max_fee < redeem_amount`. The payout **MUST** pay `btc_recipient` exactly the non-negative wide-integer difference `redeem_amount − max_fee` as a lower bound — i.e. at least `redeem_amount − max_fee`, computed with the parent specification.md §2.6 wide-integer gadgets so there is **no underflow and no zero-payout path from wrapping** (see §3.5.6 and §4.3.2). Binding a **ceiling** rather than an exact fixed fee is deliberate: a fee spike between redeem burn and fronting would otherwise leave the coin permanently unservable (loss of funds). The operator sets its actual fee `≤ max_fee` at fronting time.
- For **non-redeem** transitions (including **TS3 mints** and ordinary transfers), `redeem_commitment` **MUST** equal the all-zero 32-byte sentinel `0x00…00` (32 zero bytes). The circuit **MUST** accept the zero sentinel on non-redeem paths and **MUST** reject a zero sentinel when a redeem path is claimed (when `Out(zkBTC) == 0` and `In(zkBTC) > 0` for this asset under the redeem branch, or an explicit redeem flag if the implementation introduces one as an internal witness bit — either way the public field is non-zero iff a redeem is proven).
- There is **no** `tip_height` field and **no** per-branch tip/freshness sentinel (NEW-HOLE-01 resolved by removal).
#### 3.5.3 Redeem ID is the transition nullifier

**The redeem ID is the transition's own on-chain nullifier `(Pkᵢ, Rᵢ)`.** Sign-to-contract already binds `Rᵢ` to `H(ProofData)` and therefore to `redeem_commitment`. First-occurrence makes the **transition** ID unique. The bridge **MUST** key reimbursement claims on `(Pkᵢ, Rᵢ)`. **No separate redeem-nullifier object exists** (no global `burned_coins_smt`; that BRIDGE_MVP sketch is superseded).

#### 3.5.4 Off-chain opening and bridge consumption

The holder reveals the opening `(redeem_amount, btc_recipient, max_fee, redeem_blind)` **off-chain** to the bridge / operators as the redemption request. Chain observers see only that some transition happened (until a reimbursement claim marker appears — §8.2). The bridge fraud-proof circuit consumes the opening together with the settled nullifier. Third parties can be shown a specification.md §5.6-style trail for the redeem transition when the holder discloses the bundle.

#### 3.5.5 Transition uniqueness vs reimbursement uniqueness

- **Transition uniqueness:** one redeem transition = one `(Pkᵢ, Rᵢ)`. Re-proving the same transition cannot re-anchor: first-occurrence rejects a second publication of `Pkᵢ`. First-occurrence gives **transition** uniqueness, **not** reimbursement uniqueness.
- **Reimbursement uniqueness (MUST — claim-consumed marker):** first-occurrence alone does **not** prevent the same redeem ID from reimbursing multiple vault UTXOs across independent per-deposit BitVM2 graphs. Binding a specific free vault outpoint into `redeem_commitment` is **not** constructible (the holder does not know which free outpoint will serve the claim at redeem time; two holders binding the same outpoint would permanently strand the second burn). Instead:
  1. The operator's **claim transaction publicly commits the redeem ID `(Pkᵢ, Rᵢ)`** on Bitcoin (a **claim-consumption marker**).
  2. The reimbursement fraud statement includes the conjunct: **no prior confirmed, valid, unchallenged reimbursement claim carries the same `(Pkᵢ, Rᵢ)`** (§4.3.2) — **slashed / successfully-counterproved / failed markers are excluded** from the uniqueness set (NEW-02).
  3. A second claim for the same redeem is **counterprovable** by a Bitcoin inclusion proof of an earlier **valid unchallenged** claim — the same 1-honest-watchtower challenge class as any other false claim. A malicious operator **MUST NOT** be able to poison a redeem ID with a slashed marker and block an honest retry.
- **Payout binding and claim-marker uniqueness (MUST — NH-02 / NEW-02 / NEW-04):** the payout is an ordinary P2TR owned by `btc_recipient`; the operator **cannot** spend it (no key), so "consume the payout outpoint" is **not** a literal UTXO spend. Instead:
  1. Define a **claim-marker namespace**: the operator's reimbursement claim publicly commits the tuple `(Pkᵢ, Rᵢ, payout_txid, payout_vout)` as a **first-occurrence marker** in that namespace on Bitcoin.
  2. **Uniqueness = first-marker rule over the valid set only:** a second claim reusing the same `(Pkᵢ, Rᵢ)` **or** the same `(payout_txid, payout_vout)` is **counterprovable** by a Bitcoin inclusion proof of an earlier **valid, unchallenged** marker (same 1-honest-watchtower class as claim-consumption). The operator does **not** spend the recipient's UTXO.
  3. **Slashed-marker exclusion (MUST — NEW-02):** only a **valid, unchallenged** claim marker consumes the redeem ID / payout outpoint for uniqueness. A marker that is **slashed**, **successfully counterproved**, or otherwise **failed** under the challenge path is **excluded** from the uniqueness set and **MUST NOT** block a later honest claim for the same redeem ID or payout outpoint.
  4. **Non-transferable, claimant-committed, sole-funded payout (MUST — NEW-04).** Reimbursement fairness requires that the operator reimbursed from the vault is exactly the one that funded the payout to the holder, and that no other party can claim it. Attributing a Bitcoin payment's funding to one party proved subtle — three earlier formulations (gross/net input value-accounting, `SIGHASH_SINGLE` index-pairing, and a `SIGHASH_ALL`-only identity commitment) were each found insufficient in review — so this rule pairs a committed identity with a **mechanized sole-funder check**, and does **not** rely on any behavioural "an honest operator will not co-sign" assumption:
     - **Sole funder, single-party-authorised (MUST — the mechanized core).** **Every** input of the payout transaction **MUST** be authorised by the **claiming operator's registered identity** (its bonded key, or a funding-key set bound to it at registration), **and each input's spending condition MUST require only that identity** — no input may require a co-signature from any key **not** bound to the claimant. The claimant is therefore the transaction's **sole, single-party funder**; a payout transaction containing **any** input the claimant did not **solely** authorise — a **separate** input, **or** a **jointly-signed** (2-of-2 / multisig) input co-controlled by another party — is **not claimable**. This is a check on the transaction, not a behavioural assumption: a co-funded transaction in which a second party supplies value, whether as a **separate** input or a **jointly-signed** one, **fails** this rule, so a minority/dust claimant **cannot** ride on another operator's funding. (The only remaining way a third party's capital can reach the payout is by **gifting** the claimant a UTXO it then **solely** controls — which makes the claimant the genuine owner and funder of record, not a theft.)
     - the payout transaction **MUST** carry a **single, hiding, binding claimant-identity commitment** (e.g. `H(claiming operator's identity ‖ redeem ID (Pkᵢ, Rᵢ) ‖ blind)` in an `OP_RETURN` output or an equivalent field, **opened only in the reimbursement claim** — exact encoding launch-pinned, NEW-03 honesty), binding the payout to this claimant and this redeem. Because the commitment is **hiding**, the payout does **not** reveal the redeem↔payout link on-chain until the claim opens it (preserving the §8.2 indistinguishability-until-claim boundary); a payout transaction carrying **zero or more than one** claimant commitment is **not** claimable;
     - **all** payout-transaction inputs **MUST** be SegWit (v0 or Taproot; empty `scriptSig`), so the `txid` is **non-malleable** — a legacy co-input's malleable ECDSA `scriptSig` would otherwise let a third party change `txid` without invalidating the claimant's signature;
     - the claimant **MUST** sign the payout transaction under a **full-transaction commitment** (`SIGHASH_ALL` — all inputs and all outputs; **not** `ANYONECANPAY`);
     - the output at `payout_vout` **MUST** pay `btc_recipient` at least `redeem_amount − max_fee` (NH-03), funded from the claimant's own funds (never vault value — NH-01);
     - the reimbursement fraud statement **MUST** verify that the **claiming** operator's identity **equals** the committed identity **and** authorised **every** input (sole funder); a claim by any other party, or against a payout carrying any non-claimant input, **fails**.
     **Why this closes the known claim-hijack variants.** (i) **Sole funder + single-party authorisation** make the claimant the only party able to fund any input, so a co-funded payout — whether the second party's value enters as a **separate** input or a **jointly-signed** one — is **not claimable**; this closes the co-signed / joint-input zero-net-funding break **mechanically**, with no "honest won't co-sign" assumption. (ii) The **non-transferable identity commitment** means only the committed operator can claim, so a different operator cannot claim an honest operator's payout. (iii) **Non-malleability** (`SIGHASH_ALL` + SegWit-only inputs) prevents appending, relocating an already-signed input, duplicating the payout output, and `txid` mutation. Together these supersede the gross-input, net-output, index-pairing, and `SIGHASH_ALL`-only checks. **Honest status (do not overclaim).** Reimbursement-funding attribution proved genuinely subtle — several formulations were falsified in review — because Bitcoin exposes **spending authority**, not economic provenance. This rule closes the **known** claim-hijack variants; the exact single-party-input-authorisation check, and any residual economic-attribution question beyond it, are a specific focus of the external audit (**G4**) and the Plonky2→BitVM2 conversion (**G3**). The **invariant** — a non-transferable claim bound to the **sole, single-party funding** operator — is normative now.
  5. **Ordering (keep):** the payout confirmation height **MUST** be **>** the first-occurrence height of `(Pkᵢ, Rᵢ)`.
  6. "**Consume**" in this document means the logical first-marker over the **valid unchallenged** set, **not** a UTXO spend. This closes historical/reused-output replay without requiring the operator to control the payout key, and without letting a slashed poison-marker freeze an honest redeem.

**Finding-ID note.** **NEW-02** is the claim-marker **uniqueness / slashed-marker exclusion** rule (§3.5.5 items 2–3 / §4.3.2 item 10). **NEW-04** is the **non-transferable, claimant-committed, sole-funded payout** rule (§3.5.5 item 4 / §4.3.2 item 12). The two are distinct and both are in scope for the external audit (G4).

#### 3.5.6 Payout template mapping (bridge-facing)

The holder specifies the desired payout output (`btc_recipient`, amount ≥ `redeem_amount − max_fee`); the fronting operator constructs, **fully funds from its own SegWit inputs**, and signs the payout transaction under a **full-transaction commitment** (`SIGHASH_ALL` — §3.5.5 point 4). The transaction **MUST** carry a **single, hiding claimant-identity commitment** — a blinded commitment to `(the operator's bonded key, redeem ID (Pkᵢ, Rᵢ))`, opened only in the reimbursement claim — and **MUST** use only SegWit inputs, so it is **non-malleable** and the claim is **non-transferable**: only the committed operator can be reimbursed for it. The operator **MUST** also be the payout's **sole funder** (every input authorised by its registered identity — §3.5.5 item 4), which is what mechanically closes the co-signed multi-claimant break; the SegWit-only + `SIGHASH_ALL` form closes the BIP-341 pair-relocation hijack (NEW-04; exact encoding is a G4-audit focus). The payout transaction:

- The output identified by `payout_vout` (conventionally output 0): P2TR to `btc_recipient`, amount **≥ `redeem_amount − max_fee`** where `max_fee < redeem_amount` and the subtraction is an exact non-negative wide-integer (NH-03; parent specification.md §2.6 gadgets); the operator's actual fee is market-set at fronting time subject to that ceiling — §4.4.
- Any operator **MAY** fund the payout, but **MUST** be its **sole, single-party funder** — **every** input authorised **solely** by the operator's registered identity (no third-party inputs, and **no jointly-signed / multisig input co-controlled by another party**) — committing the whole transaction with `SIGHASH_ALL` (§3.5.5 item 4 / NEW-04). A co-funded transaction (a separate **or** a jointly-signed input supplied by another party) is **not** claimable.

The bridge fraud statement binds this template's paid output to the opening of `redeem_commitment`. An operator that pays a different address, or pays strictly less than `redeem_amount − max_fee`, **MUST** fail the reimbursement claim under an honest challenge path.

#### 3.5.7 Why not a separate BurnProof or burned SMT

Earlier research (`BRIDGE_MVP.md` §4, `BITVM_BRIDGE.md` §4) proposed a dedicated `BurnProof` ProofType emitting public `(burn_amount, btc_recipient, withdrawal_nonce)` and a global `burned_coins_smt`. That design is incompatible with:

- post-#97 on-chain nullifiers as the sole Bitcoin-published object `(Pkᵢ, Rᵢ)`;
- specification.md §2.2 single circuit `C` (InitialProof / AccountUpdateProof only);
- specification.md §6.5 version-branch dispatch for issuance (redemption is a holder transition, not a new ProofType).

The TS3 design reuses ordinary AccountUpdateProof transitions: value leaves circulation by `Out == 0` with a non-zero `redeem_commitment`, and uniqueness is the existing first-occurrence rule. No new on-chain object is introduced for burns.

### 3.6 Supply auditability

**Publicly verifiable from chain data alone = a conditional upper bound (MUST — M-04):**

```
circulating zkBTC  ≤  BTC locked in the public vault UTXO set
```

This inequality is a **conditional audit property**, not an unconditional invariant. It holds **under the reserve-safety assumptions of §5**: per-epoch **1-of-N setup honesty** (at least one honest signer deleted its **epoch signing secret** / refused a malicious graph; identity keys stay) **AND R-09 (growth-only S plus the first-mint / prefix rule of item 6 — no Attack B)** **AND, when a gatekeeper is designated, R-04 (canonical anchor — no Attack A)** **AND ≥1 honest challenger** enforcing the §4.3.2 fraud-statement rule (no successful unchallenged fraudulent/duplicate reimbursement) — i.e. **no successful Attack A, no successful Attack B, and no unchallenged fraudulent reimbursement**. Concrete counterexamples that **break** the inequality: (i) a successful **Attack A** (private-fork unbacked mint via skipped/absent R-04) mints against a non-canonical vault that is refunded on the canonical chain → circulating zkBTC with no remaining canonical vault balance; (ii) a successful **Attack B** (self-controlled Sybil-vault drain if R-09 is absent — Corner C — **or** via the prefix residual of R-09 item 6) mints against a real vault then drains that vault via a presigned malicious graph → circulating zkBTC exceeds remaining honest backing for that vault (and, via cross-graph redeem, can drain other vaults); (iii) an **unchallenged fraudulent or duplicate reimbursement claim** (Redeem-Safety residual — §4.3.1/§5): an operator appropriates vault value without a valid redeem, or reimburses twice; vault balance falls while circulating does not — closed by the §4.3.2 fraud-statement rule **plus** at least one honest challenger/watchtower. Under those assumptions, any observer can sum the public vault UTXOs on Bitcoin and treat that sum as a ceiling on circulating zkBTC (a mint requires a matching vault-output amount under clause (e)/(h); minting without *some* vault backing is in-circuit impossible under the TS3 rules — but Attack A/B **or** an unchallenged fraudulent reimbursement drain or void the *backing* after or instead of a real canonical mint).

**Exact circulating figure is not protocol-enforced from chain data alone.** Parent nullifiers reveal no amount or asset, and proof validity remains off-chain (specification.md §3.1 / §3.2). An observer **cannot** distinguish vaulted-but-never-minted deposits or slot-burned mints from successfully minted ones without off-chain proofs. Public deposits and later payouts permit **correlation**, not protocol-level equality of

```
circulating  ==  Σ vaulted  −  Σ redeemed
```

Aggregate circulating supply therefore remains a **conditional upper bound** (`circulating ≤ current backing vault balance` under the reserve-safety assumptions of §5: **1-of-N + R-09 + no successful Attack A + ≥1 honest challenger**). R-04 closes Attack A **only when gated**; Corner D leaves Attack A as a bound-breaker (Bitcoin-class / `D_mint`). A successful Attack A, Attack B, **or** unchallenged fraudulent reimbursement breaks the bound. It is **not** exactly computable from chain data alone.

**Published attestation ledger (for exact audit — optional).** Exact circulating supply requires a **published aggregate mint-minus-redeem attestation** (or equivalent proof/opening ledger). Note carefully:

- A specification.md **§5.7-style balance attestation proves one account**, not aggregate supply. It **MUST NOT** be implied that §5.7 alone yields the circulating total.
- If an **aggregate** mint-minus-redeem attestation is offered, it **MUST** be defined as such (a separate attestation form), not smuggled in under §5.7.
- **Without** such a ledger, only the upper bound plus public deposit/payout correlation exists — **not** protocol-enforced equality.

**Default published form (SHOULD).** Because publishing raw redeem openings would deanonymize `btc_recipient`, the default published form for holder-facing audit **SHOULD** be a **specification.md §5.7-style balance attestation** (per account), not raw openings. Raw openings **MAY** be disclosed under holder consent or legal process; they are not the default public audit surface. Aggregate exact supply, if published, uses the separate aggregate attestation form above.

**Contrast token standard 1:** mint amounts are not publicly summable at all (risks.md D-13). TS3 improves on TS1 by binding every mint to a public vault UTXO (upper-bound audit) and by enabling optional published attestations for exact figures.

**Honest trade-off:** vault deposit amounts and L1 payout amounts remain public by L1 visibility; internal transfers stay fully shielded (REQ-2 intact). Exact supply equality is an attestation/ledger property, not a pure chain-scan invariant. The default remains the **conditional** upper bound (under the reserve-safety assumptions of §5: **1-of-N + R-09 + no successful Attack A (R-04 only when gated) + ≥1 honest challenger**; broken by Attack A, Attack B, **or** unchallenged fraudulent reimbursement) + optional attestation, not raw openings.

### 3.7 Protocol-version consequence (v1 freeze) and migration

TS3 requires new circuit digests. Per specification.md §1.7.8 (v1 freeze): any change to the frozen circuit surface defines a **new protocol version** with **new digests and new lineages**; v1 artefacts are never edited in place.

**Normative migration / coexistence rules:**

1. zkBTC exists **only** in the v2-circuit universe. There is **no** cross-version receive between v1 and v2 lineages (cyclic recursion requires fixed verifier data within a lineage).
2. Existing v1 assets are unaffected and **MUST NOT** migrate implicitly into v2.
3. The v2 circuit **MUST** ship **all** standards (1, 2, and 3) as branches so the new universe is complete from genesis — creators of non-zkBTC assets can still issue under TS1/TS2 on v2.
4. ProofData layout v2 = six v1 fields + `redeem_commitment` (§3.7.2), with a new `circuit_digest(C)` pin for the v2 circuit. **`C_balance` is re-pinned for v2** (§3.7.2 — M-02): both digests change.
5. From the v2 release onward, specification.md §1.7.8-style freeze discipline applies to the **v2** surface: further changes are further version bumps, not in-place edits.

#### 3.7.1 Coexistence table

| Asset class | Circuit universe | Can receive from v1 lineage? | Notes |
|-------------|------------------|------------------------------|-------|
| Pre-existing v1 TS1/TS2 assets | v1 | Yes (within v1) | Frozen; unchanged |
| New TS1/TS2 assets issued on v2 | v2 | No | Same standard rules, new digests |
| zkBTC (TS3) | v2 only | No | Requires LCP + redeem field |
| Transitional bridged asset (§9) | v1 (TS1) | Yes (within v1) | Not named zkBTC |

Wallets **MUST** key assets by `asset_id` and circuit lineage, never by display name alone. A UI **MUST NOT** present a transitional asset under the zkBTC product name (§9).

#### 3.7.2 v2 circuit surface (pinned)

This subsection pins the consensus-relevant cryptographic surface for the v2 release. All values below are protocol constants of that release; changing any of them is a version bump.

**ProofData order and serialization (MUST — M-02).**

v1 `ProofData` (specification.md §1.4) is the six 32-byte digests in this order — **192 bytes**:

```
serialize(ProofData_v1) :=
    new_account_state_hash ‖ output_coins_root ‖ input_nullifiers_root
  ‖ coin_history_root ‖ nav_commitment ‖ npk_commit
```

v2 appends one field after the six v1 fields:

- **field 7** `redeem_commitment` — 32-byte Poseidon digest.

A **TS3 mint** therefore exposes:

```
{ six v1 fields, redeem_commitment (= zero-sentinel for a mint) }
```

A non-mint transition (including redeem) exposes:

```
{ six v1 fields, redeem_commitment (non-zero iff redeem) }
```

```
serialize(ProofData_v2) :=
    serialize(ProofData_v1) ‖ redeem_commitment
```

Total length: **224 bytes** (192 + 32). This is the pin **before** the short-lived `tip_height` extension was added and then removed (NEW-HOLE-01 / R-04 invert): host-side freshness and the 8-byte `tip_height` field are **gone**. `H(ProofData) := SHA-256(serialize(ProofData_v2))` for all v2 transitions (S2C binding unchanged in structure; preimage length grows from 192 → 224).

**Zero sentinels (MUST).**

| Field | Non-applicable path | Sentinel |
|-------|---------------------|----------|
| `redeem_commitment` | non-redeem (incl. mint) | 32 zero bytes |

There is **no** `tip_height` field and **no** tip/freshness per-branch sentinel.

**Public-input limb positions for the new field.**

Parent v1 layout for `C` (specification.md §2.5): six ProofData fields = five Poseidon digests (**20** field elements) + `npk_commit` (**8 × u32 limbs**) = **28** elements from `ProofData`, then `consumed_pubkey` (**8**), then `network_id` (**4**) — **40** application public-input elements.

v2 inserts `redeem_commitment` (Poseidon digest, **4** Goldilocks field elements) as field 7 **immediately after** `npk_commit` and **before** `consumed_pubkey`:

| Region | Elements | Notes |
|--------|----------|-------|
| ProofData fields 1–5 (Poseidon) | 20 | unchanged |
| `npk_commit` (SHA-256, 8 × u32 LE limbs) | 8 | unchanged |
| **`redeem_commitment` (Poseidon, 4 elements)** | **4** | **new — field 7** |
| `consumed_pubkey` | 8 | unchanged position after ProofData |
| `network_id` | 4 | unchanged last application PI |
| **Total application PI** | **44** | was 40 on v1 |

A conforming verifier reads `serialize(ProofData_v2)` from the first **32** public-input elements' encodings (20 + 8 + 4), `consumed_pubkey` from the next **8**, and `network_id` from the final **4**.

**`C_balance` re-pin (MUST — M-02).** `C_balance` **cannot** remain byte-identical under a v2 `C`. It recursively verifies a `C` proof under pinned `C` verifier data (parent specification.md §783 / §1092), so a new v2 `C` changes `C_balance`'s embedded verifier data and digest. **Both** `C` and `C_balance` receive new v2 digests: `circuit_digest(C)` **and** `circuit_digest(C_balance)` **MUST** be re-pinned for the v2 release (one pair per network tag). There is **no** "C_balance unchanged by TS3" claim.

**`genesis_tag`.** `AssetIdV3` reuses the v1 `genesis_tag` value: the fixed constant ASCII string **`zkCoins/v1/genesis`** (specification.md §1.4). Do **not** invent a new genesis tag for TS3.

**Reused v1 surface (MUST NOT change).** v2 reuses v1's `m_state` strings, network tags (`zkCoins/v1/mainnet` \| `testnet` \| `regtest`), activation parameters, and accumulator namespace **unchanged**. The **only** circuit-surface additions for TS3 are: the `redeem_commitment` field, the TS3 mint/redeem branches of `C`, the recursive LCP interface consumed by clause (e) (`MoveToBacked` confirmation), and the re-pinned `C_balance` verifier data. A new `circuit_digest(C)` **and** a new `circuit_digest(C_balance)` **MUST** be pinned for the v2 circuit (one pair per network tag).

**LCP consensus / S2C inputs (MUST pin).** The following are consensus parameters of the v2 release (circuit constants and/or S2C-relevant public inputs of `C_lcp` / the mint branch):

- LCP **checkpoint header** hash (and its height);
- **`D_mint`** and optional upper slack **`S`** (§3.3(e), §4.4). There is **no** freshness window `W`.

**Recursion-only values (MUST NOT enter on-chain public inputs).** The redeem-branch values required by the reimbursement statement (In/Out/redeem_amount openings, recursive proof of the TS3 redeem branch — §4.3.2) are exposed **only** to the reimbursement / fraud circuit via recursive verification. They **MUST NOT** enter the on-chain public-input surface of `C` or of any Bitcoin-published object. A redeem transition therefore remains on-chain indistinguishable from any other transition **until** an operator's reimbursement claim marker appears (§8.2).

---

## 4. Bridge profile — BitVM2-based reserve (the off-circuit half)

### 4.0 Construction decision and maturity gate

**Decision (works-today):** the zkBTC bridge is built on **BitVM2** — the mainnet-proven BitVM-family verifier — with **open permissionless operator registration** (§4.1.1). No federation-multisig V0. No dependency on any not-yet-mainnet construction.

**Rationale (facts + design choice):**

| Claim | Status | Source |
|-------|--------|--------|
| BitVM2 bridge live on Bitcoin mainnet (Bitlayer Jul 2025; Citrea Clementine live Jan 2026) | Fact | `bitvm.org/bitvm_bridge.pdf`; `docs.citrea.xyz`; blockworks BitVM implementation-stage |
| BitVM2: permissionless CHALLENGE (anyone with a full node) | Proven core property | `bitvm.org/bitvm2`; `bitvm_bridge.pdf` |
| BitVM2: operators pre-defined **per instance/epoch**; open **registration** is a product/ops layer (GOAT `registerPubkey`+stake; Fiamma open co-signers) | Fact + our design | GOAT bitvm2-node; Fiamma operators docs |
| Worst-case on-chain dispute cost under BitVM2 is high (~$16k class); BitVM3/Glock/Mosaic reduce it ~1000× (→ lower minima) as a **future upgrade** | Research | `bitvm.org/bitvm3.pdf`; eprint 2026/933; 2025/1485; 2026/812 |
| Plonky2 → BitVM2 (SNARK/Groth16) predicate conversion of the zkCoins compliance predicate — integration track (a) | Open engineering | — |
| Open operator-registration market (policy encoding, bond / anti-domination calibration, `reg_root_E`, ceremony) — track (b); semantics §4.1.2 | Open engineering / calibration | — |

**Historical note (superseded):** the June-2026 decision recorded a Glock-only path with no BitVM2 intermediate (`bitvm-bridge-research.md`). That framing is **historical**. This document re-bases on mainnet-proven BitVM2; Glock/BitVM3/Mosaic remain §10.1 efficiency upgrades only.

**Verifier abstraction.** The verifier is behind a trait. **BitVM2 is normative.** Glock / BitVM3 / Mosaic values are **future efficiency reference baselines** (§10), not inherited protocol properties. Clementine / Bitlayer are the **today** reference deployments.

#### Maturity gate (blocking — design document; ready-to-implement on proven components)

BitVM2-mainnet is **CLEARED** (proven). Remaining work is **three gates** on proven components: (a) the Plonky2→BitVM2 predicate-conversion integration gate (§4.6B / G3), (b) instantiating and hardening the open operator-registration market (semantics now in §4.1.2; calibration still open per §11 / §4.6A / G2), and (c) an external audit of the v2 circuit, BitVM2 graph, and pre-signed graphs (§4.6B). All three gates, plus §4.6A REQ-4 gates, **MUST** clear. This reframes the document from "future design gated on a not-yet-mainnet verifier" to "**ready-to-implement on proven components once the three remaining gates clear — not a build order until they do**."

| # | Gate | Notes |
|---|------|-------|
| G1 | BitVM2 verifier mainnet-proven | **CLEARED** — Bitlayer 2025-07; Citrea Clementine live 2026-01 |
| G2 | Reference open-registration operator market operational | GOAT/Fiamma ship open registration; our per-epoch registration market (§4.1.1 / §4.1.2) must be instantiated and calibrated |
| G3 | **Plonky2 → BitVM2 (Groth16/SNARK) conversion of the zkCoins compliance predicate demonstrated** | Integration track (a) — blocking engineering gate |
| G4 | External audit of the v2 circuit, BitVM2 graph, and pre-signed graphs published | Open — addresses the circuit/graph-soundness class that could otherwise enable theft; sound circuit/graph crypto remains a standing assumption even after audit (§4.5 / §5 / §4.6B) |

### 4.1 Roles

| Role | Function |
|------|----------|
| **User / Minter** | Requests peg-in by depositing; holds and transfers zkBTC; initiates redeem and submits opening + payout template. Any depositor **MAY** mint under the asset's mode (§3.2) |
| **Gatekeeper** (optional) | Per-mint quality authority and **canonical-chain anchor** (R-04: covers **`MoveToBacked` and `reg_root_E`**) when `gatekeeper ≠ 0³²`: source-of-funds screening + **withholds `Pk_mint` signature until both `MoveToBacked` and `reg_root_E` are confirmed on its own canonical Bitcoin view** (R-04 / Attack A). Optional R-08 is belt-and-suspenders. **Attack B is closed by R-09**, not by this role. Produces `Pk_mint` nullifier (approval = admission). **No** peg-out role |
| **Operators** | **N-of-N** co-sign the **pre-signed BitVM2 graph** at setup (`MoveToBacked`, assert/challenge/disprove/payout connectors — **no** cooperative-refund leaf on the backing-only vault), then **delete epoch signing secrets** (MUST — NEW-01: presigning set is N-of-N, not t-of-n; **identity keys are not deleted**); front peg-out BTC from own funds; claim vault reimbursement along the pre-signed graph only (**no live vault CHECKSIG** — NEW-01). Aggregate keys **MUST** be admitted by this asset's `operator_set_root` **policy** via the epoch registration commitment (§3.1.2). **Operator registration is open/permissionless (§4.1.1).** |
| **Watchtowers / challengers** | **Permissionless challenging is a delivered BitVM2 property** — anyone running a Bitcoin full node **MAY** challenge a fraudulent reimbursement claim; not restricted to a designated verifier |
| **Security council / admin keys** | **None.** Deliberate divergence from Citrea and Strata reference deployments |

Holders **MAY register** as operators (open/permissionless — §4.1.1) and self-front, subject to the bonded-onboarding cost note in (b).

#### BitVM2-specific role notes

**(a) Permissionless challenging — DELIVERED (BitVM2).** Unlike a designated-verifier construction (Glock), BitVM2's challenge is open: any full-node observer can disprove a fraudulent assert. This is the core reason BitVM2 is the works-today normative verifier. (Glock would *reduce dispute cost* but *reintroduces* designated-verifier challenge — hence §10-only.) **Permissionless challenge** (anyone **MAY** challenge) is a *mechanism-availability* property, delivered by BitVM2; **safety additionally requires that at least one honest challenger actually ACTS** within the relevant window. Availability ≠ guaranteed action. (Residual: §5 residual 3 / residual 6.)

**(b) Operator onboarding cost (BitVM2).** Joining as an operator for an epoch requires participating in that epoch's N-of-N presigning ceremony and posting a bond; per-instance setup cost is real (BitVM2 presign graph). Open registration (§4.1.1) makes join permissionless, but it is a bonded commitment, not a free click — do not assume every retail holder self-registers. BitVM3/Glock (§10) lower this cost later.

**(c) No-council / one-shot watchtower + sequencing-connector close.** Citrea Clementine (BitVM2 reference deployment) and historical Strata carry a **Payout Administrator** specifically against the documented **watchtower one-shot** weakness: a single successful counterproof may permanently weaken a watchtower versus that operator; the PA can burn a connector to block payout. Without a PA, "claims become void" and "claim-gating below capacity" are **not** enforceable in a councilless presigned-graph system (nobody can halt others' presigned claims; K parallel claims would consume K one-shots before slash #1).

**Normative BitVM2-graph construction requirement (replaces the Payout-Administrator function with graph structure):**

- **Per-operator claim serialization:** each operator's claims are chained through a **sequencing connector** so claim `N+1` is spendable only after claim `N` is resolved (reimbursed or slashed).
- A successful counterproof **slashes the operator's bond and burns the sequencing connector**, which really ejects the operator (no further claims possible).
- Consequence: one operator consumes **at most one** watchtower one-shot before removal. The independent-watchtower floor (§4.4) therefore bounds **independent operators**, not sequential claims of one operator.

This is a technical hole closed by graph structure, not a style point.

### 4.1.1 Open permissionless operator registration market

This section specifies the flagship open-operator property of REQ-4 **and** the R-09 Attack-B close: **anyone can be the exit agent, including a holder acting as their own, and a new vault cannot omit already-admitted operators.**

1. **Open join into cumulative S (permissionless, MUST — R-09).** There is one operator set S per asset. For each deposit epoch E there is a **registration window** before that epoch's vault graphs are set up. **Anyone** **MAY** join S by (i) posting the policy-P bond to a bonded/slashable output and adding their **identity** pubkey to S, and (ii) contributing a **fresh epoch signing pubkey** `pk_{E,i}` (identity-bound PoP — §4.1.2) to the epoch's N-of-N presigning ceremony over **current S ∪ {joiners}**. The identity key is **not** the ceremony/KeyAgg key. No allowlist, no admin approval, no gatekeeper approval (the gatekeeper has **NO** role here — that is mint-only). A holder **MAY** register to be their **own** exit agent and, if they join **before the first mint**, their own Attack-B honest signer (§1.1.1). **S never shrinks.** A new epoch that omitted any already-admitted operator is **invalid**.

2. **Epoch setup ceremony (Level 1 — §4.1.2).** S_E = rotate(S_{E-1}) ∪ J_E runs the BitVM2 N-of-N formation ceremony (bond/PoP/`reg_root_E`/KeyAgg; bounded restart rounds on **not-yet-admitted** joiners only), then Level-2 per-deposit graph presign for each deposit, then all delete **epoch signing secrets** (NEW-01; identity keys stay). `agg_key_E` and `reg_root_E` are formed per **§4.1.2** (MuSig2 KeyAgg over the **epoch signing keys** `{pk_{E,i}}` of S_E, not over identity keys; Merkle commitment of valid bonded registrations with identity-bound PoP **and** the identity-party superset proof against `reg_root_{E-1}`).

3. **Freeze semantics (MUST state honestly).** After the epoch freeze, S_E is fixed **for reclaim from E's vault** (the pre-signed graph binds those keys — this is the covenant-emulation reality; registration-free reclaim needs §10.2 covenants). Registration for **future** epochs stays permanently open as **join-only**: new operators add to S, old ones stay. Any given epoch's vault is reclaimable by that epoch's S_E (a prefix of later S). A late joiner **cannot** self-reclaim from vaults whose S_E does not include them. Fungibility of the **claim** (`asset_id`) is unaffected: the token is one fungible asset; redeem is cross-graph across all in-set epoch vaults (§4.3) — which is why the first-mint rule of R-09 item 6 is load-bearing. Full self-exit of the whole asset is guaranteed only if the holder joined **before the first mint**.

4. **"Be your own exit agent" — EXIT and Attack B (MUST state).** Because registration is open, a holder who wants a guaranteed self-serviced **exit** **MAY** register (once, into S) and thereafter front + reclaim their own redemptions **from vaults of epochs whose S_E includes them**. Because S is growth-only, that same registration is the Attack-B close for **later** vaults: every later vault includes them. **Scope (MUST):** "no party can prevent this" refers to a **registered holder serving their own EXIT** along a graph **already presigned at that deposit's setup**, **and** to that holder refusing a malicious graph at setup of any later vault. It does **not** mean a late joiner can reimburse themselves from older vaults they were never in. A wallet **MUST** check that compatible in-set vault capacity exists before burning a redeem. Exit reclaim does not run a live ceremony at exit time, so exit cannot be griefed once the graph exists. Setup-time (peg-in / registration) griefing is handled by §4.1.2 item 5 (Level-1 restart rounds **for not-yet-admitted joiners only**) and the deposit-taproot refund leaf (Level-2) — **not** by this exit claim. This is the concrete meaning of REQ-4's open-operator property **and** of §1.1.1's effectively-trustless claim.

5. **Irreducible residual (MUST state plainly).** A holder who **never** registers relies on ≥1 registered operator of some in-set epoch being online to front + reclaim. That is a **liveness** dependency, not custody — the operator cannot steal (1-of-N + ≥1 honest live challenger acting in-window; worst case freeze/burn (under sound circuit/BitVM2-graph crypto — a critical soundness bug can instead enable theft, §4.5); §5 residual 3). That holder also has **no Attack-B guarantee of their own**; they inherit whatever honesty S already had. Registration-free unilateral self-reclaim from a pooled vault is **covenant-class** and not available on today's Bitcoin (§10.2).

6. **Anti-domination / anti-Sybil (MUST — R-09 is the Attack-B close; gate A(1) is weaker).** Policy P's bond + admissibility predicate **MUST** make single-party domination of S economically irrational (no single party ≥ half) **and MUST** encode R-09 (growth-only, no kick after admission, every new vault N-of-N over current S). Otherwise a self-controlled **new** vault re-opens **Attack B**. The economic bond alone is **insufficient**. **R-09** is the close. In **gatekeeper mode**, Attack A (private-fork amortization) is blocked by **R-04**; optional R-08 is belt-and-suspenders, not the Attack-B close. **Corner C** (open registration + pooled **without** R-09) is **UNSOUND** (§3.2.1.2 / §5 residual 9 / §6.4).

7. **Liquidity / competition.** Multiple registered operators compete to front (fee ≤ `max_fee`); the redeeming holder submits the payout template to **any** operator (§4.3). No operator has a privileged claim.

8. **Dead / grieving admitted operators (MUST state).** An admitted operator who loses their key or refuses later presigns **cannot be dropped**. New vaults freeze until they rotate in place (old key signs the new key) or mint liveness stays halted. Existing coins of already-presigned vaults remain exit-able via 1-of-N of that vault's S_E. Safety over mint liveness.

### 4.1.2 Registration commitment, key aggregation, and ceremony robustness

This section specifies the open-registration mechanism that makes the two-level admission of §3.1.2 / §3.3.1 executable. **Semantic requirements are normative now**; concrete registration-output script bytes and `reg_root_E` commitment encoding are **launch parameters** (frozen with the v2 circuit digests, same honesty discipline as §3.1.1 point 4 / NEW-03 connector-byte launch-pin and §4.2.1).

1. **Registration output (bond) format.** Each registrant for epoch E posts a bond of at least the policy-P bond amount to a **slashable registration output** on Bitcoin that commits, in a canonical encoding: `(identity_pubkey, epoch_signing_pubkey pk_{E,i}, epoch_id E, policy_tag = operator_set_root, proof_of_possession)`. The PoP is a signature by `identity_pubkey` over a domain-tagged message binding `(identity_pubkey, E, pk_{E,i})` (NEW-01). Already-admitted identities re-register each epoch only to contribute a **fresh** `pk_{E,i}`; they do not re-join S. The bond output **MUST** be spendable by the epoch's slash/settlement path (so a proven-fraudulent or grief-defaulting operator forfeits it) and returnable to the registrant after the epoch's claim/challenge horizon if unslashed. **MUST** — no epoch signing key without a live bond output.

2. **Proof-of-possession (rogue-key defense).** Registration **MUST** include a BIP-327-style proof-of-possession so a registrant cannot register a rogue aggregate-cancelling epoch key it does not control, **and** the identity-bound PoP of item 1. Duplicate `identity_pubkey` registrations in the same epoch **MUST** be rejected. Duplicate `pk_{E,i}` **MUST** be rejected.

3. **`reg_root_E` (epoch registration commitment).** `reg_root_E` = a Merkle commitment over S_E, the set of valid registration outputs admitted for epoch E under R-09 (each satisfying items 1–2 within E's registration window, **and** every **identity-party** from `reg_root_{E-1}` — same pubkey, or `pk_new` under a rotation signed by `pk_old`). Epoch signing keys of E−1 are **not** a superset obligation. It **MUST** be published on-chain as part of the epoch anchor (either committed in the epoch's `MoveToBacked` graph anchor leaf or a dedicated epoch-anchor transaction — launch-pinned form) by the epoch's registering operators / coordinator. The in-circuit statement (via `C_lcp`) **MUST** establish: (i) `reg_root_E` is committed on a **PoW-valid header chain at adequate depth** (same LCP power as `MoveToBacked` — **canonicity is NOT established in-circuit**, exactly as §3.4); (ii) every included registrant satisfies items 1–2 (bond ≥ B, valid PoP, no duplicates); (iii) `agg_key_E` is the key-aggregation of exactly the **epoch signing keys** `{pk_{E,i}}` committed in `reg_root_E`; (iv) **R-09 superset:** every **identity-party** in `reg_root_{E-1}` is represented in `reg_root_E` (same pubkey or signed rotation; genesis epoch E=0 has no predecessor).

   **Canonicity anchor (MUST — R-04 extended; gatekeeper mode).** In gatekeeper mode, the gatekeeper — as part of its **R-04** canonical-view duty — **MUST** confirm on its **own canonical Bitcoin view** that the `reg_root_E` backing this mint's epoch is the **canonical** registration commitment (not a private-fork / substituted root) and that it satisfies the R-09 superset rule. R-04's canonical anchor therefore covers **both** `MoveToBacked` **and** `reg_root_E`. In no-gatekeeper mode there is no such Attack-A anchor; Attack B remains closed by R-09.

   **Completeness of *new* joiners = liveness residual; completeness of *already-admitted* keys = safety (MUST state).** Completeness of J_E (that every valid new bonded joiner is included) is a **liveness/fairness** property: a censored new joiner keeps its bond and retries next epoch. Completeness of S_{E-1} inside S_E is a **safety** property: omitting an already-admitted honest key re-opens Attack B and **MUST** fail R-09. **Accepted liveness residual:** a censored *new* registrant may be excluded from serving that epoch (re-registers next epoch); no funds are lost. **Forbidden:** dropping an already-admitted key.

4. **Key aggregation.** `agg_key_E := MuSig2 KeyAgg (BIP-327)` over the **epoch signing keys** `{pk_{E,i}}` in `reg_root_E`, with keys in **lexicographic (sorted) order** (deterministic, order-independent), duplicates rejected, identity-bound PoP required per items 1–2. This is **not** KeyAgg over identity keys (NEW-01). A bare "aggregate of the set" is insufficient.

5. **Ceremony robustness / anti-grief — bounded restart rounds (MUST — exclusion only of not-yet-admitted joiners).** After the registration window closes, S_E runs the N-of-N BitVM2 presign within a bounded **overall setup window**. **Per-round presign deadline ≠ setup window (MUST distinguish):** each presign **round** has its **own** deadline. A **not-yet-admitted joiner** in J_E that fails to complete its presigning share by that **round** deadline is **excluded from this join attempt** and its registration bond is **forfeited/slashed**; it was never in S. **An already-admitted operator in S_{E-1} MUST NOT be excluded** (R-09). If an admitted operator fails to presign, the round **fails** and may retry within the setup window; it does **not** drop the key. If they never complete, **new vaults of this epoch do not form** (mint liveness freeze — §4.1.1 item 8). Excluding a grief-defaulting *joiner* **changes** J_E, hence `agg_key_E`, which **invalidates already-collected MuSig2 nonces / partial signatures / graph artifacts** bound to the old aggregate key. A **new round** then begins over S_{E-1} ∪ (J_E minus the excluded joiner), with its **own** per-round deadline. The **setup window** bounds the **total** number of rounds. On each joiner-exclusion, prior partial artifacts for the affected graph are **discarded**. **Re-presign cost (honest):** a grieving *joiner* imposes a re-run cost, capped by the window and by the bond forfeited per exclusion. A grieving *admitted* operator cannot be removed to make progress — that would re-open Attack B.

6. **Two-level ceremony architecture (MUST).** Resolve the epoch-ceremony vs per-deposit-ceremony split explicitly:

   - **Level 1 — epoch operator-set formation (once per epoch):** the registration + anti-grief ceremony of item 5. **J_E is provisional until the setup window completes.** `reg_root_E` / `agg_key_E` are **published at the end of the setup window**, not at its start. A Level-1 griefer who is a **not-yet-admitted joiner** is excluded from J_E + slashed + restart (item 5) **before** that publication. A Level-1 griefer who is **already in S** is slashed if the policy so provides, **not** dropped; the epoch does not form without them.
   - **Level 2 — per-deposit graph presign (once per deposit, by the intended S_E):** each deposit's BitVM2 transaction graph (§4.2 step 3) is presigned by the epoch's N-of-N set.
     - **One-off Level-2 refusal (single deposit):** a Level-2 griefer that refuses to presign a **specific** deposit's graph does **NOT** strand that depositor: `MoveToBacked` simply never fires for that deposit, so the depositor reclaims via the **deposit-taproot refund leaf** after `refund_timelock` (existing R-01 / INV-01 escape); the Level-2 griefer is slashable for that default. No deposit funds are stuck.
     - **Systematic Level-2 griefing by a not-yet-admitted joiner → exclusion from J_E before `reg_root_E` is published (MUST).** After `reg_root_E` is published, that joiner is admitted and **MUST NOT** be dropped (R-09). Systematic Level-2 griefing by an **already-admitted** operator **MUST NOT** drop them from S. Their bond **MAY** be slashed; new vaults stall until they presign or rotate. Dropping them would re-open Attack B.

   Setup-time griefing is handled by Level-1 restart / one-off Level-2 deposit refund / systematic Level-2 → Level-1 exclusion **of not-yet-admitted joiners only**. An already-admitted operator **MUST NOT** be dropped (R-09); systematic Level-2 griefing by one freezes new vaults, it is not leave. **Exit** reclaim runs along a graph already presigned at that deposit's setup. §4.1.1 point 4 scopes "no party can prevent this" to that **exit** path **and** to the holder's refusal of a malicious graph at later-vault setup.

7. **Honest launch-pin.** The concrete registration-output script bytes and `reg_root_E` commitment encoding are **launch parameters** (frozen with the v2 circuit digests, NEW-03 style). The **semantic** requirements (items 1–6) are normative now. Implementations **MUST NOT** claim present-day absolute byte-determinism for the registration-output / `reg_root_E` encoding beyond the semantic pins above (same honesty as §3.1.1 point 4 / §4.2.1 connector-byte launch-pinning).

### 4.2 Peg-in (permissionless mint; optional gatekeeper)

Numbered happy path (**deposit taproot** → co-signed **`MoveToBacked`** → **backing-only vault output** → deep mint). These are two distinct UTXOs with cleanly separated rights (R-01 inverted binding; analogous to Clementine's MoveToVault-before-refund, but named `MoveToBacked` here because the output is permanently backing-only):

1. **Deposit preparation (deposit taproot).** The minter constructs a **deposit taproot** address (what the user pays to; pre-`MoveToBacked`). Its script tree includes:
   - vault / bridge leaf consistent with spending into the pre-signed `MoveToBacked` for an `agg_key` admitted by this asset's `operator_set_root` policy via the epoch registration commitment (N-of-N MuSig2 / graph deposit path as required by the graph);
   - **co-sign gate** for firing `MoveToBacked` (MUST — INV-01 consent + anti-griefing): the **depositor's co-signature is required in both modes**; in **gatekeeper mode** the **gatekeeper's co-signature is additionally required** (anti-griefing after refusal). Implementation: a co-sign tapleaf or additional required signature(s) on the pre-signed `MoveToBacked` path;
   - `recipient_commitment` leaf (§3.3(g));
   - in **no-gatekeeper** mode: `depositor_base_commitment` leaf (§3.2.1.2) — **MANDATORY**;
   - **depositor refund leaf** with `OP_CSV` of `refund_timelock` blocks paying the minter (`refund_timelock` is a bridge-epoch parameter — §4.4 — not part of `asset_id`). This leaf is the depositor's **only** unilateral reclaim path and is used **only if `MoveToBacked` never happens**.
2. **User deposit.** Minter broadcasts a Bitcoin transaction paying exactly one allowed denomination amount to that deposit taproot.
3. **Presign (MUST — NEW-01).** The epoch's **openly-registered operators** (§4.1.1) generate and **N-of-N** **pre-sign the entire per-deposit BitVM2 transaction graph** (`MoveToBacked`, assert/challenge/disprove/reimbursement/payout connectors — **no** cooperative-refund transaction on the backing-only vault). Content is fixed at setup → txids fixed → the downstream reimbursement graph stays pre-signable. After the **epoch's** presigning is complete (all admitted deposits — §2.1), each signer **MUST** delete its **epoch** signing secret under `agg_key_E` (NEW-01); identity keys are **not** deleted. The presigning set is **N-of-N**, not a `t < N` threshold (NEW-01 — §2.1).
4. **`MoveToBacked` (MUST — R-01 / R-04 inverted binding + INV-01 consent).** Operators (with the **co-sign gate** of step 1: **depositor always**; **gatekeeper also** in gated mode) execute **`MoveToBacked`**: an **ordinary pre-signed, nullifier-free graph transaction** that spends the user's deposit output **through the vault leaf under the N-of-N (BitVM2 aggregate) signature produced at setup** into a **backing-only** vault UTXO whose scriptPubKey is **byte-equal** to `instantiate(vault_template, asset_id, agg_key, epoch)`. `MoveToBacked` **consumes** the deposit output and thereby **extinguishes** the deposit-taproot refund leaf. Bitcoin UTXO exclusivity is the arbiter between `MoveToBacked` and the deposit refund leaf: `MoveToBacked` **MUST** fire before `refund_timelock`, exactly like Clementine's MoveToVault-before-refund.
5. **Backing-only vault output (MUST — R-01 / NEW-01 / B-01).** The resulting **vault output** (the mint anchor, post-`MoveToBacked`) carries **NO depositor refund leaf and NO cooperative refund leaf**. Its tapleaves are only: the operator/reimbursement leaves + assert/challenge/disprove/sequencing connectors (NEW-01 form: pre-signed graph commitments, **no live `agg_key` CHECKSIG**, CSV = BitVM2 assert/challenge/disprove windows — B-06 / §4.4) and the `asset_id ‖ epoch` commitment leaf (§3.1.1). There is **no** mint-window CSV formula and **no** refund-vs-mint-window race (there is no refund path on this output).
6. **Deep finality window.** `MoveToBacked` becomes mint-eligible only when confirmed at depth **≥ `D_mint`** (optionally ≤ `D_mint + S`) on the chain used for the LCP (§3.3(e), §4.4). Long finality is acceptable per REQ-4. **In gatekeeper mode**, mint settlement further requires the gatekeeper's **own canonical Bitcoin view** to show the same confirmation for `MoveToBacked` **and** for `reg_root_E` (step 7 / R-04).
7. **TS3 mint.**
   - **Gatekeeper-gated (MUST — R-04 canonical anchor; R-09 already in-circuit):** the gatekeeper verifies the mint's witness/inputs (source-of-funds, LCP-proven `MoveToBacked` to the asset's instantiated backing-only vault, committed recipient, `operator_set_root` membership and **R-09 superset** against the asset-bound policy root — §3.2.1.1) **and**, on its **own canonical Bitcoin view**, that (i) `MoveToBacked` is confirmed to depth ≥ `D_mint` on the **canonical** chain, (ii) the deposit output was **not** refunded on the canonical chain, and (iii) `reg_root_E` is the canonical registration commitment for the epoch (R-04 covers both anchors — §4.1.2); **only then** does it sign `m_state` under `Pk_mint` (approval = nullifier admission; **withhold until canonical**). The final proof `C` is constructed afterward embedding that signature. Clauses (a)–(h) are proven against the **vault outpoint** (N-of-N witness + instance byte-equality + recursive `operator_set_root` equality + R-09 + `MoveToBacked` depth ≥ `D_mint`). The one-shot mint nullifier `(Pk_mint, R)` is published. Co-signed `MoveToBacked` alone does **not** settle a mint — the gate is the withheld final mint signature (R-04 closes Attack A; R-09 closes Attack B — §3.1.2).
   - **No-gatekeeper:** the depositor signs under depositor-anchored `Pk_mint` (§3.2.1.2); same clauses (a)–(h) with `depositor_base` opening. **Honest limitation:** no external canonical observer (Attack A not cleanly closed; no anchor for `MoveToBacked` or `reg_root_E` — Bitcoin-class / `D_mint`). **Attack B closed by R-09.** Open registration + pooled **without** R-09 is **Corner C / UNSOUND** (§3.2.1.2, §5 residual 9, §6.4) and **MUST NOT** be marketed as trust-minimized or as effectively trustless. With R-09 this **is** the product default (§1.1.1).
   - Coin delivery uses ordinary zkCoins delivery to `recipient`. Receivers/bridge **MUST NOT** re-check host-side freshness or vault unspentness: the mint LCP already proves `MoveToBacked` confirmation in-circuit (§3.3.2); canonicity binding of `MoveToBacked` **and** `reg_root_E` to the Bitcoin tip is the gatekeeper's mint-time duty when designated.

**Ordering rule and consented irrevocable contribution residual (R-01 / INV-01).** After `MoveToBacked` there is **no unilateral depositor reclaim** and **no cooperative refund** of the vault-backed BTC. The depositor's unilateral protection is the **pre-`MoveToBacked` deposit-taproot refund** only. If `MoveToBacked` fires but the mint never settles (e.g. gatekeeper/operator fails after `MoveToBacked`), the vaulted BTC is **not** merely frozen recoverable BTC: because reimbursement is cross-graph (any same-asset in-set vault can back a redeem), it becomes an **irrevocable, consented contribution to the shared reserve** and **MAY** be redeemed by another holder — deliberately, so R-01 cannot re-open one level deeper with a refund race. Because `MoveToBacked` fires only with the **depositor's co-signature in both modes** (and the gatekeeper's co-signature additionally in gated mode — step 1 / 4), this contribution is **consented**, not imposed (cross-ref §4.5 no-council / operator-liveness class; §5 residual list). In gatekeeper-gated mode this is an accepted **gatekeeper-liveness residual at entry** (the quality gate and canonical-chain anchor (R-04) *are* mint-time liveness dependencies when a gatekeeper is designated — §6; optional R-08 is not). In no-gatekeeper mode the residual is depositor operational (co-sign `MoveToBacked` only when accepting the contribution risk / ready to mint). **Attack closed by R-01:** a raw vault refund leaf at `refund_timelock` (~200 blocks) would mature well before the mint-eligibility depth (`D_mint` ~2016 blocks), letting a depositor mint **and then** refund → destroy backing; separating the UTXOs and making the post-`MoveToBacked` output permanently backing-only extinguishes that path.

**Failure table:**

| Failure | Outcome |
|---------|---------|
| Gatekeeper refuses **before** `MoveToBacked` (does not co-sign) | Minter reclaims via **deposit-taproot** refund leaf after `refund_timelock`; BTC never stuck on refusal; third parties cannot force `MoveToBacked` (gatekeeper co-sign required in gated mode) |
| Depositor withholds co-signature on `MoveToBacked` | `MoveToBacked` does not fire; minter may reclaim via deposit-taproot refund after `refund_timelock` (INV-01: contribution never imposed) |
| Gatekeeper withholds mint signature after canonical check fails / not yet ready | No mint settles; if `MoveToBacked` already fired with depositor (+ gatekeeper) co-sign, BTC is an irrevocable consented reserve contribution (INV-01) |
| Gatekeeper/operator fails **after** `MoveToBacked` (mint never settles) | Vaulted BTC is an **irrevocable, consented contribution to the shared reserve** (cross-graph redeemable by others — not merely frozen recoverable BTC) |
| Operators fail to fire `MoveToBacked` | Minter reclaims via **deposit-taproot** refund leaf after `refund_timelock` |
| Mint settles | Minter/recipient holds zkBTC; backing-only vault remains under pre-signed assert/challenge/disprove graph for later peg-out (**no** live CHECKSIG) |

**Plain statement:** peg-in **depends on the gatekeeper only when one is designated** — that **is** the optional quality gate and the canonical-chain anchor (R-04 / Attack A: covers `MoveToBacked` **and** `reg_root_E`) for mint settlement. **Attack B is closed by R-09**, not by the gatekeeper. REQ-4 concerns exit only (gatekeeper-independent). The product default is no-gatekeeper + R-09 (Corner D / §1.1.1). A gatekeeper is **not** required for Attack B or for the effectively-trustless claim.

#### 4.2.1 Deposit taproot and vault output structure (normative outline)

Exact script templates are launch-time artefacts of the BitVM2 graph compiler (`PROVISIONAL` byte pin — NEW-03). The normative **semantic** requirements on the structure are:

1. **Deposit vault path** spends only into the **pre-signed** `MoveToBacked` under the N-of-N aggregate / MuSig2 path as required by the reference construction — **not** via the user's refund leaf. The aggregate key **MUST** be admitted by `operator_set_root` (policy → epoch `reg_root` → `agg_key`). Signatures for `MoveToBacked` are produced at setup; each signer's **epoch signing secret** under `agg_key_E` **MUST** be deleted after the **epoch's** presigning completes (NEW-01; identity keys are **not** deleted — §2.1), not merely its MuSig2 nonces. Firing **MUST** require the co-sign gate of §4.2 step 1: **depositor co-signature in both modes** (INV-01); **gatekeeper co-signature additionally** in gatekeeper mode.
2. **Recipient commitment path or leaf data** carries `recipient_commitment` so clause (g) can open it; the commitment **MUST** be fixed before the user signs the deposit.
3. **Depositor-base commitment (no-gatekeeper mode)** carries `depositor_base_commitment` so clause (b) can open it; **MANDATORY** when `gatekeeper = 0³²`.
4. **Deposit refund path (deposit taproot only — R-01)** pays the minter after `refund_timelock` CSV **if and only if** `MoveToBacked` does not complete. `MoveToBacked` consumes this output and extinguishes the refund. This is the depositor's **only** unilateral protection.
5. **Vault output script** after `MoveToBacked` **MUST** be byte-equal to `instantiate(vault_template, asset_id, agg_key, epoch)` (§3.1.1 — NUMS internal key + ordered pre-signed-graph tapleaf set; **no** depositor refund leaf; **no** cooperative refund leaf). Byte-equality is relative to the launch-pinned template (NEW-03).
6. **All vault-output value-moving spend paths MUST be CSV-locked to the BitVM2 assert/challenge/disprove windows** (B-06 / §4.4) after `MoveToBacked` confirmation (operator/reimbursement leaf, claim/sequencing connectors). **MUST NOT** include a depositor refund leaf. **MUST NOT** include a cooperative refund leaf. **MUST NOT** include a live free-form `agg_key` CHECKSIG (NEW-01). There is **no** `D_mint + S + W + 1` mint-window CSV term.
7. **Internal key (MUST — NUMS on vault).** The vault output's internal key **MUST** be the unspendable NUMS point of §3.1.1 so there is **no key-path spend**. Deposit outputs **SHOULD** likewise use NUMS or equivalent so that no single party can bypass script paths — matching Clementine/BitVM2 deposit style.
8. **Pre-signed graph only (MUST — NEW-01).** Every vault spend is a pre-committed graph transaction (reimbursement assert/challenge/disprove/payout connectors), each authorised by setup-time N-of-N signatures with **epoch signing keys** then deleted. A live CHECKSIG by the current identity-key holders is **forbidden**. The presigning set is **N-of-N**, not t-of-n.

### 4.3 Peg-out (gatekeeper-independent)

Numbered happy path:

1. **Consolidate.** Holder consolidates internally (shielded transfers) to an available payout denomination of the current epoch.
2. **Redeem transition.** Holder proves a redeem (§3.5): burns the denomination, sets non-zero `redeem_commitment` (incl. `max_fee` with `max_fee < redeem_amount`), anchors `(Pkᵢ, Rᵢ)`.
3. **Request.** Holder submits the opening `(redeem_amount, btc_recipient, max_fee, redeem_blind)` and the desired payout output (P2TR to `btc_recipient`, amount ≥ `redeem_amount − max_fee`; the operator funds and self-commits the payout with `SIGHASH_ALL` — §3.5.6) to **any registered operator** (open set — §4.1.1).
4. **Front.** **Any registered operator** **MAY** front BTC from **own funds** (not the vault) by funding and broadcasting a complete payout transaction committed in full under `SIGHASH_ALL` (non-malleable — §3.5.6), choosing an actual fee `≤ max_fee`. The mining fee of the payout transaction is funded by the operator's own input/anchor — **never from vault value**.
5. **Claim.** Operator claims vault reimbursement via the **BitVM2 assert/challenge/disprove** machinery (a **pre-signed graph** path — NEW-01; never a live vault CHECKSIG). The claim transaction **publicly commits the claim-marker tuple `(Pkᵢ, Rᵢ, payout_txid, payout_vout)`** on Bitcoin as a first-occurrence marker in the claim-marker namespace (logical claim-consumption + payout first-marker — §3.5.5 NH-02 / NEW-02). The operator does **not** spend the recipient's payout UTXO. Claims of one operator are **serialized** through that operator's sequencing connector (§4.1 role-note (c)). The claim **MUST** prove the claimant funded the payout by a **non-transferable, sole-funded claimant-committed payout** (the claimant is the payout's **sole, single-party funder** — every input authorised by its identity alone, no jointly-signed input; the payout tx commits the claimant's identity + redeem ID, uses SegWit-only inputs, and is signed `SIGHASH_ALL`; only the committed operator can claim it) (§4.3.2 item 12 / NEW-04).

**Fraud statement (operator reimbursement claim):** the full conjunct list of §4.3.2 (accumulator + S2C + recursive `C` verification + consumed-key binding + redeem branch + asset binding + value preservation + canonical payout under `max_fee` + claim-marker uniqueness over the **valid unchallenged** set + non-transferable, sole-funded claimant-committed payout (sole single-party funding + identity commitment + SegWit-only + `SIGHASH_ALL`)). Verified via the **BitVM2** assert/disprove path (SNARK/Groth16 verified optimistically; permissionless challenge). Wrong claims whose violated predicate is mechanized in the BitVM2 graph are killed by a permissionless **disprove** transaction (a fraud proof any full-node challenger can post); the redeem-side payout-canonicity predicate is **not** yet mechanized (§5 residual 11 / §11 item 14), so a deep private-fork payout is not provably killable by the disprove as described today; BitVM3/Glock (§10.1) later compress this to a ~single-signature-scale disprove.

6. **Reimbursement.** After the challenge window without successful challenge, operator takes reimbursement from the vault along the pre-signed graph: the claim **MUST** remove **exactly `redeem_amount`** from the vault (NH-01) — vault-input value minus change-back-to-the-same-vault-descriptor equals `redeem_amount`, with the change output constrained back to the (in-set) vault. The mining fee is funded by the operator's own input/anchor, **never from vault value** (else backing erodes below remaining supply). A second claim for the same `(Pkᵢ, Rᵢ)` or the same payout outpoint is counterprovable by inclusion of an earlier **valid, unchallenged claim-marker** (logical first-marker, not a UTXO spend of the payout; slashed markers excluded — NEW-02).
**The gatekeeper appears nowhere in this path (REQ-4).** Exit is gatekeeper-independent and operator-liveness-bounded.

**Liveness residual (honest):** exit requires ≥ 1 live, liquid, willing **registered** operator **of some in-set epoch that still holds unspent same-asset vault capacity** (redeem is cross-graph, so any such operator can serve — but if every epoch with capacity has been abandoned, exit freezes — §4.3.1 "All operators disappear"). The operator set is **open** (anyone may register to serve, including the holder — §4.1.1), so the residual is *liveness of ≥1 registered operator*, not a privileged party. The §1.3 mechanism-class table marks this exit **PARTIAL**; bitvm.org states that without at least one honest operator "the funds become unspendable eventually" (`https://bitvm.org/bitvm2`). Dishonest operators cannot steal under 1-of-N setup honesty + ≥1 honest live challenger actually acting within every relevant challenge window (§5 residual 3); worst case under that model is freeze / burn of affected deposits, not silent theft (under sound circuit/BitVM2-graph crypto — a critical soundness bug can instead enable theft, §4.5) (else unchallenged-fraud drain — §3.6). Because the redeem **burns first** and requests an operator afterward (steps 2→3), a holder who sets `max_fee` too low, or redeems when no operator's economics clear `max_fee`, holds a burned coin that is unservable until some operator serves — a real user-facing liveness/ransom cost (§4.3.1), not merely a delay.

**Cross-graph note.** Because peg-out is cross-graph, the fraud statement's asset-equality conjunct (§4.3.2 item 6) plus `operator_set_root` membership together ensure a redeem only draws **in-set** vaults of the same asset (same policy root). Under open registration **with R-09**, *in-set* of a vault created after an honest join **is** 1-of-N-honest: Attack B is closed at **setup** by growth-only S, not at redeem (§3.1.2). Without R-09, in-set is not 1-of-N-honest (**Corner C**).

#### 4.3.1 Peg-out failure modes

| Scenario | Outcome | Residual class |
|----------|---------|----------------|
| Assigned operator offline | Reassignment after timeout (§4.4); another registered operator fronts | Liveness delay |
| All operators refuse one holder | The redeem burn already happened (§4.3 step 2) and **cannot be un-burned**; exit stalls until some registered operator serves within `max_fee`. If no operator's economics clear `max_fee` (thin liquidity, capital cost, low-value asset), the burned coin is **unservable** until one does — set `max_fee` adequately at redeem time. Mitigation: the holder **MAY** have pre-registered as their own operator (§4.1.1) to self-serve. | Liveness / ransom |
| All operators disappear | Vault UTXOs locked under presigned paths; no pure user self-spend without covenants (§10.2); holder who never registered cannot reclaim alone | Liveness freeze |
| Holder pre-registered as own operator | Holder **MAY** front + reclaim own redemptions from epochs they registered for (§4.1.1) | Self-served exit (open registration) |
| Operator claims without valid redeem | Permissionless BitVM2 disprove; bond slash + sequencing-connector burn | Safety (if ≥1 challenger acts) |
| Watchtower one-shot vs one operator | Sequencing connector ejects the operator after one successful counterproof (§4.1 role-note (c)); floor covers independent operators | Safety design hole only if floor of independent operators fails |
| Double reimbursement claim for same `(Pkᵢ, Rᵢ)` | Counterprovable by Bitcoin inclusion of earlier **valid unchallenged** claim-marker; slashed markers do not block retry (NEW-02) | Safety (1-honest watchtower) |
| Payout outpoint reused across claims | Counterprovable by first-marker of earlier valid claim-marker tuple (NH-02; logical marker, not UTXO spend); the payout tx commits the claimant's identity + redeem ID and is non-malleable (SegWit-only + `SIGHASH_ALL`), so the claim is non-transferable to another operator (NEW-04) | Safety (1-honest watchtower) |
| Claim hijack (free-rider, relocation, duplicate-payout, or co-signed multi-claimant) on another's payout | Fails the **non-transferable claimant-committed sole-funded payout** rule: the payout tx commits the funding operator's identity + redeem ID, is non-malleable (SegWit-only + `SIGHASH_ALL`), and requires every input authorised by the claimant (sole funder), so the claim fails because the hijacker is not the payout's sole funder / not the committed identity (NEW-04) | Safety (if ≥1 honest challenger acts in-window) |
| Gatekeeper offline or hostile | **No effect** on peg-out | REQ-4 property |

#### 4.3.2 Fraud-statement witness (bridge circuit)

The BitVM2 assert/disprove path that authorises operator reimbursement **MUST** verify a statement equivalent to the **old accumulator + S2C checks PLUS the additions below** — a full conjunct list, not a replacement of the accumulator checks. All of the following **MUST** hold:

```
Exists opening (asset_id, redeem_amount, btc_recipient, max_fee, redeem_blind)
and a redeem transition proof such that:

  1. (Pkᵢ, Rᵢ) is first-occurrence completed on the Bitcoin-derived zkCoins
     nullifier accumulator.
  2. Rᵢ S2C-opens H(ProofData) containing redeem_commitment, where
     redeem_commitment = Hc("zkCoins/v2/RedeemCommit",
                            asset_id ‖ redeem_amount ‖ btc_recipient
                            ‖ max_fee ‖ redeem_blind).
  3. Recursive verification of the redeem transition's C proof under the
     pinned v2 verifier data (parent specification.md §5.6 requires this).
  4. Pkᵢ == redeem_proof.consumed_pubkey
     (specification.md §5.6 anti-naked-nullifier binding).
  5. The verified transition took the TS3 redeem branch:
     In(zkBTC) == redeem_amount and Out(zkBTC) == 0
     (proven via the recursive proof — see exposition note).
  6. asset_id in the opening equals the zkBTC asset_id bound to this vault
     (via vault_template / instantiate and operator_set_root; MUST — else a
     self-issued cheap foreign TS3 asset with its own vault and redeem
     could drain this asset's vault). The vault being drawn from MUST have
     agg_key admitted by this asset's operator_set_root.
  7. Fee bounds (NH-03): max_fee < redeem_amount, and
     redeem_amount − max_fee is computed as an exact non-negative
     wide-integer (parent specification.md §2.6 gadgets) — no underflow, no zero payout
     from wrapping.
  8. The Bitcoin payout output is P2TR(btc_recipient) with amount
     ≥ redeem_amount − max_fee, confirmed on the canonical chain
     (the receiver's / challenger's own view at deep depth — NOT
     "the operator's claimed chain").
     Honest note (redeem-side canonicity — §5 residual 11, partly OPEN):
     "confirmed on the canonical chain" here has NO external anchor on
     the redeem side (the gatekeeper is absent by design — REQ-4). Depth
     >= D on *some* header chain does NOT distinguish a canonical payout
     from a deep private-fork one (same LCP limit as the mint side,
     §3.4). To hold against a deep private fork the challenge/disprove
     path MUST compare CUMULATIVE WORK (most-work chain), so an honest
     challenger can counter-prove a heavier canonical chain on which the
     claimed payout is absent. Whether the concrete BitVM2 disprove can
     enforce that most-work comparison is an OPEN conversion/audit item
     (G3 / G4 — §11); this document does NOT assert it as already
     achieved. Until it is shown, redeem-side payout canonicity is an
     UNMECHANIZED bound resting on sub-~45-50% hashrate (§5 residual 4) +
     >=1 honest active challenger (§5 residual 3) — the redeem-side
     analog of the mint reorg residual, but (unlike the mint side, closed
     by the gatekeeper's external R-04 view) not closed by a specified
     mechanism here.
  9. Payout binding (NH-02 — logical claim-marker, not UTXO spend): the
     claim publicly commits the claim-marker tuple
     (Pkᵢ, Rᵢ, payout_txid, payout_vout) as a first-occurrence marker
     in the claim-marker namespace; that payout outpoint's confirmation
     height is strictly greater than the first-occurrence height of
     (Pkᵢ, Rᵢ); a second claim reusing the same (Pkᵢ, Rᵢ) or the same
     (payout_txid, payout_vout) is counterprovable by inclusion of an
     earlier **valid, unchallenged** marker. The operator does NOT spend
     the recipient's UTXO.
 10. Claim-marker uniqueness over the valid set only (NH-02 / NEW-02 —
     §3.5.5): no prior **valid, unchallenged** reimbursement
     claim-marker carries the same (Pkᵢ, Rᵢ) or the same
     (payout_txid, payout_vout). **Exclusion rule (MUST):** a marker that
     is **slashed**, **successfully counterproved**, or otherwise
     **failed** under the challenge path is **excluded** from the
     uniqueness set and MUST NOT block an honest retry. Only a valid,
     unchallenged claim consumes the redeem ID / payout outpoint for
     uniqueness.
 11. Value preservation (NH-01): the reimbursement removes exactly
     redeem_amount from the vault —
       vault_input_value − change_to_same_vault_descriptor
         == redeem_amount
     with the change output constrained back to the same in-set vault
     descriptor. The mining fee is funded by the operator's own
     input/anchor, NEVER from vault value.
 12. Non-transferable, claimant-committed, SOLE-FUNDED payout
     (MUST — NEW-04): the fraud statement MUST prove the claim is bound
     to a committed claimant identity AND that the claimant is the sole
     funder — it does NOT infer funding from input values. Rule:
       - SOLE FUNDER, SINGLE-PARTY-AUTHORISED (mechanized core): every
         input of the payout transaction MUST be authorised by the
         claiming operator's registered identity (its bonded key / a
         funding-key set bound to it), AND each input's spending
         condition MUST require ONLY that identity — no input may require
         a co-signature from any non-claimant key; a payout tx with ANY
         input the claimant did not SOLELY authorise — a separate input,
         OR a jointly-signed (2-of-2 / multisig) input co-controlled by
         another party — is NOT claimable. A co-funded tx (separate or
         jointly-signed input supplied by a second party) FAILS this
         rule;
       - the payout tx carries a SINGLE, HIDING claimant-identity
         commitment (a blinded commitment to (claiming operator's
         identity, redeem ID (Pkᵢ, Rᵢ)) in an OP_RETURN or equivalent
         field, opened only in this claim; encoding launch-pinned; a tx
         with zero or multiple such commitments is not claimable);
       - ALL payout-transaction inputs are SegWit (v0/Taproot; empty
         scriptSig), so txid is non-malleable;
       - the claimant signed the payout tx under a full-transaction
         commitment (SIGHASH_ALL; all inputs and outputs; NOT
         ANYONECANPAY);
       - the output at payout_vout pays btc_recipient at least
         redeem_amount - max_fee (NH-03), from the claimant's own funds
         (never vault value; NH-01);
       - the CLAIMING operator's identity EQUALS the committed identity
         AND authorised every input (a claim by any other party, or
         against a payout carrying any non-claimant input, fails).
     Why sound: the claim is NON-TRANSFERABLE (only the committed
     operator can claim) and SOLE-FUNDED, SINGLE-PARTY-AUTHORISED (the
     claimant solely authorised every input, so a co-funded ride via a
     separate OR a jointly-signed input is not claimable — closed
     mechanically, not by an "honest won't co-sign" assumption), and the
     tx is non-malleable (SIGHASH_ALL + SegWit-only inputs). This
     supersedes the gross, net, index-pairing, and SIGHASH_ALL-only
     checks. Honest status (do not overclaim): Bitcoin exposes spending
     authority, not economic provenance, so this closes the KNOWN
     claim-hijack variants; the exact single-party input-authorisation
     check and any residual economic-attribution question are a G4
     external-audit and G3 conversion focus. The invariant
     (non-transferable claim bound to the sole, single-party funding
     operator) is normative now.
```

**Fee rule (normative).** `max_fee` is a **ceiling** committed inside `redeem_commitment` with `max_fee < redeem_amount`. Payout **MUST** pay `btc_recipient` at least `redeem_amount − max_fee` (exact non-negative wide-integer subtraction). This is provable and market-viable (the operator sets its actual fee ≤ `max_fee` at fronting time). An **exact** fixed fee **MUST NOT** be bound: a fee spike between redeem burn and fronting would otherwise leave the coin permanently unservable (loss of funds).

**Value-preservation rule (normative — NH-01).** Reimbursement **MUST** remove **exactly `redeem_amount`** from the vault. Any wording that takes `redeem_amount + fee` from the vault is **incorrect**: the fee is operator-funded. Otherwise backing erodes below remaining circulating supply.

**Exposition note (MUST — protects §8.2 until claim).** The redeem-branch values (`In`/`Out`/`redeem_amount`/opening) are exposed **only to the reimbursement circuit via recursive verification**, **NEVER** as on-chain public inputs of `C`. A redeem transition therefore stays on-chain indistinguishable from any other transition **until** the operator's reimbursement claim marker appears; that marker then links the redeem to its payout (§8.2). Cross-check: §3.7.2 "recursion-only values".

Exact packing into BitVM2 public inputs is conversion-path work (§11). The token standard fixes the **semantic** statement so the conversion cannot silently weaken it.

### 4.4 Parameters (normative table)

Denominations, `refund_timelock`, and related deposit-epoch economics are **per-deposit-epoch bridge parameters**, not `IssuanceTerms_v3` fields. Changing them for **new** deposits does not change `asset_id`. **`D_mint` and optional `S` are different:** they are checked **in-circuit** by the mint LCP (§3.3(e)), so they are **v2-circuit-pinned consensus parameters** (§3.7.2 / §11 item 6) — advancing either is a **circuit-parameter release (new digests)**, not a per-epoch change. Both are outside `asset_id` (not token identity) but are **not** per-epoch-adjustable in the way denominations and `refund_timelock` are. Existing vaulted deposits keep the parameters of their epoch's presigned graph. (`refund_timelock` governs the deposit taproot only — consistent with denominations staying outside token identity.) There is **no** mint-freshness window `W` and **no** host-side `tip_height` rule.

| Parameter | Value | Reference baseline | Rationale |
|-----------|-------|--------------------|-----------|
| **Denominations (start set)** | **{0.1, 1, 10} BTC** (`PROVISIONAL`) | Clementine 10 BTC; Bitlayer BitVM2 | High minima allowed by REQ-4; re-based on BitVM2/Clementine economics (BitVM2 worst-case dispute cost ~$16k class). BitVM3/Glock (§10.1) later enable lower minima (toward 0.01) once mainnet-proven |
| **0.01 BTC denomination** | **Gated** behind efficiency-upgrade evidence | Earlier research sketches used 0.01 | Under BitVM2, worst-case dispute cost is a larger fraction of a 0.01 deposit than under projected Glock/BitVM3 economics; fee-spike / challenger-collateral weakness hits small denominations hardest; per-deposit graph setup scales with deposit count. Enable **only after BitVM3/Glock mainnet evidence** lowers dispute cost (§10.1) |
| `refund_timelock` | 200 blocks (`PROVISIONAL`) | Clementine / BITVM_BRIDGE | ~33 h unilateral user reclaim on **deposit taproot only** if `MoveToBacked` stalls; **not** on vault output (R-01); **not** in `asset_id` |
| `D_mint` | ~2016 blocks (`PROVISIONAL`) | Bridge security horizon; long finality OK per REQ-4 | Mint LCP: `MoveToBacked` confirmation depth lower bound (§3.3(e)); private-fork mining for mint value prohibitively costly / very low success probability at this depth for a sub-majority miner. **Circuit-pinned (v2 release)** — changing it is a new-digest circuit-parameter release (§3.7.2 / §11 item 6), not a per-epoch value |
| `S` | Launch param (`PROVISIONAL`, optional) | — | Mint LCP depth upper slack (when configured: depth ∈ `[D_mint, D_mint + S]`). **Circuit-pinned (v2 release)** — new-digest release to change (§3.7.2 / §11 item 6), not per-epoch |
| Vault spend-path CSV | **BitVM2** assert/challenge/disprove windows (B-06; same order as claim challenge window below) (`PROVISIONAL`) | Citrea/Clementine (BitVM2) | Operator/reimbursement + claim/sequencing connectors only — script-path under NUMS; pre-signed graph (no live CHECKSIG); **no** depositor or cooperative refund leaf on backing-only vault (R-01 / NEW-01); locked after `MoveToBacked`. **Not** a mint-window formula |
| Operator reassignment timeout | 504 blocks (`PROVISIONAL`) | Citrea/Clementine (BitVM2) | ~3.5 days before reassignment |
| Claim challenge window | 1064 blocks (`PROVISIONAL`) | Citrea/Clementine (BitVM2) (~1.4 weeks class) | Long windows OK per REQ-4; also pins the vault assert/challenge/disprove CSV order of magnitude (B-06) |
| Operator bond | BitVM2/Clementine-scale; exact = launch param (`PROVISIONAL`) | Clementine ~2 BTC (BitVM2-era) | Must match BitVM2 slash economics at launch pin; slash burns sequencing connector (§4.1 role-note (c)). BitVM3 later lowers required bonds (§10.1) |
| Payout fee | Market-set under `max_fee` ceiling committed in `redeem_commitment` with `max_fee < redeem_amount`; baseline 0.003 BTC (`PROVISIONAL`) | Clementine / BitVM2 ops | Operator keeps fee ≤ `max_fee`; fee never taken from vault (NH-01); no exact fixed fee bound into the commitment |
| Minimum independent watchtower count | **≥ 3** (`PROVISIONAL` floor) | PA replaced by sequencing connectors (Clementine/Strata class one-shot) | Floor bounds **independent operators** (each consumes ≤1 one-shot before ejection), not sequential claims of one operator (§4.1 role-note (c)) |
| Registration window / epoch cadence / setup window | Launch param (`PROVISIONAL`) | Open-operator market §4.1.1 / §4.1.2 | **Scheduling / economics values only** — this epoch's registration-window length, epoch cadence, exact bond amount within the policy-P bond **class**, and setup-window deadline for N-of-N presign completion (§4.1.2 item 5). These do **not** change `asset_id`. Identity-bound policy (join rule, R-09 growth-only / no-leave, bond class/tier, anti-domination predicate, KeyAgg+PoP, optional R-08 duty for gated deployments) lives in `operator_set_root` (§3.1 schema comment / §3.1.3) |

Mark every value **`PROVISIONAL` until BitVM2 launch-pin against live economics.**

### 4.5 No-council trade-off

This profile has **no** emergency multisig, **no** admin keys, and **no** in-place upgrade path for a live vault graph. Combined with NEW-01, the vault **presigning set is N-of-N** (not t-of-n) and there is **no live threshold signing path** that a current operator coalition could use to improvise vault spends: every vault movement is a pre-signed graph transaction whose **epoch signing secrets** are deleted (identity keys remain).

**Consequence of a bug depends on its class.** A **non-soundness bug** (liveness / graph-construction / operational — e.g. a mis-wired connector or a stuck watchtower) under **1-of-N setup honesty, ≥1 honest challenger acting in-window, and sound circuit/BitVM2 crypto**: affected deposits can irreversibly freeze (BitVM-family property: worst case is burn / freeze, not silent theft by a dishonest minority — but absent an active in-window challenger, unchallenged fraudulent reimbursement can instead drain, §3.6). A **critical soundness bug in the circuit itself or in the BitVM2 graph** is a **different failure class**: 1-of-N *setup* honesty is a key-custody assumption and does **not** cover circuit/crypto **soundness**, so such a bug **can enable actual vault theft** — consistent with the §5 "Reserve safety" row's **"sound BitVM2 crypto"** condition and its **"False claim reimburses thief"** failure mode. The pre-mainnet external audit gate (§4.6(B) maturity-gate audit item (G4) and the §4.5 "Required discipline" items below) exists **precisely** to **address** the circuit/graph-soundness class before mainnet — sound circuit/graph crypto remains a **standing assumption even after audit** (§5 / G4). Without a Security Council, there is no trusted party that can sweep funds to a Safe Harbor. If `MoveToBacked` fires but the mint never settles, the backing-only vault is an **irrevocable, consented contribution to the shared reserve** (no cooperative refund, no depositor vault refund — R-01 / INV-01; may be consumed by another holder's cross-graph redeem — §4.2 / §3.3.2 / §3.4), not recoverable via a live multisig or depositor reclaim.

**Required discipline before mainnet:**

- specification.md §1.7.8-grade freeze discipline on the v2 circuit surface;
- differential testing of LCP and mint/redeem branches;
- external audit gate on the v2 circuit, BitVM2 stack, and **pre-signed** graphs **before** mainnet (including verification that **epoch signing secrets** are deleted, that **identity keys remain**, and that no live `agg_key` CHECKSIG leaf remains on vault outputs);
- the §4.1 role-note (c) per-operator **sequencing connector** plus the §4.4 independent-watchtower floor close the one-shot weakness that a Payout Admin covers (graph structure, not an admin key).

**Upgrades:** new-vault migration only — new deposits into a new graph / new `vault_template` or new `operator_set_root` (new `asset_id` if those bound fields change); holders redeem-and-re-peg to move. Never in-place rotation of a live vault's admin keys or of a gatekeeper (gatekeeper rotation = new asset — §3.1). Efficiency upgrades (BitVM3/Glock/Mosaic — §10.1) are a verifier-trait swap + new vault graph (new epoch), not a token-standard change.

**Comparison:** Citrea's Security Council (3-of-5) **can** move funds in emergency / upgrade paths (Citrea Clementine docs — §12.3). This design refuses that trust root deliberately and pays for it with irreversibility.

### 4.6 Launch gates (normative)

Two blocking gate families. Both **MUST** clear before any public claim that a deployed asset is **zkBTC** under this specification.

#### (A) REQ-4 gates

Without these, the REQ-4 claim is **false** (a mint-time party re-enters on the safety or liveness axis of exit).

1. **Policy-P anti-domination and R-09 (open registration market).** Policy P's admissibility predicate **MUST** ensure that no single party controls ≥ half of S, **and MUST** encode R-09 (growth-only, no kick after admission, every new vault N-of-N over current S). Enforced economically by bond cost + honest-registration assumption; **Attack B is closed by R-09**, not by a gatekeeper vouch. (R-04 remains the private-fork / Attack A backstop when a gatekeeper is designated and is independent of this domination gate.) Bootstrap capture of **genesis** S (one organisation == entire S at first mint) reintroduces the prefix residual of R-09 item 6 — hence the first-mint rule.
2. **Setup integrity (BitVM2 form).** For every dispute path, N-of-N presign ceremony integrity **MUST** hold, with the independent-watchtower/challenger floor met and the anti-grief ceremony rule of §4.1.2 item 5. Toxic-waste concern re-based to BitVM2: connector/presign correctness; one honest signer deletes its **epoch signing secret** (NEW-01; identity keys remain). The ceremony **MUST** ensure that no single mint-time party monopolises setup artefacts that would allow forging or voiding fraud proofs.  
   **Open point:** IF a global circuit-specific setup artifact also exists in the BitVM2 conversion path (to be verified as part of the Plonky2→BitVM2 work), the classic "MPC ceremony with independent contributors" gate **MUST** apply there too. Do not abstract this uncertainty away.
3. **Documented holder → operator onboarding** (self-fronting) via **open permissionless registration** (§4.1.1 / §4.1.2), acknowledging the bonded-onboarding cost of §4.1 role-note (b).
4. **Challenger economics documented.** Name deployed Clementine's self-funded-challenge gap (challengers must self-fund; cross-chain reimbursement not deployed) as the **anti-pattern** to solve. BitVM2 permissionless challenge still needs challenger incentive/funding — an honest open item (not an availability gap).

#### (B) Maturity / integration gates

Restatement of §4.0 as a checklist (three gates — all **MUST** clear):

- [x] BitVM2 mainnet live (CLEARED — Bitlayer 2025-07; Citrea Clementine live 2026-01)
- [ ] Reference open-registration operator market operational (§4.1.1 / §4.1.2) — track (b)
- [ ] **Plonky2 → BitVM2 (Groth16/SNARK) conversion of the zkCoins compliance predicate demonstrated** — track (a)
- [ ] (G4) External audit of the v2 circuit, BitVM2 graph, and pre-signed graphs published (circuit/graph soundness — the class that can enable theft per §4.5 / §5)

---

## 5. Trust matrix

| Concern | What must hold | Who | Failure effect | Gatekeeper-dependent? |
|---------|----------------|-----|----------------|----------------------|
| **Reserve safety** | 1-of-N setup honesty **after** epoch presigning completes and ≥1 honest operator deletes its **epoch signing secret** (correct presign; identity keys stay); **no-full-collusion during the pre-deletion window** (§2.1 / residual 12); **permissionless challenge (BitVM2)** **plus ≥1 honest live challenger/watchtower actually acting within every relevant challenge window** (§5 residual 3; availability ≠ guaranteed action — §4.1 role-note (a)); per-operator sequencing connectors; ≥ floor independent watchtowers; sound BitVM2 crypto; `operator_set_root` **policy** honesty basis | Operators / watchtowers / setup | False claim reimburses thief; or vault frozen | **No** (if gates A hold) |
| **Mint integrity / canonicity** | TS3 clauses (a)–(h); LCP proves `MoveToBacked` at depth ≥ `D_mint` + N-of-N; recursive `operator_set_root` equality **and R-09 superset** (growth-only S — Attack B); **and** (gatekeeper mode) gatekeeper withholds `Pk_mint` until `MoveToBacked` **and** `reg_root_E` are confirmed on its **own canonical Bitcoin view** and the deposit is not refunded there (**R-04** / Attack A) | Minter + **gatekeeper as canonical-chain anchor** (`MoveToBacked` + `reg_root_E`) when designated; depositor co-sign on `MoveToBacked` always (INV-01); operators of S refuse malicious graphs (R-09) | Unbacked mint; private-fork amortization mint (Attack A); self-controlled Sybil-epoch vault drain (Attack B, if R-09 is absent — Corner C — or via the prefix residual of R-09 item 6); or (no-gk) non-canonical mint if operators reimburse it | **Yes for Attack A canonicity** when designated (R-04). **No for Attack B** — R-09 is gatekeeper-independent. **Corner C (open-reg + pooled without R-09): UNSOUND.** Product default is Corner D (no-gk + R-09) — residual 9 / §3.2.1.2 |
| **Transfer** | Ordinary parent specification.md §2 soundness + nullifier first-occurrence | Protocol | Double-spend / invalid transfer rejected | **No** |
| **Redeem liveness** | ≥ 1 live liquid **registered** operator (open set §4.1.1); bonds / fees economic under `max_fee` | Operators | Exit stalls (ransom / freeze risk) | **No** |
| **Redeem safety** | Full §4.3.2 fraud statement; claim-marker uniqueness (logical first-marker); value preservation; permissionless BitVM2 challenge paths **plus ≥1 honest live challenger actually acting in-window** (if ≥1 challenger acts — §4.3.1; §5 residual 3) | Operators / challengers | Unbacked vault drain | **No** (if gates A hold) |
| **Entry quality** | Gatekeeper SoF + vault legitimacy vouch (when present); else structural only | Gatekeeper / none | Tainted mint waved through; or refusal/delay — depositor reclaims via the deposit-taproot refund **only if refusal is BEFORE `MoveToBacked`**; a gatekeeper that withholds `Pk_mint` **after** `MoveToBacked` has fired leaves the depositor's vaulted BTC an irrevocable consented reserve contribution (no refund — §3.4 / residual 8), a real depositor loss-of-funds path | **Yes** when designated (by design) |

**Residual assumptions (honest list):**

1. 1-of-N setup honesty (key-deletion style covenant emulation for presigned paths) over the **asset-bound, openly registered** operator set under policy P (`operator_set_root`).
2. ≥ 1 independent **registered** operator for exit liveness (open set — anyone may register, including the holder).
3. ≥ floor independent watchtowers (normative `PROVISIONAL` ≥ 3) **and** per-operator claim serialization (§4.1 role-note (c)) against the watchtower one-shot weakness; **and**, for reserve/redeem safety, **≥1 honest, live challenger/watchtower actually acting within every relevant challenge window** — not merely that a floor count exists or that challenge is permissionlessly available (mechanism-availability is delivered by BitVM2 — residual 6 / §4.1 role-note (a); safety requires actual action; else unchallenged-fraud drain — §3.6).
4. **Bitcoin adversary below ~45–50% hashrate** for the relevant challenge/finality horizon. This is **Bitcoin's own base security assumption, inherited — not a zkBTC-specific weakness:** an attacker with majority hashrate can already reverse *any* recently confirmed Bitcoin transaction (deep reorg / double-spend / the "51% attack"), which breaks Bitcoin payments in general, not only this peg. zkBTC inherits it because mint-backing (§3.4) and redeem-side payout canonicity (residual 11) anchor to Bitcoin confirmations, and mitigates it with **deep finality** (`D_mint` ~2016 blocks ≈ two weeks — §4.4), which makes a private-fork attack **prohibitively costly and, for an attacker comfortably below 50%, very unlikely to succeed** — deep finality lowers the success probability and raises the expected cost, but the success probability **rises as the margin to 50% narrows** and it does **not** guarantee safety at a hashrate margin arbitrarily close to 50% (Clementine / whitepaper class bounds).
5. Deep-finality of `MoveToBacked` at depth ≥ `D_mint` on the proven LCP chain (§3.4); residual reorg deeper than `D_mint` is D-16 class. **Canonical binding** of that chain — for **both** `MoveToBacked` **and** `reg_root_E` — to the Bitcoin tip is **not** in-circuit alone: in gatekeeper mode it is the gatekeeper's mint-signing duty (R-04 extended).
6. **Permissionless challenging is DELIVERED under BitVM2** (not an open dependency — residual 3 / §4.1 role-note (a)); mechanism-availability alone does **not** guarantee safety. The residual beyond delivery is (i) that **≥1 honest challenger actually acts in-window** (residual 3) and (ii) challenger **incentive/funding** economics that make such action rational (§4.6A(4)).
7. When a gatekeeper is designated: gatekeeper liveness at mint time (quality filter and **canonical-chain anchor (R-04: `MoveToBacked` + `reg_root_E`)** — §6), including the gated `MoveToBacked` co-sign and withholding `Pk_mint` until canonical confirmation of both anchors. **Not** a custody dependency over circulating coins or exits; **is** load-bearing for **Attack A** canonicity and SoF; **is not** the Attack-B close (R-09 is). Under gated mode, gatekeeper **integrity** is a backing-safety dependency **for Attack A** (§6.3). Skipping optional R-08 does not reopen Attack B if R-09 holds.
8. **Consented irrevocable reserve contribution residual (R-01 / INV-01):** if `MoveToBacked` fires (with **depositor co-signature in both modes**, plus gatekeeper co-signature in gated mode) but the mint never settles, the backing-only vault BTC becomes an **irrevocable, consented contribution to the shared reserve** (cross-graph redeemable by other holders) — not merely frozen recoverable BTC (§3.3.2 / §3.4 / §4.2). Unilateral escape only pre-`MoveToBacked` via the deposit refund leaf.
9. **No-gatekeeper Attack-A residual; Attack B closed by R-09 (§3.2.1.2):** without a gatekeeper (or equivalent canonical-oracle role), there is **no external canonical observer** at mint settlement for `MoveToBacked` or `reg_root_E` (**Attack A** **not cleanly closed** — R-04 absent; Bitcoin-class residual mitigated by `D_mint`). **Attack B is closed by R-09** in both gated and no-gatekeeper modes, provided the intended honest operator is in S before the first mint (§1.1.1). The economic anti-domination bond of policy P alone is **insufficient** against Attack B. **R-09 does not close Attack A.** **Corner C** (open registration + pooled **without** R-09) is **UNSOUND** and **MUST NOT** be deployed or marketed as trust-minimized or as effectively trustless. **Corner D** (open + pooled + R-09, no gatekeeper) is the **product default** — effectively trustless self-operator. **Corner A** adds a gatekeeper for R-04 / SoF. **Corner B** is closed-enumeration, not the product.
10. **Open-operator anti-domination residual:** policy P **MUST** prevent single-party domination of S (§3.1.2 / §4.6A(1) / §4.1.1) **and MUST** encode R-09; otherwise a self-controlled **new** vault re-opens **Attack B**. Economic bond/stake enforcement is weaker than R-09 and **insufficient alone**. **Prefix residual:** coins minted before the intended honest operator joined are untrusted because the token is fungible (§3.5.5); the first-mint rule of R-09 item 6 is load-bearing, not a footnote.
11. **Redeem-side payout-canonicity residual (§4.3.2 clause 8) — partly OPEN:** the fraud statement's "payout confirmed on the canonical chain" has **no external anchor** on the redeem side (gatekeeper absent by design — REQ-4), and depth alone does not distinguish a canonical payout from a deep private-fork one. Closing it requires the challenge/disprove to compare **cumulative work** (most-work chain), not mere depth; **whether the concrete BitVM2 disprove enforces that is an OPEN conversion/audit item (G3 / G4 — §11 item 14).** Until shown, payout canonicity is an **unmechanized** bound resting on sub-~45-50% Bitcoin hashrate (residual 4) + ≥1 honest active challenger (residual 3). It is the redeem-side analog of the mint reorg residual, but — unlike the mint side, which is closed by the gatekeeper's external R-04 view **when gated** (Corner D leaves Attack A as Bitcoin-class / `D_mint` — residual 9) — **not** closed by a specified mechanism in this document.
12. **Pre-deletion-window assumption (NEW-01 — §2.1):** during an epoch's registration/presign phase, before ≥1 honest operator has deleted its **epoch signing secret**, the full N-of-N coalition can still sign — so safety **in that window** rests on the stronger **no-full-collusion** assumption, not on 1-of-N. Once the epoch's presigning completes and ≥1 honest operator has deleted its **epoch signing secret** (identity keys stay), 1-of-N setup honesty holds and no spend outside the pre-signed graph can be authorised.

---

## 6. Gatekeeper model and compliance

### 6.1 Why a gatekeeper

**The gatekeeper is optional. It is not what makes zkBTC effectively trustless.** Attack B is closed by R-09. Operator-theft safety is 1-of-N setup honesty plus ≥1 honest live challenger acting in-window plus sound circuit/graph crypto (§1.1.1 / §5). Do **not** describe the gatekeeper as a required trusted party for pooled backing.

Without an entry filter, coins from a hack/theft or sanctioned sources could be minted into the shielded system and zkCoins abused for laundering. That harms **all** holders' fungibility, the token's reputation, and regulatory acceptance. When designated, the gatekeeper screens **source-of-funds** at entry.

**Additionally, when designated, two mint-time duties:**

1. **Source-of-funds / vault-legitimacy screening** (reputation / compliance surface).
2. **Canonical-chain anchor (R-04 / Attack A; covers `MoveToBacked` and `reg_root_E`).** The mint LCP proves `MoveToBacked` (and `reg_root_E`) confirmed at adequate depth on *some* header chain; nothing in-circuit alone binds that chain to the verifier's **canonical** Bitcoin view (§3.4). Because only the gatekeeper can produce the `Pk_mint` signature (`sk_mint = sk_gk + h`) that settles the mint, and the gatekeeper **withholds** that signature until it has verified on its **own canonical Bitcoin view** that (i) `MoveToBacked` is confirmed to depth ≥ `D_mint` on the canonical chain, (ii) the deposit was not refunded there, and (iii) `reg_root_E` is the canonical registration commitment for the epoch, a private-fork `MoveToBacked` or substituted `reg_root_E` yields no mint. A co-signed `MoveToBacked` alone is insufficient (setup signatures are valid on any fork).

Optional **R-08** (identity/reputation diversity vouch) is belt-and-suspenders. **Attack B is closed by R-09**, not by R-08.

Permissionless minting without a gatekeeper **is** the product default (Corner D) when R-09 holds: effectively trustless self-operator, with Attack A a Bitcoin-class residual mitigated by `D_mint`. Open registration + pooled **without** R-09 is **Corner C / UNSOUND**.

### 6.2 Whose interest

The gatekeeper represents the interests of the **asset's existing holders** — their coins' value and fungibility depend on the token not becoming a laundering vehicle. A holder-committee threshold key (MuSig2/FROST aggregate; still a single x-only key in-circuit) operationalises "represents holders." **Threshold / FROST is allowed only for the gatekeeper key** (approval liveness; cannot settle a private-fork mint **when performing R-04 honestly**; a compromised gatekeeper can enable Attack A — §2.1/§6.3; Attack B stays closed by R-09). The vault **presigning / operator set MUST be N-of-N** (NEW-01 — §2.1): one honest **epoch-secret** deletion is what delivers 1-of-N setup safety; a `t < N` operator threshold would leave `N−1 ≥ t` epoch shares able to sign after one honest deletion. Identity keys are **not** deleted. For the **gatekeeper**, N-of-N is discouraged (loss of a single member key permanently disables minting; rotation = new asset); threshold (t-of-n) for the gatekeeper is **RECOMMENDED** (§2.1).

### 6.3 What the gatekeeper is NOT (the guarantee)

The gatekeeper gates **ENTRY (new mints) only**. Mechanism for each non-power:

| Claimed abuse | Why it fails |
|---------------|--------------|
| Freeze circulating coins | No gatekeeper role in parent specification.md §2 holder transitions |
| Claw back settled mints or transfers | No protocol clawback; coins are ordinary parent specification.md §2 state |
| Block transfers | Same as freeze — no gatekeeper clause |
| Block redemptions | No gatekeeper role in §4.3 peg-out; REQ-4 |
| Mint unbacked supply | Deposit-backing clauses (e)/(f)/(h); LCP + amount discipline + **R-09**; gated mode also withholds `Pk_mint` until **canonical** `MoveToBacked` **and** `reg_root_E` (R-04 / Attack A) — **provided the gatekeeper performs R-04 honestly**; a compromised gatekeeper that skips R-04 can enable Attack A. Skipping optional R-08 does **not** reopen Attack B if R-09 holds (§6.3) |
| Redirect a mint | Clause (g) recipient binding |
| Double-mint one deposit | First-occurrence on deterministic `Pk_mint` |
| Inflate beyond real deposits | Same deposit-backing + uniqueness (mint-time 1:1 to a real deposit; **post-mint** backing integrity is conditional — §3.6 / §5) |
| Add/remove/rotate itself in place | `gatekeeper` frozen in `asset_id`; rotation = new asset |
| Directly forge a vault spend / steal circulating coins | No gatekeeper key on vault spends; N-of-N presigned graphs; no clawback of circulating coins |

A **compromised / negligent** gatekeeper **cannot** directly forge a vault spend, touch circulating coins, freeze, or block exit (REQ-4 intact). Skipping optional R-08 does **not** reopen Attack B if R-09 holds — a Sybil cannot form a vault that omits already-admitted honest operators. Skipping the R-04 canonical-chain check (on `MoveToBacked` or `reg_root_E`) re-opens Attack A. Burning a `Pk_mint` slot remains the benign failure mode. Therefore, when designated, **gatekeeper INTEGRITY is a backing-SAFETY dependency for Attack A (and SoF)**, not for Attack B. The gatekeeper is a **mint-time liveness dependency** and an **Attack-A canonicity / entry-integrity dependency** — never a custody dependency over circulating coins or redemptions, and **never** the reason zkBTC is effectively trustless.

### 6.4 Trade-off (honest) and security classes

| Class | Gatekeeper | Operator-set binding | Source-of-funds filter | Canonical-chain anchor (R-04 / Attack A) | Attack B close | Mint-time liveness + backing-safety dependence |
|-------|------------|----------------------|------------------------|------------------------------------------|----------------|------------------------------------------------|
| **Self-operator zkBTC (Corner D — PRODUCT DEFAULT)** | Absent (`0³²`) | `operator_set_root` open **growth-only** policy (R-09) | No | **No external observer** — Attack A Bitcoin-class / `D_mint` | **R-09** (cumulative S; join before first mint) | No gatekeeper. Effectively trustless in the sense of §1.1.1. Prefix residual is load-bearing. |
| **Gatekeeper-gated (Corner A)** | Present (`gatekeeper ≠ 0³²`) | R-09 + optional R-08 belt-and-suspenders | Yes (gatekeeper remit) | **Yes** — gatekeeper withholds `Pk_mint` until canonical `MoveToBacked` **and** `reg_root_E` confirmation (§3.2.1.1 / §4.1.2) | **R-09** (R-08 optional) | Gatekeeper online for new mints; integrity is an **Attack-A** backing-safety dependency, not Attack B |
| **Closed enumerated set (Corner B)** | Absent (`0³²`) | Genesis-enumerated set; distinct policy P′ | No | **No external observer** — Attack A Bitcoin-class / `D_mint` | Enumeration (not open join) | No gatekeeper; abandons open registration |
| **Open registration without R-09 (Corner C)** | Either | Per-epoch club that can omit honest operators | n/a | n/a | **Not closed** | **UNSOUND** — forbidden |

A gatekeeper adds mint-time liveness dependence in exchange for SoF screening **and** a clean Attack-A close (R-04). It is **not** required for Attack B and **MUST NOT** be described as what makes zkBTC trustless. A no-gatekeeper token with R-09 **is** the product default: no entry filter, no external canonical observer, Attack B closed cryptographically by growth-only S.

**Prominent claim (MUST state — §3.2.1.2; R-09).** zkBTC is **effectively trustless** as the self-operator profile (Corner D): you join S before the first mint, you refuse malicious graphs, operators cannot steal under the §5 conditions, and you can exit yourself. Open registration + pooled **without** R-09 is **Corner C / UNSOUND** and **MUST NOT** be presented as trust-minimized or as effectively trustless. A gatekeeper is **optional** (Corner A) for Attack A canonicity and SoF. **Corner B** abandons open join.

**Ship condition.** A zkBTC **MUST NOT** be shipped as open registration + pooled **without** R-09 (**Corner C** is **UNSOUND**). The product ships as **Corner D** (no gatekeeper + R-09). **Corner A** is the optional gated variant (R-09 + a designated gatekeeper). Both require R-09. The first-mint rule of R-09 item 6 **MUST** be implemented in wallets.

### 6.5 Competing deployments

Restatement of §2.5: because `gatekeeper` and `operator_set_root` (and `H(vault_template)`) are bound into `asset_id`, each combination is a distinct asset. Anyone can deploy a competing zkBTC with their own or no gatekeeper; wallets key by `asset_id`; adoption decides which wins.

### 6.6 Compliance surface summary

**REQ-3 rationale.** Optional gatekeeper approval at mint prevents (when designated) wash-in of tainted BTC while keeping issuance permissionless for minters, **and** supplies a clean Attack-A close (R-04). **Attack B is closed by R-09**, not by the gatekeeper. Minting economic activity and gatekeeping remain separate roles. The product default is Corner D (no-gatekeeper + R-09): effectively trustless self-operator (§1.1.1). Open registration + pooled **without** R-09 is **Corner C / UNSOUND**. A gatekeeper **MUST NOT** be marketed as required for operator-theft safety or Attack B.

**REQ-2 and REQ-4 are deliberate.** The gatekeeper **MUST NOT** be able to freeze or claw back circulating zkBTC, and **MUST NOT** be able to block a redemption. Flip side (state plainly): exits of later-sanctioned holders **cannot** be stopped either. Compliance that needs continuous transaction-level freeze would require a different product (not this one).

**What compliance retains (gatekeeper-gated assets):**

- **L1 surface:** every payout's `btc_recipient` is a public Bitcoin output; deposit provenance is screened at entry.
- **Entry refusal (with a stated depositor-side risk):** the gatekeeper may refuse new mints. If refusal is **before** `MoveToBacked`, the depositor reclaims via the deposit-taproot refund. If the gatekeeper (or an operator) fails **after** `MoveToBacked` has fired, the depositor's vaulted BTC becomes an irrevocable, consented contribution to the shared reserve — **not** refundable (§3.4 / §4.2 / §5 residual 8). The depositor's co-signature makes it consented, but that consent is given before the mint is known to complete: a gated-mode depositor **SHOULD** co-sign `MoveToBacked` only when ready to accept that contribution risk.

**What compliance does not get:**

- No transaction-level gatekeeper visibility inside the shielded zone (privacy holds for internal transfers).
- No gatekeeper veto on transfers or redemptions.

| Surface | Visible to gatekeeper / compliance function | Mechanism |
|---------|---------------------------------------------|-----------|
| Deposit UTXO | Yes (public Bitcoin) | L1 |
| Source-of-funds / KYC | Yes when gatekeeper process requires it (off-protocol) | Off-protocol |
| Mint recipient address | Bound in deposit commitment; mint goes only to that recipient | Clause (g) |
| Vault legitimacy | Gatekeeper vouch (gated) + in-circuit `operator_set_root` | §3.2 / §3.3(e) |
| Operator-set growth-only at mint | **R-09** (cumulative S; every new vault N-of-N over current S). Optional gated R-08 is belt-and-suspenders, not the close | §3.1.2 / §3.2.1.1 / R-09 |
| Canonical `MoveToBacked` + `reg_root_E` at mint | Gatekeeper's own canonical Bitcoin view (gated; withholds `Pk_mint` until both anchors confirmed) | §3.2.1.1 / §4.1.2 / R-04 |
| Internal transfers | No | Shielded parent specification.md §2 |
| Redeem request | No (unless gatekeeper is also chosen operator) | Off-chain to operators |
| Payout UTXO | Yes (public Bitcoin) | L1 |

### 6.7 Designed non-properties

State these so product and legal review do not invent protocol powers that do not exist:

1. **No freeze list** for circulating coins.
2. **No clawback** of settled mints or transfers.
3. **No gatekeeper signature** on redeem or payout.
4. **No selective mint redirect** after deposit (clause (g)).
5. **No in-place gatekeeper rotation** (new asset only).

---

## 7. What minters and the gatekeeper can and cannot do

### 7.1 Minter CAN

- **Deposit and request a mint** to a committed recipient (permissionless economic role).
- **Hold the minted coin** (or have it delivered to the committed recipient) and transfer freely (REQ-2).
- **Redeem** without gatekeeper cooperation (REQ-4).

### 7.2 Gatekeeper CAN (when designated)

- **Refuse / approve mints** at entry (source-of-funds + **R-04** canonical-chain confirmation + **R-09** superset; optional R-08 belt-and-suspenders).
- **See deposit provenance** on L1 and any off-protocol KYC data it requires.
- **Hold and manage `sk_gk`** under its key-management policy (including as a threshold aggregate).

**Key-management properties (normative analysis):**

- **Loss of `sk_gk`:** no **new** mints of this asset ever. Existing circulating supply and redemptions are **unaffected** (redemptions do not use `sk_gk`). For an **N-of-N** gatekeeper aggregate, loss of **any single** member key has the same permanent effect — threshold (t-of-n) is **RECOMMENDED** (§2.1).
- **Theft of `sk_gk`:** thief can approve mints for **future** deposits (derive `sk_mint`, settle TS3 mints). Clause (g) recipient binding still prevents redirecting already-committed deposits, and the thief **cannot** forge a vault spend, touch circulating coins, freeze, or block exit (REQ-4 intact). **When the thief performs R-04 honestly**, circuit deposit-backing clauses still require a real vault output of matching amount — the thief cannot mint against pure fiction or redirect committed recipients. **But a thief with `sk_gk` can skip R-04** and thereby **enable Attack A** (private-fork mint). Skipping optional R-08 does **not** reopen Attack B if R-09 holds. **Worst realistic abuse:** enabling Attack A, censorship / denial of service at entry, waving through tainted mints (reputation filter bypassed), and burning slots by blind-signing garbage (signing without checking inputs — §3.2.1.1).

### 7.3 CANNOT (gatekeeper and minter)

- **Mint without a fresh real `MoveToBacked` backing-only vault output** of matching amount under N-of-N and in-set `agg_key` — clauses (e), (f), (h).
- **Redirect a mint** — clause (g).
- **Mint twice per vault outpoint** — clause (f) + first-occurrence on `Pk_mint`.
- **Block transfers** — no gatekeeper/minter role in parent specification.md §2 holder transitions.
- **Block / censor redemptions** — no gatekeeper role in §4.3.
- **Inflate supply beyond the vault UTXO ceiling** — §3.6 conditional upper-bound auditability (**conditional on the reserve-safety assumptions of §5**: 1-of-N setup honesty + R-09 + no successful Attack A (R-04 only when gated) + ≥1 honest challenger; a successful **Attack A**, **Attack B**, **or** unchallenged fraudulent/duplicate reimbursement breaks it).
- **Seize the vault unilaterally** — no unilateral vault path; spends only along presigned graphs.
- **Substitute a self-controlled operator set under this asset** — recursive `operator_set_root` membership closes the *foreign-root* substitution; **R-09** closes **Attack B** (self-controlled *in-set* vault under the correct root) because every new vault is N-of-N over the cumulative S. Open registration **without** R-09 is **Corner C / UNSOUND** (§3.1.2 / §3.2.1.2 / §6.4).

---

## 8. Privacy implications

Port of BITVM_BRIDGE.md §9, specialised for TS3.

### 8.1 Peg-in observability

The user's deposit on Bitcoin L1 is visible. Observers of the vault see:

- deposit amount (denomination-quantised);
- funding addresses;
- vault-move timing;
- temporal correlation with the subsequent mint nullifier inscription (vaulted amounts are public on L1; exact mint↔deposit linkage for third parties still requires the mint proof or a published attestation ledger — §3.6).

This is a privacy regression versus a pure off-chain mint, and a privacy improvement versus holding L1 BTC for all subsequent activity (internal transfers are shielded).

### 8.2 Peg-out observability (honest — NH-04)

Symmetric: `btc_recipient` is a public P2TR output; temporal correlation of redeem nullifier time with payout time is observable. `redeem_commitment` keeps redemption **details** off the public ProofData opening — only the bridge sees openings until claim time.

**Indistinguishability bound (MUST state honestly).** A redeem transition is on-chain indistinguishable from any other transition **only until the operator's reimbursement claim marker appears**. The claim marker then links that redeem (`(Pkᵢ, Rᵢ)`) to its payout outpoint. Redemption correlates on-chain anyway (public payout); this is an **accepted privacy boundary**, not a failure of the hiding commitment. Redeem-branch amounts and openings remain **recursion-only** for the reimbursement circuit (§4.3.2 exposition note; §3.7.2) and **MUST NOT** appear as on-chain public inputs of `C`.

### 8.3 Internal transfers

Unaffected: global anonymity set of shielded multi-asset transfers; gatekeeper and operators learn nothing about non-bridged traffic beyond what separate hosting roles already expose.

### 8.4 Mitigations

- Fresh L1 addresses per deposit and per payout.
- Holder-side timing discretion between mint and first transfer, and between redeem and requesting payout.
- Optional coinjoin after payout.
- Hiding recipient commitment on deposit (already normative in §3.3(g)) so operators see commitment, not plaintext, until mint delivery.

**Analogy:** Zcash t-address / z-address model — transparent edges, shielded interior. zkCoins-with-bridge has **less** privacy than zkCoins-without-bridge (L1 touch points) but keeps private interior transfers.

---

## 9. Transitional profile (NOT zkBTC)

Until zkBTC's launch gates clear (§4.6 — the maturity/integration gates **and** the REQ-4 gates), an operator **MAY** run a custodial-window bridged BTC asset **today** under token standard 1 plus an operator service, following the lightning-bridge.md pattern:

- operator SLA for redemption (quote / burn-address or specification.md §5.6-link style proof of payment to a sink);
- mint policy matching observed L1 locks under operator honesty;
- no new wire protocol; ordinary sender/recipient roles.

### 9.1 Naming lock (normative)

Such an asset:

- **MUST** use its own asset name and `asset_id`;
- **MUST NOT** use the name **"zkBTC"**;
- **MUST** carry the banner: *does not meet REQ-4 — redemption is an operator SLA, supply is operator-attested*;
- **MUST NOT** promise migration into zkBTC (different asset, different lineage universe).

### 9.2 What the transitional profile lacks vs TS3

| Property | Transitional (TS1 + SLA) | zkBTC (TS3 + BitVM2) |
|----------|--------------------------|----------------------|
| Supply audit | Operator-attested; amounts unobservable | Conditional upper bound vs public vault UTXOs (**conditional on the reserve-safety assumptions of §5**: 1-of-N + R-09 + no successful Attack A (R-04 only when gated) + ≥1 honest challenger — broken by Attack A, Attack B, **or** unchallenged fraudulent reimbursement); exact via optional aggregate attestation (§3.6) |
| Mint bound to vault outpoint | Policy only | In-circuit LCP (N-of-N + deep finality + operator-set) + `Pk_mint` |
| Redeem | Operator SLA | Bridge claim keyed on `(Pkᵢ, Rᵢ)` |
| Gatekeeper on exit path | N/A (often SLA counterparty = operator) | No |
| Name | Must not be "zkBTC" | "zkBTC" reserved for this profile |
| Migration promise | Forbidden | N/A |

Discovery, if any, **SHOULD** use a distinct operator `features` flag (not the reserved zkBTC product name) and fail closed when absent — same spirit as lightning-bridge discovery.

---

## 10. Future upgrade paths

Three clearly labeled tracks. None is a launch dependency.

### 10.1 Efficiency upgrades (NOT soft-fork; 1-of-N structure family)

**BitVM3 / Mosaic / Argo** reduce on-chain dispute cost ~1000× relative to BitVM2 → **lower minimum denominations**, cheaper operator bonds, cheaper open registration. These preserve BitVM2's **permissionless challenge** structure and therefore the **same trust model** (only cheaper). Adopting them is a **verifier-trait swap + new vault graph (new epoch)**, not a token-standard change.

**Glock** also reduces dispute cost (~single-signature-scale disprove) but **reintroduces a designated-verifier challenge trade-off** — a genuine **trust-model change**, **not** "same trust model" as BitVM2. Unlike BitVM2 (and unlike BitVM3/Mosaic/Argo where they preserve open challenge), Glock's challenge is designated-verifier rather than permissionless (§4.1 role-note (a)). Adopt Glock **only** with that caveat explicitly acknowledged.

| Construction | Role | Sources |
|--------------|------|---------|
| Glock | Efficiency upgrade: ~single-signature-scale disprove; **designated-verifier trade-off** (trust-model change vs BitVM2) | eprint 2025/1485 |
| BitVM3 | Efficiency upgrade: dramatically cheaper disputes; permissionless challenge preserved | `bitvm.org/bitvm3.pdf`; eprint 2026/933 |
| Mosaic | Efficiency upgrade (Glock final piece class) | eprint 2026/812 |
| Argo | Related Ideal-Group / author-cluster research | eprint 2026/049 |

State plainly: these are **not** launch blockers. BitVM2 is the works-today normative verifier; efficiency upgrades land when mainnet-proven and economically beneficial — BitVM3/Mosaic/Argo as same-trust-model efficiency upgrades; Glock only with the designated-verifier caveat.

### 10.2 Covenant soft-fork upgrades (registration-free unilateral exit)

Covenant soft forks (OP_CTV / CSFS / OP_CAT class) would allow an anyone-can-satisfy exit script of the form "valid burn / redeem proof → fixed payout template," removing the operator-liveness residual **and** enabling **registration-free** self-reclaim by a passive holder who never registered. Alpen engineer analysis notes that without covenants, BitVM-style bridges remain operator-mediated via presigned graphs; with CAT+CTV-style tools, unilateral trustless withdraws become designable. None of these opcodes is activated on Bitcoin mainnet as of mid-2026; realistic timeline is multi-year and uncertain (bitcoinops covenant topics).

**Witness-encryption / PIPEs v2** is a research-only soft-fork-free theoretical path toward registration-free reclaim (not product-ready; eprint 2026/186).

**Design consequence now:** the redeem statement (§3.5) is construction-agnostic — a hiding commitment plus an anchored ID `(Pkᵢ, Rᵢ)` — so **both** upgrade tracks **MAY** consume the **same** statement without rewriting the token standard. This document does not promise activation dates or claim that covenants are near.

### 10.3 Reserve rotation across vault generations (informative)

This subsection is informative — an idea for how deployments and future versions could further reduce epoch-aging risk. It defines no requirement of this specification.

**Motivation.** Vault spend paths are pre-signed per deposit epoch at setup (§3.1.1, §4.1.2), and newly registered operators join only future epochs (§4.1.1). Backing that remains in old vault generations therefore accumulates operator-liveness / freeze risk over time (§4.1.1, §4.3, §5; no-council residual §4.5), while fresh generations carry current, more diverse operator sets.

**Stage 1 (soft).** Operators of older epochs, while still serviceable, could prefer the oldest live vaults as their reimbursement source when serving redemptions. Redemption traffic would then drain the oldest generations first, and the reserve would roll forward into fresher vault generations on its own. Independently, any holder or operator can roll backing forward explicitly by redeeming and having the serving operator reimburse from an old-epoch vault (or self-serving as that epoch's operator), then re-depositing into a current epoch (redeem-then-remint).

**Stage 2 (strict — a possible future version).** A future protocol or deployment version could go further and treat rotation into the newest vault generation as a condition of good standing: backing that has not rolled forward within some defined window would be considered degraded, and such a deployment could regard the asset's reserve quality as degraded for exit-liveness purposes — not a per-coin taint: coins remain one fungible asset with no provenance field (§4.1.1, §3.5.5) — surfaced, for example, through an extended published attestation (in the spirit of §3.6's optional ledgers) or through client policy rather than through the circuit.

**Honest limits.** Nothing in the present construction enforces rotation. Spend paths are fixed at setup, and rotation is executable only by the old epoch's own operators or by holders re-pegging. The on-chain cost of rolling, who bears it, and the staleness window are open calibration questions (see §11 item 8 — epoch rotation across deposit generations without an admin path).

---

## 11. Open questions

1. **Plonky2 → BitVM2 (Groth16/SNARK) conversion** of the zkCoins compliance predicate — **headline blocking integration gate**; needs engineering work against BitVM2/Clementine reference deployments.
2. **Global circuit-specific setup artifact in the conversion path?** Open point for launch gate A(2); verify against BitVM2 bridge materials and conversion work.
3. **Exact operator bond and challenge economics under BitVM2** once launch-pinned against live Clementine/Bitlayer economics (Clementine ~2 BTC bond class; BitVM2 multi-MB dispute cost ~$16k class).
4. **Challenger incentive/funding economics** under permissionless BitVM2 challenge (§4.6A(4)) — availability is delivered; funding remains an open item (Clementine self-funded-challenge gap as anti-pattern).
5. **Watchtower-count floor calibration** (current `PROVISIONAL` ≥ 3) together with sequencing-connector graph structure against one-shot weakness without a Payout Administrator.
6. **LCP checkpoint governance and `D_mint` / `S` calibration.** Proposal: the v2 circuit release **pins** the checkpoint, `D_mint`, and optional `S` (§3.7.2); advancing any is a circuit-parameter release (new digests), not a live governance function. There is **no** freshness window `W`.
7. **Denominations final set** after BitVM2 launch-pin economics (including whether/when 0.01 unlocks under §10.1 efficiency upgrades).
8. **Vault key / epoch rotation across deposit generations** without an admin path (new vault / new descriptor / new epoch registration / migration only; policy change = new `operator_set_root` = new asset).
9. **DoS on gatekeeper entry** (mass junk deposit/mint requests) — rate limits and fee policy are gatekeeper operational concerns, not circuit rules.
10. **Interaction with Lightning / Arkade swap layers.** Liquidity rails on top of circulating zkBTC; `ARKADE_INTEGRATION.md` and `LIGHTNING_ATOMIC_SWAP.md` remain unaffected complements (inventory swaps, not reserve proofs).
11. **Open-registration policy-P encoding (concrete bytes launch-pinned).** Semantic requirements for the open-registration policy root, **R-09 growth-only / superset `reg_root_E`**, bond class, admissibility predicate (anti-domination), KeyAgg+PoP, and Merkle/policy tree for membership proofs are specified in **§4.1.2** (with two-level admission normative in §3.1.2). Canonicity of `reg_root_E` is a **gatekeeper R-04 duty** when designated (not an in-circuit claim — same LCP limit as `MoveToBacked`); completeness of *new joiners* is a **liveness residual**; completeness of already-admitted keys is **safety** (Attack-B safety = R-09). Remaining open: concrete byte encoding / launch-pin of the policy tree, the superset proof, and registration-output scripts (frozen with v2 digests, NEW-03 style); bond **magnitude** calibration vs live economics overlaps item 12; in-place key-rotation encoding.
12. **Anti-domination bond calibration** — bond cost high enough that single-party ≥ half of S is economically irrational, without making open registration inaccessible (economic calibration; **R-09** is the Attack-B close — §3.1.2).
13. **Registration-window / epoch-cadence / setup-window parameters (calibration).** Semantic formation of `reg_root_E` (bond, PoP, Merkle commitment, KeyAgg, bounded restart rounds on exclusion **of not-yet-admitted joiners only**, two-level ceremony Level 1/2 — §4.1.2) is specified; concrete `reg_root_E` commitment encoding is launch-pinned. Canonicity of `reg_root_E` is a gatekeeper R-04 duty **when designated** (not in-circuit; Corner D leaves Attack A as Bitcoin-class / `D_mint`). Remaining open: registration-window length, epoch-cadence tuning, and setup-window deadline calibration against live BitVM2 ceremony re-presign cost.
14. **Redeem-side payout-canonicity enforcement.** Whether the BitVM2 disprove path can enforce a **most-work (cumulative-work)** comparison so that a deep private-fork "payout" loses to an honest challenger's heavier canonical chain (§4.3.2 clause 8 / §5 residual 11). Open until the Plonky2→BitVM2 conversion (G3) and external audit (G4) demonstrate it; until then the redeem-side canonicity bound is **unmechanized** (no external anchor exists on the redeem side by design — REQ-4).

---

## 12. References

### 12.1 zkCoins references

- specification.md (docs `develop` @ e3b5d04) — §1.7.8 v1 freeze; §2.1 compliance predicate; §3.1–3.2 nullifier and S2C; §5.6 confirmation links; §6.5 token standards  
  `https://github.com/zk-coins/docs/blob/develop/docs/specification.md`  
  (URL also in `bitvm-bridge-research.md`)
- lightning-bridge.md — operator-service pattern (in `zk-coins/docs`)
  `https://github.com/zk-coins/docs/blob/develop/docs/lightning-bridge.md`
- risks.md — bridge out of core scope; D-13 / D-16 / D-17 class boundaries (in `zk-coins/docs`)
  `https://github.com/zk-coins/docs/blob/develop/docs/risks.md`
- bitvm-bridge-research.md — June-2026 Glock decision (**historical**; superseded by works-today BitVM2 decision §4.0); **explicitly cited source** for the 430–550× figure, single 64-byte Schnorr fraud-proof form, Argo ePrint 2026/049, dispute-cost table (~35k–100k sats projected), Eagen/Linus author-cluster note, and the specification.md GitHub URL above  
  (in `zk-coins/research`: https://github.com/zk-coins/research/blob/develop/bitvm-bridge-research.md)
- BITVM_BRIDGE.md — May strategy draft (partially superseded)  
  (in `zk-coins/research`: https://github.com/zk-coins/research/blob/develop/zkcoins-design/BITVM_BRIDGE.md)
- BRIDGE_MVP.md — May engineering draft; §4 ProofTypes / SMTs superseded  
  (in `zk-coins/research`: https://github.com/zk-coins/research/blob/develop/zkcoins-design/BRIDGE_MVP.md)
- ARKADE_INTEGRATION.md — complementary liquidity rails  
  (in `zk-coins/research`: https://github.com/zk-coins/research/blob/develop/zkcoins-design/ARKADE_INTEGRATION.md)
- LIGHTNING_ATOMIC_SWAP.md — complementary liquidity rails  
  (in `zk-coins/research`: https://github.com/zk-coins/research/blob/develop/zkcoins-design/LIGHTNING_ATOMIC_SWAP.md)

### 12.2 BitVM2 / BitVM3 / Glock / Argo / Mosaic (primary + efficiency)

- BitVM2 bridge paper — `https://bitvm.org/bitvm_bridge.pdf`
- BitVM2 writeup — `https://bitvm.org/bitvm2`
- BitVM3 paper — `https://bitvm.org/bitvm3.pdf`
- BitVM3 ePrint — `https://eprint.iacr.org/2026/933`
- Glock paper (Eagen) — `https://eprint.iacr.org/2025/1485` (§10.1 efficiency upgrade)
- Mosaic paper — `https://eprint.iacr.org/2026/812` (§10.1)
- Argo paper — `https://eprint.iacr.org/2026/049` (§10.1)
- GOAT Network bitvm2-node (open registration) — `https://github.com/GOATNetwork/bitvm2-node`
- Fiamma operators docs (open co-signer subsets) — `https://docs.fiammalabs.io/` (operators)
- Bitlayer BitVM bridge mainnet note — blockworks BitVM implementation-stage coverage — `https://blockworks.com/news/bitvm-implementation-stage`
- Alpen Glock blog — `https://www.alpenlabs.io/blog/glock-verification-on-bitcoin`
- Alpen Mosaic blog — `https://www.alpenlabs.io/blog/introducing-mosaic-glocks-final-piece`
- Alpen Strata bridge (historical) — `https://www.alpenlabs.io/blog/introducing-the-strata-bridge`
- Alpen BitVM2 cost analysis — `https://www.alpenlabs.io/blog/state-of-snark-verification-with-bitvm2`
- Alpen 2025 overview — `https://www.alpenlabs.io/blog/inside-alpens-2025`
- Alpen bitcoin bridge docs — `https://docs.alpen.org/how-alpen-works/bitcoin-bridge.md`
- Alpen protocol administration / safeguards — `https://docs.alpen.org/how-alpen-works/protocol-administration-and-safeguards.md`
- Storopoli BitVM / covenants note — `https://storopoli.com/posts/2025-02-10-bitvm.html`
- strata-bridge repository — `https://github.com/alpenlabs/strata-bridge`
- alpen rollup repository — `https://github.com/alpenlabs/alpen`

### 12.3 Citrea / Clementine (primary reference deployment)

- Clementine trust-minimized bridge — `https://docs.citrea.xyz/essentials/clementine-trust-minimized-bitcoin-bridge.md`
- Using Clementine (10 BTC denomination) — `https://docs.citrea.xyz/essentials/using-clementine.md`
- Clementine signers — `https://docs.citrea.xyz/advanced/clementine-signers.md`
- Security council — `https://docs.citrea.xyz/advanced/security-council.md`
- Bridge system contract — `https://docs.citrea.xyz/developer-documentation/system-contracts/bridge.md`
- Clementine whitepaper PDF — `https://citrea.xyz/clementine_whitepaper.pdf`
- Clementine ePrint — `https://eprint.iacr.org/2025/776`
- Clementine repository — `https://github.com/chainwayxyz/clementine`
- Citrea introduction (mainnet since Jan 2026) — `https://docs.citrea.xyz/essentials/introduction.md`

### 12.4 Landscape sources (mechanism matrix)

- BitVM hub — `https://bitvm.org`
- tBTC v2 — `https://docs.threshold.network/tbtc-v2`
- Liquid federation — `https://liquid.net/federation`
- Liquid technical overview — `https://docs.liquid.net/docs/technical-overview`
- Stacks sBTC design — `https://stacks-network.github.io/stacks/sbtc.html`
- Stacks sBTC signers — `https://docs.stacks.co/learn/sbtc/sbtc-signers`
- Mercury Layer — `https://mercurylayer.com/`
- Arkade unilateral exit — `https://docs.arkadeos.com/learn/security/unilateral-exit`
- Arkade primer — `https://docs.arkadeos.com/primer`
- Covenant landscape commentary — `https://www.galaxy.com/insights/research/bitcoins-next-major-upgrade-op-cat-and-op-ctv`
- OP_CAT topic — `https://bitcoinops.org/en/topics/op_cat/`
- BIP-119 CTV — `https://github.com/bitcoin/bips/blob/master/bip-0119.mediawiki`
- PIPEs v2 (research-only) — eprint 2026/186 — `https://eprint.iacr.org/2026/186`

---

## 13. Change log

| Date | Change |
|------|--------|
| 2026-08-06 | Initial specification of token standard 3 (`issuance_version == 3`): the zkBTC in-circuit token standard plus its off-circuit bridge profile, superseding the earlier `BRIDGE_MVP.md` ProofType/SMT sketches and the `IssuanceTerms_v2_glock_bridged` naming. |
| 2026-08-06 | Normative construction fixed: backing-only vault with a NUMS internal key and an N-of-N pre-signed BitVM2 graph (no live CHECKSIG, no depositor or cooperative refund leaf on the vault); mint bound in-circuit to a confirmed `MoveToBacked` vault outpoint via a recursive light-client proof (N-of-N witness, deep-finality depth, recursive `operator_set_root` equality, one-shot `Pk_mint`, `amount == vault-output amount`); redemption as an ordinary holder transition with a hiding `redeem_commitment`, redeem ID `(Pkᵢ, Rᵢ)`, claim-marker uniqueness over the valid-unchallenged set, operator-funded payout under a holder-committed `max_fee` ceiling, and exact `redeem_amount` value preservation; supply framed as a conditional upper bound against the public vault set. |
| 2026-08-06 | Reserve construction set to BitVM2 (mainnet-proven; permissionless challenge) with open, permissionless, per-epoch operator registration; `operator_set_root` reframed as an open-registration policy commitment with two-level epoch admission (bond, proof-of-possession, MuSig2 key aggregation, bounded-restart ceremony); Glock / BitVM3 / Mosaic retained only as future efficiency upgrades, and covenant soft-forks as a separate registration-free-exit track. |
| 2026-08-06 | Trust model completed: two independent mint-settlement backing-drain attacks distinguished — private-fork mint settlement (closed by the gatekeeper canonical-chain anchor over both `MoveToBacked` and `reg_root_E`) and a Sybil-controlled operator epoch (closed by the gatekeeper operator-set-diversity vouch) — and the sound-deployment trilemma stated (recommended gatekeeper-gated open-registration pooled profile; materially-weaker closed-enumeration profile; unsound open-registration no-gatekeeper profile). Every load-bearing guarantee conditioned on 1-of-N setup honesty, an active honest challenger, and sound circuit/graph crypto; gatekeeper integrity documented as a backing-safety dependency; the post-`MoveToBacked` unminted deposit documented as a consented, irrevocable reserve contribution. |
| 2026-08-07 | Reworked the operator-reimbursement fairness rule to a **non-transferable, claimant-committed payout** — the payout transaction commits `(claiming operator's bonded key, redeem ID)`, uses SegWit-only inputs, and is signed `SIGHASH_ALL`, so only the committed operator can be reimbursed and the transaction is non-malleable — superseding three earlier formulations — net value-accounting, `SIGHASH_SINGLE` index-pairing, and a `SIGHASH_ALL`-only rule — each of which left a distinct claim-hijack path (fresh-address recoup, BIP-341 input relocation, and a co-signed multi-claimant free-ride with residual `txid` malleability); the exact attribution encoding is flagged as an external-audit (G4) focus; clarified key-deletion semantics (long-term signing capability, not merely nonces) and the epoch-wide pre-deletion window for reused aggregate keys; made the redeem-side payout-canonicity residual explicit and flagged its enforcement (most-work comparison in the BitVM2 disprove) as an open conversion/audit item — an unmechanized bound with no external anchor by design and scoped the two-attack decomposition to mint settlement; conditioned the top-line "no operator can steal" claims on sound circuit/graph crypto and the Corner-A "sound" verdict on an honest, correct gatekeeper; surfaced the depositor-side gatekeeper-refusal loss path and the burn-first servability cost; corrected two RFC-2119 negations at the launch gates; reconciled `D_mint`/`S` as circuit-pinned parameters; renamed the maturity gates (G1–G4) to avoid an ID collision; broadened the README limitations coverage and the security-disclosure scope. |
| 2026-08-07 | Documentation: added a plain-language "In plain terms" summary and a one-sentence statement of the safety assumptions to the README, and clarified in the README and §5 that the sub-50% hash-power assumption is Bitcoin's own inherited base assumption (a majority-hash-power attacker can reverse any recently confirmed Bitcoin transaction), mitigated by deep finality. |
| 2026-08-07 | Strengthened the operator-reimbursement rule with a **mechanized sole-funder** requirement — every payout input must be authorised by the claiming operator's registered identity, so a co-signed transaction funded by a second party is not claimable — replacing a behavioural "an honest operator will not co-sign" argument that a hiding identity commitment had weakened; and split the overloaded finding ID (the payout-funding rule is now **NEW-04**, distinct from the claim-marker uniqueness / slashed-marker exclusion **NEW-02**). |
| 2026-08-07 | Further hardened the reimbursement rule to require **single-party-authorised** inputs — each payout input must be spendable by the claiming operator's identity **alone**, so a jointly-signed (2-of-2 / multisig) input co-funded by a second party is not claimable — and, since Bitcoin exposes spending authority rather than economic provenance, restated the closure honestly as covering the **known** claim-hijack variants with the exact input-authorisation check flagged as a G4-audit focus. Also added the active-in-window-challenger condition to the §4.5 "worst case is freeze" statement, qualified the private-fork "very unlikely to succeed" phrasing near the 50% hash-power margin, and restored the NH-04 finding-ID tag on §8.2. |
| 2026-08-07 | Documentation: added a plain-language "How zkBTC is deployed" section to the README and a §2.6 deployment-and-packaging note to the specification — recording that the off-circuit half ships as a single operator Docker module bundling the bridge and the optional gatekeeper entry control, that on the zkCoins side it acts as an ordinary API client and on the Bitcoin side drives `bitcoind`, without using the operator-internal kernel RPC or touching the trustless core, and that packaging the two roles together is a deployment convenience that does not change the trust model — the gatekeeper stays the mint-time entry control and vault safety still rests on the 1-of-N basis, with the existing role and registration rules unchanged. Also switched the plain-language deposit-screening wording from "tainted coins" to neutral source / entry-criteria phrasing. |
| 2026-08-07 | Documentation (informative): added §10.3 on oldest-first reserve rotation across vault generations — soft preference for reimbursing from the oldest live vaults (plus explicit redeem-then-remint), and a possible future strict variant that would treat unrotated backing as degraded; explicitly non-normative; no launch dependency. |
| 2026-08-20 | **R-09:** operator set is a single **cumulative, growth-only** set S per asset (join permissionless, no leave, no kick after admission, in-place key rotation only under the old key, every new vault N-of-N over current S, first-mint rule). **Attack B is closed by R-09**, not by the gatekeeper's R-08 vouch. Product default is the **effectively-trustless self-operator** profile (Corner D — §1.1.1): you join S before the first mint, you refuse malicious graphs, operators cannot steal under the §5 conditions, you can exit yourself. Gatekeeper is optional (SoF + clean Attack-A close via R-04); **MUST NOT** be described as required for Attack B or as what makes zkBTC trustless. Corner C is redefined as open registration + pooled **without** R-09 (still UNSOUND). Prefix residual stated as load-bearing, not a footnote. Dead admitted operators freeze new mints; existing coins remain 1-of-N-exitable. Role table, §7 key-theft analysis, Appendix A (D2–D13) and Appendix B rows that still named R-08 as the Attack-B close or required a gatekeeper for pooled backing were aligned to R-09. NEW-01 split: S holds **identity keys** (never deleted); each epoch contributes **fresh epoch signing keys** bound by identity PoP, then those epoch secrets are deleted — so growth-only S does not freeze later epochs. Leftover "delete signing shares" / "KeyAgg of S_E" / "long-term signing capability" wording aligned to that split throughout §2.1, §3.1, §4, §5, §6.2, and Appendix B. |

---

## Appendix A — Normative checklist (D1–D13 coverage map)

| ID | Requirement | Section |
|----|-------------|---------|
| D1 | `IssuanceTerms_v3` complete (`gatekeeper`, `operator_set_root` as operator-registration **policy** root — **default open, growth-only (R-09)** §4.1.1; closed-enumeration alternative only for Corner B; `vault_template`, `instantiate(…, agg_key, epoch)` with NUMS internal key + ordered BitVM2 assert/challenge/disprove **pre-signed-graph** tapleaves (no live CHECKSIG; no depositor/cooperative vault refund leaf), terms_hash, asset_id preimage; denominations and `refund_timelock` **not** in terms) | §3.1, §3.1.1–§3.1.3, §4.4 |
| D2 | Mint-key derivation (`Pk_mint`; gatekeeper- vs depositor-base; MintKey domain; mod-n / even-y M-01) + mint consumes `Pk_mint` on **`MoveToBacked` vault** outpoint; gatekeeper verifies inputs **and own canonical Bitcoin view** then signs (not full proof); withholds until canonical `MoveToBacked` **and** `reg_root_E` (R-04 / Attack A). R-09 (Attack B) is enforced in-circuit / by policy; when designated the gatekeeper **MUST** also withhold if the R-09 superset check fails (belt, not the close) | §3.2, §3.2.1.1, §4.1.2 |
| D3 | In-circuit mint clauses (a)–(h) incl. LCP: `MoveToBacked` vault outpoint, N-of-N witness, `C_lcp.operator_set_root == IssuanceTerms_v3.operator_set_root` (policy-root equality; two-level admission; R-09 superset `reg_root_E`/`agg_key_E` formation §4.1.2 — in-circuit PoW-depth only; canonicity = gatekeeper R-04 when designated; completeness of new joiners = liveness residual; completeness of already-admitted keys = safety), depth ≥ `D_mint`, instance byte-equality; **no** host-side freshness / `tip_height` / `W`; emission without self-credit; depositor co-sign on `MoveToBacked` both modes (INV-01) | §3.3, §3.3.1–§3.3.2, §4.1.2 |
| D4 | Deep-finality + gatekeeper canonical-chain anchor for `MoveToBacked` **and** `reg_root_E` (R-04 / Attack A when designated) + **R-09** growth-only S (Attack B); no transitive downstream re-check; optional first-recipient SHOULD; consented irrevocable reserve contribution residual (INV-01) | §3.4, §4.2, §4.1.2 |
| D5 | Redeem: `redeem_commitment` incl. `max_fee < redeem_amount`, redeem ID `:= (Pkᵢ, Rᵢ)`, claim-marker uniqueness (logical first-marker on valid unchallenged set; slashed excluded; non-transferable, sole-funded claimant-committed payout (sole single-party funding + identity commitment + SegWit-only + `SIGHASH_ALL`)), value preservation (exactly `redeem_amount` from vault), payout ≥ `redeem_amount − max_fee` | §3.5, §4.3.2 |
| D6 | ProofData layout v2 (7 fields / **224 bytes**: six v1 + `redeem_commitment`; zero-sentinel for mint) + PI limbs + **`C_balance` re-pinned for v2** + `genesis_tag` + LCP pins (`D_mint`, optional `S`) + migration / coexistence | §3.5.2, §3.7, §3.7.2 |
| D7 | Bridge parameter table (`D_mint`, optional `S`, BitVM2 assert/challenge/disprove CSV, NUMS vault internal key, deposit-taproot-only refund, pre-signed `MoveToBacked` + backing-only vault, N-of-N presigning, watchtower floor, registration window / epoch cadence) vs Clementine / BitVM2 baselines | §4.4 |
| D8 | Roles (minter / optional gatekeeper / operators; vault presigning **MUST** N-of-N; FROST/threshold **MAY only for gatekeeper**; N-of-N gatekeeper loss warning) + sequencing connectors + launch gates (policy-P anti-domination + R-09, BitVM2 setup integrity, open registration onboarding, challenger economics) + gatekeeper mint duties when designated (SoF, R-04 covering `MoveToBacked`+`reg_root_E`; optional R-08) + gatekeeper integrity as Attack-A backing-safety dependency when designated (§6.3) | §2.1, §4.1, §4.1.1–§4.1.2, §4.6, §6 |
| D9 | Trust matrix + residual ≥1 **registered** operator + consented irrevocable contribution residual (INV-01) + sound-deployment profiles (Corner D product default / self-operator + R-09; Corner A gated; Corner B closed enumeration; Corner C **UNSOUND** = open + pooled **without** R-09) + efficiency/covenant upgrade paths + no-council consequence (graph-level one-shot close) + optional gatekeeper mint-time liveness + Attack-A canonicity | §5, §3.2.1.2, §4.5, §6, §10 |
| D10 | Transitional profile: own name/id, SLA shape, "does not meet REQ-4" banner, NEVER "zkBTC" | §9 |
| D11 | Gatekeeper model: optional; reputation + **canonical-chain anchor** (R-04 / Attack A: `MoveToBacked` + `reg_root_E`); **not** the Attack-B close (R-09 is); CANNOT table (no forge vault spend; no redirect; integrity = Attack-A backing-safety when designated; compromised-gk can enable Attack A, not Attack B under R-09), security-class honesty (Corner D product; Corner C **UNSOUND** without R-09), competing tokens | §6, §2.1, §2.5 |
| D12 | Operator-set legitimacy: `operator_set_root` as open **growth-only** registration **policy** in asset_id (R-09 default; closed-enumeration alternative only for Corner B); identity vs §4.4 scheduling split; recursive LCP policy-root equality (not bare boolean); two-level epoch admission + R-09 superset; `reg_root_E` canonicity = R-04 not in-circuit when gated; Attack A (R-04) vs Attack B (R-09); cross-graph redeem draws in-set vaults only; first-mint / prefix residual; conditional supply ceiling under the reserve-safety assumptions of §5 (1-of-N + R-09 + no successful Attack A (R-04 only when gated) + ≥1 honest challenger; broken by Attack A, Attack B, **or** unchallenged fraudulent reimbursement) (§3.6) | §3.1.2, §3.3(e), §3.3.1, §3.6, §4.1.2, §4.3 |
| D13 | Open operator registration market: permissionless join into cumulative S (R-09), bond/PoP/`reg_root_E`/MuSig2 KeyAgg/bounded restart rounds (exclusion only of not-yet-admitted joiners; per-round deadline ≠ setup window) + two-level ceremony (§4.1.2), be-your-own-exit-agent scoped to EXIT and Attack B, registration-free-reclaim residual → §10.2, first-mint rule §1.1.1 | §4.1.1, §4.1.2, §1.1.1, §1.2, §4.3.1 |

## Appendix B — Supersession detail

| Prior sketch | Problem | Replacement |
|--------------|---------|-------------|
| Separate `IssuanceProof` / `BurnProof` ProofTypes | Violates single-circuit `C` (parent specification.md §2.2); conflicts with specification.md §6.5 version-branch dispatch | TS3 mint / redeem as branches of `C` on v2 surface |
| Global `peg_in_consumed_smt` / `burned_coins_smt` | New consensus objects; incompatible with post-#97 model | Per-deposit `Pk_mint` first-occurrence; redeem ID = `(Pkᵢ, Rᵢ)` |
| `IssuanceTerms_v2_glock_bridged` (issuer-less, version 2) | `issuance_version == 2` is capped-supply; incomplete legitimacy | `IssuanceTerms_v3` with optional gatekeeper + `operator_set_root` + `vault_template` binding |
| Single mandatory issuer (`issuer_pubkey` / REQ-3 monopoly) | Central party; conflates economic mint with quality control | Optional gatekeeper + permissionless minter; `Pk_mint` mode-dependent |
| Federation V0 / BitVM2 intermediate | Superseded by June-2026 Glock decision (historical) | Works-today BitVM2 normative path (§4.0) + integration gate |
| **Glock as normative verifier (not mainnet)** | Not mainnet-proven; designated-verifier challenge | **BitVM2 (mainnet-proven); Glock demoted to §10.1 efficiency upgrade** |
| **`operator_set_root` as fixed key-list / genesis enumeration** | Closed club; not open-operator | Open-registration policy root **by default (product profile)**; closed genesis-enumeration retained as a distinct non-default **Corner-B** policy P′ (materially weaker, no-gatekeeper — §3.1.2) |
| **Permissionless challenging as open dependency (designated-verifier Glock)** | Not available under Glock | **Delivered BitVM2 property (§4.1 role-note (a))** |
| Denominations / `refund_timelock` frozen in asset terms | Economics depend on unaudited projections; asset_id freeze | Bridge-side epoch parameters; start set {0.1, 1, 10}; `refund_timelock` out of terms |
| Fixed `vault_descriptor` in `asset_id` | Circular if asset-bound; cross-asset double-backing if shared | `H(vault_template)` + `instantiate(vault_template, asset_id, agg_key, epoch)` |
| Shallow LCP on user deposit outpoint | Historical inclusion ≠ current vault backing; private-fork refund forgeries | `MoveToBacked` vault outpoint + N-of-N + operator-set + depth ≥ `D_mint` |
| Host-side freshness / mint-window CSV race | Unconstructible mint↔vault co-transition; TOCTOU; tip sentinel ambiguity | Invert: mint proves `MoveToBacked` in-circuit; remove `tip_height`/`W`/`h_inscr`; BitVM2 assert/challenge/disprove CSV only (R-01/R-04 invert; NEW-HOLE-01) |
| `agg_key` as vault internal key | Key-path spend bypasses all CSV locks | NUMS internal key; all spends via CSV-locked pre-signed-graph tapleaves (NUMS / no key-path) |
| Live `agg_key` CHECKSIG leaf on vault | Coalition signs arbitrary vault spend; bypasses fraud statement / connectors; breaks 1-of-N | Pre-signed-graph-only vault spends; setup signatures then **epoch secrets** deleted (identity keys stay); no live CHECKSIG (NEW-01) |
| `t < N` vault presigning set | One honest **epoch-secret** deletion leaves `N−1 ≥ t` **epoch** shares able to sign; breaks 1-of-N | Vault presigning **MUST** be N-of-N; epoch signing secrets deleted, identity keys stay (NEW-01); threshold only for gatekeeper |
| Depositor / cooperative refund leaf on vault output | `refund_timelock` matures before mint depth; mint-then-refund destroys backing | Refund only on deposit taproot; extinguished by `MoveToBacked`; post-`MoveToBacked` unminted → **irrevocable consented reserve contribution** (INV-01 / R-01) |
| LCP-only canonicity without external observer | Private-fork `MoveToBacked` + mint + canonical refund amortises unbacked supply | Gatekeeper withholds `Pk_mint` until own **canonical Bitcoin view** confirms `MoveToBacked` **and** `reg_root_E` (R-04 extended, gated); without a gatekeeper Attack A is Bitcoin-class / `D_mint`. Open-reg + pooled **without R-09** = **Corner C UNSOUND** (§3.2.1.2) |
| Gatekeeper-only co-sign on `MoveToBacked` | MoveToBacked without depositor consent → unconsented contribution to shared reserve | Depositor co-sign **both modes** (INV-01); gatekeeper co-sign additional in gated mode |
| Bare `operator_set_member_ok` boolean | Attacker proves membership under attacker root | `C_lcp` exposes `operator_set_root`; outer `C` checks equality with asset root (R-02) |
| "Verify full mint proof before signing" | Circular (proof embeds signature) | Gatekeeper verifies inputs, signs, then proof is built (R-03) |
| Literal "consume payout UTXO" | Operator has no key on recipient P2TR | Logical claim-marker first-occurrence on `(Pkᵢ, Rᵢ, payout_txid, payout_vout)` (R-05) |
| Any claim-marker (incl. slashed) blocks uniqueness | Malicious poison-marker freezes honest redeem | Only valid unchallenged markers consume uniqueness; slashed/failed excluded (NEW-02) |
| Claim hijack: append/relocate/duplicate (BIP-341), residual `txid` malleability, or co-signed multi-claimant free-ride | `SIGHASH_SINGLE\|ANYONECANPAY` is malleable; even `SIGHASH_ALL` alone leaves a co-signed multi-operator tx claimable by a zero-net funder, and a legacy co-input can mutate `txid` | **Non-transferable claimant-committed sole-funded payout**: commit `(claimant identity, redeem ID)` in the payout tx; **every** input authorised by the claimant's registered identity (sole funder); SegWit-only inputs; `SIGHASH_ALL`; only the committed sole-funding operator claims. Gross/net/index-pairing all superseded (NEW-04; G4-audit focus) |
| "Sort by tapleaf_hash" as full tree pin | BIP-341 sorts only sibling pairs; tree shape underdetermined; NUMS deferred | Fixed leaf order key + left-complete balanced tree-shape rule + pinned NUMS derivation; connector bytes launch-pinned (NEW-03) |
| `C_balance` "unchanged" under v2 `C` | Recursive verifier data embeds `C`; digest must change | Both `C` and `C_balance` re-pinned for v2 (M-02) |
| Exact aggregate supply from chain data | Vaulted-unminted / slot-burn indistinguishable | Upper bound only; optional aggregate attestation (M-04) |
| Reimbursement without value preservation / payout bind | Vault drain or historical payout replay | Exactly `redeem_amount` from vault; claim-marker on payout `(txid,vout)`; `max_fee < redeem_amount` (NH-01..03) |
| Watchtower floor alone (no PA) | One-shot exhaustion across sequential claims | Per-operator sequencing connectors + floor over operators |
| Self-controlled N-of-N under permissionless mint | 1-of-N honesty vacuous; unbacked cross-graph redeem | `operator_set_root` policy bound in `asset_id` + recursive `C_lcp.operator_set_root` equality (foreign-root) + anti-domination + **R-09** growth-only S (Attack B — §3.1.2) |
| two-level admission asserted but registration mechanism undefined | In-circuit checks reference `reg_root_E`/`agg_key_E` without formation rules | §4.1.2 registration/bond/PoP/KeyAgg/ceremony spec |
| R-04 conflated with self-controlled-vault drain | Private-fork canonicity mis-credited for Sybil-epoch drain | **R-09** growth-only S closes Attack B; R-04 is Attack A only |
| no-gatekeeper open-registration pooled cross-graph treated as merely weaker | Understated residual; economic bond alone insufficient | **without R-09** stated **unsound** (Attack B / Corner C); **with R-09** it is the product default (Corner D — §3.2.1.2) |
| trilemma Corner B (no-gk closed set) mislabeled 'sound' → Attack A operator-oracle-only; retired claim that no clean no-gatekeeper pooled profile exists | Closing/enumerating the operator set closes Attack B only, not Attack A; the retired claim that pooled backing **requires** a gatekeeper for both attacks is itself superseded by R-09 | Corner B = closed enumeration, not the product; two-attack decomposition (A = R-04; B = **R-09**); product default = Corner D (no-gk + R-09); §3.2.1.2 / §5 / §6.4 |
| `reg_root_E` in-circuit canonicity claim | Contradicted §3.4 (LCP cannot prove canonicity); completeness mis-framed as safety | Gatekeeper-anchored canonicity when designated (R-04 covers `MoveToBacked` **and** `reg_root_E`); completeness of new joiners = liveness residual; completeness of already-admitted keys = safety; Attack-B safety = R-09 (§4.1.2) |
| no-gatekeeper same-epoch reimbursement escape | Unconstructible (`redeem_commitment` has no epoch field; vault-outpoint binding ruled out §3.5.5) and insufficient without R-09 (multi-vault Sybil epoch still cross-graph vulnerable) | R-09 closes Attack B without provenance; first-mint / prefix residual is load-bearing; Corner D = product; Corner C = without R-09, UNSOUND (§3.2.1.2) |
| ceremony exclusion silently reused old partials | Exclusion changes `agg_key_E` (KeyAgg over reduced set); old MuSig2 nonces/partials/graph artifacts invalid; "completes over subset" overclaimed | Bounded restart rounds within setup window (per-round deadline ≠ setup window) + two-level ceremony (Level 1 epoch-set / Level 2 per-deposit); Level-1 griefing of a **not-yet-admitted joiner** → slash-and-restart; one-off Level-2 → deposit-taproot refund; systematic Level-2 by a joiner → Level-1 exclusion of that joiner; systematic Level-2 by an **admitted** operator → slash / mint-liveness freeze, **not** leave |
| compromised gatekeeper "never steal" overclaim | Same breath admitted Attack B re-open (backing drain) yet claimed never-steal | Under R-09, skipping R-08 does **not** reopen Attack B; integrity when designated is **Attack-A backing-safety**; still cannot forge vault spend, freeze, or block exit (REQ-4) |
| supply ceiling conditioned only on Attack A/B → also conditional on ≥1 honest challenger (unchallenged fraudulent reimbursement is a third counterexample) — §3.6/§5 | Incomplete ceiling residual | Ceiling holds under §5 reserve-safety (1-of-N + R-09 + no successful Attack A (R-04 only when gated) + ≥1 honest challenger); broken by Attack A, Attack B, **or** unchallenged fraudulent/duplicate reimbursement |
| 'operators cannot steal' stated unconditionally at ~9 sites → conditioned on ≥1 honest live challenger acting in-window (availability of permissionless challenge ≠ guaranteed action); consistent with §3.6 third drain vector and §5 residual | Unconditional 'cannot steal' / 'never theft' restatements overclaimed relative to BitVM2 optimistic model | Conditioned on 1-of-N + ≥1 honest live challenger acting in-window (§5 residual 3); availability-≠-action stated once (§4.1 role-note (a)); honest-gatekeeper qualifier on §2.2/§6.3 forge/mint-unbacked rows |
| 'critical bug → only freeze/burn, not theft' stated unconditionally (§4.5) | Conflated a non-soundness bug's freeze/burn outcome with a circuit/graph soundness bug's theft risk; contradicted §5 'sound BitVM2 crypto' condition | Split by bug class: non-soundness bug = freeze/burn under 1-of-N + sound crypto; circuit/graph **soundness** bug can enable theft (§5 sound-crypto condition); pre-mainnet audit gate (§4.6) addresses (a standing assumption remains — §5) the soundness class |

---

*End of design specification. No code. Not a production launch until the §4.6A REQ-4 gates and §4.6B maturity/integration gates clear (three gates: Plonky2→BitVM2 conversion, open-registration market instantiation, and external circuit/graph audit); the verifier itself is mainnet-proven.*
