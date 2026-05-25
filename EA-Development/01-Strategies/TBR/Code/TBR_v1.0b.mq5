
//+------------------------------------------------------------------+
//|  TBR_v1.0b.mq5                                                   |
//|  Time Boxed Range — EA Universal ORB                             |
//|  Version 1.0b (experimental branch)                              |
//|                                                                  |
//|  NUEVAS FEATURES vs v1.4:                                        |
//|                                                                  |
//|  IDEA 4 — Breakeven por RR (BE_TriggerRR):                      |
//|    Reemplaza el trigger por % del TP con trigger por múltiplo    |
//|    del SL_dist. BE_TriggerRR=1.0 significa: activar BE cuando   |
//|    el precio avanzó exactamente 1× la distancia SL desde la     |
//|    entrada (RR=1.0 en favor). Más intuitivo y directo.           |
//|    Parámetros para optimizar: BE_TriggerRR (0.5–2.0),           |
//|    BE_BufferPct (0–5%).                                          |
//|                                                                  |
//|  IDEA 5 — Filtro de Gap pre-sesión (GapFilter):                 |
//|    Omite el día si el precio de apertura de la sesión difiere    |
//|    más de MaxGapPct% del cierre D1 del día anterior. Hipótesis: |
//|    si el mercado ya hizo un movimiento grande overnight, el      |
//|    breakout de apertura tiene menos recorrido potencial.         |
//|    Parámetros para optimizar: GapFilter_Enable, MaxGapPct.      |
//|                                                                  |
//|  HISTORIAL DE VERSIONES:                                         |
//|  v1.1 (2026-05-09): RiskPct → RiskAmountUSD; CloseAfterHours   |
//|  v1.2 (2026-05-09): BUG FIX MODE_CONFIRM post-SessionEnd       |
//|  v1.3 (2026-05-10): BUG FIX lot con SL_dist real (no rango)    |
//|  v1.4 (2026-05-10): BUG FIX VPP = $20 (no $0.20)              |
//|  v1.0b (2026-05-10): Idea 4 (BE_TriggerRR) + Idea 5 (Gap)     |
//|                                                                  |
//|  ACTIVOS COMPATIBLES: XAUUSD, NAS100, DJI30, EURUSD, GBPUSD    |
//|  TEMPORALIDADES: M1 a M15                                        |
//|  MAGIC NUMBERS RESERVADOS TBR: 202501-202520                    |
//|  REGLA CRITICA: OrderCalcProfit() para VPP — nunca TickValue    |
//+------------------------------------------------------------------+
#property copyright "TBR v1.0b"
#property version   "1.05"
#property description "Time Boxed Range — EA Universal ORB — FundingPips"
#property strict

#include <Trade\Trade.mqh>

//==================================================================
// ENUMS
//==================================================================
enum ENUM_TRADE_DIRECTION
{
   DIR_BOTH  = 0,  // Compra y Venta
   DIR_BUY   = 1,  // Solo Compra
   DIR_SELL  = 2   // Solo Venta
};

enum ENUM_ENTRY_MODE
{
   MODE_CONFIRM  = 0,  // Confirmacion (cierre de vela)
   MODE_BREAKOUT = 1   // Ruptura (ordenes STOP pendientes)
};

//==================================================================
// INPUT PARAMETERS
//==================================================================

input group "=== MODO DE ESTRATEGIA ==="
input ENUM_TRADE_DIRECTION  TradeDirection    = DIR_BUY;       // Direccion de trading
input ENUM_ENTRY_MODE       EntryMode         = MODE_CONFIRM;  // Modo de entrada

input group "=== SESION HORARIA ==="
input int  RangeCandlesCount  = 1;   // Numero de velas para formar el rango
input int  SessionStart_Hour  = 14;  // Hora de inicio de sesion (UTC)
input int  SessionStart_Min   = 27;  // Minutos de inicio de sesion
input int  SessionEnd_Hour    = 17;  // Hora de fin de sesion (UTC)
input int  SessionEnd_Min     = 0;   // Minutos de fin de sesion
input int  ServerOffsetHours  = 2;   // Offset servidor vs UTC (FundingPips = UTC+2)

input group "=== FILTROS ==="
input bool   SpreadFilter_Enable  = false;  // Activar filtro de spread maximo
input int    MaxSpread            = 20;     // Spread maximo permitido (puntos)

input group "=== FILTRO DE GAP (IDEA 5) ==="
input bool   GapFilter_Enable = false;  // Activar filtro de gap pre-sesion
input double MaxGapPct        = 0.50;   // Gap maximo permitido (% del cierre D1 anterior)

input group "=== GESTION DE POSICION ABIERTA ==="
input bool   CloseAfterHours_Enable  = true;   // Cerrar posicion despues de X horas
input int    MaxHoldHours            = 4;       // Horas maximas para mantener posicion

input group "=== STOP LOSS Y TAKE PROFIT ==="
input bool   SL_AtRangeExtreme    = true;   // SL en extremo opuesto del rango
input double RR                   = 3.0;    // Risk-Reward (TP = RR x SL distance)
input int    StopLevel_ExtraPoints = 10;    // Puntos extra sobre el stop level del broker

input group "=== BREAKEVEN (IDEA 4) ==="
input bool   UseBreakeven      = false;  // Activar breakeven
input double BE_TriggerRR      = 1.0;   // Activar BE cuando precio = entrada + TriggerRR x SL_dist
input double BE_BufferPct      = 2.0;   // Buffer BE = X% de la distancia SL (sobre entry)

input group "=== RIESGO ==="
input double RiskAmountUSD     = 12.50;  // Riesgo fijo por operacion en USD

input group "=== DIAS DE TRADING ==="
input bool   TradeSunday       = false;
input bool   TradeMonday       = true;
input bool   TradeTuesday      = false;
input bool   TradeWednesday    = true;
input bool   TradeThursday     = false;
input bool   TradeFriday       = true;
input bool   TradeSaturday     = false;

input group "=== LOGGING ==="
input bool   EnableCSV         = true;   // Exportar trades a CSV
input bool   EnableLog         = true;   // Imprimir logs en terminal

input group "=== VISUALES ==="
input bool   VIS_Enable        = true;   // Dibujar objetos en grafico

input group "=== CONFIG ==="
input int    MagicNumber       = 202501; // Magic Number unico por instancia (TBR: 202501-202520)

//==================================================================
// GLOBALES
//==================================================================

CTrade trade;

// Specs simbolo
double g_valuePerPoint;
double g_volumeMin;
double g_volumeMax;
double g_volumeStep;
int    g_digits;
int    g_stopLevel;

// Estado diario
double   g_rangeHigh         = 0;
double   g_rangeLow          = 0;
double   g_slDistance        = 0;
double   g_cachedLots        = 0;
bool     g_rangeReady        = false;
bool     g_tradeExecuted     = false;
bool     g_be_activated      = false;
datetime g_lastDay           = 0;
datetime g_sessionStartTime  = 0;
datetime g_sessionEndTime    = 0;
datetime g_holdDeadline      = 0;

// Estado confirmacion (MODE_CONFIRM)
bool     g_breakoutPending   = false;
string   g_pendingDir        = "";
datetime g_pendingBarTime    = 0;

// Niveles del trade activo
double   g_entryPrice        = 0;
double   g_slLevel           = 0;
double   g_tpLevel           = 0;
double   g_beLevel           = 0;
double   g_beActivateAt      = 0;
string   g_tradeDir          = "";
datetime g_tradeTime         = 0;

// Tickets ordenes pendientes (MODE_BREAKOUT)
ulong    g_ticketBuy         = 0;
ulong    g_ticketSell        = 0;

// CSV
int      g_csvHandle         = INVALID_HANDLE;

//==================================================================
// OnInit
//==================================================================
int OnInit()
{
   // Specs del simbolo
   g_volumeMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   g_volumeMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   g_volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   g_digits     = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_stopLevel  = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   // VPP via OrderCalcProfit (regla critica — nunca TickValue)
   double ask0       = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profitTest = 0;
   double onePoint   = 100.0 * _Point;
   bool calcOK = OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, 1.0,
                                  ask0, ask0 + onePoint, profitTest);
   if(calcOK && profitTest > 0)
      g_valuePerPoint = profitTest;
   else
   {
      double cs  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      double ts  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tv  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      g_valuePerPoint = (ts > 0) ? (tv / ts * (100.0 * _Point)) : cs * (100.0 * _Point);
      if(EnableLog) Print("VPP via fallback: ", g_valuePerPoint);
   }

   // Validacion inputs
   if(RangeCandlesCount < 1 || RangeCandlesCount > 100)
   { Print("ERROR: RangeCandlesCount debe ser 1-100."); return INIT_FAILED; }
   if(SessionStart_Hour < 0 || SessionStart_Hour > 23 ||
      SessionEnd_Hour   < 0 || SessionEnd_Hour   > 23)
   { Print("ERROR: Horas de sesion invalidas."); return INIT_FAILED; }
   if(RiskAmountUSD <= 0)
   { Print("ERROR: RiskAmountUSD debe ser mayor que 0."); return INIT_FAILED; }
   if(RR <= 0)
   { Print("ERROR: RR debe ser mayor que 0."); return INIT_FAILED; }
   if(BE_TriggerRR <= 0)
   { Print("ERROR: BE_TriggerRR debe ser mayor que 0."); return INIT_FAILED; }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   if(EnableCSV)
   {
      string csvName = StringFormat("TBR_v1b_%s_Trades.csv", _Symbol);
      g_csvHandle = FileOpen(csvName,
                             FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ",");
      if(g_csvHandle != INVALID_HANDLE)
      {
         FileWrite(g_csvHandle,
            "Date","Time","Weekday","Direction","EntryMode",
            "EntryPrice","SL","TP","BE_Level",
            "SL_Dist","Lots","RiskUSD",
            "RangeHigh","RangeLow",
            "GapPct","ExitType","ClosePrice","PnL_USD");
         FileFlush(g_csvHandle);
      }
      else Print("WARNING: No se pudo crear CSV. Error: ", GetLastError());
   }

   if(EnableLog)
   {
      Print("=======================================================");
      Print("  TBR v1.0b (experimental) — ", _Symbol);
      Print("=======================================================");
      Print("  VPP           : ", g_valuePerPoint);
      Print("  Direccion     : ", EnumToString(TradeDirection));
      Print("  Modo entrada  : ", EnumToString(EntryMode));
      Print("  Sesion UTC    : ", SessionStart_Hour, ":", SessionStart_Min,
            " -> ", SessionEnd_Hour, ":", SessionEnd_Min,
            " (srv +", ServerOffsetHours, "h)");
      Print("  Velas rango   : ", RangeCandlesCount);
      Print("  RiskAmountUSD : $", RiskAmountUSD);
      Print("  RR            : ", RR);
      Print("  MaxHoldHours  : ", CloseAfterHours_Enable ?
            (string)MaxHoldHours + "h (activo)" : "desactivado");
      if(UseBreakeven)
         Print("  Breakeven     : ON | TriggerRR=", BE_TriggerRR,
               "x | Buffer=", BE_BufferPct, "% SL");
      else
         Print("  Breakeven     : OFF");
      Print("  GapFilter     : ", GapFilter_Enable ?
            StringFormat("ON | MaxGapPct=%.2f%%", MaxGapPct) : "OFF");
      Print("  StopLevel     : broker=", g_stopLevel,
            " extra=", StopLevel_ExtraPoints,
            " efectivo=", MathMax(g_stopLevel, StopLevel_ExtraPoints));
      Print("  MagicNumber   : ", MagicNumber);
   }

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
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d",
                                              dt.year, dt.mon, dt.day));
   if(today != g_lastDay)
   {
      DailyReset();
      g_lastDay = today;
   }

   if(!IsTradingDayAllowed()) return;

   datetime now = TimeCurrent();

   if(g_sessionEndTime == 0)
      g_sessionEndTime = GetSessionEndTime();

   // PASO 1: Detectar apertura y calcular rango
   if(!g_rangeReady)
   {
      datetime sessionStartServer = GetSessionStartTime();
      if(sessionStartServer == 0) return;

      datetime rangeEndBar = (datetime)(sessionStartServer +
                              (long)RangeCandlesCount * PeriodSeconds());
      if(now >= rangeEndBar)
         CalculateRange(sessionStartServer);

      return;
   }

   // Cierre forzoso de sesion
   if(now >= g_sessionEndTime)
   {
      if(HasOpenPosition())
         CloseAllPositions("SessionEnd");
      if(EntryMode == MODE_BREAKOUT)
         CancelPendingOrders();
      return;
   }

   // Timeout de posicion
   if(CloseAfterHours_Enable && g_holdDeadline > 0 &&
      TimeCurrent() >= g_holdDeadline)
   {
      if(HasOpenPosition())
         CloseAllPositions("HoldTimeout");
      if(EntryMode == MODE_BREAKOUT)
         CancelPendingOrders();
      return;
   }

   // Filtro de spread
   if(SpreadFilter_Enable)
   {
      int currentSpread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(currentSpread > MaxSpread)
      {
         static datetime lastSpreadLog = 0;
         if(EnableLog && TimeCurrent() - lastSpreadLog > 60)
         {
            Print("Spread filtrado: ", currentSpread, " > ", MaxSpread);
            lastSpreadLog = TimeCurrent();
         }
         return;
      }
   }

   // Gestion de posicion abierta
   if(HasOpenPosition())
   {
      ManagePosition();
      return;
   }

   if(g_tradeExecuted) return;

   // PASO 2: Modo ruptura
   if(EntryMode == MODE_BREAKOUT)
   {
      CheckPendingOrdersFilled();
      if(!g_tradeExecuted)
         PlaceOrUpdatePendingOrders();
      return;
   }

   // PASO 3: Modo confirmacion
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(!g_breakoutPending)
   {
      bool bullBreak = (ask > g_rangeHigh) && (TradeDirection != DIR_SELL);
      bool bearBreak = (bid < g_rangeLow)  && (TradeDirection != DIR_BUY);

      if(bullBreak || bearBreak)
      {
         g_breakoutPending = true;
         g_pendingDir      = bullBreak ? "buy" : "sell";
         g_pendingBarTime  = currentBarTime;
         if(EnableLog)
            Print("Breakout detectado: ", g_pendingDir,
                  " | ", TimeToString(TimeCurrent()),
                  " | ask=", ask, " bid=", bid);
      }
   }
   else if(currentBarTime > g_pendingBarTime)
   {
      if(now >= g_sessionEndTime)
      {
         if(EnableLog)
            Print("Confirmacion post-SessionEnd descartada: ",
                  TimeToString(now), " >= ", TimeToString(g_sessionEndTime));
         g_breakoutPending = false;
         g_pendingDir      = "";
         g_pendingBarTime  = 0;
      }
      else
      {
         ExecuteTrade(g_pendingDir);
      }
   }
}

//==================================================================
// OnTradeTransaction
//==================================================================
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
{
   if(EntryMode != MODE_BREAKOUT) return;
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   ulong dealTicket = trans.deal;
   if(dealTicket == 0) return;

   if(HistoryDealSelect(dealTicket))
   {
      ulong  magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
      string sym   = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      long   entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

      if(magic != (ulong)MagicNumber || sym != _Symbol) return;
      if(entry != DEAL_ENTRY_IN) return;

      long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
      string dir = (dealType == DEAL_TYPE_BUY) ? "buy" : "sell";

      double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
      double dealVol   = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
      RegisterTradeFromPending(dir, dealPrice, dealVol);

      if(dir == "buy"  && g_ticketSell != 0) CancelOrder(g_ticketSell);
      if(dir == "sell" && g_ticketBuy  != 0) CancelOrder(g_ticketBuy);
      g_ticketBuy  = 0;
      g_ticketSell = 0;
      g_tradeExecuted = true;
   }
}

//==================================================================
// CalculateRange
//==================================================================
void CalculateRange(datetime sessionStart)
{
   int approxIdx = iBarShift(_Symbol, PERIOD_CURRENT, sessionStart, false);
   if(approxIdx < 0)
   {
      if(EnableLog) Print("ERROR CalculateRange: iBarShift no encontro barra.");
      return;
   }

   int startIdx = approxIdx;
   while(startIdx > 0 && iTime(_Symbol, PERIOD_CURRENT, startIdx) < sessionStart)
      startIdx--;
   while(startIdx <= approxIdx + 5 &&
         iTime(_Symbol, PERIOD_CURRENT, startIdx) > sessionStart)
      startIdx++;

   datetime barOpenTime = iTime(_Symbol, PERIOD_CURRENT, startIdx);
   if(MathAbs((long)(barOpenTime - sessionStart)) > PeriodSeconds())
   {
      if(EnableLog)
         Print("ERROR CalculateRange: primera barra de sesion no coincide. ",
               "BarTime=", TimeToString(barOpenTime),
               " SessionStart=", TimeToString(sessionStart));
      return;
   }

   int endIdx = startIdx - (RangeCandlesCount - 1);
   if(endIdx < 0) endIdx = 0;

   double high = -DBL_MAX, low = DBL_MAX;
   for(int i = endIdx; i <= startIdx; i++)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      double l = iLow (_Symbol, PERIOD_CURRENT, i);
      if(h <= 0 || l <= 0)
      {
         if(EnableLog) Print("ERROR: datos insuficientes en barra idx=", i);
         return;
      }
      if(h > high) high = h;
      if(l < low)  low  = l;
   }

   if(EnableLog)
   {
      Print("-- Barras del rango --");
      for(int i = endIdx; i <= startIdx; i++)
         Print("  Bar[", i, "] = ", TimeToString(iTime(_Symbol, PERIOD_CURRENT, i)),
               " H=", iHigh(_Symbol, PERIOD_CURRENT, i),
               " L=", iLow (_Symbol, PERIOD_CURRENT, i));
   }

   g_rangeHigh  = high;
   g_rangeLow   = low;
   g_slDistance = g_rangeHigh - g_rangeLow;

   if(g_slDistance <= 0)
   {
      if(EnableLog) Print("ERROR: rango calculado = 0.");
      return;
   }

   // ── IDEA 5: Filtro de Gap pre-sesion ─────────────────────────
   if(GapFilter_Enable)
   {
      double prevDayClose = iClose(_Symbol, PERIOD_D1, 1);
      if(prevDayClose > 0)
      {
         double sessionOpenPrice = iOpen(_Symbol, PERIOD_CURRENT, startIdx);
         double gapPct = MathAbs(sessionOpenPrice - prevDayClose) / prevDayClose * 100.0;

         if(gapPct > MaxGapPct)
         {
            if(EnableLog)
               Print("GapFilter: gap=", DoubleToString(gapPct, 3),
                     "% > MaxGapPct=", MaxGapPct, "% -- dia omitido",
                     " | sessionOpen=", DoubleToString(sessionOpenPrice, g_digits),
                     " prevClose=", DoubleToString(prevDayClose, g_digits));
            return;  // No poner g_rangeReady = true — dia saltado
         }
         if(EnableLog)
            Print("GapFilter OK: gap=", DoubleToString(gapPct, 3),
                  "% <= ", MaxGapPct, "% -- dia aceptado");
      }
   }

   // Calcular lotaje (estimacion preliminar con rango bruto)
   g_cachedLots = CalculateLotSize(g_slDistance);
   if(g_cachedLots <= 0)
   {
      if(EnableLog) Print("ERROR: lotaje calculado = 0. Dia omitido.");
      return;
   }

   g_rangeReady = true;

   if(EnableLog)
   {
      Print("-- Rango TBR calculado --");
      Print("  RangeHigh : ", DoubleToString(g_rangeHigh, g_digits));
      Print("  RangeLow  : ", DoubleToString(g_rangeLow,  g_digits));
      Print("  SL_Dist   : ", DoubleToString(g_slDistance, g_digits),
            " (", DoubleToString(g_slDistance / _Point, 0), " puntos)");
      Print("  Lots est. : ", g_cachedLots, " (sera recalculado con SL real)");
      Print("  Modo      : ", EnumToString(EntryMode));
   }

   if(EntryMode == MODE_BREAKOUT && !g_tradeExecuted)
   {
      PlaceOrUpdatePendingOrders();
      if(CloseAfterHours_Enable && g_holdDeadline == 0)
         g_holdDeadline = TimeCurrent() + (datetime)MaxHoldHours * 3600;
   }

   if(VIS_Enable) VIS_DrawRange();
}

//==================================================================
// CalculateLotSize
//==================================================================
double CalculateLotSize(double slDist)
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
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(marginReq > freeMargin * 0.90)
      {
         double safeLots = MathFloor((freeMargin * 0.90 / marginReq * lots)
                           / g_volumeStep) * g_volumeStep;
         safeLots = MathMax(safeLots, g_volumeMin);
         if(EnableLog)
            Print("WARNING: Margen insuficiente. Lots: ", lots, " -> ", safeLots);
         lots = safeLots;
      }
   }

   return lots;
}

//==================================================================
// ExecuteTrade — Modo Confirmacion
// IDEA 4: beActivateAt = entry + SL_dist * BE_TriggerRR
//==================================================================
void ExecuteTrade(string direction)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   int effectiveStop = MathMax(g_stopLevel, StopLevel_ExtraPoints);

   g_tradeDir  = direction;
   g_tradeTime = TimeCurrent();

   if(direction == "buy")
   {
      g_entryPrice = ask;
      g_slLevel    = NormalizeDouble(g_rangeLow  - effectiveStop * _Point, g_digits);
      g_slDistance = g_entryPrice - g_slLevel;
      g_tpLevel    = NormalizeDouble(g_entryPrice + g_slDistance * RR,     g_digits);

      // IDEA 4: BE se activa cuando precio avanza TriggerRR x SL_dist desde entrada
      g_beActivateAt = NormalizeDouble(g_entryPrice + g_slDistance * BE_TriggerRR, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel    = NormalizeDouble(g_entryPrice + beBuffer, g_digits);

      // v1.3: recalcular lots con SL_dist real
      g_cachedLots = CalculateLotSize(g_slDistance);
      if(g_cachedLots <= 0)
      {
         if(EnableLog) Print("ERROR ExecuteTrade: lotaje=0 con SL_dist=", g_slDistance);
         return;
      }

      if(!trade.Buy(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel,
                    "TBR BUY v1.0b"))
      {
         if(EnableLog)
            Print("ERROR Buy: ", trade.ResultRetcode(),
                  " -- ", trade.ResultRetcodeDescription());
         return;
      }
   }
   else
   {
      g_entryPrice = bid;
      g_slLevel    = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);
      g_slDistance = g_slLevel - g_entryPrice;
      g_tpLevel    = NormalizeDouble(g_entryPrice - g_slDistance * RR,     g_digits);

      // IDEA 4: BE se activa cuando precio cae TriggerRR x SL_dist desde entrada
      g_beActivateAt = NormalizeDouble(g_entryPrice - g_slDistance * BE_TriggerRR, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel    = NormalizeDouble(g_entryPrice - beBuffer, g_digits);

      g_cachedLots = CalculateLotSize(g_slDistance);
      if(g_cachedLots <= 0)
      {
         if(EnableLog) Print("ERROR ExecuteTrade: lotaje=0 con SL_dist=", g_slDistance);
         return;
      }

      if(!trade.Sell(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel,
                     "TBR SELL v1.0b"))
      {
         if(EnableLog)
            Print("ERROR Sell: ", trade.ResultRetcode(),
                  " -- ", trade.ResultRetcodeDescription());
         return;
      }
   }

   g_tradeExecuted   = true;
   g_breakoutPending = false;
   g_pendingDir      = "";
   g_pendingBarTime  = 0;

   if(CloseAfterHours_Enable)
      g_holdDeadline = TimeCurrent() + (datetime)MaxHoldHours * 3600;

   if(EnableLog) LogTradeOpen();
   if(VIS_Enable) VIS_DrawLevels();
}

//==================================================================
// RegisterTradeFromPending
// IDEA 4: beActivateAt = entry + SL_dist * BE_TriggerRR
//==================================================================
void RegisterTradeFromPending(string direction, double fillPrice, double fillVol)
{
   int effectiveStop = MathMax(g_stopLevel, StopLevel_ExtraPoints);

   g_tradeDir   = direction;
   g_tradeTime  = TimeCurrent();
   g_cachedLots = fillVol;
   g_entryPrice = fillPrice;

   if(direction == "buy")
   {
      g_slLevel      = NormalizeDouble(g_rangeLow  - effectiveStop * _Point, g_digits);
      g_slDistance   = g_entryPrice - g_slLevel;
      g_tpLevel      = NormalizeDouble(g_entryPrice + g_slDistance * RR,     g_digits);

      // IDEA 4
      g_beActivateAt = NormalizeDouble(g_entryPrice + g_slDistance * BE_TriggerRR, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel      = NormalizeDouble(g_entryPrice + beBuffer, g_digits);
   }
   else
   {
      g_slLevel      = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);
      g_slDistance   = g_slLevel - g_entryPrice;
      g_tpLevel      = NormalizeDouble(g_entryPrice - g_slDistance * RR,     g_digits);

      // IDEA 4
      g_beActivateAt = NormalizeDouble(g_entryPrice - g_slDistance * BE_TriggerRR, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel      = NormalizeDouble(g_entryPrice - beBuffer, g_digits);
   }

   ulong ticket = GetOpenPositionTicket();
   if(ticket > 0)
      trade.PositionModify(ticket, g_slLevel, g_tpLevel);

   if(CloseAfterHours_Enable)
      g_holdDeadline = TimeCurrent() + (datetime)MaxHoldHours * 3600;

   if(EnableLog) LogTradeOpen();
   if(VIS_Enable) VIS_DrawLevels();
}

//==================================================================
// PlaceOrUpdatePendingOrders — Modo Ruptura
//==================================================================
void PlaceOrUpdatePendingOrders()
{
   if(g_tradeExecuted || !g_rangeReady) return;

   int    effectiveStop = MathMax(g_stopLevel, StopLevel_ExtraPoints);
   double slBuy         = NormalizeDouble(g_rangeLow  - effectiveStop * _Point, g_digits);
   double slSell        = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(TradeDirection != DIR_SELL && g_ticketBuy == 0)
   {
      double buyEntry  = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);
      double tpBuy     = NormalizeDouble(buyEntry + (buyEntry - slBuy) * RR, g_digits);
      double slDistBuy = buyEntry - slBuy;
      double lotsBuy   = CalculateLotSize(slDistBuy);
      if(lotsBuy <= 0) lotsBuy = g_volumeMin;

      if(buyEntry > ask)
      {
         if(trade.BuyStop(lotsBuy, buyEntry, _Symbol, slBuy, tpBuy,
                          ORDER_TIME_DAY, 0, "TBR BUY STOP v1.0b"))
            g_ticketBuy = trade.ResultOrder();
         else if(EnableLog)
            Print("ERROR BuyStop: ", trade.ResultRetcode(),
                  " -- ", trade.ResultRetcodeDescription());
      }
   }

   if(TradeDirection != DIR_BUY && g_ticketSell == 0)
   {
      double sellEntry  = NormalizeDouble(g_rangeLow - effectiveStop * _Point, g_digits);
      double tpSell     = NormalizeDouble(sellEntry - (slSell - sellEntry) * RR, g_digits);
      double slDistSell = slSell - sellEntry;
      double lotsSell   = CalculateLotSize(slDistSell);
      if(lotsSell <= 0) lotsSell = g_volumeMin;

      if(sellEntry < bid)
      {
         if(trade.SellStop(lotsSell, sellEntry, _Symbol, slSell, tpSell,
                           ORDER_TIME_DAY, 0, "TBR SELL STOP v1.0b"))
            g_ticketSell = trade.ResultOrder();
         else if(EnableLog)
            Print("ERROR SellStop: ", trade.ResultRetcode(),
                  " -- ", trade.ResultRetcodeDescription());
      }
   }
}

//==================================================================
// CheckPendingOrdersFilled
//==================================================================
void CheckPendingOrdersFilled()
{
   if(g_ticketBuy != 0 && !OrderExistsByTicket(g_ticketBuy))
   {
      if(HasOpenPosition()) g_ticketBuy = 0;
   }
   if(g_ticketSell != 0 && !OrderExistsByTicket(g_ticketSell))
   {
      if(HasOpenPosition()) g_ticketSell = 0;
   }
}

//==================================================================
// ManagePosition — Breakeven (IDEA 4)
// Activa BE cuando precio llega a beActivateAt = entry + TriggerRR x SL_dist
//==================================================================
void ManagePosition()
{
   if(!UseBreakeven || g_be_activated) return;

   ulong ticket = GetOpenPositionTicket();
   if(ticket == 0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool beCond = (g_tradeDir == "buy"  && bid >= g_beActivateAt) ||
                 (g_tradeDir == "sell" && ask <= g_beActivateAt);

   if(beCond)
   {
      if(trade.PositionModify(ticket, g_beLevel, g_tpLevel))
      {
         g_slLevel      = g_beLevel;
         g_be_activated = true;
         if(EnableLog)
            Print("BE activado [RR=", DoubleToString(BE_TriggerRR, 2), "x]. SL -> ",
                  DoubleToString(g_beLevel, g_digits),
                  " (entry + ", BE_BufferPct, "% SL buffer)");
         if(VIS_Enable) VIS_UpdateSL();
      }
   }
}

//==================================================================
// CloseAllPositions
//==================================================================
void CloseAllPositions(string exitType)
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
   if(EnableLog)
      Print("Posicion cerrada: ", exitType,
            " | PnL=$", DoubleToString(pnl, 2));

   if(EnableCSV) LogToCSV(exitType, closePrice, pnl);
}

//==================================================================
// CancelPendingOrders
//==================================================================
void CancelPendingOrders()
{
   if(g_ticketBuy  != 0) { CancelOrder(g_ticketBuy);  g_ticketBuy  = 0; }
   if(g_ticketSell != 0) { CancelOrder(g_ticketSell); g_ticketSell = 0; }
}

void CancelOrder(ulong ticket)
{
   if(OrderSelect(ticket))
      trade.OrderDelete(ticket);
}

//==================================================================
// DailyReset
//==================================================================
void DailyReset()
{
   if(EntryMode == MODE_BREAKOUT)
      CancelPendingOrders();

   g_rangeHigh        = 0;
   g_rangeLow         = 0;
   g_slDistance       = 0;
   g_cachedLots       = 0;
   g_rangeReady       = false;
   g_tradeExecuted    = false;
   g_be_activated     = false;
   g_breakoutPending  = false;
   g_pendingDir       = "";
   g_pendingBarTime   = 0;
   g_entryPrice       = 0;
   g_slLevel          = 0;
   g_tpLevel          = 0;
   g_beLevel          = 0;
   g_beActivateAt     = 0;
   g_tradeDir         = "";
   g_tradeTime        = 0;
   g_sessionStartTime = 0;
   g_sessionEndTime   = 0;
   g_holdDeadline     = 0;
   g_ticketBuy        = 0;
   g_ticketSell       = 0;

   VIS_CleanAll();
}

//==================================================================
// Helpers — Sesion
//==================================================================
datetime GetSessionStartTime()
{
   if(g_sessionStartTime > 0) return g_sessionStartTime;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int targetHour = SessionStart_Hour + ServerOffsetHours;
   int targetMin  = SessionStart_Min;

   datetime candidate = StringToTime(
      StringFormat("%04d.%02d.%02d %02d:%02d:00",
                   dt.year, dt.mon, dt.day, targetHour, targetMin));

   if(TimeCurrent() < candidate) return 0;

   g_sessionStartTime = candidate;
   return g_sessionStartTime;
}

datetime GetSessionEndTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int totalMin = (SessionEnd_Hour + ServerOffsetHours) * 60 + SessionEnd_Min;
   int daysOffset = totalMin / (24 * 60);
   int remMin     = totalMin % (24 * 60);
   int endH       = remMin / 60;
   int endM       = remMin % 60;

   datetime base = StringToTime(
      StringFormat("%04d.%02d.%02d 00:00:00", dt.year, dt.mon, dt.day));

   return base + (datetime)(daysOffset * 86400 + endH * 3600 + endM * 60);
}

bool IsTradingDayAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   switch(dt.day_of_week)
   {
      case 0: return TradeSunday;
      case 1: return TradeMonday;
      case 2: return TradeTuesday;
      case 3: return TradeWednesday;
      case 4: return TradeThursday;
      case 5: return TradeFriday;
      case 6: return TradeSaturday;
      default: return false;
   }
}

//==================================================================
// Helpers — Posiciones y Ordenes
//==================================================================
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) > 0)
         if((int)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
            return true;
   }
   return false;
}

ulong GetOpenPositionTicket()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t > 0)
         if((int)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
            return t;
   }
   return 0;
}

bool OrderExistsByTicket(ulong ticket)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderGetTicket(i) == ticket) return true;
   }
   return false;
}

//==================================================================
// Logging
//==================================================================
void LogTradeOpen()
{
   if(!EnableLog) return;
   Print("-- Trade ejecutado (TBR v1.0b) --");
   Print("  Modo      : ", EnumToString(EntryMode));
   Print("  Dir       : ", g_tradeDir);
   Print("  Entry     : ", DoubleToString(g_entryPrice,  g_digits));
   Print("  SL        : ", DoubleToString(g_slLevel,     g_digits));
   Print("  TP        : ", DoubleToString(g_tpLevel,     g_digits));
   Print("  BE activa : ", DoubleToString(g_beActivateAt, g_digits),
         " (entry + ", BE_TriggerRR, "x SL_dist)");
   Print("  BE nivel  : ", DoubleToString(g_beLevel, g_digits),
         " (entry + ", BE_BufferPct, "% SL buffer)");
   Print("  SL_Dist   : ", DoubleToString(g_slDistance, g_digits));
   Print("  Lots      : ", g_cachedLots);
   Print("  RiskConf  : $", RiskAmountUSD);
   Print("  RiskReal  : $", DoubleToString(
         g_cachedLots * g_slDistance * g_valuePerPoint, 2));
}

void LogToCSV(string exitType, double closePrice, double pnl)
{
   if(g_csvHandle == INVALID_HANDLE) return;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string wdays[] = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};

   double riskUSD = g_cachedLots * g_slDistance * g_valuePerPoint;

   // Calcular gap actual del dia para registro
   double gapPctLog = 0;
   if(GapFilter_Enable)
   {
      double prevClose = iClose(_Symbol, PERIOD_D1, 1);
      if(prevClose > 0)
         gapPctLog = MathAbs(g_entryPrice - prevClose) / prevClose * 100.0;
   }

   FileWrite(g_csvHandle,
      StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day),
      StringFormat("%02d:%02d",      dt.hour, dt.min),
      wdays[dt.day_of_week],
      g_tradeDir,
      EnumToString(EntryMode),
      DoubleToString(g_entryPrice,  g_digits),
      DoubleToString(g_slLevel,     g_digits),
      DoubleToString(g_tpLevel,     g_digits),
      DoubleToString(g_beLevel,     g_digits),
      DoubleToString(g_slDistance,  g_digits),
      DoubleToString(g_cachedLots,  2),
      DoubleToString(riskUSD,       2),
      DoubleToString(g_rangeHigh,   g_digits),
      DoubleToString(g_rangeLow,    g_digits),
      DoubleToString(gapPctLog,     3),
      exitType,
      DoubleToString(closePrice,    g_digits),
      DoubleToString(pnl,           2)
   );
   FileFlush(g_csvHandle);
}

//==================================================================
// MODULO VISUAL
//==================================================================
void VIS_DrawRange()
{
   if(!VIS_Enable) return;

   datetime sessionStart = GetSessionStartTime();
   if(sessionStart == 0) return;

   datetime t0 = sessionStart;
   datetime t1 = (datetime)(sessionStart + (long)RangeCandlesCount * PeriodSeconds());

   string boxName = "TBR_RangeBox";
   ObjectDelete(0, boxName);
   ObjectCreate(0, boxName, OBJ_RECTANGLE, 0, t0, g_rangeLow, t1, g_rangeHigh);
   ObjectSetInteger(0, boxName, OBJPROP_COLOR, (color)0x1E90FF);
   ObjectSetInteger(0, boxName, OBJPROP_FILL,  true);
   ObjectSetInteger(0, boxName, OBJPROP_BACK,  true);
   ObjectSetInteger(0, boxName, OBJPROP_WIDTH, 1);

   string lineOpen = "TBR_LineOpen";
   ObjectDelete(0, lineOpen);
   ObjectCreate(0, lineOpen, OBJ_VLINE, 0, sessionStart, 0);
   ObjectSetInteger(0, lineOpen, OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, lineOpen, OBJPROP_STYLE, STYLE_DASH);

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime sessionEndTime = StringToTime(
      StringFormat("%04d.%02d.%02d %02d:%02d:00",
                   dt.year, dt.mon, dt.day,
                   SessionEnd_Hour + ServerOffsetHours,
                   SessionEnd_Min));
   string lineClose = "TBR_LineClose";
   ObjectDelete(0, lineClose);
   ObjectCreate(0, lineClose, OBJ_VLINE, 0, sessionEndTime, 0);
   ObjectSetInteger(0, lineClose, OBJPROP_COLOR, clrOrangeRed);
   ObjectSetInteger(0, lineClose, OBJPROP_STYLE, STYLE_DASH);

   string rH = "TBR_RangeH";
   ObjectDelete(0, rH);
   ObjectCreate(0, rH, OBJ_HLINE, 0, 0, g_rangeHigh);
   ObjectSetInteger(0, rH, OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, rH, OBJPROP_STYLE, STYLE_DOT);

   string rL = "TBR_RangeL";
   ObjectDelete(0, rL);
   ObjectCreate(0, rL, OBJ_HLINE, 0, 0, g_rangeLow);
   ObjectSetInteger(0, rL, OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, rL, OBJPROP_STYLE, STYLE_DOT);

   ChartRedraw();
}

void VIS_DrawLevels()
{
   if(!VIS_Enable) return;

   string arrName = "TBR_Arrow";
   ObjectDelete(0, arrName);
   ObjectCreate(0, arrName, OBJ_ARROW, 0, TimeCurrent(), g_entryPrice);
   if(g_tradeDir == "buy")
   {
      ObjectSetInteger(0, arrName, OBJPROP_ARROWCODE, 241);
      ObjectSetInteger(0, arrName, OBJPROP_COLOR,     clrLime);
   }
   else
   {
      ObjectSetInteger(0, arrName, OBJPROP_ARROWCODE, 242);
      ObjectSetInteger(0, arrName, OBJPROP_COLOR,     clrRed);
   }
   ObjectSetInteger(0, arrName, OBJPROP_WIDTH, 2);

   if(CloseAfterHours_Enable && g_holdDeadline > 0)
   {
      string lineTimeout = "TBR_LineTimeout";
      ObjectDelete(0, lineTimeout);
      ObjectCreate(0, lineTimeout, OBJ_VLINE, 0, g_holdDeadline, 0);
      ObjectSetInteger(0, lineTimeout, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, lineTimeout, OBJPROP_STYLE, STYLE_DOT);
   }

   struct LvlDef { string name; double price; color clr; ENUM_LINE_STYLE sty; int w; };
   LvlDef lvls[4];
   lvls[0].name="TBR_SL";    lvls[0].price=g_slLevel;    lvls[0].clr=clrRed;    lvls[0].sty=STYLE_DOT;   lvls[0].w=1;
   lvls[1].name="TBR_Entry"; lvls[1].price=g_entryPrice; lvls[1].clr=clrWhite;  lvls[1].sty=STYLE_SOLID; lvls[1].w=1;
   lvls[2].name="TBR_BE";    lvls[2].price=g_beLevel;    lvls[2].clr=clrCyan;   lvls[2].sty=STYLE_DASH;  lvls[2].w=1;
   lvls[3].name="TBR_TP";    lvls[3].price=g_tpLevel;    lvls[3].clr=clrLime;   lvls[3].sty=STYLE_SOLID; lvls[3].w=2;

   for(int i = 0; i < 4; i++)
   {
      ObjectDelete(0, lvls[i].name);
      ObjectCreate(0, lvls[i].name, OBJ_HLINE, 0, 0, lvls[i].price);
      ObjectSetInteger(0, lvls[i].name, OBJPROP_COLOR, lvls[i].clr);
      ObjectSetInteger(0, lvls[i].name, OBJPROP_STYLE, lvls[i].sty);
      ObjectSetInteger(0, lvls[i].name, OBJPROP_WIDTH, lvls[i].w);
   }

   string lblName = "TBR_Label";
   ObjectDelete(0, lblName);
   ObjectCreate(0, lblName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, lblName, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, lblName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, lblName, OBJPROP_YDISTANCE, 50);
   ObjectSetString (0, lblName, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE,  9);
   ObjectSetInteger(0, lblName, OBJPROP_COLOR,     clrWhite);

   string dir  = (g_tradeDir == "buy") ? "BUY" : "SELL";
   string mode = (EntryMode == MODE_CONFIRM) ? "CONFIRM" : "BREAKOUT";
   ObjectSetString(0, lblName, OBJPROP_TEXT,
      StringFormat("TBR v1.0b | %s | %s | SL=%.2f | TP=%.2f | BE@%.1fx | Lots:%.2f",
         dir, mode, g_slLevel, g_tpLevel, BE_TriggerRR, g_cachedLots));

   ChartRedraw();
}

void VIS_UpdateSL()
{
   if(!VIS_Enable) return;
   ObjectSetDouble(0, "TBR_SL", OBJPROP_PRICE, g_slLevel);
   ChartRedraw();
}

void VIS_CleanAll()
{
   string names[] = {
      "TBR_RangeBox","TBR_LineOpen","TBR_LineClose","TBR_LineTimeout",
      "TBR_RangeH",  "TBR_RangeL",
      "TBR_Arrow",   "TBR_SL",     "TBR_Entry",
      "TBR_BE",      "TBR_TP",     "TBR_Label"
   };
   for(int i = 0; i < 12; i++) ObjectDelete(0, names[i]);
   ChartRedraw();
}

//==================================================================
// OnTester — metrica custom
// Maximiza PF * (1 - DD) con penalizacion por muestra baja.
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
