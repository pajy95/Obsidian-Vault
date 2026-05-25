//+------------------------------------------------------------------+
//|       BreakoutNY_v9_FundingPips_XAUUSD.mq5                       |
//|   BreakoutNY v9.0 — FundingPips — XAUUSD (Gold Spot 100oz)       |
//|                                                                   |
//|   VERSIÓN V3 — Configuración óptima validada por análisis        |
//|   estadístico de 362 días (Oct 2024 – Mar 2026)                  |
//|                                                                   |
//|   CAMBIOS vs v8.02 (V2):                                         |
//|   [V3-1] RiskAmountUSD default: 75 (era 100) → MaxDD < 8%       |
//|   [V3-2] BE_BufferPct default: 100 (era 20)  → PF 1.46→2.05    |
//|   [V3-3] MaxSL_Points default: 15 (era 12)   → captura P75      |
//|   [V3-4] FilterTuesday default: false (filtra martes)            |
//|   [V3-5] FilterFriday default: false (filtra viernes)            |
//|   [V3-6] NUEVO: EntryMaxCandle=2 → solo entrar en velas 1-2     |
//|           Vela 4 tiene SL=64.7%, TP3=0% — eliminar              |
//|   [V3-7] EnablePartials default: false (parciales PF=1.19<2.05) |
//|   [V3-8] CSV enriquecido: BreakoutCandle + RangeSize             |
//+------------------------------------------------------------------+
//
//  CONTRACT SPECS (FundingPips XAUUSD):
//    ContractSize  : 100 oz
//    TickSize      : 0.01
//    TickValue     : $1.00 / lot / tick  (100 oz × $0.01)
//    _Point        : 0.01
//    VolumeMin     : 0.01   VolumeMax: 5.00   VolumeStep: 0.01
//    ServerOffset  : UTC+2  (FundingPips standard)
//
//  LOT CALC (ejemplo con mediana $9.07, risk=$75):
//    lotsRaw  = 75 / (9.07 × 100) = 0.082 lots
//    Riesgo   = 0.08 × 9.07 × 100 = $72.56 ✓
//
//  BUGS HEREDADOS — YA CORREGIDOS (NO reintroducir):
//    [1] slDistance comparado directo vs MinSL/MaxSL (no × _Point)
//    [2] valuePerPoint = TickValue/TickSize (era inestable en backtester)
//    [3] UseFixedLot eliminado — siempre dinámico
//    [4] Sin range-based for loops (incompatible MQL5)
//    [5] Margen: OrderCalcMargin + ACCOUNT_MARGIN_FREE
//    [6] cachedLots calculado UNA VEZ al detectar rango
//    [7] ACCOUNT_MARGIN_FREE (no deprecated ACCOUNT_FREEMARGIN)
//    [8] FilterXxx: true=OPERA, false=SALTA
//    [9] VPP via OrderCalcProfit (TickValue/TickSize inestable CFD XCCY)
//
//  MÉTRICAS ESTADÍSTICAS (Oct2024–Mar2026, n=362 días):
//    Todos días PF > 1.4 con TP3 objetivo
//    TP3 alcanzado: 9.5% (driver real: SessionEnd captura 1-2×rango)
//    TP3 vs TP1: Net +$15,016 vs +$5,677 (2.6× mejor)
//    Parciales 50/50: PF=1.19 (PEOR que TP1 solo — no usar)
//    Vela 1-2: 79.1% breakouts antes de 15:00 UTC
//    Vela 4+: SL=64.7%, TP3=0% (eliminar con EntryMaxCandle)
//    MAE mediana: 0.83×rango → BE al 100% es el óptimo
//+------------------------------------------------------------------+
#property copyright   "BreakoutNY v9.0"
#property version     "9.00"
#property description "BreakoutNY NY Open Breakout — XAUUSD — FundingPips — V3 Óptima"
#property strict

#include <Trade\Trade.mqh>

//==================================================================
// INPUT PARAMETERS
//==================================================================

input group "=== HORARIO ==="
input int    ServerOffsetHours  = 2;    // Offset servidor vs UTC (FundingPips = UTC+2)
input int    EntryWindowEnd_Min = 15;   // Seguridad: ventana cierra a 15:HH UTC (rara vez alcanzado)

input group "=== RIESGO ==="
input double RiskAmountUSD      = 75.0; // [V3-1] $75 → MaxDD < 8% en 5 años backtested

input group "=== OBJETIVOS (Múltiplos del SL = rango) ==="
input double TP1_RR             = 1.0;  // TP1 = 1×rango (usado como referencia BE)
input double TP2_RR             = 2.0;  // TP2 = 2×rango
input double TP3_RR             = 3.0;  // TP3 = 3×rango (objetivo principal — SessionEnd captura el resto)

input group "=== CIERRES PARCIALES ==="
// [V3-7] ESTADÍSTICO: EnablePartials=false es ÓPTIMO
// Parciales 50%TP1+50%TP3: PF=1.188 vs TP3-todo: PF=2.053
// Dejar false salvo decisión consciente de reducir varianza a costa de rendimiento
input bool   EnablePartials     = false; // false = RECOMENDADO (mejor PF)
input int    TP1_ClosePct       = 40;    // % del lote a cerrar en TP1 (solo si EnablePartials=true)
input int    TP2_ClosePct       = 40;    // % del lote a cerrar en TP2 (solo si EnablePartials=true)

input group "=== BREAKEVEN ==="
// [V3-2] BE=100% es ÓPTIMO estadísticamente
// MAE mediano = 0.83×rango: el precio retrocede casi 1×rango antes de recuperarse.
// BE al 20% (configuración anterior) cerraba el 91.6% de trades en $0 — destruía valor.
// BE al 100%: activa solo cuando el precio ya avanzó 1×rango completo (50.3% de trades).
input double BE_BufferPct       = 100.0; // [V3-2] 100% = BE solo cuando TP1 es inminente

input group "=== FILTROS DE RANGO ==="
input double MinSL_Points       = 5.50;  // SL mínimo = rango mínimo ($) ← P25 del rango
input double MaxSL_Points       = 15.00; // [V3-3] SL máximo = rango máximo ($) ← P75 del rango

input group "=== FILTROS DE DÍA ==="
// [V3-4][V3-5] Martes y Viernes filtrados (PF < 1.5 en backtest EA con BE=20%)
// NOTA: con TP3+BE=100%, el estadístico muestra Mar=1.437 y Vie=1.641 PF
// Candidatos a reactivar después de 60 días de forward test real
input bool   FilterMonday       = true;  // PF=2.000 — opera
input bool   FilterTuesday      = false; // [V3-4] PF=0.73 en backtest EA — filtrado
input bool   FilterWednesday    = true;  // PF=1.851 — opera
input bool   FilterThursday     = true;  // PF=4.261 — motor principal de la estrategia
input bool   FilterFriday       = false; // [V3-5] filtrado por precaución
input bool   ConfirmOnClose     = true;  // SIEMPRE true — núcleo de la estrategia. NO optimizar.

input group "=== FILTRO DE VELA DE ENTRADA (NUEVO V3) ==="
// [V3-6] ESTADÍSTICO: 79.1% breakouts en velas 1-2 (14:50-14:55 UTC)
// Vela 4 (15:05 UTC): SL=64.7%, TP3=0.0% — es el peor punto de entrada
// EntryMaxCandle=2: solo entrar si el breakout se detectó en vela 1 o 2
// EntryMaxCandle=0: sin límite de vela (comportamiento v8 anterior)
input int    EntryMaxCandle     = 2;     // [V3-6] Máx vela M5 del breakout (1=14:50, 2=14:55, 0=sin límite)

input group "=== LOGGING ==="
input bool   EnableCSV          = true;  // Genera CSV con cada trade ejecutado

input group "=== VISUAL ==="
input bool   VIS_Enable         = true;  // Dibuja rango y niveles en el gráfico

input group "=== CONFIG ==="
input int    MagicNumber        = 202409; // Número mágico único (actualizado para V3)

//==================================================================
// GLOBALES
//==================================================================

CTrade trade;

// Specs del símbolo (cargadas en OnInit)
double g_tickValue;
double g_tickSize;
double g_valuePerPoint;   // $ por lote por 1 punto de precio — via OrderCalcProfit (BUG FIX [9])
double g_volumeMin;
double g_volumeMax;
double g_volumeStep;
int    g_digits;

// Estado diario
double   g_rangeHigh            = 0;
double   g_rangeLow             = 0;
double   g_slDistance           = 0;
double   g_cachedLots           = 0;
bool     g_rangeCalculated      = false;
bool     g_rangeSet             = false;
bool     g_tradeExecuted        = false;
bool     g_be_activated         = false;
bool     g_tp1_hit              = false;
bool     g_tp2_hit              = false;
datetime g_lastDay              = 0;
datetime g_nyOpenTime           = 0;    // [V3-6] Timestamp de apertura NY del día actual

// Estado ConfirmOnClose
bool     g_breakoutPending      = false;
string   g_pendingDir           = "";
datetime g_pendingBarTime       = 0;
int      g_breakoutDetectedCandle = 0;  // [V3-6] Vela M5 en que se detectó el breakout

// Niveles del trade activo
double   g_entryPrice           = 0;
double   g_slLevel              = 0;
double   g_tpLevel1             = 0;
double   g_tpLevel2             = 0;
double   g_tpLevel3             = 0;
double   g_beLevel              = 0;
string   g_tradeDir             = "";
datetime g_tradeTime            = 0;

// CSV
int      g_csvHandle            = INVALID_HANDLE;

//==================================================================
// OnInit
//==================================================================
int OnInit()
{
   // ── Cargar specs del símbolo ──────────────────────────────────
   g_tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   g_tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   g_volumeMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   g_volumeMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   g_volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   g_digits     = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   if(g_tickSize <= 0) {
      Print("CRITICAL ERROR: TickSize=0. Verifique el símbolo.");
      return INIT_FAILED;
   }

   // ── BUG FIX [9]: VPP robusto via OrderCalcProfit ──────────────
   // PROBLEMA: SymbolInfoDouble(SYMBOL_TRADE_TICK_VALUE) devuelve ~0.19-0.49
   //           en el backtester MT5 para CFD XCCY (XAUUSD), causando lotaje
   //           2.6-3.8× mayor → pérdidas reales de $261-$384 en vez de $100.
   // SOLUCIÓN: OrderCalcProfit mide el VPP real en el contexto de ejecución.
   //           Para XAUUSD (100oz): 1lot × $1 de precio = $100 → VPP=100.
   double ask0      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profitTest = 0;
   double contractSz = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   bool calcOK = OrderCalcProfit(ORDER_TYPE_BUY, _Symbol,
                                  1.0, ask0, ask0 + 1.0, profitTest);
   if(calcOK && profitTest > 0.01) {
      g_valuePerPoint = profitTest;
      Print("VPP via OrderCalcProfit: ", g_valuePerPoint,
            "  (esperado ~100 para XAUUSD 100oz)");
   } else {
      g_valuePerPoint = contractSz;   // Fallback: ContractSize ($100 para XAUUSD)
      Print("VPP via ContractSize (fallback): ", g_valuePerPoint);
   }

   // Verificación cruzada informativa (NO usada en cálculo)
   double vppTick = (g_tickSize > 0) ? (g_tickValue / g_tickSize) : 0;
   Print("VPP via TickValue/TickSize (ref — NO usada): ", vppTick);

   // ── Verificaciones de inputs ──────────────────────────────────
   if(MinSL_Points >= MaxSL_Points) {
      Print("ERROR: MinSL_Points (", MinSL_Points, ") debe ser < MaxSL_Points (", MaxSL_Points, ")");
      return INIT_FAILED;
   }
   if(EntryMaxCandle < 0 || EntryMaxCandle > 26) {
      Print("ERROR: EntryMaxCandle debe estar entre 0 y 26.");
      return INIT_FAILED;
   }

   // ── Log de inicio ─────────────────────────────────────────────
   Print("╔══════════════════════════════════════════════════════╗");
   Print("║  BreakoutNY v9.00 — XAUUSD — FundingPips — V3      ║");
   Print("║  Configuración óptima validada estadísticamente     ║");
   Print("╚══════════════════════════════════════════════════════╝");
   Print("── Specs del símbolo ───────────────────────────────────");
   Print("  Símbolo       : ", _Symbol);
   Print("  ContractSize  : ", contractSz,      " (esperado: 100)");
   Print("  TickValue     : ", g_tickValue,      " (info; NO usado)");
   Print("  TickSize      : ", g_tickSize,       " (esperado: 0.01)");
   Print("  ValuePerPoint : ", g_valuePerPoint,  " (esperado: 100.0) ← CORREGIDO [9]");
   Print("  _Point        : ", SymbolInfoDouble(_Symbol, SYMBOL_POINT));
   Print("  VolumeMin/Max : ", g_volumeMin, " / ", g_volumeMax);
   Print("── Configuración V3 ────────────────────────────────────");
   Print("  RiskAmountUSD : $", RiskAmountUSD,  " [V3-1: era $100]");
   Print("  BE_BufferPct  : ", BE_BufferPct, "%", " [V3-2: era 20%]");
   Print("  MinSL_Points  : ", MinSL_Points);
   Print("  MaxSL_Points  : ", MaxSL_Points,    " [V3-3: era 12.00]");
   Print("  EntryMaxCandle: ", EntryMaxCandle,  " [V3-6: nuevo]");
   Print("  FilterTue     : ", FilterTuesday,   " [V3-4: filtrado]");
   Print("  FilterFri     : ", FilterFriday,    " [V3-5: filtrado]");
   Print("  EnablePartials: ", EnablePartials,  " [V3-7: false=óptimo]");
   Print("  ConfirmOnClose: ", ConfirmOnClose,  " (SIEMPRE true)");
   Print("── Verificación lotaje (mediana rango=$9.07) ────────────");
   double slEx = 9.07;
   double loEx = NormalizeDouble(RiskAmountUSD / (slEx * g_valuePerPoint), 4);
   Print("  lots = ", RiskAmountUSD, " / (", slEx, " × ", g_valuePerPoint, ") = ", loEx);
   Print("  Riesgo verificado = $", NormalizeDouble(loEx * slEx * g_valuePerPoint, 2),
         "  (debe ser ≈ $", RiskAmountUSD, ")");
   Print("────────────────────────────────────────────────────────");

   // ── Configurar CTrade ─────────────────────────────────────────
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   // ── Inicializar CSV ───────────────────────────────────────────
   if(EnableCSV) {
      string csvName = "BreakoutNY_V3_XAUUSD_Trades.csv";
      g_csvHandle = FileOpen(csvName,
                              FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ",");
      if(g_csvHandle != INVALID_HANDLE) {
         FileWrite(g_csvHandle,
            "Date", "Time", "Weekday", "Direction",
            "EntryPrice", "SL_Pts", "RangeSize",
            "BreakoutCandle", "BreakoutTime_UTC",
            "ExitType", "ClosePrice", "PnL_USD",
            "RangeHigh", "RangeLow", "SL_Final",
            "BE_Activated", "Lots", "RiskUSD"
         );
         FileFlush(g_csvHandle);
         Print("CSV inicializado: ", csvName);
      } else {
         Print("WARNING: No se pudo crear el CSV. Error: ", GetLastError());
      }
   }

   return INIT_SUCCEEDED;
}

//==================================================================
// OnDeinit
//==================================================================
void OnDeinit(const int reason)
{
   if(g_csvHandle != INVALID_HANDLE) {
      FileFlush(g_csvHandle);
      FileClose(g_csvHandle);
   }
   if(VIS_Enable) VIS_CleanAll();
}

//==================================================================
// OnTick
//==================================================================
void OnTick()
{
   // ── Reset diario ──────────────────────────────────────────────
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
   if(today != g_lastDay) {
      DailyReset();
      g_lastDay = today;
   }

   // ── Filtro de día ─────────────────────────────────────────────
   if(!IsTradingDayAllowed()) return;

   // ── Tiempo servidor ───────────────────────────────────────────
   MqlDateTime sdt;
   TimeToStruct(TimeCurrent(), sdt);
   int sHour = sdt.hour;
   int sMin  = sdt.min;

   // Conversión UTC → Servidor (FundingPips UTC+2):
   // Range calc : 14:50 UTC → 16:50 servidor
   // Window end : 15:MM  UTC → 17:MM  servidor
   // Force close: 17:00  UTC → 19:00  servidor
   int rHour = 14 + ServerOffsetHours;   // 16
   int rMin  = 50;
   int wHour = 15 + ServerOffsetHours;   // 17
   int wMin  = EntryWindowEnd_Min;
   int fHour = 17 + ServerOffsetHours;   // 19

   // ── PASO 1: Calcular rango a las 14:50 UTC ────────────────────
   if(!g_rangeCalculated && sHour == rHour && sMin == rMin) {
      CalculateRange();
      g_rangeCalculated = true;
   }

   if(!g_rangeSet) return;

   // ── Cierre forzoso 17:00 UTC ──────────────────────────────────
   if(sHour >= fHour) {
      if(HasOpenPosition()) CloseAllPositions("SessionEnd");
      return;
   }

   // ── Ventana de entrada ────────────────────────────────────────
   bool afterRange    = (sHour > rHour) || (sHour == rHour && sMin >= rMin);
   bool beforeWindow  = (sHour < wHour) || (sHour == wHour && sMin <= wMin);
   bool inWindow      = afterRange && beforeWindow;

   if(!inWindow) return;

   // ── Gestión de posición abierta ───────────────────────────────
   if(HasOpenPosition()) {
      ManagePosition();
      return;
   }

   if(g_tradeExecuted) return;

   // ── PASO 2: Detección y confirmación del breakout ─────────────
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(ConfirmOnClose) {
      datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);

      // FASE A — Detección
      if(!g_breakoutPending) {
         bool bullBreak = (ask > g_rangeHigh);
         bool bearBreak = (bid < g_rangeLow);

         if(bullBreak || bearBreak) {
            // ── [V3-6] Filtro de vela de entrada ─────────────────
            // Calcular en qué vela M5 estamos desde la apertura NY
            int candleNum = 0;
            if(g_nyOpenTime > 0) {
               int secondsSinceNY = (int)(currentBarTime - g_nyOpenTime);
               candleNum = (secondsSinceNY / 300) + 1;  // 300 seg = 5 min = 1 vela M5
               candleNum = MathMax(1, candleNum);
            }

            // Si el breakout es demasiado tardío, lo ignoramos
            if(EntryMaxCandle > 0 && candleNum > EntryMaxCandle) {
               // Solo loguear una vez por día para no saturar el log
               static datetime lastSkipLog = 0;
               if(currentBarTime != lastSkipLog) {
                  Print("Breakout tardío ignorado: vela ", candleNum,
                        " > EntryMaxCandle=", EntryMaxCandle,
                        " (", bullBreak ? "BUY" : "SELL", ")");
                  lastSkipLog = currentBarTime;
               }
               return;  // No operar — breakout demasiado tardío
            }

            // Breakout válido — registrar como pendiente
            g_breakoutPending         = true;
            g_pendingDir              = bullBreak ? "buy" : "sell";
            g_pendingBarTime          = currentBarTime;
            g_breakoutDetectedCandle  = candleNum;

            Print("Breakout detectado: ", g_pendingDir, " | vela ", candleNum,
                  " | ", TimeToString(TimeCurrent()),
                  " | ask=", ask, " bid=", bid,
                  " | rango: [", g_rangeLow, "–", g_rangeHigh, "]");
         }
      }

      // FASE B — Confirmación (nueva vela M5 formada)
      if(g_breakoutPending && currentBarTime > g_pendingBarTime) {
         bool stillValid = (g_pendingDir == "buy"  && ask > g_rangeHigh) ||
                           (g_pendingDir == "sell" && bid < g_rangeLow);
         if(!stillValid) {
            Print("False breakout cancelado en vela ", g_breakoutDetectedCandle,
                  ". Precio regresó al rango.");
            g_breakoutPending        = false;
            g_pendingDir             = "";
            g_pendingBarTime         = 0;
            g_breakoutDetectedCandle = 0;
         } else {
            ExecuteTrade(g_pendingDir);
         }
      }
   }
   else {
      // Sin confirmación: entrada en primer tick (no recomendado)
      if(ask > g_rangeHigh) {
         ExecuteTrade("buy");
      } else if(bid < g_rangeLow) {
         ExecuteTrade("sell");
      }
   }
}

//==================================================================
// CalculateRange
// Lee las 3 velas M5 anteriores a 14:50 UTC: [14:35, 14:40, 14:45]
//==================================================================
void CalculateRange()
{
   // En la apertura de 14:50 UTC (Bar[0]):
   //   Bar[1] = 14:45 UTC (cerrada) ← usamos
   //   Bar[2] = 14:40 UTC (cerrada) ← usamos
   //   Bar[3] = 14:35 UTC (cerrada) ← usamos
   double h1 = iHigh(_Symbol, PERIOD_M5, 1);
   double h2 = iHigh(_Symbol, PERIOD_M5, 2);
   double h3 = iHigh(_Symbol, PERIOD_M5, 3);
   double l1 = iLow (_Symbol, PERIOD_M5, 1);
   double l2 = iLow (_Symbol, PERIOD_M5, 2);
   double l3 = iLow (_Symbol, PERIOD_M5, 3);

   if(h1 == 0 || h2 == 0 || h3 == 0) {
      Print("ERROR CalculateRange: datos históricos insuficientes.");
      return;
   }

   g_rangeHigh  = MathMax(h1, MathMax(h2, h3));
   g_rangeLow   = MathMin(l1, MathMin(l2, l3));
   g_slDistance = g_rangeHigh - g_rangeLow;  // Raw price diff (no × _Point) [BUG FIX 1]

   // [V3-6] Guardar timestamp de NY open para calcular número de vela
   g_nyOpenTime = iTime(_Symbol, PERIOD_M5, 0);  // Bar[0] = 14:50 UTC

   // ── Filtro de rango ───────────────────────────────────────────
   if(g_slDistance < MinSL_Points) {
      Print("Rango FILTRADO (pequeño): $", DoubleToString(g_slDistance, 2),
            " < MinSL=$", MinSL_Points);
      return;
   }
   if(g_slDistance > MaxSL_Points) {
      Print("Rango FILTRADO (grande): $", DoubleToString(g_slDistance, 2),
            " > MaxSL=$", MaxSL_Points);
      return;
   }

   // ── Calcular lotaje UNA SOLA VEZ [BUG FIX 6] ─────────────────
   g_cachedLots = CalculateLotSize(g_slDistance);
   if(g_cachedLots <= 0) {
      Print("ERROR: Lotaje calculado = 0. Día omitido.");
      return;
   }

   g_rangeSet = true;

   Print("── Rango calculado (V3) ────────────────────────────────");
   Print("  RangeHigh   : ", DoubleToString(g_rangeHigh, g_digits));
   Print("  RangeLow    : ", DoubleToString(g_rangeLow,  g_digits));
   Print("  SL_Dist     : $", DoubleToString(g_slDistance, 2));
   Print("  Lots        : ", g_cachedLots);
   Print("  Risk        : $", DoubleToString(g_cachedLots * g_slDistance * g_valuePerPoint, 2));
   Print("  EntryMax    : vela ≤", EntryMaxCandle, " (hasta ", 14, ":", 50 + EntryMaxCandle * 5, " UTC)");
   if(VIS_Enable) VIS_DrawRange();
}

//==================================================================
// CalculateLotSize
//==================================================================
double CalculateLotSize(double slDist)
{
   // [BUG FIX 9]: g_valuePerPoint via OrderCalcProfit
   // XAUUSD 100oz: 1 lot × $1 de precio = $100 → VPP=100
   // lots = RiskUSD / (slDist × VPP)
   // Ej: 75 / (9.07 × 100) = 0.082 lots → riesgo = 0.08 × 9.07 × 100 = $72.56 ✓
   if(g_valuePerPoint <= 0 || slDist <= 0) {
      Print("ERROR CalculateLotSize: VPP=", g_valuePerPoint, " slDist=", slDist);
      return 0;
   }

   double lotsRaw = RiskAmountUSD / (slDist * g_valuePerPoint);

   // Redondear a volumeStep del broker
   double lots = MathFloor(lotsRaw / g_volumeStep) * g_volumeStep;
   lots = MathMax(lots, g_volumeMin);
   lots = MathMin(lots, g_volumeMax);
   lots = NormalizeDouble(lots, 2);

   // ── Verificación de margen [BUG FIX 5+7] ─────────────────────
   double marginReq = 0;
   double askNow    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, askNow, marginReq)) {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);  // [BUG FIX 7]
      if(marginReq > freeMargin * 0.90) {
         double safeLots = MathFloor((freeMargin * 0.90 / marginReq * lots) / g_volumeStep) * g_volumeStep;
         safeLots = MathMax(safeLots, g_volumeMin);
         Print("WARNING: Margen insuficiente. Reduciendo lots: ", lots, " → ", safeLots);
         lots = safeLots;
      }
   }

   return lots;
}

//==================================================================
// ExecuteTrade
//==================================================================
void ExecuteTrade(string direction)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   g_tradeDir  = direction;
   g_tradeTime = TimeCurrent();

   if(direction == "buy") {
      g_entryPrice = ask;
      g_slLevel    = NormalizeDouble(g_entryPrice - g_slDistance,                           g_digits);
      g_beLevel    = NormalizeDouble(g_entryPrice + g_slDistance * BE_BufferPct / 100.0,    g_digits);
      g_tpLevel1   = NormalizeDouble(g_entryPrice + g_slDistance * TP1_RR,                  g_digits);
      g_tpLevel2   = NormalizeDouble(g_entryPrice + g_slDistance * TP2_RR,                  g_digits);
      g_tpLevel3   = NormalizeDouble(g_entryPrice + g_slDistance * TP3_RR,                  g_digits);

      if(!trade.Buy(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel3,
                    StringFormat("BreakoutNY BUY v%.2f", 9.0))) {
         Print("ERROR Buy: ", trade.ResultRetcode(), " — ", trade.ResultRetcodeDescription());
         return;
      }
   }
   else {
      g_entryPrice = bid;
      g_slLevel    = NormalizeDouble(g_entryPrice + g_slDistance,                           g_digits);
      g_beLevel    = NormalizeDouble(g_entryPrice - g_slDistance * BE_BufferPct / 100.0,    g_digits);
      g_tpLevel1   = NormalizeDouble(g_entryPrice - g_slDistance * TP1_RR,                  g_digits);
      g_tpLevel2   = NormalizeDouble(g_entryPrice - g_slDistance * TP2_RR,                  g_digits);
      g_tpLevel3   = NormalizeDouble(g_entryPrice - g_slDistance * TP3_RR,                  g_digits);

      if(!trade.Sell(g_cachedLots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel3,
                     StringFormat("BreakoutNY SELL v%.2f", 9.0))) {
         Print("ERROR Sell: ", trade.ResultRetcode(), " — ", trade.ResultRetcodeDescription());
         return;
      }
   }

   g_tradeExecuted          = true;
   g_breakoutPending        = false;
   g_pendingDir             = "";
   g_pendingBarTime         = 0;
   // Nota: g_breakoutDetectedCandle se conserva para el CSV

   Print("── Trade ejecutado (V3) ────────────────────────────────");
   Print("  Dir          : ", direction);
   Print("  Entry        : ", DoubleToString(g_entryPrice, g_digits));
   Print("  SL           : ", DoubleToString(g_slLevel,    g_digits),
         "  (dist=$", DoubleToString(g_slDistance, 2), ")");
   Print("  BE (", BE_BufferPct, "%) : ", DoubleToString(g_beLevel, g_digits));
   Print("  TP1          : ", DoubleToString(g_tpLevel1,   g_digits));
   Print("  TP2          : ", DoubleToString(g_tpLevel2,   g_digits));
   Print("  TP3          : ", DoubleToString(g_tpLevel3,   g_digits));
   Print("  Lots         : ", g_cachedLots);
   Print("  Risk         : $", DoubleToString(g_cachedLots * g_slDistance * g_valuePerPoint, 2));
   Print("  BreakoutVela : ", g_breakoutDetectedCandle,
         " (", 14, ":", MathMin(50 + (g_breakoutDetectedCandle - 1) * 5, 59), " UTC)");

   if(VIS_Enable) VIS_DrawLevels();
}

//==================================================================
// ManagePosition — Breakeven + Parciales (si habilitado)
//==================================================================
void ManagePosition()
{
   ulong ticket = GetOpenPositionTicket();
   if(ticket == 0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // ── Breakeven ─────────────────────────────────────────────────
   // [V3-2] BE=100%: activa cuando precio avanza 1×SL desde entrada
   // Estadístico: 50.3% de trades alcanzan este nivel
   // MAE mediano: 0.83×rango → BE a 100% no lo activa prematuramente
   if(!g_be_activated) {
      bool beCond = (g_tradeDir == "buy"  && bid >= g_beLevel) ||
                    (g_tradeDir == "sell" && ask <= g_beLevel);
      if(beCond) {
         double newSL = NormalizeDouble(g_entryPrice, g_digits);
         if(trade.PositionModify(ticket, newSL, g_tpLevel3)) {
            g_slLevel      = newSL;
            g_be_activated = true;
            Print("BE activado (", BE_BufferPct, "%). SL→entry: ", DoubleToString(newSL, g_digits));
         }
      }
   }

   // ── Cierre parcial TP1 ────────────────────────────────────────
   // [V3-7] EnablePartials=false por defecto (estadístico: PF=1.19 < 2.05)
   if(!g_tp1_hit && EnablePartials) {
      bool tp1Cond = (g_tradeDir == "buy"  && bid >= g_tpLevel1) ||
                     (g_tradeDir == "sell" && ask <= g_tpLevel1);
      if(tp1Cond) {
         if(PositionSelectByTicket(ticket)) {
            double posVol   = PositionGetDouble(POSITION_VOLUME);
            double closeVol = NormalizeDouble(posVol * TP1_ClosePct / 100.0, 2);
            closeVol = MathMax(closeVol, g_volumeMin);
            closeVol = MathMin(closeVol, posVol - g_volumeMin);
            if(closeVol >= g_volumeMin) {
               trade.PositionClosePartial(ticket, closeVol);
               // SL a entry + pequeño buffer
               double newSL = (g_tradeDir == "buy") ?
                  NormalizeDouble(g_entryPrice + g_slDistance * 0.05, g_digits) :
                  NormalizeDouble(g_entryPrice - g_slDistance * 0.05, g_digits);
               trade.PositionModify(ticket, newSL, g_tpLevel3);
               g_slLevel = newSL;
            }
         }
         g_tp1_hit = true;
         Print("TP1 alcanzado. Parcial ejecutado (", TP1_ClosePct, "%).");
      }
   }

   // ── Cierre parcial TP2 ────────────────────────────────────────
   if(g_tp1_hit && !g_tp2_hit && EnablePartials) {
      bool tp2Cond = (g_tradeDir == "buy"  && bid >= g_tpLevel2) ||
                     (g_tradeDir == "sell" && ask <= g_tpLevel2);
      if(tp2Cond) {
         if(PositionSelectByTicket(ticket)) {
            double posVol   = PositionGetDouble(POSITION_VOLUME);
            double closeVol = NormalizeDouble(posVol * TP2_ClosePct / 100.0, 2);
            closeVol = MathMax(closeVol, g_volumeMin);
            closeVol = MathMin(closeVol, posVol - g_volumeMin);
            if(closeVol >= g_volumeMin) {
               trade.PositionClosePartial(ticket, closeVol);
               trade.PositionModify(ticket, g_tpLevel1, g_tpLevel3);
               g_slLevel = g_tpLevel1;
            }
         }
         g_tp2_hit = true;
         Print("TP2 alcanzado. Parcial ejecutado (", TP2_ClosePct, "%). SL→TP1.");
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

   if(PositionSelectByTicket(ticket)) {
      closePrice = (g_tradeDir == "buy") ?
         SymbolInfoDouble(_Symbol, SYMBOL_BID) :
         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      pnl = PositionGetDouble(POSITION_PROFIT);
   }

   trade.PositionClose(ticket);
   Print("Posición cerrada: ", exitType, " | PnL=$", DoubleToString(pnl, 2));

   if(EnableCSV) LogToCSV(exitType, closePrice, pnl);
}

//==================================================================
// LogToCSV — [V3-8] CSV enriquecido
//==================================================================
void LogToCSV(string exitType, double closePrice, double pnl)
{
   if(g_csvHandle == INVALID_HANDLE) return;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string wdays[] = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};

   // Calcular hora de breakout en UTC
   string breakoutTimeUTC = "N/A";
   if(g_breakoutDetectedCandle > 0) {
      int minAbs = 14*60 + 50 + (g_breakoutDetectedCandle - 1) * 5;
      breakoutTimeUTC = StringFormat("%02d:%02d", minAbs/60, minAbs%60);
   }

   double riskActual = g_cachedLots * g_slDistance * g_valuePerPoint;

   FileWrite(g_csvHandle,
      StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day),
      StringFormat("%02d:%02d",      dt.hour, dt.min),
      wdays[dt.day_of_week],
      g_tradeDir,
      DoubleToString(g_entryPrice,           g_digits),
      DoubleToString(g_slDistance,           2),        // SL en $ (= tamaño del rango)
      DoubleToString(g_slDistance,           2),        // RangeSize = SL distance
      IntegerToString(g_breakoutDetectedCandle),        // Vela M5 del breakout
      breakoutTimeUTC,                                   // Hora UTC del breakout
      exitType,
      DoubleToString(closePrice,             g_digits),
      DoubleToString(pnl,                    2),
      DoubleToString(g_rangeHigh,            g_digits),
      DoubleToString(g_rangeLow,             g_digits),
      DoubleToString(g_slLevel,              g_digits),
      (string)g_be_activated,
      DoubleToString(g_cachedLots,           2),
      DoubleToString(riskActual,             2)
   );
   FileFlush(g_csvHandle);
}

//==================================================================
// DailyReset
//==================================================================
void DailyReset()
{
   g_rangeHigh              = 0;
   g_rangeLow               = 0;
   g_slDistance             = 0;
   g_cachedLots             = 0;
   g_rangeCalculated        = false;
   g_rangeSet               = false;
   g_tradeExecuted          = false;
   g_be_activated           = false;
   g_tp1_hit                = false;
   g_tp2_hit                = false;
   g_breakoutPending        = false;
   g_pendingDir             = "";
   g_pendingBarTime         = 0;
   g_breakoutDetectedCandle = 0;   // [V3-6]
   g_nyOpenTime             = 0;   // [V3-6]
   g_entryPrice             = 0;
   g_slLevel                = 0;
   g_tradeDir               = "";
   g_tradeTime              = 0;
}

//==================================================================
// Helpers
//==================================================================
bool IsTradingDayAllowed()
{
   // [BUG FIX 8]: true = OPERA, false = SALTA
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   switch(dt.day_of_week) {
      case 1: return FilterMonday;
      case 2: return FilterTuesday;    // [V3-4] false
      case 3: return FilterWednesday;
      case 4: return FilterThursday;
      case 5: return FilterFriday;     // [V3-5] false
      default: return false;
   }
}

bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionGetTicket(i) > 0)
         if((int)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
            return true;
   }
   return false;
}

ulong GetOpenPositionTicket()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t > 0)
         if((int)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
            return t;
   }
   return 0;
}

//==================================================================
// MÓDULO VISUAL
//==================================================================
void VIS_DrawRange()
{
   if(!VIS_Enable) return;

   datetime t0 = iTime(_Symbol, PERIOD_M5, 3);   // 14:35 UTC
   datetime t1 = iTime(_Symbol, PERIOD_M5, 0);   // 14:50 UTC

   string rName = "BNY_Range";
   ObjectDelete(0, rName);
   ObjectCreate(0, rName, OBJ_RECTANGLE, 0, t0, g_rangeLow, t1, g_rangeHigh);
   ObjectSetInteger(0, rName, OBJPROP_COLOR, (color)0x1E90FF);
   ObjectSetInteger(0, rName, OBJPROP_FILL,  true);
   ObjectSetInteger(0, rName, OBJPROP_BACK,  true);

   for(int i = 0; i < 2; i++) {
      string n    = (i == 0) ? "BNY_RangeH" : "BNY_RangeL";
      double lvl  = (i == 0) ? g_rangeHigh  : g_rangeLow;
      ObjectDelete(0, n);
      ObjectCreate(0, n, OBJ_HLINE, 0, 0, lvl);
      ObjectSetInteger(0, n, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, n, OBJPROP_STYLE, STYLE_DOT);
   }

   // Indicador de EntryMaxCandle en el chart
   if(EntryMaxCandle > 0) {
      string ecName = "BNY_EntryMax";
      datetime ecTime = (datetime)(g_nyOpenTime + EntryMaxCandle * 300);
      ObjectDelete(0, ecName);
      ObjectCreate(0, ecName, OBJ_VLINE, 0, ecTime, 0);
      ObjectSetInteger(0, ecName, OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(0, ecName, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, ecName, OBJPROP_WIDTH, 1);
   }

   ChartRedraw();
}

void VIS_DrawLevels()
{
   if(!VIS_Enable) return;

   datetime t = TimeCurrent();

   string arrName = "BNY_Arrow";
   ObjectDelete(0, arrName);
   ObjectCreate(0, arrName, OBJ_ARROW, 0, t, g_entryPrice);
   if(g_tradeDir == "buy") {
      ObjectSetInteger(0, arrName, OBJPROP_ARROWCODE, 241);
      ObjectSetInteger(0, arrName, OBJPROP_COLOR,     clrLime);
   } else {
      ObjectSetInteger(0, arrName, OBJPROP_ARROWCODE, 242);
      ObjectSetInteger(0, arrName, OBJPROP_COLOR,     clrRed);
   }
   ObjectSetInteger(0, arrName, OBJPROP_WIDTH, 2);

   // Niveles de precio
   struct LvlDef { string name; double price; color clr; ENUM_LINE_STYLE sty; int w; };
   LvlDef lvls[6];
   lvls[0].name="BNY_SL";    lvls[0].price=g_slLevel;    lvls[0].clr=clrRed;      lvls[0].sty=STYLE_DOT;   lvls[0].w=1;
   lvls[1].name="BNY_Entry"; lvls[1].price=g_entryPrice; lvls[1].clr=clrWhite;    lvls[1].sty=STYLE_SOLID; lvls[1].w=1;
   lvls[2].name="BNY_BE";    lvls[2].price=g_beLevel;    lvls[2].clr=clrCyan;     lvls[2].sty=STYLE_DASH;  lvls[2].w=1;
   lvls[3].name="BNY_TP1";   lvls[3].price=g_tpLevel1;   lvls[3].clr=clrYellow;   lvls[3].sty=STYLE_SOLID; lvls[3].w=1;
   lvls[4].name="BNY_TP2";   lvls[4].price=g_tpLevel2;   lvls[4].clr=clrOrange;   lvls[4].sty=STYLE_SOLID; lvls[4].w=1;
   lvls[5].name="BNY_TP3";   lvls[5].price=g_tpLevel3;   lvls[5].clr=clrLime;     lvls[5].sty=STYLE_SOLID; lvls[5].w=2;

   for(int i = 0; i < 6; i++) {
      ObjectDelete(0, lvls[i].name);
      ObjectCreate(0, lvls[i].name, OBJ_HLINE, 0, 0, lvls[i].price);
      ObjectSetInteger(0, lvls[i].name, OBJPROP_COLOR, lvls[i].clr);
      ObjectSetInteger(0, lvls[i].name, OBJPROP_STYLE, lvls[i].sty);
      ObjectSetInteger(0, lvls[i].name, OBJPROP_WIDTH, lvls[i].w);
   }

   // Etiqueta de estado
   string lblName = "BNY_Label";
   ObjectDelete(0, lblName);
   ObjectCreate(0, lblName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, lblName, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, lblName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, lblName, OBJPROP_YDISTANCE, 50);
   ObjectSetString (0, lblName, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE,  9);
   ObjectSetInteger(0, lblName, OBJPROP_COLOR,     clrWhite);

   string dir = (g_tradeDir == "buy") ? "▲ BUY" : "▼ SELL";
   ObjectSetString(0, lblName, OBJPROP_TEXT,
      StringFormat("BreakoutNY v9 V3 | %s | SL=$%.2f | TP3=$%.2f | Lots:%.2f | Vela:%d",
         dir, g_slDistance, g_slDistance * TP3_RR, g_cachedLots, g_breakoutDetectedCandle));

   ChartRedraw();
}

void VIS_CleanAll()
{
   string names[] = {
      "BNY_Range","BNY_RangeH","BNY_RangeL","BNY_EntryMax",
      "BNY_Arrow","BNY_SL","BNY_Entry","BNY_BE",
      "BNY_TP1","BNY_TP2","BNY_TP3","BNY_Label"
   };
   for(int i = 0; i < 12; i++) ObjectDelete(0, names[i]);
   ChartRedraw();
}
//+------------------------------------------------------------------+