//+------------------------------------------------------------------+
//| ARE_CSVLogger.mqh                                                |
//| Adaptive Regime Engine — CSV trade logger con atribución módulo  |
//| Jose Yanez — 2026-05-01                                          |
//+------------------------------------------------------------------+
#ifndef ARE_CSV_LOGGER_MQH
#define ARE_CSV_LOGGER_MQH

struct ARETradeRecord
{
   ulong     ticket;
   datetime  dtOpen;
   datetime  dtClose;
   string    symbol;
   string    module;
   double    hurstValue;
   string    regimeLabel;
   double    rsiAtEntry;
   double    atrAtEntry;
   double    slMulti;
   double    tpMulti;
   double    rrRatio;
   double    entryPrice;
   double    slPrice;
   double    tpPrice;
   double    exitPrice;
   string    exitType;
   double    profitUSD;
   double    profitR;
   int       durationMin;
};

//+------------------------------------------------------------------+
void CSVWriteHeader(string filePath)
{
   if(FileIsExist(filePath, FILE_COMMON)) return;

   int h = FileOpen(filePath, FILE_WRITE | FILE_COMMON, ',');
   if(h == INVALID_HANDLE) return;

   FileWrite(h,
      "ticket","datetime_open","datetime_close","symbol","module",
      "hurst_value","regime_label","rsi_at_entry","atr_at_entry",
      "sl_multi","tp_multi","rr_ratio",
      "entry_price","sl_price","tp_price","exit_price","exit_type",
      "profit_usd","profit_r","duration_min");
   FileClose(h);
}

//+------------------------------------------------------------------+
void CSVWriteTrade(string filePath, const ARETradeRecord &rec)
{
   CSVWriteHeader(filePath);

   int h = FileOpen(filePath, FILE_READ | FILE_WRITE | FILE_COMMON, ',');
   if(h == INVALID_HANDLE) return;
   FileSeek(h, 0, SEEK_END);

   FileWrite(h,
      IntegerToString((long)rec.ticket),
      TimeToString(rec.dtOpen,  TIME_DATE|TIME_MINUTES),
      TimeToString(rec.dtClose, TIME_DATE|TIME_MINUTES),
      rec.symbol,
      rec.module,
      DoubleToString(rec.hurstValue,  4),
      rec.regimeLabel,
      DoubleToString(rec.rsiAtEntry,  2),
      DoubleToString(rec.atrAtEntry,  5),
      DoubleToString(rec.slMulti,     2),
      DoubleToString(rec.tpMulti,     2),
      DoubleToString(rec.rrRatio,     2),
      DoubleToString(rec.entryPrice,  5),
      DoubleToString(rec.slPrice,     5),
      DoubleToString(rec.tpPrice,     5),
      DoubleToString(rec.exitPrice,   5),
      rec.exitType,
      DoubleToString(rec.profitUSD,   2),
      DoubleToString(rec.profitR,     3),
      IntegerToString(rec.durationMin));
   FileClose(h);
}

//+------------------------------------------------------------------+
string GetCSVFilePath(string symbol)
{
   return("ARE_" + symbol + "_trades.csv");
}

//+------------------------------------------------------------------+
string BuildOrderComment(string module, double hurstValue)
{
   return("ARE_" + StringSubstr(module, 0, 2) + "|H=" + DoubleToString(hurstValue, 3));
}

//+------------------------------------------------------------------+
string DetectExitType(double exitPrice, double slPrice, double tpPrice, bool isLong)
{
   double slDist = MathAbs(exitPrice - slPrice);
   double tpDist = MathAbs(exitPrice - tpPrice);
   if(tpDist < slDist) return("TP");
   if(slDist < tpDist) return("SL");
   return("MANUAL");
}

#endif
