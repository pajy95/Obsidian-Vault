//+------------------------------------------------------------------+
//|  RBR_v1.0.mq5                                                    |
//|  Range Bound Reversal                                            |
//|  Version 1.0                                                     |
//|                                                                  |
//|  LOGICA:                                                         |
//|  Calcula rango rolling (Max/Min de ultimas N velas). Define      |
//|  zonas en los extremos (ZonePct%). Cuando precio toca zona con  |
//|  rechazo confirmado (IBS + mecha), entra en direccion contraria. |
//|  Target: mid-point del rango (equilibrio).                      |
//|                                                                  |
//|  COMPLEMENTO A TBR: opera en paralelo, logica independiente.    |
//|  TBR gana en mercado trending. RBR gana en mercado lateral.     |
//|                                                                  |
//|  MAGIC NUMBER RESERVADO: 202511                                  |
//|  ACTIVOS: NAS100, SPX500, XAUUSD, GBPUSD                       |
//|                                                                  |
//|  REGLA CRITICA: OrderCalcProfit() para VPP — nunca TickValue   |
//|                                                                  |
//|  HISTORIAL:                                                      |
//|  v1.0 (2026-05-23): Version inicial                             |
//+------------------------------------------------------------------+
#property copyright "RBR v1.0"
#property version   "1.00"
#property description "Range Bound Reversal — Mean Reversion — FundingPips"
#property strict

#include <Trade\Trade.mqh>

//==================================================================
// ENUMS
//==================================================================
enum ENUM_TRADE_DIRECTION
{
   DIR_BOTH = 0,  // Compra y Venta
   DIR_BUY  = 1,  // Solo Compra
   DIR_SELL = 2   // Solo Venta
};

enum ENUM_ENTRY_MODE
{
   MODE_CONFIRM = 0,  // Confirmacion (cierre de vela con IBS + mecha)
   MODE_LIMIT   = 1   // Limite (orden limit en borde de zona)
};

//==================================================================
// INPUTS
//==================================================================

input group "=== RANGO ==="
input int    RangePeriod         = 20;    // Velas para calcular High/Low del rango
input double ZonePct             = 0.10;  // % del rango que define zona de entrada

input group "=== CONFIRMACION DE RECHAZO ==="
input double IBS_LongThreshold   = 0.70;  // IBS minimo para señal LONG (zona baja)
input double IBS_ShortThreshold  = 0.30;  // IBS maximo para señal SHORT (zona alta)
input double MinWickPct          = 0.60;  // Mecha minima como % del rango de la vela

input group "=== MODO DE ENTRADA ==="
input ENUM_ENTRY_MODE      EntryMode      = MODE_CONFIRM;  // Modo de entrada
input ENUM_TRADE_DIRECTION TradeDirection = DIR_BOTH;      // Direccion permitida
input int    LimitExpireBars     = 3;     // Velas antes de cancelar limit no ejecutado

input group "=== FILTRO DE REGIMEN ==="
input bool   UseRegimeFilter     = true;  // Activar filtro de mercado trending
input double RegimeMultiplier    = 1.50;  // Umbral: rango > ATR*sqrt(N)*mult -> trending
input int    RegimePeriod        = 20;    // Velas para calcular ATR de referencia

input group "=== SESION DE TRADING ==="
input int    TradeSession_Start_Hour = 14; // Hora inicio sesion (tiempo servidor)
input int    TradeSession_Start_Min  = 0;  // Minuto inicio sesion
input int    TradeSession_End_Hour   = 17; // Hora fin sesion (tiempo servidor)
input int    TradeSession_End_Min    = 0;  // Minuto fin sesion
input int    ServerOffsetHours       = 2;  // Offset servidor vs UTC
input bool   CloseAtSessionEnd       = true; // Cerrar posicion al fin de sesion

input group "=== GESTION DE POSICION ==="
input double SL_BufferPoints     = 10.0;  // Puntos extra mas alla del extremo para SL
input bool   UseTimeStop         = true;  // Activar cierre por tiempo sin progreso
input int    TimeStopBars        = 5;     // Velas sin progreso para activar timestop
input double TimeStopProgressPct = 0.20;  // Progreso minimo hacia TP (fraccion)

input group "=== BREAKEVEN ==="
input bool   UseBreakeven        = true;  // Activar breakeven
input double BE_TriggerPct       = 0.50;  // BE activa cuando precio recorre X% hacia TP
input int    BE_BufferPoints     = 2;     // Puntos sobre entrada para SL de BE

input group "=== DIAS DE TRADING ==="
input bool   TradeMonday         = true;
input bool   TradeTuesday        = true;
input bool   TradeWednesday      = true;
input bool   TradeThursday       = true;
input bool   TradeFriday         = true;

input group "=== RIESGO ==="
input double RiskAmountUSD       = 10.0;  // Riesgo fijo por operacion en USD

input group "=== VISUALES ==="
input bool   ShowObjects         = true;
input bool   ShowDashboard       = true;
input color  ColorZoneHigh       = clrCrimson;
input color  ColorZoneLow        = clrDodgerBlue;
input color  ColorMid            = clrGold;

input group "=== CSV ==="
input bool   ExportCSV           = true;
input string CSVFileName         = "RBR_Trades";

input group "=== CONFIG ==="
input int    MagicNumber         = 202511;
input string EA_Comment          = "RBR_v1.0";

//==================================================================
// GLOBALES
//==================================================================
CTrade trade;

// Specs simbolo
double g_valuePerPoint = 0;
double g_volumeMin     = 0;
double g_volumeMax     = 0;
double g_volumeStep    = 0;
int    g_digits        = 5;
int    g_stopLevel     = 0;

// Estado del rango (rolling, se actualiza cada vela)
double g_rangeHigh = 0;
double g_rangeLow  = 0;
double g_rangeMid  = 0;
double g_rangeSize = 0;
double g_zoneHigh  = 0;
double g_zoneLow   = 0;

// Sesion
datetime g_sessionStart = 0;
datetime g_sessionEnd   = 0;
datetime g_lastDay      = 0;

// Estado del trade
bool     g_tradeExecuted = false;
bool     g_be_activated  = false;
double   g_entryPrice    = 0;
double   g_slLevel       = 0;
double   g_tpLevel       = 0;
double   g_beActivateAt  = 0;
double   g_beLevel       = 0;
string   g_tradeDir      = "";
datetime g_tradeTime     = 0;
double   g_cachedLots    = 0;
int      g_barsInTrade   = 0;
double   g_ibsAtEntry    = 0;
string   g_regimeAtEntry = "";

// Orden limit (MODE_LIMIT)
ulong  g_ticketLimit     = 0;
int    g_limitBarsCount  = 0;

// CSV
int    g_csvHandle       = INVALID_HANDLE;

// Prefijo objetos visuales — evita colision con TBR u otros EAs
string g_prefix          = "";

//==================================================================
// OnInit
//==================================================================
int OnInit()
{
   g_prefix = "RBR_" + IntegerToString(MagicNumber) + "_";

   g_volumeMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   g_volumeMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   g_volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   g_digits     = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_stopLevel  = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   // VPP via OrderCalcProfit — REGLA CRITICA, nunca TickValue
   double ask0     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profit   = 0;
   double onePoint = 100.0 * _Point;
   if(OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, 1.0, ask0, ask0 + onePoint, profit) && profit > 0)
      g_valuePerPoint = profit;
   else
   {
      double cs = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      g_valuePerPoint = (ts > 0) ? (tv / ts * onePoint) : cs * onePoint;
      Print("RBR WARNING: VPP via fallback = ", g_valuePerPoint);
   }

   // Validaciones
   if(RangePeriod < 5)
   { Print("ERROR: RangePeriod minimo = 5"); return INIT_FAILED; }
   if(ZonePct <= 0.0 || ZonePct >= 0.50)
   { Print("ERROR: ZonePct debe ser 0.01-0.49"); return INIT_FAILED; }
   if(RiskAmountUSD <= 0)
   { Print("ERROR: RiskAmountUSD debe ser > 0"); return INIT_FAILED; }
   if(IBS_LongThreshold <= IBS_ShortThreshold)
   { Print("ERROR: IBS_LongThreshold debe ser > IBS_ShortThreshold"); return INIT_FAILED; }
   if(BE_TriggerPct <= 0.0 || BE_TriggerPct >= 1.0)
   { Print("ERROR: BE_TriggerPct debe ser 0.01-0.99"); return INIT_FAILED; }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   if(ExportCSV)
   {
      string fname = CSVFileName + "_" + _Symbol + ".csv";
      g_csvHandle  = FileOpen(fname, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ",");
      if(g_csvHandle != INVALID_HANDLE)
      {
         FileWrite(g_csvHandle,
            "Date","Time","Weekday","Symbol","Direction","EntryMode",
            "EntryPrice","SL","TP","BE_Level","Lots","RiskUSD",
            "RangeHigh","RangeLow","RangeMid","RangeSize_pts",
            "ZoneHigh","ZoneLow","IBS_Entry","RegimeAtEntry",
            "ExitType","ClosePrice","PnL_USD","BarsHeld");
         FileFlush(g_csvHandle);
      }
      else Print("RBR WARNING: No se pudo crear CSV. Error=", GetLastError());
   }

   Print("=======================================================");
   Print("  RBR v1.0 — ", _Symbol);
   Print("=======================================================");
   Print("  VPP           : ", DoubleToString(g_valuePerPoint, 4));
   Print("  Direccion     : ", EnumToString(TradeDirection));
   Print("  Modo entrada  : ", EnumToString(EntryMode));
   Print("  RangePeriod   : ", RangePeriod, " velas");
   Print("  ZonePct       : ", ZonePct * 100.0, "%");
   Print("  IBS Long/Short: >=", IBS_LongThreshold, " / <=", IBS_ShortThreshold);
   Print("  MinWickPct    : ", MinWickPct * 100.0, "%");
   Print("  RegimeFilter  : ", UseRegimeFilter ?
         StringFormat("ON (mult=%.2f, periodo=%d)", RegimeMultiplier, RegimePeriod) : "OFF");
   Print("  Sesion srv    : ",
         TradeSession_Start_Hour, ":", StringFormat("%02d", TradeSession_Start_Min),
         " -> ", TradeSession_End_Hour, ":", StringFormat("%02d", TradeSession_End_Min));
   Print("  Breakeven     : ", UseBreakeven ?
         StringFormat("ON (trigger=%.0f%% TP, buffer=%d pts)", BE_TriggerPct * 100, BE_BufferPoints) : "OFF");
   Print("  TimeStop      : ", UseTimeStop ?
         StringFormat("ON (%d velas, progreso min=%.0f%%)", TimeStopBars, TimeStopProgressPct * 100) : "OFF");
   Print("  RiskAmountUSD : $", RiskAmountUSD);
   Print("  MagicNumber   : ", MagicNumber);

   return INIT_SUCCEEDED;
}

//==================================================================
// OnDeinit
//==================================================================
void OnDeinit(const int reason)
{
   if(g_csvHandle != INVALID_HANDLE)
   {
      FileFlush(g_csvHandle);
      FileClose(g_csvHandle);
   }
   VIS_CleanAll();
}

//==================================================================
// OnTick
//==================================================================
void OnTick()
{
   // Reset diario
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
   if(today != g_lastDay)
   {
      DailyReset();
      g_lastDay = today;
   }

   if(!IsTradingDayAllowed()) return;

   datetime now = TimeCurrent();

   if(g_sessionStart == 0) g_sessionStart = CalcSessionTime(TradeSession_Start_Hour, TradeSession_Start_Min);
   if(g_sessionEnd   == 0) g_sessionEnd   = CalcSessionTime(TradeSession_End_Hour,   TradeSession_End_Min);

   // Cierre al fin de sesion
   if(now >= g_sessionEnd)
   {
      if(CloseAtSessionEnd && HasOpenPosition())
         ClosePosition("SessionEnd");
      if(EntryMode == MODE_LIMIT && g_ticketLimit != 0)
         CancelLimitOrder("Sesion terminada");
      return;
   }

   // Antes de sesion
   if(now < g_sessionStart) return;

   if(!IsNewBar()) return;

   // Actualizar rango en cada barra
   UpdateRange();
   if(ShowDashboard) VIS_UpdateDashboard();

   // Gestionar posicion abierta
   if(HasOpenPosition())
   {
      g_barsInTrade++;
      ManagePosition();
      return;
   }

   // Gestionar orden limit pendiente
   if(EntryMode == MODE_LIMIT && g_ticketLimit != 0)
   {
      g_limitBarsCount++;
      if(g_limitBarsCount >= LimitExpireBars)
         CancelLimitOrder("Expiracion");
      return;
   }

   if(g_tradeExecuted) return;
   if(g_rangeSize <= 0) return;

   CheckEntrySignal();
}

//==================================================================
// OnTradeTransaction — captura fills y cierres por TP/SL
//==================================================================
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   ulong dealTicket = trans.deal;
   if(dealTicket == 0) return;
   if(!HistoryDealSelect(dealTicket)) return;

   ulong  magic  = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   string sym    = HistoryDealGetString (dealTicket, DEAL_SYMBOL);
   if(magic != (ulong)MagicNumber || sym != _Symbol) return;

   long   entry  = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

   // Fill de orden limit
   if(entry == DEAL_ENTRY_IN && EntryMode == MODE_LIMIT)
   {
      long   dealType  = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
      double dealPrice = HistoryDealGetDouble (dealTicket, DEAL_PRICE);
      double dealVol   = HistoryDealGetDouble (dealTicket, DEAL_VOLUME);
      string dir       = (dealType == DEAL_TYPE_BUY) ? "buy" : "sell";

      RegisterLimitFill(dir, dealPrice, dealVol);
      g_ticketLimit    = 0;
      g_limitBarsCount = 0;
      g_tradeExecuted  = true;
      return;
   }

   // Cierre por TP o SL (gestionado por MT5)
   if(entry == DEAL_ENTRY_OUT)
   {
      long   reason     = HistoryDealGetInteger(dealTicket, DEAL_REASON);
      double closePrice = HistoryDealGetDouble (dealTicket, DEAL_PRICE);
      double pnl        = HistoryDealGetDouble (dealTicket, DEAL_PROFIT);

      string exitType = "Cierre";
      if(reason == DEAL_REASON_TP)     exitType = "TP";
      else if(reason == DEAL_REASON_SL) exitType = "SL";

      if(exitType == "TP" || exitType == "SL")
      {
         Print("RBR Cierre auto: ", exitType, " | PnL=$", DoubleToString(pnl, 2));
         if(ExportCSV) LogToCSV(exitType, closePrice, pnl);
      }
   }
}

//==================================================================
// UpdateRange — calcula rango, zonas y mid
//==================================================================
void UpdateRange()
{
   double high = -DBL_MAX, low = DBL_MAX;

   for(int i = 1; i <= RangePeriod; i++)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      double l = iLow (_Symbol, PERIOD_CURRENT, i);
      if(h <= 0 || l <= 0) continue;
      if(h > high) high = h;
      if(l < low)  low  = l;
   }

   if(high == -DBL_MAX || low == DBL_MAX || high <= low) return;

   g_rangeHigh = high;
   g_rangeLow  = low;
   g_rangeSize = high - low;
   g_rangeMid  = NormalizeDouble((high + low) / 2.0, g_digits);
   g_zoneHigh  = NormalizeDouble(high - ZonePct * g_rangeSize, g_digits);
   g_zoneLow   = NormalizeDouble(low  + ZonePct * g_rangeSize, g_digits);

   if(ShowObjects) VIS_DrawRange();
}

//==================================================================
// IsRegimeTrending — ATR-based: rango > ATR*sqrt(N)*mult
// Base matematica: en mercado aleatorio el rango esperado ~ ATR*sqrt(N).
// Si el rango actual supera ese umbral x mult, hay tendencia.
//==================================================================
bool IsRegimeTrending()
{
   if(!UseRegimeFilter || g_rangeSize <= 0 || RegimePeriod < 5) return false;

   double sumATR = 0;
   int    count  = 0;

   for(int i = 1; i <= RegimePeriod; i++)
   {
      double h     = iHigh (_Symbol, PERIOD_CURRENT, i);
      double l     = iLow  (_Symbol, PERIOD_CURRENT, i);
      double prevC = iClose(_Symbol, PERIOD_CURRENT, i + 1);
      if(h <= 0 || l <= 0 || prevC <= 0) continue;

      double tr = MathMax(h - l,
                  MathMax(MathAbs(h - prevC),
                          MathAbs(l - prevC)));
      sumATR += tr;
      count++;
   }

   if(count < 5) return false;

   double avgATR        = sumATR / count;
   double expectedRange = avgATR * MathSqrt((double)RegimePeriod);

   return (g_rangeSize > expectedRange * RegimeMultiplier);
}

//==================================================================
// CheckEntrySignal — evalua señal en vela recien cerrada (idx=1)
//==================================================================
void CheckEntrySignal()
{
   double barHigh  = iHigh (_Symbol, PERIOD_CURRENT, 1);
   double barLow   = iLow  (_Symbol, PERIOD_CURRENT, 1);
   double barOpen  = iOpen (_Symbol, PERIOD_CURRENT, 1);
   double barClose = iClose(_Symbol, PERIOD_CURRENT, 1);

   if(barHigh <= 0 || barLow <= 0 || barHigh <= barLow) return;

   double barRange  = barHigh - barLow;
   if(barRange <= 0) return;

   double IBS       = (barClose - barLow) / barRange;
   double lowerWick = (MathMin(barOpen, barClose) - barLow)  / barRange;
   double upperWick = (barHigh - MathMax(barOpen, barClose)) / barRange;

   bool trending = IsRegimeTrending();

   // Señal LONG — zona baja
   if(TradeDirection != DIR_SELL)
   {
      bool inZone  = (barLow <= g_zoneLow);
      bool ibsOK   = (IBS >= IBS_LongThreshold);
      bool wickOK  = (lowerWick >= MinWickPct);

      if(inZone && ibsOK && wickOK && !trending)
      {
         g_ibsAtEntry    = IBS;
         g_regimeAtEntry = "RANGE";
         if(EntryMode == MODE_CONFIRM)
            ExecuteMarketOrder("buy");
         else
            PlaceLimitOrder("buy");
         return;
      }
   }

   // Señal SHORT — zona alta
   if(TradeDirection != DIR_BUY)
   {
      bool inZone  = (barHigh >= g_zoneHigh);
      bool ibsOK   = (IBS <= IBS_ShortThreshold);
      bool wickOK  = (upperWick >= MinWickPct);

      if(inZone && ibsOK && wickOK && !trending)
      {
         g_ibsAtEntry    = IBS;
         g_regimeAtEntry = "RANGE";
         if(EntryMode == MODE_CONFIRM)
            ExecuteMarketOrder("sell");
         else
            PlaceLimitOrder("sell");
      }
   }
}

//==================================================================
// ExecuteMarketOrder — MODE_CONFIRM
//==================================================================
void ExecuteMarketOrder(string direction)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int    eff = MathMax(g_stopLevel, (int)SL_BufferPoints);

   g_tradeDir  = direction;
   g_tradeTime = TimeCurrent();

   if(direction == "buy")
   {
      g_entryPrice    = ask;
      g_slLevel       = NormalizeDouble(g_rangeLow  - eff * _Point, g_digits);
      g_tpLevel       = g_rangeMid;
      double distToTP = g_tpLevel - g_entryPrice;
      if(distToTP <= 0) { Print("RBR: TP <= Entry en BUY. Señal descartada."); return; }
      g_beActivateAt  = NormalizeDouble(g_entryPrice + distToTP * BE_TriggerPct, g_digits);
      g_beLevel       = NormalizeDouble(g_entryPrice + BE_BufferPoints * _Point,  g_digits);
      double slDist   = g_entryPrice - g_slLevel;
      g_cachedLots    = CalcLotSize(slDist);
      if(g_cachedLots <= 0) return;

      if(!trade.Buy(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel, EA_Comment))
      {
         Print("RBR ERROR Buy: ", trade.ResultRetcode(), " — ", trade.ResultRetcodeDescription());
         return;
      }
   }
   else
   {
      g_entryPrice    = bid;
      g_slLevel       = NormalizeDouble(g_rangeHigh + eff * _Point, g_digits);
      g_tpLevel       = g_rangeMid;
      double distToTP = g_entryPrice - g_tpLevel;
      if(distToTP <= 0) { Print("RBR: TP >= Entry en SELL. Señal descartada."); return; }
      g_beActivateAt  = NormalizeDouble(g_entryPrice - distToTP * BE_TriggerPct, g_digits);
      g_beLevel       = NormalizeDouble(g_entryPrice - BE_BufferPoints * _Point,  g_digits);
      double slDist   = g_slLevel - g_entryPrice;
      g_cachedLots    = CalcLotSize(slDist);
      if(g_cachedLots <= 0) return;

      if(!trade.Sell(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel, EA_Comment))
      {
         Print("RBR ERROR Sell: ", trade.ResultRetcode(), " — ", trade.ResultRetcodeDescription());
         return;
      }
   }

   g_tradeExecuted = true;
   g_barsInTrade   = 0;

   Print("RBR Trade CONFIRM: ", direction,
         " | Entry=",  DoubleToString(g_entryPrice, g_digits),
         " | SL=",     DoubleToString(g_slLevel,    g_digits),
         " | TP=",     DoubleToString(g_tpLevel,    g_digits),
         " | Mid=",    DoubleToString(g_rangeMid,   g_digits),
         " | IBS=",    DoubleToString(g_ibsAtEntry, 3),
         " | Lots=",   DoubleToString(g_cachedLots, 2));

   if(ShowObjects) VIS_DrawLevels();
}

//==================================================================
// PlaceLimitOrder — MODE_LIMIT
//==================================================================
void PlaceLimitOrder(string direction)
{
   int    eff = MathMax(g_stopLevel, (int)SL_BufferPoints);
   g_tradeDir    = direction;
   g_limitBarsCount = 0;

   if(direction == "buy")
   {
      double lPrice = NormalizeDouble(g_zoneLow,  g_digits);
      double slP    = NormalizeDouble(g_rangeLow  - eff * _Point, g_digits);
      double tpP    = g_rangeMid;
      double slDist = lPrice - slP;
      double lots   = CalcLotSize(slDist);
      if(lots <= 0) return;

      if(trade.BuyLimit(lots, lPrice, _Symbol, slP, tpP, ORDER_TIME_DAY, 0, EA_Comment))
      {
         g_ticketLimit = trade.ResultOrder();
         Print("RBR BuyLimit colocado @ ", lPrice, " | SL=", slP, " | TP=", tpP);
      }
      else Print("RBR ERROR BuyLimit: ", trade.ResultRetcode());
   }
   else
   {
      double lPrice = NormalizeDouble(g_zoneHigh, g_digits);
      double slP    = NormalizeDouble(g_rangeHigh + eff * _Point, g_digits);
      double tpP    = g_rangeMid;
      double slDist = slP - lPrice;
      double lots   = CalcLotSize(slDist);
      if(lots <= 0) return;

      if(trade.SellLimit(lots, lPrice, _Symbol, slP, tpP, ORDER_TIME_DAY, 0, EA_Comment))
      {
         g_ticketLimit = trade.ResultOrder();
         Print("RBR SellLimit colocado @ ", lPrice, " | SL=", slP, " | TP=", tpP);
      }
      else Print("RBR ERROR SellLimit: ", trade.ResultRetcode());
   }
}

//==================================================================
// RegisterLimitFill — cuando se llena una orden limit
//==================================================================
void RegisterLimitFill(string direction, double fillPrice, double fillVol)
{
   int    eff       = MathMax(g_stopLevel, (int)SL_BufferPoints);
   g_tradeDir       = direction;
   g_tradeTime      = TimeCurrent();
   g_entryPrice     = fillPrice;
   g_cachedLots     = fillVol;
   g_barsInTrade    = 0;

   if(direction == "buy")
   {
      g_slLevel      = NormalizeDouble(g_rangeLow  - eff * _Point, g_digits);
      g_tpLevel      = g_rangeMid;
      double distToTP = g_tpLevel - g_entryPrice;
      g_beActivateAt = NormalizeDouble(g_entryPrice + distToTP * BE_TriggerPct, g_digits);
      g_beLevel      = NormalizeDouble(g_entryPrice + BE_BufferPoints * _Point,  g_digits);
   }
   else
   {
      g_slLevel      = NormalizeDouble(g_rangeHigh + eff * _Point, g_digits);
      g_tpLevel      = g_rangeMid;
      double distToTP = g_entryPrice - g_tpLevel;
      g_beActivateAt = NormalizeDouble(g_entryPrice - distToTP * BE_TriggerPct, g_digits);
      g_beLevel      = NormalizeDouble(g_entryPrice - BE_BufferPoints * _Point,  g_digits);
   }

   ulong ticket = GetOpenPositionTicket();
   if(ticket > 0) trade.PositionModify(ticket, g_slLevel, g_tpLevel);

   Print("RBR Limit fill: ", direction,
         " @ ", DoubleToString(fillPrice, g_digits),
         " | SL=", DoubleToString(g_slLevel, g_digits),
         " | TP=", DoubleToString(g_tpLevel, g_digits));

   if(ShowObjects) VIS_DrawLevels();
}

//==================================================================
// ManagePosition — Breakeven y TimeStop
//==================================================================
void ManagePosition()
{
   ulong ticket = GetOpenPositionTicket();
   if(ticket == 0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Breakeven
   if(UseBreakeven && !g_be_activated)
   {
      bool beCond = (g_tradeDir == "buy"  && bid >= g_beActivateAt) ||
                    (g_tradeDir == "sell" && ask <= g_beActivateAt);
      if(beCond)
      {
         if(trade.PositionModify(ticket, g_beLevel, g_tpLevel))
         {
            g_slLevel      = g_beLevel;
            g_be_activated = true;
            Print("RBR BE activado. SL -> ", DoubleToString(g_beLevel, g_digits));
            if(ShowObjects) VIS_UpdateSL();
         }
      }
   }

   // TimeStop — cierra si no hay progreso suficiente hacia TP
   if(UseTimeStop && g_barsInTrade >= TimeStopBars)
   {
      double distTotal = MathAbs(g_tpLevel - g_entryPrice);
      double distAct   = (g_tradeDir == "buy") ?
                         (bid - g_entryPrice) : (g_entryPrice - ask);
      double progress  = (distTotal > 0) ? distAct / distTotal : 0;

      if(progress < TimeStopProgressPct)
      {
         Print("RBR TimeStop: ", g_barsInTrade, " velas | progreso=",
               DoubleToString(progress * 100, 1), "% (min=",
               DoubleToString(TimeStopProgressPct * 100, 0), "%). Cerrando.");
         ClosePosition("TimeStop");
      }
   }
}

//==================================================================
// ClosePosition — cierre explicito por EA (TimeStop, SessionEnd)
//==================================================================
void ClosePosition(string exitType)
{
   ulong ticket = GetOpenPositionTicket();
   if(ticket == 0) return;

   double closePrice = 0;
   double pnl        = 0;
   if(PositionSelectByTicket(ticket))
   {
      closePrice = (g_tradeDir == "buy") ?
         SymbolInfoDouble(_Symbol, SYMBOL_BID) :
         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      pnl = PositionGetDouble(POSITION_PROFIT);
   }

   trade.PositionClose(ticket);
   Print("RBR Cierre: ", exitType, " | PnL=$", DoubleToString(pnl, 2));

   if(ExportCSV) LogToCSV(exitType, closePrice, pnl);
}

//==================================================================
// CancelLimitOrder
//==================================================================
void CancelLimitOrder(string reason)
{
   if(g_ticketLimit == 0) return;
   bool exists = false;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
      if(OrderGetTicket(i) == g_ticketLimit) { exists = true; break; }
   if(exists) trade.OrderDelete(g_ticketLimit);
   Print("RBR: Orden limit cancelada — ", reason);
   g_ticketLimit    = 0;
   g_limitBarsCount = 0;
}

//==================================================================
// CalcLotSize
//==================================================================
double CalcLotSize(double slDist)
{
   if(g_valuePerPoint <= 0 || slDist <= 0) return 0;

   double lotsRaw = RiskAmountUSD * (100.0 * _Point) / (slDist * g_valuePerPoint);
   double lots    = MathFloor(lotsRaw / g_volumeStep) * g_volumeStep;
   lots = MathMax(lots, g_volumeMin);
   lots = MathMin(lots, g_volumeMax);
   lots = NormalizeDouble(lots, 2);

   double marginReq = 0;
   double askNow    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, askNow, marginReq))
   {
      double freeMgn = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(marginReq > freeMgn * 0.90)
      {
         double safeLots = MathFloor(freeMgn * 0.90 / marginReq * lots / g_volumeStep) * g_volumeStep;
         safeLots = MathMax(safeLots, g_volumeMin);
         Print("RBR WARNING: margen insuficiente. Lots: ", lots, " -> ", safeLots);
         lots = safeLots;
      }
   }
   return lots;
}

//==================================================================
// DailyReset
//==================================================================
void DailyReset()
{
   if(EntryMode == MODE_LIMIT && g_ticketLimit != 0)
      CancelLimitOrder("Reset diario");

   g_sessionStart   = 0;
   g_sessionEnd     = 0;
   g_tradeExecuted  = false;
   g_be_activated   = false;
   g_entryPrice     = 0;
   g_slLevel        = 0;
   g_tpLevel        = 0;
   g_beActivateAt   = 0;
   g_beLevel        = 0;
   g_tradeDir       = "";
   g_tradeTime      = 0;
   g_cachedLots     = 0;
   g_barsInTrade    = 0;
   g_ibsAtEntry     = 0;
   g_regimeAtEntry  = "";
   g_ticketLimit    = 0;
   g_limitBarsCount = 0;

   VIS_CleanAll();
}

//==================================================================
// Helpers — Sesion
//==================================================================
datetime CalcSessionTime(int hour, int minute)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return StringToTime(StringFormat("%04d.%02d.%02d %02d:%02d:00",
                                    dt.year, dt.mon, dt.day, hour, minute));
}

bool IsTradingDayAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   switch(dt.day_of_week)
   {
      case 1: return TradeMonday;
      case 2: return TradeTuesday;
      case 3: return TradeWednesday;
      case 4: return TradeThursday;
      case 5: return TradeFriday;
      default: return false;
   }
}

bool IsNewBar()
{
   static datetime g_lastBar = 0;
   datetime curBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(curBar != g_lastBar) { g_lastBar = curBar; return true; }
   return false;
}

//==================================================================
// Helpers — Posiciones
//==================================================================
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) > 0 &&
         (int)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         return true;
   return false;
}

ulong GetOpenPositionTicket()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t > 0 &&
         (int)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         return t;
   }
   return 0;
}

//==================================================================
// CSV
//==================================================================
void LogToCSV(string exitType, double closePrice, double pnl)
{
   if(g_csvHandle == INVALID_HANDLE) return;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string wdays[] = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};

   double slDist   = MathAbs(g_entryPrice - g_slLevel);
   double riskReal = (g_valuePerPoint > 0 && slDist > 0) ?
                     g_cachedLots * slDist * g_valuePerPoint / (100.0 * _Point) : 0;

   FileWrite(g_csvHandle,
      StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day),
      StringFormat("%02d:%02d",      dt.hour, dt.min),
      wdays[dt.day_of_week],
      _Symbol,
      g_tradeDir,
      EnumToString(EntryMode),
      DoubleToString(g_entryPrice, g_digits),
      DoubleToString(g_slLevel,    g_digits),
      DoubleToString(g_tpLevel,    g_digits),
      DoubleToString(g_beLevel,    g_digits),
      DoubleToString(g_cachedLots, 2),
      DoubleToString(riskReal,     2),
      DoubleToString(g_rangeHigh,  g_digits),
      DoubleToString(g_rangeLow,   g_digits),
      DoubleToString(g_rangeMid,   g_digits),
      DoubleToString(g_rangeSize / _Point, 1),
      DoubleToString(g_zoneHigh,   g_digits),
      DoubleToString(g_zoneLow,    g_digits),
      DoubleToString(g_ibsAtEntry, 3),
      g_regimeAtEntry,
      exitType,
      DoubleToString(closePrice,   g_digits),
      DoubleToString(pnl,          2),
      IntegerToString(g_barsInTrade)
   );
   FileFlush(g_csvHandle);
}

//==================================================================
// MODULO VISUAL
//==================================================================
void VIS_DrawRange()
{
   if(!ShowObjects) return;

   datetime t0 = iTime(_Symbol, PERIOD_CURRENT, RangePeriod);
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 0);

   // Rectangulo del rango
   string box = g_prefix + "RangeBox";
   ObjectDelete(0, box);
   ObjectCreate(0, box, OBJ_RECTANGLE, 0, t0, g_rangeLow, t1, g_rangeHigh);
   ObjectSetInteger(0, box, OBJPROP_COLOR, (color)0x1A1A2E);
   ObjectSetInteger(0, box, OBJPROP_FILL,  true);
   ObjectSetInteger(0, box, OBJPROP_BACK,  true);

   // Zona alta — entrada SHORT
   string zh = g_prefix + "ZoneHigh";
   ObjectDelete(0, zh);
   ObjectCreate(0, zh, OBJ_HLINE, 0, 0, g_zoneHigh);
   ObjectSetInteger(0, zh, OBJPROP_COLOR, ColorZoneHigh);
   ObjectSetInteger(0, zh, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, zh, OBJPROP_WIDTH, 2);

   // Zona baja — entrada LONG
   string zl = g_prefix + "ZoneLow";
   ObjectDelete(0, zl);
   ObjectCreate(0, zl, OBJ_HLINE, 0, 0, g_zoneLow);
   ObjectSetInteger(0, zl, OBJPROP_COLOR, ColorZoneLow);
   ObjectSetInteger(0, zl, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, zl, OBJPROP_WIDTH, 2);

   // Mid — target
   string zm = g_prefix + "RangeMid";
   ObjectDelete(0, zm);
   ObjectCreate(0, zm, OBJ_HLINE, 0, 0, g_rangeMid);
   ObjectSetInteger(0, zm, OBJPROP_COLOR, ColorMid);
   ObjectSetInteger(0, zm, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, zm, OBJPROP_WIDTH, 1);

   ChartRedraw();
}

void VIS_DrawLevels()
{
   if(!ShowObjects) return;

   // Flecha de entrada
   string arr = g_prefix + "Arrow";
   ObjectDelete(0, arr);
   ObjectCreate(0, arr, OBJ_ARROW, 0, TimeCurrent(), g_entryPrice);
   ObjectSetInteger(0, arr, OBJPROP_ARROWCODE, g_tradeDir == "buy" ? 241 : 242);
   ObjectSetInteger(0, arr, OBJPROP_COLOR,     g_tradeDir == "buy" ? clrLime : clrOrangeRed);
   ObjectSetInteger(0, arr, OBJPROP_WIDTH, 2);

   // SL
   string sl = g_prefix + "SL";
   ObjectDelete(0, sl);
   ObjectCreate(0, sl, OBJ_HLINE, 0, 0, g_slLevel);
   ObjectSetInteger(0, sl, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, sl, OBJPROP_STYLE, STYLE_DOT);

   // BE activacion
   string beA = g_prefix + "BE_Activate";
   ObjectDelete(0, beA);
   if(UseBreakeven)
   {
      ObjectCreate(0, beA, OBJ_HLINE, 0, 0, g_beActivateAt);
      ObjectSetInteger(0, beA, OBJPROP_COLOR, clrCyan);
      ObjectSetInteger(0, beA, OBJPROP_STYLE, STYLE_DASH);
   }

   ChartRedraw();
}

void VIS_UpdateSL()
{
   if(!ShowObjects) return;
   ObjectSetDouble(0, g_prefix + "SL", OBJPROP_PRICE, g_slLevel);
   ChartRedraw();
}

void VIS_UpdateDashboard()
{
   if(!ShowDashboard) return;

   string lbl = g_prefix + "Dashboard";
   ObjectDelete(0, lbl);
   ObjectCreate(0, lbl, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, lbl, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, lbl, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, lbl, OBJPROP_YDISTANCE, 50);
   ObjectSetString (0, lbl, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE,  9);
   ObjectSetInteger(0, lbl, OBJPROP_COLOR,     clrWhite);

   bool   trending = IsRegimeTrending();
   bool   inSess   = (TimeCurrent() >= g_sessionStart && TimeCurrent() < g_sessionEnd);
   string posStr   = HasOpenPosition() ?
      StringFormat("%s | SL=%.5f | TP(Mid)=%.5f | Bars=%d",
                   g_tradeDir, g_slLevel, g_tpLevel, g_barsInTrade) : "FLAT";

   ObjectSetString(0, lbl, OBJPROP_TEXT,
      StringFormat("RBR v1.0 | %s | %s | Sesion:%s | Mid=%.5f | %s",
         _Symbol,
         trending ? "TRENDING(OFF)" : "RANGE(ON)",
         inSess   ? "SI" : "NO",
         g_rangeMid,
         posStr));

   ChartRedraw();
}

void VIS_CleanAll()
{
   string names[] = {
      "RangeBox","ZoneHigh","ZoneLow","RangeMid",
      "Arrow","SL","BE_Activate","Dashboard"
   };
   for(int i = 0; i < ArraySize(names); i++)
      ObjectDelete(0, g_prefix + names[i]);
   ChartRedraw();
}

//==================================================================
// OnTester — metrica custom
// Maximiza PF * (1 - DD). Umbral minimo: 30 trades. DD > 10% = 0.
//==================================================================
double OnTester()
{
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < 30) return 0.0;

   double pf = TesterStatistics(STAT_PROFIT_FACTOR);
   if(pf <= 0) return 0.0;

   double dd = TesterStatistics(STAT_EQUITY_DD_RELATIVE);
   if(dd > 10.0) return 0.0;

   return pf * (1.0 - dd / 100.0);
}
//+------------------------------------------------------------------+
