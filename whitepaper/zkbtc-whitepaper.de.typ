// zkBTC: Das vollständig private, vertrauensfreie Bitcoin
// Structural homage to Satoshi Nakamoto, Bitcoin (2008).
// German translation of zkbtc-whitepaper.typ. Built-ins only; no imports.

#set document(
  title: "zkBTC: Das vollständig private, vertrauensfreie Bitcoin",
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
  leading: 0.62em,
  first-line-indent: 1em,
  spacing: 0.62em,
)
#set text(font: "New Computer Modern", size: 11pt, lang: "de")

#set heading(numbering: "1.")
#show heading.where(level: 1): it => block(above: 1.3em, below: 0.55em)[
  #set text(weight: "bold", size: 13pt)
  #if it.numbering != none [#counter(heading).display(it.numbering)#h(0.6em)]#it.body
]

#let fig-label(body) = text(size: 7pt, body)
#let fig-label-sm(body) = text(size: 6.5pt, body)

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

#align(center)[
  #v(0.25em)
  #text(size: 16.5pt, weight: "bold")[
    zkBTC: Das vollständig private, vertrauensfreie Bitcoin
  ]
  #v(0.8em)
  #text(size: 11pt)[TaprootFreak]
  #v(0.3em)
  #text(size: 11pt)[www.zkcoins.com]
]

#v(0.9em)

#pad(x: 0.75in)[
  #set par(first-line-indent: 0pt, justify: true, leading: 0.60em)
  #text(weight: "bold")[Zusammenfassung.]
  #h(0.4em)
  Eine rein zwischen Peers laufende Form privaten elektronischen Geldes,
  gedeckt durch Bitcoin, würde Zahlungen erlauben, ohne Beträge oder den
  Transaktionsgraphen preiszugeben und ohne Verwahrer. Digitale Signaturen
  und Zero-Knowledge-Gültigkeitsbeweise lösen einen Teil, aber der Nutzen
  geht verloren, wenn eine vertrauenswürdige Partei Transaktionen ordnen
  oder das Deckungs-Bitcoin halten muss. Wir schlagen ein System vor, das
  Bitcoin nur als Ordnungsschicht nutzt. zkCoins ist ein clientseitig
  geprüftes Transferprotokoll: jeder Zustandsübergang trägt einen
  rekursiven Gültigkeitsbeweis, und der einzige On-Chain-Abdruck ist ein
  Nullifier fester Grösse von 64 Byte, der Doppelausgaben verhindert, ohne
  ein globales Betragsbuch. zkBTC ist ein eins-zu-eins durch Bitcoin
  gedecktes Token auf diesem Protokoll. Die Reserve liegt in Tresoren, die
  nur entlang vorsignierter BitVM2-Betrugsnachweis-Pfade ausgebbar sind,
  optional unter einem Gatekeeper je Asset prägbbar und von jedem Inhaber
  einlösbar, solange einer aus einer offenen, erlaubnisfreien Menge von
  Operatoren lebt. Unter den genannten Ehrlichkeits- und
  Lebendigkeitsannahmen (1-aus-N beim Einrichten, mindestens ein ehrlicher
  lebender Challenger in jedem Widerspruchsfenster, und einwandfreie
  Circuit- und Graph-Kryptographie) kann kein Operator die Reserve stehlen.
]

#v(0.4em)

= Einleitung

Der Internethandel siedelt noch immer über Finanzinstitute als
vertrauenswürdige Dritte. Bitcoin hat dieses Vertrauen für die Abwicklung
entfernt, doch jede Zahlung auf seinem Buch sendet Zahler, Empfänger und
Betrag an die Welt. Vertraulichkeit ist im gewöhnlichen Handel nötig; die
üblichen Mittel geben auf, was Bitcoin wertvoll macht. Eigene
Privatsphäre-Ketten ersetzen Bitcoins Sicherheitsmodell durch ein neues.
Verwahrte oder föderierte Wrapping-Token führen genau den Dritten wieder
ein, den Bitcoin entfernt hat.

Gebraucht wird elektronisches Geld, das Bitcoin als einzige Abwicklungs-
und einzige Deckungsgrundlage behält, Beträge und den Graphen
kryptographisch verbirgt und jedem Inhaber den Ausgang zurück auf
On-Chain-Bitcoin erlaubt, ohne dass jemand zustimmen muss. Dieses Paper
schlägt ein solches System vor. zkCoins ist ein clientseitig geprüftes
Transferprotokoll, dessen einziger On-Chain-Abdruck 64 Byte je Übergang
ist. zkBTC ist ein durch Bitcoin gedecktes Token darauf, dessen Reserve
durch Betrugsnachweise gesichert ist, nicht durch Verwahrung. Ehrliche
Mehrheit der Hashrate ordnet die Nullifier. Operatoren können die Reserve
nicht stehlen, solange ein ehrlicher Operator je Deckungsgruppe seinen
Schlüssel beim Einrichten löscht, mindestens ein ehrlicher lebender
Challenger in jedem Fenster handelt und Circuit sowie BitVM2-Graph
einwandfrei sind. Kanonizität des Mints und Vielfalt der Operator-Menge
sind eigene Residuen; ein bestimmter Gatekeeper kann beides prüfen.

= Transaktionen

Wir definieren eine elektronische Münze als Kette beweis tragender
Kontozustands-Übergänge. Jedes Konto ist eine Folge von Zuständen. Jeder
Übergang (Senden, Empfangen, Mint, Einlösen) trägt einen
Zero-Knowledge-Beweis, dass er den Regeln gegenüber seinem Vorgänger
genügt, und eine BIP-340-Signatur des aktuellen Kontoschlüssels. Der
Empfänger prüft den Beweis. Die Prüfung ist clientseitig: niemand sonst
muss Beträge oder Parteien sehen. Der Empfänger prüft die Beweiskette so,
wie ein Bitcoin-Empfänger die Signaturkette prüft.

Das Problem ist, dass der Empfänger nicht sehen kann, ob der Zahler einen
zweiten, widersprüchlichen Übergang desselben Zustands erzeugt hat. Eine
zentrale Prägeanstalt könnte ordnen, dann hängt das ganze Geldsystem an
ihr, und Privatsphäre und Ausgang fallen in Verwahrung zurück. Der
Empfänger muss wissen, dass kein früherer widersprüchlicher Übergang
existiert. Dafür braucht es eine einzige vereinbarte Geschichte von
Übergangsmarkern, öffentlich bekannt, ohne Beträge oder Parteien. Bei
zkBTC ist der erste Übergang einer Münze ein Mint, gebunden an eine
On-Chain-Tresor-Einlage (Abschnitt 11), der letzte ein Einlösen, das sie
verbrennt; dazwischen sind Transfers gewöhnliche zkCoins-Übergänge, und
die Deckung bewegt sich nicht. Der Lebenszyklus ist also Mint, Transfer,
Einlösen: nur die Endpunkte berühren die Reserve, jeder innere Schritt
bleibt vom Bitcoin-Buch weg ausser seinem Nullifier.

#v(0.35em)
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
      Übergang \
      Kontostand $i-1$ \
      Beweis $pi_(i-1)$ \
      Signatur des Inhabers
    ])
    place(dx: x1, dy: y, fbox(bw, bh)[
      Übergang \
      Kontostand $i$ \
      Beweis $pi_i$ \
      Signatur des Inhabers
    ])
    place(dx: x2, dy: y, fbox(bw, bh)[
      Übergang \
      Kontostand $i+1$ \
      Beweis $pi_(i+1)$ \
      Signatur des Inhabers
    ])
    let midy = y + bh / 2
    dline(x0 + bw, midy, x1, midy)
    place(dx: x0 + bw + 0.06in, dy: midy - 9pt, fig-label-sm[Prüfen])
    dline(x1 + bw, midy, x2, midy)
    place(dx: x1 + bw + 0.06in, dy: midy - 9pt, fig-label-sm[Prüfen])
    let ky = y + bh + 0.28in
    let kw = 1.15in
    let kh = 0.30in
    let kx0 = x0 + (bw - kw) / 2
    let kx1 = x1 + (bw - kw) / 2
    let kx2 = x2 + (bw - kw) / 2
    place(dx: kx0, dy: ky, fbox(kw, kh)[Kontoschlüssel])
    place(dx: kx1, dy: ky, fbox(kw, kh)[Kontoschlüssel])
    place(dx: kx2, dy: ky, fbox(kw, kh)[Kontoschlüssel])
    arrow(kx0 + kw / 2, ky, x0 + bw / 2, y + bh)
    place(dx: kx0 + kw / 2 + 4pt, dy: ky - 0.22in, fig-label-sm[Signieren])
    arrow(kx1 + kw / 2, ky, x1 + bw / 2, y + bh)
    place(dx: kx1 + kw / 2 + 4pt, dy: ky - 0.22in, fig-label-sm[Signieren])
    arrow(kx2 + kw / 2, ky, x2 + bw / 2, y + bh)
    place(dx: kx2 + kw / 2 + 4pt, dy: ky - 0.22in, fig-label-sm[Signieren])
  })
]
#v(0.08em)

= Die Nullifier-Kette

Die Lösung beginnt bei Bitcoin selbst als Ordnungsschicht. Bitcoin ist der
Zeitstempelserver. Jeder zustandsfortschreibende Übergang veröffentlicht
einen Nullifier fester Grösse (ein Paar $(upright("Pk")_i, R_i)$, ein aus
dem Kontoschlüssel abgeleiteter öffentlicher Schlüssel und eine
Nonce-Festlegung der Signatur, 64 Byte) in Bitcoin-Blöcken über
Inschriften, je Batch halbaggregiert. Der Nullifier verrät nichts über
Beträge, Parteien oder den Graphen; er bedeutet nur denen etwas, die die
Geschichte der Münze schon halten. Das erste Vorkommen eines gegebenen
Schlüssels $upright("Pk")_i$ auf der Kette zählt. Ein zweiter
widersprüchlicher Übergang desselben Zustands trifft denselben Schlüssel
und wird von jedem Prüfer abgewiesen. Die im Circuit verankerte
Vorgängerbindung lässt jeden Übergang beweisen, dass der Nullifier seines
Vorgängers schon on-chain ist, sodass keine Off-Chain-Gabel überlebt.
Halbaggregation lässt einen Publisher viele Nullifier-Signaturen zu einer
Inschrift mit einem gemeinsamen Aggregatskalar verbinden, sodass die
On-Chain-Kosten je Übergang beim 64-Byte-Paar bleiben, auch wenn ein Batch
viele Marker hält.

#v(0.35em)
#align(center)[
  #block(width: 5.4in, height: 1.55in, {
    let bw = 1.9in
    let bh = 0.92in
    let x0 = 0.35in
    let x1 = 3.0in
    let y = 0.08in
    place(dx: x0 + 0.35in, dy: y, fbox(1.2in, 0.26in)[Inschrift-Hash])
    place(dx: x1 + 0.35in, dy: y, fbox(1.2in, 0.26in)[Inschrift-Hash])
    place(dx: x0, dy: y + 0.30in, box(width: bw, height: bh, stroke: 0.6pt))
    place(dx: x1, dy: y + 0.30in, box(width: bw, height: bh, stroke: 0.6pt))
    place(dx: x0, dy: y + 0.34in, box(
      width: bw, height: 0.22in,
      align(center + horizon, text(size: 7pt)[Bitcoin-Block]),
    ))
    place(dx: x1, dy: y + 0.34in, box(
      width: bw, height: 0.22in,
      align(center + horizon, text(size: 7pt)[Bitcoin-Block]),
    ))
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

= Gültigkeitsbeweise

Wo Bitcoin Regeln mit Proof-of-Work durchsetzt, setzt zkCoins sie mit
Zero-Knowledge-Gültigkeitsbeweisen durch. Ein Compliance-Prädikat $C$ (ein
einziger Circuit) prüft jeden Übergang: Werterhaltung je Asset (weite Summe,
überlaufsicher, sodass kein Übergang Wert erzeugt ausser über einen
ausdrücklichen Mint), Autorisierung durch den Kontoschlüssel, korrekter
Vorgängerzustand, einmalige Verwendung jeder Münze und die Verankerung
alles dessen, was der Prüfer nicht sehen kann, in verbergende
Commitments. Beweise setzen sich rekursiv zusammen (proof-carrying data):
wer den letzten Beweis prüft, prüft die ganze Geschichte bis zur Genesis,
die Prüfkosten bleiben konstant. Eine Münze fälschen heisst, das
Beweissystem zu brechen, nicht das Netz zu überrechnen. Der Circuit ist
fest und sein Digest festgenagelt: alle prüfen gegen dasselbe Prädikat, wie
jeder Bitcoin-Knoten dasselbe Proof-of-Work-Ziel prüft.

#v(0.35em)
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
    place(dx: x0, dy: y, box(width: bw, height: bh, stroke: 0.6pt))
    place(dx: x1, dy: y, box(width: bw, height: bh, stroke: 0.6pt))
    place(dx: x0 + inset, dy: y + 0.08in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[$pi_(i-1)$ | $C$]),
    ))
    place(dx: x0 + inset, dy: y + 0.08in + ih + 0.04in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[Zustandsübergang]),
    ))
    place(dx: x1 + inset, dy: y + 0.08in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[$pi_i$ | $C$]),
    ))
    place(dx: x1 + inset, dy: y + 0.08in + ih + 0.04in, box(
      width: iw, height: ih, stroke: 0.5pt, inset: 2pt,
      align(center + horizon, text(size: 7pt)[Zustandsübergang]),
    ))
    arrow(x0 + bw, y + bh / 2, x1, y + bh / 2)
    place(dx: x0 + bw + 0.1in, dy: y + bh / 2 - 12pt, fig-label-sm[rekursiv])
  })
]
#v(0.08em)

= Netzwerk

Die Schritte, das Netz zu betreiben, sind:

#set par(first-line-indent: 0pt)
#enum(
  numbering: "1)",
  tight: true,
  [Der Sender baut einen Zustandsübergang und seinen Gültigkeitsbeweis und
    sendet den Münzbeweis direkt an den Empfänger off-chain (gift-wrapped,
    NIP-17-artiger Transport).],
  [Der Sender reicht seinen Nullifier an einen Publisher.],
  [Publisher bündeln Nullifier und schreiben den Batch als Inschrift in einen
    Bitcoin-Block, gegen On-Chain-Gebühren.],
  [Bitcoin ordnet die Inschriften mit Proof-of-Work.],
  [Empfänger (ihre Knoten) scannen Blöcke und nehmen einen Übergang nur an,
    wenn das erste Vorkommen seines Nullifiers passt.],
  [Wallets verlängern ihre Kontoketten auf verankerten Übergängen.],
)
#set par(first-line-indent: 1em)

Knoten halten stets die Bitcoin-Kette mit der meisten kumulierten Arbeit für
die richtige. Reorganisationen folgen Bitcoins eigener Longest-Chain-Regel:
ein tiefer als die Finalitätstiefe begrabener Übergang ist gesiedelt.
Erscheinen zwei Inschriften desselben Schlüssels, zählt nur das erste
Vorkommen auf der kanonischen Kette; das spätere ist eine Doppelausgabe und
wird abgewiesen.

Publisher sind erlaubnisfrei und austauschbar. Jeder kann selbst
veröffentlichen. Neue Nullifier-Ankündigungen vertragen verspätete
Ausstrahlung: wer einen Batch verpasst, kann später gegen die Kette prüfen.
Ein Nullifier muss nicht jeden Publisher erreichen; eine Aufnahme in einem
bestätigten Batch genügt, und wer keinem Publisher traut, schreibt ihn
selbst. Kein Publisher kann stehlen: sie berühren nie Münzen, nur
64-Byte-Marker. Einen bestimmten Nutzer zu zensieren kostet Gebühren, die
ein Wettbewerber einnimmt. Fälschen liegt ausser Reichweite: die Marker
tragen keinen ausgebbaren Wert, die Gültigkeit erzwingen die Beweise, die
der Empfänger prüft. Gleichstände zwischen Bitcoin-Gabeln löst weiteres
Proof-of-Work, wie in Bitcoin selbst; das erste Vorkommen eines Nullifiers
wird immer auf der überlebenden kanonischen Kette nach Reorg bewertet.

= Anreiz

Das Protokoll definiert einen Gebührenmünz-Mechanismus, unter dem Publisher
je eingeschriebenem Marker entlohnt werden. Sie legen die On-Chain-Kosten
vor und werden in Gebührenmünzen an den Batch-Einträgen bezahlt. Die erste
Protokollversion hält das Veröffentlichen gesponsert: jeder kann selbst
veröffentlichen oder einen sponsernden Publisher nutzen. Der offene
Gebührenmarkt ist ein definierter, aufgeschobener Mechanismus, kein
Startmerkmal; es gibt keine neue Ausgabe für Publisher. Die Anordnung
gleicht Minern, die Transaktionsgebühren einziehen, sobald die
Blocksubvention sinkt.

Für die zkBTC-Reserve hinterlegen Operatoren Kautionen und verdienen
Einlösegebühren (die `max_fee`-Decke des Inhabers) dafür, dass sie Bitcoin
an Einlöser vorstrecken. Eine falsche Behauptung wird on-chain widerlegt,
die Kaution des Operators wird gestrichen und der Anspruch ist nichtig, ein
Betrüger verbrennt also seinen Einsatz für eine Forderung, die nichts
zahlt. Widerspruch ist erlaubnisfrei; wie Challenger finanziert werden, ist
eine wirtschaftliche Kalibrierung, die der Entwurf offenlässt. Ehrlichkeit
ist die profitable Strategie. Ein Publisher gewinnt nichts durch
Zurückhalten: Nutzer wechseln. Unter diesen Regeln und den genannten
Annahmen (1-aus-N beim Einrichten, mindestens ein ehrlicher lebender
Challenger im Fenster, einwandfreie Circuit- und Graph-Kryptographie) ist
Betrug nicht profitabel. Der Anreiz ist Gebühreneinkommen für ehrlichen
Dienst, nicht Ausgabe eines neuen Basisassets. Wer Kautionen anhäuft und
viele Operatoren anmeldet, gewinnt keine direkte Ausgabemacht über die
Tresore; Ausgaben existieren nur entlang des vorsignierten Graphen.
Gewinnsuchendes Kapital ist besser damit eingesetzt, Einlösungen gegen
Gebühr zu bedienen, als Kautionen auf widerlegbaren Behauptungen zu
verbrennen. Die gierige Strategie ist ehrlicher Dienst, nicht abgesprochener
Betrug.

= Kompakter Zustand

Ist der letzte rekursive Beweis eines Kontos geprüft, müssen die früheren
nicht behalten werden. Bitcoin beschneidet ausgegebene Transaktionen im
Nachhinein; zkCoins materialisiert die globale Geschichte gar nicht.
Rekursion faltet die ganze Übergangsgeschichte in einen Beweis fester
Grösse. Die Kette trägt nur 64 Byte je Übergang. Knoten halten keine
globale UTXO-Menge und keinen Nutzerzustand: ein nur anhängendes Log der
Erstvorkommen reicht, und die Geschichte jedes Kontos faltet sich in einen
konstanten rekursiven Beweis.

#v(0.3em)
#align(center)[
  #block(width: 6.4in, height: 1.55in, {
    let ly = 0.05in
    let lx = 0.1in
    place(dx: lx, dy: ly, fbox(0.7in, 0.32in)[T1])
    place(dx: lx + 0.8in, dy: ly, fbox(0.7in, 0.32in)[T2])
    place(dx: lx + 1.6in, dy: ly, fbox(0.7in, 0.32in)[T3])
    place(dx: lx + 0.9in, dy: ly + 0.45in, fbox(1.2in, 0.4in)[Rekursion])
    arrow(lx + 0.35in, ly + 0.34in, lx + 1.2in, ly + 0.45in)
    arrow(lx + 1.15in, ly + 0.34in, lx + 1.4in, ly + 0.45in)
    arrow(lx + 1.95in, ly + 0.34in, lx + 1.7in, ly + 0.45in)
    place(dx: lx + 0.95in, dy: ly + 1.0in, fbox(1.1in, 0.35in)[$pi$ konst.])
    arrow(lx + 1.5in, ly + 0.87in, lx + 1.5in, ly + 1.0in)
    place(dx: lx + 0.35in, dy: ly + 1.38in, fig-label[Volle Übergangsgeschichte])

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
      align(center + horizon, fig-label-sm[gefaltet]),
    ))
    place(dx: rx + 0.95in, dy: ly + 1.0in, fbox(1.1in, 0.35in)[$pi$ konst.])
    arrow(rx + 1.5in, ly + 0.87in, rx + 1.5in, ly + 1.0in)
    place(dx: rx + 0.05in, dy: ly + 1.38in, fig-label[Nach dem Falten bleibt nur der letzte Beweis])
  })
]

#v(0.2em)
Eine grobe Kapazitätsgrenze folgt allein aus dem Blockraum. Mit 4-MB-Blöcken
alle 10 Minuten und 64 Byte je Nullifier lässt Bitcoin wie er ist rund
$4 times 10^6 \/ 64 \/ 600 approx 104$ Übergänge je Sekunde zu, wenn der
ganze Block Nullifier wäre. Die Blockprüfung des Nullifier-Stroms ist
billiger als Bitcoins eigene: keine Witness-Ausführung, kein UTXO-Lookup.
Neue Knoten brauchen keinen Initial Block Download von Transaktionsdaten,
nur die 64-Byte-Marker und das nur anhängende Erstvorkommen-Log. Jeder
Knoten leitet dieses Log aus der Kette allein ab, Knoten können gehen und
wiederkommen und die in ihrer Abwesenheit eingeschriebenen Nullifier als
Beweis dessen nehmen, was geschah — es gibt sonst nichts, dem zu vertrauen
wäre.

= Vereinfachte Prüfung

Zahlungen lassen sich prüfen, ohne den vollen Beweisstapel zu betreiben.
Zwei leichte Anordnungen gelten.

Eine dünne Wallet darf nur ihre Schlüssel und geheimen Blinds halten, während
ein Knoten scannt und beweist. Der nächste Ausgabeschlüssel des Kontos ist
über ein wallet-eigenes verbergendes Commitment gebunden, ein bösartiger
Knoten kann die Schlüssel der Wallet nicht drehen. Er kann aber noch die
Ausgaben wählen, die er beweist: Zahlungsabsicht in den Circuit zu binden
ist dokumentierte offene Entwurfsarbeit, eine Wallet, die das Beweisen
abgibt, legt darin Vertrauen in ihren Knoten.

Getrennt davon bettet der Mint-Übergang einen rekursiven
Bitcoin-Light-Client-Beweis (Header und Proof-of-Work-Tiefe) ein, der zeigt,
dass die Deckungs-Transaktion mindestens $D_"mint"$ Blöcke tief liegt. Das
ist vereinfachte Zahlungsprüfung im Circuit. Wie Nakamoto für SPV feststellte,
beweist Proof-of-Work-Tiefe Arbeit, nicht Kanonizität: eine private Gabel
kann ebenfalls tief sein. Genau dieses Residual ist der Grund, warum der
Mint-Pfad einen äusseren Canonical-View-Check tragen kann (der Gatekeeper
aus Abschnitt 11).

Wer häufige oder hochwertige Zahlungen empfängt, wird weiter eigenen Knoten
und Prover für unabhängige Prüfung vorziehen. Delegation ist eine
Bequemlichkeit mit diesem Residual; beides selbst zu betreiben stellt den
vollen clientseitigen Prüfpfad von Abschnitt 4 wieder her, ohne Dritte für
Scan oder Beweis.

#v(0.3em)
#align(center)[
  #block(width: 5.8in, height: 1.65in, {
    let bw = 1.35in
    let bh = 0.45in
    let y = 0.15in
    let x0 = 0.3in
    let x1 = 2.0in
    let x2 = 3.7in
    place(dx: 1.6in, dy: 0in, fig-label-sm[Bitcoin-Header-Kette])
    place(dx: x0, dy: y, fbox(bw, bh)[Block-Header])
    place(dx: x1, dy: y, fbox(bw, bh)[Block-Header])
    place(dx: x2, dy: y, fbox(bw, bh)[Block-Header])
    arrow(x0 + bw, y + bh / 2, x1, y + bh / 2)
    arrow(x1 + bw, y + bh / 2, x2, y + bh / 2)
    place(dx: x1 + 0.1in, dy: y + bh + 0.28in, fbox(1.15in, 0.35in)[MoveToBacked])
    arrow(x1 + bw / 2, y + bh, x1 + bw / 2, y + bh + 0.28in)
    place(dx: x1 + 0.2in, dy: y + bh + 0.75in, fbox(0.95in, 0.32in)[LCP $pi$])
    arrow(x1 + bw / 2, y + bh + 0.63in, x1 + bw / 2, y + bh + 0.75in)
  })
]

= Zusammenfassen und Aufteilen von Wert

Münzen einzeln zu behandeln wäre möglich; Übergänge mit mehreren Eingängen
und Ausgängen sind effizienter. Ein Übergang lässt bis zu acht Eingänge und
acht Ausgänge zu; Erhaltung wird im Circuit erzwungen. Eine typische Zahlung
nimmt eine Eingangsmünze und teilt sie in eine Zahlungs- und eine
Wechselausgabe. Eine eigenständige Kopie der vollen Geschichte einer Münze
braucht es nie; die Rekursion hat sie schon in den letzten Beweis gefaltet.

#v(0.3em)
#align(center)[
  #block(width: 4.8in, height: 1.1in, {
    let cx = 1.7in
    let cy = 0.12in
    let bw = 1.5in
    let bh = 0.85in
    place(dx: 0.1in, dy: 0.12in, fbox(0.7in, 0.28in)[Ein])
    place(dx: 0.1in, dy: 0.55in, fbox(0.7in, 0.28in)[Ein])
    place(dx: cx, dy: cy, fbox(bw, bh)[Übergang])
    place(dx: 3.7in, dy: 0.12in, fbox(0.7in, 0.28in)[Aus])
    place(dx: 3.7in, dy: 0.55in, fbox(0.7in, 0.28in)[Aus])
    arrow(0.82in, 0.26in, cx, cy + 0.28in)
    arrow(0.82in, 0.69in, cx, cy + 0.55in)
    arrow(cx + bw, cy + 0.28in, 3.7in, 0.26in)
    arrow(cx + bw, cy + 0.55in, 3.7in, 0.69in)
  })
]

= Privatsphäre

Banken schaffen Vertraulichkeit, indem sie Information bewachen: Zugang
haben die Parteien und ihr Vermittler. Ein System, das Übergangsmarker
öffentlich ansagen muss, muss Privatsphäre anderswo schaffen. Bitcoin
bricht den Informationsfluss an den Identitäten, hält sie ausserhalb des
öffentlichen Buchs, während Beträge und Graph voll öffentlich bleiben.
zkCoins schiebt die Grenze weiter: nur die 64-Byte-Nullifier sind
öffentlich. Beträge, Parteien und Graph bleiben zwischen Sender und
Empfänger, geschützt durch verbergende Commitments mit frischen Blinds.
Adresswiederverwendung verknüpft keine On-Chain-Marker; der
Nullifier-Schlüssel jedes Übergangs ist einmalig.

#v(0.25em)
#align(center)[
  #block(width: 6.4in, height: 1.8in, {
    let y1 = 0.02in
    place(dx: 0in, dy: y1, fig-label-sm[*Herkömmliches Privatsphäre-Modell*])
    let y1b = y1 + 0.22in
    place(dx: 0.05in, dy: y1b, fbox(0.85in, 0.28in)[Identitäten])
    arrow(0.92in, y1b + 0.14in, 1.1in, y1b + 0.14in)
    place(dx: 1.12in, dy: y1b, fbox(0.95in, 0.28in)[Transaktionen])
    arrow(2.09in, y1b + 0.14in, 2.27in, y1b + 0.14in)
    place(dx: 2.29in, dy: y1b, fbox(1.15in, 0.28in)[Vertrauter Dritter])
    arrow(3.46in, y1b + 0.14in, 3.64in, y1b + 0.14in)
    place(dx: 3.66in, dy: y1b, fbox(1.0in, 0.28in)[Gegenpartei])
    place(dx: 4.75in, dy: y1b - 0.02in, line(angle: 90deg, length: 0.32in, stroke: 1.2pt))
    place(dx: 4.9in, dy: y1b, fbox(0.7in, 0.28in)[Öffentlich])

    let y2 = 0.68in
    place(dx: 0in, dy: y2, fig-label-sm[*Bitcoin*])
    let y2b = y2 + 0.22in
    place(dx: 0.05in, dy: y2b, fbox(0.85in, 0.28in)[Identitäten])
    place(dx: 0.98in, dy: y2b - 0.02in, line(angle: 90deg, length: 0.32in, stroke: 1.2pt))
    place(dx: 1.12in, dy: y2b, fbox(0.95in, 0.28in)[Transaktionen])
    arrow(2.09in, y2b + 0.14in, 2.27in, y2b + 0.14in)
    place(dx: 2.29in, dy: y2b, fbox(0.7in, 0.28in)[Öffentlich])

    let y3 = 1.28in
    place(dx: 0in, dy: y3, fig-label-sm[*zkCoins*])
    let y3b = y3 + 0.22in
    place(dx: 0.05in, dy: y3b, fbox(0.85in, 0.28in)[Identitäten])
    place(dx: 0.98in, dy: y3b - 0.02in, line(angle: 90deg, length: 0.32in, stroke: 1.2pt))
    place(dx: 1.12in, dy: y3b, fbox(1.15in, 0.28in)[Transaktionen])
    arrow(2.29in, y3b + 0.14in, 2.5in, y3b + 0.14in)
    place(dx: 2.52in, dy: y3b, fbox(1.35in, 0.28in)[Nur Nullifier])
  })
]

#v(0.15em)
Als zusätzliche Brandmauer wird je Übergang ein neuer Kontoschlüssel
verwendet, und üblich ist ein neues Empfangskonto je Gegenpartei, wenn
Unverkettbarkeit unter Gegenparteien nötig ist. Die ehrliche Grenze bleibt:
Peg-in und Peg-out von zkBTC sind gewöhnliche öffentliche
Bitcoin-Transaktionen, Beträge und Zeit am Rand sind beobachtbar und
korrelierbar. Innere Transfers sind abgeschirmt.

= Die Bitcoin-Reserve

Wir beschreiben jetzt das durch Bitcoin gedeckte Token. zkBTC ist
Token-Standard 3 auf dem zkCoins-Transfersystem: ein eins-zu-eins-Anspruch
auf Bitcoin in Tresoren, nicht in Verwahrung.

Der Tresor ist eine Taproot-Ausgabe mit NUMS-Internschlüssel, es gibt also
keinen Key-Path-Spend. Seine einzigen Ausgabepfade sind ein geordneter,
N-aus-N vorsignierter BitVM2-Transaktionsgraph (Assert, Challenge, Disprove,
Payout), fest beim Einrichten der Einlage. Nach dem Einrichten werden die
Signaturschlüssel gelöscht. Der Tresor hat dann überhaupt keinen lebenden
Unterzeichner. Unter ehrlichem 1-aus-N-Löschen kann keine Koalition etwas
ausserhalb des Graphen unterschreiben.

Peg-in (Mint) läuft so. Einleger und Operatoren unterschreiben gemeinsam
eine MoveToBacked-Transaktion, die die Einlage unter den Tresor legt. Der
Mint-Übergang beweist im Circuit, über den Light-Client-Beweis aus
Abschnitt 8, dass MoveToBacked mindestens $D_"mint"$ Blöcke tief liegt
(tiefe Finalität, in der Grössenordnung 2016 Blöcke) und dass die
Tresorinstanz zu den Asset-Bedingungen passt: die Policy-Wurzel der
Operator-Anmeldung, Betragsgleichheit mit der Tresorausgabe und ein
Einmal-Mintschlüssel, sodass jeder Tresor genau einmal prägt. Der Umlauf
ist dann eine bedingte Obergrenze gegen die öffentliche Tresormenge auf der
kanonischen Kette, kein unbedingtes Invariant der Kette allein.

Der Gatekeeper ist optional und je Asset. Reine Proof-of-Work-Tiefe im
Circuit beweist keine Kanonizität (eine private Gabel kann tief sein) und
kann die vielen Schlüssel einer Partei nicht von vielen Parteien
unterscheiden (eine Sybil-Operator-Epoche). Zwei unabhängige Drain-Angriffe
auf die Deckung folgen: Mint-Abrechnung gegen eine private Gabel (Angriff
A) und eine selbst kontrollierte Operator-Epoche, die über gewöhnliches
Einlösen geleert wird (Angriff B). Ein bestimmter Gatekeeper kann beide nur
zur Mint-Zeit schliessen. Es unterschreibt einen Mint erst, nachdem es auf
seiner eigenen kanonischen Bitcoin-Sicht die Deckungs-Transaktion und die
Anmeldeverpflichtung der Epoche bestätigt hat (Angriff A), und nur wenn es
verbürgt, dass die Operator-Menge der Epoche mindestens einen unabhängigen
ehrlichen Unterzeichner enthält (Angriff B). Es hat keinen Schlüssel auf
dem Tresor, keine Rolle bei Transfers oder Einlösen und kann nicht
einfrieren, beschlagnahmen oder umleiten. Es kann nur neue Mints
ablehnen. Ein nachlässiger oder kompromittierter Gatekeeper, der diese
Prüfungen überspringt, ermöglicht Angriff A und B.

Operatoren melden sich offen an. Jeder darf sich je Einlage-Epoche anmelden,
indem er eine Kaution mit Beweis des Schlüsselbesitzes hinterlegt.
Anmeldungen verpflichten sich in eine Policy-Wurzel. Ein Inhaber darf sich
anmelden und den eigenen Ausgang bedienen. Die Epochenaufnahme ist
zweistufig: eine Policy-Wurzel nagelt Kautionsklasse und
Anti-Dominanz-Regel fest, die Anmeldung je Epoche verpflichtet die
zugelassene Menge. Die Bedingungen eines Assets nageln also die
Anmelderegel fest, keine feste Operatorliste.

Peg-out (Einlösen) ist zuerst verbrennen. Der Einlöse-Übergang des Inhabers
zerstört die Münze und veröffentlicht eine Einlösekennung (ihren
Übergangs-Nullifier), die Auszahladresse und eine `max_fee`-Decke in
verbergender Form festlegt. Es gibt kein Ent-Verbrennen: eine zu niedrig
gesetzte Decke kann eine verbrannte Münze unbedient lassen. Jeder
angemeldete Operator streckt die Auszahlung aus eigenen Mitteln innerhalb
`max_fee` vor und holt genau den Einlösebetrag aus dem Tresor zurück, indem
er korrekten Dienst über den BitVM2-Graphen behauptet. Jeder Beobachter
kann eine falsche Behauptung im Widerspruchsfenster anfechten; ein einziger
erfolgreicher Disprove streicht die Kaution und macht den Anspruch nichtig.
Die Erstattung ist anspruchnehmergebunden, allein finanziert und von einer
Partei autorisiert: die Auszahltransaktion ist konstruktionsgemäss nicht
übertragbar. Unter den genannten Annahmen (1-aus-N beim Einrichten,
mindestens ein ehrlicher lebender Challenger im Fenster, einwandfreie
Circuit- und Graph-Kryptographie) ist der schlimmste Fall ein Einfrieren
(das Einlösen wartet auf einen lebenden Operator), nicht Diebstahl. Ein
kritischer Circuit- oder Graph-Soundness-Fehler ist der Diebstahlfall,
deshalb sperrt ein externes Audit das Mainnet.

Ehrliche Residuen bleiben, auch wenn Diebstahl geschlossen ist. Die
Mitunterschrift des Einlegers macht einen getresorten Beitrag zugestimmt;
ein Gatekeeper, der seine Mint-Signatur zurückhält, nachdem MoveToBacked
gefeuert hat, lässt diese Einlage einen unwiderruflichen Reservebeitrag, ein
Verlustpfad auf der Einlegerseite. Ohne Rat und ohne Admin-Schlüssel kann
ein Einfrieren unter den genannten Annahmen dauerhaft sein, solange kein
künftiges Covenant-Upgrade kommt. „Nicht Diebstahl" heisst nicht
„wieder holbar".

Wir betrachten die Wahrscheinlichkeit eines Aufholens gegen die kanonische
Kette in denselben Begriffen wie Nakamotos Angreiferanalyse [1]. Das Rennen
zwischen ehrlicher Kette und Angreifer ist ein binomialer Random Walk. Die
Wahrscheinlichkeit, dass ein Angreifer von $z$ Blöcken Rückstand aufholt,
wenn $p$ die Wahrscheinlichkeit ist, dass ein ehrlicher Knoten den nächsten
Block findet, und $q = 1 - p$ die des Angreifers, ist die
Gambler's-Ruin-Wahrscheinlichkeit

$
q_z = cases(
  1 & "falls" p <= q,
  (q \/ p)^z & "falls" p > q.
)
$

Der Prüfer eines neuen Mints kann den Fortschritt des Angreifers auf einer
privaten Gabel nicht kennen. Wie lange muss das Netz warten, bevor es die
Deckung eines Mints als gesiedelt behandelt? Nimmt man an, ehrliche Blöcke
brauchten die erwartete Zeit, ist der mögliche Fortschritt des Angreifers,
während der Mint auf $z$ Bestätigungen wartet, eine Poisson-Verteilung mit
Erwartungswert

$
lambda = z dot q \/ p.
$

Die Wahrscheinlichkeit, dass der Angreifer jetzt noch aufholen könnte,
ergibt sich, indem man die Poisson-Dichte jedes Fortschritts mit der
Aufholwahrscheinlichkeit von dort multipliziert:

$
sum_(k=0)^infinity (lambda^k e^(-lambda) \/ k!) dot
cases(
  (q \/ p)^((z-k)) & "falls" k <= z,
  1 & "falls" k > z.
)
$

Umgestellt, damit man nicht den unendlichen Schwanz summiert:

$
1 - sum_(k=0)^z (lambda^k e^(-lambda) \/ k!) dot (1 - (q \/ p)^((z-k))).
$

Als C-Code:

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
#set par(first-line-indent: 1em, leading: 0.62em)

Einige Ergebnisse: die Wahrscheinlichkeit fällt exponentiell mit $z$:

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
#set par(first-line-indent: 1em, leading: 0.62em)

Für $P$ kleiner als 0,1 %:

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
#set par(first-line-indent: 1em, leading: 0.62em)

Selbst die Extremzeile ($q = 0.45$) braucht nur $z = 340$ für $P < 0.1\%$.
Die Mint-Abrechnung wartet $z = D_"mint" approx 2016$, wo die reine
Aufholwahrscheinlichkeit weiter zusammenbricht. Die geschlossene Form
$q_z = (q \/ p)^z$ für $p > q$ bei tiefer Finalität ergibt für drei
Angreiferanteile:

#set par(first-line-indent: 0pt, leading: 0.48em)
#pad(left: 1.2em)[
  #set text(font: "DejaVu Sans Mono", size: 8pt)
  q=0.10  (q/p = 1/9):   z=2016  P ≈ 10^-1924\
  q=0.30  (q/p = 3/7):   z=2016  P ≈ 10^-742\
  q=0.45  (q/p = 9/11):  z=2016  P ≈ 10^-176
]
#set par(first-line-indent: 1em, leading: 0.62em)

Bei tiefer Finalität ist das Aufholen gegen die ehrliche Kette selbst für
einen 45-Prozent-Angreifer wirtschaftlich geschlossen: $z = 2016$ liefert
Wahrscheinlichkeiten der Ordnung $10^(-176)$ und kleiner. Das ist nicht
Angriff A: eine private Gabel kann tief sein, ohne die ehrliche Kette
einzuholen. Das Residual-Mint-Risiko ist daher die Kanonizität der
bewiesenen Kette und die Unterscheidung zwischen den Schlüsseln einer
Partei und vielen Parteien, nicht rohes Proof-of-Work-Aufholen. Ein
bestimmter Gatekeeper kann beides zur Mint-Zeit prüfen.

= Schluss

Wir haben ein System für privates elektronisches Geld vorgeschlagen, gedeckt
durch Bitcoin, ohne Verwahrvertrauen. Münzen sind Ketten beweis tragender
Zustandsübergänge. Bitcoin ordnet Nullifier fester Grösse, sodass
Doppelausgaben öffentlich erkennbar sind, ohne Beträge preiszugeben.
Gültigkeitsbeweise ersetzen die globale Prüfung eines Wertbuchs; der
On-Chain-Abdruck bleibt konstant. Die Reserve ist durch vorsignierte
Betrugsnachweis-Pfade mit offener Operator-Menge gesichert: unter 1-aus-N
beim Einrichten, mindestens einem ehrlichen lebenden Challenger in jedem
Fenster und einwandfreier Kryptographie können Operatoren nicht stehlen. Ein
Gatekeeper, wenn einer bestimmt ist, handelt nur an der Mint-Grenze und
kann Transfers oder Einlösen nicht einfrieren. Der Ausgang hängt an der
Lebendigkeit eines angemeldeten Operators, nie an einer Erlaubnis. Die
Garantien sind an die aufgezählten Annahmen gebunden. Dieses Paper ist eine
informative Einführung; der Entwurf ist normativ in [8] festgelegt und
wartet auf Umsetzung und externes Audit.

#heading(numbering: none)[Literatur]

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

[8]#h(0.6em)"zkCoins-Protokollspezifikation," https://github.com/zk-coins/docs, und "zkBTC-Tokenstandard,"
https://github.com/zk-coins/zkbtc, 2026.
