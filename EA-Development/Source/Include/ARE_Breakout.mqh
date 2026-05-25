//+------------------------------------------------------------------+
//| ARE_Breakout.mqh                                                 |
//| Adaptive Regime Engine — Módulo Breakout                         |
//| Filtros: BOS + Body Ratio (B) + Swing HH/HL opcional (C)        |
//| Jose Yanez — 2026-05-01                                          |
//+------------------------------------------------------------------+
#ifndef ARE_BREAKOUT_MQH
#define ARE_BREAKOUT_MQH

enum ENUM_BO_SIGNAL
{
   BO_LONG  =  1,
   BO_SHORT = -1,
   BO_NONE  =  0
};

//+------------------------------------------------------------------+
//| Busca el precio del último pivot high (type=1) o low (type=-1)   |
//+------------------------------------------------------------------+
double FindLastSwing(string symbol, ENUM_TIMEFRAMES tf, int lookback, int type)
{
   for(int i = 2; i < 200; i++)
   {
      if(type == 1)
      {
         double hc = iHigh(symbol, tf, i);
         bool   ok = true;
         for(int j = 1; j <= lookback && ok; j++)
         {
            if(iHigh(symbol, tf, i+j) >= hc) ok = false;
            if(iHigh(symbol, tf, i-j) >= hc) ok = false;
         }
         if(ok) return(hc);
      }
      else
      {
         double lc = iLow(symbol, tf, i);
         bool   ok = true;
         for(int j = 1; j <= lookback && ok; j++)
         {
            if(iLow(symbol, tf, i+j) <= lc) ok = false;
            if(iLow(symbol, tf, i-j) <= lc) ok = false;
         }
         if(ok) return(lc);
      }
   }
   return(0.0);
}

//+------------------------------------------------------------------+
bool IsSwingBullish(string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   // Necesitamos dos pivot highs y dos pivot lows consecutivos
   double ph1 = 0.0, ph2 = 0.0, pl1 = 0.0, pl2 = 0.0;
   int    phCount = 0, plCount = 0;

   for(int i = 2; i < 300 && (phCount < 2 || plCount < 2); i++)
   {
      // Pivot high
      if(phCount < 2)
      {
         double hc = iHigh(symbol, tf, i);
         bool ok = true;
         for(int j = 1; j <= lookback && ok; j++)
         {
            if(iHigh(symbol, tf, i+j) >= hc) ok = false;
            if(i-j >= 1 && iHigh(symbol, tf, i-j) >= hc) ok = false;
         }
         if(ok) { phCount++; if(phCount==1) ph1=hc; else ph2=hc; }
      }
      // Pivot low
      if(plCount < 2)
      {
         double lc = iLow(symbol, tf, i);
         bool ok = true;
         for(int j = 1; j <= lookback && ok; j++)
         {
            if(iLow(symbol, tf, i+j) <= lc) ok = false;
            if(i-j >= 1 && iLow(symbol, tf, i-j) <= lc) ok = false;
         }
         if(ok) { plCount++; if(plCount==1) pl1=lc; else pl2=lc; }
      }
   }

   if(phCount < 2 || plCount < 2) return(false);
   return(ph1 > ph2 && pl1 > pl2);  // HH + HL
}

//+------------------------------------------------------------------+
bool IsSwingBearish(string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   double ph1 = 0.0, ph2 = 0.0, pl1 = 0.0, pl2 = 0.0;
   int    phCount = 0, plCount = 0;

   for(int i = 2; i < 300 && (phCount < 2 || plCount < 2); i++)
   {
      if(phCount < 2)
      {
         double hc = iHigh(symbol, tf, i);
         bool ok = true;
         for(int j = 1; j <= lookback && ok; j++)
         {
            if(iHigh(symbol, tf, i+j) >= hc) ok = false;
            if(i-j >= 1 && iHigh(symbol, tf, i-j) >= hc) ok = false;
         }
         if(ok) { phCount++; if(phCount==1) ph1=hc; else ph2=hc; }
      }
      if(plCount < 2)
      {
         double lc = iLow(symbol, tf, i);
         bool ok = true;
         for(int j = 1; j <= lookback && ok; j++)
         {
            if(iLow(symbol, tf, i+j) <= lc) ok = false;
            if(i-j >= 1 && iLow(symbol, tf, i-j) <= lc) ok = false;
         }
         if(ok) { plCount++; if(plCount==1) pl1=lc; else pl2=lc; }
      }
   }

   if(phCount < 2 || plCount < 2) return(false);
   return(ph1 < ph2 && pl1 < pl2);  // LH + LL
}

//+------------------------------------------------------------------+
ENUM_BO_SIGNAL GetBOSignal(string symbol, ENUM_TIMEFRAMES tf,
                            int    bosPeriod,
                            double bodyRatioMin,
                            double momentumATRMin,
                            bool   useSwingFilter,
                            int    swingLookback,
                            int    atrPeriod)
{
   // ATR
   int atrH = iATR(symbol, tf, atrPeriod);
   if(atrH == INVALID_HANDLE) return(BO_NONE);
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   int ac = CopyBuffer(atrH, 0, 1, 1, atrBuf);
   IndicatorRelease(atrH);
   if(ac < 1) return(BO_NONE);
   double atr = atrBuf[0];
   if(atr <= 0.0) return(BO_NONE);

   // Vela cerrada shift=1
   double close1 = iClose(symbol, tf, 1);
   double open1  = iOpen(symbol,  tf, 1);
   double high1  = iHigh(symbol,  tf, 1);
   double low1   = iLow(symbol,   tf, 1);
   if(close1 == 0.0 || high1 <= low1) return(BO_NONE);

   double bodySize   = MathAbs(close1 - open1);
   double totalRange = high1 - low1;
   double bodyRatio  = bodySize / totalRange;
   double bodyATR    = bodySize / atr;

   // Highest/Lowest de las N barras previas (shift 2..bosPeriod+1)
   double highest = 0.0;
   double lowest  = 1e300;
   for(int i = 2; i <= bosPeriod + 1; i++)
   {
      double h = iHigh(symbol, tf, i);
      double l = iLow(symbol,  tf, i);
      if(h > highest) highest = h;
      if(l < lowest)  lowest  = l;
   }

   bool bullfiltB = (bodyRatio >= bodyRatioMin && bodyATR >= momentumATRMin && close1 > open1);
   bool bearfiltB = (bodyRatio >= bodyRatioMin && bodyATR >= momentumATRMin && close1 < open1);

   // LONG
   if(close1 > highest && bullfiltB)
   {
      if(useSwingFilter && !IsSwingBullish(symbol, tf, swingLookback)) return(BO_NONE);
      return(BO_LONG);
   }

   // SHORT
   if(close1 < lowest && bearfiltB)
   {
      if(useSwingFilter && !IsSwingBearish(symbol, tf, swingLookback)) return(BO_NONE);
      return(BO_SHORT);
   }

   return(BO_NONE);
}

#endif
