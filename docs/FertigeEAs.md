# Fertige Handelssysteme mit Testreihen – Recherche und Analyse

Stand: 27.11.2026. Gesucht wurden **fertige, herunterladbare** Systeme (vor allem MT5-EAs,
dazu Python/Open Source), zu denen eine **veröffentlichte Testreihe** existiert
(Backtest-Report, Live-Signal oder Wettbewerb). Geprüft: MQL5 CodeBase, MQL5 Market (Free und
bezahlt), MQL5-Artikel und -Blogs, GitHub, QuantConnect/Quantpedia, Freqtrade sowie
Review-Seiten zu bekannten Verkaufs-EAs.

Zu jedem Eintrag stehen **Quelle (URL) und Veröffentlichungsdatum**. Alle Zahlen sind
Angaben der Autoren oder Verkäufer, nicht von uns nachgerechnet. Einzige Ausnahme sind die
Geraked-Reports (Nr. 1): deren Excel-Reports und `.set`-Dateien haben wir selbst ausgelesen.
Fremder Code wurde **nicht ausgeführt**.

Legende Glaubwürdigkeit: ★★★ unabhängig oder live belegt · ★★ nachvollziehbarer Backtest mit
Stop-Loss und genug Trades · ★ dünn, in-sample oder unvollständig · ⚠ Grid/Martingale oder
belegter Kontocrash.

## Ergebnis in Kürze

- **Wirklich belastbar ist wenig.** Rund 30 Systeme geprüft; eine mehrjährige Live-Historie
  haben nur Rob Carvers eigenes Konto (pysystemtrade, 12 Jahre, Sharpe 0,80) und die
  Verkaufs-EAs von V. Mishchenko – darunter Waka Waka als Warnung (−94,9 %).
- **Die besten MT5-Vergleichskandidaten für unseren Turtle** sind zwei frei verfügbare
  Donchian-Ausbruchs-EAs mit Stop-Loss und vollständigem Report: *Gold Breakout EA* (Quellcode)
  und *FXEA365 Donchian Trend Engine* (nur kompiliert).
- **Die größte offene MT5-Sammlung mit Reports (Geraked, MIT) ist geschönt:** alle elf Reports
  laufen mit Grid und ohne Stop-Loss. Wir haben den Code trotzdem nach `third_party/` übernommen,
  weil er sich mit `Grid=false` sauber nachtesten lässt.
- **Teure Verkaufs-EAs** liefern entweder gar keine Testreihe, eine in-sample-Optimierung oder
  Zinseszins-Fantasiezahlen ($3.000 → $14,2 Mio.). Keiner davon ist ein Kauf.
- **Grundrauschen:** Papers With Backtest hat 4.843 veröffentlichte Strategien nachgerechnet;
  der Median erreicht Sharpe 0,37, und nur 48 % sind statistisch von null unterscheidbar.
  Das ist die realistische Messlatte für alles hier.

## Ranking für unseren Vergleich

| Rang | System | Plattform | Typ | Testreihe | Glaubw. | Lizenz/Preis | Was wir damit tun |
|---|---|---|---|---|---|---|---|
| 1 | [Gold Breakout EA (CodeBase 77691)](#3-gold-breakout-ea-xauusd-h4) | MT5, Quellcode | 20-Bar-Donchian + EMA200, 2 ATR Stop | 2020–2026, 198 Trades, PF 1,77, DD 11,4 %, Jahreswerte | ★★ | gratis, CodeBase | direkt gegen TurtleEA S1 auf XAUUSD H4 laufen lassen |
| 2 | [FXEA365 Donchian Trend Engine](#4-fxea365-donchian-trend-engine) | MT5, nur .ex5 | 40-Bar-Donchian Long, 2 ATR Stop | 2017–2026, 631 Trades, PF 1,50, DD 10,3 % | ★★ | gratis, Market | Benchmark USDJPY H1 gegen Turtle S1/S2 |
| 3 | [pysystemtrade (Carver)](#18-pysystemtrade--robert-carver) | Python | EWMAC-Trend + Carry, Futures | **Live-Konto 12 Jahre**, Sharpe 0,80 | ★★★ | GPL-3 | Referenz für Positionsgröße/Vol-Ziel (EWMAC-EA aus FremdeModelle.md) |
| 4 | [QuantConnect/Quantpedia-Bibliothek](#19-quantconnect-strategy-library--quantpedia) | Python/C# (LEAN) | Trend, Momentum, FX-Carry u. a. | Paper-Backtests + Out-of-sample auf QC | ★★–★★★ | LEAN Apache-2.0 | Multi-Asset-Ideen (GTAA, Asset-Class-Momentum) |
| 5 | [Geraked-EAs mit Grid=false](#1-geraked-metatrader5-11-eas-mit-reports) | MT5, Quellcode | 11 Indikator-Kombis M5–D1 | Reports 2019–2024, aber mit Grid | ⚠ / ★ | MIT, **im Repo** | ohne Grid neu testen; was übrig bleibt, ist die echte Signalqualität |
| 6 | [Faultline H4](#11-faultline-h4) | MT5, kostenpflichtig | H4-S/R-Ausbruch/-Fade, 28 FX-Paare | 2022–2026 in-sample, PF Ø 1,69, DD Ø 21 % | ★ | 149 USD | nur Idee (Fade auf FX), nicht kaufen |
| 7 | [Noise Band Momentum](#5-noise-band-momentum-nasdaq-100-intraday) | MT5, Quellcode | Intraday-Noise-Band-Ausbruch (Zarattini 2024) | 2015–2026, 2.880 Trades, +3,6 bp/Trade | ★★ | gratis, CodeBase | Kandidat für Intraday-Vergleich auf NAS100 |
| 8 | [Larry-Williams-Serie](#7-larry-williams-market-secrets-mql5-artikelserie) | MT5, Quellcode | Volatilitätsausbruch, Smash Day | nur 2025, nur Gold, ohne PF/DD | ★ | Artikel, Rechte bei MetaQuotes | Regelvorlagen; selbst über 2008–2025 testen |
| 9 | [MetaQuotes-Beispiele](#10-metaquotes-beispiel-eas-macd-sample-und-moving-average) | MT5, liegt bei | MACD-Kreuz, MA-Kreuz | keine | – | im Terminal | Null-Linie: jeder EA muss diese schlagen |

**Warnliste (nicht verwenden):** Waka Waka (−94,9 % live), Kingdom Hunter Gold
(Zinseszins-Backtest), Simple_Grid und andere Grid-EAs ohne Stop, Geraked-Reports wie
veröffentlicht. Details in den Abschnitten unten.

---

## A. MT5 – frei mit Quellcode

### 1. Geraked „metatrader5“ (11 EAs mit Reports)

**Quelle:** <https://github.com/geraked/metatrader5>, Autor „Geraked“ (Rabist). Erster Commit
23.08.2023, letzter 15.11.2025. Lizenz **MIT**. Jeder EA hat einen Ordner `Test/` mit
MT5-Report (`report.xlsx`), Tester-Einstellungen und `.set`-Datei.

**Was wir aus den Reports ausgelesen haben** (Startkapital jeweils 10.000 USD):

| EA | Signal | Symbol, TF, Zeitraum | Nettogewinn | PF | Balance-DD | **Equity-DD** | Trades | Grid-Einstellung |
|---|---|---|---|---|---|---|---|---|
| CEZLSMA | Chandelier Exit + ZLSMA auf Heikin Ashi | AUDUSD M15, 2019–08/2023 | 3.331.060 | 2,78 | 6,9 % | **31,9 %** | 1.010 | Mult 1,5, 50 Stufen, Risk 3 % |
| 2MAAOS | 2 MAs + Andean Oscillator | EURUSD H4, 2019–10/2023 | 1.151.871 | 2,85 | 16,3 % | **64,0 %** | 206 | Mult 1,3, 20 Stufen, Risk 5,5 % |
| NWERSIASF | Nadaraya-Watson + RSI + ATR-SL | EURUSD H2, 2019–10/2023 | 1.097.801 | 2,19 | 12,9 % | **52,8 %** | 1.008 | Mult 1,1, 20 Stufen |
| 3MAF | 3 MAs + Fractals | USDCAD M15, 02/2021–09/2023 | 429.367 | 2,05 | 12,5 % | **47,5 %** | 907 | Mult 1,5, 20 Stufen |
| COT1 | COT-Daten + SuperTrend | EURUSD D1, 2021–01/2024 | 429.635 | 3,65 | 13,8 % | **47,2 %** | 283 | Mult 1,2, 20 Stufen |
| LRCUTB | Lin.-Regr.-Kerzen + UT Bot | AUDCAD M15, 2019–10/2023 | 311.962 | 1,92 | 13,8 % | **47,8 %** | 1.677 | Mult 1,2, 50 Stufen |
| 2MACDSTO | 2 MACD + Stochastik | NZDUSD H3, 2020–10/2023 | 164.016 | 4,42 | 5,8 % | **24,5 %** | 296 | Mult 1,0, 50 Stufen |
| AFAOSMD | Average Force + AOS + MACD | NZDCAD M30, 2019–10/2023 | 128.374 | 2,34 | 13,5 % | **46,6 %** | 779 | Mult 1,1, 20 Stufen |
| 3MACD | 3 MACD (Scalping) | AUDUSD M5, 02/2021–09/2023 | 71.112 | 2,04 | 4,3 % | **18,9 %** | 2.518 | Mult 1,0, 50 Stufen |
| DHLAOS | Tageshoch/-tief + AOS | AUDUSD M5, 02/2021–09/2023 | 61.314 | 1,92 | 9,8 % | **36,6 %** | 1.123 | Mult 1,1, 50 Stufen |
| BBRSI | Bollinger + RSI | XAUUSD M5, 02/2021–09/2023 | 36.877 | 2,31 | 10,5 % | **35,7 %** | 401 | Mult 1,1, 20 Stufen |

**Analyse**
- In **allen elf** `.set`-Dateien steht `Grid=true`; dazu `IgnoreSL=true` (Default im Code).
  Verluste werden also nicht realisiert, sondern nachgekauft. Das erklärt die hohen
  Trefferquoten (64–84 %) und die Lücke zwischen Balance-DD (4–16 %) und Equity-DD (19–64 %).
- Der Autor warnt selbst im README, die Grid-Technik sei eingebaut, um die Profitabilität
  „forcefully“ zu erhöhen.
- Jeder EA wurde auf **genau ein** Symbol und einen Zeitraum von 2,5–5 Jahren optimiert,
  ohne Out-of-sample. Marktphasen 2008 und 2013–17 fehlen komplett.
- Positiv: sauberer, gut strukturierter MQL5-Code, alle Parameter offen, Testsetup
  reproduzierbar (Modell „Every tick“, 98–100 % History Quality).

**Eignung:** Signal-Logik ja, Ergebnisse nein. Code liegt jetzt unter
[`third_party/geraked-metatrader5/`](../third_party/geraked-metatrader5/) (ohne COT1, der
Windows-DLLs braucht). Testvorschlag: `Grid=false`, `IgnoreSL=false`, 1 % Risiko, 2008–2025.

### 2. MQL5-Championship-EAs (ATC 2011/2012)

**Quellen:** „Automated Trading Championship 2011: Trading Robots with an Open Source Code“,
MetaQuotes, 24.11.2011 (<https://www.mql5.com/en/forum/5412>); Liste der 25 ATC-2012-Teilnehmer
mit freiem EA, 01.10.2012 (<https://www.mql5.com/en/forum/8083>).

Einzelne EAs mit Code in der CodeBase:
- **cs2011** (Igor Korepin, 31.10.2011, <https://www.mql5.com/en/code/611>): MACD-Nulllinien- und
  Signallinien-Kreuz, EURUSD H1, „aggressives“ Aufstocken bis Maximalvolumen. Laut
  Forum die Version des ATC-2011-Siegers.
- **Jolly Roger** (Andrey Kornishkin, 19.07.2012, <https://www.mql5.com/en/code/919>): nur RSI(14)
  auf M5, TP 150 / SL 50. Ausdrücklich nicht der Original-ATC-EA.
- **KositBablo10** (Aleksandr Prishenko, 21.01.2013, <https://www.mql5.com/en/code/1433>):
  ATC-2012-Teilnehmer, TP/SL, Lot = freie Margin/20.000.

**Analyse:** Die Championship war ein echter Forward-Test (3 Monate, Demo, Echtzeit), also
methodisch wertvoll. Aber: drei Monate sind statistisch fast nichts, die Ergebnisse stehen
nur noch als Bilder online, und die Sieger setzten auf aggressive Positionsgrößen. Code
von 2011/12, teils mit veralteter MQL5-Syntax. **Eignung gering**, höchstens historisch.

### 3. Gold Breakout EA (XAUUSD H4)

**Quelle:** Ali Akbar, MQL5 CodeBase, 24.09.2026, <https://www.mql5.com/en/code/77691>.

**Regeln:** Long, wenn ein H4-Schluss das Hoch der letzten 20 Bars bricht **und** über der
EMA(200) liegt. Short standardmäßig aus. Stop 2 × ATR(20), 1 % Risiko pro Trade, eine Position.
Exit wählbar: 3-ATR-Trailing, 10-Bar-Kanal (Turtle) oder fester 2R-Ziel (Default).
Kein Grid/Martingale. Spread-Filter.

**Testreihe (Autor):** 01.01.2020–20.09.2026, MetaQuotes-Demo, 10.000 USD, „every tick from M1“
mit Spread und Swap. Netto +9.029,72 USD, **198 Trades**, Trefferquote 47 %, **PF 1,77**,
**Max-Equity-DD 11,4 %**, Recovery-Faktor 7,07. Jahre: 2020 +5,1 %, 2021 −2,9 %, 2022 +4,6 %,
2023 +4,8 %, 2024 +24,0 %, 2025 +27,1 %, 2026 bis Sept. +7,9 %.
Mit Shorts: PF 1,28, DD 14,3 %. Auf EURUSD H1: PF 1,03 (praktisch null).

**Analyse:** Ehrlich dokumentiert, inklusive Jahreswerten und Gegenproben. Aber: Gewinn
stammt zu über zwei Dritteln aus der Gold-Hausse 2024/25 – das ist eher „Long Gold mit Stop“
als ein robuster Ausbruch. Forum-Kritik: Kurvenanpassung an den Bullenmarkt. Kein Test vor 2020.

**Eignung: sehr gut** – fast identisch mit unserem Turtle S1 (20-Bar-Ausbruch, 2N-Stop,
10-Bar-Exit wählbar), aber mit EMA-200-Filter. Perfekter Kontrolltest: unser TurtleEA mit
ADX-Filter vs. dieser EA, gleiche Daten, 2008–2025.

### 4. FXEA365 Donchian Trend Engine

**Quelle:** Kenichiro Sakamoto (FXEA365), MQL5 Market (Free), 13.07.2026, Version 1.26 vom
10.10.2026, <https://www.mql5.com/en/market/product/185534>. Nur kompiliert (.ex5).

**Regeln:** Ausbruch aus 40-Bar-Donchian auf Schlusskursbasis, standardmäßig nur Long,
USDJPY H1. Stop 2 ATR, Trailing 8 ATR, maximal 60 Bars Haltedauer, 0,5 % Risiko.
Kein Grid/Martingale.

**Testreihe (Autor):** USDJPY H1, 01/2017–06/2026, Dukascopy-Echtticks, 10.000 USD:
**631 Trades, PF 1,50, Max-Equity-DD 10,3 %**. Kein Live-Konto. Autor schreibt selbst, dass die
Defaults auf EURUSD, Gold und anderen Symbolen **nicht** profitabel getestet wurden.

**Begleitanalyse des Autors** (20.10.2026, <https://www.mql5.com/en/blogs/post/778096>): Jahresaufteilung
seiner 8 EAs. Bei allen stammen 29–57 % des Gesamtgewinns aus einem einzigen Jahr. Das ist
ein seltener, ehrlicher Robustheitscheck – und zeigt, wie stark Ergebnisse an einzelnen
Marktphasen hängen.

**Eignung: gut als Benchmark.** Long-only auf USDJPY profitiert vom Carry und vom Yen-Trend
seit 2021 – daher unbedingt mit Turtle S2 (55-Bar) auf USDJPY vergleichen, beide Richtungen.

### 5. Noise Band Momentum (Nasdaq 100 intraday)

**Quelle:** Augusto Martin D'anna, MQL5 CodeBase, 21.11.2026, <https://www.mql5.com/en/code/79868>.
Grundlage: Zarattini, Aziz, Barbon (2024), „Beat the Market: An Effective Intraday Momentum
Strategy for S&P500 ETF (SPY)“, SSRN.

**Regeln:** „Noise-Band“ aus der durchschnittlichen Abweichung vom Sessionsopen zur gleichen
Uhrzeit (14 Sessions). Prüfung alle 30 Min. von 10:00–15:30 NY; Ausbruch über/unter Band →
Einstieg; Exit zurück im Band oder über VWAP; flat um 16:00. Kein TP, Notstopp optional.

**Testreihe (Autor):** NAS100, M1, CFD-Kosten, 2015–11/2026: **2.880 Trades, +3,6 Basispunkte
pro Trade**, 40 % Gewinner; 2024 +7,7 %, 2025 +8,1 %, 2026 +7,7 %. Ehrlicher Zusatz: auf S&P,
Dow, Gold, Silber, Öl, Bitcoin und acht FX-Paaren **verlustreich**. Python-Gegenprobe:
303 von 312 Einstiegen identisch.

**Analyse:** 3,6 bp pro Trade sind dünn – ein Spread von 1–2 Indexpunkten frisst das fast auf.
Dass nur ein Markt funktioniert, deutet auf Selektion hin. Dennoch: saubere Dokumentation
und bekannte Paper-Quelle. **Eignung mittel**, nur für unseren Intraday-Zweig.

### 6. Weitere CodeBase-EAs (kurz geprüft)

| EA | Quelle, Datum | Regeln | Testreihe | Urteil |
|---|---|---|---|---|
| Session Opening Range Breakout | <https://www.mql5.com/en/code/76153>, 15.08.2026 | 30-Min-Range nach Sessionsstart, 1 % Risiko, Stop gegenüberliegende Range, TP 2R | keine | ORB-Vorlage; siehe ORB in FremdeModelle.md (netto ≈ 0) |
| Easy Range Breakout | <https://www.mql5.com/en/code/71460>, 10.04.2026 | Range zwischen Stunden X–Y, Ausbruch, TP = Rangegröße | nur Bild, 2 Monate | ★, zu kurz |
| BreakRevertPro | <https://www.mql5.com/en/code/56773>, 09.03.2025 | Ausbruch + Mean Reversion über Verteilungsmodelle, ATR-Trailing | keine; Forum: „low profit factor“, nur Shorts | ★, undurchsichtig |
| Devil Trader AI Lite | <https://www.mql5.com/en/code/79905>, 22.11.2026 | Order-Blocks, XAUUSD M30/H1, ATR-Stop | nur Bild | ★, Marketing-Anmutung |
| Simple_Grid | <https://www.mql5.com/en/code/63244>, 01.10.2025 | Pending-Grid beidseitig, **kein Stop** | keine; Autor: „nicht für Echtgeld“ | ⚠ |

### 7. Larry Williams Market Secrets (MQL5-Artikelserie)

**Quelle:** Chacha Ian Maroa, MQL5-Artikel, Jan.–Feb. 2026, z. B.
Teil 4 (14.01.2026, <https://www.mql5.com/en/articles/20716>),
Teil 6 (22.01.2026, <https://www.mql5.com/en/articles/20862>),
Teil 8 (28.01.2026, <https://www.mql5.com/en/articles/21003>),
Teil 9 (02.02.2026, <https://www.mql5.com/en/articles/21063>),
Teil 10 (06.02.2026, <https://www.mql5.com/en/articles/21127>),
Teil 12 (25.02.2026, <https://mql5.com/en/articles/21228>).
Jeweils vollständiger EA-Quellcode als Anhang. Rechte bei MetaQuotes („Copying or reprinting
… prohibited“), daher **nur verlinkt**.

**Regeln (Auswahl):**
- *Volatilitätsausbruch (Teil 6):* Range = größere von |Hoch(t−3) − Tief(t−1)| und
  |Hoch(t−1) − Tief(t−3)|; Kauf bei Open + 0,5 × Range, Stop 0,5 × Range, Ziel 4R.
- *Smash Day (Teil 10/12):* Schluss unter dem Tief der Vortage, Einstieg beim Bruch des
  Smash-Day-Hochs, Stop am Smash-Tief, Ziel 3R; Teil 12 mit Supertrend- und Wochentagsfilter.
- *Swing-Punkte (Teil 4/8):* kurzfristige Swing-Tiefs nach Williams, optional Zeitfilter.

**Testreihe:** jeweils **nur 2025, nur Gold, D1**, 10.000 USD, 1–2 % Risiko. Beispiele: Teil 6
+4.450 USD (Trefferquote 48 %), Teil 10 +2.307 USD (64 %), Teil 8 +3.711 USD (55 %).
Teil 4 über 2024–11/2025: Gold +9.123, S&P 500 +158, Bitcoin +4.573, GBPUSD −279.
Kein Profitfaktor, kein Drawdown, keine Tradezahl im Text.

**Analyse:** Ein Jahr Gold-Hausse long-only ist kein Test. Wertvoll sind die sauber
umgesetzten Williams-Regeln (Originalquelle: L. Williams, *Long-Term Secrets to Short-Term
Trading*, 1999). **Eignung:** als Regelvorlage für einen eigenen „WilliamsBreakoutEA“, Test
über 2008–2025 auf mehreren Märkten.

## B. MT5 – frei, aber ohne Quellcode oder ohne Testreihe

### 8. EA31337 Libre

**Quelle:** <https://github.com/EA31337/EA31337-Libre>, letzter Commit 10.10.2024, **GPL-3**.
Multi-Strategie-EA für MT4/MT5 mit über 35 Indikator-Strategien
(<https://github.com/EA31337/EA31337-strategies>).

**Testreihe:** keine veröffentlichte Ergebnisreihe; nur CI-Badges „Backtest“ (läuft durch,
ohne Kennzahlen). Autor: „not suitable for real trading without relevant knowledge“.

**Eignung:** als Code-Steinbruch (GPL – Übernahme würde unser Repo GPL-pflichtig machen,
daher nur verlinkt). Für den Vergleich nicht nutzbar.

### 9. CommunityPower MT5 und Stock Index Trader

- **CommunityPower MT5** (Andrey Khatimlianskii, Market Free, 21.04.2020, v3.2 vom 06.03.2026,
  <https://www.mql5.com/en/market/product/48493>): Baukasten-EA, Bewertung 4,69 (113 Reviews).
  Laut Beschreibung „not a ready-to-use money-making machine“; Strategien kommen als
  `.set`-Dateien aus dem Forum. Keine Testreihe des Autors. **Nicht vergleichbar.**
- **Stock Index Trader EA** (Yuriy Kuzmin, Market Free, 01.12.2023,
  <https://www.mql5.com/en/market/product/109253>): Kerzenmuster (Engulfing, Piercing) auf US30
  und GBPUSD, M30/H1, Stop pro Order, kein Grid. **Kein veröffentlichter Backtest**; ein
  Reviewer meldet einen Gold-Absturz durch falsche Lotgröße. **Nicht vergleichbar.**

### 10. MetaQuotes-Beispiel-EAs (MACD Sample und Moving Average)

**Quelle:** MetaQuotes, liegen jeder MT5-Installation unter `MQL5/Experts/Examples/` bei;
MACD Sample in der CodeBase seit 02.06.2014 (<https://www.mql5.com/en/code/2154>).

- **MACD Sample:** MACD(12,26,9) kreuzt Signallinie unter/über null, EMA(26)-Richtung als Filter;
  TP 50 Pips, Trailing 30 Pips, **kein Anfangs-Stop**, 0,1 Lot fix.
- **Moving Average** (aus dem mitgelieferten Code, nicht aus einer Webquelle): Kerze kreuzt
  MA(12) mit Shift 6; Lot nach 2 % Risiko, nach Verlustserien verkleinert (DecreaseFactor 3).

**Testreihe:** keine veröffentlicht. **Eignung:** als Null-Linie. Kostet nichts, ist sofort
testbar – jeder fremde oder eigene EA muss diese beiden auf gleichen Daten klar schlagen.

## C. MT5 – kostenpflichtig (Verkäufer-Angaben)

### 11. Faultline H4

**Quelle:** Tigran Papyan, MQL5 Market, 01.08.2026 (v1.13 vom 02.08.2026),
<https://www.mql5.com/en/market/product/188611>. 149 USD Kauf, ab 49 USD Miete.

**Regeln:** H4-Bruch von Unterstützung/Widerstand auf 28 FX-Paaren; je Paar fest einkompiliert,
ob gefadet (20 Paare), gefolgt (2) oder gemischt (6). Fester ATR-Stop und TP, eine Position,
„no martingale, no grid“. Default-Risiko 3 %.

**Testreihe:** 28 Einzeltests 2022–07/2026, Echtticks, ohne Kommission, ausdrücklich
**in-sample**: PF 1,24–2,54 (Ø 1,69), Equity-DD 9–35 % (Ø 21 %), 3.157 Trades. Kein Live-Konto.

**Analyse:** Die Paar-für-Paar-Wahl „Fade oder Follow“ ist klassisches Overfitting – 28 × 2
Möglichkeiten, nachträglich die bessere gewählt. 3 % Risiko bei 21 % Ø-DD ist aggressiv.
**Eignung:** nicht kaufen; die Idee „Ausbruch auf FX eher faden“ ist aber testenswert
(passt zu Turtle Soup aus FremdeModelle.md).

### 12. Kingdom Hunter Gold ⚠

**Quelle:** Blog von Lewis Kosasih, 03.10.2026, <https://www.mql5.com/en/blogs/post/776851>;
Produkt <https://www.mql5.com/en/market/product/193298>. 599 USD.

**Testreihe:** XAUUSD H1, 01/2018–08/2026, Echtticks, **3.000 USD → 14.157.646 USD**,
7.359 Trades, PF 4,39, Equity-DD 33 %. 2025 allein: +2.320 %.

**Analyse:** Zinseszins mit steigender Lotgröße erzeugt Fantasiezahlen, die kein Broker
ausführen könnte (Liquidität, Lot-Limits). Gruppenpositionen mit „Profit-Leiter“ und
Zeitlimits statt klarem Einzelstopp deuten auf Averaging hin; ein Stop pro Trade wird nicht
genannt. Live-Signal verlinkt, aber ohne Zahlen. **Warnliste.**

### 13. Weitere Verkaufs-EAs mit Blog-Tests

| EA | Quelle, Datum | Testreihe | Urteil |
|---|---|---|---|
| SmartTrader Pro Gold | <https://www.mql5.com/en/blogs/post/773312>, 28.07.2026 | 3 Perioden 2025–26: PF 0,92 / 1,17 / 0,60, zusammen +227 USD bei ~3.000 Trades | ehrlich, aber **kein Edge** |
| TrendCandleEA (XAUUSD M30) | <https://www.mql5.com/en/blogs/post/775609>, 10.09.2026 | 01–09/2026: 98 Trades PF 2,65 bzw. 37 Trades PF 5,60 (alle Long) | ★, 8 Monate Gold-Hausse |
| Easy Trade Attack (EURUSD M1) | <https://www.mql5.com/en/blogs/post/777080>, 08.10.2026 | 2021–2026 Echtticks: 4.744 Trades, PF 1,23, DD 16,7 %; Autor: in-sample optimiert | ★, PF 1,23 auf M1 hält Kosten kaum aus |

### 14.–16. Valeriia Mishchenko (Waka Waka, Night Hunter Pro, Evening Scalper Pro)

Drei der meistverkauften MQL5-EAs (jeweils ca. 2.000–2.500 USD), mit echten Myfxbook-/MQL5-Signalen
– und deshalb die lehrreichste Testreihe dieser Recherche.

- **Waka Waka ⚠** – Grid auf AUDCAD/AUDNZD/NZDCAD M15. Offizielles MQL5-Signal
  (<https://www.mql5.com/en/signals/995287>, Start 06.05.2021, Stand 27.11.2026):
  **Wachstum −94,91 %, Max-DD 99,61 % (Balance)**, PF 1,03 bei 5.562 Trades, Trefferquote 74 %.
  Review vom 02.01.2026 (<https://newyorkcityservers.com/blog/waka-waka-ea-review>): Entwickler-DD
  über 40 % Anfang 2024, Nutzerkonten „completely depleted“. Lehrbuchbeispiel: hohe Trefferquote,
  jahrelang glatte Kurve, dann Totalverlust.
- **Night Hunter Pro** – Nacht-Scalper M5, fester Stop, kein Grid. Myfxbook seit 10/2020:
  +215 %, Max-DD ≈ 30 %; seit 2023 seitwärts; MQL5-Reviews Nov. 2024/Jan. 2025 melden
  Kontoverluste (Review 08.01.2026, <https://newyorkcityservers.com/blog/night-hunter-pro-review>).
- **Evening Scalper Pro** – Mean-Reversion-Scalper M5, Stop pro Trade. Myfxbook seit 05/2021:
  +54,8 %, **Max-DD 41 %, PF ≈ 1,0** (Review 19.12.2025,
  <https://newyorkcityservers.com/blog/evening-scalper-pro-review>).

**Analyse:** Auch ohne Grid erodiert der Scalping-Edge nach einigen Jahren (Spreads,
Broker-Ausführung, Regimewechsel). Deckt sich mit unserer Notiz „Kosten fressen Edge auf
kurzen TFs“. **Keiner geeignet.**

## D. Python und andere Plattformen

### 17. Freqtrade-Strategien und NostalgiaForInfinity (Krypto)

- **freqtrade-strategies** (<https://github.com/freqtrade/freqtrade-strategies>, GPL-3): Sammlung
  freier Strategien, ausdrücklich „starting point“, keine einheitliche Testreihe.
- **NostalgiaForInfinity** (<https://github.com/iterativv/NostalgiaForInfinity>, GPL-3): die
  bekannteste Freqtrade-Strategie, 5-Min-Krypto, 40–80 Paare; Backtests nur in
  Commit-Kommentaren, Strategie wird laufend nachoptimiert (Auto-Update-Skript).

**Eignung:** außerhalb unseres Fokus (Aktien, Metalle, FX), laufendes Nachoptimieren
macht jede historische Testreihe wertlos. Nur verlinkt.

### 18. pysystemtrade – Robert Carver

**Quelle:** <https://github.com/pst-group/pysystemtrade> (ursprünglich robcarver17, offen seit
Dezember 2015, seit Januar 2026 unter „pst-group“), **GPL-3**. Implementiert die Systeme aus
*Systematic Trading* (2015) und *Advanced Futures Trading Strategies* (2023):
EWMAC-Trendfolge, Carry, Volatilitätsziel, IB-Anbindung.

**Testreihe – live:** „Annual performance update – year 12“, 15.04.2026
(<https://qoppac.blogspot.com/2026/04/annual-performance-update-year-12.html>): eigenes
Futures-Konto, Mittel 13,8 % p. a., Volatilität 17,3 %, **Sharpe 0,80** (SG-CTA-Index 0,54,
AHL 0,52), Korrelation zum SG-CTA 0,68. Letztes Steuerjahr Futures +23,7 %, davor −16,3 %.

**Analyse:** Die glaubwürdigste Testreihe der ganzen Recherche – echtes Geld, 12 Jahre,
Verluste offen ausgewiesen, Code identisch mit dem, was er handelt. Aber: Futures-Portfolio
mit vielen Märkten, nicht 1:1 auf einen MT5-CFD-Account übertragbar.

**Eignung:** Referenz für unseren geplanten Carver-EWMAC-EA (FremdeModelle.md Nr. 4) und für
den optionalen Python-Backtester. GPL → nur verlinkt.

### 19. QuantConnect Strategy Library / Quantpedia

**Quellen:** Kooperation angekündigt 23.07.2018
(<https://quantpedia.com/announcing-quantconnect-quantpedia-cooperation/>); Bibliothek
<https://www.quantconnect.com/docs/v2/writing-algorithms/strategy-library>. Engine LEAN unter
**Apache-2.0** (<https://github.com/QuantConnect/Lean>).

Relevante fertige Implementierungen (je mit Code und QC-Backtest): Asset Class Trend Following,
Asset Class Momentum, Sector Momentum, Forex Carry Trade, Forex Momentum, Momentum in
Commodities, Term Structure in Commodities, Mean Reversion in Country Indexes, Pairs Trading,
Dual Thrust, Dynamic Breakout II.

**Beispiel Asset Class Trend Following** (<https://quantpedia.com/strategies/asset-class-trend-following>):
fünf ETFs (SPY, EFA, BND, VNQ, GSG), halten nur über 10-Monats-SMA, monatlich. Paper-Werte
(Faber, 1973–2008): 11,27 % p. a., Vol 6,87 %, Max-DD −29,43 %, Sharpe 1,06, ohne Kosten.
Out-of-sample-Backtest auf QuantConnect verlinkt.

**Eignung:** gut für Multi-Asset-Ideen, die in MT5 schwer zu testen sind. Code-Lizenz der
einzelnen Bibliotheksbeispiele nicht ausdrücklich angegeben → nur verlinkt.

### 20. Papers With Backtest / awesome-systematic-trading (Meta-Quelle)

**Quelle:** <https://github.com/paperswithbacktest/awesome-systematic-trading> (README, abgerufen
27.11.2026). Kein einzelnes System, sondern eine Replikation von **4.843** veröffentlichten
Strategien über ihre volle Historie: Median-Sharpe **0,37**, nur **48 %** mit t-Wert > 1,96,
Median-Beta zum S&P 500 +0,17. Nach Veröffentlichung kein messbarer Verfall.

**Bedeutung für uns:** Ein EA, der im Backtest Sharpe > 1,5 oder PF > 2,5 zeigt, ist
eher überoptimiert als gut. Realistisch sind Sharpe 0,4–0,8 nach Kosten.

---

## Prüfraster (wie wir fremde EAs bewerten)

1. **Stop-Loss pro Trade vorhanden?** Nein → raus (Grid/Martingale-Verdacht).
2. **Equity-DD ≫ Balance-DD?** Faktor > 2 → offene Verluste werden versteckt.
3. **Trefferquote > 70 % bei PF < 1,5?** Typisch für Averaging; Crash-Risiko.
4. **Mindestens 200 Trades und 8 Jahre inkl. 2008 oder 2020?** Sonst ★.
5. **Out-of-sample oder Live-Signal?** Ohne → maximal ★★.
6. **Mehr als ein Markt profitabel?** Nur ein Symbol → Selektionsverdacht.
7. **Zinseszins-Endkapital in Millionen?** Ignorieren, auf PF/DD/Trades schauen.
8. **Gewinnkonzentration:** > 50 % aus einem Jahr → Regime-Wette, nicht Strategie.

## Empfehlung und nächste Schritte

1. **Gold Breakout EA** (CodeBase 77691) herunterladen und mit TurtleEA S1 + ADX-Filter auf
   XAUUSD H4 vergleichen, 2008–2025, gleiche Kosten. Das ist der direkteste Test, ob unser
   Turtle mit Filter mithält.
2. **FXEA365 Donchian Trend Engine** (gratis .ex5) gegen Turtle S2 auf USDJPY H1, beide
   Richtungen.
3. **Geraked-EAs** aus `third_party/` mit `Grid=false`, `IgnoreSL=false`, 1 % Risiko
   nachtesten. Erwartung: die meisten fallen auf PF ≈ 1. Was übrig bleibt, ist ein echter Kandidat.
4. **MACD Sample und Moving Average** als Null-Linie im selben Testlauf.
5. Für Multi-Asset (GTAA, Carver-EWMAC) den optionalen Python-Backtester angehen, mit
   pysystemtrade bzw. QuantConnect als Referenzergebnis.

Bewusst **nicht** empfohlen: alle Verkaufs-EAs dieser Liste und jeder EA ohne Stop-Loss.
