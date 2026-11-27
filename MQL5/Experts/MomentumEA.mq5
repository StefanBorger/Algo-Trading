//+------------------------------------------------------------------+
//|                                                  MomentumEA.mq5  |
//|  Modell D: Zeitreihen-Momentum (Time-Series Momentum)            |
//|                                                                  |
//|  Richtung = Vorzeichen der Rendite ueber InpLookback Bars        |
//|  (optional ohne die letzten InpSkipBars Bars, z.B. "12-1").      |
//|  Nur alle InpRebalanceBars Bars wird neu entschieden, dazwischen |
//|  bleibt die Position liegen -> sehr wenige Trades.               |
//|  Positionsgroesse wie beim Turtle-Unit: 1 ATR Kursbewegung =     |
//|  InpRiskPercent % der Equity (Volatilitaets-Targeting).          |
//|  Optionaler Notfall-Stop in ATR (Standard: aus, wie im Original).|
//+------------------------------------------------------------------+
#property copyright "Stefan Borger"
#property version   "1.00"
#property description "Zeitreihen-Momentum mit periodischem Rebalancing"

#include <AlgoTrading\StrategyCommon.mqh>

input group "Allgemein"
input ENUM_TIMEFRAMES      InpTimeframe      = PERIOD_D1;  // Zeitrahmen fuer Signale
input ENUM_TRADE_DIRECTION InpDirection      = DIR_BOTH;   // Handelsrichtung
input ulong                InpMagic          = 20261204;   // Magic Number
input int                  InpSlippage       = 10;         // max. Slippage (Punkte)

input group "Signal"
input int                  InpLookback       = 252;        // Rendite-Zeitraum (Bars, D1: 252 = 1 Jahr)
input int                  InpSkipBars       = 0;          // juengste Bars auslassen (z.B. 21)
input double               InpThresholdPct   = 0.0;        // Mindestrendite in % (darunter flat)
input int                  InpRebalanceBars  = 21;         // neu entscheiden alle X Bars (D1: 21 = Monat)

input group "Risiko"
input int                  InpATRPeriod      = 20;         // ATR-Periode (Wilder)
input double               InpRiskPercent    = 1.0;        // % Equity je 1 ATR Kursbewegung
input double               InpStopATR        = 0.0;        // Notfall-Stop in ATR (0 = aus)

input group "Optimierung"
input int                  InpMinTrades      = 10;         // OnTester: Mindestanzahl Trades (wenige Trades je Jahr)

CStrategyHelper h;
int    g_dir       = 0;
double g_stop      = 0.0;
int    g_barsSince = 0;     // Bars seit dem letzten Rebalancing

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpLookback < 1 || InpSkipBars < 0 || InpThresholdPct < 0.0 || InpRebalanceBars < 1 ||
      InpATRPeriod < 1 || InpRiskPercent <= 0.0 || InpStopATR < 0.0)
     {
      Print("MomentumEA: ungueltige Parameter");
      return(INIT_PARAMETERS_INCORRECT);
     }

   h.Init("MomentumEA", InpTimeframe, InpMagic, InpSlippage);

//--- erste Bar entscheidet sofort (nach Neustart ebenfalls)
   g_barsSince = InpRebalanceBars;

   double openPrice = 0.0;
   g_dir = h.RecoverPosition(g_stop, openPrice);
   if(g_dir != 0 && g_stop <= 0.0 && InpStopATR > 0.0)
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
void OnTick()
  {
   if(g_dir != 0 && h.CountPositions() == 0)
     {
      g_dir  = 0;
      g_stop = 0.0;
     }

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
bool ProcessBar()
  {
   ENUM_TIMEFRAMES tf = h.Timeframe();
   int oldShift = 1 + InpSkipBars + InpLookback;
   if(!h.EnoughBars(MathMax(oldShift, InpATRPeriod * 2) + 1))
      return(false);

   double recent = iClose(_Symbol, tf, 1 + InpSkipBars);
   double past   = iClose(_Symbol, tf, oldShift);
   double atr    = h.WilderATR(InpATRPeriod);
   if(recent <= 0.0 || past <= 0.0 || atr <= 0.0)
      return(false);

   g_dir = h.PositionDir();
   if(g_dir == 0)
      g_stop = 0.0;

   g_barsSince++;
   if(g_barsSince < InpRebalanceBars)
      return(true);
   g_barsSince = 0;

//--- Zielrichtung bestimmen
   double ret    = (recent / past - 1.0) * 100.0;
   int    target = 0;
   if(ret > InpThresholdPct)
      target = 1;
   else if(ret < -InpThresholdPct)
      target = -1;
   if(target != 0 && !DirectionAllowed(InpDirection, target))
      target = 0;

   if(target == g_dir)
      return(true);                // Richtung unveraendert: liegen lassen

   if(g_dir != 0)
     {
      h.CloseAll();
      if(h.CountPositions() > 0)
         return(true);             // Schliessen fehlgeschlagen, beim naechsten Mal erneut
      g_dir  = 0;
      g_stop = 0.0;
     }

   if(target != 0)
     {
      OpenTrade(target, atr);
      if(g_dir != target)
         g_barsSince = InpRebalanceBars - 1;   // Order fehlgeschlagen: naechste Bar erneut
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Volumen: 1 ATR Bewegung = InpRiskPercent % Equity                 |
//+------------------------------------------------------------------+
void OpenTrade(const int dir, const double atr)
  {
   double volume = h.VolumeForRisk(atr, InpRiskPercent);
   if(volume <= 0.0)
      return;

   double stop = 0.0;
   if(InpStopATR > 0.0)
     {
      double price = (dir > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                               : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      stop = price - dir * InpStopATR * atr;
     }
   if(h.OpenPosition(dir, volume, stop, dir > 0 ? "Momentum L" : "Momentum S"))
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
