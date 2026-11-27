# 10 fremde Handelsmodelle – Analyse

Stand: 27.11.2026. Ausgewählt wurden zehn öffentlich dokumentierte Modelle anderer Autoren,
die sich **nicht** mit unseren fünf EAs doppeln (Turtle S1/S2, EMA-50/200-Kreuzung,
Keltner-Ausbruch, RSI(2)-Mean-Reversion, 12-Monats-Zeitreihen-Momentum).

Bei jedem Modell stehen **Quelle und Datum der Erstveröffentlichung**. Die Performance-Zahlen
stammen aus den Originalquellen oder aus Sekundärquellen, die angegeben sind. Fast alle
Zahlen sind **Backtests vor Kosten und Steuern**; wo unabhängige Nachtests oder Kritik
existieren, steht das dabei. Was nicht verifiziert werden konnte, ist als solches markiert.

## Kurzübersicht

| # | Modell | Autor(en) | Erstveröffentlichung | Typ | Zeitrahmen | Kosten­empfindlich | MT5-Eignung |
|---|---|---|---|---|---|---|---|
| 1 | GTAA / 10-Monats-SMA | Mebane Faber | 2006 (White Paper), 2007 (J. of Wealth Management) | Trend, Asset Allocation | Monat | sehr gering | mittel (Multi-Symbol) |
| 2 | Dual Momentum (GEM) | Gary Antonacci | 2012 (SSRN), Buch 2014 | relatives + absolutes Momentum | Monat | sehr gering | mittel (Multi-Symbol) |
| 3 | Stocks on the Move | Andreas Clenow | 2015 (Buch) | Aktien-Querschnittsmomentum | Tag/Woche | gering | schwierig (500 Aktien) |
| 4 | EWMAC + Volatilitätsziel | Robert Carver | 2015 (Buch „Systematic Trading“) | Trend, kontinuierliche Positionsgröße | Tag | gering | gut |
| 5 | Triple Screen | Alexander Elder | 1986 (Futures Magazine), Buch 1993 | Trend + Pullback, Multi-Timeframe | W1/D1/H4 o. D1/H1/M15 | mittel | gut |
| 6 | Turtle Soup | L. Connors, L. Raschke | 1995 („Street Smarts“) | Fehlausbruch (Anti-Turtle) | Tag, auch Intraday | mittel–hoch | sehr gut |
| 7 | Holy Grail | L. Raschke (in „Street Smarts“) | 1995 | Pullback im starken Trend | Tag, H1–H4 | mittel | sehr gut |
| 8 | Opening Range Breakout | T. Crabel; C. Zarattini, A. Aziz | 1990 (Crabel); 2023 (SSRN) | Intraday-Ausbruch | M5–M30 | **sehr hoch** | gut |
| 9 | Ichimoku Kinko Hyo | Goichi Hosoda | 1969 (Buchreihe) | Trend, Wolke als Filter | H4–D1 | mittel | sehr gut |
| 10 | Saisonalität (Halloween + Monatswechsel) | Bouman/Jacobsen; Lakonishok/Smidt; McConnell/Xu | 1988, 2002, 2008 | Kalendereffekt | Tag | gering | sehr gut |

---

## 1. Global Tactical Asset Allocation (GTAA) – 10-Monats-SMA

**Quelle:** Mebane T. Faber, *„A Quantitative Approach to Tactical Asset Allocation“*,
White Paper 2006, veröffentlicht in *The Journal of Wealth Management*, Frühjahr 2007;
aktualisierte Fassung mit Daten bis 2012 (SSRN 962461, Update 2013). Laut Bloomberg/ThinkAdvisor
(02.09.2015) eines der meistgeladenen SSRN-Papiere überhaupt.

**Regeln**
- Fünf Anlageklassen gleichgewichtet: US-Aktien, Auslandsaktien, Anleihen, REITs, Rohstoffe.
- Am Monatsende: Schlusskurs über dem 10-Monats-SMA → halten, sonst Cash (T-Bills).
- Monatliches Rebalancing, nur Long.

**Belegte Performance** (Quantpedia nach Exhibit 19 des Papers, 1973–2008, ohne Kosten):
11,3 % p. a., Volatilität 6,9 %, Max-Drawdown −29 %, Sharpe 1,06. Gegenüber Buy-and-Hold
deutlich geringere Volatilität und Drawdowns bei ähnlicher Rendite.

**Kritik / Robustheit:** Zakamulin (SSRN 2242795, 2013) findet Data-Mining-Bias; mit
Out-of-Sample-Test und realistischen Kosten ist das Timing „nur geringfügig besser“ als
passiv. Der Hauptnutzen ist die **Drawdown-Reduktion**, nicht Mehrrendite.

**Marktphasen:** 2008 stark (rechtzeitig in Cash), 2013–17 leicht schwächer als Buy-and-Hold
(Fehlsignale), 2020 schwach (V-Erholung, Wiedereinstieg spät), 2022 gut bei Aktien,
aber Anleihen fielen gleichzeitig – Cash war dann die einzige sichere Seite.

**Vor-/Nachteile:** + extrem einfach, kaum Parameter, sehr wenige Trades.
− nur Long, langsam, braucht mehrere Anlageklassen, um zu wirken.

**MT5-Umsetzung:** Möglich als Multi-Symbol-EA (z. B. US500, EU-Index, Bund/Treasury-CFD, Gold,
Öl/Rohstoffindex) mit Monats-SMA. Nähe zu unserem `MomentumEA`, aber andere Logik (SMA-Filter
statt Renditevorzeichen, nur Long, gleichgewichtetes Portfolio). Strategietester kann
Multi-Symbol, die Datenhistorie der CFDs ist aber oft kurz.

## 2. Dual Momentum / Global Equities Momentum (GEM)

**Quelle:** Gary Antonacci, *„Risk Premia Harvesting Through Dual Momentum“*, SSRN 2042750,
2012; Buch *„Dual Momentum Investing“*,
McGraw-Hill, Nov. 2014.

**Regeln (GEM)**
- Monatlich: Vergleiche 12-Monats-Rendite von US-Aktien (S&P 500) und Welt ex-US (ACWI ex-US)
  → stärkeren nehmen (**relatives Momentum**).
- Nur halten, wenn dessen 12-Monats-Rendite über der von T-Bills liegt (**absolutes Momentum**),
  sonst US-Aggregate-Anleihen.

**Belegte Performance** (CXO Advisory, 14.10.2014, nach dem Buch, 1974–2013, ohne Kosten):
17,4 % p. a. vs. 9,6 % ACWI, Volatilität 12,6 %, Sharpe 0,87, Max-Drawdown −22,7 %.
Erweiterter Test von ReSolve (Advisor Perspectives, 06.05.2019, 1950–2018): 14,9 % p. a.,
Sharpe 0,9.

**Kritik / Robustheit:** ReSolve testete 1 226 Varianten (1–18 Monate Lookback): die
Originalvariante schlägt die anderen nur in 61 % der Bootstrap-Fälle → Wahl „12 Monate“ ist
teils Glück. Ein Ensemble mehrerer Lookbacks liefert ähnliche Rendite bei geringerem Drawdown
(Sharpe 0,93, Ø Max-DD −13 %). Großteil der Stichprobe fiel in einen Anleihe-Bullenmarkt;
2022 (Aktien und Anleihen fallen) ist der Härtetest.

**Marktphasen:** 2008 gut (Wechsel in Anleihen), 2020 Wiedereinstieg spät, 2022 Verluste
durch Anleihen als „sicheren Hafen“.

**Vor-/Nachteile:** + sehr wenige Trades, kombiniert Querschnitt und Trend.
− Ergebnis hängt an 3 Instrumenten, Rebalancing-Tag und Lookback stark.

**MT5-Umsetzung:** Wie GTAA als Multi-Symbol-EA, Unterschied zu `MomentumEA`: Auswahl des
**stärksten** Markts statt jedes Markts einzeln. Gut als Ensemble (3/6/9/12 Monate) umsetzbar.

## 3. Stocks on the Move (Clenow-Momentum)

**Quelle:** Andreas F. Clenow, *„Stocks on the Move: Beating the Market with Hedge Fund
Momentum Strategies“*, Eigenverlag, 2015.

**Regeln**
- Universum S&P-500-Aktien; Rang nach **annualisierter Steigung × R²** einer
  exponentiellen (log-)Regression über 90 Tage.
- Ausschluss: Kurs unter 100-Tage-SMA oder Tagesgap > 15 % in den letzten 90 Tagen.
- Neue Käufe nur, wenn der S&P 500 über seinem 200-Tage-SMA liegt.
- Positionsgröße nach ATR (Risikoparität), wöchentliche Auswahl (Mittwoch), Größen-Rebalancing
  alle zwei Wochen; Portfolio von etwa 10–30 Titeln.

**Belegte Performance:** Das Buch zeigt einen Backtest 1999–2014 mit etwa doppelter
Index-Rendite bei geringerem Drawdown (Zahl aus dem Buch, nicht unabhängig verifiziert).
Nachbau von Chris Chow (10.11.2018, vereinfacht, 60 Tage, Top 10, ohne Kosten): 8,7 % p. a.
bei 8,5 % Volatilität und −11,7 % Max-DD vs. S&P 500 8,6 % / 15,0 % / −27,3 %; also
**gleiche Rendite, halbes Risiko**, aber keine signifikante Vorhersagekraft auf 5 Tage.

**Marktphasen:** Bullenmärkte stark (2013–17), Index-Filter schützt 2008 und 2022, 2020
Wiedereinstieg spät. Typische Momentum-Crashs bei scharfen Umkehrungen (z. B. 2009).

**MT5-Umsetzung:** Schwierig. Braucht 500 Aktien mit sauberer, survivorship-freier Historie,
was MT5-Broker selten bieten. Die **Ranking-Kennzahl Steigung × R²** ist aber
wiederverwendbar: als Trendqualitäts-Filter für unsere Breakout-EAs (Alternative zu ADX).
Für das eigentliche Modell ist ein Python-Backtester besser geeignet.

## 4. EWMAC mit Forecast-Skalierung und Volatilitätsziel (Carver)

**Quelle:** Robert Carver, *„Systematic Trading: A Unique New Method for Designing Trading and
Investing Systems“*, Harriman House, 2015; Open-Source-Implementierung *pysystemtrade* und
Blog *qoppac.blogspot.com* (seit 2015). Folgebuch *„Advanced Futures Trading Strategies“*, 2023.

**Regeln**
- Signal = (EMA schnell − EMA langsam) / Volatilität, in mehreren Geschwindigkeiten
  (z. B. 8/32, 16/64, 32/128, 64/256).
- Jedes Signal wird auf einen **Forecast** mit Ø-Betrag 10 skaliert und auf ±20 begrenzt;
  Forecasts werden gewichtet kombiniert.
- Positionsgröße **proportional zum Forecast** und zu einem Jahres-Volatilitätsziel
  (z. B. 20–25 %), täglich angepasst mit Puffer gegen Mini-Trades. Kein fester Stop.

**Belegte Performance:** Carver nennt für sein Gesamtsystem (~45 Futures, 8 Regeln,
30 Varianten) im 35-Jahres-Backtest ein **Sharpe von etwa 1,0 nach Kosten** und rät, für
die Zukunft mit 0,75 × Backtest zu rechnen (CXO Advisory, 30.09.2015). Carver handelt das
System seit 2014 mit eigenem Geld und veröffentlicht laufend Ergebnisse auf seinem Blog.

**Marktphasen:** Wie alle Trendfolger stark 2008, 2014, 2022; schwach 2012–2013 und
2015–2019. Mehrere Geschwindigkeiten glätten die Kurve gegenüber einem einzelnen Crossover.

**Unterschied zu unserem `MACrossEA`:** nicht Ein/Aus, sondern **kontinuierliche
Positionsgröße**; mehrere Geschwindigkeiten statt einer; Volatilitätsziel statt Stop.

**MT5-Umsetzung:** Gut machbar, pro Symbol ein EA, der die Zielposition täglich neu
berechnet und nur bei Abweichung > 10 % nachjustiert. Hauptproblem: Mindestlot bei kleinen
Konten verhindert feine Abstufung. Teile davon (Volatilitätsziel, Forecast-Kappung) sind
auch für unsere bestehenden EAs als Positionsgrößen-Modul nützlich.

## 5. Triple Screen (Elder)

**Quelle:** Alexander Elder, Artikel in *Futures Magazine*, April 1986; ausführlich in
*„Trading for a Living“*, Wiley, 1993, und *„The New Trading for a Living“*, 2014.

**Regeln**
1. **Bildschirm 1 (langer TF, z. B. W1):** Trendrichtung über Steigung der 13-Perioden-EMA
   oder MACD-Histogramm. Nur in diese Richtung handeln.
2. **Bildschirm 2 (mittlerer TF, z. B. D1):** Oszillator (Force Index, Stochastik oder
   Williams %R) zeigt Gegenbewegung – im Aufwärtstrend überverkauft → Kaufbereitschaft.
3. **Bildschirm 3 (Einstieg):** Buy-Stop über dem Hoch des Vortags (Trailing-Buy-Stop),
   Stop unter dem letzten Tief. Elder-Regel: max. 2 % Risiko je Trade, 6 % je Monat.

**Belegte Performance:** Keine peer-reviewten oder systematisch veröffentlichten Backtests
gefunden; Elder selbst veröffentlicht keine. Es ist eher ein **Rahmen** als ein
geschlossenes System. Bewertung daher: Wirksamkeit ungeprüft.

**Marktphasen:** Im Trend mit Rücksetzern gut (2013–17 bei Indizes), in Seitwärtsphasen
viele kleine Verluste, in V-Umkehrungen (2020) zu spät.

**Unterschied zu unseren Modellen:** Kombiniert Trendrichtung eines höheren Zeitrahmens mit
Pullback-Einstieg – das haben wir noch nicht. Unser `MeanReversionEA` mit SMA(200)-Filter ist
die nächste Verwandte, aber auf einem Zeitrahmen.

**MT5-Umsetzung:** Gut, MT5 kann mehrere Zeitrahmen in einem EA abfragen. Passt zu Stefans
Ziel „Zeitrahmen Tag bis Minute“: das Modell skaliert natürlich (W1/D1/H4 bis H1/M15/M5).

## 6. Turtle Soup (Connors/Raschke)

**Quelle:** Laurence A. Connors und Linda Bradford Raschke, *„Street Smarts: High Probability
Short-Term Trading Strategies“*, M. Gordon Publishing, 1995. Der Name ist eine bewusste
Anspielung auf die Turtle-Regeln.

**Regeln (Long, Short spiegelbildlich)**
- Heute neues 20-Tage-Tief, das vorherige 20-Tage-Tief liegt **mindestens 4 Tage** zurück.
- Kauf-Stop knapp über dem **vorherigen** 20-Tage-Tief (also wenn der Ausbruch scheitert).
- Stop knapp unter dem heutigen Tief; Teilgewinne nach 2–6 Bars, Rest mit Trailing-Stop.
- Variante „Turtle Soup Plus One“: Signal erst am Folgetag nach Schluss unter dem alten Tief.

**Belegte Performance:** Oxford Capital Strategies (23./25.07.2012) testete beide Varianten
auf 42 Futures 1980–2011 mit 1 % Risiko und bewertet das Ergebnis mit „D“ (schwach, nach
Kosten kaum profitabel). Die Autoren selbst zeigten 1995 nur Chartbeispiele, keine
Systemstatistik. Gilt als **Setup, das vom Marktumfeld abhängt**: gut in Seitwärtsphasen.

**Marktphasen:** Genau umgekehrt zu Turtle: verdient 2013–17 (FX seitwärts), verliert 2008,
2022 (echte Ausbrüche laufen weiter).

**Warum interessant für uns:** Es ist der natürliche **Hedge zum TurtleEA**. Der Code ist fast
derselbe (20-Bar-Donchian), nur das Signal wird umgedreht. Im Portfolio mit Turtle
interessant, um zu messen, wie viele unserer Turtle-Ausbrüche fehlschlagen.

**MT5-Umsetzung:** Sehr einfach, nutzt `StrategyCommon.mqh` und Donchian-Logik aus `TurtleEA`.
Kostenempfindlichkeit mittel–hoch, weil die Gewinne kurz und klein sind.

## 7. Holy Grail (Raschke)

**Quelle:** Laurence A. Connors und Linda Bradford Raschke, *„Street Smarts“*, 1995
(Kapitel „The Holy Grail“).

**Regeln (Long, Short spiegelbildlich)**
- ADX(14) > 30 und steigend, +DI > −DI (starker Trend).
- Rücksetzer bis an die EMA(20).
- Kauf-Stop über dem Hoch der Bar, die die EMA berührt hat; Stop unter deren Tief.
- Ausstieg am letzten Swing-Hoch bzw. mit Trailing-Stop.

**Belegte Performance:** Die Autoren zeigen Beispiele, keine Statistik. Unabhängige Tests
in Foren und bei Anbietern (TradingView-Skripte, Blogtests) sind uneinheitlich; keine
belastbare Studie gefunden. Wirksamkeit **unbelegt**.

**Marktphasen:** Nur in klaren Trends aktiv (ADX > 30), dadurch wenige Trades in
Seitwärtsphasen. Schwäche: Trendende – der erste Rücksetzer nach dem Hoch ist oft die Wende.

**Warum interessant für uns:** Nutzt genau den ADX-Filter, den wir schon in `TurtleEA` haben,
aber als **Pullback-Einstieg** statt Ausbruch → besseres Chance-Risiko-Verhältnis, enger Stop.
Ergänzt Turtle (gleicher Trend, anderer Einstieg).

**MT5-Umsetzung:** Sehr einfach (iADX, iMA). Läuft auf D1 bis H1.

## 8. Opening Range Breakout (ORB)

**Quelle:** Toby Crabel, *„Day Trading with Short Term Price Patterns and Opening Range
Breakout“*, Traders Press, 1990. Aktuelle Studie: Carlo Zarattini und Andrew Aziz,
*„Can Day Trading Really Be Profitable?“*, SSRN 4416622, geschrieben 10.04.2023, online
24.04.2023, überarbeitet 22.09.2025. Verwandt: Larry Williams' „Volatility Breakout“
(Eröffnung ± k × Vortagesspanne), *„How I Made One Million Dollars Last Year Trading
Commodities“*, 1973.

**Regeln (Zarattini/Aziz, laut CXO Advisory 08.05.2023)**
- QQQ, erste 5-Minuten-Kerze: steigt sie → Long, fällt sie → Short zu Beginn der 2. Kerze.
  Kein Trade bei Doji.
- Stop am Tief (Hoch) der ersten Kerze; Ziel 10 × Risiko; sonst Ausstieg zum Handelsschluss.
- 1 % Risiko je Trade, max. 4-facher Hebel.

**Belegte Performance:** 2016–2023, 1 795 Trades: 33 % p. a. vs. 14,9 % für QQQ,
„annualisiertes Alpha 33 % nach Kommission“; Kosten nur Kommission, **ohne Spread und Slippage**.

**Kritik / Robustheit:** Nachbau auf MQL5 (T. Krueger, 25.09.2026, nicht begutachtet,
Autor verkauft eigene Produkte) auf NQ, SPX, Dow, DAX, FTSE als CFD, 2015–2026, Regeln
unverändert: **brutto bestätigt** (NQ +0,13 R je Trade, Trefferquote 23 %), **netto null**
nach Spread und Slippage (NQ +0,00 R, die anderen vier negativ). Die Kante existiert,
ist aber kleiner als die Handelskosten beim Retail-Broker.

**Marktphasen:** Profitiert von volatilen Tagen (2020, 2022), leidet in ruhigen Phasen.

**Warum trotzdem auf der Liste:** Es ist das am besten dokumentierte **Minutenmodell** – und
Stefans Ziel umfasst Minuten-Zeitrahmen. Der Test zeigt genau die bekannte Einschränkung
„Kosten fressen die Edge auf kurzen TFs“.

**MT5-Umsetzung:** Gut machbar (M5, Sessionzeiten als Parameter). Muss mit echten Ticks und
realem Spread getestet werden; nur bei Broker mit sehr engen Index-Spreads sinnvoll.

## 9. Ichimoku Kinko Hyo

**Quelle:** Goichi Hosoda (Pseudonym „Ichimoku Sanjin“), entwickelt ab den 1930er-Jahren,
veröffentlicht 1969 in einer mehrbändigen Buchreihe in Japan. Wissenschaftlicher Test:
Deng, Yu, Wei, Yang, Tatsuro, *„The profitability of Ichimoku Kinkohyo based trading rules in
stock markets and FX markets“*, International Journal of Finance & Economics 26(4),
S. 5321–5336, online Feb. 2021.

**Regeln (klassisch, Parameter 9/26/52)**
- Long, wenn Kurs über der Wolke (Senkou Span A/B), Tenkan-sen kreuzt Kijun-sen nach oben
  und Chikou Span über dem Kurs von vor 26 Bars. Short spiegelbildlich.
- Stop/Ausstieg an Kijun-sen oder Wolkenrand.

**Belegte Performance (Deng et al. 2021):** 4 Aktienindizes 1995–2018 und 4 Währungspaare
2003–2018. Standardparameter im ersten Teilzeitraum teils profitabel, im zweiten **nicht
mehr konsistent**. Mit optimierten Parametern einige profitable Varianten bei Aktienindizes,
**keine bei Währungen**.

**Marktphasen:** Trendfolger: gut 2008 und 2022, schwach in Seitwärtsmärkten (Kurs pendelt
in der Wolke).

**Vor-/Nachteile:** + Wolke ist ein natürlicher Trendfilter, populär, eingebaut in MT5.
− viele Parameter und Bedingungen, Ergebnisse in der Literatur gemischt, bei FX schwach.

**MT5-Umsetzung:** Sehr einfach mit `iIchimoku`. Am nützlichsten wohl als **weiterer
Filter** (Kurs über/unter Wolke) für die bestehenden EAs statt als eigenes Modell.

## 10. Saisonalität: Halloween-Effekt und Monatswechsel

**Quellen**
- Sven Bouman und Ben Jacobsen, *„The Halloween Indicator, ‚Sell in May and Go Away‘:
  Another Puzzle“*, American Economic Review 92(5), S. 1618–1635, Dezember 2002.
- Ben Jacobsen und Cherry Y. Zhang, *„The Halloween Indicator: Everywhere and All the
  Time“*, SSRN 2154873, ca. 2012 (genaues Datum nicht verifiziert; Daten bis 11/2011).
- Josef Lakonishok und Seymour Smidt, *„Are Seasonal Anomalies Real? A Ninety-Year
  Perspective“*, Review of Financial Studies 1(4), 1988 (Monatswechsel-Effekt).
- John J. McConnell und Wei Xu, *„Equity Returns at the Turn of the Month“*, Financial
  Analysts Journal 64(2), S. 49–64, März 2008.

**Regeln**
- **Halloween:** Aktienindex Long von Anfang November bis Ende April, Mai–Oktober Cash.
- **Monatswechsel:** Long vom letzten Handelstag des Monats bis zum 3. Handelstag des neuen
  Monats (übliche Definition nach Lakonishok/Smidt; Fenster bei McConnell/Xu nicht im
  frei zugänglichen Abstract).

**Belegte Performance**
- Bouman/Jacobsen: Sommerrenditen niedriger als Winterrenditen in **36 von 37 Ländern**
  (1970–1998).
- Jacobsen/Zhang: 108 Länder, 319 Jahre (UK seit 1693): Nov–Apr im Schnitt **4,5 %-Punkte**
  höher als Mai–Okt (t = 9,7), in den letzten 50 Jahren 6,3 %-Punkte. Out-of-Sample
  1998–2011 in allen 37 Ursprungsländern positiv, 15 signifikant.
- McConnell/Xu: US-Aktien 1926–2005 – **außerhalb des Monatswechsels gab es im Schnitt keine
  Risikoprämie**; Effekt in 31 von 35 Ländern; nicht auf kleine Werte oder Jahresende beschränkt.

**Marktphasen:** Halloween hätte 2008 (Mai–Okt Crash) geholfen; 2020 (Crash im März,
Erholung im Sommer) geschadet. Monatswechsel ist phasenunabhängig, aber kleine Gewinne.

**Vor-/Nachteile:** + am besten belegte Anomalien hier, wenige Trades, nicht mit Trends
korreliert. − Effekt nur bei Aktienindizes, nicht bei FX/Metallen; Monatswechsel bringt
wenige Basispunkte pro Trade → Swap- und Spreadkosten bei CFDs prüfen.

**MT5-Umsetzung:** Sehr einfach (Datumslogik). Gut als **Filter**: z. B. Long-Signale der
Trend-EAs in Indizes nur Nov–Apr zulassen, oder Positionsgröße im Monatswechsel erhöhen.

---

## Weitere geprüfte, aber nicht aufgenommene Modelle

- **FX-Carry** (Lustig/Roussanov/Verdelhan 2011): gut belegt, aber in MT5 hängt das Ergebnis
  am Swap des Brokers, und Crash-Risiko (2008) ist hoch. Kandidat für später bei FX.
- **Pairs Trading** (Gatev, Goetzmann, Rouwenhorst 2006): braucht viele Aktien und
  Leerverkauf, besser in Python.
- **Bollinger-Squeeze, Connors-RSI, Double 7s:** doppeln sich zu stark mit Keltner bzw.
  RSI(2)-Mean-Reversion.

## Vergleich nach unseren Testachsen

| Modell | Zeitrahmen Tag→Minute | Aktien | Metalle | FX | 2008 | 2013–17 | 2020 | 2022 |
|---|---|---|---|---|---|---|---|---|
| GTAA | nur Monat | ✓ | ✓ | – | + | o | − | o |
| Dual Momentum | nur Monat | ✓ | – | – | + | + | − | − |
| Clenow | D1/W1 | ✓ | – | – | + (Filter) | + | − | + (Filter) |
| Carver EWMAC | D1 | ✓ | ✓ | ✓ | + | − | o | + |
| Triple Screen | W1 bis M5 | ✓ | ✓ | ✓ | o | + | − | o |
| Turtle Soup | D1 bis M15 | ✓ | ✓ | ✓ | − | + | o | − |
| Holy Grail | D1 bis H1 | ✓ | ✓ | ✓ | + | o | o | + |
| ORB | M5–M30 | ✓ (Indizes) | ? | ? | ? | ? | + | + |
| Ichimoku | H4/D1 | ✓ | o | − | + | − | o | + |
| Saisonalität | D1 | ✓ (Indizes) | – | – | + | o | − | o |

+ = günstig, o = neutral, − = ungünstig, ? = keine Daten. Die Einträge zu den Marktphasen
sind eine Einschätzung aus der Modelllogik und den Quellen, keine eigenen Backtests.

## Empfehlung: die nächsten 2–3 Modelle

1. **Turtle Soup + Holy Grail als Paar** (beide aus „Street Smarts“, 1995). Sie nutzen
   die Bausteine, die wir schon haben (Donchian, ADX, EMA, ATR), sind in einem Tag gebaut
   und direkt mit `TurtleEA` vergleichbar: Turtle Soup testet die **Gegenhypothese**
   (Ausbrüche scheitern), Holy Grail einen **besseren Einstieg im Trend**. Schwäche: kaum
   belastbare veröffentlichte Statistik – unsere eigenen Tests wären hier echter Erkenntnisgewinn.
2. **Carver EWMAC mit Volatilitätsziel** (2015). Die am besten dokumentierte und
   vom Autor live gehandelte Trendvariante; bringt mit kontinuierlicher Positionsgröße und
   mehreren Geschwindigkeiten ein Konzept, das keiner unserer EAs hat. Das
   Volatilitätsziel-Modul lässt sich danach in alle EAs einbauen.
3. **Elder Triple Screen** (1986/1993) – wegen Stefans Zeitrahmen-Achse: das einzige Modell
   hier, das von W1 bis M5 sinnvoll skaliert und die Richtung eines höheren Zeitrahmens
   nutzt. Alternativ **ORB**, wenn der Minutenbereich Vorrang hat – dann aber nur mit
   echten Ticks und realem Spread testen, weil der unabhängige Nachtest netto null ergab.

Schnelle Zusatzgewinne ohne neues Modell: **Saisonalitätsfilter** (Halloween/Monatswechsel)
und **Ichimoku-Wolke** bzw. **Clenow-Steigung × R²** als zusätzliche Filteroptionen
neben RSI/ADX in den bestehenden EAs.

## Quellenliste

- Faber (2007): SSRN 962461; Zusammenfassung: [Quantpedia – Asset Class Trend-Following](https://quantpedia.com/strategies/asset-class-trend-following); [ThinkAdvisor, 02.09.2015](https://thinkadvisor.com/2015/09/02/most-downloaded-ssrn-paper-ever-says-you-should-be/); Kritik: Zakamulin, SSRN 2242795.
- Antonacci: SSRN 2042750; [CXO Advisory, 14.10.2014](https://www.cxoadvisory.com/momentum-investing/a-few-notes-on-dual-momentum-investing); [Advisor Perspectives / ReSolve, 06.05.2019](https://files.advisorperspectives.com/articles/2019/05/06/global-equity-momentum-a-craftsmans-perspective).
- Clenow: Buch 2015; [TuringTrader-Regelbeschreibung](https://turingtrader-com.web.app/portfolios/clenow-stocks-on-the-move); [Chris Chow, 10.11.2018](https://chrischow.github.io/dataandstuff/2018-11-10-how-not-to-invest-clenow-momentum).
- Carver: Buch 2015; [CXO Advisory, 30.09.2015](https://www.cxoadvisory.com/big-ideas/a-few-notes-on-systematic-trading); Blog [qoppac.blogspot.com](https://qoppac.blogspot.com/).
- Elder: Futures Magazine 04/1986; „Trading for a Living“, Wiley 1993.
- Connors/Raschke: „Street Smarts“, 1995; Tests: [Oxford Capital Strategies, Turtle Soup Setup 1](https://oxfordstrat.com/trading-strategies/turtle-soup-plus-1/) und [Setup 2](https://oxfordstrat.com/trading-strategies/turtle-soup-plus-2/), 07/2012.
- ORB: Crabel 1990; [Zarattini/Aziz, SSRN 4416622](https://papers.ssrn.com/abstract=4416622); [CXO Advisory, 08.05.2023](https://www.cxoadvisory.com/technical-trading/day-trading-with-an-opening-range-breakout-strategy); [MQL5-Nachtest, 25.09.2026](https://www.mql5.com/en/blogs/post/776235).
- Ichimoku: Hosoda 1969; [Deng et al., IJFE 2021](https://ideas.repec.org/a/wly/ijfiec/v26y2021i4p5321-5336.html).
- Saisonalität: [Bouman/Jacobsen, AER 2002](https://ideas.repec.org/r/aea/aecrev/v92y2002i5p1618-1635.html); [Jacobsen/Zhang](https://www.bnains.org/backtest/periode/The_Halloween_Indicator_everywhere_and_all_the_time_-_Ben_Jacobsen_%26_Cherry_Y._Zhang.pdf); Lakonishok/Smidt, RFS 1988; [McConnell/Xu, FAJ 2008](https://rpc.cfainstitute.org/research/financial-analysts-journal/2008/equity-returns-at-the-turn-of-the-month).
