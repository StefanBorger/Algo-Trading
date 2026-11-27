//+------------------------------------------------------------------+
//|                                                    TurtleEA.mq5  |
//|  Nachbau der beiden originalen Turtle-Trading-Systeme fuer MT5   |
//|                                                                  |
//|  System 1: Einstieg 20-Bar-Ausbruch, Ausstieg 10-Bar-Gegenausbr. |
//|            Skip-Regel: Signal auslassen, wenn der letzte          |
//|            Ausbruch ein Gewinner war (ausser 55-Bar-Failsafe).    |
//|  System 2: Einstieg 55-Bar-Ausbruch, Ausstieg 20-Bar-Gegenausbr. |
//|                                                                  |
//|  N = ATR(20) nach Wilder, Unit = 1 % Equity pro 1 N,             |
//|  Stop 2 N, Nachkauf alle 0,5 N bis max. 4 Units, Stops werden    |
//|  beim Nachkauf nachgezogen.                                      |
//|  Optionaler Trendfilter: RSI oder ADX.                           |
//+------------------------------------------------------------------+
#property copyright "Stefan Borger"
#property version   "1.00"
#property description "Turtle Trading System 1 und 2 mit optionalem RSI/ADX-Filter"

#include <Trade\Trade.mqh>

//--- Auswahl des Systems
enum ENUM_TURTLE_SYSTEM
  {
   TURTLE_SYSTEM_1 = 1,   // System 1 (20/10)
   TURTLE_SYSTEM_2 = 2    // System 2 (55/20)
  };

//--- Auswahl des Trendfilters
enum ENUM_TREND_FILTER
  {
   FILTER_NONE = 0,       // kein Filter
   FILTER_RSI  = 1,       // RSI
   FILTER_ADX  = 2        // ADX + DI-Richtung
  };

//--- Eingabeparameter
input group "Allgemein"
input ENUM_TIMEFRAMES    InpTimeframe     = PERIOD_D1;        // Zeitrahmen fuer Signale
input ENUM_TURTLE_SYSTEM InpSystem        = TURTLE_SYSTEM_1;  // System
input ulong              InpMagic         = 20261127;         // Magic Number
input int                InpSlippage      = 10;               // max. Slippage (Punkte)

input group "System 1"
input int                InpS1EntryBars   = 20;               // S1 Einstiegs-Kanal (Bars)
input int                InpS1ExitBars    = 10;               // S1 Ausstiegs-Kanal (Bars)
input bool               InpUseSkipRule   = true;             // S1 Skip-Regel aktiv
input int                InpFailsafeBars  = 55;               // S1 Failsafe-Kanal (Bars)

input group "System 2"
input int                InpS2EntryBars   = 55;               // S2 Einstiegs-Kanal (Bars, z.B. 50)
input int                InpS2ExitBars    = 20;               // S2 Ausstiegs-Kanal (Bars)

input group "Risiko / Money-Management"
input int                InpATRPeriod     = 20;               // N: ATR-Periode (Wilder)
input double             InpRiskPercent   = 1.0;              // Equity-Risiko pro Unit (% je 1 N)
input double             InpStopN         = 2.0;              // Stop-Abstand in N
input double             InpPyramidN      = 0.5;              // Nachkauf-Abstand in N
input int                InpMaxUnits      = 4;                // max. Units pro Position

input group "Trendfilter"
input ENUM_TREND_FILTER  InpFilter        = FILTER_NONE;      // Filter
input int                InpRSIPeriod     = 14;               // RSI Periode
input double             InpRSILong       = 55.0;             // RSI: Long nur ab
input double             InpRSIShort      = 45.0;             // RSI: Short nur bis
input int                InpADXPeriod     = 14;               // ADX Periode
input double             InpADXMin        = 25.0;             // ADX: Mindeststaerke

input group "Optimierung"
input int                InpMinTrades     = 30;               // OnTester: Mindestanzahl Trades

//--- globale Objekte / Zustand
CTrade   trade;
ENUM_TIMEFRAMES g_tf;

int      g_rsiHandle = INVALID_HANDLE;
int      g_adxHandle = INVALID_HANDLE;

datetime g_lastBarTime = 0;
bool     g_dataReady   = false;

//--- pro Bar berechnete Werte
double   g_N            = 0.0;
double   g_entryHigh    = 0.0, g_entryLow    = 0.0;
double   g_exitHigh     = 0.0, g_exitLow     = 0.0;
double   g_failsafeHigh = 0.0, g_failsafeLow = 0.0;
double   g_rsi          = 50.0;
double   g_adx          = 0.0, g_plusDI = 0.0, g_minusDI = 0.0;

//--- Positionszustand
int      g_units      = 0;     // Anzahl offener Units
int      g_dir        = 0;     // +1 long, -1 short, 0 flat
double   g_lastEntry  = 0.0;   // Preis des letzten Units
double   g_entryN     = 0.0;   // N beim Ersteinstieg (fuer Pyramiding)
double   g_stopPrice  = 0.0;   // gemeinsamer Stop aller Units

//--- Skip-Regel (System 1): virtueller Trade je Ausbruch
bool     g_virtActive    = false;
int      g_virtDir       = 0;
double   g_virtEntry     = 0.0;
double   g_virtStop      = 0.0;
bool     g_virtSkipped   = false;  // wurde dieser Ausbruch ausgelassen?
bool     g_lastWasWinner = false;  // war der letzte Ausbruch ein Gewinner?

//+------------------------------------------------------------------+
int OnInit()
  {
   g_tf = (InpTimeframe == PERIOD_CURRENT) ? (ENUM_TIMEFRAMES)_Period : InpTimeframe;

   if(InpS1EntryBars < 2 || InpS1ExitBars < 1 || InpS2EntryBars < 2 || InpS2ExitBars < 1 ||
      InpFailsafeBars < 2 || InpATRPeriod < 1 || InpMaxUnits < 1 ||
      InpRiskPercent <= 0.0 || InpStopN <= 0.0 || InpPyramidN <= 0.0)
     {
      Print("TurtleEA: ungueltige Parameter");
      return(INIT_PARAMETERS_INCORRECT);
     }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);

   if(InpFilter == FILTER_RSI)
     {
      g_rsiHandle = iRSI(_Symbol, g_tf, InpRSIPeriod, PRICE_CLOSE);
      if(g_rsiHandle == INVALID_HANDLE)
        {
         Print("TurtleEA: RSI-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
         return(INIT_FAILED);
        }
     }
   else if(InpFilter == FILTER_ADX)
     {
      g_adxHandle = iADX(_Symbol, g_tf, InpADXPeriod);
      if(g_adxHandle == INVALID_HANDLE)
        {
         Print("TurtleEA: ADX-Handle konnte nicht erstellt werden, Fehler ", GetLastError());
         return(INIT_FAILED);
        }
     }

   RecoverState();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_rsiHandle != INVALID_HANDLE)
      IndicatorRelease(g_rsiHandle);
   if(g_adxHandle != INVALID_HANDLE)
      IndicatorRelease(g_adxHandle);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
//--- neue Bar im Signal-Zeitrahmen? Dann Kanaele, N und Filter neu berechnen
   datetime barTime = iTime(_Symbol, g_tf, 0);
   if(barTime == 0)
      return;
   if(barTime != g_lastBarTime || !g_dataReady)
     {
      g_dataReady = UpdateBarData();
      if(g_dataReady)
         g_lastBarTime = barTime;
     }
   if(!g_dataReady)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0.0 || ask <= 0.0)
      return;

//--- Position extern geschlossen (z.B. Stop beim Broker ausgeloest)?
   if(g_units > 0 && CountPositions() == 0)
      ResetPosition();

//--- Skip-Regel fuer System 1 fortschreiben
   if(InpSystem == TURTLE_SYSTEM_1)
      UpdateVirtualTrade(bid, ask);

//--- offene Position verwalten
   if(g_units > 0)
     {
      if(CheckExit(bid, ask))
         return;
      CheckPyramid(bid, ask);
      return;
     }

//--- flat: nach Einstieg suchen
   CheckEntry(bid, ask);
  }

//+------------------------------------------------------------------+
//| Kanaele, N und Filterwerte fuer die zuletzt geschlossene Bar      |
//+------------------------------------------------------------------+
bool UpdateBarData()
  {
   int entryBars = (InpSystem == TURTLE_SYSTEM_1) ? InpS1EntryBars : InpS2EntryBars;
   int exitBars  = (InpSystem == TURTLE_SYSTEM_1) ? InpS1ExitBars  : InpS2ExitBars;
   int needed    = MathMax(MathMax(entryBars, exitBars), MathMax(InpFailsafeBars, InpATRPeriod + 1)) + 1;

   if(Bars(_Symbol, g_tf) < needed + 1)
      return(false);

   double n = CalcWilderATR(InpATRPeriod);
   if(n <= 0.0)
      return(false);

   double eh, el, xh, xl, fh, fl;
   if(!ChannelHighLow(entryBars, eh, el))
      return(false);
   if(!ChannelHighLow(exitBars, xh, xl))
      return(false);
   if(!ChannelHighLow(InpFailsafeBars, fh, fl))
      return(false);

   if(InpFilter == FILTER_RSI)
     {
      double buf[];
      if(CopyBuffer(g_rsiHandle, 0, 1, 1, buf) != 1)
         return(false);
      g_rsi = buf[0];
     }
   else if(InpFilter == FILTER_ADX)
     {
      double adx[], pdi[], mdi[];
      if(CopyBuffer(g_adxHandle, 0, 1, 1, adx) != 1)
         return(false);
      if(CopyBuffer(g_adxHandle, 1, 1, 1, pdi) != 1)
         return(false);
      if(CopyBuffer(g_adxHandle, 2, 1, 1, mdi) != 1)
         return(false);
      g_adx     = adx[0];
      g_plusDI  = pdi[0];
      g_minusDI = mdi[0];
     }

   g_N            = n;
   g_entryHigh    = eh;  g_entryLow    = el;
   g_exitHigh     = xh;  g_exitLow     = xl;
   g_failsafeHigh = fh;  g_failsafeLow = fl;
   return(true);
  }

//+------------------------------------------------------------------+
//| Hoch/Tief der letzten 'bars' geschlossenen Bars (Shift 1..bars)   |
//+------------------------------------------------------------------+
bool ChannelHighLow(const int bars, double &hi, double &lo)
  {
   int iHi = iHighest(_Symbol, g_tf, MODE_HIGH, bars, 1);
   int iLo = iLowest(_Symbol, g_tf, MODE_LOW, bars, 1);
   if(iHi < 0 || iLo < 0)
      return(false);
   hi = iHigh(_Symbol, g_tf, iHi);
   lo = iLow(_Symbol, g_tf, iLo);
   return(hi > 0.0 && lo > 0.0);
  }

//+------------------------------------------------------------------+
//| ATR nach Wilder (MT5-iATR nutzt einen einfachen Durchschnitt).    |
//| Startwert = SMA der ersten 'period' True Ranges, danach           |
//| N = (N_alt * (period-1) + TR) / period.                           |
//+------------------------------------------------------------------+
double CalcWilderATR(const int period)
  {
   int available = Bars(_Symbol, g_tf) - 1;            // ohne laufende Bar
   int count     = MathMin(period * 10, available - 1); // Einschwingphase
   if(count < period + 1)
      return(0.0);

   MqlRates rates[];
   ArraySetAsSeries(rates, false);                      // aelteste zuerst
   int copied = CopyRates(_Symbol, g_tf, 1, count + 1, rates);
   if(copied < period + 2)
      return(0.0);

   double atr = 0.0;
   for(int i = 1; i < copied; i++)
     {
      double h  = rates[i].high;
      double l  = rates[i].low;
      double pc = rates[i - 1].close;
      double tr = MathMax(h - l, MathMax(MathAbs(h - pc), MathAbs(l - pc)));

      if(i <= period)
        {
         atr += tr;
         if(i == period)
            atr /= period;
        }
      else
         atr = (atr * (period - 1) + tr) / period;
     }
   return(atr);
  }

//+------------------------------------------------------------------+
//| Trendfilter                                                       |
//+------------------------------------------------------------------+
bool FilterAllows(const int dir)
  {
   switch(InpFilter)
     {
      case FILTER_RSI:
         return(dir > 0 ? g_rsi >= InpRSILong : g_rsi <= InpRSIShort);
      case FILTER_ADX:
         if(g_adx < InpADXMin)
            return(false);
         return(dir > 0 ? g_plusDI > g_minusDI : g_minusDI > g_plusDI);
      default:
         break;
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Skip-Regel: jeden 20-Bar-Ausbruch virtuell verfolgen (1 Unit,     |
//| 2N-Stop, 10-Bar-Exit), egal ob gehandelt oder nicht. Verlierer =  |
//| 2N-Stop erreicht oder Exit unter Einstand.                        |
//+------------------------------------------------------------------+
void UpdateVirtualTrade(const double bid, const double ask)
  {
   if(g_virtActive)
     {
      if(g_virtDir > 0)
        {
         if(bid <= g_virtStop)
           { g_lastWasWinner = false; g_virtActive = false; }
         else if(bid < g_exitLow)
           { g_lastWasWinner = (bid > g_virtEntry); g_virtActive = false; }
        }
      else
        {
         if(ask >= g_virtStop)
           { g_lastWasWinner = false; g_virtActive = false; }
         else if(ask > g_exitHigh)
           { g_lastWasWinner = (ask < g_virtEntry); g_virtActive = false; }
        }
      if(g_virtActive)
         return;
     }

//--- neuer Ausbruch?
   int dir = 0;
   if(ask > g_entryHigh)
      dir = 1;
   else if(bid < g_entryLow)
      dir = -1;
   if(dir == 0)
      return;

   g_virtActive  = true;
   g_virtDir     = dir;
   g_virtEntry   = (dir > 0) ? ask : bid;
   g_virtStop    = g_virtEntry - dir * InpStopN * g_N;
   g_virtSkipped = InpUseSkipRule && g_lastWasWinner;
  }

//+------------------------------------------------------------------+
//| Einstieg                                                          |
//+------------------------------------------------------------------+
void CheckEntry(const double bid, const double ask)
  {
   int dir = 0;
   if(ask > g_entryHigh)
      dir = 1;
   else if(bid < g_entryLow)
      dir = -1;
   if(dir == 0)
      return;

//--- System 1: Skip-Regel mit 55-Bar-Failsafe
   if(InpSystem == TURTLE_SYSTEM_1 && g_virtActive && g_virtDir == dir && g_virtSkipped)
     {
      bool failsafe = (dir > 0) ? (ask > g_failsafeHigh) : (bid < g_failsafeLow);
      if(!failsafe)
         return;
     }

   if(!FilterAllows(dir))
      return;

   g_entryN = g_N;
   OpenUnit(dir);
  }

//+------------------------------------------------------------------+
//| Ausstieg: Gegenausbruch oder Stop (Backup zum Broker-Stop)        |
//+------------------------------------------------------------------+
bool CheckExit(const double bid, const double ask)
  {
   bool exitNow = false;
   if(g_dir > 0)
      exitNow = (bid < g_exitLow) || (g_stopPrice > 0.0 && bid <= g_stopPrice);
   else if(g_dir < 0)
      exitNow = (ask > g_exitHigh) || (g_stopPrice > 0.0 && ask >= g_stopPrice);

   if(!exitNow)
      return(false);

   CloseAll();
   if(CountPositions() == 0)
      ResetPosition();
   return(true);
  }

//+------------------------------------------------------------------+
//| Pyramiding: alle 0,5 N ein weiteres Unit bis InpMaxUnits          |
//+------------------------------------------------------------------+
void CheckPyramid(const double bid, const double ask)
  {
   if(g_units >= InpMaxUnits || g_entryN <= 0.0)
      return;

   double step = InpPyramidN * g_entryN;
   bool add = (g_dir > 0) ? (ask >= g_lastEntry + step) : (bid <= g_lastEntry - step);
   if(add)
      OpenUnit(g_dir);
  }

//+------------------------------------------------------------------+
//| Unit-Groesse: 1 N Kursbewegung = InpRiskPercent der Equity        |
//+------------------------------------------------------------------+
double UnitVolume(const double n)
  {
   double equity    = AccountInfoDouble(ACCOUNT_EQUITY);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(equity <= 0.0 || tickValue <= 0.0 || tickSize <= 0.0 || n <= 0.0)
      return(0.0);

   double moneyPerLotPerN = n / tickSize * tickValue;
   double volume = equity * InpRiskPercent / 100.0 / moneyPerLotPerN;
   return(NormalizeVolume(volume));
  }

//+------------------------------------------------------------------+
double NormalizeVolume(double volume)
  {
   double minVol  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(stepVol <= 0.0)
      stepVol = minVol;

   volume = MathFloor(volume / stepVol + 1e-9) * stepVol;
   if(volume < minVol)
      return(0.0);          // Konto zu klein fuer 1 Unit -> nicht handeln
   if(volume > maxVol)
      volume = maxVol;

   int digits = (int)MathMax(0.0, MathCeil(-MathLog10(stepVol)));
   return(NormalizeDouble(volume, digits));
  }

//+------------------------------------------------------------------+
//| Ein Unit eroeffnen und Stops aller Units nachziehen               |
//+------------------------------------------------------------------+
bool OpenUnit(const int dir)
  {
   double volume = UnitVolume(g_entryN);
   if(volume <= 0.0)
      return(false);

   double price = (dir > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                            : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double margin = 0.0;
   ENUM_ORDER_TYPE type = (dir > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(OrderCalcMargin(type, _Symbol, volume, price, margin) &&
      margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     {
      Print("TurtleEA: nicht genug freie Margin fuer ", DoubleToString(volume, 2), " Lots");
      return(false);
     }

   string comment = StringFormat("Turtle S%d U%d", (int)InpSystem, g_units + 1);
   bool ok = (dir > 0) ? trade.Buy(volume, _Symbol, 0.0, 0.0, 0.0, comment)
                       : trade.Sell(volume, _Symbol, 0.0, 0.0, 0.0, comment);
   if(!ok || (trade.ResultRetcode() != TRADE_RETCODE_DONE &&
              trade.ResultRetcode() != TRADE_RETCODE_PLACED))
     {
      Print("TurtleEA: Order fehlgeschlagen, Retcode ", trade.ResultRetcode(),
            " ", trade.ResultRetcodeDescription());
      return(false);
     }

   double fill = trade.ResultPrice();
   if(fill <= 0.0)
      fill = price;

   g_units++;
   g_dir       = dir;
   g_lastEntry = fill;
   g_stopPrice = NormalizeDouble(fill - dir * InpStopN * g_entryN, _Digits);
   UpdateStops();
   return(true);
  }

//+------------------------------------------------------------------+
//| Gemeinsamen Stop auf alle Positionen dieses EAs setzen            |
//+------------------------------------------------------------------+
void UpdateStops()
  {
   double point     = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long   stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist   = stopLevel * point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      double curSL = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      if(MathAbs(curSL - g_stopPrice) < point / 2.0)
         continue;

      //--- Mindestabstand des Brokers pruefen; sonst greift der interne Stop
      ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double ref = (ptype == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                                : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(MathAbs(ref - g_stopPrice) <= minDist)
         continue;

      if(!trade.PositionModify(ticket, g_stopPrice, tp))
         Print("TurtleEA: Stop-Anpassung fehlgeschlagen, Ticket ", ticket,
               " Retcode ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
void CloseAll()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      if(!trade.PositionClose(ticket))
         Print("TurtleEA: Schliessen fehlgeschlagen, Ticket ", ticket,
               " Retcode ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
int CountPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagic)
         count++;
     }
   return(count);
  }

//+------------------------------------------------------------------+
void ResetPosition()
  {
   g_units     = 0;
   g_dir       = 0;
   g_lastEntry = 0.0;
   g_entryN    = 0.0;
   g_stopPrice = 0.0;
  }

//+------------------------------------------------------------------+
//| Nach Neustart: Zustand aus offenen Positionen rekonstruieren       |
//| (Hedging: 1 Position = 1 Unit; Netting: mindestens 1 Unit)         |
//+------------------------------------------------------------------+
void RecoverState()
  {
   ResetPosition();
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      int    dir  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl   = PositionGetDouble(POSITION_SL);

      g_units++;
      g_dir = dir;
      if(g_lastEntry == 0.0 || (dir > 0 && open > g_lastEntry) || (dir < 0 && open < g_lastEntry))
         g_lastEntry = open;
      if(sl > 0.0)
         g_stopPrice = sl;
     }

   if(g_units > 0)
     {
      double n = CalcWilderATR(InpATRPeriod);
      g_entryN = (n > 0.0) ? n : 0.0;
      if(g_stopPrice <= 0.0 && g_entryN > 0.0)
         g_stopPrice = NormalizeDouble(g_lastEntry - g_dir * InpStopN * g_entryN, _Digits);
      if(g_units > InpMaxUnits)
         g_units = InpMaxUnits;
      PrintFormat("TurtleEA: %d Unit(s) wiederhergestellt, Richtung %d, Stop %.5f",
                  g_units, g_dir, g_stopPrice);
     }
  }

//+------------------------------------------------------------------+
//| Eigenes Optimierungskriterium: Gewinn / Equity-Drawdown,          |
//| gewertet erst ab InpMinTrades Trades                              |
//+------------------------------------------------------------------+
double OnTester()
  {
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < InpMinTrades)
      return(0.0);

   double profit = TesterStatistics(STAT_PROFIT);
   double dd     = TesterStatistics(STAT_EQUITY_DD);
   if(dd <= 0.0)
      return(profit > 0.0 ? profit : 0.0);
   return(profit / dd);
  }
//+------------------------------------------------------------------+
