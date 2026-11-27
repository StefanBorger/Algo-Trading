# Algo-Trading

Nachbau der beiden originalen Turtle-Trading-Systeme als Expert Advisor für MetaTrader 5,
mit optionalem Trendfilter (RSI oder ADX).

## Inhalt

| Datei | Beschreibung |
|---|---|
| `MQL5/Experts/TurtleEA.mq5` | Expert Advisor (System 1 und 2, Filter, eigenes Optimierungskriterium) |

## Installation

1. `TurtleEA.mq5` nach `<MT5-Datenordner>/MQL5/Experts/` kopieren (Datei → Dateiordner öffnen).
2. In MetaEditor öffnen und mit F7 kompilieren.
3. Im Strategietester (Strg+R) den EA auswählen.

## Regeln

**System 1:** Einstieg beim Ausbruch über das 20-Bar-Hoch bzw. unter das 20-Bar-Tief,
Ausstieg beim 10-Bar-Gegenausbruch. Skip-Regel: Ein Signal wird ausgelassen, wenn der
letzte Ausbruch ein Gewinner war. Jeder 20-Bar-Ausbruch wird dafür virtuell verfolgt
(1 Unit, 2N-Stop, 10-Bar-Exit), egal ob er gehandelt wurde. Ein ausgelassener Ausbruch
wird trotzdem gehandelt, wenn der Kurs den 55-Bar-Kanal durchbricht (Failsafe).

**System 2:** Einstieg beim 55-Bar-Ausbruch (per Parameter z. B. 50), Ausstieg beim
20-Bar-Gegenausbruch. Keine Skip-Regel.

**Gemeinsam:**
- N = ATR(20) nach Wilder (selbst berechnet, da `iATR` in MT5 einen einfachen Durchschnitt nutzt).
- Unit-Größe wie im Original: Eine Kursbewegung von 1 N entspricht 1 % der Equity.
  Beim Stop von 2 N riskiert ein Unit also rund 2 %.
- Stop bei 2 N unter (über) dem letzten Einstieg.
- Nachkauf alle 0,5 N (gemessen am N beim Ersteinstieg) bis maximal 4 Units; der Stop
  aller Units wird dabei auf 2 N vom letzten Einstieg nachgezogen.
- Kanäle, N und Filter werden auf geschlossenen Bars des gewählten Zeitrahmens berechnet;
  Ein- und Ausstiege passieren tickgenau, sobald der Kurs den Kanal durchbricht.
- Der Stop liegt beim Broker; zusätzlich prüft der EA ihn intern (falls der Broker-Mindestabstand das Setzen verhindert).

**Filter (`InpFilter`):**
- `kein Filter`
- `RSI`: Long nur bei RSI ≥ 55, Short nur bei RSI ≤ 45 (geschlossene Bar).
- `ADX`: nur bei ADX ≥ 25, Long nur bei +DI > −DI, Short nur bei −DI > +DI.

Der Filter gilt nur für den Ersteinstieg, nicht für Nachkäufe.

## Parameter

| Parameter | Standard | Bedeutung |
|---|---|---|
| `InpTimeframe` | D1 | Signal-Zeitrahmen (optimierbar) |
| `InpSystem` | System 1 | System 1 oder 2 |
| `InpS1EntryBars` / `InpS1ExitBars` | 20 / 10 | Kanäle System 1 |
| `InpUseSkipRule` | true | Skip-Regel System 1 |
| `InpFailsafeBars` | 55 | Failsafe-Kanal System 1 |
| `InpS2EntryBars` / `InpS2ExitBars` | 55 / 20 | Kanäle System 2 |
| `InpATRPeriod` | 20 | Periode für N |
| `InpRiskPercent` | 1.0 | % Equity je 1 N pro Unit |
| `InpStopN` | 2.0 | Stop in N |
| `InpPyramidN` | 0.5 | Nachkauf-Abstand in N |
| `InpMaxUnits` | 4 | max. Units |
| `InpFilter` | kein Filter | Trendfilter |
| `InpRSIPeriod`, `InpRSILong`, `InpRSIShort` | 14, 55, 45 | RSI-Filter |
| `InpADXPeriod`, `InpADXMin` | 14, 25 | ADX-Filter |
| `InpMinTrades` | 30 | Mindestanzahl Trades für das Optimierungskriterium |

## Testplan im Strategietester

1. **Optimierungskriterium:** „Benutzerdefiniertes Maximum“ (Custom max). `OnTester` liefert
   Gewinn ÷ Equity-Drawdown, aber erst ab 30 Trades (sonst 0).
2. **Zu optimierende Parameter:** `InpTimeframe` (z. B. M1, M5, M15, H1, H4, D1),
   `InpSystem` (1, 2), `InpFilter` (kein, RSI, ADX). Alles andere fest lassen, damit
   die Ergebnisse dem Original entsprechen.
3. **Symbole:** Unter „Symbol“ den Eintrag „Alle Symbole in der Marktübersicht“ wählen und
   vorher die Marktübersicht mit den gewünschten Instrumenten füllen (z. B. Aktien/Indizes,
   XAUUSD, XAGUSD, EURUSD, USDJPY, GBPUSD).
4. **Marktphasen getrennt testen:**
   - 2008 (Finanzkrise)
   - 2013–2017 (ruhiger Bullenmarkt)
   - 2020 (Corona-Crash und Erholung)
   - 2022 (Zinswende, Bärenmarkt)
5. **Modellierung:** „Jeder Tick basierend auf realen Ticks“ für kurze Zeitrahmen, damit
   Spread und Kommission realistisch sind; für D1/H4 reicht „1-Minute-OHLC“.
   „Nur Eröffnungspreise“ ist schnell für einen ersten Überblick, verschiebt aber Ein- und
   Ausstiege an den Bar-Anfang.
6. Startkapital groß genug wählen, dass auch bei kleinem N mindestens das Mindestvolumen
   herauskommt (sonst wird nicht gehandelt).

## Bekannte Einschränkungen

- **Sekunden-Charts** gibt es in MT5 nicht nativ. Dafür bräuchte man ein Custom Symbol
  mit Sekundenbars oder einen separaten Python-Backtester.
- **RSI** filtert bei Ausbrüchen wenig, weil er dort fast immer schon über 50 liegt.
  ADX ist als Trendstärke-Filter besser geeignet.
- **Kurze Zeitrahmen:** Spread und Kommission fressen den Vorteil wahrscheinlich auf.
- **Portfolio:** Der EA handelt pro Instanz ein Symbol. Die originalen Portfolio-Limits
  (max. Units über korrelierte Märkte) sind nicht umgesetzt.
- **Netting-Konten:** Nachkäufe werden zu einer Position zusammengefasst; die Unit-Zahl
  führt der EA intern. Nach einem Neustart wird sie bei Netting nur als 1 Unit rekonstruiert.
- Der Code wurde ohne MetaEditor geschrieben und per Review geprüft; das erste Kompilieren
  steht noch aus.
