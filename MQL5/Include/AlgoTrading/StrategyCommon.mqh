//+------------------------------------------------------------------+
//|                                              StrategyCommon.mqh  |
//|  Gemeinsame Bausteine fuer die Strategie-EAs (MACross, Keltner,  |
//|  MeanReversion, Momentum):                                       |
//|   - Erkennung neuer Bars im Signal-Zeitrahmen                    |
//|   - ATR nach Wilder (auch als Reihe ueber mehrere Bars)          |
//|   - Positionsgroesse nach Risiko                                 |
//|   - Oeffnen, Schliessen, Stop setzen, Zustand wiederherstellen   |
//|   - Optimierungskriterium Gewinn / Equity-Drawdown               |
//|  Jeder EA haelt hoechstens eine Position (kein Pyramiding).      |
//+------------------------------------------------------------------+
#ifndef ALGOTRADING_STRATEGY_COMMON_MQH
#define ALGOTRADING_STRATEGY_COMMON_MQH

#include <Trade\Trade.mqh>

//--- Handelsrichtung
enum ENUM_TRADE_DIRECTION
  {
   DIR_BOTH       = 0,   // Long und Short
   DIR_LONG_ONLY  = 1,   // nur Long
   DIR_SHORT_ONLY = 2    // nur Short
  };

//+------------------------------------------------------------------+
bool DirectionAllowed(const ENUM_TRADE_DIRECTION mode, const int dir)
  {
   if(dir == 0)
      return(false);
   if(mode == DIR_LONG_ONLY)
      return(dir > 0);
   if(mode == DIR_SHORT_ONLY)
      return(dir < 0);
   return(true);
  }

//+------------------------------------------------------------------+
//| Optimierungskriterium: Gewinn / Equity-Drawdown ab minTrades      |
//| (gleich wie im TurtleEA, damit die Ergebnisse vergleichbar sind)  |
//+------------------------------------------------------------------+
double ProfitDrawdownScore(const int minTrades)
  {
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < minTrades)
      return(0.0);

   double profit = TesterStatistics(STAT_PROFIT);
   double dd     = TesterStatistics(STAT_EQUITY_DD);
   if(dd <= 0.0)
      return(profit > 0.0 ? profit : 0.0);
   return(profit / dd);
  }

//+------------------------------------------------------------------+
//| Hilfsklasse: ein Symbol, ein Zeitrahmen, eine Magic Number        |
//+------------------------------------------------------------------+
class CStrategyHelper
  {
private:
   string            m_name;
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;
   ulong             m_magic;
   datetime          m_lastBar;

   bool              IsMine(void);
   double            RoundToTick(const double price);
   bool              StopDistanceOk(const int dir, const double stop);

public:
   CTrade            trade;

                     CStrategyHelper(void) : m_name(""), m_symbol(""), m_tf(PERIOD_CURRENT),
                                             m_magic(0), m_lastBar(0) {}

   void              Init(const string name, const ENUM_TIMEFRAMES tf,
                          const ulong magic, const int slippage);
   ENUM_TIMEFRAMES   Timeframe(void) const { return(m_tf); }

   //--- neue Bar: BarPending() so lange true, bis BarProcessed() aufgerufen wurde
   bool              BarPending(void);
   void              BarProcessed(void);

   //--- Marktdaten
   bool              EnoughBars(const int needed);
   bool              WilderATRSeries(const int period, const int count, double &out[]);
   double            WilderATR(const int period);

   //--- Positionen
   double            VolumeForRisk(const double stopDistance, const double riskPercent);
   bool              OpenPosition(const int dir, const double volume, const double stop,
                                  const string comment);
   void              CloseAll(void);
   int               CountPositions(void);
   int               PositionDir(void);
   datetime          PositionOpenTime(void);
   void              SetStop(const double stop);
   bool              StopHit(const int dir, const double stop);
   int               RecoverPosition(double &stop, double &openPrice);
  };

//+------------------------------------------------------------------+
void CStrategyHelper::Init(const string name, const ENUM_TIMEFRAMES tf,
                           const ulong magic, const int slippage)
  {
   m_name    = name;
   m_symbol  = _Symbol;
   m_tf      = (tf == PERIOD_CURRENT) ? (ENUM_TIMEFRAMES)_Period : tf;
   m_magic   = magic;
   m_lastBar = 0;

   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(slippage);
   trade.SetTypeFillingBySymbol(m_symbol);
  }

//+------------------------------------------------------------------+
bool CStrategyHelper::BarPending(void)
  {
   datetime t = iTime(m_symbol, m_tf, 0);
   return(t != 0 && t != m_lastBar);
  }

//+------------------------------------------------------------------+
void CStrategyHelper::BarProcessed(void)
  {
   datetime t = iTime(m_symbol, m_tf, 0);
   if(t != 0)
      m_lastBar = t;
  }

//+------------------------------------------------------------------+
bool CStrategyHelper::EnoughBars(const int needed)
  {
   return(Bars(m_symbol, m_tf) >= needed + 1);
  }

//+------------------------------------------------------------------+
//| ATR nach Wilder fuer die letzten 'count' geschlossenen Bars.      |
//| out[0] = Shift 1 (zuletzt geschlossene Bar), out[1] = Shift 2 ... |
//| Startwert = SMA der ersten 'period' True Ranges, danach           |
//| ATR = (ATR_alt * (period-1) + TR) / period.                       |
//+------------------------------------------------------------------+
bool CStrategyHelper::WilderATRSeries(const int period, const int count, double &out[])
  {
   if(period < 1 || count < 1)
      return(false);

   int available = Bars(m_symbol, m_tf) - 1;            // ohne laufende Bar
   int wanted    = period * 10 + count + 1;             // Einschwingphase
   int n         = MathMin(wanted, available);
   if(n < period + count + 1)
      return(false);

   MqlRates rates[];
   ArraySetAsSeries(rates, false);                       // aelteste zuerst
   int copied = CopyRates(m_symbol, m_tf, 1, n, rates);
   if(copied < period + count + 1)
      return(false);

   if(ArrayResize(out, count) != count)
      return(false);
   ArrayInitialize(out, 0.0);

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

      int idx = copied - 1 - i;                          // 0 = neueste geschlossene Bar
      if(i >= period && idx < count)
         out[idx] = atr;
     }

   for(int k = 0; k < count; k++)
      if(out[k] <= 0.0)
         return(false);
   return(true);
  }

//+------------------------------------------------------------------+
double CStrategyHelper::WilderATR(const int period)
  {
   double buf[];
   if(!WilderATRSeries(period, 1, buf))
      return(0.0);
   return(buf[0]);
  }

//+------------------------------------------------------------------+
//| Volumen so, dass 'stopDistance' Kursbewegung 'riskPercent' %      |
//| der Equity kostet. 0 = Konto zu klein fuer das Mindestvolumen.    |
//+------------------------------------------------------------------+
double CStrategyHelper::VolumeForRisk(const double stopDistance, const double riskPercent)
  {
   double equity    = AccountInfoDouble(ACCOUNT_EQUITY);
   double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   if(equity <= 0.0 || tickValue <= 0.0 || tickSize <= 0.0 ||
      stopDistance <= 0.0 || riskPercent <= 0.0)
      return(0.0);

   double moneyPerLot = stopDistance / tickSize * tickValue;
   double volume      = equity * riskPercent / 100.0 / moneyPerLot;

   double minVol  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxVol  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double stepVol = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   if(stepVol <= 0.0)
      stepVol = minVol;
   if(stepVol <= 0.0)
      return(0.0);

   volume = MathFloor(volume / stepVol + 1e-9) * stepVol;
   if(volume < minVol)
      return(0.0);
   if(maxVol > 0.0 && volume > maxVol)
      volume = maxVol;

   int digits = (int)MathMax(0.0, MathCeil(-MathLog10(stepVol)));
   return(NormalizeDouble(volume, digits));
  }

//+------------------------------------------------------------------+
double CStrategyHelper::RoundToTick(const double price)
  {
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   int    digits   = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   double p        = price;
   if(tickSize > 0.0)
      p = MathRound(price / tickSize) * tickSize;
   return(NormalizeDouble(p, digits));
  }

//+------------------------------------------------------------------+
//| Liegt der Stop weit genug vom Kurs (Broker-Mindestabstand)?       |
//+------------------------------------------------------------------+
bool CStrategyHelper::StopDistanceOk(const int dir, const double stop)
  {
   if(stop <= 0.0)
      return(false);
   double point   = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double minDist = (double)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   if(dir > 0)
      return(stop < SymbolInfoDouble(m_symbol, SYMBOL_BID) - minDist);
   return(stop > SymbolInfoDouble(m_symbol, SYMBOL_ASK) + minDist);
  }

//+------------------------------------------------------------------+
//| Position eroeffnen. stop <= 0: ohne Broker-Stop. Liegt der Stop   |
//| zu nah am Kurs, wird ohne Broker-Stop eroeffnet; der EA prueft    |
//| ihn dann intern (StopHit).                                        |
//+------------------------------------------------------------------+
bool CStrategyHelper::OpenPosition(const int dir, const double volume, const double stop,
                                   const string comment)
  {
   if(dir == 0 || volume <= 0.0)
      return(false);

   ENUM_ORDER_TYPE type  = (dir > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double          price = (dir > 0) ? SymbolInfoDouble(m_symbol, SYMBOL_ASK)
                                     : SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double margin = 0.0;
   if(OrderCalcMargin(type, m_symbol, volume, price, margin) &&
      margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     {
      PrintFormat("%s: nicht genug freie Margin fuer %.2f Lots", m_name, volume);
      return(false);
     }

   double sl = 0.0;
   if(stop > 0.0)
     {
      sl = RoundToTick(stop);
      if(!StopDistanceOk(dir, sl))
         sl = 0.0;
     }

   bool ok = (dir > 0) ? trade.Buy(volume, m_symbol, 0.0, sl, 0.0, comment)
                       : trade.Sell(volume, m_symbol, 0.0, sl, 0.0, comment);
   uint rc = trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED))
     {
      PrintFormat("%s: Order fehlgeschlagen, Retcode %u %s", m_name, rc,
                  trade.ResultRetcodeDescription());
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
bool CStrategyHelper::IsMine(void)
  {
   return(PositionGetString(POSITION_SYMBOL) == m_symbol &&
          (ulong)PositionGetInteger(POSITION_MAGIC) == m_magic);
  }

//+------------------------------------------------------------------+
void CStrategyHelper::CloseAll(void)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsMine())
         continue;
      if(!trade.PositionClose(ticket))
         PrintFormat("%s: Schliessen fehlgeschlagen, Ticket %I64u Retcode %u",
                     m_name, ticket, trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
int CStrategyHelper::CountPositions(void)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket != 0 && IsMine())
         count++;
     }
   return(count);
  }

//+------------------------------------------------------------------+
//| +1 long, -1 short, 0 flat                                         |
//+------------------------------------------------------------------+
int CStrategyHelper::PositionDir(void)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsMine())
         continue;
      return(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 1 : -1);
     }
   return(0);
  }

//+------------------------------------------------------------------+
//| Eroeffnungszeit der aeltesten eigenen Position (0 = keine)        |
//+------------------------------------------------------------------+
datetime CStrategyHelper::PositionOpenTime(void)
  {
   datetime oldest = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsMine())
         continue;
      datetime t = (datetime)PositionGetInteger(POSITION_TIME);
      if(oldest == 0 || t < oldest)
         oldest = t;
     }
   return(oldest);
  }

//+------------------------------------------------------------------+
//| Stop auf alle eigenen Positionen setzen (falls Abstand erlaubt)   |
//+------------------------------------------------------------------+
void CStrategyHelper::SetStop(const double stop)
  {
   if(stop <= 0.0)
      return;
   double sl    = RoundToTick(stop);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsMine())
         continue;

      double curSL = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      if(MathAbs(curSL - sl) < point / 2.0)
         continue;

      int dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      if(!StopDistanceOk(dir, sl))
         continue;                       // interner Stop greift stattdessen

      if(!trade.PositionModify(ticket, sl, tp))
         PrintFormat("%s: Stop-Anpassung fehlgeschlagen, Ticket %I64u Retcode %u",
                     m_name, ticket, trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//| Interner Stop (Backup zum Broker-Stop), tickgenau                 |
//+------------------------------------------------------------------+
bool CStrategyHelper::StopHit(const int dir, const double stop)
  {
   if(stop <= 0.0 || dir == 0)
      return(false);
   if(dir > 0)
      return(SymbolInfoDouble(m_symbol, SYMBOL_BID) <= stop);
   return(SymbolInfoDouble(m_symbol, SYMBOL_ASK) >= stop);
  }

//+------------------------------------------------------------------+
//| Nach Neustart: Richtung und Stop aus offenen Positionen lesen      |
//+------------------------------------------------------------------+
int CStrategyHelper::RecoverPosition(double &stop, double &openPrice)
  {
   stop      = 0.0;
   openPrice = 0.0;
   int dir = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsMine())
         continue;
      dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double sl = PositionGetDouble(POSITION_SL);
      if(sl > 0.0)
         stop = sl;
      openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
     }
   if(dir != 0)
      PrintFormat("%s: Position wiederhergestellt, Richtung %d, Stop %.5f", m_name, dir, stop);
   return(dir);
  }

#endif // ALGOTRADING_STRATEGY_COMMON_MQH
//+------------------------------------------------------------------+
