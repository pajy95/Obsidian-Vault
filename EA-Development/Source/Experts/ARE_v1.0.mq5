//+------------------------------------------------------------------+
//| ARE_v1.0.mq5                                                     |
//| Adaptive Regime Engine — EA principal                            |
//| Detecta régimen via Hurst R/S → ejecuta MR o Breakout           |
//| Jose Yanez — 2026-05-01                                          |
//+------------------------------------------------------------------+
#property copyright "Jose Yanez"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include "..\\Include\\ARE_HurstEngine.mqh"
#include "..\\Include\\ARE_RiskEngine.mqh"
#include "..\\Include\\ARE_MeanReversion.mqh"
#include "..\\Include\\ARE_Breakout.mqh"
#include "..\\Include\\ARE_CSVLogger.mqh"

//--- REGIME DETECTOR
input int    InpHurst_Period        = 200;   // Hurst rolling window (barras)

//--- MEAN REVERSION
input int    InpRSI_Period          = 14;    // RSI period
input double InpRSI_OB              = 72.0;  // RSI overbought threshold
input double InpRSI_OS              = 28.0;  // RSI oversold threshold
input int    InpBB_Period           = 20;    // Bollinger Bands period
input double InpBB_Dev              = 2.0;   // Bollinger Bands deviation

//--- BREAKOUT
input int    InpBOS_Period          = 20;    // BOS lookback (Highest/Lowest)
input double InpBodyRatio_Min       = 0.6;   // Min candle body ratio
input double InpMomentum_ATR_Min    = 1.5;   // Min body size in ATR multiples
input bool   InpUseSwingFilter      = true;  // Enable Swing Structure filter (HH/HL)
input int    InpSwing_Lookback      = 3;     // Swing pivot lookback bars

//--- RISK ENGINE
input int    InpATR_Period          = 14;    // ATR period (sizing + SL/TP)
input double InpSL_ATR_Multi        = 1.5;   // SL multiplier (x ATR)
input double InpTP_ATR_Multi        = 3.0;   // TP multiplier (x ATR)
input double InpRisk_Pct            = 1.0;   // Risk per trade (% balance)

//--- EA CONFIG
input int    InpMagicNumber         = 77700;
input double InpMaxDailyDD          = 3.0;   // Daily DD halt (%)
input double InpMaxTotalDD          = 6.0;   // Total DD halt (%)

//--- Objetos globales
CTrade  g_trade;
string  g_csvPath;
datetime g_lastBarTime = 0;

//--- Registro de trade abierto activo
struct OpenTradeInfo
{
   ulong    ticket;
   string   module;
   double   hurstAtEntry;
   double   rsiAtEntry;
   double   atrAtEntry;
   double   entryPrice;
   double   slPrice;
   double   tpPrice;
   double   riskAmount;
   datetime openTime;
   bool     isLong;
   bool     active;
};
OpenTradeInfo g_openTrade;

//+------------------------------------------------------------------+
int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);

   g_csvPath = GetCSVFilePath(_Symbol);
   CSVWriteHeader(g_csvPath);

   ZeroMemory(g_openTrade);
   g_openTrade.active = false;

   Print("ARE v1.0 iniciado | Símbolo: ", _Symbol,
         " | TF: ", EnumToString(_Period),
         " | Hurst period: ", InpHurst_Period);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("ARE v1.0 detenido. Razón: ", reason);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // --- Ejecutar solo en nueva barra
   datetime barTime = iTime(_Symbol, _Period, 0);
   if(barTime == g_lastBarTime) return;
   g_lastBarTime = barTime;

   // --- Verificar cierre de trade abierto
   if(g_openTrade.active)
      CheckTradeClose();

   // --- Control de drawdown
   if(IsDDLimitReached(InpMaxDailyDD, InpMaxTotalDD))
   {
      Print("ARE: DD limit alcanzado — trading suspendido");
      return;
   }

   // --- No abrir si ya hay posición activa
   if(HasOpenPosition(_Symbol, InpMagicNumber)) return;

   // --- Detectar régimen
   ENUM_REGIME regime = GetCurrentRegime(_Symbol, _Period, InpHurst_Period);
   if(regime == REGIME_NEUTRAL) return;

   double hurstVal = GetHurstValue(_Symbol, _Period, InpHurst_Period);
   double atrVal   = GetATR(_Symbol, _Period, InpATR_Period);
   if(atrVal <= 0.0) return;

   // --- Evaluar señales según régimen
   if(regime == REGIME_MEAN_REVERSION)
      ProcessMRSignal(hurstVal, atrVal);
   else if(regime == REGIME_BREAKOUT)
      ProcessBOSignal(hurstVal, atrVal);
}

//+------------------------------------------------------------------+
void ProcessMRSignal(double hurstVal, double atrVal)
{
   ENUM_MR_SIGNAL sig = GetMRSignal(_Symbol, _Period,
                                     InpRSI_Period, InpRSI_OS, InpRSI_OB,
                                     InpBB_Period,  InpBB_Dev);
   if(sig == MR_NONE) return;

   double rsiVal = GetRSIValue(_Symbol, _Period, InpRSI_Period);
   ExecuteTrade(sig == MR_LONG, "MEAN_REVERSION", hurstVal, rsiVal, atrVal);
}

//+------------------------------------------------------------------+
void ProcessBOSignal(double hurstVal, double atrVal)
{
   ENUM_BO_SIGNAL sig = GetBOSignal(_Symbol, _Period,
                                     InpBOS_Period,
                                     InpBodyRatio_Min,
                                     InpMomentum_ATR_Min,
                                     InpUseSwingFilter,
                                     InpSwing_Lookback,
                                     InpATR_Period);
   if(sig == BO_NONE) return;

   double rsiVal = GetRSIValue(_Symbol, _Period, InpRSI_Period);
   ExecuteTrade(sig == BO_LONG, "BREAKOUT", hurstVal, rsiVal, atrVal);
}

//+------------------------------------------------------------------+
void ExecuteTrade(bool     isLong,
                  string   module,
                  double   hurstVal,
                  double   rsiVal,
                  double   atrVal)
{
   double slPrice = 0.0, tpPrice = 0.0;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entryPrice = isLong ? ask : bid;

   bool ok = isLong
             ? CalcSLTP_Long(_Symbol,  _Period, InpATR_Period, InpSL_ATR_Multi, InpTP_ATR_Multi, entryPrice, slPrice, tpPrice)
             : CalcSLTP_Short(_Symbol, _Period, InpATR_Period, InpSL_ATR_Multi, InpTP_ATR_Multi, entryPrice, slPrice, tpPrice);
   if(!ok) return;

   double slDist = MathAbs(entryPrice - slPrice);
   double lots   = CalcLotSize(_Symbol, InpRisk_Pct, slDist,
                                AccountInfoDouble(ACCOUNT_BALANCE));
   if(lots <= 0.0) return;

   string comment = BuildOrderComment(module, hurstVal);
   bool   placed  = false;

   if(isLong)
      placed = g_trade.Buy(lots, _Symbol, ask, slPrice, tpPrice, comment);
   else
      placed = g_trade.Sell(lots, _Symbol, bid, slPrice, tpPrice, comment);

   if(!placed)
   {
      Print("ARE: Error al abrir orden | ", module,
            " | Error: ", GetLastError());
      return;
   }

   // --- Registrar trade abierto
   g_openTrade.ticket      = g_trade.ResultOrder();
   g_openTrade.module      = module;
   g_openTrade.hurstAtEntry = hurstVal;
   g_openTrade.rsiAtEntry  = rsiVal;
   g_openTrade.atrAtEntry  = atrVal;
   g_openTrade.entryPrice  = entryPrice;
   g_openTrade.slPrice     = slPrice;
   g_openTrade.tpPrice     = tpPrice;
   g_openTrade.riskAmount  = AccountInfoDouble(ACCOUNT_BALANCE) * InpRisk_Pct / 100.0;
   g_openTrade.openTime    = TimeCurrent();
   g_openTrade.isLong      = isLong;
   g_openTrade.active      = true;

   Print("ARE: ", module, " | ", (isLong ? "BUY" : "SELL"),
         " | Lots=", lots,
         " | Entry=", entryPrice,
         " | SL=", slPrice,
         " | TP=", tpPrice,
         " | H=", DoubleToString(hurstVal, 3));
}

//+------------------------------------------------------------------+
//| Verifica si el trade activo se cerró y lo loguea                |
//+------------------------------------------------------------------+
void CheckTradeClose()
{
   if(!g_openTrade.active) return;

   // Buscar en historial de deals
   HistorySelect(g_openTrade.openTime - 1, TimeCurrent() + 1);

   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0) continue;

      // Buscar deal de cierre asociado al orden de apertura
      ulong dealOrder = (ulong)HistoryDealGetInteger(dealTicket, DEAL_ORDER);
      if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      // Verificar que sea nuestro magic
      if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != InpMagicNumber) continue;

      // Verificar símbolo
      if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) continue;

      double exitPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
      double profitUSD = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) +
                         HistoryDealGetDouble(dealTicket, DEAL_SWAP)   +
                         HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
      datetime closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);

      // Calcular profit en R
      double profitR = (g_openTrade.riskAmount > 0.0)
                       ? profitUSD / g_openTrade.riskAmount : 0.0;

      int durationMin = (int)((closeTime - g_openTrade.openTime) / 60);

      string exitType = DetectExitType(exitPrice,
                                        g_openTrade.slPrice,
                                        g_openTrade.tpPrice,
                                        g_openTrade.isLong);

      // --- Construir registro CSV
      ARETradeRecord rec;
      rec.ticket       = g_openTrade.ticket;
      rec.dtOpen       = g_openTrade.openTime;
      rec.dtClose      = closeTime;
      rec.symbol       = _Symbol;
      rec.module       = g_openTrade.module;
      rec.hurstValue   = g_openTrade.hurstAtEntry;
      rec.regimeLabel  = g_openTrade.module;
      rec.rsiAtEntry   = g_openTrade.rsiAtEntry;
      rec.atrAtEntry   = g_openTrade.atrAtEntry;
      rec.slMulti      = InpSL_ATR_Multi;
      rec.tpMulti      = InpTP_ATR_Multi;
      rec.rrRatio      = InpTP_ATR_Multi / InpSL_ATR_Multi;
      rec.entryPrice   = g_openTrade.entryPrice;
      rec.slPrice      = g_openTrade.slPrice;
      rec.tpPrice      = g_openTrade.tpPrice;
      rec.exitPrice    = exitPrice;
      rec.exitType     = exitType;
      rec.profitUSD    = profitUSD;
      rec.profitR      = profitR;
      rec.durationMin  = durationMin;

      CSVWriteTrade(g_csvPath, rec);

      Print("ARE: Trade cerrado | ", g_openTrade.module,
            " | ExitType=", exitType,
            " | P&L=", DoubleToString(profitUSD, 2),
            " | R=", DoubleToString(profitR, 2));

      g_openTrade.active = false;
      return;
   }
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
{
   // Trigger inmediato al cierre de posición para no esperar nueva barra
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
      CheckTradeClose();
}
