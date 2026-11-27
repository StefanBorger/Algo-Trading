//+------------------------------------------------------------------+
//|                                                   MACrossEA.mq5  |
//|  Modell A: Trendfolge per Gleitender-Durchschnitt-Kreuzung       |
//|                                                                  |
//|  Long, wenn der schnelle MA den langsamen nach oben kreuzt,      |
//|  Short bei Kreuzung nach unten (geschlossene Bars).              |
//|  Ausstieg: Gegenkreuzung (dann Umkehr) oder ATR-Trailing-Stop.   |
//|  Positionsgroesse: Anfangsstop = InpStopATR * ATR riskiert       |
//|  InpRiskPercent % der Equity.                                    |
//+------------------------------------------------------------------+
#property copyright "Stefan Borger"
#property version   "1.00"
#property description "MA-Crossover-Trendfolge mit ATR-Stop"

#include <AlgoTrading\StrategyCommon.mqh>

input group "Allgemein"
input ENUM_TIMEFRAMES      InpTimeframe   = PERIOD_D1;     // Zeitrahmen fuer Signale
input ENUM_TRADE_DIRECTION InpDirection   = DIR_BOTH;      // Handelsrichtung
input ulong                InpMagic       = 20261201;      // Magic Number
input int                  InpSlippage    = 10;            // max. Slippage (Punkte)

input group "Signal"
input int                  InpFastPeriod  = 50;            // schneller MA (Bars)
input int                  InpSlowPeriod  = 200;           // langsamer MA (Bars)
input ENUM_MA_METHOD       InpMAMethod    = MODE_EMA;      // MA-Typ
input ENUM_APPLIED_PRICE   InpMAPrice     = PRICE_CLOSE;   // MA-Preis

input group "Risiko"
input int                  InpATRPeriod   = 20;            // ATR-Periode (Wilder)
input double               InpRiskPercent = 1.0;           // Risiko je Trade (% Equity bis Anfangsstop)
input double               InpStopATR     = 3.0;           // Anfangsstop in ATR
input double               InpTrailATR    = 3.0;           // Trailing-Stop in ATR (0 = aus)

input group "Optimierung"
input int                  InpMinTrades   = 30;            // OnTester: Mindestanzahl Trades

CStrategyHelper h;
int    g_fastHandle = INVALID_HANDLE;
int    g_slowHandle = INVALID_HANDLE;
int    g_dir        = 0;      // +1 long, -1 short, 0 flat
double g_stop       = 0.0;    // aktueller Stop (intern, auch beim Broker gesetzt)

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastPeriod < 1 || InpSlowPeriod <= InpFastPeriod || InpATRPeriod < 1 ||
      InpRiskPercent <= 0.0 || InpStopATR <= 0.0 || InpTrailATR < 0.0)
     {
      Print("MACrossEA: ungueltige Parameter");
      return(INIT_PARAMETERS_INCORRECT);
     }

   h.Init("MACrossEA", InpTimeframe, InpMagic, InpSlippage);

   g_fastHandle = iMA(_Symbol, h.Timeframe(), InpFastPeriod, 0, InpMAMethod, InpMAPrice);
   g_slowHandle = iMA(_Symbol, h.Timeframe(), InpSlowPeriod, 0, InpMAMethod, InpMAPrice);
   if(g_fastHandle == INVALID_HANDLE || g_slowHandle == INVALID_HANDLE)
     {
      Print("MACrossEA: MA-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
      return(INIT_FAILED);
     }

   double openPrice = 0.0;
   g_dir = h.RecoverPosition(g_stop, openPrice);
   if(g_dir != 0 && g_stop <= 0.0)
     {
      double atr = h.WilderATR(InpATRPeriod);
      if(atr > 0.0)
        {
         g_stop = openPrice - g_dir * InpStopATR * atr;
         h.SetStop(g_stop);
        }
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_fastHandle != INVALID_HANDLE)
      IndicatorRelease(g_fastHandle);
   if(g_slowHandle != INVALID_HANDLE)
      IndicatorRelease(g_slowHandle);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
//--- Position extern geschlossen (Broker-Stop)?
   if(g_dir != 0 && h.CountPositions() == 0)
     {
      g_dir  = 0;
      g_stop = 0.0;
     }

//--- interner Stop (falls der Broker-Stop nicht gesetzt werden konnte)
   if(g_dir != 0 && h.StopHit(g_dir, g_stop))
     {
      h.CloseAll();
      if(h.CountPositions() == 0)
        {
         g_dir  = 0;
         g_stop = 0.0;
        }
      return;
     }

   if(!h.BarPending())
      return;
   if(ProcessBar())
      h.BarProcessed();
  }

//+------------------------------------------------------------------+
//| Einmal pro neuer Bar. false = Daten noch nicht bereit (Retry).    |
//+------------------------------------------------------------------+
bool ProcessBar()
  {
   ENUM_TIMEFRAMES tf = h.Timeframe();
   if(!h.EnoughBars(InpSlowPeriod + 2))
      return(false);

   double fast[], slow[];
   ArraySetAsSeries(fast, true);                       // [0] = Shift 1, [1] = Shift 2
   ArraySetAsSeries(slow, true);
   if(CopyBuffer(g_fastHandle, 0, 1, 2, fast) != 2)
      return(false);
   if(CopyBuffer(g_slowHandle, 0, 1, 2, slow) != 2)
      return(false);

   double atr    = h.WilderATR(InpATRPeriod);
   double close1 = iClose(_Symbol, tf, 1);
   if(atr <= 0.0 || close1 <= 0.0)
      return(false);

   int cross = 0;
   if(fast[0] > slow[0] && fast[1] <= slow[1])
      cross = 1;
   else if(fast[0] < slow[0] && fast[1] >= slow[1])
      cross = -1;

   g_dir = h.PositionDir();
   if(g_dir == 0)
      g_stop = 0.0;

//--- Gegenkreuzung: Position schliessen (Umkehr folgt unten)
   if(g_dir != 0 && cross == -g_dir)
     {
      h.CloseAll();
      if(h.CountPositions() == 0)
        {
         g_dir  = 0;
         g_stop = 0.0;
        }
     }

//--- Trailing-Stop: nur in Gewinnrichtung nachziehen
   if(g_dir != 0 && InpTrailATR > 0.0)
     {
      double ns = close1 - g_dir * InpTrailATR * atr;
      if(g_stop <= 0.0 || (g_dir > 0 && ns > g_stop) || (g_dir < 0 && ns < g_stop))
        {
         g_stop = ns;
         h.SetStop(g_stop);
        }
     }

//--- Einstieg nur direkt bei der Kreuzung
   if(g_dir == 0 && cross != 0 && DirectionAllowed(InpDirection, cross))
      OpenTrade(cross, atr);

   return(true);
  }

//+------------------------------------------------------------------+
void OpenTrade(const int dir, const double atr)
  {
   double stopDist = InpStopATR * atr;
   double volume   = h.VolumeForRisk(stopDist, InpRiskPercent);
   if(volume <= 0.0)
      return;

   double price = (dir > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                            : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double stop  = price - dir * stopDist;
   if(h.OpenPosition(dir, volume, stop, dir > 0 ? "MACross L" : "MACross S"))
     {
      g_dir  = dir;
      g_stop = stop;
     }
  }

//+------------------------------------------------------------------+
double OnTester()
  {
   return(ProfitDrawdownScore(InpMinTrades));
  }
//+------------------------------------------------------------------+
