//+------------------------------------------------------------------+
//|  BreakoutNY_GBPUSD_FP.mq5                                        |
//|  BreakoutNY — GBPUSD — FundingPips                               |
//|  Timeframe : M5   Version : 1.0   Abril 2026                     |
//|                                                                   |
//|  SPECS GBPUSD:                                                    |
//|    Dígitos 5 | pip = _Point×10 | VPP ≈ $10/pip/lot               |
//|    Rango NY: 3 velas M5 → 14:35/14:40/14:45 UTC                 |
//|    Ventana entrada: 14:50 UTC + EntryWindowEnd_Min               |
//|    Ambas direcciones habilitadas por defecto                      |
//|                                                                   |
//|  CALIBRACIÓN (ejecutar BreakoutNY_Calibrador_GBPUSD primero):    |
//|    MinSL_Pips ← P25 del calibrador                               |
//|    MaxSL_Pips ← P75 del calibrador                               |
//+------------------------------------------------------------------+
#property copyright "BreakoutNY GBPUSD v1.0 — Jose Yanez"
#property version   "1.00"
#property description "BreakoutNY GBPUSD — FundingPips — M5"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade        trade;
CPositionInfo posInfo;

//===================================================================
//  ENUMERACIONES
//===================================================================

enum ENUM_TRADE_DIRECTION
{
   DIRECTION_BOTH  = 0,  // Compra y Venta
   DIRECTION_LONG  = 1,  // Solo Compra
   DIRECTION_SHORT = 2   // Solo Venta
};

enum ENUM_ENTRY_MODEL
{
   ENTRY_CONFIRM_CLOSE = 0,  // Confirmación al cierre de vela M5
   ENTRY_BREAKOUT_TICK = 1   // Ruptura directa (primer tick)
};

//===================================================================
//  PARÁMETROS DE ENTRADA
//===================================================================

//=== SESIÓN =========================================================
input group "=== SESION ==="
input int    ServerOffsetHours  = 2;    // Offset servidor vs UTC (FundingPips = UTC+2)
input int    EntryWindowEnd_Min = 15;   // Minutos de ventana desde las 14:50 UTC
input int    SessionCloseHour   = 17;   // Hora UTC cierre forzoso
input int    SessionCloseMin    = 0;    // Minutos cierre forzoso

//=== RIESGO =========================================================
input group "=== RIESGO ==="
input double RiskAmountUSD      = 50.0; // Riesgo por trade en USD

//=== MODELO DE ENTRADA ==============================================
input group "=== MODELO DE ENTRADA ==="
input ENUM_ENTRY_MODEL EntryModel      = ENTRY_CONFIRM_CLOSE; // Modelo de entrada
input int    EntryMaxCandle     = 0;    // Máx vela M5 para el breakout (0 = sin límite)

//=== DIRECCIÓN DE TRADING ===========================================
input group "=== DIRECCION DE TRADING ==="
input ENUM_TRADE_DIRECTION TradeDirection = DIRECTION_BOTH; // Dirección permitida

//=== GESTIÓN DE TRADE ===============================================
input group "=== GESTION DE TRADE ==="
input int    BE_BufferPct       = 50;   // % del SL para activar BreakEven
input double TP1_RR             = 1.0;  // TP1: múltiplo del SL
input double TP2_RR             = 2.0;  // TP2: SL se mueve a TP1 al alcanzar
input double TP3_RR             = 3.0;  // TP3: objetivo final

//=== CIERRES PARCIALES ==============================================
input group "=== CIERRES PARCIALES ==="
input bool   EnablePartials     = false; // Activar cierres parciales
input int    TP1_ClosePct       = 40;   // % del lote a cerrar en TP1
input int    TP2_ClosePct       = 40;   // % del lote a cerrar en TP2

//=== FILTROS DE RANGO (en PIPS) =====================================
// Ajustar con los resultados del Calibrador GBPUSD (P25 / P75)
// Defaults conservadores hasta tener calibración real
input group "=== FILTROS DE RANGO (PIPS) ==="
input double MinSL_Pips         = 8.0;  // Rango mínimo en pips ← P25 del calibrador
input double MaxSL_Pips         = 30.0; // Rango máximo en pips ← P75 del calibrador

//=== FILTROS DE DÍA =================================================
input group "=== FILTROS DE DIA ==="
input bool   FilterMonday       = true;  // Operar los lunes
input bool   FilterTuesday      = true;  // Operar los martes
input bool   FilterWednesday    = true;  // Operar los miércoles
input bool   FilterThursday     = true;  // Operar los jueves
input bool   FilterFriday       = true;  // Operar los viernes

//=== FILTRO ATR (VOLATILIDAD) =======================================
input group "=== FILTRO ATR (VOLATILIDAD) ==="
input bool   ATR_FilterEnable   = true;  // Activar filtro de volatilidad ATR
input int    ATR_Period         = 14;    // Período del ATR (velas M5)
input double ATR_MaxMultiplier  = 2.0;   // Bloquea si ATR > baseline × este valor
input double ATR_MinMultiplier  = 0.3;   // Bloquea si ATR < baseline × este valor
input int    ATR_BaselineDays   = 20;    // Días de lookback para baseline ATR

//=== LOGGING ========================================================
input group "=== LOGGING ==="
input bool   EnableCSV          = true;
input string CSVFileName        = "BreakoutNY_GBPUSD_trades";

//=== VISUAL =========================================================
input group "=== VISUAL ==="
input bool   VIS_Enable         = true;   // Activar módulo visual
input int    VIS_LookbackDays   = 25;     // Días históricos a redibujar
input int    VIS_ExtendBars     = 50;     // Velas de extensión lateral
input bool   VIS_ShowBE         = true;   // Mostrar línea de BreakEven
input bool   VIS_ShowLabel      = true;   // Mostrar panel informativo
input color  VIS_ColRange       = C'14,25,52';    // Color fondo zona de rango
input color  VIS_ColRangeBorder = C'55,115,215';  // Color bordes HIGH/LOW
input color  VIS_ColSL          = C'220,50,70';   // Color Stop Loss
input color  VIS_ColEntry       = C'195,208,230'; // Color línea de entrada
input color  VIS_ColBE          = C'0,195,218';   // Color BreakEven
input color  VIS_ColTP1         = C'228,188,38';  // Color TP1
input color  VIS_ColTP2         = C'228,128,28';  // Color TP2
input color  VIS_ColTP3         = C'28,208,128';  // Color TP3

//=== CONFIGURACIÓN ==================================================
input group "=== CONFIGURACION ==="
input int    MagicNumber        = 202410; // Magic number — GBPUSD

//===================================================================
//  ESTADO GLOBAL
//===================================================================

string   VIS_PFX = "BNYGBP_";

// Specs del símbolo
double   g_pipSize    = 0;    // 0.0001 para GBPUSD 5 dígitos
double   g_cachedVPP  = 0;    // Value Per Pip ($/pip/lot)

// Estado diario
double   g_rangeHigh      = 0;
double   g_rangeLow       = 0;
double   g_slDistance     = 0;  // en precio (unidades reales)
double   g_slPips         = 0;  // en pips (para log)
double   g_cachedLots     = 0;
bool     g_rangeFormed    = false;
bool     g_rangeAttempted = false;
bool     g_tradedToday    = false;
bool     g_sessionClosePrinted = false;

// Breakout pendiente (CONFIRM_CLOSE)
bool     g_brkPending     = false;
int      g_brkDir         = 0;
datetime g_brkBarTime     = 0;
int      g_brkCandleNum   = 0;

// Niveles del trade activo
double   g_entryPrice     = 0;
double   g_originalSL     = 0;
double   g_beLevel        = 0;
double   g_tp1Level       = 0;
double   g_tp2Level       = 0;
double   g_tp3Level       = 0;
bool     g_beActivated    = false;
bool     g_tp2Hit         = false;
bool     g_tp1Hit         = false;
string   g_tradeDir       = "";

datetime g_nyOpenTime     = 0;

int      g_atrHandle      = INVALID_HANDLE;
int      g_csvHandle      = INVALID_HANDLE;

int      g_lastResetDay   = -1;
datetime g_lastBarTime    = 0;

string   vis_dayTag       = "";
bool     vis_hasTrade     = false;

//===================================================================
//  VPP — Value Per Pip para forex
//===================================================================

double GetValuePerPip()
{
   int    digits  = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double tv      = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts      = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   // pip = 10 × _Point para par de 5 dígitos
   if(digits == 3 || digits == 5)
      g_pipSize = 10.0 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   else
      g_pipSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double vpp = 0;
   if(tv > 0 && ts > 0)
      vpp = (tv / ts) * g_pipSize;   // $/pip/lot
   else
   {
      Print("ERROR VPP: TV=", tv, " TS=", ts);
      return 0;
   }

   PrintFormat("VPP=$%.4f/pip/lot | TickValue=%.6f | TickSize=%.6f | pipSize=%.5f",
               vpp, tv, ts, g_pipSize);
   return vpp;
}

//===================================================================
//  CÁLCULO DE LOTE  (riesgo en pips)
//===================================================================

double CalculateLotSize(double slPips)
{
   if(g_cachedVPP <= 0 || slPips <= 0) return 0;

   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double lRaw = RiskAmountUSD / (slPips * g_cachedVPP);
   double lots = MathMax(vMin, MathMin(vMax, MathFloor(lRaw / vStep) * vStep));

   // Verificación de margen
   double freeMargin  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginPerLot = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, ask, marginPerLot))
      marginPerLot = ask * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) * 0.05;

   if(marginPerLot > 0)
   {
      double maxByMargin = MathFloor((freeMargin * 0.90) / marginPerLot / vStep) * vStep;
      maxByMargin = MathMax(vMin, MathMin(vMax, maxByMargin));
      if(lots > maxByMargin)
      {
         PrintFormat("AVISO MARGEN: lots=%.3f excede margen libre=$%.2f (max=%.3f lots) — reduciendo",
                     lots, freeMargin, maxByMargin);
         lots = maxByMargin;
      }
   }

   double realRisk = lots * slPips * g_cachedVPP;
   PrintFormat("LotCalc | SL=%.1f pips | VPP=$%.4f/pip/lot | Raw=%.4f | Lots=%.3f | Risk=$%.2f",
               slPips, g_cachedVPP, lRaw, lots, realRisk);
   return lots;
}

//===================================================================
//  OnInit
//===================================================================

int OnInit()
{
   if(_Period != PERIOD_M5) { Alert("Ejecutar en M5"); return INIT_FAILED; }

   if(BE_BufferPct < 0 || BE_BufferPct > 500)
      { Alert("BE_BufferPct debe estar entre 0 y 500"); return INIT_FAILED; }
   if(!(TP1_RR > 0 && TP2_RR > TP1_RR && TP3_RR > TP2_RR))
      { Alert("Requerido: TP1_RR < TP2_RR < TP3_RR"); return INIT_FAILED; }
   if(EnablePartials && (TP1_ClosePct + TP2_ClosePct >= 100))
      { Alert("TP1_ClosePct + TP2_ClosePct debe ser < 100"); return INIT_FAILED; }
   if(SessionCloseHour > 23)
      { Alert("SessionCloseHour debe ser 0–23"); return INIT_FAILED; }
   if(MinSL_Pips >= MaxSL_Pips)
      { Alert("MinSL_Pips debe ser menor que MaxSL_Pips"); return INIT_FAILED; }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(20);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   g_cachedVPP = GetValuePerPip();
   if(g_cachedVPP <= 0) { Alert("FATAL: no se pudo determinar VPP"); return INIT_FAILED; }

   if(ATR_FilterEnable)
   {
      g_atrHandle = iATR(_Symbol, PERIOD_M5, ATR_Period);
      if(g_atrHandle == INVALID_HANDLE) { Print("Error al crear handle ATR"); return INIT_FAILED; }
   }

   if(EnableCSV)
   {
      string path = CSVFileName + ".csv";
      g_csvHandle = FileOpen(path, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
      if(g_csvHandle != INVALID_HANDLE)
      {
         FileSeek(g_csvHandle, 0, SEEK_END);
         if(FileTell(g_csvHandle) == 0)
            FileWrite(g_csvHandle,
                      "Fecha","Dia","Dir","Lotes","VPP_pip","Riesgo$",
                      "Entry","SL","BE","TP1","TP2","TP3",
                      "SL_pips","EntryModel","BrkCandle","ATR");
         FileFlush(g_csvHandle);
      }
   }

   string dirStr = (TradeDirection == DIRECTION_LONG)  ? "Solo Compra" :
                   (TradeDirection == DIRECTION_SHORT) ? "Solo Venta" : "Compra y Venta";
   string modStr = (EntryModel == ENTRY_CONFIRM_CLOSE) ? "Confirmacion al cierre" : "Ruptura directa";

   Print("╔══════════════════════════════════════════════════════╗");
   PrintFormat("║  BreakoutNY GBPUSD v1.0 — %s", _Symbol);
   Print("╚══════════════════════════════════════════════════════╝");
   PrintFormat("  VPP=$%.4f/pip/lot | Riesgo=$%.2f | CierreUTC=%02d:%02d",
               g_cachedVPP, RiskAmountUSD, SessionCloseHour, SessionCloseMin);
   PrintFormat("  Dirección: %s | Modelo: %s", dirStr, modStr);
   PrintFormat("  BE=%d%% | TP %.1fR/%.1fR/%.1fR | EntryMaxCandle=%d",
               BE_BufferPct, TP1_RR, TP2_RR, TP3_RR, EntryMaxCandle);
   PrintFormat("  Días: Lun=%s Mar=%s Mié=%s Jue=%s Vie=%s",
               FilterMonday?"S":"N", FilterTuesday?"S":"N", FilterWednesday?"S":"N",
               FilterThursday?"S":"N", FilterFriday?"S":"N");
   PrintFormat("  pipSize=%.5f | MinSL=%.1f pips | MaxSL=%.1f pips",
               g_pipSize, MinSL_Pips, MaxSL_Pips);
   Print("  Tabla de lotes:");
   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double slTest[] = {MinSL_Pips, (MinSL_Pips + MaxSL_Pips) / 2.0, MaxSL_Pips};
   for(int i = 0; i < 3; i++)
   {
      double lr = RiskAmountUSD / (slTest[i] * g_cachedVPP);
      double lf = MathMax(vMin, MathMin(vMax, MathFloor(lr / vStep) * vStep));
      PrintFormat("    SL=%.1f pips -> lots=%.3f -> riesgo=$%.2f",
                  slTest[i], lf, lf * slTest[i] * g_cachedVPP);
   }
   Print("═══════════════════════════════════════════════════════");

   if(VIS_Enable) VisRedrawAll();

   return INIT_SUCCEEDED;
}

//===================================================================
//  OnDeinit
//===================================================================

void OnDeinit(const int reason)
{
   VisPurgeAll();
   if(g_csvHandle != INVALID_HANDLE) { FileFlush(g_csvHandle); FileClose(g_csvHandle); }
   if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//===================================================================
//  OnTick — lógica principal
//===================================================================

void OnTick()
{
   datetime serverNow = TimeCurrent();
   datetime utcNow    = serverNow - ServerOffsetHours * 3600;
   MqlDateTime utcDT; TimeToStruct(utcNow, utcDT);

   //--- Reset diario
   if(utcDT.day != g_lastResetDay)
   {
      g_lastResetDay = utcDT.day;
      g_rangeFormed   = false;  g_rangeAttempted = false;
      g_tradedToday   = false;  g_brkPending     = false;
      g_brkDir        = 0;      g_brkCandleNum   = 0;
      g_rangeHigh = g_rangeLow = g_slDistance = g_slPips = g_cachedLots = 0;
      g_beActivated = false;    g_tp2Hit = false; g_tp1Hit = false;
      g_entryPrice  = 0;        g_originalSL = 0;
      g_sessionClosePrinted = false;
      g_nyOpenTime  = 0;
      if(vis_dayTag != "") VisDeleteDay(vis_dayTag);
      vis_dayTag   = VisMakeDayTag();
      vis_hasTrade = false;
      g_tradeDir   = "";
      if(VIS_Enable) VisRedrawAll();
   }

   //--- Cierre forzoso de sesión
   if(HasOpenPosition())
   {
      bool mustClose = (utcDT.hour > SessionCloseHour) ||
                       (utcDT.hour == SessionCloseHour && utcDT.min >= SessionCloseMin);
      if(mustClose)
      {
         if(!g_sessionClosePrinted)
         {
            g_sessionClosePrinted = true;
            PrintFormat("SESSION_END: cerrando posicion a las %02d:%02d UTC", utcDT.hour, utcDT.min);
         }
         ClosePosition("SESSION_END");
         return;
      }
      ManagePosition();
      if(VIS_Enable && VIS_ShowLabel)
      {
         if(PositionSelect(_Symbol))
         {
            double floatPL = PositionGetDouble(POSITION_PROFIT);
            VisUpdatePanel(g_tradeDir, g_slPips, floatPL, true, false, "");
         }
      }
      return;
   }

   if(g_tradedToday) return;

   //--- Filtro de día
   if(!IsTradingDay(utcDT.day_of_week))
   {
      if(VIS_Enable && VIS_ShowLabel)
         VisUpdatePanel("", 0, 0, false, true, "Dia no operado");
      return;
   }

   datetime curBar = iTime(_Symbol, PERIOD_M5, 0);
   bool newBar     = (curBar != g_lastBarTime);
   if(newBar) g_lastBarTime = curBar;

   //--- Formar el rango (una vez por día, a partir de las 14:50 UTC)
   if(!g_rangeFormed && !g_rangeAttempted)
   {
      int totalMin = utcDT.hour * 60 + utcDT.min;
      if(totalMin >= 14 * 60 + 50)
      {
         TryFormRange(utcDT);
         if(g_rangeFormed)
            g_nyOpenTime = curBar;
      }
   }
   if(!g_rangeFormed) return;

   //--- Ventana de entrada: 14:50 UTC → 14:50 + EntryWindowEnd_Min
   int totMin = utcDT.hour * 60 + utcDT.min;
   if(totMin < 14 * 60 + 50 || totMin >= 14 * 60 + 50 + EntryWindowEnd_Min) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //===================================================================
   //  MODELO 1: Confirmación al cierre de vela M5
   //===================================================================
   if(EntryModel == ENTRY_CONFIRM_CLOSE)
   {
      // FASE B — Confirmación al abrir nueva vela
      if(g_brkPending && curBar != g_brkBarTime)
      {
         bool stillValid = (g_brkDir == 1  && ask > g_rangeHigh) ||
                           (g_brkDir == -1 && bid < g_rangeLow);
         if(stillValid)
            ExecuteTrade(g_brkDir);
         else
         {
            PrintFormat("Falsa ruptura cancelada en vela %d — precio regreso al rango", g_brkCandleNum);
            g_brkPending   = false;
            g_brkDir       = 0;
            g_brkCandleNum = 0;
         }
         return;
      }

      // FASE A — Detección de ruptura
      if(!g_brkPending)
      {
         bool bullBreak = (ask > g_rangeHigh) && (TradeDirection != DIRECTION_SHORT);
         bool bearBreak = (bid < g_rangeLow)  && (TradeDirection != DIRECTION_LONG);

         if(bullBreak || bearBreak)
         {
            int candleNum = 1;
            if(EntryMaxCandle > 0 && g_nyOpenTime > 0)
            {
               int secs = (int)(curBar - g_nyOpenTime);
               candleNum = (secs / 300) + 1;
               candleNum = MathMax(1, candleNum);
               if(candleNum > EntryMaxCandle)
               {
                  static datetime lastSkipLog = 0;
                  if(curBar != lastSkipLog)
                  {
                     PrintFormat("Breakout tardio ignorado: vela %d > EntryMaxCandle=%d (%s)",
                                 candleNum, EntryMaxCandle, bullBreak ? "BUY" : "SELL");
                     lastSkipLog = curBar;
                  }
                  return;
               }
            }

            g_brkPending   = true;
            g_brkDir       = bullBreak ? 1 : -1;
            g_brkBarTime   = curBar;
            g_brkCandleNum = candleNum;
            PrintFormat("BREAKOUT detectado: %s | vela %d | ask=%.5f bid=%.5f | rango [%.5f-%.5f]",
                        bullBreak ? "BUY" : "SELL", candleNum, ask, bid, g_rangeLow, g_rangeHigh);
         }
      }
   }
   //===================================================================
   //  MODELO 2: Ruptura directa (primer tick)
   //===================================================================
   else
   {
      bool bullBreak = (ask > g_rangeHigh) && (TradeDirection != DIRECTION_SHORT);
      bool bearBreak = (bid < g_rangeLow)  && (TradeDirection != DIRECTION_LONG);

      if(bullBreak)      ExecuteTrade(1);
      else if(bearBreak) ExecuteTrade(-1);
   }

   if(VIS_Enable && VIS_ShowLabel && !g_brkPending)
      VisUpdatePanel("", 0, 0, false, false, "");
}

//===================================================================
//  TryFormRange
//===================================================================

void TryFormRange(MqlDateTime &utcDT)
{
   datetime srvMid = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",
                                               utcDT.year, utcDT.mon, utcDT.day));
   datetime c1 = srvMid + (14 + ServerOffsetHours) * 3600 + 35 * 60;
   datetime c2 = srvMid + (14 + ServerOffsetHours) * 3600 + 40 * 60;
   datetime c3 = srvMid + (14 + ServerOffsetHours) * 3600 + 45 * 60;

   int i1 = iBarShift(_Symbol, PERIOD_M5, c1, false);
   int i2 = iBarShift(_Symbol, PERIOD_M5, c2, false);
   int i3 = iBarShift(_Symbol, PERIOD_M5, c3, false);
   if(i1 < 0 || i2 < 0 || i3 < 0) return;

   g_rangeAttempted = true;

   if(MathAbs((int)(iTime(_Symbol, PERIOD_M5, i1) - c1)) > 300 ||
      MathAbs((int)(iTime(_Symbol, PERIOD_M5, i2) - c2)) > 300 ||
      MathAbs((int)(iTime(_Symbol, PERIOD_M5, i3) - c3)) > 300)
   {
      Print("RANGE SKIP: desfase de velas — verificar ServerOffsetHours");
      return;
   }

   g_rangeHigh  = MathMax(iHigh(_Symbol, PERIOD_M5, i1),
                  MathMax(iHigh(_Symbol, PERIOD_M5, i2), iHigh(_Symbol, PERIOD_M5, i3)));
   g_rangeLow   = MathMin(iLow(_Symbol,  PERIOD_M5, i1),
                  MathMin(iLow(_Symbol,  PERIOD_M5, i2), iLow(_Symbol,  PERIOD_M5, i3)));

   // Rango en precio (unidades reales) y en pips
   g_slDistance = g_rangeHigh - g_rangeLow;
   g_slPips     = g_slDistance / g_pipSize;

   // Filtro de rango en pips
   if(g_slPips < MinSL_Pips)
   {
      PrintFormat("RANGE SKIP: %.1f pips < MinSL=%.1f pips", g_slPips, MinSL_Pips);
      if(VIS_Enable) VisUpdatePanel("", 0, 0, false, true,
         StringFormat("Rango filtrado (%.1f < %.1f pips)", g_slPips, MinSL_Pips));
      return;
   }
   if(g_slPips > MaxSL_Pips)
   {
      PrintFormat("RANGE SKIP: %.1f pips > MaxSL=%.1f pips", g_slPips, MaxSL_Pips);
      if(VIS_Enable) VisUpdatePanel("", 0, 0, false, true,
         StringFormat("Rango filtrado (%.1f > %.1f pips)", g_slPips, MaxSL_Pips));
      return;
   }

   if(ATR_FilterEnable && !CheckATRFilter()) return;

   // Lote calculado en base a pips
   g_cachedLots = CalculateLotSize(g_slPips);
   if(g_cachedLots <= 0) { Print("RANGE SKIP: calculo de lotes fallido"); return; }

   g_rangeFormed = true;
   vis_dayTag    = VisMakeDayTag();

   PrintFormat("RANGE VALIDO: H=%.5f L=%.5f | %.1f pips | lots=%.3f | riesgo=$%.2f",
               g_rangeHigh, g_rangeLow, g_slPips, g_cachedLots,
               g_cachedLots * g_slPips * g_cachedVPP);
}

//===================================================================
//  CheckATRFilter
//===================================================================

bool CheckATRFilter()
{
   if(g_atrHandle == INVALID_HANDLE) return true;

   double cur[]; ArraySetAsSeries(cur, true);
   if(CopyBuffer(g_atrHandle, 0, 1, 1, cur) <= 0) return true;

   double base[]; ArraySetAsSeries(base, true);
   int copied = CopyBuffer(g_atrHandle, 0, 1, ATR_BaselineDays * 78, base);
   if(copied < 10) return true;

   double sum = 0;
   for(int i = 0; i < copied; i++) sum += base[i];
   double baseline = sum / copied;

   if(cur[0] < baseline * ATR_MinMultiplier)
   {
      PrintFormat("RANGE SKIP: ATR bajo (%.5f < baseline=%.5f x %.1f)", cur[0], baseline, ATR_MinMultiplier);
      if(VIS_Enable) VisUpdatePanel("", 0, 0, false, true, "ATR filtrado (volatilidad baja)");
      return false;
   }
   if(cur[0] > baseline * ATR_MaxMultiplier)
   {
      PrintFormat("RANGE SKIP: ATR alto (%.5f > baseline=%.5f x %.1f)", cur[0], baseline, ATR_MaxMultiplier);
      if(VIS_Enable) VisUpdatePanel("", 0, 0, false, true, "ATR filtrado (volatilidad alta)");
      return false;
   }
   return true;
}

//===================================================================
//  ExecuteTrade
//===================================================================

void ExecuteTrade(int dir)
{
   if(g_cachedLots <= 0) return;
   if(dir == 1  && TradeDirection == DIRECTION_SHORT) return;
   if(dir == -1 && TradeDirection == DIRECTION_LONG)  return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double slD = g_slDistance;  // distancia en precio

   if(dir == 1)  // BUY
   {
      g_entryPrice = ask;
      g_originalSL = NormalizeDouble(ask - slD,                         _Digits);
      g_beLevel    = NormalizeDouble(ask + slD * (BE_BufferPct / 100.0), _Digits);
      g_tp1Level   = NormalizeDouble(ask + slD * TP1_RR,                _Digits);
      g_tp2Level   = NormalizeDouble(ask + slD * TP2_RR,                _Digits);
      g_tp3Level   = NormalizeDouble(ask + slD * TP3_RR,                _Digits);

      if(trade.Buy(g_cachedLots, _Symbol, ask, g_originalSL, g_tp3Level, "BreakoutNY_BUY"))
      {
         g_tradedToday = true; g_brkPending = false;
         g_beActivated = false; g_tp2Hit = false; g_tp1Hit = false;
         g_tradeDir = "buy";
         PrintFormat("BUY %.3f | SL=%.5f (%.1f pips) BE=%.5f TP1=%.5f TP2=%.5f TP3=%.5f",
                     g_cachedLots, g_originalSL, g_slPips, g_beLevel,
                     g_tp1Level, g_tp2Level, g_tp3Level);
         vis_hasTrade = true; VisRedrawToday();
         LogTrade("BUY");
      }
      else
         PrintFormat("ERROR Buy: %d — %s", trade.ResultRetcode(), trade.ResultRetcodeDescription());
   }
   else  // SELL
   {
      g_entryPrice = bid;
      g_originalSL = NormalizeDouble(bid + slD,                         _Digits);
      g_beLevel    = NormalizeDouble(bid - slD * (BE_BufferPct / 100.0), _Digits);
      g_tp1Level   = NormalizeDouble(bid - slD * TP1_RR,                _Digits);
      g_tp2Level   = NormalizeDouble(bid - slD * TP2_RR,                _Digits);
      g_tp3Level   = NormalizeDouble(bid - slD * TP3_RR,                _Digits);

      if(trade.Sell(g_cachedLots, _Symbol, bid, g_originalSL, g_tp3Level, "BreakoutNY_SELL"))
      {
         g_tradedToday = true; g_brkPending = false;
         g_beActivated = false; g_tp2Hit = false; g_tp1Hit = false;
         g_tradeDir = "sell";
         PrintFormat("SELL %.3f | SL=%.5f (%.1f pips) BE=%.5f TP1=%.5f TP2=%.5f TP3=%.5f",
                     g_cachedLots, g_originalSL, g_slPips, g_beLevel,
                     g_tp1Level, g_tp2Level, g_tp3Level);
         vis_hasTrade = true; VisRedrawToday();
         LogTrade("SELL");
      }
      else
         PrintFormat("ERROR Sell: %d — %s", trade.ResultRetcode(), trade.ResultRetcodeDescription());
   }
}

//===================================================================
//  ManagePosition — BE + parciales
//===================================================================

void ManagePosition()
{
   if(!HasOpenPosition()) return;

   double curSL  = PositionGetDouble(POSITION_SL);
   long   posTyp = PositionGetInteger(POSITION_TYPE);

   if(posTyp == POSITION_TYPE_BUY)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      if(!g_beActivated && bid >= g_beLevel)
      {
         g_beActivated = true;
         double nSL = NormalizeDouble(g_entryPrice, _Digits);
         if(nSL > curSL + _Point)
         {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "")
               VisMoveLevel(VIS_PFX + "SL_" + vis_dayTag, nSL);
            PrintFormat("BE activado — SL movido a entry %.5f", nSL);
         }
      }

      if(!g_tp1Hit && EnablePartials && bid >= g_tp1Level)
      {
         g_tp1Hit = true;
         DoPartialClose(TP1_ClosePct);
         Print("TP1 alcanzado — parcial ejecutado (", TP1_ClosePct, "%)");
      }

      if(!g_tp2Hit && bid >= g_tp2Level)
      {
         g_tp2Hit = true;
         double nSL = NormalizeDouble(g_tp1Level, _Digits);
         if(nSL > curSL + _Point)
         {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "")
               VisMoveLevel(VIS_PFX + "SL_" + vis_dayTag, nSL);
            PrintFormat("TP2 alcanzado — SL asegurado en TP1 %.5f", nSL);
         }
         if(EnablePartials) DoPartialClose(TP2_ClosePct);
      }
   }
   else if(posTyp == POSITION_TYPE_SELL)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(!g_beActivated && ask <= g_beLevel)
      {
         g_beActivated = true;
         double nSL = NormalizeDouble(g_entryPrice, _Digits);
         if(nSL < curSL - _Point)
         {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "")
               VisMoveLevel(VIS_PFX + "SL_" + vis_dayTag, nSL);
            PrintFormat("BE activado — SL movido a entry %.5f", nSL);
         }
      }

      if(!g_tp1Hit && EnablePartials && ask <= g_tp1Level)
      {
         g_tp1Hit = true;
         DoPartialClose(TP1_ClosePct);
         Print("TP1 alcanzado — parcial ejecutado (", TP1_ClosePct, "%)");
      }

      if(!g_tp2Hit && ask <= g_tp2Level)
      {
         g_tp2Hit = true;
         double nSL = NormalizeDouble(g_tp1Level, _Digits);
         if(nSL < curSL - _Point)
         {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "")
               VisMoveLevel(VIS_PFX + "SL_" + vis_dayTag, nSL);
            PrintFormat("TP2 alcanzado — SL asegurado en TP1 %.5f", nSL);
         }
         if(EnablePartials) DoPartialClose(TP2_ClosePct);
      }
   }
}

//===================================================================
//  Helpers
//===================================================================

void DoPartialClose(int pct)
{
   if(pct <= 0 || pct > 100) return;
   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double cur   = PositionGetDouble(POSITION_VOLUME);
   double toClose = MathFloor(cur * pct / 100.0 / vStep) * vStep;
   if(toClose >= vMin) trade.PositionClosePartial(_Symbol, toClose);
}

bool HasOpenPosition()
{
   if(!PositionSelect(_Symbol)) return false;
   return((int)PositionGetInteger(POSITION_MAGIC) == MagicNumber);
}

void ClosePosition(string reason)
{
   if(!HasOpenPosition()) return;
   double pnl = PositionGetDouble(POSITION_PROFIT);
   if(trade.PositionClose(_Symbol))
      PrintFormat("CERRADO: %s | P&L=$%.2f", reason, pnl);
   if(VIS_Enable && vis_dayTag != "")
   {
      VisDeleteDay(vis_dayTag);
      VisRedrawToday();
      VisDrawMottoPanel();
   }
}

bool IsTradingDay(int dow)
{
   if(dow == 0 || dow == 6) return false;
   if(dow == 1 && !FilterMonday)    return false;
   if(dow == 2 && !FilterTuesday)   return false;
   if(dow == 3 && !FilterWednesday) return false;
   if(dow == 4 && !FilterThursday)  return false;
   if(dow == 5 && !FilterFriday)    return false;
   return true;
}

void LogTrade(string dir)
{
   if(!EnableCSV || g_csvHandle == INVALID_HANDLE) return;
   datetime utcNow = TimeCurrent() - ServerOffsetHours * 3600;
   MqlDateTime dt; TimeToStruct(utcNow, dt);
   string dn[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
   double atr = 0;
   if(g_atrHandle != INVALID_HANDLE)
   {
      double atrBuf[]; ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(g_atrHandle, 0, 1, 1, atrBuf) > 0) atr = atrBuf[0];
   }
   string modStr = (EntryModel == ENTRY_CONFIRM_CLOSE) ? "CONFIRM" : "BREAKOUT";
   double risk   = g_cachedLots * g_slPips * g_cachedVPP;
   FileWrite(g_csvHandle,
             TimeToString(utcNow, TIME_DATE), dn[dt.day_of_week], dir,
             DoubleToString(g_cachedLots, 3), DoubleToString(g_cachedVPP, 4), DoubleToString(risk, 2),
             DoubleToString(g_entryPrice, _Digits), DoubleToString(g_originalSL, _Digits),
             DoubleToString(g_beLevel,    _Digits), DoubleToString(g_tp1Level,   _Digits),
             DoubleToString(g_tp2Level,   _Digits), DoubleToString(g_tp3Level,   _Digits),
             DoubleToString(g_slPips, 1), modStr,
             IntegerToString(g_brkCandleNum), DoubleToString(atr, 5));
   FileFlush(g_csvHandle);
}

//===================================================================
//  MÓDULO VISUAL
//===================================================================

string VisMakeDayTag()
{
   MqlDateTime u;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, u);
   return StringFormat("%04d%02d%02d", u.year, u.mon, u.day);
}

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

void VisLevel(const string name,
              datetime t1, datetime t2, double price,
              color clr, ENUM_LINE_STYLE style, int width,
              const string label)
{
   VisSegment(name, t1, t2, price, price, clr, style, width, false);
   datetime tLabel = t2 + (datetime)(PeriodSeconds(PERIOD_M5));
   string   priceStr = DoubleToString(price, _Digits);
   VisText(name + "_LBL", tLabel, price,
           " " + label + " " + priceStr,
           clr, 7, ANCHOR_LEFT_UPPER, false);
}

void VisMoveLevel(const string name, double newPrice)
{
   if(ObjectFind(0, name) < 0) return;
   ObjectSetDouble(0, name, OBJPROP_PRICE, newPrice, 0);
   ObjectSetDouble(0, name, OBJPROP_PRICE, newPrice, 1);
   string lblName = name + "_LBL";
   if(ObjectFind(0, lblName) < 0) return;
   ObjectSetDouble(0, lblName, OBJPROP_PRICE, newPrice);
   string currTxt  = ObjectGetString(0, lblName, OBJPROP_TEXT);
   int    sep      = StringFind(currTxt, " ");
   string lbl      = sep >= 0 ? StringSubstr(currTxt, 0, sep + 1) : currTxt;
   string priceStr = DoubleToString(newPrice, _Digits);
   ObjectSetString(0, lblName, OBJPROP_TEXT, lbl + priceStr + " ");
   ChartRedraw();
}

bool VisGetCandle(const MqlRates &R[], int total,
                  datetime dayUTC, int h, int m,
                  double &hi, double &lo, datetime &barTime)
{
   for(int i = 0; i < total; i++)
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      datetime barDay = StringToTime(
         StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
      if(barDay != dayUTC) continue;
      if(u.hour == h && u.min == m)
      {
         hi = R[i].high; lo = R[i].low; barTime = R[i].time;
         return true;
      }
   }
   return false;
}

void VisDrawDay(const MqlRates &R[], int total, datetime dayUTC)
{
   double h35, l35, h40, l40, h45, l45;
   datetime t35, t40, t45;
   if(!VisGetCandle(R, total, dayUTC, 14, 35, h35, l35, t35)) return;
   if(!VisGetCandle(R, total, dayUTC, 14, 40, h40, l40, t40)) return;
   if(!VisGetCandle(R, total, dayUTC, 14, 45, h45, l45, t45)) return;

   double rH   = MathMax(h35, MathMax(h40, h45));
   double rL   = MathMin(l35, MathMin(l40, l45));
   double slD  = rH - rL;

   MqlDateTime dt; TimeToStruct(dayUTC, dt);
   string tag = StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);

   datetime tRangeEnd = t45 + 300;

   // Zona del rango
   string nBox = VIS_PFX + "BOX_" + tag;
   if(ObjectFind(0, nBox) < 0)
      ObjectCreate(0, nBox, OBJ_RECTANGLE, 0, t35, rH, tRangeEnd, rL);
   ObjectSetInteger(0, nBox, OBJPROP_COLOR,      VIS_ColRange);
   ObjectSetInteger(0, nBox, OBJPROP_BGCOLOR,    VIS_ColRange);
   ObjectSetInteger(0, nBox, OBJPROP_FILL,       true);
   ObjectSetInteger(0, nBox, OBJPROP_BACK,       true);
   ObjectSetInteger(0, nBox, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nBox, OBJPROP_HIDDEN,     true);

   VisSegment(VIS_PFX + "RH_" + tag, t35, tRangeEnd, rH, rH, VIS_ColRangeBorder, STYLE_SOLID, 2, true);
   VisSegment(VIS_PFX + "RL_" + tag, t35, tRangeEnd, rL, rL, VIS_ColRangeBorder, STYLE_SOLID, 2, true);
   VisText(VIS_PFX + "LRHI_" + tag, t35, rH, "  RANGE HIGH", VIS_ColRangeBorder, 8, ANCHOR_LEFT_LOWER, false);
   VisText(VIS_PFX + "LRLO_" + tag, t35, rL, "  RANGE LOW",  VIS_ColRangeBorder, 8, ANCHOR_LEFT_UPPER, false);

   // Buscar ruptura en ventana 14:50 – 14:50+EntryWindowEnd_Min UTC
   double   eEntry = 0, eSL = 0, eTp1 = 0, eTp2 = 0, eTp3 = 0, eBE = 0;
   string   eDir   = "";
   datetime eBreak = 0;
   bool     broke  = false;

   for(int i = total - 1; i >= 0; i--)
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      datetime barDay = StringToTime(
         StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
      if(barDay != dayUTC) continue;

      int totalMin = u.hour * 60 + u.min;
      int winStart = 14 * 60 + 50;
      int winEnd   = winStart + EntryWindowEnd_Min;
      if(totalMin < winStart || totalMin >= winEnd) continue;

      bool bullOK = (R[i].high > rH) && (TradeDirection != DIRECTION_SHORT);
      bool bearOK = (R[i].low  < rL) && (TradeDirection != DIRECTION_LONG);

      if(bullOK || bearOK)
      {
         double entryPx;
         if(EntryModel == ENTRY_CONFIRM_CLOSE)
            entryPx = (i + 1 < total) ? R[i + 1].open : R[i].close;
         else
            entryPx = bullOK ? R[i].high : R[i].low;

         eEntry = entryPx;
         eDir   = bullOK ? "buy" : "sell";
         eBreak = R[i].time;

         if(bullOK)
         {
            eSL  = NormalizeDouble(eEntry - slD,                          _Digits);
            eTp1 = NormalizeDouble(eEntry + slD * TP1_RR,                 _Digits);
            eTp2 = NormalizeDouble(eEntry + slD * TP2_RR,                 _Digits);
            eTp3 = NormalizeDouble(eEntry + slD * TP3_RR,                 _Digits);
            eBE  = NormalizeDouble(eEntry + slD * (BE_BufferPct / 100.0), _Digits);
         }
         else
         {
            eSL  = NormalizeDouble(eEntry + slD,                          _Digits);
            eTp1 = NormalizeDouble(eEntry - slD * TP1_RR,                 _Digits);
            eTp2 = NormalizeDouble(eEntry - slD * TP2_RR,                 _Digits);
            eTp3 = NormalizeDouble(eEntry - slD * TP3_RR,                 _Digits);
            eBE  = NormalizeDouble(eEntry - slD * (BE_BufferPct / 100.0), _Digits);
         }
         broke = true;
         break;
      }
   }

   if(broke)
   {
      bool     isBuy = (eDir == "buy");
      datetime tEnd  = eBreak + (datetime)(VIS_ExtendBars * PeriodSeconds(PERIOD_M5));

      // Flecha de dirección
      double   arrPx = isBuy ? rH : rL;
      datetime tArr  = t35 - (datetime)(2 * PeriodSeconds(PERIOD_M5));
      string   nArr  = VIS_PFX + "ARR_" + tag;
      if(ObjectFind(0, nArr) < 0)
         ObjectCreate(0, nArr, OBJ_ARROW, 0, tArr, arrPx);
      ObjectSetDouble(0,  nArr, OBJPROP_PRICE,      arrPx);
      ObjectSetInteger(0, nArr, OBJPROP_TIME,       tArr, 0);
      ObjectSetInteger(0, nArr, OBJPROP_ARROWCODE,  232);
      ObjectSetInteger(0, nArr, OBJPROP_COLOR,      isBuy ? VIS_ColTP3 : VIS_ColSL);
      ObjectSetInteger(0, nArr, OBJPROP_WIDTH,      3);
      ObjectSetInteger(0, nArr, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nArr, OBJPROP_HIDDEN,     true);

      // Línea vertical de ruptura
      string nVL = VIS_PFX + "VL_" + tag;
      if(ObjectFind(0, nVL) < 0)
         ObjectCreate(0, nVL, OBJ_VLINE, 0, eBreak, 0);
      ObjectSetInteger(0, nVL, OBJPROP_COLOR,      isBuy ? C'40,140,80' : C'180,50,70');
      ObjectSetInteger(0, nVL, OBJPROP_STYLE,      STYLE_DOT);
      ObjectSetInteger(0, nVL, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, nVL, OBJPROP_BACK,       true);
      ObjectSetInteger(0, nVL, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nVL, OBJPROP_HIDDEN,     true);

      // Niveles
      VisLevel(VIS_PFX + "SL_"  + tag, eBreak, tEnd, eSL,    VIS_ColSL,    STYLE_DASH,  2, "SL");
      VisLevel(VIS_PFX + "EN_"  + tag, eBreak, tEnd, eEntry, VIS_ColEntry, STYLE_SOLID, 1, "ENTRY");
      if(VIS_ShowBE)
         VisLevel(VIS_PFX + "BE_" + tag, eBreak, tEnd, eBE, VIS_ColBE, STYLE_DOT, 1, "BE");
      VisLevel(VIS_PFX + "TP1_" + tag, eBreak, tEnd, eTp1, VIS_ColTP1, STYLE_SOLID, 1, "TP1");
      VisLevel(VIS_PFX + "TP2_" + tag, eBreak, tEnd, eTp2, VIS_ColTP2, STYLE_SOLID, 1, "TP2");
      VisLevel(VIS_PFX + "TP3_" + tag, eBreak, tEnd, eTp3, VIS_ColTP3, STYLE_SOLID, 3, "TP3");

      // Marcador de cierre de sesión
      datetime tClose = StringToTime(StringFormat("%04d.%02d.%02d %02d:%02d:00",
                        dt.year, dt.mon, dt.day,
                        SessionCloseHour + ServerOffsetHours, SessionCloseMin));
      string nSC = VIS_PFX + "SC_" + tag;
      if(ObjectFind(0, nSC) < 0)
         ObjectCreate(0, nSC, OBJ_VLINE, 0, tClose, 0);
      ObjectSetInteger(0, nSC, OBJPROP_COLOR,      C'100,100,140');
      ObjectSetInteger(0, nSC, OBJPROP_STYLE,      STYLE_DASH);
      ObjectSetInteger(0, nSC, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, nSC, OBJPROP_BACK,       true);
      ObjectSetInteger(0, nSC, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nSC, OBJPROP_HIDDEN,     true);
      VisText(VIS_PFX + "SCL_" + tag, tClose, eTp3,
              StringFormat(" %d:%02d UTC", SessionCloseHour, SessionCloseMin),
              C'100,100,160', 7, ANCHOR_LEFT_UPPER, false);

      string modLabel = (EntryModel == ENTRY_CONFIRM_CLOSE) ? " Confirm-Close" : " Breakout-Tick";
      VisText(VIS_PFX + "MOD_" + tag, t35, rH,
              modLabel, C'150,170,210', 7, ANCHOR_LEFT_LOWER, false);
   }
   else
   {
      VisText(VIS_PFX + "NOBRK_" + tag, tRangeEnd + 300, (rH + rL) / 2.0,
              "  sin ruptura", C'80,100,130', 7, ANCHOR_LEFT, false);
   }
}

void VisRedrawAll()
{
   if(!VIS_Enable) return;
   VisPurgeAll();

   MqlRates R[];
   ArraySetAsSeries(R, true);
   int copied = CopyRates(_Symbol, PERIOD_M5, 0, VIS_LookbackDays * 120, R);
   if(copied <= 0) return;

   datetime days[];
   int nDays = 0;
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

   PrintFormat("VIS: Redibujando %d dias historicos (últimos %d dias)", nDays, VIS_LookbackDays);
   for(int i = 0; i < nDays; i++)
      VisDrawDay(R, copied, days[i]);

   VisDrawMottoPanel();
   VisUpdatePanel("", 0, 0, false, false, "");
   ChartRedraw();
}

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

void VisUpdatePanel(string direction, double slPipsVal, double netPL,
                    bool hasTrade, bool isFiltered, string filterReason)
{
   if(!VIS_Enable || !VIS_ShowLabel) return;

   MqlDateTime u; TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, u);
   string dayNames[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
   string dayStr  = dayNames[u.day_of_week];
   string dateStr = StringFormat("%02d/%02d/%04d", u.day, u.mon, u.year);

   string dirStr = (TradeDirection == DIRECTION_LONG)  ? "Solo Compra" :
                   (TradeDirection == DIRECTION_SHORT) ? "Solo Venta" : "Compra y Venta";
   string modStr = (EntryModel == ENTRY_CONFIRM_CLOSE) ? "Confirm" : "Breakout";

   string line1, line2, line3, line4, line5;
   color  panelColor;

   if(isFiltered)
   {
      line1      = "BreakoutNY GBPUSD v1.0";
      line2      = dayStr + " " + dateStr + "  |  " + dirStr + "  |  " + modStr;
      line3      = "  " + filterReason;
      line4      = "Riesgo: $" + DoubleToString(RiskAmountUSD, 0) + "/trade";
      line5      = "";
      panelColor = C'100,100,140';
   }
   else if(!hasTrade && direction == "")
   {
      line1 = "BreakoutNY GBPUSD v1.0  |  " + _Symbol;
      line2 = dayStr + " " + dateStr + "  |  Esperando 14:50 UTC";
      line3 = dirStr + "  |  " + modStr +
              "  |  SL " + DoubleToString(MinSL_Pips, 1) +
              "-" + DoubleToString(MaxSL_Pips, 1) + " pips";
      line4 = "Riesgo $" + DoubleToString(RiskAmountUSD, 0) +
              "  |  TP1 1:" + DoubleToString(TP1_RR, 0) +
              "  TP2 1:" + DoubleToString(TP2_RR, 0) +
              "  TP3 1:" + DoubleToString(TP3_RR, 0);
      line5 = "";
      panelColor = C'100,130,180';
   }
   else
   {
      bool   isBuy  = (direction == "buy");
      string arrow  = isBuy ? "▲ BUY" : "▼ SELL";
      string plStr  = (netPL >= 0)
         ? "+ $" + DoubleToString(netPL, 0)
         : "- $" + DoubleToString(MathAbs(netPL), 0);
      line1 = "BreakoutNY GBPUSD v1.0  |  " + _Symbol + "  |  " + dayStr;
      line2 = arrow + "  |  SL " + DoubleToString(slPipsVal, 1) + " pips" +
              "  |  TP3 " + DoubleToString(slPipsVal * TP3_RR, 1) + " pips";
      line3 = "Riesgo $" + DoubleToString(RiskAmountUSD, 0) +
              "  |  BE " + DoubleToString(BE_BufferPct, 0) + "%" +
              "  |  " + modStr;
      line4 = hasTrade ? ("P/L flotante:  " + plStr) : "Sin posicion abierta";
      line5 = "";
      panelColor = isBuy ? VIS_ColTP3 : VIS_ColSL;
   }

   string pnames[] = {"PNL1","PNL2","PNL3","PNL4","PNL5"};
   string ptexts[5]; ptexts[0] = line1; ptexts[1] = line2;
   ptexts[2] = line3; ptexts[3] = line4; ptexts[4] = line5;
   int pyoffs[] = {15, 30, 45, 60, 75};
   int pfonts[] = {9,  9,  8,  9,   8};

   for(int i = 0; i < 5; i++)
   {
      if(ptexts[i] == "") { ObjectDelete(0, VIS_PFX + pnames[i]); continue; }
      string nm = VIS_PFX + pnames[i];
      if(ObjectFind(0, nm) < 0)
         ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, 12);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, pyoffs[i]);
      ObjectSetString(0,  nm, OBJPROP_TEXT,      ptexts[i]);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,     (i == 0) ? C'195,208,230' : panelColor);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,  pfonts[i]);
      ObjectSetString(0,  nm, OBJPROP_FONT,      "Consolas");
      ObjectSetInteger(0, nm, OBJPROP_ANCHOR,    ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN,    false);
      ObjectSetInteger(0, nm, OBJPROP_BACK,      false);
   }
}

void VisDrawMottoPanel()
{
   if(!VIS_Enable) return;

   string nm1 = VIS_PFX + "MOTTO1";
   if(ObjectFind(0, nm1) < 0) ObjectCreate(0, nm1, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm1, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nm1, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, nm1, OBJPROP_YDISTANCE, 38);
   ObjectSetString(0,  nm1, OBJPROP_TEXT,
      "\"El filtro ATR no te protege de las perdidas — te protege de las que no merecen ocurrir.\"");
   ObjectSetInteger(0, nm1, OBJPROP_COLOR,     C'80,100,140');
   ObjectSetInteger(0, nm1, OBJPROP_FONTSIZE,  8);
   ObjectSetString(0,  nm1, OBJPROP_FONT,      "Consolas");
   ObjectSetInteger(0, nm1, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm1, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm1, OBJPROP_BACK,      false);

   string nm2 = VIS_PFX + "MOTTO2";
   if(ObjectFind(0, nm2) < 0) ObjectCreate(0, nm2, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm2, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nm2, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, nm2, OBJPROP_YDISTANCE, 24);
   ObjectSetString(0,  nm2, OBJPROP_TEXT,
      "\"Las que quedan son el precio de admision.\"");
   ObjectSetInteger(0, nm2, OBJPROP_COLOR,     C'80,100,140');
   ObjectSetInteger(0, nm2, OBJPROP_FONTSIZE,  8);
   ObjectSetString(0,  nm2, OBJPROP_FONT,      "Consolas");
   ObjectSetInteger(0, nm2, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm2, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm2, OBJPROP_BACK,      false);

   string nm3 = VIS_PFX + "MOTTO3";
   if(ObjectFind(0, nm3) < 0) ObjectCreate(0, nm3, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm3, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nm3, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, nm3, OBJPROP_YDISTANCE, 10);
   ObjectSetString(0,  nm3, OBJPROP_TEXT,
      StringFormat("BreakoutNY GBPUSD v1.0  ·  %s FundingPips  ·  Magic %d  ·  Jose Yanez",
                   _Symbol, (int)MagicNumber));
   ObjectSetInteger(0, nm3, OBJPROP_COLOR,     C'55,75,110');
   ObjectSetInteger(0, nm3, OBJPROP_FONTSIZE,  7);
   ObjectSetString(0,  nm3, OBJPROP_FONT,      "Consolas");
   ObjectSetInteger(0, nm3, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm3, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm3, OBJPROP_BACK,      false);

   ChartRedraw();
}
//+------------------------------------------------------------------+
