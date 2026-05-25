//+------------------------------------------------------------------+
//| ARE_RiskEngine.mqh                                               |
//| Adaptive Regime Engine — ATR-based sizing, SL/TP universal      |
//| Jose Yanez — 2026-05-01                                          |
//+------------------------------------------------------------------+
#ifndef ARE_RISK_ENGINE_MQH
#define ARE_RISK_ENGINE_MQH

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
double GetATR(string symbol, ENUM_TIMEFRAMES tf, int period)
{
   int handle = iATR(symbol, tf, period);
   if(handle == INVALID_HANDLE) return(0.0);
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 1, 1, buf);
   IndicatorRelease(handle);
   if(copied < 1) return(0.0);
   return(buf[0]);
}

//+------------------------------------------------------------------+
double CalcLotSize(string symbol, double riskPct, double slDistPrice, double accountBalance)
{
   if(slDistPrice <= 0.0) return(0.0);

   double riskAmount = accountBalance * riskPct / 100.0;
   double tickSize   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0) return(0.0);

   double profitPerLot = 0.0;
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   if(!OrderCalcProfit(ORDER_TYPE_BUY, symbol, 1.0, ask, ask + tickSize, profitPerLot))
      return(0.0);
   if(profitPerLot <= 0.0) return(0.0);

   double slTicks    = slDistPrice / tickSize;
   double lossPerLot = slTicks * profitPerLot;
   if(lossPerLot <= 0.0) return(0.0);

   double lots    = riskAmount / lossPerLot;
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double lotMin  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double lotMax  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lotMin, MathMin(lotMax, lots));
   return(NormalizeDouble(lots, 2));
}

//+------------------------------------------------------------------+
bool CalcSLTP_Long(string symbol, ENUM_TIMEFRAMES tf, int atrPeriod,
                   double slMulti, double tpMulti, double entryPrice,
                   double &slPrice, double &tpPrice)
{
   double atr = GetATR(symbol, tf, atrPeriod);
   if(atr <= 0.0) return(false);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   slPrice = NormalizeDouble(entryPrice - atr * slMulti, digits);
   tpPrice = NormalizeDouble(entryPrice + atr * tpMulti, digits);
   return(true);
}

//+------------------------------------------------------------------+
bool CalcSLTP_Short(string symbol, ENUM_TIMEFRAMES tf, int atrPeriod,
                    double slMulti, double tpMulti, double entryPrice,
                    double &slPrice, double &tpPrice)
{
   double atr = GetATR(symbol, tf, atrPeriod);
   if(atr <= 0.0) return(false);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   slPrice = NormalizeDouble(entryPrice + atr * slMulti, digits);
   tpPrice = NormalizeDouble(entryPrice - atr * tpMulti, digits);
   return(true);
}

//+------------------------------------------------------------------+
bool HasOpenPosition(string symbol, long magicNumber)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL)  == symbol &&
         PositionGetInteger(POSITION_MAGIC)  == magicNumber)
         return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
bool IsDDLimitReached(double maxDailyDD_pct, double maxTotalDD_pct)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   if(balance <= 0.0) return(false);

   double dd_pct = (balance - equity) / balance * 100.0;
   if(dd_pct >= maxTotalDD_pct) return(true);
   if(dd_pct >= maxDailyDD_pct) return(true);
   return(false);
}

#endif
