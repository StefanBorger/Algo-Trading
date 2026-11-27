# MT5-Anleitung: EAs installieren und historisch testen

Schritt für Schritt: vom GitHub-Repo bis zum Backtest und zur Optimierung im Strategietester
von MetaTrader 5. Gilt für alle EAs im Repo (TurtleEA, Modelle A–D und die Geraked-EAs in
`third_party/`).

> Hinweis: `.mq5` ist der Quelltext. MT5 kann nur die kompilierte `.ex5` ausführen. Das Kompilieren
> passiert im MetaEditor (Schritt 4) und erzeugt die `.ex5` automatisch im selben Ordner.

## 1. Repo herunterladen

1. Auf GitHub das Repo öffnen → grüner Button **Code** → **Download ZIP**.
2. ZIP entpacken. Wichtig sind die Ordner `MQL5/` und `third_party/geraked-metatrader5/MQL5/`.

## 2. MT5-Datenordner öffnen

In MetaTrader 5: **Datei → Dateiordner öffnen**. Es öffnet sich der Datenordner des Terminals;
darin liegt der Ordner `MQL5` (mit `Experts`, `Include`, `Indicators` …).

## 3. Dateien hineinkopieren

**Eigene EAs (Turtle + Modelle A–D):** Den Inhalt von `MQL5/` aus dem ZIP in den `MQL5`-Ordner
des Terminals kopieren und beim Nachfragen **zusammenführen** (nicht ersetzen). Danach liegen:

| Datei | Ziel im Datenordner |
|---|---|
| `TurtleEA.mq5`, `MACrossEA.mq5`, `KeltnerBreakoutEA.mq5`, `MeanReversionEA.mq5`, `MomentumEA.mq5` | `MQL5/Experts/` |
| `StrategyCommon.mqh` | `MQL5/Include/AlgoTrading/` |

Der TurtleEA braucht keine Include-Datei, die Modelle A–D brauchen `StrategyCommon.mqh`.

**Geraked-EAs (optional):** Den Inhalt von `third_party/geraked-metatrader5/MQL5/` ebenfalls in
den `MQL5`-Ordner kopieren und zusammenführen:

| Quelle | Ziel |
|---|---|
| `Experts/*.mq5` | `MQL5/Experts/` |
| `Include/EAUtils.mqh`, `Include/errordescription.mqh` | `MQL5/Include/` |
| `Indicators/*.mq5` | `MQL5/Indicators/` |

## 4. Kompilieren im MetaEditor

1. In MT5 **F4** drücken (öffnet den MetaEditor).
2. Im Navigator links `Experts/TurtleEA.mq5` öffnen und **F7** (Kompilieren) drücken.
3. Unten im Reiter **Fehler** muss „0 errors“ stehen. Warnungen sind meist unkritisch.
   Bei Fehlern die Meldungen (Datei, Zeile, Text) kopieren und melden; der Code ist noch
   nie in MetaEditor kompiliert worden.
4. Dasselbe für die anderen EAs wiederholen.

**Reihenfolge bei den Geraked-EAs:** Zuerst die benötigten **Indikatoren** in
`Indicators/` kompilieren (z. B. `AndeanOscillator.mq5`, `AverageForce.mq5`, `AtrSlFinder.mq5`,
`NadarayaWatsonEnvelope.mq5` …), dann erst den EA. Die EAs binden die fertigen
`Indicators\*.ex5` als Ressource ein; fehlt die `.ex5`, bricht das Kompilieren ab.
Am einfachsten: im Navigator alle Indikatoren nacheinander mit F7 kompilieren.

Danach in MT5 im **Navigator** (Strg+N) unter **Expert Advisors** auf „Aktualisieren“
klicken; die EAs erscheinen dort.

## 5. Strategietester einrichten

**Strg+R** öffnet den Strategietester. Im Reiter **Einstellungen**:

| Feld | Wert |
|---|---|
| Experte | z. B. `TurtleEA.ex5` |
| Symbol | z. B. `XAUUSD` (muss beim Broker existieren, ggf. Namen wie `XAUUSD.r` beachten) |
| Zeitrahmen | z. B. `D1`. Beim TurtleEA und den Modellen A–D zählt der Parameter `InpTimeframe` für die Signale; der Tester-Zeitrahmen ist nur das Chart. Am besten beide gleich setzen. |
| Datum | „Benutzerdefinierter Zeitraum“, z. B. 2008.01.01 bis heute |
| Forward | Nein (für den Anfang) |
| Verzögerung | „Ohne Verzögerung“ oder realistisch „Zufällige Verzögerung“ |

## 6. Modellierung, Kapital, Hebel

| Zeitrahmen | Modellierung |
|---|---|
| D1, H4 | **1 Minute OHLC** (schnell und genau genug) |
| H1 und kürzer | **Jeder Tick basierend auf realen Ticks** (realer Spread und Kommission) |
| Schneller Überblick | „Nur Eröffnungspreise“; verschiebt aber Ein-/Ausstiege an den Bar-Anfang |

- **Einzahlung (Startkapital):** z. B. 10 000 oder 100 000. Muss groß genug sein, dass auch bei
  kleinem N mindestens das Mindestvolumen (meist 0,01 Lot) herauskommt, sonst handelt der EA nicht.
- **Hebel:** wie beim echten Konto (z. B. 1:30 bei EU-Brokern für Gold/FX).

Im Reiter **Parameter** die Eingaben des EAs prüfen. Beim TurtleEA zum Beispiel:
`InpSystem` (System 1 / System 2), `InpFilter` (kein Filter / RSI / ADX + DI-Richtung),
`InpRiskPercent` = 1.0. Alle Parameter mit Bedeutung stehen in der [README](../README.md#parameter).

**Geraked-EAs:** Unbedingt `Grid = false` und `IgnoreSL = false` setzen. Die Standardwerte
(`true`) entsprechen den Original-Reports mit Grid und ohne Stop und sind nicht vergleichbar
(siehe [FertigeEAs.md](FertigeEAs.md)).

## 7. Test starten und auswerten

1. **Start** klicken. Beim ersten Lauf lädt MT5 die Historie vom Broker herunter; das kann
   bei realen Ticks über Jahre einige Minuten dauern. Im Reiter **Journal** sieht man den Fortschritt.
   Prüfen, ab wann wirklich Daten vorhanden sind (viele Broker haben reale Ticks erst ab ca. 2015–2018,
   M1-Daten oft länger).
2. Danach in den Reitern:
   - **Backtest:** Kennzahlen (Nettogewinn, Profit-Faktor, Max. Drawdown, Anzahl Trades, Sharpe).
   - **Grafik:** Kontostand- und Equity-Kurve.
   - **Positionen/Deals:** jeder einzelne Trade.
   - **Journal:** Meldungen des EAs (z. B. „Volumen unter Minimum“).
3. **Visueller Modus** (Häkchen „Visualisierung“) zeigt den Chart mit allen Trades, praktisch
   zum Prüfen der Regeln.
4. Bericht speichern: Rechtsklick im Reiter Backtest → **Bericht** → als HTML/XML speichern.

## 8. Optimierung (viele Varianten auf einmal)

1. Im Reiter Einstellungen bei **Optimierung** wählen:
   - **Langsamer vollständiger Algorithmus:** testet jede Kombination (bei wenigen Parametern).
   - **Schneller genetischer Algorithmus:** bei vielen Kombinationen.
2. **Kriterium:** **Benutzerdefiniertes Maximum** (Custom max). Alle EAs im Repo liefern über
   `OnTester` Gewinn ÷ Equity-Drawdown, aber erst ab `InpMinTrades` Trades (Turtle und A–C: 30,
   Momentum: 10), sonst 0.
3. Im Reiter **Parameter** die zu optimierenden Werte anhaken und Start/Schritt/Stopp setzen.
   Für den TurtleEA:
   - `InpTimeframe`: z. B. M15 bis D1
   - `InpSystem`: System 1 und 2
   - `InpFilter`: kein Filter, RSI, ADX
   - alles andere fest lassen, damit die Regeln dem Original entsprechen
4. **Symbol:** Für mehrere Instrumente auf einmal „Alle Symbole in der Marktübersicht“ wählen
   (vorher die gewünschten Symbole in die Marktübersicht holen, z. B. XAUUSD, XAGUSD, EURUSD,
   USDJPY, GBPUSD, Indizes, Aktien).
5. Ergebnisse im Reiter **Optimierungsergebnisse** sortieren; Doppelklick auf eine Zeile startet
   diesen Einzeltest.

## 9. Marktphasen

Jeden Kandidaten zusätzlich getrennt über einzelne Zeiträume testen (Datum im Tester anpassen):

| Phase | Zeitraum |
|---|---|
| Finanzkrise | 2008.01.01 – 2008.12.31 |
| Ruhiger Bullenmarkt | 2013.01.01 – 2017.12.31 |
| Corona-Crash und Erholung | 2020.01.01 – 2020.12.31 |
| Zinswende, Bärenmarkt | 2022.01.01 – 2022.12.31 |

Gegen Überanpassung: mit „Forward“ (z. B. 1/3) einen Teil der Daten zurückhalten und nur
Einstellungen übernehmen, die auch im Forward-Zeitraum funktionieren.

## Häufige Probleme

| Problem | Ursache / Lösung |
|---|---|
| EA nicht im Navigator | Nicht kompiliert oder Navigator nicht aktualisiert (Rechtsklick → Aktualisieren). |
| `cannot open file 'AlgoTrading\StrategyCommon.mqh'` | Include liegt nicht unter `MQL5/Include/AlgoTrading/`. |
| `cannot open file 'EAUtils.mqh'` | Geraked-Include fehlt in `MQL5/Include/`. |
| Ressourcen-Fehler `Indicators\...ex5` | Indikator vorher kompilieren (Schritt 4). |
| Keine Trades | Startkapital zu klein (Mindestvolumen), Symbol ohne Historie im Zeitraum oder Filter zu streng. Journal lesen. |
| Ergebnis „0“ bei Optimierung | Weniger Trades als `InpMinTrades`; Zeitraum verlängern oder Wert senken. |
| Sekunden-Zeitrahmen fehlt | MT5 hat keine Sekunden-Charts; kürzester Zeitrahmen ist M1. |
