//+------------------------------------------------------------------+
//|                                           KeltnerBreakoutEA.mq5  |
//|  Modell B: Volatilitaets-Ausbruch aus dem Keltner-Kanal          |
//|                                                                  |
//|  Kanal: Mitte = EMA(InpKCPeriod), Baender = Mitte +/- K * ATR.   |
//|  Long, wenn eine Bar ueber dem oberen Band schliesst (vorherige  |
//|  Bar noch darunter), Short spiegelbildlich.                      |
//|  Optionaler Squeeze-Filter: nur handeln, wenn die Bollinger-     |
//|  Baender in den letzten InpSqueezeBars Bars innerhalb des        |
//|  Keltner-Kanals lagen (Ruhe vor dem Ausbruch).                   |
//|  Ausstieg: Schlusskurs zurueck ueber/unter die Mitte, Anfangs-   |
//|  stop und ATR-Trailing-Stop.                                     |
//+------------------------------------------------------------------+
#property copyright "Stefan Borger"
#property version   "1.00"
#property description "Keltner-Kanal-Ausbruch mit optionalem Bollinger-Squeeze"

#include <AlgoTrading\StrategyCommon.mqh>

input group "Allgemein"
input ENUM_TIMEFRAMES      InpTimeframe    = PERIOD_D1;    // Zeitrahmen fuer Signale
input ENUM_TRADE_DIRECTION InpDirection    = DIR_BOTH;     // Handelsrichtung
input ulong                InpMagic        = 20261202;     // Magic Number
input int                  InpSlippage     = 10;           // max. Slippage (Punkte)

input group "Keltner-Kanal"
input int                  InpKCPeriod     = 20;           // EMA-Periode (Mitte)
input double               InpKCMult       = 2.0;          // Bandbreite in ATR
input bool                 InpExitAtMiddle = true;         // Ausstieg bei Schluss jenseits der Mitte

input group "Squeeze-Filter"
input int                  InpSqueezeBars  = 0;            // Squeeze in den letzten X Bars (0 = aus)
input int                  InpBBPeriod     = 20;           // Bollinger-Periode
input double               InpBBDev        = 2.0;          // Bollinger-Standardabweichungen

input group "Risiko"
input int                  InpATRPeriod    = 20;           // ATR-Periode (Wilder, auch fuer Kanal)
input double               InpRiskPercent  = 1.0;          // Risiko je Trade (% Equity bis Anfangsstop)
input double               InpStopATR      = 2.0;          // Anfangsstop in ATR
input double               InpTrailATR     = 2.0;          // Trailing-Stop in ATR (0 = aus)

input group "Optimierung"
input int                  InpMinTrades    = 30;           // OnTester: Mindestanzahl Trades

CStrategyHelper h;
int    g_emaHandle = INVALID_HANDLE;
int    g_bbHandle  = INVALID_HANDLE;
int    g_dir       = 0;
double g_stop      = 0.0;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpKCPeriod < 1 || InpKCMult <= 0.0 || InpSqueezeBars < 0 || InpBBPeriod < 2 ||
      InpBBDev <= 0.0 || InpATRPeriod < 1 || InpRiskPercent <= 0.0 || InpStopATR <= 0.0 ||
      InpTrailATR < 0.0)
     {
      Print("KeltnerBreakoutEA: ungueltige Parameter");
      return(INIT_PARAMETERS_INCORRECT);
     }

   h.Init("KeltnerBreakoutEA", InpTimeframe, InpMagic, InpSlippage);

   g_emaHandle = iMA(_Symbol, h.Timeframe(), InpKCPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(g_emaHandle == INVALID_HANDLE)
     {
      Print("KeltnerBreakoutEA: EMA-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
      return(INIT_FAILED);
     }
   if(InpSqueezeBars > 0)
     {
      g_bbHandle = iBands(_Symbol, h.Timeframe(), InpBBPeriod, 0, InpBBDev, PRICE_CLOSE);
      if(g_bbHandle == INVALID_HANDLE)
        {
         Print("KeltnerBreakoutEA: Bollinger-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
         return(INIT_FAILED);
        }
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
   if(g_emaHandle != INVALID_HANDLE)
      IndicatorRelease(g_emaHandle);
   if(g_bbHandle != INVALID_HANDLE)
      IndicatorRelease(g_bbHandle);
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
   int count = MathMax(2, InpSqueezeBars + 1);           // Shift 1 .. count
   if(!h.EnoughBars(MathMax(InpKCPeriod, InpBBPeriod) + count + 2))
      return(false);

   double ema[], cls[], atr[];
   ArraySetAsSeries(ema, true);                          // [0] = Shift 1
   ArraySetAsSeries(cls, true);
   if(CopyBuffer(g_emaHandle, 0, 1, count, ema) != count)
      return(false);
   if(CopyClose(_Symbol, tf, 1, count, cls) != count)
      return(false);
   if(!h.WilderATRSeries(InpATRPeriod, count, atr))      // atr[0] = Shift 1
      return(false);

   double up0 = ema[0] + InpKCMult * atr[0];
   double lo0 = ema[0] - InpKCMult * atr[0];
   double up1 = ema[1] + InpKCMult * atr[1];
   double lo1 = ema[1] - InpKCMult * atr[1];

   int signal = 0;
   if(cls[0] > up0 && cls[1] <= up1)
      signal = 1;
   else if(cls[0] < lo0 && cls[1] >= lo1)
      signal = -1;

//--- Squeeze-Filter: Bollinger innerhalb Keltner in Shift 2 .. InpSqueezeBars+1
   if(signal != 0 && InpSqueezeBars > 0)
     {
      double bbUp[], bbLo[];
      ArraySetAsSeries(bbUp, true);
      ArraySetAsSeries(bbLo, true);
      if(CopyBuffer(g_bbHandle, 1, 1, count, bbUp) != count)  // UPPER_BAND
         return(false);
      if(CopyBuffer(g_bbHandle, 2, 1, count, bbLo) != count)  // LOWER_BAND
         return(false);

      bool squeeze = false;
      for(int k = 1; k < count && !squeeze; k++)
        {
         double kcUp = ema[k] + InpKCMult * atr[k];
         double kcLo = ema[k] - InpKCMult * atr[k];
         if(bbUp[k] < kcUp && bbLo[k] > kcLo)
            squeeze = true;
        }
      if(!squeeze)
         signal = 0;
     }

   g_dir = h.PositionDir();
   if(g_dir == 0)
      g_stop = 0.0;

//--- Ausstieg: Schluss jenseits der Kanalmitte
   if(g_dir != 0 && InpExitAtMiddle &&
      ((g_dir > 0 && cls[0] < ema[0]) || (g_dir < 0 && cls[0] > ema[0])))
     {
      h.CloseAll();
      if(h.CountPositions() == 0)
        {
         g_dir  = 0;
         g_stop = 0.0;
        }
     }

//--- Gegenausbruch bei offener Position: schliessen, Umkehr folgt unten
   if(g_dir != 0 && signal == -g_dir)
     {
      h.CloseAll();
      if(h.CountPositions() == 0)
        {
         g_dir  = 0;
         g_stop = 0.0;
        }
     }

//--- Trailing-Stop
   if(g_dir != 0 && InpTrailATR > 0.0)
     {
      double ns = cls[0] - g_dir * InpTrailATR * atr[0];
      if(g_stop <= 0.0 || (g_dir > 0 && ns > g_stop) || (g_dir < 0 && ns < g_stop))
        {
         g_stop = ns;
         h.SetStop(g_stop);
        }
     }

//--- Einstieg
   if(g_dir == 0 && signal != 0 && DirectionAllowed(InpDirection, signal))
      OpenTrade(signal, atr[0]);

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
   if(h.OpenPosition(dir, volume, stop, dir > 0 ? "Keltner L" : "Keltner S"))
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
