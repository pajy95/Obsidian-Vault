
//+------------------------------------------------------------------+
//|  TBR_v1.mq5                                                      |
//|  Time Boxed Range — EA Universal ORB                             |
//|  Version 1.2                                                     |
//|                                                                  |
//|  ESTRATEGIA:                                                     |
//|  Define un rango usando las primeras N velas de la sesión.       |
//|  Ejecuta un breakout por confirmación (cierre de vela) o por    |
//|  ruptura (órdenes STOP pendientes). Una operación por día.      |
//|                                                                  |
//|  CAMBIOS v1.1 (2026-05-09):                                     |
//|  - RiskPct → RiskAmountUSD: riesgo fijo en USD por trade        |
//|  - CloseAfterHours_Enable=true por defecto (MaxHoldHours=4)     |
//|  - Modo BREAKOUT: deadline arranca al colocar órdenes, no       |
//|    al ejecutarlas — cancela pendientes al vencer el timeout      |
//|                                                                  |
//|  CAMBIOS v1.2 (2026-05-09):                                     |
//|  - BUG FIX: MODE_CONFIRM ya no ejecuta entrada si la            |
//|    confirmación de vela llega después de SessionEnd — evita     |
//|    trades post-sesión (72% de los trades en T5 eran post-17:00) |
//|  - UseBreakeven=false por defecto                               |
//|  - OnTester() custom para optimización genética                  |
//|    (penaliza PF × DD, rechaza sample < 30)                      |
//|                                                                  |
//|  CAMBIOS v1.3 (2026-05-10):                                     |
//|  - BUG FIX CRÍTICO: lot calculado con SL_dist del rango bruto  |
//|    pero SL real colocado con distancia mayor (ask - rangeLow -  |
//|    extra). Riesgo real era 3.5x el configurado. Fix: recalcular |
//|    lots en ExecuteTrade() con la SL_dist real al momento de la  |
//|    entrada. Mismo fix en PlaceOrUpdatePendingOrders() para      |
//|    MODE_BREAKOUT (lot ahora = floor(risk / SL_real / VPP))      |
//|                                                                  |
//|  ACTIVOS COMPATIBLES: XAUUSD, NAS100, DJI30, EURUSD, GBPUSD    |
//|  TEMPORALIDADES: M1 a M15                                        |
//|                                                                  |
//|  MAGIC NUMBERS RESERVADOS TBR: 202501–202520                    |
//|                                                                  |
//|  REGLA CRÍTICA: OrderCalcProfit() para VPP — nunca TickValue    |
//+------------------------------------------------------------------+
#property copyright "TBR v1.4"
#property version   "1.40"
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
   MODE_CONFIRM  = 0,  // Confirmación (cierre de vela)
   MODE_BREAKOUT = 1   // Ruptura (órdenes STOP pendientes)
};

//==================================================================
// INPUT PARAMETERS
//==================================================================

input group "=== MODO DE ESTRATEGIA ==="
input ENUM_TRADE_DIRECTION  TradeDirection    = DIR_BUY;       // Dirección de trading
input ENUM_ENTRY_MODE       EntryMode         = MODE_CONFIRM;  // Modo de entrada

input group "=== SESIÓN HORARIA ==="
input int  RangeCandlesCount  = 1;   // Número de velas para formar el rango
input int  SessionStart_Hour  = 14;  // Hora de inicio de sesión (UTC)
input int  SessionStart_Min   = 27;  // Minutos de inicio de sesión
input int  SessionEnd_Hour    = 17;  // Hora de fin de sesión (UTC)
input int  SessionEnd_Min     = 0;   // Minutos de fin de sesión
input int  ServerOffsetHours  = 2;   // Offset servidor vs UTC (FundingPips = UTC+2)

input group "=== FILTROS ==="
input bool   SpreadFilter_Enable  = false;  // Activar filtro de spread máximo
input int    MaxSpread            = 20;     // Spread máximo permitido (puntos)

input group "=== GESTIÓN DE POSICIÓN ABIERTA ==="
input bool   CloseAfterHours_Enable  = true;   // Cerrar posición después de X horas
input int    MaxHoldHours            = 4;       // Horas máximas para mantener posición

input group "=== STOP LOSS Y TAKE PROFIT ==="
input bool   SL_AtRangeExtreme    = true;   // SL en extremo opuesto del rango
input double RR                   = 3.0;    // Risk-Reward (TP = RR × SL distance)
input int    StopLevel_ExtraPoints = 10;    // Puntos extra sobre el stop level del broker

input group "=== BREAKEVEN ==="
input bool   UseBreakeven      = false;  // Activar breakeven
input double BE_TriggerPct     = 50.0;   // Activar BE cuando precio alcanza X% del TP
input double BE_BufferPct      = 2.0;    // Buffer BE = X% de la distancia SL (sobre entry)

input group "=== RIESGO ==="
input double RiskAmountUSD     = 12.50;  // Riesgo fijo por operación en USD

input group "=== DÍAS DE TRADING ==="
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
input bool   VIS_Enable        = true;   // Dibujar objetos en gráfico

input group "=== CONFIG ==="
input int    MagicNumber       = 202501; // Magic Number único por instancia (TBR: 202501–202520)

//==================================================================
// GLOBALES
//==================================================================

CTrade trade;

// Specs símbolo
double g_valuePerPoint;
double g_volumeMin;
double g_volumeMax;
double g_volumeStep;
int    g_digits;
int    g_stopLevel;   // Stop level mínimo del broker en puntos

// Estado diario
double   g_rangeHigh         = 0;
double   g_rangeLow          = 0;
double   g_slDistance        = 0;
double   g_cachedLots        = 0;
bool     g_rangeReady        = false;   // Rango calculado y listo
bool     g_tradeExecuted     = false;   // Ya se ejecutó el trade del día
bool     g_be_activated      = false;
datetime g_lastDay           = 0;
datetime g_sessionStartTime  = 0;       // Timestamp del inicio de sesión (servidor)
datetime g_sessionEndTime    = 0;       // Timestamp del fin de sesión (servidor) — calculado una vez por día
datetime g_holdDeadline      = 0;       // Timestamp límite para CloseAfterHours

// Estado confirmación (MODE_CONFIRM)
bool     g_breakoutPending   = false;
string   g_pendingDir        = "";
datetime g_pendingBarTime    = 0;

// Niveles del trade activo
double   g_entryPrice        = 0;
double   g_slLevel           = 0;
double   g_tpLevel           = 0;
double   g_beLevel           = 0;
double   g_beActivateAt      = 0;  // Precio que activa el BE (% del TP)
string   g_tradeDir          = "";
datetime g_tradeTime         = 0;

// Tickets órdenes pendientes (MODE_BREAKOUT)
ulong    g_ticketBuy         = 0;
ulong    g_ticketSell        = 0;

// CSV
int      g_csvHandle         = INVALID_HANDLE;

//==================================================================
// OnInit
//==================================================================
int OnInit()
{
   // ── Specs del símbolo ─────────────────────────────────────────
   g_volumeMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   g_volumeMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   g_volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   g_digits     = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_stopLevel  = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   // ── VPP via OrderCalcProfit (regla crítica — nunca TickValue) ─
   // NDX100 FundingPips: _Point=0.01 → 1 punto = 100*_Point
   // Usamos 1 punto exacto: closePrice = ask + 100*_Point → profit = VPP
   double ask0       = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profitTest = 0;
   double onePoint   = 100.0 * _Point;   // 1 punto del instrumento
   bool calcOK = OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, 1.0,
                                  ask0, ask0 + onePoint, profitTest);
   // profitTest = profit de 1 punto con 1 lote = VPP directamente
   if(calcOK && profitTest > 0)
      g_valuePerPoint = profitTest;
   else
   {
      // Fallback: ContractSize × TickSize / TickValue ratio
      double cs  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      double ts  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tv  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      g_valuePerPoint = (ts > 0) ? (tv / ts * _Point) : cs * _Point;
      if(EnableLog) Print("VPP via fallback: ", g_valuePerPoint);
   }

   // ── Validación inputs ─────────────────────────────────────────
   if(RangeCandlesCount < 1 || RangeCandlesCount > 100)
   {
      Print("ERROR: RangeCandlesCount debe ser 1–100.");
      return INIT_FAILED;
   }
   if(SessionStart_Hour < 0 || SessionStart_Hour > 23 ||
      SessionEnd_Hour   < 0 || SessionEnd_Hour   > 23)
   {
      Print("ERROR: Horas de sesión inválidas.");
      return INIT_FAILED;
   }
   if(RiskAmountUSD <= 0)
   {
      Print("ERROR: RiskAmountUSD debe ser mayor que 0.");
      return INIT_FAILED;
   }
   if(RR <= 0)
   {
      Print("ERROR: RR debe ser mayor que 0.");
      return INIT_FAILED;
   }

   // ── CTrade ────────────────────────────────────────────────────
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   // ── CSV ───────────────────────────────────────────────────────
   if(EnableCSV)
   {
      string csvName = StringFormat("TBR_v1_%s_Trades.csv", _Symbol);
      g_csvHandle = FileOpen(csvName,
                             FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ",");
      if(g_csvHandle != INVALID_HANDLE)
      {
         FileWrite(g_csvHandle,
            "Date", "Time", "Weekday", "Direction", "EntryMode",
            "EntryPrice", "SL", "TP", "BE_Level",
            "SL_Dist", "Lots", "RiskUSD",
            "RangeHigh", "RangeLow",
            "ExitType", "ClosePrice", "PnL_USD");
         FileFlush(g_csvHandle);
      }
      else
         Print("WARNING: No se pudo crear CSV. Error: ", GetLastError());
   }

   // ── Log de inicio ─────────────────────────────────────────────
   if(EnableLog)
   {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║  TBR v1.4 — Time Boxed Range — ", _Symbol, "              ║");
      Print("╚══════════════════════════════════════════════════════╝");
      Print("  VPP           : ", g_valuePerPoint);
      Print("  Dirección     : ", EnumToString(TradeDirection));
      Print("  Modo entrada  : ", EnumToString(EntryMode));
      Print("  Sesión UTC    : ", SessionStart_Hour, ":", SessionStart_Min,
            " → ", SessionEnd_Hour, ":", SessionEnd_Min,
            " (srv +", ServerOffsetHours, "h)");
      Print("  Velas rango   : ", RangeCandlesCount);
      Print("  RiskAmountUSD : $", RiskAmountUSD);
      Print("  MaxHoldHours  : ", CloseAfterHours_Enable ? (string)MaxHoldHours + "h (activo)" : "desactivado");
      Print("  Breakeven     : ", UseBreakeven ? StringFormat("ON (trigger=%.0f%% TP, buf=%.0f%% SL)", BE_TriggerPct, BE_BufferPct) : "OFF");
      Print("  RR            : ", RR);
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
   // ── Reset diario ──────────────────────────────────────────────
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d",
                                              dt.year, dt.mon, dt.day));
   if(today != g_lastDay)
   {
      DailyReset();
      g_lastDay = today;
   }

   // ── Filtro de día ─────────────────────────────────────────────
   if(!IsTradingDayAllowed()) return;

   datetime now = TimeCurrent();

   // ── Calcular timestamps de sesión una vez por día ─────────────
   if(g_sessionEndTime == 0)
      g_sessionEndTime = GetSessionEndTime();

   // ── PASO 1: Detectar apertura de sesión y calcular rango ──────
   if(!g_rangeReady)
   {
      datetime sessionStartServer = GetSessionStartTime();
      if(sessionStartServer == 0) return;  // Sesión aún no comenzó

      // Esperar a que cierren exactamente RangeCandlesCount velas
      datetime rangeEndBar = (datetime)(sessionStartServer +
                              (long)RangeCandlesCount * PeriodSeconds());
      if(now >= rangeEndBar)
         CalculateRange(sessionStartServer);

      return;  // Sin rango no hay operación
   }

   // ── Cierre forzoso de sesión (timestamp absoluto) ─────────────
   if(now >= g_sessionEndTime)
   {
      if(HasOpenPosition())
         CloseAllPositions("SessionEnd");
      if(EntryMode == MODE_BREAKOUT)
         CancelPendingOrders();
      return;
   }

   // ── Timeout de posición y de órdenes pendientes ───────────────
   if(CloseAfterHours_Enable && g_holdDeadline > 0 &&
      TimeCurrent() >= g_holdDeadline)
   {
      if(HasOpenPosition())
         CloseAllPositions("HoldTimeout");
      if(EntryMode == MODE_BREAKOUT)
         CancelPendingOrders();
      return;
   }

   // ── Filtro de spread ──────────────────────────────────────────
   if(SpreadFilter_Enable)
   {
      int currentSpread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      if(currentSpread > MaxSpread)
      {
         if(EnableLog)
         {
            static datetime lastSpreadLog = 0;
            if(TimeCurrent() - lastSpreadLog > 60)
            {
               Print("Spread filtrado: ", currentSpread, " > ", MaxSpread);
               lastSpreadLog = TimeCurrent();
            }
         }
         return;
      }
   }

   // ── Gestión de posición abierta ───────────────────────────────
   if(HasOpenPosition())
   {
      ManagePosition();
      return;
   }

   if(g_tradeExecuted) return;

   // ── PASO 2: Verificar órdenes pendientes activadas ────────────
   if(EntryMode == MODE_BREAKOUT)
   {
      CheckPendingOrdersFilled();
      if(!g_tradeExecuted)
         PlaceOrUpdatePendingOrders();
      return;
   }

   // ── PASO 3: Modo confirmación — detección y confirmación ──────
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
      // Nueva vela formada — confirmar
      // Verificar que la confirmación llega dentro de la sesión.
      // Si SessionEnd ya pasó, la señal se descarta aunque el breakout
      // haya ocurrido antes (ej: breakout 16:58, confirmación vela 17:05).
      if(now >= g_sessionEndTime)
      {
         if(EnableLog)
            Print("Confirmación post-SessionEnd descartada: ",
                  TimeToString(now), " >= ", TimeToString(g_sessionEndTime));
         g_breakoutPending = false;
         g_pendingDir      = "";
         g_pendingBarTime  = 0;
      }
      else
      {
         bool stillValid = (g_pendingDir == "buy"  && ask > g_rangeHigh) ||
                           (g_pendingDir == "sell" && bid < g_rangeLow);
         if(!stillValid)
         {
            if(EnableLog) Print("False breakout cancelado. Precio regresó al rango.");
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
}

//==================================================================
// OnTradeTransaction — detectar órdenes pendientes ejecutadas
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

      // Determinar dirección del deal ejecutado
      long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
      string dir = (dealType == DEAL_TYPE_BUY) ? "buy" : "sell";

      // Registrar niveles
      double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
      double dealVol   = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
      RegisterTradeFromPending(dir, dealPrice, dealVol);

      // Cancelar la orden contraria
      if(dir == "buy"  && g_ticketSell != 0) CancelOrder(g_ticketSell);
      if(dir == "sell" && g_ticketBuy  != 0) CancelOrder(g_ticketBuy);
      g_ticketBuy  = 0;
      g_ticketSell = 0;
      g_tradeExecuted = true;
   }
}

//==================================================================
// CalculateRange
// Lee las RangeCandlesCount velas cerradas desde el inicio de sesión.
// BUG FIX: iBarShift puede retornar la barra ANTERIOR al sessionStart.
// Usamos iTime para buscar la primera barra con apertura >= sessionStart.
//==================================================================
void CalculateRange(datetime sessionStart)
{
   // Buscar la primera barra cuyo tiempo de apertura >= sessionStart.
   // Partimos del índice que iBarShift nos da como punto de partida.
   int approxIdx = iBarShift(_Symbol, PERIOD_CURRENT, sessionStart, false);
   if(approxIdx < 0)
   {
      if(EnableLog) Print("ERROR CalculateRange: iBarShift no encontró barra.");
      return;
   }

   // Ajustar hacia adelante (índice menor = más reciente) hasta que
   // la barra tenga apertura >= sessionStart
   int startIdx = approxIdx;
   while(startIdx > 0 && iTime(_Symbol, PERIOD_CURRENT, startIdx) < sessionStart)
      startIdx--;
   // Ajustar hacia atrás si nos pasamos (barra anterior al sessionStart)
   while(startIdx <= approxIdx + 5 &&
         iTime(_Symbol, PERIOD_CURRENT, startIdx) > sessionStart)
      startIdx++;

   // Verificar que la barra encontrada pertenece a la sesión
   datetime barOpenTime = iTime(_Symbol, PERIOD_CURRENT, startIdx);
   if(MathAbs((long)(barOpenTime - sessionStart)) > PeriodSeconds())
   {
      if(EnableLog)
         Print("ERROR CalculateRange: primera barra de sesión no coincide. ",
               "BarTime=", TimeToString(barOpenTime),
               " SessionStart=", TimeToString(sessionStart));
      return;
   }

   // Las N velas del rango son [startIdx, startIdx-1, ..., startIdx-(N-1)]
   // (índices DECRECIENTES = más recientes)
   int endIdx = startIdx - (RangeCandlesCount - 1);
   if(endIdx < 0) endIdx = 0;

   double high = -DBL_MAX, low = DBL_MAX;
   for(int i = endIdx; i <= startIdx; i++)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      double l = iLow (_Symbol, PERIOD_CURRENT, i);
      if(h <= 0 || l <= 0)
      {
         if(EnableLog) Print("ERROR: datos insuficientes en barra idx=", i,
                             " time=", TimeToString(iTime(_Symbol, PERIOD_CURRENT, i)));
         return;
      }
      if(h > high) high = h;
      if(l < low)  low  = l;
   }

   if(EnableLog)
   {
      Print("── Barras del rango ────────────────────────────────────");
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

   // Calcular lotaje
   g_cachedLots = CalculateLotSize(g_slDistance);
   if(g_cachedLots <= 0)
   {
      if(EnableLog) Print("ERROR: lotaje calculado = 0. Día omitido.");
      return;
   }

   g_rangeReady = true;

   if(EnableLog)
   {
      Print("── Rango TBR calculado ─────────────────────────────────");
      Print("  RangeHigh : ", DoubleToString(g_rangeHigh, g_digits));
      Print("  RangeLow  : ", DoubleToString(g_rangeLow,  g_digits));
      Print("  SL_Dist   : ", DoubleToString(g_slDistance, g_digits),
            " (", DoubleToString(g_slDistance / _Point, 0), " puntos)");
      Print("  Lots      : ", g_cachedLots);
      Print("  RiskUSD   : $", DoubleToString(
            g_cachedLots * g_slDistance * g_valuePerPoint, 2));
      Print("  Modo      : ", EnumToString(EntryMode));
   }

   // En modo ruptura: colocar órdenes y armar deadline desde ya
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

   double lotsRaw  = RiskAmountUSD / (slDist * g_valuePerPoint);

   double lots = MathFloor(lotsRaw / g_volumeStep) * g_volumeStep;
   lots = MathMax(lots, g_volumeMin);
   lots = MathMin(lots, g_volumeMax);
   lots = NormalizeDouble(lots, 2);

   // Verificación de margen
   double marginReq  = 0;
   double askNow     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, askNow, marginReq))
   {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(marginReq > freeMargin * 0.90)
      {
         double safeLots = MathFloor((freeMargin * 0.90 / marginReq * lots)
                           / g_volumeStep) * g_volumeStep;
         safeLots = MathMax(safeLots, g_volumeMin);
         if(EnableLog)
            Print("WARNING: Margen insuficiente. Lots: ", lots, " → ", safeLots);
         lots = safeLots;
      }
   }

   return lots;
}

//==================================================================
// ExecuteTrade — Modo Confirmación
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
      g_beActivateAt = NormalizeDouble(g_entryPrice +
                       g_slDistance * RR * BE_TriggerPct / 100.0, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel    = NormalizeDouble(g_entryPrice + beBuffer, g_digits);

      // v1.3: recalcular lots con SL_dist real (no el rango bruto del CalculateRange)
      g_cachedLots = CalculateLotSize(g_slDistance);
      if(g_cachedLots <= 0)
      {
         if(EnableLog) Print("ERROR ExecuteTrade: lotaje=0 con SL_dist=", g_slDistance);
         return;
      }

      if(!trade.Buy(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel,
                    "TBR BUY v1"))
      {
         if(EnableLog)
            Print("ERROR Buy: ", trade.ResultRetcode(),
                  " — ", trade.ResultRetcodeDescription());
         return;
      }
   }
   else
   {
      g_entryPrice = bid;
      g_slLevel    = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);
      g_slDistance = g_slLevel - g_entryPrice;
      g_tpLevel    = NormalizeDouble(g_entryPrice - g_slDistance * RR,     g_digits);
      g_beActivateAt = NormalizeDouble(g_entryPrice -
                       g_slDistance * RR * BE_TriggerPct / 100.0, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel    = NormalizeDouble(g_entryPrice - beBuffer, g_digits);

      // v1.3: recalcular lots con SL_dist real (no el rango bruto del CalculateRange)
      g_cachedLots = CalculateLotSize(g_slDistance);
      if(g_cachedLots <= 0)
      {
         if(EnableLog) Print("ERROR ExecuteTrade: lotaje=0 con SL_dist=", g_slDistance);
         return;
      }

      if(!trade.Sell(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel,
                     "TBR SELL v1"))
      {
         if(EnableLog)
            Print("ERROR Sell: ", trade.ResultRetcode(),
                  " — ", trade.ResultRetcodeDescription());
         return;
      }
   }

   g_tradeExecuted   = true;
   g_breakoutPending = false;
   g_pendingDir      = "";
   g_pendingBarTime  = 0;

   // Deadline de cierre por tiempo
   if(CloseAfterHours_Enable)
      g_holdDeadline = TimeCurrent() + (datetime)MaxHoldHours * 3600;

   if(EnableLog) LogTradeOpen();
   if(VIS_Enable) VIS_DrawLevels();
}

//==================================================================
// RegisterTradeFromPending — registrar niveles tras fill de orden pendiente
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
      g_beActivateAt = NormalizeDouble(g_entryPrice +
                       g_slDistance * RR * BE_TriggerPct / 100.0, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel      = NormalizeDouble(g_entryPrice + beBuffer, g_digits);
   }
   else
   {
      g_slLevel      = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);
      g_slDistance   = g_slLevel - g_entryPrice;
      g_tpLevel      = NormalizeDouble(g_entryPrice - g_slDistance * RR,     g_digits);
      g_beActivateAt = NormalizeDouble(g_entryPrice -
                       g_slDistance * RR * BE_TriggerPct / 100.0, g_digits);
      double beBuffer = g_slDistance * BE_BufferPct / 100.0;
      g_beLevel      = NormalizeDouble(g_entryPrice - beBuffer, g_digits);
   }

   // Modificar SL/TP de la posición abierta
   ulong ticket = GetOpenPositionTicket();
   if(ticket > 0)
      trade.PositionModify(ticket, g_slLevel, g_tpLevel);

   // Deadline de cierre por tiempo
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
   double tpBuy         = NormalizeDouble(g_rangeHigh + (g_rangeHigh - slBuy) * RR, g_digits);
   double slSell        = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);
   double tpSell        = NormalizeDouble(g_rangeLow  - (slSell - g_rangeLow) * RR, g_digits);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Colocar orden BUY STOP
   if(TradeDirection != DIR_SELL && g_ticketBuy == 0)
   {
      double buyEntry   = NormalizeDouble(g_rangeHigh + effectiveStop * _Point, g_digits);
      double slDistBuy  = buyEntry - slBuy;  // v1.3: SL_dist real del BUY STOP
      double lotsBuy    = CalculateLotSize(slDistBuy);
      if(lotsBuy <= 0) lotsBuy = g_volumeMin;

      if(buyEntry > ask)  // válido solo si está por encima del precio actual
      {
         if(trade.BuyStop(lotsBuy, buyEntry, _Symbol, slBuy, tpBuy,
                          ORDER_TIME_DAY, 0, "TBR BUY STOP v1"))
            g_ticketBuy = trade.ResultOrder();
         else if(EnableLog)
            Print("ERROR BuyStop: ", trade.ResultRetcode(),
                  " — ", trade.ResultRetcodeDescription());
      }
   }

   // Colocar orden SELL STOP
   if(TradeDirection != DIR_BUY && g_ticketSell == 0)
   {
      double sellEntry  = NormalizeDouble(g_rangeLow - effectiveStop * _Point, g_digits);
      double slDistSell = slSell - sellEntry;  // v1.3: SL_dist real del SELL STOP
      double lotsSell   = CalculateLotSize(slDistSell);
      if(lotsSell <= 0) lotsSell = g_volumeMin;

      if(sellEntry < bid)  // válido solo si está por debajo del precio actual
      {
         if(trade.SellStop(lotsSell, sellEntry, _Symbol, slSell, tpSell,
                           ORDER_TIME_DAY, 0, "TBR SELL STOP v1"))
            g_ticketSell = trade.ResultOrder();
         else if(EnableLog)
            Print("ERROR SellStop: ", trade.ResultRetcode(),
                  " — ", trade.ResultRetcodeDescription());
      }
   }
}

//==================================================================
// CheckPendingOrdersFilled — verificar si alguna orden fue ejecutada
//==================================================================
void CheckPendingOrdersFilled()
{
   // Verificar si el ticket de buy ya no existe como orden pendiente
   // pero existe como posición → fue ejecutada
   if(g_ticketBuy != 0 && !OrderExistsByTicket(g_ticketBuy))
   {
      if(HasOpenPosition())
      {
         // La orden fue ejecutada — ya manejada en OnTradeTransaction
         // Solo limpiar el ticket
         g_ticketBuy = 0;
      }
   }
   if(g_ticketSell != 0 && !OrderExistsByTicket(g_ticketSell))
   {
      if(HasOpenPosition())
      {
         g_ticketSell = 0;
      }
   }
}

//==================================================================
// ManagePosition — Breakeven
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
            Print("BE activado. SL→", DoubleToString(g_beLevel, g_digits),
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
      Print("Posición cerrada: ", exitType,
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
   // Cancelar órdenes pendientes del día anterior
   if(EntryMode == MODE_BREAKOUT)
      CancelPendingOrders();

   g_rangeHigh       = 0;
   g_rangeLow        = 0;
   g_slDistance      = 0;
   g_cachedLots      = 0;
   g_rangeReady      = false;
   g_tradeExecuted   = false;
   g_be_activated    = false;
   g_breakoutPending = false;
   g_pendingDir      = "";
   g_pendingBarTime  = 0;
   g_entryPrice      = 0;
   g_slLevel         = 0;
   g_tpLevel         = 0;
   g_beLevel         = 0;
   g_beActivateAt    = 0;
   g_tradeDir        = "";
   g_tradeTime       = 0;
   g_sessionStartTime = 0;
   g_sessionEndTime   = 0;
   g_holdDeadline    = 0;
   g_ticketBuy       = 0;
   g_ticketSell      = 0;

   VIS_CleanAll();
}

//==================================================================
// Helpers — Sesión
//==================================================================

// Devuelve el timestamp (hora servidor) del inicio de sesión del día actual.
// Retorna 0 si aún no ha llegado esa hora.
datetime GetSessionStartTime()
{
   if(g_sessionStartTime > 0) return g_sessionStartTime;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int targetHour = SessionStart_Hour + ServerOffsetHours;
   int targetMin  = SessionStart_Min;

   // Construir datetime del inicio de sesión de hoy
   datetime candidate = StringToTime(
      StringFormat("%04d.%02d.%02d %02d:%02d:00",
                   dt.year, dt.mon, dt.day, targetHour, targetMin));

   if(TimeCurrent() < candidate) return 0;  // Aún no llegó

   g_sessionStartTime = candidate;
   return g_sessionStartTime;
}

// Retorna el timestamp absoluto (servidor) del fin de sesión del día actual.
// Maneja correctamente offsets que superan las 23h.
datetime GetSessionEndTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int totalMin = (SessionEnd_Hour + ServerOffsetHours) * 60 + SessionEnd_Min;

   // Si el offset lleva el fin de sesión al día siguiente
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
// Helpers — Posiciones y Órdenes
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
   Print("── Trade ejecutado (TBR v1.1) ──────────────────────────");
   Print("  Modo      : ", EnumToString(EntryMode));
   Print("  Dir       : ", g_tradeDir);
   Print("  Entry     : ", DoubleToString(g_entryPrice,  g_digits));
   Print("  SL        : ", DoubleToString(g_slLevel,     g_digits));
   Print("  TP        : ", DoubleToString(g_tpLevel,     g_digits));
   Print("  BE activa : ", DoubleToString(g_beActivateAt, g_digits),
         " (", BE_TriggerPct, "% TP)");
   Print("  BE nivel  : ", DoubleToString(g_beLevel,     g_digits),
         " (entry + ", BE_BufferPct, "% SL)");
   Print("  SL_Dist   : ", DoubleToString(g_slDistance,  g_digits));
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
      exitType,
      DoubleToString(closePrice,    g_digits),
      DoubleToString(pnl,           2)
   );
   FileFlush(g_csvHandle);
}

//==================================================================
// MÓDULO VISUAL
//==================================================================
void VIS_DrawRange()
{
   if(!VIS_Enable) return;

   datetime sessionStart = GetSessionStartTime();
   if(sessionStart == 0) return;

   // Box translúcido del rango (velas de formación)
   datetime t0 = sessionStart;
   datetime t1 = (datetime)(sessionStart + (long)RangeCandlesCount * PeriodSeconds());

   string boxName = "TBR_RangeBox";
   ObjectDelete(0, boxName);
   ObjectCreate(0, boxName, OBJ_RECTANGLE, 0, t0, g_rangeLow, t1, g_rangeHigh);
   ObjectSetInteger(0, boxName, OBJPROP_COLOR,   (color)0x1E90FF);
   ObjectSetInteger(0, boxName, OBJPROP_FILL,    true);
   ObjectSetInteger(0, boxName, OBJPROP_BACK,    true);
   ObjectSetInteger(0, boxName, OBJPROP_WIDTH,   1);

   // Línea vertical de inicio de sesión
   string lineOpen = "TBR_LineOpen";
   ObjectDelete(0, lineOpen);
   ObjectCreate(0, lineOpen, OBJ_VLINE, 0, sessionStart, 0);
   ObjectSetInteger(0, lineOpen, OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, lineOpen, OBJPROP_STYLE, STYLE_DASH);

   // Línea vertical de cierre de sesión
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

   // Líneas horizontales del rango
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

   // Flecha de entrada
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

   // Línea vertical de timeout (si aplica)
   if(CloseAfterHours_Enable && g_holdDeadline > 0)
   {
      string lineTimeout = "TBR_LineTimeout";
      ObjectDelete(0, lineTimeout);
      ObjectCreate(0, lineTimeout, OBJ_VLINE, 0, g_holdDeadline, 0);
      ObjectSetInteger(0, lineTimeout, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, lineTimeout, OBJPROP_STYLE, STYLE_DOT);
   }

   // Niveles horizontales
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

   // Label de estado
   string lblName = "TBR_Label";
   ObjectDelete(0, lblName);
   ObjectCreate(0, lblName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, lblName, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, lblName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, lblName, OBJPROP_YDISTANCE, 50);
   ObjectSetString (0, lblName, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE,  9);
   ObjectSetInteger(0, lblName, OBJPROP_COLOR,     clrWhite);

   string dir  = (g_tradeDir == "buy") ? "▲ BUY" : "▼ SELL";
   string mode = (EntryMode == MODE_CONFIRM) ? "CONFIRM" : "BREAKOUT";
   ObjectSetString(0, lblName, OBJPROP_TEXT,
      StringFormat("TBR v1 | %s | %s | SL=%.5f | TP=%.5f | RR=%.1f | Lots:%.2f",
         dir, mode, g_slLevel, g_tpLevel, RR, g_cachedLots));

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
      "TBR_RangeBox", "TBR_LineOpen", "TBR_LineClose", "TBR_LineTimeout",
      "TBR_RangeH",   "TBR_RangeL",
      "TBR_Arrow",    "TBR_SL",      "TBR_Entry",
      "TBR_BE",       "TBR_TP",      "TBR_Label"
   };
   for(int i = 0; i < 12; i++) ObjectDelete(0, names[i]);
   ChartRedraw();
}

//==================================================================
// OnTester — métrica custom para optimización genética
// Maximiza PF × (1 - DD_relativo) con penalización por muestra baja.
// Requiere: Strategy Tester → Optimizar por "Custom max".
//==================================================================
double OnTester()
{
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < 30) return 0.0;  // muestra insuficiente — rechazar

   double pf = TesterStatistics(STAT_PROFIT_FACTOR);
   if(pf <= 0) return 0.0;

   double dd = TesterStatistics(STAT_EQUITY_DD_RELATIVE);  // % 0–100

   // Penalización severa si DD supera el umbral del 10%
   if(dd > 10.0) return 0.0;

   return pf * (1.0 - dd / 100.0);
}
//+------------------------------------------------------------------+
