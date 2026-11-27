# Strategie-Modelle im Vergleich

Neben dem `TurtleEA` gibt es vier weitere Modelle. Sie decken bewusst unterschiedliche
Marktverhalten ab, damit man im Strategietester sieht, **welches Modell in welcher Phase,
auf welchem Zeitrahmen und bei welchem Instrument** funktioniert. Alle fünf EAs nutzen

- denselben Signal-Zeitrahmen-Parameter `InpTimeframe`,
- dieselbe ATR nach Wilder für Stops und Positionsgröße,
- dasselbe Optimierungskriterium `OnTester` = Gewinn ÷ Equity-Drawdown ab `InpMinTrades` Trades,

so dass die Ergebnisse direkt nebeneinander gestellt werden können.

## Kurzübersicht

| Modell | Datei | Logik | Stärkste Phase | Schwächste Phase |
|---|---|---|---|---|
| Turtle (S1/S2) | `TurtleEA.mq5` | Donchian-Ausbruch, Pyramiding | lange, starke Trends (2008, 2020, 2022) | Seitwärtsmärkte (2013–17 bei FX) |
| A: MA-Crossover | `MACrossEA.mq5` | schneller MA kreuzt langsamen MA | langsame, stabile Trends | Seitwärts, schnelle V-Umkehr (2020) |
| B: Keltner-Ausbruch | `KeltnerBreakoutEA.mq5` | Schluss außerhalb EMA ± 2 ATR, optional Squeeze | Ausbruch nach ruhiger Phase | Fehlausbrüche in Seitwärtsmärkten |
| C: Mean-Reversion | `MeanReversionEA.mq5` | RSI(2) extrem → Gegenposition, Ausstieg am SMA(5) | Seitwärts und Bullenmarkt mit Rücksetzern (2013–17) | Crash- und Trendphasen (2008, 2022 Short-Seite) |
| D: Momentum | `MomentumEA.mq5` | Vorzeichen der 12-Monats-Rendite, monatlich | lange Makrotrends über viele Märkte | Trendwenden, kurze Zeitrahmen |

## Vor- und Nachteile im Detail

### Turtle (Referenz)

**Vorteile**
- Bewährtes, vollständig regelbasiertes Trendfolge-System; fängt große Trends voll mit.
- Pyramiding bis 4 Units hebelt die seltenen großen Gewinner.
- Positionsgröße über N passt sich automatisch an jedes Instrument an.

**Nachteile**
- Viele kleine Verluste (Trefferquote meist 30–40 %), lange Drawdown-Phasen.
- Pyramiding erhöht das Risiko pro Markt auf bis zu ~8 % (4 Units × 2 N).
- Tickgenaue Ausbrüche auf kurzen Zeitrahmen: Spread und Slippage schlagen voll durch.

### Modell A: MA-Crossover (`MACrossEA`)

Long, wenn EMA(50) die EMA(200) nach oben kreuzt, Short umgekehrt. Ausstieg bei
Gegenkreuzung (mit Umkehr) oder über den ATR-Trailing-Stop (3 ATR).

**Vorteile**
- Sehr einfach, robust und schwer zu überoptimieren (nur zwei Perioden).
- Wenige Trades, dadurch auf D1/H4 kaum kostenempfindlich.
- Glattere Kurve als Turtle, weil nicht pyramidisiert wird.

**Nachteile**
- Spät: Einstieg oft erst nach einem großen Teil der Bewegung, Ausstieg spät nach der Wende.
- In Seitwärtsphasen „Whipsaws“ (Kreuzung hin und her).
- Nach einem Stop-Ausstieg wird erst bei der nächsten Kreuzung wieder eingestiegen,
  ein fortlaufender Trend kann also verpasst werden.

**Zeitrahmen:** D1, H4. Unter H1 zu viele Fehlsignale. **Kosten:** gering. **Drawdown:** mittel, aber lange Erholungszeiten.

### Modell B: Keltner-Ausbruch (`KeltnerBreakoutEA`)

Long, wenn eine Bar über EMA(20) + 2 ATR schließt; Short spiegelbildlich. Optionaler
Squeeze-Filter (`InpSqueezeBars` > 0): nur handeln, wenn kurz vorher die Bollinger-Bänder
innerhalb des Keltner-Kanals lagen, also die Volatilität ungewöhnlich niedrig war.
Ausstieg bei Schluss jenseits der EMA, über Anfangsstop (2 ATR) oder Trailing-Stop.

**Vorteile**
- Volatilitätsangepasster Kanal statt fester Hoch/Tief-Werte: reagiert schneller als der
  55-Bar-Donchian, aber mit Schlusskurs-Bestätigung (weniger Fehlausbrüche als tickgenau).
- Squeeze-Filter sortiert viele Fehlausbrüche aus und ist ein Gegenstück zum ADX-Filter.
- Kürzere Haltedauer als Turtle → schnellere Erholung nach Drawdowns.

**Nachteile**
- Ausstieg an der Mitte nimmt Gewinne in großen Trends früh mit.
- Mehr Parameter (Periode, Breite, Squeeze) → höheres Überoptimierungsrisiko.
- Mit Squeeze-Filter deutlich weniger Trades (Mindestanzahl für `OnTester` beachten).

**Zeitrahmen:** H1 bis D1; auf M15 nur mit Squeeze sinnvoll. **Kosten:** mittel. **Drawdown:** mittel, kürzer als bei Turtle.

### Modell C: Mean-Reversion (`MeanReversionEA`)

Long, wenn RSI(2) unter 10 fällt (optional nur über dem SMA(200)), Short über 90
(nur unter dem SMA(200)). Ausstieg, sobald der Schlusskurs den SMA(5) überquert, nach
spätestens 10 Bars, oder am weiten Notfall-Stop (3 ATR). Optional nur bei ADX < Grenze.

**Vorteile**
- Gegenpol zu allen Trendmodellen: verdient in Seitwärtsphasen, in denen Turtle verliert.
  Im Portfolio glättet das die Equity-Kurve deutlich.
- Hohe Trefferquote (oft 60–75 %), kurze Haltedauer, wenig Kapitalbindung.
- Funktioniert historisch gut bei Aktienindizes und Einzelaktien (Long-Seite).

**Nachteile**
- Gewinne klein, Verluste gelegentlich groß: Wenn ein Rücksetzer zum Crash wird
  (2008, März 2020), schlägt der Notfall-Stop zu.
- Short-Seite in Bullenmärkten und bei Aktien meist schwach → `InpDirection = nur Long` testen.
- Bei FX und Rohstoffen schwächer, weil dort Trends länger laufen.

**Zeitrahmen:** D1, H4. Kürzer wird es schnell kostendominiert, weil der Gewinn je Trade klein ist.
**Kosten:** hoch empfindlich. **Drawdown:** selten, aber abrupt.

### Modell D: Zeitreihen-Momentum (`MomentumEA`)

Richtung = Vorzeichen der Rendite über 252 Bars (D1 ≈ 1 Jahr), optional ohne den
letzten Monat (`InpSkipBars = 21`, „12-1-Momentum“). Neu entschieden wird nur alle
21 Bars (monatlich). Positionsgröße wie ein Turtle-Unit: 1 ATR = 1 % Equity.
Standardmäßig ohne Stop, wie in der Literatur (Moskowitz/Ooi/Pedersen).

**Vorteile**
- Sehr wenige Trades → kaum Kosten, auch für Konten mit höheren Kommissionen geeignet.
- Gut dokumentiert über viele Anlageklassen und Jahrzehnte; profitiert von Krisenjahren
  (2008, 2022) über Short-Positionen.
- Kaum Parameter, wenig Überoptimierungsrisiko.

**Nachteile**
- Reagiert sehr langsam: Trendwenden kosten oft einen Monat Verlust oder mehr (V-Erholung 2020).
- Pro Instrument wenige Trades → statistisch dünn; erst im Portfolio über viele Märkte aussagekräftig.
- Ohne Stop sind die Einzeltrade-Drawdowns groß; `InpStopATR` (z. B. 5) begrenzt sie, ändert aber das Modell.
- Auf Minuten-Zeitrahmen ist die Grundannahme (Monatstrends) nicht übertragbar.

**Zeitrahmen:** nur D1 (oder W1). **Kosten:** sehr gering. **Drawdown:** tief, aber langsam.

## Vergleich nach Kriterien

| Kriterium | Turtle | A: MA-Cross | B: Keltner | C: Mean-Rev. | D: Momentum |
|---|---|---|---|---|---|
| Marktannahme | Trend | Trend | Volatilitätsausbruch | Rückkehr zum Mittel | Trend (lang) |
| Trades pro Jahr (D1, 1 Markt) | 10–20 | 2–5 | 8–20 | 15–40 | 2–6 |
| Trefferquote | niedrig | niedrig | mittel | hoch | mittel |
| Kostenempfindlichkeit | mittel–hoch | gering | mittel | hoch | sehr gering |
| Sinnvolle Zeitrahmen | H4–D1 | H4–D1 | H1–D1 | H4–D1 | D1–W1 |
| Drawdown-Profil | lang, tief | lang, mittel | kürzer, mittel | selten, abrupt | tief, langsam |
| Parameteranzahl | mittel | gering | hoch | mittel | gering |
| Beste Instrumente | FX, Metalle, Rohstoffe | Indizes, Metalle | Metalle, Indizes | Aktien, Indizes | breites Portfolio |

Die Zahlen sind Erfahrungswerte aus der Literatur, keine Backtest-Ergebnisse dieses Repos.

## Vorschlag für die Tests

1. Jedes Modell mit Standardparametern auf D1 über alle Marktphasen und Instrumente
   laufen lassen (Optimierung nur über `InpTimeframe` und Symbole), um eine Basislinie zu haben.
2. Danach je Modell höchstens zwei Parameter optimieren:
   - Turtle: `InpSystem`, `InpFilter`
   - MA-Cross: `InpFastPeriod`, `InpSlowPeriod`
   - Keltner: `InpKCMult`, `InpSqueezeBars` (0 / 5 / 10)
   - Mean-Reversion: `InpRSILow`/`InpRSIHigh`, `InpDirection`
   - Momentum: `InpLookback` (63 / 126 / 252), `InpSkipBars` (0 / 21)
3. Out-of-Sample prüfen: auf 2013–2017 optimieren, auf 2020 und 2022 testen (und umgekehrt).
4. Für Momentum `InpMinTrades` niedriger lassen (Standard 10) oder über viele Symbole testen.
5. Interessant für später: Trendmodell + Mean-Reversion gleichzeitig (unterschiedliche
   Magic Numbers) auf demselben Konto – die beiden ergänzen sich typischerweise.
