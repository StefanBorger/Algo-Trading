# Geraked MT5-EAs (Drittcode, MIT-Lizenz)

Herkunft: <https://github.com/geraked/metatrader5> (Autor „Geraked“/Rabist),
übernommen am 27.11.2026 vom Commit `d3eb29c382acf715727d5cd6a0414151e821fc2d`
(letzter Commit dort: 15.11.2025, erster: 23.08.2023). Lizenz: MIT, siehe [LICENSE](LICENSE).
Der Code ist unverändert.

**Nicht übernommen:** kompilierte `.ex5`-Dateien, die Testreports, `COT1.mq5` und die
Includes `Cot.mqh`, `Shell.mqh`, `WinINet.mqh`, `Sql.mqh`, `Storage.mqh`, `SysTime.mqh`,
`Knn.mqh`, `JAson.mqh`. COT1 lädt COT-Daten per Windows-DLL (`wininet.dll`, PowerShell) –
das wollen wir im Tester nicht freischalten. Die übrigen EAs brauchen nur `EAUtils.mqh`,
`errordescription.mqh` und die Indikatoren.

## Achtung: veröffentlichte Ergebnisse beruhen auf Grid

Alle 11 Testreports im Originalrepo laufen mit `Grid=true` (Volumen-Multiplikator 1,0–1,5,
bis 20–50 Stufen) und `IgnoreSL=true`. Deshalb liegt der Equity-Drawdown dort bei 19–64 %,
der Balance-Drawdown nur bei 4–16 %. Für unseren Vergleich **immer `Grid=false` und
`IgnoreSL=false` setzen** – siehe [docs/FertigeEAs.md](../../docs/FertigeEAs.md#1-geraked-metatrader5-11-eas-mit-reports).

## Installation

Die EAs binden die Indikatoren als Ressource ein (`Indicators\\<Name>.ex5`):

1. `MQL5/Indicators/*.mq5` nach `<Datenordner>/MQL5/Indicators/` kopieren und kompilieren.
2. `MQL5/Include/*.mqh` nach `<Datenordner>/MQL5/Include/` kopieren.
3. `MQL5/Experts/*.mq5` nach `<Datenordner>/MQL5/Experts/Geraked/` kopieren und kompilieren.
   `Heiken_Ashi` liegt bei jedem MT5 unter `Indicators/Examples/` bereits bei.

Nicht kompiliert und nicht ausgeführt (wie unser eigener Code).
