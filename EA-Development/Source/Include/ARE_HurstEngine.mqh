//+------------------------------------------------------------------+
//| ARE_HurstEngine.mqh                                              |
//| Adaptive Regime Engine — Hurst Exponent via Rescaled Range (R/S) |
//| Jose Yanez — 2026-05-01                                          |
//+------------------------------------------------------------------+
#ifndef ARE_HURST_ENGINE_MQH
#define ARE_HURST_ENGINE_MQH

#define HURST_TREND   0.55
#define HURST_REVERT  0.45

enum ENUM_REGIME
{
   REGIME_BREAKOUT       =  1,
   REGIME_MEAN_REVERSION = -1,
   REGIME_NEUTRAL        =  0
};

//+------------------------------------------------------------------+
double HurstRS(const double &price[], int period)
{
   int sz = ArraySize(price);
   if(sz < period || period < 20) return(-1.0);

   // Retornos logarítmicos (índice 0 = más antiguo)
   int n = period - 1;
   double returns[];
   ArrayResize(returns, n);
   for(int i = 0; i < n; i++)
   {
      int pi = sz - period + i;
      if(price[pi] <= 0.0 || price[pi+1] <= 0.0) return(-1.0);
      returns[i] = MathLog(price[pi+1] / price[pi]);
   }

   // Tamaños de subserie
   int sub0 = (int)MathMax(n / 4, 4);
   int sub1 = (int)MathMax(n / 3, 4);
   int sub2 = (int)MathMax(n / 2, 4);
   int sub3 = n;

   int    subs[4];
   subs[0] = sub0; subs[1] = sub1; subs[2] = sub2; subs[3] = sub3;

   double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_x2 = 0.0;
   int    cnt   = 0;

   for(int s = 0; s < 4; s++)
   {
      int sub = subs[s];
      if(sub < 4) continue;
      int num_sub = n / sub;
      if(num_sub < 1) continue;

      double rs_sum = 0.0;
      int    rs_cnt = 0;

      for(int k = 0; k < num_sub; k++)
      {
         int start = k * sub;
         int end   = start + sub;

         double lmean = 0.0;
         for(int i = start; i < end; i++) lmean += returns[i];
         lmean /= sub;

         double lvar = 0.0;
         for(int i = start; i < end; i++) lvar += (returns[i]-lmean)*(returns[i]-lmean);
         double lstd = MathSqrt(lvar / sub);
         if(lstd <= 0.0) continue;

         double cum = 0.0, maxc = -1e300, minc = 1e300;
         for(int i = start; i < end; i++)
         {
            cum += (returns[i] - lmean);
            if(cum > maxc) maxc = cum;
            if(cum < minc) minc = cum;
         }

         double rs = (maxc - minc) / lstd;
         if(rs <= 0.0) continue;
         rs_sum += rs;
         rs_cnt++;
      }

      if(rs_cnt == 0) continue;
      double avg_rs = rs_sum / rs_cnt;
      if(avg_rs <= 0.0) continue;

      double lx = MathLog((double)sub);
      double ly = MathLog(avg_rs);
      sum_x  += lx;
      sum_y  += ly;
      sum_xy += lx * ly;
      sum_x2 += lx * lx;
      cnt++;
   }

   if(cnt < 2) return(-1.0);

   double denom = cnt * sum_x2 - sum_x * sum_x;
   if(denom == 0.0) return(-1.0);

   double H = (cnt * sum_xy - sum_x * sum_y) / denom;
   if(H < 0.0) H = 0.0;
   if(H > 1.0) H = 1.0;
   return(H);
}

//+------------------------------------------------------------------+
ENUM_REGIME GetRegime(double H)
{
   if(H < 0.0)             return(REGIME_NEUTRAL);
   if(H > HURST_TREND)     return(REGIME_BREAKOUT);
   if(H < HURST_REVERT)    return(REGIME_MEAN_REVERSION);
   return(REGIME_NEUTRAL);
}

//+------------------------------------------------------------------+
ENUM_REGIME GetCurrentRegime(string symbol, ENUM_TIMEFRAMES tf, int period)
{
   double closes[];
   ArraySetAsSeries(closes, false);
   if(CopyClose(symbol, tf, 0, period + 2, closes) < period) return(REGIME_NEUTRAL);
   return(GetRegime(HurstRS(closes, period)));
}

//+------------------------------------------------------------------+
double GetHurstValue(string symbol, ENUM_TIMEFRAMES tf, int period)
{
   double closes[];
   ArraySetAsSeries(closes, false);
   if(CopyClose(symbol, tf, 0, period + 2, closes) < period) return(-1.0);
   return(HurstRS(closes, period));
}

#endif
