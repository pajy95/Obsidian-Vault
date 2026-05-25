//+------------------------------------------------------------------+
//|                                          BreakoutNY_FINAL_FP.mq5  |
//|              BreakoutNY EA v9.1 VISUAL — FundingPips NAS100              |
//|                                                                   |
//|  ═══ TRADING (idéntico a v7) ════════════════════════════════   |
//|  · Breakout de las 3 velas 14:35 / 14:40 / 14:45 UTC           |
//|  · Ventana de entrada 14:50 – 15:15 UTC (configurable)         |
//|  · Cierres parciales en TP1 y TP2 (configurables)              |
//|  · BreakEven con buffer de ganancia garantizada                 |
//|  · Filtros día semana + rango MinSL/MaxSL                       |
//|  · CSV de operaciones                                            |
//|                                                                   |
//|  ═══ VISUAL (se dibuja automáticamente en el gráfico) ════════  |
//|                                                                   |
//|  ZONA DEL RANGO                                                  |
//|    Rectángulo azul oscuro sobre las 3 velas del rango           |
//|    Línea azul en el HIGH y LOW del rango                        |
//|                                                                   |
//|  AL HABER RUPTURA                                                |
//|    Flecha ▲ verde (BUY) o ▼ roja (SELL)                        |
//|    Línea vertical punteada en la vela de ruptura                |
//|                                                                   |
//|  NIVELES (se extienden N velas a la derecha)                    |
//|    ─ ─  roja         → SL   (se actualiza al activar BE)        |
//|    ───  blanca        → ENTRY                                    |
//|    ···  celeste       → BE   (entry + buffer %)                 |
//|    ───  amarilla      → TP1  1:1                                |
//|    ───  naranja       → TP2  1:2                                |
//|    ══   verde gruesa  → TP3  1:3  (objetivo final)             |
//|                                                                   |
//|  Cada línea tiene etiqueta con nombre y precio exacto           |
//|  Etiqueta resumen encima del rango: SL pts, TP3 pts, dirección  |
//|                                                                   |
//|  DINÁMICA EN VIVO                                                |
//|    Al activarse el BE → línea SL se mueve a bePrice            |
//|    Al moverse SL a TP1 → línea SL se mueve a tp1Price          |
//|    Al cerrarse el trade → marca de precio de cierre en gráfico  |
//+------------------------------------------------------------------+
#property copyright "BreakoutNY EA v8.0 FundingPips"
#property version   "9.10"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//===================================================================
//  PARÁMETROS DE ENTRADA
//===================================================================

input group "=== HORARIO ==="
input int    ServerOffsetHours  = 2;     // Offset servidor vs UTC — FundingPips UTC+2 (verificar)
input int    EntryWindowEnd_Min = 15;    // Minuto fin ventana (14:50 – 15:HH UTC)
input int    SessionCloseHour   = 17;    // Hora de cierre forzoso (UTC). Default=17:00, extendido=17:30
input int    SessionCloseMin    = 0;     // Minuto de cierre forzoso (UTC). Default=0, extendido=30
                                          // Ejemplo extendido: SessionCloseHour=17, SessionCloseMin=30
                                          // ⚠ No extender más allá de 18:00 UTC — riesgo overnight

input group "=== RIESGO ==="
input double RiskAmountUSD      = 50.0;  // Riesgo por operación en USD
// UseFixedLot eliminado como input — siempre dinámico para evitar errores de optimización
// Para lote fijo manual: poner RiskAmountUSD muy pequeño o editar el código

input group "=== OBJETIVOS ==="
input double TP1_RR             = 1.0;   // TP1 — múltiplo del SL (1:1) — activa BE
input double TP2_RR             = 2.0;   // TP2 — múltiplo del SL (1:2) — SL sube a TP1
input double TP3_RR             = 3.0;   // TP3 — múltiplo del SL (1:3) — target final

input group "=== CIERRES PARCIALES ==="
input bool   EnablePartials     = false; // BACKTEST ORIGINAL: cierra todo en TP3, sin parciales
input int    TP1_ClosePct       = 40;    // % del lote a cerrar en TP1  (0–60)
input int    TP2_ClosePct       = 40;    // % del lote a cerrar en TP2  (0–60)

input group "=== BREAKEVEN ==="
input double BE_BufferPct       = 20.0;  // Buffer BE: % del SL original como ganancia mínima

input group "=== FILTROS ==="
input bool   FilterMonday       = false; // true=OPERA | false=FILTRA — FILTRADO: PF=1.188, AvgTrade=$8.9 (validado)
input bool   FilterTuesday      = true;  // true=OPERA | false=FILTRA
input bool   FilterWednesday    = false; // true=OPERA | false=FILTRA — FILTRADO por backtest ADJ
input bool   FilterThursday     = true;  // true=OPERA | false=FILTRA
input bool   FilterFriday       = true;  // true=OPERA | false=FILTRA
input double MinSL_Points       = 25.0;  // SL mínimo en puntos REALES (equivalente 250 broker pts RoboForex)
input double MaxSL_Points       = 50.0;  // SL máximo en puntos REALES (equivalente 450 broker pts RoboForex)
input bool   ConfirmOnClose     = true;  // Esperar cierre de vela M5 antes de entrar
                                         // true  = entra al ABRIR la vela SIGUIENTE al primer cruce del rango
                                         //         → filtra mechas falsas que cruzan y revierten en la misma vela
                                         // false = entra en el primer tick que cruza el rango (comportamiento original)

input group "=== FILTRO ATR (VOLATILIDAD) ==="
input bool   ATR_FilterEnable   = true;  // true = activar filtro ATR | false = desactivado (no afecta trading)
input int    ATR_Period         = 14;    // Período del ATR (velas M5)
input double ATR_MaxMultiplier  = 2.0;  // Máx ATR permitido = ATR_Baseline × ATR_MaxMultiplier
input double ATR_MinMultiplier  = 0.5;  // Mín ATR permitido = ATR_Baseline × ATR_MinMultiplier
input int    ATR_BaselineDays   = 20;   // Días de lookback para calcular la línea base del ATR
                                         // Lógica: si el ATR actual está fuera del rango [baseline×min, baseline×max]
                                         //         → mercado con volatilidad anormal → no operar ese día
                                         // Ejemplo: baseline=50pts, multiplier máx=2.0 → no opera si ATR>100pts
                                         // Ejemplo: baseline=50pts, multiplier mín=0.5 → no opera si ATR<25pts

input group "=== FILTRO DE TENDENCIA INTRADIARIA (Experimental) ==="
input bool   TF_Enable          = false; // true = activar | false = desactivado (configuración ADJ base)
input double TF_Threshold_Pts   = 0.0;   // Zona neutra ±N pts alrededor del prevClose (0=binario puro)
input bool   TF_BlockNeutral    = true;  // true = zona neutra → no operar | false → operar en ambas
                                          // LÓGICA: prevClose = cierre última vela M5 ≤16:55 UTC día anterior
                                          //         midRange  = (rangeHigh + rangeLow) / 2.0
                                          //         midRange > prevClose + threshold → solo BUY
                                          //         midRange < prevClose - threshold → solo SELL
                                          //         dentro del threshold             → zona neutra
                                          // ⚠ PENDIENTE VALIDACIÓN — backtest con TF_Enable=true aún no confirmado

input group "=== LOGGING ==="
input bool   EnableCSV          = true;
input string CSVFileName        = "BreakoutNY_v9_trades";

input group "=== VISUAL ==="
input bool   VIS_Enable         = true;  // Activar módulo visual en el gráfico
input int    VIS_LookbackDays   = 25;    // Días históricos a redibujar al iniciar
input int    VIS_ExtendBars     = 50;    // Velas que se extienden los niveles hacia la derecha
input bool   VIS_ShowBE         = true;  // Mostrar línea de BreakEven en el gráfico
input bool   VIS_ShowLabel      = true;  // Mostrar panel informativo en esquinas
// ─── Colores del módulo visual ───────────────────────────────────────────────
input color  VIS_ColRange       = C'14,25,52';    // Color fondo zona de rango 14:35–14:45
input color  VIS_ColRangeBorder = C'55,115,215';  // Color bordes HIGH/LOW del rango
input color  VIS_ColSL          = C'220,50,70';   // Color línea Stop Loss
input color  VIS_ColEntry       = C'195,208,230'; // Color línea de entrada (Entry)
input color  VIS_ColBE          = C'0,195,218';   // Color línea BreakEven
input color  VIS_ColTP1         = C'228,188,38';  // Color línea Take Profit 1
input color  VIS_ColTP2         = C'228,128,28';  // Color línea Take Profit 2
input color  VIS_ColTP3         = C'28,208,128';  // Color línea Take Profit 3 (objetivo final)

input group "=== CONFIGURACIÓN ==="
input ulong  MagicNumber        = 202401;

//===================================================================
//  VARIABLES GLOBALES — TRADING
//===================================================================

CTrade        trade;
CPositionInfo posInfo;

// Estado diario
bool     rangeCalculated = false;
bool     tradeExecuted   = false;
bool     dayFiltered     = false;
bool     rangeFiltered   = false;
double   rangeHigh       = 0;
double   rangeLow        = 0;
double   slDistance      = 0;
datetime lastTradeDay    = 0;

// Estado operación activa
ulong    activeTicket    = 0;
double   entryPrice      = 0;
double   originalSL      = 0;
double   originalLots    = 0;
double   cachedLots     = 0;   // Lots calculados al detectar el rango (evita recalcular en cada tick)

// Filtro de Tendencia — PrevClose vs MidRange (experimental, TF_Enable=false por defecto)
double   tf_prevClose   = 0;      // Cierre última vela M5 ≤16:55 UTC del día anterior
double   tf_midRange    = 0;      // Midpoint del rango NY calculado en PASO 1
string   tf_allowedDir  = "both"; // "buy" | "sell" | "both" | "none"

// Estado de confirmación de ruptura (ConfirmOnClose)
bool     breakoutPending = false; // Se detectó un cruce del rango, esperando cierre de vela
string   pendingDir      = "";    // Dirección del breakout pendiente ("buy" / "sell")
datetime pendingBarTime  = 0;     // Tiempo de la vela que cruzó (esperamos que esta cierre)
string   tradeDir        = "";
double   tp1Price        = 0;
double   tp2Price        = 0;
double   tp3Price        = 0;
double   bePrice         = 0;

// Fases de gestión
bool     phase1Done      = false;
bool     phase2Done      = false;

// Logging CSV
int      csvHandle       = INVALID_HANDLE;
datetime log_OpenTime    = 0;
string   log_Weekday     = "";
bool     log_Phase1Hit   = false;
bool     log_Phase2Hit   = false;
double   log_SL_Pts      = 0;
// Diagnóstico lotaje y SL
double   log_ValuePerPoint   = 0;   // USD por punto por lot usado en el cálculo
double   log_LotsCalculated  = 0;   // Lotaje matemático antes de normalizar
double   log_RiskReal_USD    = 0;   // Riesgo real = SL_pts × vpp × lots
double   log_RangeHigh       = 0;   // High exacto del rango detectado
double   log_RangeLow        = 0;   // Low exacto del rango detectado
double   log_SL_Final        = 0;   // SL al momento del cierre (puede haber subido por BE)
bool     log_BE_Activated    = false; // Si el BE llegó a moverse
bool     log_ConfirmUsed     = false; // Si la entrada esperó confirmación de cierre de vela

// Stats OnTester
int      stat_total      = 0;
int      stat_wins       = 0;
int      stat_losses     = 0;
double   stat_grossProfit= 0;
double   stat_grossLoss  = 0;

//===================================================================
//  VARIABLES GLOBALES — VISUAL
//===================================================================

#define VIS_PFX "BNYV_"       // Prefijo de todos los objetos del visual

string   vis_dayTag      = ""; // Tag del día actual (YYYYMMDD)
bool     vis_hasTrade    = false;

//===================================================================
//  ██████╗  FUNCIONES DE TRADING
//===================================================================

void GetCurrentUTC(int &hour, int &minute)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, dt);
   hour = dt.hour;  minute = dt.min;
}

int GetWeekdayUTC()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, dt);
   return dt.day_of_week;
}

string WeekdayName(int wd)
{
   string n[] = {"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"};
   return n[wd];
}

bool IsTradingDayAllowed()
{
   switch(GetWeekdayUTC())
   {
      case 1: return FilterMonday;
      case 2: return FilterTuesday;
      case 3: return FilterWednesday;
      case 4: return FilterThursday;
      case 5: return FilterFriday;
      default: return false;
   }
}

double CalculateLotSize(double slPoints)
{
   //-------------------------------------------------------------------
   // Funcion de lotaje robusta - compatible con todos los brokers,
   // incluyendo aquellos que reportan TickValue=0 (ej. FundingPips NDX100)
   //
   // UNIDADES: slPoints = puntos REALES del índice (ej. 35.0 para un SL de 35 pts)
   //           valuePerPoint = USD por lot por 1 punto real (ej. $20/lot/pt con ContractSize=20)
   //           Lots = RiskUSD / (slPoints × valuePerPoint)
   //           Ejemplo: $50 / (35 × $20) = 0.071 → 0.07 lots → riesgo real = 35×$20×0.07 = $49 ✅
   //
   // Cascada de fallback:
   //   1. TickValue y TickSize validos  -> valuePerPoint = tv/ts
   //   2. TickValue=0                  -> valuePerPoint = ContractSize (fallback)
   //   3. Sin datos                    -> volumen minimo + log error
   //-------------------------------------------------------------------
   if(slPoints <= 0) return 0;

   double tv  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double cs  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double pt  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ls  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mn  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double valuePerPoint = 0;   // USD por lot por 1 punto de precio

   // METODO 1: Broker reporta TickValue y TickSize correctos
   if(tv > 0 && ts > 0)
   {
      valuePerPoint = tv / ts;
   }
   // METODO 2: TickValue=0 (bug en algunos brokers CFD)
   // Para un CFD de índice: valuePerPoint = ContractSize
   // Equivalencia: tv/ts = ContractSize×pt/pt = ContractSize
   else if(cs > 0)
   {
      valuePerPoint = cs;
      Print("INFO LotCalc: TickValue=0. Fallback: valuePerPoint=ContractSize=", cs);
   }
   else
   {
      Print("ERROR LotCalc: Datos insuficientes. TV=", tv, " TS=", ts,
            " CS=", cs, " PT=", pt, ". Usando lote minimo.");
      return mn;
   }

   if(valuePerPoint <= 0)
   {
      Print("ERROR LotCalc: valuePerPoint=0. Usando lote minimo.");
      return mn;
   }

   // LOTAJE DINAMICO: Lots = RiskUSD / (SL_pts_reales × $/pt/lot)
   double lotsRaw = RiskAmountUSD / (slPoints * valuePerPoint);
   double lots    = MathFloor(lotsRaw / ls) * ls;
   lots           = MathMax(mn, MathMin(mx, lots));

   double realRisk = slPoints * valuePerPoint * lots;

   // Guardar en variables globales para el CSV de diagnóstico
   log_ValuePerPoint  = valuePerPoint;
   log_RiskReal_USD   = realRisk;

   // ── Verificación de margen disponible ────────────────────────
   // Evita "not enough money" calculando el margen requerido
   // y reduciendo lots hasta que quepan en el capital disponible.
   double freeMargin  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginPerLot = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0,
                       SymbolInfoDouble(_Symbol, SYMBOL_ASK), marginPerLot))
      marginPerLot = SymbolInfoDouble(_Symbol, SYMBOL_ASK) *
                     SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * 0.05;

   if(marginPerLot > 0)
   {
      double maxLotsByMargin = MathFloor((freeMargin * 0.90) / marginPerLot / ls) * ls;
      maxLotsByMargin = MathMax(mn, MathMin(mx, maxLotsByMargin));
      if(lots > maxLotsByMargin)
      {
         Print("AVISO Margen: lots=", DoubleToString(lots,2),
               " excede margen libre=$", DoubleToString(freeMargin,2),
               " (max=", DoubleToString(maxLotsByMargin,2), " lots).",
               " Reduciendo a ", DoubleToString(maxLotsByMargin,2));
         lots = maxLotsByMargin;
         realRisk = slPoints * valuePerPoint * lots;
         log_RiskReal_USD = realRisk;
      }
   }

   log_LotsCalculated = lotsRaw;

   Print("LotCalc | SL=", DoubleToString(slPoints,2), "pts",
         " | vpp=$", DoubleToString(valuePerPoint,2), "/pt/lot",
         " | Raw=", DoubleToString(lotsRaw,4),
         " | Lots=", DoubleToString(lots,2),
         " | Risk=$", DoubleToString(realRisk,2),
         " | Margin/lot=$", DoubleToString(marginPerLot,2),
         " | FreeMargin=$", DoubleToString(freeMargin,2));

   return lots;
}

double NormalizeLots(double lots)
{
   double ls = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   lots = MathFloor(lots / ls) * ls;
   return MathMax(mn, MathMin(mx, lots));
}

bool GetCandleAtUTC(int h, int m, double &high, double &low)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M5, 0, 100, rates) <= 0) return false;
   for(int i = 0; i < ArraySize(rates); i++)
   {
      MqlDateTime dt;
      TimeToStruct(rates[i].time - (long)ServerOffsetHours * 3600, dt);
      if(dt.hour == h && dt.min == m)
      {
         high = rates[i].high;
         low  = rates[i].low;
         return true;
      }
   }
   return false;
}

bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(posInfo.SelectByIndex(i))
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber)
            return true;
   return false;
}

double GetPositionLots()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(posInfo.SelectByIndex(i))
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber)
            return posInfo.Volume();
   return 0;
}

ulong GetPositionTicket()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(posInfo.SelectByIndex(i))
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber)
            return posInfo.Ticket();
   return 0;
}

bool ClosePartial(ulong ticket, double lotsToClose)
{
   lotsToClose = NormalizeLots(lotsToClose);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lotsToClose < minLot)
   {
      Print("ClosePartial: lote muy pequeño, cerrando todo.");
      return trade.PositionClose(ticket);
   }
   return trade.PositionClosePartial(ticket, lotsToClose);
}

bool ModifySL(double newSL)
{
   ulong ticket = GetPositionTicket();
   if(ticket == 0) return false;
   if(!posInfo.SelectByTicket(ticket)) return false;
   double curSL = posInfo.StopLoss();
   double curTP = posInfo.TakeProfit();
   if(tradeDir == "buy"  && newSL <= curSL) return false;
   if(tradeDir == "sell" && newSL >= curSL && curSL > 0) return false;
   return trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), curTP);
}

void CloseAll()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(posInfo.SelectByIndex(i))
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == MagicNumber)
            trade.PositionClose(posInfo.Ticket());
}

//===================================================================
//  ██████╗  LOGGING CSV
//===================================================================

void InitCSV()
{
   if(!EnableCSV) return;
   string path = CSVFileName + ".csv";
   csvHandle = FileOpen(path, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ',');
   if(csvHandle == INVALID_HANDLE) { Print("ERROR CSV: ", GetLastError()); return; }
   FileWrite(csvHandle,
      "OpenTime","CloseTime","Weekday","Direction",
      "Entry","SL_orig","TP1","TP2","TP3","Lots",
      "SL_Points","RR_TP1","RR_TP2","RR_TP3",
      "BE_Buffer_Pct","TP1_ClosePct","TP2_ClosePct",
      "Phase1Hit","Phase2Hit",
      "ExitType","ClosePrice","PnL_USD",
      "DayFiltered","RangeFiltered",
      "MinSL_Filter","MaxSL_Filter","EntryWindowEnd",
      "ValuePerPoint","LotsCalculated","RiskReal_USD",
      "RangeHigh","RangeLow","SL_Final","BE_Activated",
      "ConfirmOnClose");
   Print("CSV listo: ", path);
}

void WriteTradeRow(string closeTime, string exitType,
                   double closePrice, double pnl,
                   bool dayFlt, bool rngFlt)
{
   if(!EnableCSV || csvHandle == INVALID_HANDLE) return;
   FileWrite(csvHandle,
      TimeToString(log_OpenTime, TIME_DATE|TIME_MINUTES),
      closeTime, log_Weekday, tradeDir,
      DoubleToString(entryPrice,  _Digits),
      DoubleToString(originalSL,  _Digits),
      DoubleToString(tp1Price,    _Digits),
      DoubleToString(tp2Price,    _Digits),
      DoubleToString(tp3Price,    _Digits),
      DoubleToString(originalLots, 2),
      DoubleToString(log_SL_Pts, 1),
      DoubleToString(TP1_RR, 1), DoubleToString(TP2_RR, 1), DoubleToString(TP3_RR, 1),
      DoubleToString(BE_BufferPct, 1),
      IntegerToString(EnablePartials ? TP1_ClosePct : 0),
      IntegerToString(EnablePartials ? TP2_ClosePct : 0),
      log_Phase1Hit ? "1":"0", log_Phase2Hit ? "1":"0",
      exitType,
      DoubleToString(closePrice, _Digits),
      DoubleToString(pnl, 2),
      dayFlt ? "1":"0", rngFlt ? "1":"0",
      DoubleToString(MinSL_Points, 0),
      DoubleToString(MaxSL_Points, 0),
      IntegerToString(EntryWindowEnd_Min),
      DoubleToString(log_ValuePerPoint,  4),
      DoubleToString(log_LotsCalculated, 4),
      DoubleToString(log_RiskReal_USD,   2),
      DoubleToString(log_RangeHigh, _Digits),
      DoubleToString(log_RangeLow,  _Digits),
      DoubleToString(log_SL_Final,  _Digits),
      log_BE_Activated ? "1" : "0",
      log_ConfirmUsed  ? "1" : "0");
}

void WriteFilteredRow(string reason)
{
   if(!EnableCSV || csvHandle == INVALID_HANDLE) return;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   string ds = StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day);
   FileWrite(csvHandle,
      ds, "", WeekdayName(GetWeekdayUTC()), "",
      "","","","","","",
      "","","","",
      DoubleToString(BE_BufferPct, 1),
      IntegerToString(TP1_ClosePct), IntegerToString(TP2_ClosePct),
      "0","0",
      "filtered_"+reason, "", "0",
      reason=="day"?"1":"0", reason=="range"?"1":"0",
      DoubleToString(MinSL_Points,0), DoubleToString(MaxSL_Points,0),
      IntegerToString(EntryWindowEnd_Min));
}

//===================================================================
//  ██████╗  RESET DIARIO
//===================================================================

void DailyReset()
{
   rangeCalculated = false; tradeExecuted = false;
   dayFiltered     = false; rangeFiltered = false;
   rangeHigh       = 0;     rangeLow      = 0;     slDistance = 0;
   cachedLots      = 0;
   activeTicket    = 0;     entryPrice    = 0;     originalSL = 0;
   originalLots    = 0;     tradeDir      = "";
   tp1Price        = 0;     tp2Price      = 0;
   tp3Price        = 0;     bePrice       = 0;
   phase1Done      = false; phase2Done    = false;
   log_OpenTime    = 0;     log_Weekday   = "";
   log_Phase1Hit   = false; log_Phase2Hit = false;
   log_SL_Pts      = 0;
   log_ValuePerPoint   = 0;  log_LotsCalculated = 0;
   log_RiskReal_USD    = 0;  log_RangeHigh      = 0;
   log_RangeLow        = 0;  log_SL_Final       = 0;
   log_BE_Activated    = false;
   log_ConfirmUsed     = false;
   breakoutPending     = false;
   pendingDir          = "";
   pendingBarTime      = 0;
   tf_prevClose        = 0;
   tf_midRange         = 0;
   tf_allowedDir       = "both";
   // Visual
   vis_dayTag   = "";
   vis_hasTrade = false;
}

//===================================================================
//  ██████╗  FUNCIONES VISUALES
//===================================================================

// Genera el tag único del día (YYYYMMDD en UTC)
string VisMakeDayTag()
{
   MqlDateTime u;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, u);
   return StringFormat("%04d%02d%02d", u.year, u.mon, u.day);
}

// Borra todos los objetos del visual que coincidan con un tag de día
void VisDeleteDay(const string tag)
{
   int n = ObjectsTotal(0, 0, -1);
   for(int i = n - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, VIS_PFX) == 0 && StringFind(name, tag) >= 0)
         ObjectDelete(0, name);
   }
}

// Borra absolutamente todos los objetos del visual
void VisPurgeAll()
{
   int n = ObjectsTotal(0, 0, -1);
   for(int i = n - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, VIS_PFX) == 0)
         ObjectDelete(0, name);
   }
}

//--- Primitivos de dibujo ─────────────────────────────────────────

void VisSegment(const string name,
                datetime t1, datetime t2,
                double   p1, double   p2,
                color clr, ENUM_LINE_STYLE style, int width, bool back)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_TIME,       t1, 0);
   ObjectSetInteger(0, name, OBJPROP_TIME,       t2, 1);
   ObjectSetDouble(0,  name, OBJPROP_PRICE,      p1, 0);
   ObjectSetDouble(0,  name, OBJPROP_PRICE,      p2, 1);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       back);
}

void VisText(const string name,
             datetime t, double price, const string txt,
             color clr, int sz, ENUM_ANCHOR_POINT anchor, bool back)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetInteger(0, name, OBJPROP_TIME,        t);
   ObjectSetDouble(0,  name, OBJPROP_PRICE,       price);
   ObjectSetString(0,  name, OBJPROP_TEXT,        txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,    sz);
   ObjectSetString(0,  name, OBJPROP_FONT,        "Consolas");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,      anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,      true);
   ObjectSetInteger(0, name, OBJPROP_BACK,        back);
}

// Nivel horizontal — label al lado DERECHO del final de la línea
// tEnd + 1 vela garantiza que el texto queda fuera del área de velas activas
void VisLevel(const string name,
              datetime t1, datetime t2, double price,
              color clr, ENUM_LINE_STYLE style, int width,
              const string label)
{
   VisSegment(name, t1, t2, price, price, clr, style, width, false);
   // Label una vela después del final de la línea → zona derecha libre
   // ANCHOR_LEFT_UPPER = texto crece hacia la derecha desde el punto de anclaje
   datetime tLabel   = t2 + (datetime)(PeriodSeconds(PERIOD_M5));
   string   priceStr = DoubleToString(price, _Digits <= 5 ? 1 : _Digits);
   VisText(name + "_LBL", tLabel, price,
           " " + label + " " + priceStr,
           clr, 7, ANCHOR_LEFT_UPPER, false);
}

// Actualiza el precio de una línea ya dibujada (para SL dinámico)
void VisMoveLevel(const string name, double newPrice)
{
   if(ObjectFind(0, name) < 0) return;
   ObjectSetDouble(0, name, OBJPROP_PRICE, newPrice, 0);
   ObjectSetDouble(0, name, OBJPROP_PRICE, newPrice, 1);

   string lblName = name + "_LBL";
   if(ObjectFind(0, lblName) < 0) return;
   ObjectSetDouble(0, lblName, OBJPROP_PRICE, newPrice);
   // Reconstruir texto conservando el prefijo de label
   string currTxt  = ObjectGetString(0, lblName, OBJPROP_TEXT);
   int    sep      = StringFind(currTxt, " ");
   string lbl      = sep >= 0 ? StringSubstr(currTxt, 0, sep + 1) : currTxt;
   string priceStr = DoubleToString(newPrice, _Digits <= 5 ? 1 : _Digits);
   ObjectSetString(0, lblName, OBJPROP_TEXT, lbl + priceStr + " ");
   ChartRedraw();
}

//===================================================================
//  DIBUJAR UN DÍA COMPLETO (rango + niveles si hubo ruptura)
//===================================================================

// Busca una vela específica (hora:min UTC) dentro del array de rates
bool VisGetCandle(const MqlRates &R[], int total,
                  datetime dayUTC,   // medianoche UTC del día
                  int h, int m,
                  double &hi, double &lo, datetime &barTime)
{
   for(int i = 0; i < total; i++)
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      // Medianoche UTC de esta barra
      datetime barDay = StringToTime(
         StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
      if(barDay != dayUTC) continue;
      if(u.hour == h && u.min == m)
      {
         hi = R[i].high;  lo = R[i].low;  barTime = R[i].time;
         return true;
      }
   }
   return false;
}

void VisDrawDay(const MqlRates &R[], int total, datetime dayUTC)
{
   // ── Obtener las 3 velas del rango ─────────────────────────────
   double h35,l35, h40,l40, h45,l45;
   datetime t35, t40, t45;
   if(!VisGetCandle(R, total, dayUTC, 14,35, h35,l35,t35)) return;
   if(!VisGetCandle(R, total, dayUTC, 14,40, h40,l40,t40)) return;
   if(!VisGetCandle(R, total, dayUTC, 14,45, h45,l45,t45)) return;

   // ── Calcular rango y SL — réplica exacta de la lógica del EA ──
   double rH    = MathMax(h35, MathMax(h40, h45));
   double rL    = MathMin(l35, MathMin(l40, l45));
   // CORREGIDO v8.1: igual que slDistance en trading — rango completo de las 3 velas
   double slD   = rH - rL;
   double slPts = slD / _Point;

   // Tag único del día
   MqlDateTime dt; TimeToStruct(dayUTC, dt);
   string tag = StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);

   datetime tRangeEnd = t45 + 300;  // fin de la vela 14:45 (5 min = 300 s)

   // ── Zona del rango ─────────────────────────────────────────────

   // Rectángulo de fondo sombreado
   string nBox = VIS_PFX + "BOX_" + tag;
   if(ObjectFind(0, nBox) < 0)
      ObjectCreate(0, nBox, OBJ_RECTANGLE, 0, t35, rH, tRangeEnd, rL);
   ObjectSetInteger(0, nBox, OBJPROP_COLOR,      VIS_ColRange);
   ObjectSetInteger(0, nBox, OBJPROP_BGCOLOR,    VIS_ColRange);
   ObjectSetInteger(0, nBox, OBJPROP_FILL,       true);
   ObjectSetInteger(0, nBox, OBJPROP_BACK,       true);
   ObjectSetInteger(0, nBox, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nBox, OBJPROP_HIDDEN,     true);

   // Borde superior (RANGE HIGH)
   VisSegment(VIS_PFX+"RH_"+tag,
              t35, tRangeEnd, rH, rH,
              VIS_ColRangeBorder, STYLE_SOLID, 2, true);

   // Borde inferior (RANGE LOW)
   VisSegment(VIS_PFX+"RL_"+tag,
              t35, tRangeEnd, rL, rL,
              VIS_ColRangeBorder, STYLE_SOLID, 2, true);

   // Etiquetas del rango
   VisText(VIS_PFX+"LRHI_"+tag,
           t35, rH, "  RANGE HIGH",
           VIS_ColRangeBorder, 8, ANCHOR_LEFT_LOWER, false);
   VisText(VIS_PFX+"LRLO_"+tag,
           t35, rL, "  RANGE LOW",
           VIS_ColRangeBorder, 8, ANCHOR_LEFT_UPPER, false);

   // ── Buscar ruptura en ventana 14:50–15:15 UTC ──────────────────
   double   eEntry=0, eSL=0, eTp1=0, eTp2=0, eTp3=0, eBE=0;
   string   eDir="";
   datetime eBreak=0;
   bool     broke=false;

   for(int i = total - 1; i >= 0; i--)   // orden cronológico
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      datetime barDay = StringToTime(
         StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
      if(barDay != dayUTC) continue;

      bool inWin = (u.hour == 14 && u.min >= 50) ||
                   (u.hour == 15 && u.min <= 15);
      if(!inWin) continue;

      if(R[i].high > rH)   // BUY breakout detectado en esta vela
      {
         // Con ConfirmOnClose la entrada real ocurre al ABRIR la vela SIGUIENTE
         // → eEntry = Open de la vela i+1 (si existe), sino Open de la vela de ruptura
         double entryPx = (i + 1 < total) ? R[i+1].open : R[i].close;
         eEntry  = entryPx;
         eDir    = "buy";
         eBreak  = R[i].time;
         eSL     = NormalizeDouble(eEntry - slD,                          _Digits);
         eTp1    = NormalizeDouble(eEntry + slD * TP1_RR,                 _Digits);
         eTp2    = NormalizeDouble(eEntry + slD * TP2_RR,                 _Digits);
         eTp3    = NormalizeDouble(eEntry + slD * TP3_RR,                 _Digits);
         eBE     = NormalizeDouble(eEntry + slD * (BE_BufferPct / 100.0), _Digits);
         broke   = true;
         break;
      }
      if(R[i].low < rL)    // SELL breakout detectado en esta vela
      {
         double entryPx = (i + 1 < total) ? R[i+1].open : R[i].close;
         eEntry  = entryPx;
         eDir    = "sell";
         eBreak  = R[i].time;
         eSL     = NormalizeDouble(eEntry + slD,                          _Digits);
         eTp1    = NormalizeDouble(eEntry - slD * TP1_RR,                 _Digits);
         eTp2    = NormalizeDouble(eEntry - slD * TP2_RR,                 _Digits);
         eTp3    = NormalizeDouble(eEntry - slD * TP3_RR,                 _Digits);
         eBE     = NormalizeDouble(eEntry - slD * (BE_BufferPct / 100.0), _Digits);
         broke   = true;
         break;
      }
   }

   // ── Niveles de la operación ────────────────────────────────────
   if(broke)
   {
      bool     isBuy = (eDir == "buy");
      datetime tEnd  = eBreak + (datetime)(VIS_ExtendBars * PeriodSeconds(PERIOD_M5));

      // Flecha horizontal → posicionada a la izquierda del rango, al nivel de la ruptura
      // Código 232 = flecha derecha (→) en la fuente Wingdings de MT5
      double arrPx  = isBuy ? rH : rL;   // al nivel exacto del rango roto
      datetime tArr = t35 - (datetime)(2 * PeriodSeconds(PERIOD_M5)); // 2 velas antes del rango
      string nArr   = VIS_PFX + "ARR_" + tag;
      if(ObjectFind(0, nArr) < 0)
         ObjectCreate(0, nArr, OBJ_ARROW, 0, tArr, arrPx);
      ObjectSetDouble(0,  nArr, OBJPROP_PRICE,      arrPx);
      ObjectSetInteger(0, nArr, OBJPROP_TIME,       tArr, 0);
      ObjectSetInteger(0, nArr, OBJPROP_ARROWCODE,  232);   // → flecha derecha horizontal
      ObjectSetInteger(0, nArr, OBJPROP_COLOR,      isBuy ? VIS_ColTP3 : VIS_ColSL);
      ObjectSetInteger(0, nArr, OBJPROP_WIDTH,      3);
      ObjectSetInteger(0, nArr, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nArr, OBJPROP_HIDDEN,     true);

      // MEJORA: línea vertical de entrada — color más visible
      string nVL = VIS_PFX + "VL_" + tag;
      if(ObjectFind(0, nVL) < 0)
         ObjectCreate(0, nVL, OBJ_VLINE, 0, eBreak, 0);
      ObjectSetInteger(0, nVL, OBJPROP_COLOR,      isBuy ? C'40,140,80' : C'180,50,70');
      ObjectSetInteger(0, nVL, OBJPROP_STYLE,      STYLE_DOT);
      ObjectSetInteger(0, nVL, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, nVL, OBJPROP_BACK,       true);
      ObjectSetInteger(0, nVL, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nVL, OBJPROP_HIDDEN,     true);

      // Niveles — SL, ENTRY, BE, TP1, TP2, TP3
      VisLevel(VIS_PFX+"SL_" +tag, eBreak, tEnd, eSL,    VIS_ColSL,    STYLE_DASH,  2, "SL");
      VisLevel(VIS_PFX+"EN_" +tag, eBreak, tEnd, eEntry, VIS_ColEntry, STYLE_SOLID, 1, "ENTRY");
      if(VIS_ShowBE)
         VisLevel(VIS_PFX+"BE_"+tag, eBreak, tEnd, eBE, VIS_ColBE, STYLE_DOT, 1, "BE");
      VisLevel(VIS_PFX+"TP1_"+tag, eBreak, tEnd, eTp1, VIS_ColTP1, STYLE_SOLID, 1, "TP1");
      VisLevel(VIS_PFX+"TP2_"+tag, eBreak, tEnd, eTp2, VIS_ColTP2, STYLE_SOLID, 1, "TP2");
      VisLevel(VIS_PFX+"TP3_"+tag, eBreak, tEnd, eTp3, VIS_ColTP3, STYLE_SOLID, 3, "TP3");

      // MEJORA: MARCADOR DE SESIÓN — línea vertical a las 17:00 UTC
      datetime tClose17 = StringToTime(StringFormat("%04d.%02d.%02d %02d:%02d:00",
                          dt.year, dt.mon, dt.day,
                          SessionCloseHour + ServerOffsetHours, SessionCloseMin));
      string nSC = VIS_PFX + "SC_" + tag;
      if(ObjectFind(0, nSC) < 0)
         ObjectCreate(0, nSC, OBJ_VLINE, 0, tClose17, 0);
      ObjectSetInteger(0, nSC, OBJPROP_COLOR,      C'100,100,140');
      ObjectSetInteger(0, nSC, OBJPROP_STYLE,      STYLE_DASH);
      ObjectSetInteger(0, nSC, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, nSC, OBJPROP_BACK,       true);
      ObjectSetInteger(0, nSC, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nSC, OBJPROP_HIDDEN,     true);
      // Label del cierre de sesión
      VisText(VIS_PFX+"SCL_"+tag, tClose17, eTp3,
              StringFormat(" %d:%02d UTC", SessionCloseHour, SessionCloseMin),
              C'100,100,160', 7, ANCHOR_LEFT_UPPER, false);
   }
   else
   {
      // MEJORA: DÍA SIN RUPTURA — texto indicativo en la zona del rango
      VisText(VIS_PFX+"NOBRK_"+tag, tRangeEnd + 300, (rH+rL)/2.0,
              "  sin ruptura",
              C'80,100,130', 7, ANCHOR_LEFT, false);
   }

   // Panel de información del día — se actualiza vía VisUpdatePanel() en OnTick
   // NO se dibuja aquí para evitar solapamiento — ver VisUpdatePanel()
}

//===================================================================
//  REDIBUJAR TODO EL HISTÓRICO
//===================================================================

void VisRedrawAll()
{
   if(!VIS_Enable) return;
   VisPurgeAll();

   MqlRates R[];
   ArraySetAsSeries(R, true);
   int copied = CopyRates(_Symbol, PERIOD_M5, 0, VIS_LookbackDays * 120, R);
   if(copied <= 0) return;

   // Recopilar días únicos que tengan la vela 14:35 UTC
   datetime days[];
   int      nDays = 0;
   for(int i = copied - 1; i >= 0; i--)
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      if(u.hour != 14 || u.min != 35) continue;
      datetime d = StringToTime(
         StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
      bool found = false;
      for(int k = 0; k < nDays; k++) if(days[k] == d) { found = true; break; }
      if(found) continue;
      ArrayResize(days, nDays + 1);
      days[nDays++] = d;
   }

   for(int i = 0; i < nDays; i++)
      VisDrawDay(R, copied, days[i]);

   VisDrawMottoPanel();
   VisUpdatePanel("", 0, 0, false, false, "");
   ChartRedraw();
}

//===================================================================
//  PANEL FIJO — esquina superior derecha (sin solapamiento)
//  Reemplaza todos los labels flotantes que antes se solapaban
//===================================================================

void VisUpdatePanel(string direction, double slPts, double netPL,
                    bool hasTrade, bool isFiltered, string filterReason)
{
   if(!VIS_Enable || !VIS_ShowLabel) return;

   // ── Construir las líneas del panel ───────────────────────────
   string sym   = _Symbol;
   string dayStr = "";
   MqlDateTime u; TimeToStruct(TimeCurrent() - (long)ServerOffsetHours*3600, u);
   string days[7] = {"Dom","Lun","Mar","Mié","Jue","Vie","Sáb"};
   dayStr = days[u.day_of_week];
   string dateStr = StringFormat("%02d/%02d/%04d", u.day, u.mon, u.year);

   string line1, line2, line3, line4, line5;
   color  panelColor;

   if(isFiltered)
   {
      line1      = "BreakoutNY v9.1  |  " + sym;
      line2      = dayStr + " " + dateStr;
      line3      = "★  " + filterReason;
      line4      = "Riesgo: $" + DoubleToString(RiskAmountUSD, 0) + "/trade";
      line5      = "";
      panelColor = C'100,100,140';
   }
   else if(!hasTrade && direction == "")
   {
      line1 = "BreakoutNY v9.1  |  " + sym;
      line2 = dayStr + " " + dateStr + "  |  Esperando 14:50 UTC";
      line3 = "Riesgo $" + DoubleToString(RiskAmountUSD,0) +
              "  |  SL " + DoubleToString(MinSL_Points,0) +
              "–" + DoubleToString(MaxSL_Points,0) + " pts";
      line4 = "TP1 1:" + DoubleToString(TP1_RR,0) +
              "  TP2 1:" + DoubleToString(TP2_RR,0) +
              "  TP3 1:" + DoubleToString(TP3_RR,0);
      line5 = "";
      panelColor = C'100,130,180';
   }
   else
   {
      bool isBuy = (direction == "buy");
      string dirArrow = isBuy ? "▲ BUY" : "▼ SELL";
      string plStr = (netPL >= 0)
         ? "+ $" + DoubleToString(netPL, 0)
         : "- $" + DoubleToString(MathAbs(netPL), 0);
      line1 = "BreakoutNY v9.1  |  " + sym + "  |  " + dayStr;
      line2 = dirArrow + "  |  SL " + DoubleToString(slPts, 1) + " pts" +
              "  |  TP3 " + DoubleToString(slPts * TP3_RR, 1) + " pts";
      line3 = "Riesgo $" + DoubleToString(RiskAmountUSD, 0) +
              "  |  BE " + DoubleToString(BE_BufferPct, 0) + "%";
      line4 = hasTrade ? ("P/L flotante:  " + plStr) : "Sin posición abierta";
      line5 = "";
      panelColor = isBuy ? VIS_ColTP3 : VIS_ColSL;
   }

   // ── Crear / actualizar los OBJ_LABEL del panel ────────────────
   string pnames[5] = {"PNL1","PNL2","PNL3","PNL4","PNL5"};
   string ptexts[5]; ptexts[0]=line1; ptexts[1]=line2;
   ptexts[2]=line3;  ptexts[3]=line4; ptexts[4]=line5;
   int    pyoffs[5] = {15, 30, 45, 60, 75};   // offsets verticales en píxeles
   int    pfonts[5] = {9,  9,  8,  9,   8};

   for(int i = 0; i < 5; i++)
   {
      if(ptexts[i] == "") { ObjectDelete(0, VIS_PFX+pnames[i]); continue; }
      string nm = VIS_PFX + pnames[i];
      if(ObjectFind(0, nm) < 0)
         ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, 12);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, pyoffs[i]);
      ObjectSetString(0,  nm, OBJPROP_TEXT,      ptexts[i]);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,     (i==0) ? C'195,208,230' : panelColor);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,  pfonts[i]);
      ObjectSetString(0,  nm, OBJPROP_FONT,      "Consolas");
      ObjectSetInteger(0, nm, OBJPROP_ANCHOR,    ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN,    false);
      ObjectSetInteger(0, nm, OBJPROP_BACK,      false);
   }
}

//===================================================================
//  PANEL INFERIOR — frase de la estrategia + identidad
//===================================================================

void VisDrawMottoPanel()
{
   if(!VIS_Enable) return;

   // Línea 1: frase
   string nm1 = VIS_PFX + "MOTTO1";
   if(ObjectFind(0, nm1) < 0) ObjectCreate(0, nm1, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm1, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nm1, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, nm1, OBJPROP_YDISTANCE, 38);
   ObjectSetString(0,  nm1, OBJPROP_TEXT,
      "\"El filtro ATR no te protege de las pérdidas — te protege de las pérdidas que no merecen ocurrir.\"");
   ObjectSetInteger(0, nm1, OBJPROP_COLOR,     C'80,100,140');
   ObjectSetInteger(0, nm1, OBJPROP_FONTSIZE,  8);
   ObjectSetString(0,  nm1, OBJPROP_FONT,      "Consolas");
   ObjectSetInteger(0, nm1, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm1, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, nm1, OBJPROP_BACK,      false);

   // Línea 2: segunda parte de la frase
   string nm2 = VIS_PFX + "MOTTO2";
   if(ObjectFind(0, nm2) < 0) ObjectCreate(0, nm2, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm2, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nm2, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, nm2, OBJPROP_YDISTANCE, 24);
   ObjectSetString(0,  nm2, OBJPROP_TEXT,
      "\"Las que quedan son el precio de admisión.\"");
   ObjectSetInteger(0, nm2, OBJPROP_COLOR,     C'80,100,140');
   ObjectSetInteger(0, nm2, OBJPROP_FONTSIZE,  8);
   ObjectSetString(0,  nm2, OBJPROP_FONT,      "Consolas");
   ObjectSetInteger(0, nm2, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm2, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, nm2, OBJPROP_BACK,      false);

   // Línea 3: identidad del EA
   string nm3 = VIS_PFX + "MOTTO3";
   if(ObjectFind(0, nm3) < 0) ObjectCreate(0, nm3, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm3, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nm3, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, nm3, OBJPROP_YDISTANCE, 10);
   ObjectSetString(0,  nm3, OBJPROP_TEXT,
      StringFormat("BreakoutNY v9.1  ·  NAS100 FundingPips  ·  Magic %d  ·  Jose Yanez  ·  PF 1.874  ·  MaxDD 5.46%%",
                   (int)MagicNumber));
   ObjectSetInteger(0, nm3, OBJPROP_COLOR,     C'55,75,110');
   ObjectSetInteger(0, nm3, OBJPROP_FONTSIZE,  7);
   ObjectSetString(0,  nm3, OBJPROP_FONT,      "Consolas");
   ObjectSetInteger(0, nm3, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm3, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, nm3, OBJPROP_BACK,      false);

   ChartRedraw();
}

//===================================================================
//  REDIBUJAR SOLO EL DÍA ACTUAL
//===================================================================

void VisRedrawToday()
{
   if(!VIS_Enable) return;
   MqlDateTime u;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, u);
   datetime dayUTC = StringToTime(
      StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
   VisDeleteDay(vis_dayTag);

   MqlRates R[];
   ArraySetAsSeries(R, true);
   int copied = CopyRates(_Symbol, PERIOD_M5, 0, 200, R);
   if(copied > 0) VisDrawDay(R, copied, dayUTC);
   ChartRedraw();
}

//===================================================================
//  ██████╗  EVENTOS MT5
//===================================================================

int OnInit()
{
   // Validaciones de parámetros
   if(TP1_RR <= 0 || TP2_RR <= TP1_RR || TP3_RR <= TP2_RR)
   {
      Alert("ERROR: TP1_RR < TP2_RR < TP3_RR deben ser crecientes y positivos.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(TP1_ClosePct < 0 || TP1_ClosePct > 60 || TP2_ClosePct < 0 || TP2_ClosePct > 60)
   {
      Alert("ERROR: TP1_ClosePct y TP2_ClosePct deben estar entre 0 y 60.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(TP1_ClosePct + TP2_ClosePct >= 100)
   {
      Alert("ERROR: TP1_ClosePct + TP2_ClosePct debe ser < 100.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(BE_BufferPct < 0 || BE_BufferPct > 99)
   {
      Alert("ERROR: BE_BufferPct debe estar entre 0 y 99.");
      return INIT_PARAMETERS_INCORRECT;
   }

   trade.SetExpertMagicNumber(MagicNumber);
   InitCSV();

   //--- DIAGNÓSTICO DEL SÍMBOLO (imprime specs del broker al arrancar)
   double _tv  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double _ts  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double _cs  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double _pt  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double _mn  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double _mx  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   string _lotMethod = (_tv > 0 && _ts > 0) ? "ESTANDAR (TickValue/TickSize)" : "FALLBACK (ContractSize x Point)";
   double _vpp = (_tv > 0 && _ts > 0) ? _tv/_ts : _cs*_pt;

   Print("=== BreakoutNY EA v8.0 FundingPips ===");
   Print("--- SPECS DEL SIMBOLO: ", _Symbol, " ---");
   Print("  ContractSize   : ", _cs);
   Print("  TickSize       : ", _ts);
   Print("  TickValue      : ", _tv);
   Print("  Point          : ", _pt);
   Print("  LotMin/Max     : ", _mn, " / ", _mx);
   Print("  Metodo lotaje  : ", _lotMethod);
   Print("  ValorPorPunto  : $", DoubleToString(_vpp,4), "/punto/lot");
   double _ls   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double _mn2  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double _mx2  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   Print("  Modo lotaje    : DINAMICO | vpp=$", DoubleToString(_vpp,2), "/pt/lot");
   int _slTests[4] = {35, 50, 65, 80};
   for(int _ti=0; _ti<4; _ti++)
   {
      double _slT   = _slTests[_ti];
      double _lrT   = RiskAmountUSD / (_slT * _vpp);
      double _lnT   = MathMax(_mn2, MathMin(_mx2, MathFloor(_lrT/_ls)*_ls));
      double _riskT = _slT * _vpp * _lnT;
      double _tp1T  = _slT * TP1_RR * _vpp * _lnT;
      Print("  TEST SL=", (int)_slT, "pts: ", DoubleToString(_lnT,2),
            " lots | Risk=$", DoubleToString(_riskT,0),
            " | TP1=$", DoubleToString(_tp1T,0));
   }
   Print("--- FIN SPECS ---");
   Print("Offset UTC     : ", ServerOffsetHours, "h");
   Print("Ventana        : 14:50 – 15:", StringFormat("%02d", EntryWindowEnd_Min), " UTC");
   Print("Cierre sesión  : ", SessionCloseHour, ":", StringFormat("%02d", SessionCloseMin),
         " UTC", (SessionCloseHour==17 && SessionCloseMin==0) ? " (default)" : " (extendido)");
   Print("Riesgo         : $", RiskAmountUSD);
   Print("Objetivos      : TP1=1:", TP1_RR, "  TP2=1:", TP2_RR, "  TP3=1:", TP3_RR);
   Print("Parciales      : ", EnablePartials ? "ACTIVOS" : "DESACTIVADOS");
   if(EnablePartials)
   {
      Print("  TP1 cierra : ", TP1_ClosePct, "%  +  BE buffer ", BE_BufferPct, "%");
      Print("  TP2 cierra : ", TP2_ClosePct, "%  +  SL → TP1");
      Print("  Remanente  : ", 100 - TP1_ClosePct - TP2_ClosePct, "%  → TP3");
   }
   Print("Filtros día    : L=", FilterMonday?"SI":"NO",
         " M=", FilterTuesday?"SI":"NO",
         " X=", FilterWednesday?"SI":"NO",
         " J=", FilterThursday?"SI":"NO",
         " V=", FilterFriday?"SI":"NO");
   Print("MinSL/MaxSL    : ", MinSL_Points, " / ", MaxSL_Points, " pts");
   Print("ConfirmOnClose : ", ConfirmOnClose ? "SI — espera cierre de vela antes de entrar" : "NO — entrada inmediata al cruzar el rango");
   if(ATR_FilterEnable)
      Print("Filtro ATR     : ACTIVO | Período=", ATR_Period, " | Base=", ATR_BaselineDays, "días",
            " | Rango permitido=[baseline×", ATR_MinMultiplier, " – baseline×", ATR_MaxMultiplier, "]");
   else
      Print("Filtro ATR     : DESACTIVADO");
   Print("SL Calc        : rangeHigh - rangeLow (v8.1 corregido)");
   Print("Visual         : ", VIS_Enable ? "ACTIVO — Entry/SL/TP coinciden con la operación real" : "DESACTIVADO");

   // Dibujar histórico al arrancar
   VisRedrawAll();
   VisDrawMottoPanel();

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(csvHandle != INVALID_HANDLE) FileClose(csvHandle);

   double pf = (stat_grossLoss != 0)
               ? stat_grossProfit / MathAbs(stat_grossLoss) : 0;
   Print("=== RESUMEN v7 ===  Total:", stat_total,
         "  W:", stat_wins, "  L:", stat_losses,
         "  PF:", DoubleToString(pf, 3),
         "  Net: $", DoubleToString(stat_grossProfit + stat_grossLoss, 2));

   // Limpiar visual al quitar el EA
   VisPurgeAll();
   ChartRedraw();
}

//+------------------------------------------------------------------+
double OnTester()
{
   return (stat_grossLoss != 0)
          ? stat_grossProfit / MathAbs(stat_grossLoss) : 0;
}

//+------------------------------------------------------------------+
//| Procesa deals de salida para CSV y visual                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   ulong dealTicket = trans.deal;
   if(dealTicket <= 0 || !HistoryDealSelect(dealTicket)) return;
   if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;
   if((ulong)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != MagicNumber) return;

   double   profit     = HistoryDealGetDouble(dealTicket,  DEAL_PROFIT);
   double   closePrice = HistoryDealGetDouble(dealTicket,  DEAL_PRICE);
   datetime closeTime  = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
   string   comment    = HistoryDealGetString(dealTicket,  DEAL_COMMENT);

   bool isFullClose = !HasOpenPosition();
   if(!isFullClose) return;

   // Tipo de salida
   string exitType = "session";
   if(StringFind(comment,"tp") >= 0 || StringFind(comment,"TP") >= 0) exitType = "tp3";
   else if(StringFind(comment,"sl") >= 0 || StringFind(comment,"SL") >= 0)
      exitType       = phase1Done ? "sl_be" : "sl";
      log_BE_Activated = phase1Done;
      // Capturar SL real al cierre desde la posición
      if(PositionSelectByTicket(activeTicket))
         log_SL_Final = PositionGetDouble(POSITION_SL);
      else
         log_SL_Final = originalSL;

   // CSV
   stat_total++;
   WriteTradeRow(TimeToString(closeTime, TIME_DATE|TIME_MINUTES),
                 exitType, closePrice, profit,
                 dayFiltered, rangeFiltered);
   if(profit > 0) { stat_wins++;   stat_grossProfit += profit; }
   else           { stat_losses++; stat_grossLoss   += profit; }

   // Visual: marca de cierre
   if(VIS_Enable && vis_dayTag != "")
   {
      color  clrClose = (exitType=="tp3")   ? VIS_ColTP3  :
                        (exitType=="sl_be") ? VIS_ColBE   :
                        (exitType=="sl")    ? VIS_ColSL   : VIS_ColEntry;
      string lbl      = (exitType=="tp3")   ? "✓ TP3"     :
                        (exitType=="sl_be") ? "◐ SL@BE"   :
                        (exitType=="sl")    ? "✗ SL"      :
                        "○ " + IntegerToString(SessionCloseHour) + ":" +
                        StringFormat("%02d", SessionCloseMin);
      datetime tClose = closeTime;
      datetime tEnd   = tClose + (datetime)(6 * PeriodSeconds(PERIOD_M5));
      VisLevel(VIS_PFX+"CLS_"+vis_dayTag,
               tClose, tEnd, closePrice,
               clrClose, STYLE_SOLID, 2, lbl);
      ChartRedraw();
   }

   tradeDir = ""; entryPrice = 0; activeTicket = 0;
}

//+------------------------------------------------------------------+
//| CalcTrendFilter — Filtro TF (Experimental)                       |
//| Compara el cierre de sesión anterior (prevClose) con el midpoint  |
//| del rango NY para determinar el sesgo direccional del día.        |
//+------------------------------------------------------------------+
void CalcTrendFilter(double rangeMid)
{
   tf_midRange = rangeMid;

   MqlRates R[];
   int total = CopyRates(_Symbol, PERIOD_M5, 0, 600, R);
   if(total < 10) { tf_prevClose = 0; tf_allowedDir = "both"; return; }
   ArraySetAsSeries(R, true);

   MqlDateTime nowUtc;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, nowUtc);
   int todayY = nowUtc.year, todayMo = nowUtc.mon, todayD = nowUtc.day;

   double foundClose = 0;
   datetime foundTime = 0;
   for(int i = 0; i < total; i++)
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      if(u.year == todayY && u.mon == todayMo && u.day == todayD) continue;
      int barMin = u.hour * 60 + u.min;
      if(barMin <= 16 * 60 + 55) { foundClose = R[i].close; foundTime = R[i].time; break; }
   }

   if(foundClose <= 0) { tf_prevClose = 0; tf_allowedDir = "both";
      Print("TF: No se encontró prevClose. Filtro no aplicado."); return; }

   tf_prevClose  = foundClose;
   double diff   = rangeMid - tf_prevClose;

   if     (diff >  TF_Threshold_Pts) tf_allowedDir = "buy";
   else if(diff < -TF_Threshold_Pts) tf_allowedDir = "sell";
   else                               tf_allowedDir = TF_BlockNeutral ? "none" : "both";

   Print("TF: prevClose=", DoubleToString(tf_prevClose,_Digits),
         " mid=", DoubleToString(rangeMid,_Digits),
         " diff=", DoubleToString(diff,2), "pts → dir=", tf_allowedDir);
}

//+------------------------------------------------------------------+
//| OnTick — lógica principal de trading + actualización visual     |
//+------------------------------------------------------------------+
void OnTick()
{
   int utcH, utcM;
   GetCurrentUTC(utcH, utcM);

   // Calcular "hoy" según servidor para el reset diario
   MqlDateTime sdt; TimeToStruct(TimeCurrent(), sdt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",
                                 sdt.year, sdt.mon, sdt.day));

   //=== RESET DIARIO ================================================
   if(today != lastTradeDay)
   {
      DailyReset();
      lastTradeDay = today;
      vis_dayTag   = VisMakeDayTag();
      VisRedrawAll();
      VisDrawMottoPanel();
   }

   if(dayFiltered) return;

   //=== FILTRO: DÍA DE SEMANA =======================================
   if(!rangeCalculated && !dayFiltered && !tradeExecuted &&
      utcH == 14 && utcM >= 50)
   {
      if(!IsTradingDayAllowed())
      {
         dayFiltered = true; tradeExecuted = true;
         Print("DIA FILTRADO: ", WeekdayName(GetWeekdayUTC()));
         WriteFilteredRow("day");
         VisUpdatePanel("", 0, 0, false, true, "Día no operado");
         return;
      }
   }

   //=== PASO 1: CALCULAR RANGO (14:50 UTC) ==========================
   if(!rangeCalculated && !tradeExecuted && utcH == 14 && utcM >= 50)
   {
      double h35,l35, h40,l40, h45,l45;
      bool ok = GetCandleAtUTC(14,35,h35,l35) &&
                GetCandleAtUTC(14,40,h40,l40) &&
                GetCandleAtUTC(14,45,h45,l45);
      if(!ok) { Print("AVISO: Velas del rango no encontradas."); return; }

      rangeHigh  = MathMax(h35, MathMax(h40, h45));
      rangeLow   = MathMin(l35, MathMin(l40, l45));
      // CORREGIDO v8.1: SL = rango completo MAX(High) − MIN(Low) de las 3 velas
      // Antes usaba promedio de rangos de solo 2 velas → niveles visuales no coincidían con la operación real
      slDistance   = rangeHigh - rangeLow;
      double slPts     = slDistance / _Point;  // broker points
      double slPtsReal = slDistance;           // puntos REALES del índice

      // ── Filtro ATR (opcional) ────────────────────────────────────
      // Compara el ATR actual vs la línea base histórica para detectar
      // condiciones de volatilidad anormal (excesiva o insuficiente)
      if(ATR_FilterEnable)
      {
         int atrHandle = iATR(_Symbol, PERIOD_M5, ATR_Period);
         if(atrHandle != INVALID_HANDLE)
         {
            // ATR actual (última vela cerrada)
            double atrNow[1];
            CopyBuffer(atrHandle, 0, 1, 1, atrNow);
            double currentATR = atrNow[0] / _Point; // convertir a puntos reales

            // ATR baseline = media del ATR en los últimos ATR_BaselineDays días
            int barsBaseline = ATR_BaselineDays * 24 * 12; // días × horas × velas por hora en M5
            double atrBuf[];
            ArrayResize(atrBuf, barsBaseline);
            int copied = CopyBuffer(atrHandle, 0, 1, barsBaseline, atrBuf);
            IndicatorRelease(atrHandle);

            if(copied > 10)
            {
               double sum = 0;
               for(int ai = 0; ai < copied; ai++) sum += atrBuf[ai];
               double baselineATR = (sum / copied) / _Point;

               double atrMin = baselineATR * ATR_MinMultiplier;
               double atrMax = baselineATR * ATR_MaxMultiplier;

               if(currentATR < atrMin || currentATR > atrMax)
               {
                  rangeFiltered = true; tradeExecuted = true;
                  Print("ATR FILTRADO: ATR actual=", DoubleToString(currentATR,1),
                        "pts | Baseline=", DoubleToString(baselineATR,1),
                        "pts | Rango permitido=[", DoubleToString(atrMin,1),
                        " - ", DoubleToString(atrMax,1), "]");
                  WriteFilteredRow("atr");
                  VisUpdatePanel("", 0, 0, false, true, "ATR filtrado");
                  return;
               }
               else
                  Print("ATR OK: ", DoubleToString(currentATR,1),
                        "pts | Baseline=", DoubleToString(baselineATR,1),
                        "pts | Rango=[", DoubleToString(atrMin,1),
                        "-", DoubleToString(atrMax,1), "]");
            }
         }
      }

      // Filtro en puntos reales del índice — independiente del broker
      bool tooLarge = (MaxSL_Points > 0 && slPtsReal > MaxSL_Points);
      bool tooSmall = (MinSL_Points > 0 && slPtsReal < MinSL_Points);

      if(tooLarge || tooSmall)
      {
         rangeFiltered = true; tradeExecuted = true;
         log_SL_Pts    = slPtsReal;   // puntos reales
         log_Weekday   = WeekdayName(GetWeekdayUTC());
         Print("RANGO FILTRADO: ", DoubleToString(slPtsReal,2), " pts reales (", DoubleToString(slPts,1), " broker pts) | Filtro: ", MinSL_Points, "-", MaxSL_Points, " pts reales");
         WriteFilteredRow("range");
         VisUpdatePanel("", 0, 0, false, true, "Rango filtrado (" + DoubleToString(slPtsReal,1) + "pts)");
         return;
      }

      rangeCalculated = true;
      log_RangeHigh   = rangeHigh;
      log_RangeLow    = rangeLow;
      cachedLots = CalculateLotSize(slDistance);

      // ── Filtro TF (experimental, desactivado por defecto) ────────
      if(TF_Enable)
      {
         double rangeMid = (rangeHigh + rangeLow) / 2.0;
         CalcTrendFilter(rangeMid);
         if(tf_allowedDir == "none")
         {
            rangeFiltered = true; tradeExecuted = true;
            Print("TF ZONA NEUTRA: no se opera | mid=", DoubleToString(rangeMid,_Digits),
                  " prevClose=", DoubleToString(tf_prevClose,_Digits),
                  " threshold=±", TF_Threshold_Pts);
            WriteFilteredRow("tf");
            VisUpdatePanel("", 0, 0, false, true, "TF zona neutra");
            return;
         }
      }
      else tf_allowedDir = "both";

      Print("Rango OK: H=",rangeHigh," L=",rangeLow,
            " slReal=",DoubleToString(slDistance,2),"pts",
            " | ConfirmOnClose=",ConfirmOnClose ? "SI":"NO",
            " | TF=", TF_Enable ? tf_allowedDir : "OFF",
            " | Lots=",DoubleToString(cachedLots,2));

      VisRedrawToday();
   }

   //=== PASO 2: BUSCAR ENTRADA =======================================
   // Lógica de dos fases cuando ConfirmOnClose=true:
   //   FASE A: detectar el primer cruce del rango → registrar vela y dirección
   //   FASE B: en el tick de apertura de la vela SIGUIENTE → ejecutar entrada
   //
   // Con ConfirmOnClose=false: entra en el primer tick que cruza (original)
   //
   // ¿Por qué funciona?
   //   Los false breakouts de NDX100 son mechas intracandle: el precio cruza
   //   el rango dentro de la vela pero CIERRA de vuelta adentro.
   //   USTECHCash nunca llega a esos niveles → RoboForex no entra.
   //   Al esperar el cierre de la vela de ruptura, filtramos esas mechas.

   if(rangeCalculated && !tradeExecuted)
   {
      bool inWindow;
      if(EntryWindowEnd_Min >= 50)
         inWindow = (utcH == 14 && utcM >= 50 && utcM <= EntryWindowEnd_Min);
      else
         inWindow = (utcH == 14 && utcM >= 50) ||
                    (utcH == 15 && utcM <= EntryWindowEnd_Min);

      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // Obtener la vela M5 actual (para saber en qué barra estamos)
      datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);

      //----------------------------------------------------------------
      // FASE A — DETECCIÓN: primera vez que el precio cruza el rango
      //          Registrar la vela y la dirección. No entrar todavía.
      //----------------------------------------------------------------
      if(inWindow && !HasOpenPosition() && !breakoutPending)
      {
         if(ask > rangeHigh)   // Candidato BUY
         {
            if(TF_Enable && tf_allowedDir == "sell")
            {
               Print("TF: BUY bloqueado (dir=SELL) | prevClose=",DoubleToString(tf_prevClose,_Digits));
               tradeExecuted = true; WriteFilteredRow("tf");
               VisUpdatePanel("", 0, 0, false, true, "TF: dir=SELL (BUY bloqueado)");
               return;
            }
            if(!ConfirmOnClose)
            {
               // Modo original: entrar inmediatamente
               double lots = cachedLots;
               if(lots <= 0) { Print("ERROR: Lotaje 0."); return; }
               double sl = NormalizeDouble(ask - slDistance, _Digits);
               double tp = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
               if(trade.Buy(lots, _Symbol, ask, sl, tp, "BreakoutNY BUY"))
               {
                  tradeExecuted = true;
                  entryPrice = ask;  originalSL = sl;
                  originalLots = lots; tradeDir = "buy";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(ask + slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(ask + slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(ask + slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime  = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts    = slDistance;    log_ConfirmUsed = false;
                  Print(">>> BUY (inmediato) Entry=",ask," SL=",sl,
                        " TP1=",tp1Price," TP3=",tp3Price," Lots=",lots);
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
            else
            {
               // Modo confirmación: registrar y esperar cierre de vela
               breakoutPending = true;
               pendingDir      = "buy";
               pendingBarTime  = currentBarTime;
               Print(">>> BUY pendiente confirmación | vela=",
                     TimeToString(currentBarTime, TIME_DATE|TIME_MINUTES),
                     " | ask=",ask," rangeHigh=",rangeHigh);
            }
         }
         else if(bid < rangeLow)   // Candidato SELL
         {
            if(TF_Enable && tf_allowedDir == "buy")
            {
               Print("TF: SELL bloqueado (dir=BUY) | prevClose=",DoubleToString(tf_prevClose,_Digits));
               tradeExecuted = true; WriteFilteredRow("tf");
               VisUpdatePanel("", 0, 0, false, true, "TF: dir=BUY (SELL bloqueado)");
               return;
            }
            if(!ConfirmOnClose)
            {
               // Modo original: entrar inmediatamente
               double lots = cachedLots;
               if(lots <= 0) { Print("ERROR: Lotaje 0."); return; }
               double sl = NormalizeDouble(bid + slDistance, _Digits);
               double tp = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
               if(trade.Sell(lots, _Symbol, bid, sl, tp, "BreakoutNY SELL"))
               {
                  tradeExecuted = true;
                  entryPrice = bid;  originalSL = sl;
                  originalLots = lots; tradeDir = "sell";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(bid - slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(bid - slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(bid - slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime  = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts    = slDistance;    log_ConfirmUsed = false;
                  Print(">>> SELL (inmediato) Entry=",bid," SL=",sl,
                        " TP1=",tp1Price," TP3=",tp3Price," Lots=",lots);
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
            else
            {
               // Modo confirmación: registrar y esperar cierre de vela
               breakoutPending = true;
               pendingDir      = "sell";
               pendingBarTime  = currentBarTime;
               Print(">>> SELL pendiente confirmación | vela=",
                     TimeToString(currentBarTime, TIME_DATE|TIME_MINUTES),
                     " | bid=",bid," rangeLow=",rangeLow);
            }
         }
      }

      //----------------------------------------------------------------
      // FASE B — CONFIRMACIÓN: si hay breakout pendiente y la barra cambió
      //          → la vela de ruptura ya cerró → confirmar la entrada
      //----------------------------------------------------------------
      if(breakoutPending && !tradeExecuted && !HasOpenPosition() &&
         currentBarTime > pendingBarTime)
      {
         // Verificar que el precio sigue al otro lado del rango al abrir la nueva vela
         // Si el precio ya revirtió dentro del rango → señal falsa, cancelar
         bool stillValid = false;
         if(pendingDir == "buy"  && ask > rangeHigh) stillValid = true;
         if(pendingDir == "sell" && bid < rangeLow)  stillValid = true;

         if(!stillValid)
         {
            // La vela de ruptura cerró DENTRO del rango → false breakout confirmado
            // Esto es exactamente lo que pasa en los 51 trades falsos de NDX100
            Print(">>> Breakout CANCELADO: la vela cerró de vuelta al rango. "
                  "Dir=",pendingDir," ask=",ask," bid=",bid,
                  " rangeHigh=",rangeHigh," rangeLow=",rangeLow);
            breakoutPending = false;
            pendingDir      = "";
            pendingBarTime  = 0;
            // No marcamos tradeExecuted → seguimos buscando otro breakout en la ventana
         }
         else
         {
            // Breakout confirmado por cierre de vela → ejecutar entrada
            double lots = cachedLots;
            if(lots <= 0) { Print("ERROR: Lotaje 0."); return; }

            if(pendingDir == "buy")
            {
               double sl = NormalizeDouble(ask - slDistance, _Digits);
               double tp = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
               if(trade.Buy(lots, _Symbol, ask, sl, tp, "BreakoutNY BUY"))
               {
                  tradeExecuted    = true;
                  breakoutPending  = false;
                  entryPrice = ask; originalSL = sl;
                  originalLots = lots; tradeDir = "buy";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(ask + slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(ask + slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(ask + slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime    = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts      = slDistance;    log_ConfirmUsed = true;
                  Print(">>> BUY CONFIRMADO Entry=",ask," SL=",sl,
                        " TP1=",tp1Price," TP3=",tp3Price," Lots=",lots,
                        " (esperó cierre de vela ",
                        TimeToString(pendingBarTime,TIME_DATE|TIME_MINUTES),")");
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
            else // sell
            {
               double sl = NormalizeDouble(bid + slDistance, _Digits);
               double tp = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
               if(trade.Sell(lots, _Symbol, bid, sl, tp, "BreakoutNY SELL"))
               {
                  tradeExecuted    = true;
                  breakoutPending  = false;
                  entryPrice = bid; originalSL = sl;
                  originalLots = lots; tradeDir = "sell";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(bid - slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(bid - slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(bid - slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime    = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts      = slDistance;    log_ConfirmUsed = true;
                  Print(">>> SELL CONFIRMADO Entry=",bid," SL=",sl,
                        " TP1=",tp1Price," TP3=",tp3Price," Lots=",lots,
                        " (esperó cierre de vela ",
                        TimeToString(pendingBarTime,TIME_DATE|TIME_MINUTES),")");
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
         }
      }

      // Ventana cerrada sin entrada ejecutada
      if(!inWindow && !HasOpenPosition() && !breakoutPending && !tradeExecuted)
      {
         tradeExecuted = true;
         Print("Ventana cerrada sin breakout.");
         VisRedrawToday();
      }
      // Ventana cerrada con breakout pendiente → ya no hay tiempo de confirmar
      if(!inWindow && breakoutPending && !tradeExecuted)
      {
         Print("Ventana cerrada con breakout pendiente sin confirmar. Dir=",pendingDir);
         breakoutPending = false;
         tradeExecuted   = true;
         VisRedrawToday();
      }
   }

   //=== PASO 3: GESTIÓN DE PARCIALES Y BE ===========================
   if(tradeExecuted && HasOpenPosition() && EnablePartials && entryPrice > 0)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- FASE 1: precio toca TP1 → cierre parcial + activar BE ----
      if(!phase1Done)
      {
         bool tp1Hit = (tradeDir=="buy"  && bid >= tp1Price) ||
                       (tradeDir=="sell" && ask <= tp1Price);
         if(tp1Hit)
         {
            phase1Done    = true;
            log_Phase1Hit = true;

            double lotsToClose = 0;
            if(TP1_ClosePct > 0)
            {
               lotsToClose = NormalizeLots(originalLots * TP1_ClosePct / 100.0);
               if(lotsToClose >= GetPositionLots()) lotsToClose = 0;
            }
            if(lotsToClose > 0)
            {
               ulong tk = GetPositionTicket();
               if(ClosePartial(tk, lotsToClose))
                  Print("FASE 1: Cerrado ", lotsToClose, " lotes en TP1");
               else
                  Print("FASE 1: Error cierre parcial: ", GetLastError());
            }
            if(ModifySL(bePrice))
            {
               Print("FASE 1: BE activado → SL=", bePrice);
               // Visual: mover línea SL al precio de BE
               if(VIS_Enable && vis_dayTag != "")
                  VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, bePrice);
            }
            else
               Print("FASE 1: Error al activar BE: ", GetLastError());
         }
      }

      //--- FASE 2: precio toca TP2 → cierre parcial + SL a TP1 -----
      if(phase1Done && !phase2Done)
      {
         bool tp2Hit = (tradeDir=="buy"  && bid >= tp2Price) ||
                       (tradeDir=="sell" && ask <= tp2Price);
         if(tp2Hit)
         {
            phase2Done    = true;
            log_Phase2Hit = true;

            double lotsToClose = 0;
            if(TP2_ClosePct > 0)
            {
               lotsToClose = NormalizeLots(originalLots * TP2_ClosePct / 100.0);
               double curLots = GetPositionLots();
               double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
               if(curLots - lotsToClose < minLot)
                  lotsToClose = NormalizeLots(curLots - minLot);
               if(lotsToClose < minLot) lotsToClose = 0;
            }
            if(lotsToClose > 0)
            {
               ulong tk = GetPositionTicket();
               if(ClosePartial(tk, lotsToClose))
                  Print("FASE 2: Cerrado ", lotsToClose, " lotes en TP2");
               else
                  Print("FASE 2: Error cierre parcial: ", GetLastError());
            }
            if(ModifySL(tp1Price))
            {
               Print("FASE 2: SL → TP1=", tp1Price, " (remanente libre de riesgo)");
               // Visual: mover línea SL al precio de TP1
               if(VIS_Enable && vis_dayTag != "")
                  VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, tp1Price);
            }
            else
               Print("FASE 2: Error al mover SL a TP1: ", GetLastError());
         }
      }
   }

   //=== PASO 4: CIERRE AL FINAL DE SESIÓN ===========================
   // Configurable: default 17:00 UTC, extendido 17:30 UTC
   bool pastCloseTime;
   if(SessionCloseMin == 0)
      pastCloseTime = (utcH >= SessionCloseHour);
   else
      pastCloseTime = (utcH > SessionCloseHour) ||
                      (utcH == SessionCloseHour && utcM >= SessionCloseMin);

   if(pastCloseTime && HasOpenPosition())
   {
      Print("Fin de sesión (", SessionCloseHour, ":",
            StringFormat("%02d", SessionCloseMin), " UTC) — cerrando posición.");
      CloseAll();
   }

   //=== ACTUALIZACIÓN DEL PANEL VISUAL EN CADA TICK =================
   if(VIS_Enable && VIS_ShowLabel)
   {
      double floatPL = 0;
      if(HasOpenPosition() && activeTicket > 0 && PositionSelectByTicket(activeTicket))
         floatPL = PositionGetDouble(POSITION_PROFIT);
      VisUpdatePanel(tradeDir, slDistance, floatPL,
                     HasOpenPosition(), false, "");
   }
}
//+------------------------------------------------------------------+
