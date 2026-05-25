//+------------------------------------------------------------------+
//| ARE_MeanReversion.mqh                                            |
//| Adaptive Regime Engine — Módulo Mean Reversion                   |
//| Condición: RSI extremo + BB extremo + vela de rechazo            |
//| Jose Yanez — 2026-05-01                                          |
//+------------------------------------------------------------------+
#ifndef ARE_MEAN_REVERSION_MQH
#define ARE_MEAN_REVERSION_MQH

enum ENUM_MR_SIGNAL
{
   MR_LONG  =  1,
   MR_SHORT = -1,
   MR_NONE  =  0
};

//+------------------------------------------------------------------+
ENUM_MR_SIGNAL GetMRSignal(string symbol, ENUM_TIMEFRAMES tf,
                            int rsiPeriod, double rsiOS, double rsiOB,
                            int bbPeriod,  double bbDev)
{
   // RSI
   int rsiH = iRSI(symbol, tf, rsiPeriod, PRICE_CLOSE);
   if(rsiH == INVALID_HANDLE) return(MR_NONE);
   double rsiBuf[];
   ArraySetAsSeries(rsiBuf, true);
   int rc = CopyBuffer(rsiH, 0, 1, 1, rsiBuf);
   IndicatorRelease(rsiH);
   if(rc < 1) return(MR_NONE);
   double rsi = rsiBuf[0];

   // Bollinger Bands
   int bbH = iBands(symbol, tf, bbPeriod, 0, bbDev, PRICE_CLOSE);
   if(bbH == INVALID_HANDLE) return(MR_NONE);
   double bbUp[], bbLo[];
   ArraySetAsSeries(bbUp, true);
   ArraySetAsSeries(bbLo, true);
   int bu = CopyBuffer(bbH, 1, 1, 1, bbUp);
   int bl = CopyBuffer(bbH, 2, 1, 1, bbLo);
   IndicatorRelease(bbH);
   if(bu < 1 || bl < 1) return(MR_NONE);

   // Vela cerrada shift=1
   double close1 = iClose(symbol, tf, 1);
   double open1  = iOpen(symbol,  tf, 1);
   if(close1 == 0.0) return(MR_NONE);

   // LONG: oversold + bajo BB lower + vela alcista (rechazo)
   if(rsi < rsiOS && close1 < bbLo[0] && close1 > open1)
      return(MR_LONG);

   // SHORT: overbought + sobre BB upper + vela bajista (rechazo)
   if(rsi > rsiOB && close1 > bbUp[0] && close1 < open1)
      return(MR_SHORT);

   return(MR_NONE);
}

//+------------------------------------------------------------------+
double GetRSIValue(string symbol, ENUM_TIMEFRAMES tf, int period)
{
   int h = iRSI(symbol, tf, period, PRICE_CLOSE);
   if(h == INVALID_HANDLE) return(-1.0);
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(h, 0, 1, 1, buf);
   IndicatorRelease(h);
   if(copied < 1) return(-1.0);
   return(buf[0]);
}

#endif
