//+------------------------------------------------------------------+
//|                                             MeanReversionEA.mq5  |
//|  Modell C: Mean-Reversion (Gegenpol zu den Trendmodellen)        |
//|                                                                  |
//|  Kauft kurzfristige Ueberverkaufung, verkauft Ueberkaufung:      |
//|   Long : RSI(2) < InpRSILow  (optional nur ueber dem SMA 200)    |
//|   Short: RSI(2) > InpRSIHigh (optional nur unter dem SMA 200)    |
//|  Optional nur in Seitwaertsphasen: ADX < InpADXMax.              |
//|  Ausstieg: Schluss ueber (Long) bzw. unter (Short) dem kurzen    |
//|  SMA, Zeitstop nach InpMaxBars Bars, weiter Notfall-Stop in ATR. |
//+------------------------------------------------------------------+
#property copyright "Stefan Borger"
#property version   "1.00"
#property description "RSI(2)-Mean-Reversion mit Trend- und ADX-Filter"

#include <AlgoTrading\StrategyCommon.mqh>

input group "Allgemein"
input ENUM_TIMEFRAMES      InpTimeframe    = PERIOD_D1;    // Zeitrahmen fuer Signale
input ENUM_TRADE_DIRECTION InpDirection    = DIR_BOTH;     // Handelsrichtung
input ulong                InpMagic        = 20261203;     // Magic Number
input int                  InpSlippage     = 10;           // max. Slippage (Punkte)

input group "Signal"
input int                  InpRSIPeriod    = 2;            // RSI-Periode
input double               InpRSILow       = 10.0;         // Long unter diesem RSI
input double               InpRSIHigh      = 90.0;         // Short ueber diesem RSI
input int                  InpTrendPeriod  = 200;          // Trendfilter SMA (0 = aus)
input int                  InpADXPeriod    = 14;           // ADX-Periode
input double               InpADXMax       = 0.0;          // nur handeln bei ADX unter (0 = aus)

input group "Ausstieg"
input int                  InpExitMAPeriod = 5;            // Ausstieg bei Schluss jenseits SMA
input int                  InpMaxBars      = 10;           // Zeitstop in Bars (0 = aus)

input group "Risiko"
input int                  InpATRPeriod    = 20;           // ATR-Periode (Wilder)
input double               InpRiskPercent  = 1.0;          // Risiko je Trade (% Equity bis Notfall-Stop)
input double               InpStopATR      = 3.0;          // Notfall-Stop in ATR

input group "Optimierung"
input int                  InpMinTrades    = 30;           // OnTester: Mindestanzahl Trades

CStrategyHelper h;
int    g_rsiHandle   = INVALID_HANDLE;
int    g_trendHandle = INVALID_HANDLE;
int    g_exitHandle  = INVALID_HANDLE;
int    g_adxHandle   = INVALID_HANDLE;
int    g_dir         = 0;
double g_stop        = 0.0;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpRSIPeriod < 1 || InpRSILow <= 0.0 || InpRSIHigh >= 100.0 || InpRSILow >= InpRSIHigh ||
      InpTrendPeriod < 0 || InpADXPeriod < 1 || InpADXMax < 0.0 || InpExitMAPeriod < 1 ||
      InpMaxBars < 0 || InpATRPeriod < 1 || InpRiskPercent <= 0.0 || InpStopATR <= 0.0)
     {
      Print("MeanReversionEA: ungueltige Parameter");
      return(INIT_PARAMETERS_INCORRECT);
     }

   h.Init("MeanReversionEA", InpTimeframe, InpMagic, InpSlippage);
   ENUM_TIMEFRAMES tf = h.Timeframe();

   g_rsiHandle  = iRSI(_Symbol, tf, InpRSIPeriod, PRICE_CLOSE);
   g_exitHandle = iMA(_Symbol, tf, InpExitMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(g_rsiHandle == INVALID_HANDLE || g_exitHandle == INVALID_HANDLE)
     {
      Print("MeanReversionEA: Indikator-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
      return(INIT_FAILED);
     }
   if(InpTrendPeriod > 0)
     {
      g_trendHandle = iMA(_Symbol, tf, InpTrendPeriod, 0, MODE_SMA, PRICE_CLOSE);
      if(g_trendHandle == INVALID_HANDLE)
        {
         Print("MeanReversionEA: Trend-MA-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
         return(INIT_FAILED);
        }
     }
   if(InpADXMax > 0.0)
     {
      g_adxHandle = iADX(_Symbol, tf, InpADXPeriod);
      if(g_adxHandle == INVALID_HANDLE)
        {
         Print("MeanReversionEA: ADX-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
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
   if(g_rsiHandle != INVALID_HANDLE)
      IndicatorRelease(g_rsiHandle);
   if(g_trendHandle != INVALID_HANDLE)
      IndicatorRelease(g_trendHandle);
   if(g_exitHandle != INVALID_HANDLE)
      IndicatorRelease(g_exitHandle);
   if(g_adxHandle != INVALID_HANDLE)
      IndicatorRelease(g_adxHandle);
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
//| Wert eines Indikatorpuffers an Shift 1                            |
//+------------------------------------------------------------------+
bool Value1(const int handle, const int buffer, double &value)
  {
   double buf[];
   if(CopyBuffer(handle, buffer, 1, 1, buf) != 1)
      return(false);
   value = buf[0];
   return(true);
  }

//+------------------------------------------------------------------+
bool ProcessBar()
  {
   ENUM_TIMEFRAMES tf = h.Timeframe();
   int needed = MathMax(MathMax(InpTrendPeriod, InpExitMAPeriod),
                        MathMax(InpRSIPeriod, InpADXPeriod * 2)) + 2;
   if(!h.EnoughBars(needed))
      return(false);

   double rsi = 0.0, exitMA = 0.0;
   if(!Value1(g_rsiHandle, 0, rsi) || !Value1(g_exitHandle, 0, exitMA))
      return(false);

   double trendMA = 0.0;
   if(InpTrendPeriod > 0 && !Value1(g_trendHandle, 0, trendMA))
      return(false);

   double adx = 0.0;
   if(InpADXMax > 0.0 && !Value1(g_adxHandle, 0, adx))   // MAIN_LINE
      return(false);

   double atr    = h.WilderATR(InpATRPeriod);
   double close1 = iClose(_Symbol, tf, 1);
   if(atr <= 0.0 || close1 <= 0.0)
      return(false);

   g_dir = h.PositionDir();
   if(g_dir == 0)
      g_stop = 0.0;

//--- offene Position: Ausstieg am kurzen SMA oder per Zeitstop
   if(g_dir != 0)
     {
      bool exitNow = (g_dir > 0) ? (close1 > exitMA) : (close1 < exitMA);

      if(!exitNow && InpMaxBars > 0)
        {
         datetime opened = h.PositionOpenTime();
         int held = (opened > 0) ? iBarShift(_Symbol, tf, opened, false) : 0;
         if(held >= InpMaxBars)
            exitNow = true;
        }

      if(exitNow)
        {
         h.CloseAll();
         if(h.CountPositions() == 0)
           {
            g_dir  = 0;
            g_stop = 0.0;
           }
        }
      return(true);           // kein neuer Einstieg in derselben Bar
     }

//--- Einstieg
   int signal = 0;
   if(rsi < InpRSILow)
      signal = 1;
   else if(rsi > InpRSIHigh)
      signal = -1;
   if(signal == 0)
      return(true);

   if(InpTrendPeriod > 0)
     {
      if(signal > 0 && close1 <= trendMA)
         return(true);
      if(signal < 0 && close1 >= trendMA)
         return(true);
     }
   if(InpADXMax > 0.0 && adx >= InpADXMax)
      return(true);
   if(!DirectionAllowed(InpDirection, signal))
      return(true);

   OpenTrade(signal, atr);
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
   if(h.OpenPosition(dir, volume, stop, dir > 0 ? "MeanRev L" : "MeanRev S"))
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
