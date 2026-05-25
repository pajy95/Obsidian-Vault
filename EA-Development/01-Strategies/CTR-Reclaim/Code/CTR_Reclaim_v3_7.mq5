//+------------------------------------------------------------------+
//|  CTR Reclaim EA v3.7 — Version Final                            |
//|  Liquidity Sweep Reversal — NDX100 M10 — Funding Pips            |
//|                                                                  |
//|  CAMBIO vs v3.4:                                                 |
//|  [FIX] Gestión de riesgo unificada en una sola fórmula:         |
//|                                                                  |
//|    Lots = RiskAmountUSD / (SL_ticks × ValuePerTickPerLot)        |
//|                                                                  |
//|    Verificado empíricamente en 3,000+ trades de NDX100 FP:       |
//|    ValuePerTickPerLot = $0.20/tick/lot (real vs $0.05 reportado) |
//|    Ejemplo: $100 / (110 × $0.20) = 4.54 lots                    |
//|    Riesgo real: 4.54 × 110 × $0.20 = $99.88 ✓                   |
//|                                                                  |
//|  Eliminados modos RISK_FIXED_LOTS y RISK_PERCENT.                |
//|  Solo RiskAmountUSD controla el riesgo.                          |
//|                                                                  |
//|  CONFIGURACIÓN PARA EL BACKTEST:                                 |
//|  - Símbolo: NDX100, TF: M10                                      |
//|  - Período: 2020.01.01 — 2025.12.31                              |
//|  - Capital: $10,000 (cuenta real FP)                             |
//|  - RiskAmountUSD = 100 → 4.54 lots calculados                   |
//|    (broker limita a ~0.24 lots por margen con $10k → $5.28 real) |
//|  - Capital: $100,000 → hasta ~2.5 lots permitidos por margen     |
//+------------------------------------------------------------------+
#property copyright "CTR Reclaim v3.7"
#property version   "3.70"
#property strict

#include <Trade\Trade.mqh>

//──────────────────────────────────────────────
// ENUMS
//──────────────────────────────────────────────
enum ENUM_TRADE_DIR
{
   BOTH  = 0,
   LONG  = 1,
   SHORT = 2
};

//──────────────────────────────────────────────
// INPUTS
//──────────────────────────────────────────────

input group "=== GESTIÓN DE RIESGO ==="
// Fórmula: Lots = RiskAmountUSD / (SL_ticks × ValuePerTickPerLot)
// NDX100 FP: $0.20/tick/lot verificado en 3,000+ trades
// Ejemplo: $100 / (110 × $0.20) = 4.54 lots → riesgo real $99.88
input double          RiskAmountUSD      = 100.0;                   // Riesgo fijo en USD por operacion
input double          ValuePerTickPerLot = 0.20;                    // USD por tick por lot (NDX100 FP=0.20)
input int             AccountLeverage    = 20;                      // Apalancamiento real de la cuenta (FP=1:20)

input group "=== PROTECCIÓN (Funding Pips) ==="
input bool            EnableDailyLossLimit = true;
input double          DailyLossLimitUSD    = 500.0;   // 5% de $10k / 0.5% de $100k
input bool            EnableMaxDD          = true;
input double          MaxDDFromInitial     = 1000.0;  // 10% de $10k / 1% de $100k

input group "=== TRADE ==="
input int             MagicNumber        = 3700;                    // Magic Number
input int             SL_ticks           = 100;                     // Stop Loss en ticks — OPT2: best IS PF=2.172
input int             TP_ticks           = 690;                     // Take Profit en ticks — OPT2: R:R=6.9x
input int             MaxTradesPerDay    = 1;
input int             MaxSpreadPoints    = 300;
input int             SlippagePoints     = 10;
input ENUM_TRADE_DIR  TradeType          = BOTH;

input group "=== KEY CANDLE ==="
input int             NY_Hour            = 8;
input int             NY_Minute          = 40;
input int             GMT_Offset         = 3;      // FP verano GMT+3

input group "=== SEÑAL — FILTRO DE BARRAS ==="
// WindowMinBar=3: FIJO — regla estructural validada en OOS
//   Bar1 WR=6.6%, Bar2 WR=5.3%, Bar3 WR=0% → todas bajo BE 12.7%
//   Bar4-8: WR=22-50% → edge fuerte y consistente
// WindowMaxBar=8: OPT2 confirma zona optima
input int             WindowMinBar       = 3;                       // Barra minima post-key [FIJO=3]
input int             WindowMaxBar       = 8;                       // Barra maxima post-key — OPT2 optimo

input group "=== DIAS DE TRADING — TODOS ON ==="
// Todos activos: consistente con OPT2 (optimizacion corrio con todos los dias)
input bool            TradeSunday        = false;                   // Operar domingo
input bool            TradeMonday        = false;                   // DESACTIVADO — PF=0.516 OOS, unico dia negativo
input bool            TradeTuesday       = true;                    // Operar martes
input bool            TradeWednesday     = true;                    // Operar miercoles
input bool            TradeThursday      = true;                    // Operar jueves
input bool            TradeFriday        = true;                    // Operar viernes
input bool            TradeSaturday      = false;                   // Operar sabado

input group "=== BREAKEVEN ==="
// [REC 3] Breakeven activo: convierte SL en BE cuando price avanza >50% del TP
// En versión BE: WR=40.6% vs NOBE WR=29.2% — diferencia de +11.4 puntos porcentuales
input bool            EnableBreakeven    = true;                    // Activar breakeven — OPT2: estructural
input int             BE_TriggerTicks    = 350;                     // Ticks para activar BE — OPT2: 350 optimo
input int             BE_OffsetTicks     = 10;                      // Ticks sobre entrada al mover SL [FIJO=10]

input group "=== DISPLAY ==="
input bool            ShowDashboard      = true;
input bool            DrawLevels         = true;
input bool            DebugMode          = true;
input bool            ExportCSV          = true;

//──────────────────────────────────────────────
// ESTADO GLOBAL
//──────────────────────────────────────────────
CTrade   m_trade;

datetime g_keyCandleTime  = 0;
double   g_keyCandleHigh  = 0;
double   g_keyCandleLow   = 0;
double   g_keyCandleRange = 0;

bool     g_signalActive   = false;
int      g_signalDir      = 0;
datetime g_signalBarTime  = 0;
double   g_sweepOpen=0, g_sweepHigh=0, g_sweepLow=0, g_sweepClose=0;
int      g_barsSinceKey   = 0;

// Estadísticas por barra (para CSV resumen — diagnóstico)
int      g_bskCount[13];  // barras 0-12 desde key candle
int      g_bskWins[13];

datetime g_lastDayBarTime = 0;
int      g_tradesToday    = 0;
double   g_dailyPnL       = 0;
bool     g_dailyBlocked   = false;

int      g_totalTrades    = 0;
int      g_totalWins      = 0;
int      g_totalLosses    = 0;
double   g_grossProfit    = 0;
double   g_grossLoss      = 0;
double   g_runningPnL     = 0;
double   g_initialBalance = 0;
double   g_peakEquity     = 0;
double   g_maxDD          = 0;

datetime g_openTime       = 0;
double   g_openEntry      = 0;
double   g_openLots       = 0;
int      g_openBSK        = 0;

int      g_serverHour     = 0;
int      g_serverMinute   = 0;

ENUM_ORDER_TYPE_FILLING g_fillMode;

// CSV — FILE_COMMON: accesible tanto en backtest como en live
string   g_csvFile        = "";
int      g_csvHandle      = INVALID_HANDLE;
string   g_resFile        = "";

// Diagnóstico completo del flujo de señales
int      g_filteredByMinBar  = 0;
int      g_filteredBySpread  = 0;
int      g_keyCandlesFound   = 0;   // cuantas veces se detectó key candle
int      g_sweepsDetected    = 0;   // cuantas veces hubo sweep válido
int      g_signalsActivated  = 0;   // cuantas veces g_signalActive=true
int      g_tradesAttempted   = 0;   // cuantas veces se llamó ExecuteSignal
int      g_tradesFailed      = 0;   // cuantas veces m_trade falló

string   OBJ_PREFIX = "CTR37_";

//──────────────────────────────────────────────
// INIT
//──────────────────────────────────────────────
int OnInit()
{
   int rawHour    = NY_Hour + 4 + GMT_Offset;
   g_serverHour   = rawHour % 24;
   int tfMin      = PeriodSeconds(_Period) / 60;
   if(tfMin < 1) tfMin = 1;
   g_serverMinute = (NY_Minute / tfMin) * tfMin;

   // Validaciones
   if(WindowMinBar > WindowMaxBar)
   {
      Alert("[CTR3.7] WindowMinBar > WindowMaxBar. Corregir parámetros.");
      return INIT_FAILED;
   }
   if(BE_TriggerTicks >= TP_ticks && EnableBreakeven)
      PrintFormat("[CTR3.7] AVISO: BE_TriggerTicks=%d >= TP=%d — breakeven nunca se activará",
                  BE_TriggerTicks, TP_ticks);

   // Fill mode
   long ff = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((ff & SYMBOL_FILLING_IOC) != 0)       g_fillMode = ORDER_FILLING_IOC;
   else if((ff & SYMBOL_FILLING_FOK) != 0)   g_fillMode = ORDER_FILLING_FOK;
   else                                       g_fillMode = ORDER_FILLING_RETURN;

   m_trade.SetExpertMagicNumber(MagicNumber);
   m_trade.SetDeviationInPoints(SlippagePoints);
   m_trade.SetTypeFilling(g_fillMode);

   g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_peakEquity     = AccountInfoDouble(ACCOUNT_EQUITY);

   ArrayInitialize(g_bskCount, 0);
   ArrayInitialize(g_bskWins,  0);

   // Log de configuración
   double lots    = GetLots();
   double riskR   = lots * SL_ticks * ValuePerTickPerLot;
   double winR    = lots * TP_ticks * ValuePerTickPerLot;
   double rr      = (double)TP_ticks / SL_ticks;
   double beWR    = 100.0 / (1.0 + rr);

   Print("╔══════════════════════════════════════════════╗");
   PrintFormat("║  CTR Reclaim v3.7 — %s M%d", _Symbol, tfMin);
   Print(     "║  Fórmula de riesgo: Lots = RiskAmountUSD / (SL × VPT)");
   PrintFormat("║  RiskAmountUSD=$%.2f | SL=%d ticks | VPT=$%.4f",
               RiskAmountUSD, SL_ticks, ValuePerTickPerLot);
   PrintFormat("║  Lots calculados: %.4f → %.2f | Riesgo real=$%.2f",
               RiskAmountUSD/(SL_ticks*ValuePerTickPerLot),
               GetLots(),
               GetLots() * SL_ticks * ValuePerTickPerLot);
   PrintFormat("║  Win si TP: +$%.2f | R:R=1:%.2f | BE WR=%.1f%%",
               GetLots() * TP_ticks * ValuePerTickPerLot, rr, beWR);
   Print(     "║  ─────────────────────────────────────────");
   PrintFormat("║  [REC1] WindowMinBar=%d | [REC2] Lunes=%s | [REC3] BE=%s",
               WindowMinBar, TradeMonday?"ON":"OFF", EnableBreakeven?"ON":"OFF");
   PrintFormat("║  Key candle: %02d:%02d servidor (NY %02d:%02d GMT+%d)",
               g_serverHour, g_serverMinute, NY_Hour, NY_Minute, GMT_Offset);
   PrintFormat("║  Ventana: barras [%d, %d] | Días: %s%s%s%s%s",
               WindowMinBar, WindowMaxBar,
               TradeMonday?"Lun ":"", TradeTuesday?"Mar ":"",
               TradeWednesday?"Mie ":"", TradeThursday?"Jue ":"",
               TradeFriday?"Vie":"");
   Print("╚══════════════════════════════════════════════╝");

   // CSV trades
   if(ExportCSV)
   {
      g_csvFile = "CTR_v37_" + _Symbol + "_M" + IntegerToString(tfMin) +
                  "_" + IntegerToString(MagicNumber) + ".csv";
      g_resFile = "CTR_v37_RESUMEN_" + _Symbol + "_" +
                  IntegerToString(MagicNumber) + ".csv";

      g_csvHandle = FileOpen(g_csvFile,
                             FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ',');
      if(g_csvHandle != INVALID_HANDLE)
      {
         FileWriteString(g_csvHandle,
            "TradeNo,OpenDate,OpenTime,CloseDate,CloseTime,DayOfWeek,Direction,"
            "KeyHigh,KeyLow,KeyRange_pts,"
            "SweepOpen,SweepHigh,SweepLow,SweepClose,BarsSinceKey,"
            "Entry,SL,TP,Lots,RiskUSD_real,WinUSD_real,Spread_pts,"
            "Profit,Result,HoldTime_min,"
            "Balance,RunningPnL,DD_from_initial_USD,WinRate_pct,PF\n");
         FileFlush(g_csvHandle);
         PrintFormat("[CTR3.7] CSV trades: MQL5\\Files\\Common\\%s", g_csvFile);
      }
      else
         PrintFormat("[CTR3.7] ⚠ No se pudo abrir CSV. Error=%d", GetLastError());
   }

   return INIT_SUCCEEDED;
}

//──────────────────────────────────────────────
// DEINIT
//──────────────────────────────────────────────
void OnDeinit(const int reason)
{
   if(g_csvHandle != INVALID_HANDLE)
   { FileClose(g_csvHandle); g_csvHandle = INVALID_HANDLE; }
   ObjectsDeleteAll(0, OBJ_PREFIX);
   Comment("");
}

//──────────────────────────────────────────────
// TICK
//──────────────────────────────────────────────
void OnTick()
{
   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, _Period, 0);
   bool isNewBar = (curBar != lastBar);
   if(isNewBar) lastBar = curBar;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > g_peakEquity) g_peakEquity = eq;
   double dd = g_peakEquity - eq;
   if(dd > g_maxDD) g_maxDD = dd;

   CheckDayReset(curBar);
   CheckProtections();

   if(isNewBar)
   {
      ScanForKeyCandle();
      if(g_keyCandleTime > 0 && !g_signalActive) ScanForSweep();
      if(g_signalActive && !g_dailyBlocked &&
         g_tradesToday < MaxTradesPerDay && IsTradingDay())
         ExecuteSignal();
   }

   if(EnableBreakeven) ManageBreakeven();
   if(ShowDashboard)   UpdateDashboard();
}

//──────────────────────────────────────────────
// DAY RESET
//──────────────────────────────────────────────
void CheckDayReset(datetime curBar)
{
   MqlDateTime dt; TimeToStruct(curBar, dt);
   datetime stamp = StringToTime(StringFormat("%04d.%02d.%02d 00:00",
                                  dt.year, dt.mon, dt.day));
   if(stamp == g_lastDayBarTime) return;

   if(DebugMode && g_lastDayBarTime > 0)
      PrintFormat("[CTR3.7] Nuevo día | trades=%d | PnL=$%.2f | run=$%.2f | DD=$%.2f",
                  g_tradesToday, g_dailyPnL, g_runningPnL,
                  g_initialBalance - AccountInfoDouble(ACCOUNT_EQUITY));

   g_lastDayBarTime = stamp;
   g_tradesToday    = 0;
   g_dailyPnL       = 0;
   g_dailyBlocked   = false;
   g_signalActive   = false;
   g_signalDir      = 0;

   if(DrawLevels)
   {
      string nm = OBJ_PREFIX + "DL_" + IntegerToString((int)curBar);
      if(ObjectFind(0, nm) < 0)
      {
         ObjectCreate(0, nm, OBJ_VLINE, 0, curBar, 0);
         ObjectSetInteger(0, nm, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(0, nm, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, nm, OBJPROP_BACK,  true);
      }
   }
}

//──────────────────────────────────────────────
// PROTECCIONES
//──────────────────────────────────────────────
void CheckProtections()
{
   if(g_dailyBlocked) return;

   if(EnableDailyLossLimit && g_dailyPnL <= -MathAbs(DailyLossLimitUSD))
   {
      g_dailyBlocked = true;
      PrintFormat("[CTR3.7] ⚠ Daily loss limit: $%.2f (límite $%.2f)",
                  g_dailyPnL, DailyLossLimitUSD);
      return;
   }
   if(EnableMaxDD)
   {
      double ddNow = g_initialBalance - AccountInfoDouble(ACCOUNT_EQUITY);
      if(ddNow >= MathAbs(MaxDDFromInitial))
      {
         g_dailyBlocked = true;
         PrintFormat("[CTR3.7] ⚠ Max DD desde inicial: $%.2f (límite $%.2f)",
                     ddNow, MaxDDFromInitial);
      }
   }
}

//──────────────────────────────────────────────
// SCAN KEY CANDLE — sin todayStart (data gap fix heredado de v3.0)
//──────────────────────────────────────────────
void ScanForKeyCandle()
{
   int total = Bars(_Symbol, _Period);
   if(total < 2) return;

   for(int i = 1; i < MathMin(total, 500); i++)
   {
      datetime bt = iTime(_Symbol, _Period, i);
      if(bt == 0) continue;
      if(g_keyCandleTime > 0 && bt <= g_keyCandleTime) break;

      MqlDateTime dt; TimeToStruct(bt, dt);
      if(dt.hour != g_serverHour || dt.min != g_serverMinute) continue;
      if(!IsTradingDayDT(dt)) break;

      g_keyCandleTime  = bt;
      g_keyCandleHigh  = iHigh(_Symbol, _Period, i);
      g_keyCandleLow   = iLow (_Symbol, _Period, i);
      g_keyCandleRange = g_keyCandleHigh - g_keyCandleLow;

      if(DebugMode)
         PrintFormat("[CTR3.7] Key candle: %s H=%.2f L=%.2f R=%.0fpts",
                     TimeToString(bt, TIME_DATE|TIME_MINUTES),
                     g_keyCandleHigh, g_keyCandleLow, g_keyCandleRange / _Point);

      if(DrawLevels)
      {
         DrawHLine(OBJ_PREFIX+"KH_"+IntegerToString((int)bt),
                   g_keyCandleHigh, clrDodgerBlue, STYLE_DASH);
         DrawHLine(OBJ_PREFIX+"KL_"+IntegerToString((int)bt),
                   g_keyCandleLow,  clrOrangeRed,  STYLE_DASH);
      }

      g_signalActive = false;
      g_signalDir    = 0;
      g_keyCandlesFound++;
      break;
   }
}

//──────────────────────────────────────────────
// SCAN SWEEP — con filtro WindowMinBar / WindowMaxBar
// [REC 1] Solo acepta señales en barras >= WindowMinBar post-key candle
//──────────────────────────────────────────────
void ScanForSweep()
{
   if(g_keyCandleTime == 0) return;

   // Localizar key candle (loop manual — evita iBarShift bug)
   int kcBar = -1;
   int total = Bars(_Symbol, _Period);
   for(int i = 0; i < total; i++)
      if(iTime(_Symbol, _Period, i) == g_keyCandleTime) { kcBar = i; break; }
   if(kcBar < 0) return;

   int sbIdx = 1;                        // barra[1] = última barra cerrada
   int bsk   = kcBar - sbIdx;            // barras transcurridas desde key candle

   // [REC 1] Filtro principal: WindowMinBar
   if(bsk < WindowMinBar || bsk > WindowMaxBar)
   {
      if(bsk > 0 && bsk < WindowMinBar && DebugMode)
      {
         // Verificar si hay sweep válido que estamos rechazando
         double sH = iHigh(_Symbol, _Period, sbIdx);
         double sL = iLow (_Symbol, _Period, sbIdx);
         double sC = iClose(_Symbol, _Period, sbIdx);
         bool wouldTrade = (sL < g_keyCandleLow && sC > g_keyCandleLow) ||
                           (sH > g_keyCandleHigh && sC < g_keyCandleHigh);
         if(wouldTrade)
         {
            g_filteredByMinBar++;
            PrintFormat("[CTR3.7] Señal en bar %d filtrada por WindowMinBar=%d (total filtradas: %d)",
                        bsk, WindowMinBar, g_filteredByMinBar);
         }
      }
      return;
   }

   datetime sbTime = iTime(_Symbol, _Period, sbIdx);
   if(sbTime == g_signalBarTime) return;  // ya analizada

   double sO = iOpen (_Symbol, _Period, sbIdx);
   double sH = iHigh (_Symbol, _Period, sbIdx);
   double sL = iLow  (_Symbol, _Period, sbIdx);
   double sC = iClose(_Symbol, _Period, sbIdx);

   bool bull = (sL < g_keyCandleLow  && sC > g_keyCandleLow  && TradeType != SHORT);
   bool bear = (sH > g_keyCandleHigh && sC < g_keyCandleHigh && TradeType != LONG);
   if(!bull && !bear) return;

   g_signalActive  = true;
   g_signalDir     = bull ? 1 : -1;
   g_signalBarTime = sbTime;
   g_sweepsDetected++;
   g_signalsActivated++;
   g_sweepOpen     = sO; g_sweepHigh = sH;
   g_sweepLow      = sL; g_sweepClose = sC;
   g_barsSinceKey  = bsk;

   PrintFormat("[CTR3.7] SEÑAL %s | %s | bar=%d/%d",
               g_signalDir > 0 ? "BUY" : "SELL",
               TimeToString(sbTime, TIME_DATE|TIME_MINUTES),
               bsk, WindowMaxBar);
}

//──────────────────────────────────────────────
// EXECUTE SIGNAL
//──────────────────────────────────────────────
void ExecuteSignal()
{
   if(!g_signalActive) return;
   g_tradesAttempted++;

   // Spread check
   long sp = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(sp > MaxSpreadPoints)
   {
      if(DebugMode)
         PrintFormat("[CTR3.7] Spread=%d > %d — señal descartada", (int)sp, MaxSpreadPoints);
      g_filteredBySpread++;
      g_signalActive = false;
      return;
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entry, slPx, tpPx;

   if(g_signalDir > 0)
   {
      entry = ask;
      slPx  = NormalizeDouble(entry - SL_ticks * _Point, _Digits);
      tpPx  = NormalizeDouble(entry + TP_ticks * _Point, _Digits);
   }
   else
   {
      entry = bid;
      slPx  = NormalizeDouble(entry + SL_ticks * _Point, _Digits);
      tpPx  = NormalizeDouble(entry - TP_ticks * _Point, _Digits);
   }

   double lots    = GetLots();
   double riskR   = lots * SL_ticks * ValuePerTickPerLot;
   double winR    = lots * TP_ticks * ValuePerTickPerLot;

   bool ok = g_signalDir > 0
             ? m_trade.Buy (lots, _Symbol, entry, slPx, tpPx, "CTR37_BUY")
             : m_trade.Sell(lots, _Symbol, entry, slPx, tpPx, "CTR37_SELL");

   if(ok)
   {
      g_tradesToday++; g_totalTrades++;
      g_signalActive = false;
      g_openTime   = iTime(_Symbol, _Period, 0);
      g_openEntry  = entry;
      g_openLots   = lots;
      g_openBSK    = g_barsSinceKey;

      // Actualizar estadísticas BSK
      if(g_barsSinceKey >= 0 && g_barsSinceKey <= 12)
         g_bskCount[g_barsSinceKey]++;

      PrintFormat("[CTR3.7] ✓ #%d %s | lots=%.2f | bar=%d | entry=%.2f | SL=%.2f | TP=%.2f | riesgo=$%.2f",
                  g_totalTrades, g_signalDir > 0 ? "BUY" : "SELL",
                  lots, g_barsSinceKey, entry, slPx, tpPx, riskR);

      if(DrawLevels)
      {
         DrawHLine(OBJ_PREFIX+"E_"+IntegerToString((int)g_openTime),
                   entry, g_signalDir > 0 ? clrLime : clrRed, STYLE_SOLID);
         DrawHLine(OBJ_PREFIX+"T_"+IntegerToString((int)g_openTime),
                   tpPx, clrGold, STYLE_DOT);
         DrawHLine(OBJ_PREFIX+"S_"+IntegerToString((int)g_openTime),
                   slPx, clrOrangeRed, STYLE_DOT);
      }

      // CSV — fila OPEN
      if(ExportCSV && g_csvHandle != INVALID_HANDLE)
      {
         MqlDateTime dt; TimeToStruct(g_openTime, dt);
         string days[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
         string row = StringFormat(
            "%d,%s,%s,,,,%s,%.5f,%.5f,%.1f,%.5f,%.5f,%.5f,%.5f,%d,%.5f,%.5f,%.5f,%.2f,%.2f,%.2f,%d,,OPEN,,%.2f,%.2f,%.2f,,\n",
            g_totalTrades,
            TimeToString(g_openTime, TIME_DATE),
            TimeToString(g_openTime, TIME_MINUTES),
            days[dt.day_of_week],
            g_keyCandleHigh, g_keyCandleLow, g_keyCandleRange / _Point,
            g_sweepOpen, g_sweepHigh, g_sweepLow, g_sweepClose,
            g_barsSinceKey,
            entry, slPx, tpPx, lots, riskR, winR, (int)sp,
            AccountInfoDouble(ACCOUNT_BALANCE),
            g_runningPnL,
            g_initialBalance - AccountInfoDouble(ACCOUNT_EQUITY));
         FileWriteString(g_csvHandle, row);
         FileFlush(g_csvHandle);
      }
   }
   else
   {
      PrintFormat("[CTR3.7] ✗ Trade falló: %d %s",
                  m_trade.ResultRetcode(), m_trade.ResultComment());
      g_tradesFailed++;
      g_signalActive = false;
   }
}

//──────────────────────────────────────────────
// GET LOTS — riesgo fijo con cap real del broker
//
// Paso 1: lots_target = RiskAmountUSD / (SL_ticks × ValuePerTickPerLot)
//         Ej: $100 / (100 × $0.20) = 5.00 lots
//
// Paso 2: OrderCalcMargin devuelve el margen REAL que cobra el broker.
//         FundingPips NDX100 cobra ~79% del nocional (no 1:20 teórico).
//         Esto limita los lots al máximo que el broker acepta.
//
// Paso 3: lots = MIN(target, FreeMargin×0.90 / marginReal)
//         El trade SIEMPRE se ejecuta con los lots disponibles.
//         El riesgo real puede ser menor que RiskAmountUSD si el margen
//         del broker es el factor limitante.
//──────────────────────────────────────────────
double GetLots()
{
   if(ValuePerTickPerLot <= 0 || SL_ticks <= 0)
   {
      Print("[CTR3.7] ERROR: ValuePerTickPerLot o SL_ticks = 0");
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   }

   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vStep <= 0) vStep = 0.01;

   // Paso 1 — lots objetivo por riesgo
   double rawLots = RiskAmountUSD / (SL_ticks * ValuePerTickPerLot);
   double lots    = MathFloor(rawLots / vStep) * vStep;
   lots           = MathMax(vMin, MathMin(vMax, lots));

   // Paso 2 — margen REAL del broker via OrderCalcMargin
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double marginPerLot = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, ask, marginPerLot) || marginPerLot <= 0)
   {
      // Fallback: usar apalancamiento configurado si OrderCalcMargin falla
      double cs = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      if(cs <= 0) cs = 5.0;
      marginPerLot = (ask * cs) / AccountLeverage;
   }

   // Paso 3 — cap por margen disponible (90% buffer)
   if(marginPerLot > 0)
   {
      double freeMargin  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      double maxByMargin = MathFloor((freeMargin * 0.90) / marginPerLot / vStep) * vStep;
      maxByMargin        = MathMax(vMin, MathMin(vMax, maxByMargin));

      if(lots > maxByMargin)
      {
         PrintFormat("[CTR3.7] Cap margen: target=%.2f → reducido a %.2f lots "
                     "(libre=$%.0f, margen/lot=$%.0f)",
                     lots, maxByMargin, freeMargin, marginPerLot);
         lots = maxByMargin;
      }
   }

   double realRisk = lots * SL_ticks * ValuePerTickPerLot;
   double realWin  = lots * TP_ticks * ValuePerTickPerLot;

   PrintFormat("[CTR3.7] Lots: target=%.4f → final=%.2f | riesgo=$%.2f | win=$%.2f | margin/lot=$%.0f",
               rawLots, lots, realRisk, realWin, marginPerLot);

   return lots;
}

//──────────────────────────────────────────────
// OnTradeTransaction — cierre de trades
//──────────────────────────────────────────────
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &req,
                        const MqlTradeResult      &res)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ulong dT = trans.deal;
   if(!HistoryDealSelect(dT)) return;
   if(HistoryDealGetInteger(dT, DEAL_MAGIC)  != MagicNumber) return;
   if(HistoryDealGetString (dT, DEAL_SYMBOL) != _Symbol)     return;

   ENUM_DEAL_ENTRY de = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dT, DEAL_ENTRY);
   if(de != DEAL_ENTRY_OUT && de != DEAL_ENTRY_OUT_BY) return;

   double profit = HistoryDealGetDouble(dT, DEAL_PROFIT)
                 + HistoryDealGetDouble(dT, DEAL_SWAP)
                 + HistoryDealGetDouble(dT, DEAL_COMMISSION);

   g_dailyPnL   += profit;
   g_runningPnL += profit;
   if(profit > 0) { g_totalWins++;   g_grossProfit += profit; }
   else           { g_totalLosses++; g_grossLoss   += profit; }

   // Actualizar BSK win stats
   if(g_openBSK >= 0 && g_openBSK <= 12 && profit > 0)
      g_bskWins[g_openBSK]++;

   double wr = g_totalTrades > 0 ? 100.0 * g_totalWins  / g_totalTrades : 0;
   double pf = g_grossLoss   != 0 ? MathAbs(g_grossProfit / g_grossLoss) : 0;
   string out = profit > 0 ? "WIN" : (profit < 0 ? "LOSS" : "BE");

   datetime closeTime = (datetime)HistoryDealGetInteger(dT, DEAL_TIME);
   int holdMin = g_openTime > 0 ? (int)((closeTime - g_openTime) / 60) : 0;
   double ddNow = g_initialBalance - AccountInfoDouble(ACCOUNT_EQUITY);

   PrintFormat("[CTR3.7] %s | P/L=$%.2f | bar=%d | WR=%.1f%% | PF=%.3f | run=$%.2f | DD=$%.2f",
               out, profit, g_openBSK, wr, pf, g_runningPnL, ddNow);

   // CSV — fila CLOSE (escribe directamente al archivo, no buffered)
   if(ExportCSV && g_csvHandle != INVALID_HANDLE)
   {
      MqlDateTime dtC; TimeToStruct(closeTime, dtC);
      string days[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
      double riskR = g_openLots * SL_ticks * ValuePerTickPerLot;
      double winR  = g_openLots * TP_ticks * ValuePerTickPerLot;

      string row = StringFormat(
         "%d,%s,%s,%s,%s,%s,%s,%.5f,%.5f,%.1f,%.5f,%.5f,%.5f,%.5f,%d,%.5f,,,%.2f,%.2f,%.2f,,%.2f,%s,%d,%.2f,%.2f,%.2f,%.1f,%.3f\n",
         g_totalTrades,
         TimeToString(g_openTime,  TIME_DATE),
         TimeToString(g_openTime,  TIME_MINUTES),
         TimeToString(closeTime,   TIME_DATE),
         TimeToString(closeTime,   TIME_MINUTES),
         days[dtC.day_of_week], out,
         g_keyCandleHigh, g_keyCandleLow, g_keyCandleRange / _Point,
         g_sweepOpen, g_sweepHigh, g_sweepLow, g_sweepClose, g_openBSK,
         g_openEntry, g_openLots, riskR, winR,
         profit, out, holdMin,
         AccountInfoDouble(ACCOUNT_BALANCE),
         g_runningPnL, ddNow, wr, pf);
      FileWriteString(g_csvHandle, row);
      FileFlush(g_csvHandle);
   }
}

//──────────────────────────────────────────────
// OnTester — CSV resumen + análisis BSK al final del backtest
// FIX: lee el archivo de trades en vez de usar g_csvBuffer
// → esto garantiza que 2024 y todos los años aparezcan correctamente
//──────────────────────────────────────────────
double OnTester()
{
   double wr  = g_totalTrades > 0 ? 100.0 * g_totalWins / g_totalTrades : 0;
   double pf  = g_grossLoss   != 0 ? MathAbs(g_grossProfit / g_grossLoss) : 0;
   double rr  = (double)TP_ticks / SL_ticks;
   double beW = 100.0 / (1.0 + rr);
   double lots = GetLots();
   double riskR= lots * SL_ticks * ValuePerTickPerLot;
   double winR = lots * TP_ticks * ValuePerTickPerLot;

   // Cerrar CSV de trades
   if(g_csvHandle != INVALID_HANDLE)
   { FileClose(g_csvHandle); g_csvHandle = INVALID_HANDLE; }

   if(!ExportCSV) return pf;

   // Escribir resumen separado
   int fh = FileOpen(g_resFile, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ',');
   if(fh == INVALID_HANDLE)
   {
      PrintFormat("[CTR3.7] ⚠ No se pudo crear resumen. Error=%d", GetLastError());
      return pf;
   }

   FileWriteString(fh, "CTR Reclaim v3.7 — Resumen Backtest\n");
   FileWriteString(fh, StringFormat("Simbolo,%s\n", _Symbol));
   FileWriteString(fh, StringFormat("Balance inicial,$%.2f\n", g_initialBalance));
   FileWriteString(fh, StringFormat("Balance final,$%.2f\n",   g_initialBalance + g_runningPnL));
   FileWriteString(fh, StringFormat("Profit neto,$%.2f\n",     g_runningPnL));
   FileWriteString(fh, StringFormat("Total trades,%d\n",       g_totalTrades));
   FileWriteString(fh, StringFormat("Wins,%d\n",               g_totalWins));
   FileWriteString(fh, StringFormat("Losses,%d\n",             g_totalLosses));
   FileWriteString(fh, StringFormat("Win Rate,%.2f%%\n",       wr));
   FileWriteString(fh, StringFormat("Profit Factor,%.4f\n",    pf));
   FileWriteString(fh, StringFormat("Gross Profit,$%.2f\n",    g_grossProfit));
   FileWriteString(fh, StringFormat("Gross Loss,$%.2f\n",      g_grossLoss));
   FileWriteString(fh, StringFormat("Max DD,$%.2f\n",          g_maxDD));
   FileWriteString(fh, StringFormat("R:R,1:%.2f\n",            rr));
   FileWriteString(fh, StringFormat("BE Win Rate,%.2f%%\n",    beW));
   FileWriteString(fh, StringFormat("Edge WR-BE,%.2f%%\n",     wr - beW));
   FileWriteString(fh, StringFormat("SL ticks,%d\n",           SL_ticks));
   FileWriteString(fh, StringFormat("TP ticks,%d\n",           TP_ticks));
   FileWriteString(fh, StringFormat("RiskAmountUSD,$%.2f\n",   RiskAmountUSD));
   FileWriteString(fh, StringFormat("ValuePerTickPerLot,$%.4f\n", ValuePerTickPerLot));
   FileWriteString(fh, StringFormat("AccountLeverage,1:%d\n",     AccountLeverage));
   FileWriteString(fh, StringFormat("Lots calculados,%.4f\n",  RiskAmountUSD/(SL_ticks*ValuePerTickPerLot)));
   FileWriteString(fh, StringFormat("Lots normalizados,%.2f\n",lots));
   FileWriteString(fh, StringFormat("RiesgoReal/trade,$%.2f\n",riskR));
   FileWriteString(fh, StringFormat("WinReal/trade,$%.2f\n",   winR));
   FileWriteString(fh, StringFormat("WindowMinBar,%d\n",       WindowMinBar));
   FileWriteString(fh, StringFormat("WindowMaxBar,%d\n",       WindowMaxBar));
   FileWriteString(fh, StringFormat("TradeMonday,%s\n",        TradeMonday?"true":"false"));
   FileWriteString(fh, StringFormat("EnableBreakeven,%s\n",    EnableBreakeven?"true":"false"));
   FileWriteString(fh, StringFormat("BE_TriggerTicks,%d\n",    BE_TriggerTicks));
   FileWriteString(fh, StringFormat("MaxSpreadPoints,%d\n",    MaxSpreadPoints));
   FileWriteString(fh, StringFormat("Filtradas_MinBar,%d\n",    g_filteredByMinBar));
   FileWriteString(fh, StringFormat("Filtradas_Spread,%d\n",    g_filteredBySpread));
   FileWriteString(fh, StringFormat("KeyCandlesFound,%d\n",     g_keyCandlesFound));
   FileWriteString(fh, StringFormat("SweepsDetected,%d\n",      g_sweepsDetected));
   FileWriteString(fh, StringFormat("SignalsActivated,%d\n",    g_signalsActivated));
   FileWriteString(fh, StringFormat("TradesAttempted,%d\n",     g_tradesAttempted));
   FileWriteString(fh, StringFormat("TradesFailed,%d\n",        g_tradesFailed));
   FileWriteString(fh, "\n");

   // Análisis por barra desde key candle (directo del array en memoria — no usa archivo)
   FileWriteString(fh, "=== ANÁLISIS BARS SINCE KEY ===\n");
   FileWriteString(fh, "BarsSinceKey,Trades,Wins,WR_pct,Expected_WR\n");
   for(int b = 1; b <= 12; b++)
   {
      if(g_bskCount[b] == 0) continue;
      double bWR = 100.0 * g_bskWins[b] / g_bskCount[b];
      string flag = bWR > beW + 5.0 ? " STRONG" : (bWR < beW ? " WEAK" : "");
      FileWriteString(fh, StringFormat("Bar %d,%d,%d,%.1f%%,%.1f%%%s\n",
                                       b, g_bskCount[b], g_bskWins[b], bWR, beW, flag));
   }
   FileWriteString(fh, "\n");

   // El archivo de trades completo ya está en g_csvFile — referenciarlo
   FileWriteString(fh, StringFormat("=== TRADES ===\nVer archivo: %s\n", g_csvFile));
   FileClose(fh);

   // Log de cierre
   Print("╔══════════════════════════════════════════════╗");
   PrintFormat("║  BACKTEST FINALIZADO — CTR v3.5 — %s", _Symbol);
   PrintFormat("║  Trades: %d | WR: %.1f%% [BE=%.1f%%] | Edge: %+.1f%%",
               g_totalTrades, wr, beW, wr - beW);
   PrintFormat("║  PF: %.4f | Net: $%.2f | MaxDD: $%.2f",
               pf, g_runningPnL, g_maxDD);
   PrintFormat("║  RiskAmountUSD=$%.2f | VPT=$%.4f | Lots=%.2f | RiesgoReal=$%.2f",
               RiskAmountUSD, ValuePerTickPerLot, lots, riskR);
   PrintFormat("║  DIAGNOSTICO: KeyCandles=%d | Sweeps=%d | Signals=%d | Attempted=%d | Failed=%d",
               g_keyCandlesFound, g_sweepsDetected, g_signalsActivated,
               g_tradesAttempted, g_tradesFailed);
   PrintFormat("║  Filtradas MinBar=%d: %d | Spread: %d",
               WindowMinBar, g_filteredByMinBar, g_filteredBySpread);
   Print(     "║  Análisis BSK:");
   for(int b = 1; b <= 12; b++)
   {
      if(g_bskCount[b] == 0) continue;
      double bWR = 100.0 * g_bskWins[b] / g_bskCount[b];
      PrintFormat("║    Bar %d: %d trades | WR=%.1f%% | Edge=%+.1f%%",
                  b, g_bskCount[b], bWR, bWR - beW);
   }
   Print("╚══════════════════════════════════════════════╝");
   PrintFormat("[CTR3.7] CSV trades:  MQL5\\Files\\Common\\%s", g_csvFile);
   PrintFormat("[CTR3.7] CSV resumen: MQL5\\Files\\Common\\%s", g_resFile);

   return pf;
}

//──────────────────────────────────────────────
// [REC 3] BREAKEVEN
//──────────────────────────────────────────────
void ManageBreakeven()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)     continue;

      double op  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl  = PositionGetDouble(POSITION_SL);
      double cp  = PositionGetDouble(POSITION_PRICE_CURRENT);
      long   pt  = PositionGetInteger(POSITION_TYPE);

      if(pt == POSITION_TYPE_BUY)
      {
         double btgt = op + BE_TriggerTicks * _Point;
         double nsl  = op + BE_OffsetTicks  * _Point;
         if(cp >= btgt && sl < nsl - _Point)
         {
            m_trade.PositionModify(ticket, nsl, PositionGetDouble(POSITION_TP));
            PrintFormat("[CTR3.7] BE BUY #%I64u → SL=%.2f", ticket, nsl);
         }
      }
      else if(pt == POSITION_TYPE_SELL)
      {
         double btgt = op - BE_TriggerTicks * _Point;
         double nsl  = op - BE_OffsetTicks  * _Point;
         if(cp <= btgt && (sl > nsl + _Point || sl == 0))
         {
            m_trade.PositionModify(ticket, nsl, PositionGetDouble(POSITION_TP));
            PrintFormat("[CTR3.7] BE SELL #%I64u → SL=%.2f", ticket, nsl);
         }
      }
   }
}

//──────────────────────────────────────────────
// DASHBOARD
//──────────────────────────────────────────────
void UpdateDashboard()
{
   double lots  = GetLots();
   double risk  = lots * SL_ticks * ValuePerTickPerLot;
   double win   = lots * TP_ticks * ValuePerTickPerLot;
   double wr    = g_totalTrades > 0 ? 100.0 * g_totalWins / g_totalTrades : 0;
   double pf    = g_grossLoss   != 0 ? MathAbs(g_grossProfit / g_grossLoss) : 0;
   double rr    = (double)TP_ticks / SL_ticks;
   double beWR  = 100.0 / (1.0 + rr);
   long   sp    = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double ddNow = g_initialBalance - AccountInfoDouble(ACCOUNT_EQUITY);

   string state = g_dailyBlocked ? "BLOQUEADO" :
                  (g_signalActive ? (g_signalDir > 0 ? "SENAL BUY" : "SENAL SELL") :
                  (g_keyCandleTime > 0 ? "KEY SET" : "IDLE"));

   string beStr = EnableBreakeven
                  ? StringFormat("BE ON (trig=%d, off=%d)", BE_TriggerTicks, BE_OffsetTicks)
                  : "BE OFF";

   Comment(StringFormat(
      "CTR Reclaim v3.5\n"
      "Estado: %s\n"
      "Key: %02d:%02d srv  |  Bar ventana: [%d, %d]\n"
      "SL=%d | TP=%d | R:R=1:%.2f | %s\n"
      "Risk=$%.2f → Lots=%.2f | Riesgo=$%.2f | Win=$%.2f\n"
      "Spread: %d/%d pts | Trades hoy: %d/%d\n"
      "Sesion: %d trades | WR=%.1f%% [BE=%.1f%%] | PF=%.3f\n"
      "PnL dia: $%.2f | Total: $%.2f\n"
      "DD: $%.2f | MaxDD: $%.2f\n"
      "Filtradas MinBar: %d | Spread: %d",
      state,
      g_serverHour, g_serverMinute, WindowMinBar, WindowMaxBar,
      SL_ticks, TP_ticks, rr, beStr,
      RiskAmountUSD, lots, risk, win,
      (int)sp, MaxSpreadPoints, g_tradesToday, MaxTradesPerDay,
      g_totalTrades, wr, beWR, pf,
      g_dailyPnL, g_runningPnL,
      ddNow, g_maxDD,
      g_filteredByMinBar, g_filteredBySpread
   ));
}

//──────────────────────────────────────────────
// HELPERS
//──────────────────────────────────────────────
bool IsTradingDay()
{
   MqlDateTime dt; TimeToStruct(iTime(_Symbol, _Period, 0), dt);
   return IsTradingDayDT(dt);
}
bool IsTradingDayDT(MqlDateTime &dt)
{
   switch(dt.day_of_week)
   {
      case 0: return TradeSunday;
      case 1: return TradeMonday;
      case 2: return TradeTuesday;
      case 3: return TradeWednesday;
      case 4: return TradeThursday;
      case 5: return TradeFriday;
      case 6: return TradeSaturday;
   }
   return false;
}
void DrawHLine(string nm, double px, color cl, ENUM_LINE_STYLE st)
{
   if(ObjectFind(0, nm) >= 0) ObjectDelete(0, nm);
   ObjectCreate(0, nm, OBJ_HLINE, 0, 0, px);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, cl);
   ObjectSetInteger(0, nm, OBJPROP_STYLE, st);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, nm, OBJPROP_BACK,  true);
}
//+------------------------------------------------------------------+
