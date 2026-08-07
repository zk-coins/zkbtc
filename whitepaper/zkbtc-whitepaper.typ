// zkBTC: Private Electronic Cash Backed by Bitcoin
// Structural homage to Satoshi Nakamoto, Bitcoin (2008).
// Built-ins only; no imports.

#set document(
  title: "zkBTC: Private Electronic Cash Backed by Bitcoin",
  author: "TaprootFreak",
)
#set page(
  paper: "us-letter",
  margin: (x: 1in, y: 1in),
  numbering: "1",
  number-align: center,
)
#set par(
  justify: true,
  leading: 0.65em,
  first-line-indent: 1em,
  spacing: 0.65em,
)
#set text(font: "New Computer Modern", size: 11pt, lang: "en")

// Headings: numbered "1. Title", bold ~13pt (Bitcoin-paper style)
#set heading(numbering: "1.")
#show heading.where(level: 1): it => block(above: 1.4em, below: 0.6em)[
  #set text(weight: "bold", size: 13pt)
  #if it.numbering != none [#counter(heading).display(it.numbering)#h(0.6em)]#it.body
]

#let fig-label(body) = text(size: 7pt, body)
#let fig-label-sm(body) = text(size: 6.5pt, body)

// ONE reusable arrow: line + filled polygon head (built-ins only).
// Coordinates are lengths in the enclosing block's place-space.
// Tip is forced to (x1,y1) by shifting the polygon so place's top-left layout
// still lands the geometric tip on the intended point.
#let arrow(x0, y0, x1, y1, stroke: 0.6pt) = {
  place(line(start: (x0, y0), end: (x1, y1), stroke: stroke))
  let dx = (x1 - x0) / 1pt
  let dy = (y1 - y0) / 1pt
  let len = calc.sqrt(dx * dx + dy * dy)
  if len > 0 {
    let ux = dx / len
    let uy = dy / len
    let px = -uy
    let py = ux
    let hl = 6.0
    let hs = 3.5
    // Tip at local (0,0); base corners back along -u
    let t0x = 0.0
    let t0y = 0.0
    let t1x = -hl * ux + hs * px
    let t1y = -hl * uy + hs * py
    let t2x = -hl * ux - hs * px
    let t2y = -hl * uy - hs * py
    let minx = calc.min(t0x, t1x, t2x)
    let miny = calc.min(t0y, t1y, t2y)
    place(
      dx: x1 + minx * 1pt,
      dy: y1 + miny * 1pt,
      polygon(
        fill: black,
        ((t0x - minx) * 1pt, (t0y - miny) * 1pt),
        ((t1x - minx) * 1pt, (t1y - miny) * 1pt),
        ((t2x - minx) * 1pt, (t2y - miny) * 1pt),
      ),
    )
  }
}

#let dline(x0, y0, x1, y1, stroke: 0.5pt) = {
  place(line(
    start: (x0, y0),
    end: (x1, y1),
    stroke: (paint: black, thickness: stroke, dash: "dashed"),
  ))
}

#let fbox(w, h, body) = {
  box(
    width: w,
    height: h,
    stroke: 0.6pt,
    inset: 3pt,
    align(center + horizon, text(size: 7pt, body)),
  )
}

// ============================================================================
// Title block
// ============================================================================
#align(center)[
  #v(0.25em)
  #text(size: 17.5pt, weight: "bold")[
    zkBTC: Private Electronic Cash Backed by Bitcoin
  ]
  #v(0.8em)
  #text(size: 11pt)[TaprootFreak]
  #v(0.3em)
  #text(size: 11pt)[www.zkcoins.com]
]

#v(1.0em)

// Abstract — indented block, bold lead-in (Bitcoin-paper style)
#pad(x: 0.75in)[
  #set par(first-line-indent: 0pt, justify: true, leading: 0.62em)
  #text(weight: "bold")[Abstract.]
  #h(0.4em)
  A purely peer-to-peer version of private electronic cash backed by bitcoin
  would allow payments to be sent without revealing amounts or the transaction
  graph and without a custodian. Digital signatures and zero-knowledge validity
  proofs provide part of the solution, but the main benefits are lost if a
  trusted party is still required to order transactions or to hold the backing
  bitcoin. We propose a system for private electronic cash that uses Bitcoin
  itself only as an ordering layer. zkCoins is a client-side-validated transfer
  protocol: each state transition carries a recursive validity proof, and the
  only on-chain footprint is a constant-size nullifier of 64 bytes that prevents
  double-spending without a global ledger of amounts. zkBTC is a one-to-one
  bitcoin-backed token on that protocol. Its reserve is held in vaults spendable
  only along pre-signed BitVM2 fraud-proof paths, mintable under an optional
  per-asset gatekeeper and redeemable by any holder as long as one of an open,
  permissionless set of operators is live. Under the stated honesty and liveness
  assumptions (one-of-N setup honesty, at least one honest live challenger
  acting within each challenge window, and sound circuit and graph cryptography),
  no operator can steal the reserve.
]

#v(0.5em)

// ============================================================================
// 1. Introduction
// ============================================================================
= Introduction

Internet commerce still settles through financial institutions acting as trusted
third parties. Bitcoin removed that trust for settlement, yet every payment on
its ledger broadcasts the payer, the payee, and the amount to the world.
Confidentiality is routinely required for ordinary commerce; the accepted
remedies give up what makes Bitcoin valuable.
Separate privacy chains replace Bitcoin's security model with a new one.
Custodial or federated wrapped tokens reintroduce exactly the trusted third
party Bitcoin removed.

What is needed is an electronic cash system that keeps Bitcoin as the only
settlement layer and the only backing asset, hides amounts and the transaction
graph cryptographically, and lets any holder exit back to on-chain bitcoin
without anyone's permission. This paper proposes such a system. zkCoins is a
client-side-validated transfer protocol whose only on-chain footprint is a
constant 64 bytes per transaction. zkBTC is a bitcoin-backed token on that
protocol whose reserve is secured by fraud proofs rather than custody. The
system is secure as long as the following assumptions hold: honest majority
hashpower for Bitcoin's ordering of nullifiers; for the reserve, one honest
operator per backing group at setup (key deletion), at least one honest live
challenger acting within each challenge window, sound proof-system and BitVM2
graph cryptography; and, where an asset designates one, an honest gatekeeper at
mint time.

// ============================================================================
// 2. Transactions
// ============================================================================
= Transactions

We define an electronic coin as a chain of proof-carrying account-state
transitions. Each account is a sequence of states. Each transition (send,
receive, mint, or redeem) carries a zero-knowledge proof that it follows the
protocol rules given its predecessor, and a BIP-340 signature by the account's
current signing key. The recipient verifies the proof. Verification is
client-side: nobody else needs to see amounts or parties. The payee verifies
the chain of proofs the way a Bitcoin payee verifies the chain of signatures.

The problem is that the payee cannot tell that the payer did not create a
second, conflicting transition of the same account state. A central mint could
order transitions, but then the whole money system depends on that mint, and
the privacy and exit properties collapse back into custody. We need the payee
to know that no earlier conflicting transition exists. For that there must be
a single agreed history of transition markers, publicly announced, without
revealing the amounts or parties those markers stand for. For zkBTC the first
transition of a coin is a mint bound to an on-chain vault deposit (Section 11)
and the last is a redeem that burns it; between the two, transfers are ordinary
zkCoins transitions, and the backing never moves. The lifecycle is therefore
mint, transfer, redeem: only the endpoints touch the reserve, and every internal
step stays off the Bitcoin ledger except for its nullifier marker.

#v(0.35em)
// FIG-1: three Transition boxes (compact)
#align(center)[
  #block(width: 6.3in, height: 1.7in, {
    let bw = 1.55in
    let bh = 0.78in
    let gap = 0.42in
    let x0 = 0.15in
    let x1 = x0 + bw + gap
    let x2 = x1 + bw + gap
    let y = 0.02in
    place(dx: x0, dy: y, fbox(bw, bh)[
      Transition \
      Account State $i-1$ \
      Proof $pi_(i-1)$ \
      Owner's Signature
    ])
    place(dx: x1, dy: y, fbox(bw, bh)[
      Transition \
      Account State $i$ \
      Proof $pi_i$ \
      Owner's Signature
    ])
    place(dx: x2, dy: y, fbox(bw, bh)[
      Transition \
      Account State $i+1$ \
      Proof $pi_(i+1)$ \
      Owner's Signature
    ])
    let midy = y + bh / 2
    dline(x0 + bw, midy, x1, midy)
    place(dx: x0 + bw + 0.06in, dy: midy - 9pt, fig-label-sm[Verify])
    dline(x1 + bw, midy, x2, midy)
    place(dx: x1 + bw + 0.06in, dy: midy - 9pt, fig-label-sm[Verify])
    let ky = y + bh + 0.28in
    let kw = 1.15in
    let kh = 0.30in
    let kx0 = x0 + (bw - kw) / 2
    let kx1 = x1 + (bw - kw) / 2
    let kx2 = x2 + (bw - kw) / 2
    place(dx: kx0, dy: ky, fbox(kw, kh)[Account Key])
    place(dx: kx1, dy: ky, fbox(kw, kh)[Account Key])
    place(dx: kx2, dy: ky, fbox(kw, kh)[Account Key])
    arrow(kx0 + kw / 2, ky, x0 + bw / 2, y + bh)
    place(dx: kx0 + kw / 2 + 4pt, dy: ky - 0.22in, fig-label-sm[Sign])
    arrow(kx1 + kw / 2, ky, x1 + bw / 2, y + bh)
    place(dx: kx1 + kw / 2 + 4pt, dy: ky - 0.22in, fig-label-sm[Sign])
    arrow(kx2 + kw / 2, ky, x2 + bw / 2, y + bh)
    place(dx: kx2 + kw / 2 + 4pt, dy: ky - 0.22in, fig-label-sm[Sign])
  })
]
#v(0.08em)
// ============================================================================
// 3. The Nullifier Chain
// ============================================================================
= The Nullifier Chain

The solution begins with Bitcoin itself as the ordering layer. Bitcoin is the
timestamp server. Every state-advancing transition publishes a constant-size
nullifier (a pair $(upright("Pk")_i, R_i)$, an account-key-derived public key
and a signature nonce commitment, 64 bytes) into Bitcoin blocks via
inscriptions, half-aggregated per batch. The nullifier reveals nothing about
amounts, parties, or the transaction graph; it is meaningful only to those who
already hold the coin's history. The first occurrence of a given key
$upright("Pk")_i$ on the chain is the one that counts. A second conflicting
transition of the same state hits the same key and is rejected by every
verifier. In-circuit predecessor-anchoring makes each transition prove that its
predecessor's nullifier is already on-chain, so no off-chain fork can survive.
Half-aggregation lets a publisher combine many transitions' nullifier signatures
into a single inscription that carries one shared aggregate scalar, so the
on-chain cost per transition stays at the 64-byte pair even when a batch holds
many markers.

#v(0.35em)
// FIG-2: two Bitcoin Block boxes chained; nullifiers as small bordered boxes
#align(center)[
  #block(width: 5.4in, height: 1.55in, {
    let bw = 1.9in
    let bh = 0.92in
    let x0 = 0.35in
    let x1 = 3.0in
    let y = 0.08in
    place(dx: x0 + 0.35in, dy: y, fbox(1.2in, 0.26in)[Inscription Hash])
    place(dx: x1 + 0.35in, dy: y, fbox(1.2in, 0.26in)[Inscription Hash])
    // Outer Bitcoin Block frames
    place(dx: x0, dy: y + 0.30in, box(width: bw, height: bh, stroke: 0.6pt))
    place(dx: x1, dy: y + 0.30in, box(width: bw, height: bh, stroke: 0.6pt))
    place(dx: x0, dy: y + 0.34in, box(
      width: bw, height: 0.22in,
      align(center + horizon, text(size: 7pt)[Bitcoin Block]),
    ))
    place(dx: x1, dy: y + 0.34in, box(
      width: bw, height: 0.22in,
      align(center + horizon, text(size: 7pt)[Bitcoin Block]),
    ))
    // Inner Nf boxes + trailing "..."
    let nfw = 0.32in
    let nfh = 0.28in
    let nfy = y + 0.62in
    let nf-gap = 0.06in
    for blk-x in (x0, x1) {
      let nfx0 = blk-x + 0.12in
      for i in range(4) {
        let nx = nfx0 + i * (nfw + nf-gap)
        place(dx: nx, dy: nfy, box(
          width: nfw, height: nfh, stroke: 0.5pt, inset: 1pt,
          align(center + horizon, text(size: 6.5pt)[Nf]),
        ))
      }
      place(
        dx: nfx0 + 4 * (nfw + nf-gap),
        dy: nfy + 0.04in,
        text(size: 7pt)[...],
      )
    }
    arrow(x0 + bw, y + 0.30in + bh / 2, x1, y + 0.30in + bh / 2)
  })
]
#v(0.08em)
// ============================================================================
// 4. Validity Proofs
// ============================================================================
= Validity Proofs

Where Bitcoin enforces rules with proof-of-work, zkCoins enforces them with
zero-knowledge validity proofs. One compliance predicate $C$ (a single circuit)
checks every transition: per-asset value conservation (wide-sum, overflow-safe,
so no transition creates value), authorization by the account key, correct
predecessor state, one-time use of each coin, and the anchoring of everything the verifier
cannot see into hiding commitments. Proofs compose recursively (proof-carrying
data): verifying the latest proof verifies the entire history back to genesis,
so verification cost is constant regardless of history length. Forging a coin
means breaking the proof system, not out-computing the network. The circuit is
fixed and its digest pinned: everyone verifies against the same predicate, like
every Bitcoin node checks the same proof-of-work target.

#v(0.35em)
// FIG-3: two chained proof boxes with inner stacked fields (Bitcoin-paper style)
#align(center)[
  #block(width: 5.6in, height: 1.15in, {
    let bw = 2.0in
    let bh = 0.88in
    let x0 = 0.4in
    let x1 = 3.2in
    let y = 0.10in
    let ih = 0.36in
    let inset = 0.08in
    let iw = bw - 2 * inset
    // Outer frames
    place(dx: x0, dy: y, box(width: bw, height: bh, stroke: 0.6pt))
    place(dx: x1, dy: y, box(width: bw, height: bh, stroke: 0.6pt))
    // Inner fields: top π|C, bottom state transition
    place(dx: x0 + inset, dy: y + 0.08in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[$pi_(i-1)$ | $C$]),
    ))
    place(dx: x0 + inset, dy: y + 0.08in + ih + 0.04in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[state transition]),
    ))
    place(dx: x1 + inset, dy: y + 0.08in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[$pi_i$ | $C$]),
    ))
    place(dx: x1 + inset, dy: y + 0.08in + ih + 0.04in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[state transition]),
    ))
    arrow(x0 + bw, y + bh / 2, x1, y + bh / 2)
    place(dx: x0 + bw + 0.1in, dy: y + bh / 2 - 12pt, fig-label-sm[recurse])
  })
]
#v(0.08em)
// ============================================================================
// 5. Network
// ============================================================================
= Network

The steps to run the network are as follows:

#set par(first-line-indent: 0pt)
#enum(
  numbering: "1)",
  tight: true,
  [The sender builds a state transition and its validity proof, and sends the
    coin proof directly to the recipient off-chain (gift-wrapped, NIP-17 style
    transport).],
  [The sender submits its nullifier to a publisher.],
  [Publishers batch nullifiers and inscribe the batch into a Bitcoin block,
    paying on-chain fees.],
  [Bitcoin orders the inscriptions with proof-of-work.],
  [Recipients (their nodes) scan blocks and accept a transition only if its
    nullifier's first occurrence matches.],
  [Wallets extend their account chains on top of anchored transitions.],
)
#set par(first-line-indent: 1em)

Nodes always consider the Bitcoin chain with the most cumulative proof-of-work
to be the correct one. Reorganizations follow Bitcoin's own longest-chain rule:
a transition buried deeper than the finality depth is settled. If two
inscriptions of the same key appear, only the first occurrence in the canonical
chain is admitted; the later is a double-spend and is rejected.

Publishers are permissionless and interchangeable. Anyone can self-publish.
New nullifier announcements are tolerant of delayed broadcast: a recipient who
misses a batch can still verify later against the chain. A nullifier does not
need to reach every publisher; one inclusion in any batch that confirms is
enough, and a sender who distrusts all publishers inscribes it itself. No
publisher can steal: they never touch coins, only 64-byte markers. Censoring a
specific user costs fees lost to a competitor. Forging is out of reach: the
markers carry no spendable value, and validity is enforced by the proofs the
recipient checks. Ties between Bitcoin forks are resolved by waiting for further
proof-of-work, as in Bitcoin itself; nullifier first-occurrence is always
evaluated on the surviving canonical chain after reorg.

// ============================================================================
// 6. Incentive
// ============================================================================
= Incentive

The protocol defines a fee-coin mechanism under which publishers are compensated
per inscribed marker. They front the on-chain inscription cost and are paid in
fee coins attached to batch entries. The first protocol version keeps publishing
sponsored: anyone can self-publish or use a sponsoring publisher. The open fee
market is a defined, deferred mechanism rather than a launch feature; there is
no new issuance for publishers. The arrangement is analogous to miners collecting
transaction fees once block subsidy declines.

For the zkBTC reserve, operators post bonds and earn redemption fees (the
holder's max_fee ceiling) for fronting bitcoin to redeemers. A false assertion
is disproved on-chain, the operator's bond is slashed and the claim is void, so
a cheater burns its stake for a claim that pays nothing. Challenging is
permissionless, and how challengers are funded is an economic calibration the
design leaves open. Honesty is the profitable strategy. A publisher gains
nothing by withholding: users switch. Under those rules and the stated
assumptions (one-of-N setup honesty, at least one honest live challenger
in-window, and sound circuit and graph cryptography), cheating is not
profitable. The incentive is fee income for honest service, not issuance of a
new base asset. An attacker who accumulates bonds and registers many operators
gains no direct spend power over the vaults; spends exist only along the
pre-signed graph. Profit-seeking capital is better spent serving redemptions
for fees than burning bonds on disprovable assertions. The greedy strategy is
honest service, not coordinated fraud.

// ============================================================================
// 7. Compact State
// ============================================================================
= Compact State

Once the latest recursive proof of an account is verified, the earlier proofs
need not be kept. Bitcoin prunes spent transactions after the fact; zkCoins
never materializes the global history at all. Recursion folds the entire
transition history into one constant-size proof. The chain carries only 64
bytes per transaction. Nodes keep no global UTXO set and no per-user state: an
append-only log of first-occurrence markers suffices, and every account's
history folds into a constant-size recursive proof.

#v(0.3em)
// FIG-4 / FIG-5 side by side — small panel labels only (Bitcoin-paper style)
#align(center)[
  #block(width: 6.4in, height: 1.55in, {
    let ly = 0.05in
    let lx = 0.1in
    place(dx: lx, dy: ly, fbox(0.7in, 0.32in)[T1])
    place(dx: lx + 0.8in, dy: ly, fbox(0.7in, 0.32in)[T2])
    place(dx: lx + 1.6in, dy: ly, fbox(0.7in, 0.32in)[T3])
    place(dx: lx + 0.9in, dy: ly + 0.45in, fbox(1.2in, 0.4in)[recursion])
    arrow(lx + 0.35in, ly + 0.34in, lx + 1.2in, ly + 0.45in)
    arrow(lx + 1.15in, ly + 0.34in, lx + 1.4in, ly + 0.45in)
    arrow(lx + 1.95in, ly + 0.34in, lx + 1.7in, ly + 0.45in)
    place(dx: lx + 0.95in, dy: ly + 1.0in, fbox(1.1in, 0.35in)[$pi$ const.])
    arrow(lx + 1.5in, ly + 0.87in, lx + 1.5in, ly + 1.0in)
    place(dx: lx + 0.35in, dy: ly + 1.38in, fig-label[Full transition history])

    let rx = 3.5in
    place(dx: rx, dy: ly, box(
      width: 0.7in, height: 0.32in,
      stroke: (paint: black, thickness: 0.5pt, dash: "dashed"),
      inset: 2pt,
      align(center + horizon, fig-label-sm[T1]),
    ))
    place(dx: rx + 0.8in, dy: ly, box(
      width: 0.7in, height: 0.32in,
      stroke: (paint: black, thickness: 0.5pt, dash: "dashed"),
      inset: 2pt,
      align(center + horizon, fig-label-sm[T2]),
    ))
    place(dx: rx + 1.6in, dy: ly, box(
      width: 0.7in, height: 0.32in,
      stroke: (paint: black, thickness: 0.5pt, dash: "dashed"),
      inset: 2pt,
      align(center + horizon, fig-label-sm[T3]),
    ))
    place(dx: rx + 0.9in, dy: ly + 0.45in, box(
      width: 1.2in, height: 0.4in,
      stroke: (paint: black, thickness: 0.5pt, dash: "dashed"),
      inset: 2pt,
      align(center + horizon, fig-label-sm[folded]),
    ))
    place(dx: rx + 0.95in, dy: ly + 1.0in, fbox(1.1in, 0.35in)[$pi$ const.])
    arrow(rx + 1.5in, ly + 0.87in, rx + 1.5in, ly + 1.0in)
    place(dx: rx + 0.05in, dy: ly + 1.38in, fig-label[After folding only the latest proof is kept])
  })
]

#v(0.2em)
A rough capacity bound follows from block space alone. With 4 MB blocks every
10 minutes and 64 bytes per nullifier, Bitcoin as-is admits on the order of
$4 times 10^6 \/ 64 \/ 600 approx 104$ transitions per second if the entire block
were nullifiers. Block verification for the nullifier stream is cheaper than
Bitcoin's own: there is no witness execution and no UTXO lookup. New nodes need
no initial block download of transaction data, only the 64-byte markers and the
append-only first-occurrence log. Every node derives that log from the chain
alone, so nodes can leave and rejoin at will, accepting the nullifiers inscribed
while they were gone as proof of what happened — there is nothing else to trust.

// ============================================================================
// 8. Simplified Verification
// ============================================================================
= Simplified Verification

It is possible to verify payments without running a full proving stack. Two
light-verification arrangements apply.

A thin wallet may hold only its keys and secret blinds while a node runs
scanning and proving. The account's next spending key is bound through a
wallet-native hiding commitment, so a malicious node cannot rotate the wallet's
keys. It can, however, still choose the outputs it proves: binding payment
intent into the circuit is documented open design work, so a wallet that
delegates proving places that much trust in its node.

Separately, the mint transition embeds a recursive Bitcoin light-client proof
(headers and proof-of-work depth) showing that the backing transaction is buried
at least $D_"mint"$ blocks deep. This is in-circuit simplified payment
verification. As Nakamoto noted for SPV, proof-of-work depth proves work, not
canonicity: a private fork can also be deep. That residual is exactly why the
mint path can carry an external canonical-view check (the gatekeeper of
Section 11).

Users who receive frequent or high-value payments will still prefer to run their
own node and prover for independent verification. Delegation is a convenience
with that residual; running both recovers the full client-side verification path
of Section 4 without relying on a third party for scanning or proving.

#v(0.3em)
// FIG-6: header chain + LCP branch
#align(center)[
  #block(width: 5.8in, height: 1.65in, {
    let bw = 1.35in
    let bh = 0.45in
    let y = 0.15in
    let x0 = 0.3in
    let x1 = 2.0in
    let x2 = 3.7in
    place(dx: 1.6in, dy: 0in, fig-label-sm[Bitcoin Header Chain])
    place(dx: x0, dy: y, fbox(bw, bh)[Block Header])
    place(dx: x1, dy: y, fbox(bw, bh)[Block Header])
    place(dx: x2, dy: y, fbox(bw, bh)[Block Header])
    arrow(x0 + bw, y + bh / 2, x1, y + bh / 2)
    arrow(x1 + bw, y + bh / 2, x2, y + bh / 2)
    place(dx: x1 + 0.1in, dy: y + bh + 0.28in, fbox(1.15in, 0.35in)[MoveToBacked])
    arrow(x1 + bw / 2, y + bh, x1 + bw / 2, y + bh + 0.28in)
    place(dx: x1 + 0.2in, dy: y + bh + 0.75in, fbox(0.95in, 0.32in)[LCP $pi$])
    arrow(x1 + bw / 2, y + bh + 0.63in, x1 + bw / 2, y + bh + 0.75in)
  })
]

// ============================================================================
// 9. Combining and Splitting Value
// ============================================================================
= Combining and Splitting Value

Although it would be possible to handle coins individually, transitions that
contain multiple inputs and outputs are more efficient. A transition admits up
to eight inputs and eight outputs; conservation is enforced in-circuit. A
typical payment takes one input coin and splits it into a payment output and a
change output. There is never a need to extract a standalone copy of a coin's
full history; recursion has already folded it into the latest proof.

#v(0.3em)
// FIG-7: Transition with Ins and Outs
#align(center)[
  #block(width: 4.8in, height: 1.1in, {
    let cx = 1.7in
    let cy = 0.12in
    let bw = 1.5in
    let bh = 0.85in
    place(dx: 0.1in, dy: 0.12in, fbox(0.7in, 0.28in)[In])
    place(dx: 0.1in, dy: 0.55in, fbox(0.7in, 0.28in)[In])
    place(dx: cx, dy: cy, fbox(bw, bh)[Transition])
    place(dx: 3.7in, dy: 0.12in, fbox(0.7in, 0.28in)[Out])
    place(dx: 3.7in, dy: 0.55in, fbox(0.7in, 0.28in)[Out])
    arrow(0.82in, 0.26in, cx, cy + 0.28in)
    arrow(0.82in, 0.69in, cx, cy + 0.55in)
    arrow(cx + bw, cy + 0.28in, 3.7in, 0.26in)
    arrow(cx + bw, cy + 0.55in, 3.7in, 0.69in)
  })
]

// ============================================================================
// 10. Privacy
// ============================================================================
= Privacy

Banks provide confidentiality by gatekeeping information: access is limited to
the parties and their intermediary. A system that must announce transition
markers publicly has to create privacy elsewhere. Bitcoin breaks the information
flow at identities, keeping them outside the public ledger while amounts and the
graph remain fully public. zkCoins moves the boundary further: only the 64-byte
nullifiers are public. Amounts, parties, and the graph stay between sender and
receiver, protected by hiding commitments with fresh blinds. Address reuse does
not link on-chain markers; each transition's nullifier key is one-time.

#v(0.25em)
// FIG-8: three privacy model rows
#align(center)[
  #block(width: 6.4in, height: 1.8in, {
    let y1 = 0.02in
    place(dx: 0in, dy: y1, fig-label-sm[*Traditional Privacy Model*])
    let y1b = y1 + 0.22in
    place(dx: 0.05in, dy: y1b, fbox(0.85in, 0.28in)[Identities])
    arrow(0.92in, y1b + 0.14in, 1.1in, y1b + 0.14in)
    place(dx: 1.12in, dy: y1b, fbox(0.95in, 0.28in)[Transactions])
    arrow(2.09in, y1b + 0.14in, 2.27in, y1b + 0.14in)
    place(dx: 2.29in, dy: y1b, fbox(1.15in, 0.28in)[Trusted Third Party])
    arrow(3.46in, y1b + 0.14in, 3.64in, y1b + 0.14in)
    place(dx: 3.66in, dy: y1b, fbox(1.0in, 0.28in)[Counterparty])
    place(dx: 4.75in, dy: y1b - 0.02in, line(angle: 90deg, length: 0.32in, stroke: 1.2pt))
    place(dx: 4.9in, dy: y1b, fbox(0.7in, 0.28in)[Public])

    let y2 = 0.68in
    place(dx: 0in, dy: y2, fig-label-sm[*Bitcoin*])
    let y2b = y2 + 0.22in
    place(dx: 0.05in, dy: y2b, fbox(0.85in, 0.28in)[Identities])
    place(dx: 0.98in, dy: y2b - 0.02in, line(angle: 90deg, length: 0.32in, stroke: 1.2pt))
    place(dx: 1.12in, dy: y2b, fbox(0.95in, 0.28in)[Transactions])
    arrow(2.09in, y2b + 0.14in, 2.27in, y2b + 0.14in)
    place(dx: 2.29in, dy: y2b, fbox(0.7in, 0.28in)[Public])

    let y3 = 1.28in
    place(dx: 0in, dy: y3, fig-label-sm[*zkCoins*])
    let y3b = y3 + 0.22in
    place(dx: 0.05in, dy: y3b, fbox(0.85in, 0.28in)[Identities])
    place(dx: 0.98in, dy: y3b - 0.02in, line(angle: 90deg, length: 0.32in, stroke: 1.2pt))
    place(dx: 1.12in, dy: y3b, fbox(1.15in, 0.28in)[Transactions])
    arrow(2.29in, y3b + 0.14in, 2.5in, y3b + 0.14in)
    place(dx: 2.52in, dy: y3b, fbox(1.35in, 0.28in)[Nullifiers only])
  })
]

#v(0.15em)
As an additional firewall, a new account key is used for each transition, and
common practice is a new receiving account per counterparty relationship when
unlinkability among counterparties is required. The honest boundary remains:
peg-in and peg-out of zkBTC are ordinary public Bitcoin transactions, so amounts
and timing at the boundary are observable and correlatable. Internal transfers
are shielded.

// ============================================================================
// 11. The Bitcoin Reserve
// ============================================================================
= The Bitcoin Reserve

We now describe the bitcoin-backed token. zkBTC is token standard 3 on the
zkCoins transfer system: a one-to-one claim on bitcoin held in vaults, not in
custody.

The vault is a taproot output with a NUMS internal key, so there is no key-path
spend. Its only spend paths are an ordered, N-of-N pre-signed BitVM2 transaction
graph (assert, challenge, disprove, payout) fixed at deposit setup. After setup
the signing keys are deleted. The vault then has no live signer at all. Under
one-of-N honest deletion, no coalition can sign anything outside the graph.

Peg-in (mint) proceeds as follows. The depositor and the operators co-sign a
MoveToBacked transaction that places the deposit under the vault. The mint
transition proves in-circuit, via the light-client proof of Section 8, that
MoveToBacked is buried at least $D_"mint"$ blocks deep (deep finality, on the
order of 2016 blocks) and that the vault instance matches the asset's terms:
the operator-registration policy root, amount equality with the vault output,
and a one-shot mint key so each vault mints exactly once. Circulating supply is
then a conditional upper bound against the public vault set under the reserve
safety assumptions, not an unconditional invariant of the chain alone.

The gatekeeper is optional, per-asset, and load-bearing when present. Pure
in-circuit proof-of-work depth cannot prove canonicity (a private fork can be
deep) and cannot distinguish one party's many keys from many parties (a Sybil
operator epoch). Two independent backing-drain attacks follow: private-fork mint
settlement (Attack A), and a self-controlled operator epoch drained via ordinary
redemption (Attack B). A designated gatekeeper closes both at mint time only.
It co-signs a mint only after confirming, on its own canonical Bitcoin view, the
backing transaction and the epoch's registration commitment (Attack A), and only
if it vouches that the epoch's operator set contains at least one independent
honest signer (Attack B). It has no key on the vault, no role in transfers or
redemption, and cannot freeze, seize, or redirect. It can only refuse new mints.
A negligent or compromised gatekeeper that skips these checks enables Attacks A
and B; gatekeeper integrity at mint is therefore a backing-safety dependency in
gated mode. Without a gatekeeper, a pooled open-registration reserve is unsound.

Operators register openly. Anyone may register per deposit epoch by posting a
bond with proof of key possession. Registrations commit into a policy root. A
holder may register and serve their own exit. Epoch admission is two-level: a
policy root pins the bond class and an anti-domination rule, and per-epoch
registration commits the admitted set. An asset's terms therefore pin the
registration policy, not a fixed operator list.

Peg-out (redeem) is burn-first. The holder's redeem transition destroys the coin
and publishes a redeem identifier (its transition nullifier) committing the
payout address and a max_fee ceiling in hiding form. There is no un-burn: a
ceiling set too low can leave a burned coin unserved. Any registered operator
fronts the payout from its own funds within max_fee, then reclaims exactly the
redeem amount from the vault by asserting correct service through the BitVM2
graph. Any watcher can challenge a false assertion within the challenge window;
a single successful disprove slashes the operator's bond and voids the claim.
Reimbursement is claimant-committed, sole-funded, and single-party-authorised:
the payout transaction is non-transferable by construction. Under the stated
assumptions (one-of-N setup honesty, at least one honest live challenger acting
within the window, and sound circuit and graph cryptography), the worst case is
a freeze (redemption waits for a live operator), not theft. A critical circuit
or graph soundness bug is the theft case, which is why an external audit gates
mainnet.

Honest residuals remain even when theft is closed. The depositor's co-signature
makes a vaulted contribution consented; a gatekeeper that withholds its mint
signature after MoveToBacked has fired leaves that deposit an irrevocable reserve
contribution, a depositor-side loss path. With no council and no admin keys, a
freeze under the stated assumptions can be permanent absent a future covenant
upgrade. "Not theft" does not mean "recoverable."

We consider the probability of a private-fork mint settlement in the same terms
as Nakamoto's attacker analysis [1]. The race between the honest chain and an
attacker is a Binomial Random Walk. The probability of an attacker catching up
from $z$ blocks behind, when $p$ is the probability an honest node finds the
next block and $q = 1 - p$ is the attacker's, is the Gambler's Ruin probability

$
q_z = cases(
  1 & "if" p <= q,
  (q \/ p)^z & "if" p > q.
)
$

The verifier of a new mint cannot know the attacker's progress on a private
fork. How long must the network wait before treating a mint's backing as
settled? Assuming honest blocks took the expected time, the attacker's potential
progress while the mint waits for $z$ confirmations is a Poisson distribution
with expected value

$
lambda = z dot q \/ p.
$

To get the probability the attacker could still catch up now, multiply the
Poisson density for each amount of progress by the catch-up probability from
that point:

$
sum_(k=0)^infinity (lambda^k e^(-lambda) \/ k!) dot
cases(
  (q \/ p)^((z-k)) & "if" k <= z,
  1 & "if" k > z.
)
$

Rearranging to avoid summing the infinite tail of the distribution:

$
1 - sum_(k=0)^z (lambda^k e^(-lambda) \/ k!) dot (1 - (q \/ p)^((z-k))).
$

Converting to C code:

#set par(first-line-indent: 0pt, leading: 0.52em)
#pad(left: 1.2em)[
  #set text(font: "DejaVu Sans Mono", size: 8pt)
  #set par(leading: 0.52em)
  double AttackerSuccessProbability(double q, int z)\
  {\
  #h(1em)double p = 1.0 - q;\
  #h(1em)double lambda = z \* (q / p);\
  #h(1em)double sum = 1.0;\
  #h(1em)int i, k;\
  #h(1em)for (k = 0; k \<= z; k++)\
  #h(1em){\
  #h(2em)double poisson = exp(-lambda);\
  #h(2em)for (i = 1; i \<= k; i++)\
  #h(3em)poisson \*= lambda / i;\
  #h(2em)sum -= poisson \* (1 - pow(q / p, z - k));\
  #h(1em)}\
  #h(1em)return sum;\
  }
]
#set par(first-line-indent: 1em, leading: 0.65em)

Running some results, the probability drops off exponentially with $z$:

#set par(first-line-indent: 0pt, leading: 0.48em)
#pad(left: 1.2em)[
  #set text(font: "DejaVu Sans Mono", size: 8pt)
  q=0.1\
  z=0    P=1.0000000\
  z=1    P=0.2045873\
  z=2    P=0.0509779\
  z=3    P=0.0131722\
  z=4    P=0.0034552\
  z=5    P=0.0009137\
  z=6    P=0.0002428\
  z=7    P=0.0000647\
  z=8    P=0.0000173\
  z=9    P=0.0000046\
  z=10   P=0.0000012\
  \
  q=0.3\
  z=0    P=1.0000000\
  z=5    P=0.1773523\
  z=10   P=0.0416605\
  z=15   P=0.0101008\
  z=20   P=0.0024804\
  z=25   P=0.0006132\
  z=30   P=0.0001522\
  z=35   P=0.0000379\
  z=40   P=0.0000095\
  z=45   P=0.0000024\
  z=50   P=0.0000006
]
#set par(first-line-indent: 1em, leading: 0.65em)

Solving for $P$ less than 0.1\%:

#set par(first-line-indent: 0pt, leading: 0.48em)
#pad(left: 1.2em)[
  #set text(font: "DejaVu Sans Mono", size: 8pt)
  P \< 0.001\
  q=0.10   z=5\
  q=0.15   z=8\
  q=0.20   z=11\
  q=0.25   z=15\
  q=0.30   z=24\
  q=0.35   z=41\
  q=0.40   z=89\
  q=0.45   z=340
]
#set par(first-line-indent: 1em, leading: 0.65em)

Even the extreme row ($q = 0.45$) needs only $z = 340$ for $P < 0.1\%$. Mint
settlement waits $z = D_"mint" approx 2016$, where the pure catch-up probability
collapses further. The closed form $q_z = (q \/ p)^z$ for $p > q$ at deep
finality yields, for three attacker shares:

#set par(first-line-indent: 0pt, leading: 0.48em)
#pad(left: 1.2em)[
  #set text(font: "DejaVu Sans Mono", size: 8pt)
  q=0.10  (q/p = 1/9):   z=2016  P ≈ 10^-1924\
  q=0.30  (q/p = 3/7):   z=2016  P ≈ 10^-742\
  q=0.45  (q/p = 9/11):  z=2016  P ≈ 10^-176
]
#set par(first-line-indent: 1em, leading: 0.65em)

At deep finality the private-fork channel is economically closed even for a 45\%
attacker: $z = 2016$ yields probabilities on the order of $10^(-176)$ and
smaller. The residual mint risk is therefore the canonical-view and Sybil pair
closed by the gatekeeper, not raw proof-of-work catch-up.

// ============================================================================
// 12. Conclusion
// ============================================================================
= Conclusion

We have proposed a system for private electronic cash backed by bitcoin without
custodial trust. Coins are chains of proof-carrying state transitions. Bitcoin
orders constant-size nullifiers so double-spends are publicly detectable without
revealing amounts. Validity proofs replace global validation of a ledger of
values; the on-chain footprint stays constant. The reserve is secured by
pre-signed fraud-proof paths with an open operator set: under one-of-N setup
honesty, at least one honest live challenger in each window, and sound
cryptography, operators cannot steal. A gatekeeper, when designated, acts only
at the mint boundary and cannot freeze transfers or redemption. Exit depends on
liveness of some registered operator, never on permission. The guarantees are
conditional on the enumerated assumptions. This paper is an informative
introduction; the design is specified normatively in [8] and awaits
implementation and external audit.

// ============================================================================
// References
// ============================================================================
#heading(numbering: none)[References]

#set par(first-line-indent: 0pt, hanging-indent: 1.5em, justify: true, leading: 0.58em)
#set text(size: 10pt)

[1]#h(0.6em)S. Nakamoto, "Bitcoin: A Peer-to-Peer Electronic Cash System,"
https://bitcoin.org/bitcoin.pdf, 2008.

[2]#h(0.6em)R. Linus, "zkCoins,"
https://gist.github.com/RobinLinus/d036511015caea5a28514259a1bab119, 2023.

[3]#h(0.6em)J. Nick, L. Eagen, R. Linus, "Shielded CSV: Private and Efficient
Client-Side Validation," Cryptology ePrint Archive 2025/068, 2025.

[4]#h(0.6em)P. Todd, "Scalable Semi-Trustless Asset Transfer via Single-Use-Seals and
Proof-of-Publication," https://petertodd.org/2017/scalable-single-use-seal-asset-transfer, 2017.

[5]#h(0.6em)R. Linus et al., "BitVM2: Bridging Bitcoin to Second Layers,"
https://bitvm.org/bitvm_bridge.pdf, 2024.

[6]#h(0.6em)E. Bal, L. Aumayr, A. İyidoğan, G. Scaffino, H. Karakuş, C. E. Aslan, O. S. Thyfronitis
Litos, "Clementine: A Collateral-Efficient, Trust-Minimized, and Scalable Bitcoin Bridge," Cryptology
ePrint Archive 2025/776, 2025.

[7]#h(0.6em)P. Wuille, J. Nick, T. Ruffing, "Schnorr Signatures for secp256k1,"
BIP-340, 2020.

[8]#h(0.6em)"zkCoins protocol specification," https://github.com/zk-coins/docs, and "zkBTC token
standard," https://github.com/zk-coins/zkbtc, 2026.
