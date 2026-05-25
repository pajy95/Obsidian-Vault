//+------------------------------------------------------------------+
//|  BreakoutNY_v4_DJI30_FP.mq5                                     |
//|  BreakoutNY Strategy — DJI30 (US Wall Street 30) — FundingPips  |
//|  Timeframe : M5   Version : 4.1   April 2026                   |
//|                                                                  |
//|  VALIDATED: IS PF=1.609 MaxDD=3.97% | OOS PF=2.017 MaxDD=3.93% |
//|                                                                  |
//|  VPP FIX: ContractSize*Point = 5*0.01 = $0.05/point/lot        |
//|  FOR $5k CHALLENGE: RiskAmountUSD = 50 (1% of $5,000)          |
//+------------------------------------------------------------------+
#property copyright "BreakoutNY v4.1 DJI30 FundingPips — Jose Yanez"
#property version   "4.10"
#property description "IS PF=1.609 | OOS PF=2.017 | MaxDD<4%"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade        trade;
CPositionInfo posInfo;

//=== SESSION ============================================================
input group   "=== SESSION ==="
input int     ServerOffsetHours  = 2;    // UTC offset del servidor (UTC+2 FundingPips)
input int     EntryWindowEnd_Min = 15;   // Ventana entrada: 14:50–14:50+N UTC
input int     SessionCloseHour   = 17;   // Cierre forzoso hora UTC — NUNCA >23
input int     SessionCloseMin    = 0;    // Cierre forzoso minutos

//=== RISK ===============================================================
input group   "=== RISK ==="
input double  RiskAmountUSD      = 50.0; // Riesgo por trade: $5k=50 · $25k=250 · $100k=1000

//=== TRADE MANAGEMENT ===================================================
input group   "=== TRADE MANAGEMENT ==="
input int     BE_BufferPct       = 50;   // % del SL antes de activar BE — optimizar: Start=30 Step=10 Stop=300
input double  TP1_RR             = 1.0;  // TP1 ratio (SL ya en entry por BE)
input double  TP2_RR             = 2.0;  // TP2 ratio — SL sube a TP1 (profit asegurado)
input double  TP3_RR             = 3.0;  // TP3 ratio — cierre total (target final validado)

//=== PARTIALS ===========================================================
input group   "=== PARTIALS ==="
input bool    EnablePartials     = false; // Mantener false — validado en backtests
input double  TP2_ClosePct       = 40.0; // % cierre parcial en TP2 (solo si EnablePartials)

//=== DAY FILTERS ========================================================
input group   "=== DAY FILTERS ==="
input bool    FilterMonday       = true;
input bool    FilterTuesday      = true;
input bool    FilterWednesday    = false; // MANTENER FALSE — confirmado en 10+ backtests
input bool    FilterThursday     = true;
input bool    FilterFriday       = true;

//=== RANGE FILTER =======================================================
input group   "=== RANGE FILTER ==="
input double  MinSL_Points       = 8200.0;  // Rango mínimo (P25 histórico optimizado)
input double  MaxSL_Points       = 20000.0; // Rango máximo (estable en optimización)
input bool    ConfirmOnClose     = true;     // SIEMPRE true — confirmación al cierre de vela

//=== ATR FILTER =========================================================
input group   "=== ATR FILTER ==="
input bool    ATR_FilterEnable   = true;    // Mantener activo
input int     ATR_Period         = 14;
input double  ATR_MaxMultiplier  = 2.0;     // Bloquea días con ATR > 2× baseline
input double  ATR_MinMultiplier  = 0.3;     // Bloquea días con ATR < 0.3× baseline
input int     ATR_BaselineDays   = 20;      // Ventana rolling del baseline

//=== MISC ===============================================================
input group   "=== MISC ==="
input bool    EnableCSV          = true;
input string  CSVFileName        = "BreakoutNY_v4_DJI30_trades";
input int     MagicNumber        = 202402;  // DJI30=202402 · NAS100=202401 · SP500=202403

//=== VISUAL =============================================================
input group "=== VISUAL ==="
input bool   VIS_Enable         = true;   // Activar módulo visual en el gráfico
input int    VIS_LookbackDays   = 25;     // Días históricos a redibujar al iniciar
input int    VIS_ExtendBars     = 50;     // Velas que se extienden los niveles hacia la derecha
input bool   VIS_ShowBE         = true;   // Mostrar línea de BreakEven en el gráfico
input bool   VIS_ShowLabel      = true;   // Mostrar panel informativo en esquinas
// ─── Colores del módulo visual ─────────────────────────────────────────
input color  VIS_ColRange       = C'14,25,52';    // Color fondo zona de rango 14:35–14:45
input color  VIS_ColRangeBorder = C'55,115,215';  // Color bordes HIGH/LOW del rango
input color  VIS_ColSL          = C'220,50,70';   // Color línea Stop Loss
input color  VIS_ColEntry       = C'195,208,230'; // Color línea de entrada (Entry)
input color  VIS_ColBE          = C'0,195,218';   // Color línea BreakEven
input color  VIS_ColTP1         = C'228,188,38';  // Color línea Take Profit 1
input color  VIS_ColTP2         = C'228,128,28';  // Color línea Take Profit 2
input color  VIS_ColTP3         = C'28,208,128';  // Color línea Take Profit 3 (objetivo final)

//=== GLOBAL STATE =======================================================
double   g_rangeHigh=0, g_rangeLow=0, g_slDistance=0;
double   g_cachedLots=0, g_cachedVPP=0;
bool     g_rangeFormed=false, g_tradedToday=false;
bool     g_rangeAttempted=false;    // evita mensajes repetidos en terminal
bool     g_sessionClosePrinted=false; // evita mensaje SESSION_END repetido
bool     g_brkPending=false;
int      g_brkDir=0;
datetime g_brkBarTime=0;
double   g_entryPrice=0, g_originalSL=0;
double   g_beLevel=0, g_tp1Level=0, g_tp2Level=0, g_tp3Level=0;
bool     g_beActivated=false, g_tp2Hit=false;
int      g_atrHandle=INVALID_HANDLE, g_csvHandle=INVALID_HANDLE;
datetime g_lastBarTime=0;
int      g_lastResetDay=-1;
string   g_tradeDir="";   // "buy" | "sell" | "" — para panel visual
string   vis_dayTag  =""; // Tag del día actual (YYYYMMDD) — para VisMoveLevel
bool     vis_hasTrade=false; // true si hubo trade hoy — para VisRedrawToday

#define VIS_PFX "BNYV_"   // Prefijo de todos los objetos del visual

//+------------------------------------------------------------------+
//  FUNCIONES DE SOPORTE — VPP y tamaño de lote
//+------------------------------------------------------------------+
double GetValuePerPoint()
{
   double cs  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double pt  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double vpp = cs * pt;
   if(vpp <= 0) {
      Print("WARNING: ContractSize*Point=0, usando OrderCalcProfit");
      double profit=0, ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      if(OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1.0,ask,ask+100.0*pt,profit)&&profit>0)
         return profit/100.0;
      return 0;
   }
   double profitCheck=0, ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(ask>0 && OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1.0,ask,ask+100.0*pt,profitCheck)&&profitCheck>0) {
      double vppChk = profitCheck/100.0;
      double err    = MathAbs(vpp-vppChk)/vppChk*100.0;
      PrintFormat("VPP: Formula=$%.6f  OCP=$%.6f  Err=%.2f%%", vpp, vppChk, err);
      if(err > 5.0) { Print("WARNING: Usando valor de OrderCalcProfit"); return vppChk; }
   }
   return vpp;
}

double CalculateLotSize(double slPts)
{
   if(g_cachedVPP <= 0) return 0;
   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double lRaw  = RiskAmountUSD / (slPts * g_cachedVPP);
   double lots  = MathMax(MathMin(MathRound(lRaw/vStep)*vStep, vMax), vMin);
   double marginReq=0;
   if(OrderCalcMargin(ORDER_TYPE_BUY,_Symbol,lots,SymbolInfoDouble(_Symbol,SYMBOL_ASK),marginReq))
      if(marginReq > AccountInfoDouble(ACCOUNT_MARGIN_FREE)*0.90)
      { Print("RANGE SKIP: margen insuficiente"); return 0; }
   return lots;
}

//+------------------------------------------------------------------+
//  OnInit
//+------------------------------------------------------------------+
int OnInit()
{
   if(_Period != PERIOD_M5)           { Alert("Ejecutar en M5"); return INIT_FAILED; }
   if(BE_BufferPct<0||BE_BufferPct>500) { Alert("BE_BufferPct fuera de rango (0-500)"); return INIT_FAILED; }
   if(!(TP1_RR>0&&TP2_RR>TP1_RR&&TP3_RR>TP2_RR)) { Alert("TP1<TP2<TP3 requerido"); return INIT_FAILED; }
   if(SessionCloseHour>23)            { Alert("SessionCloseHour debe ser 0-23, valor: ",SessionCloseHour); return INIT_FAILED; }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(20);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   g_cachedVPP = GetValuePerPoint();
   if(g_cachedVPP <= 0) { Alert("FATAL: No se puede determinar ValuePerPoint"); return INIT_FAILED; }

   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   Print("=== BreakoutNY v4.1 DJI30 FundingPips ===");
   PrintFormat("  VPP=$%.6f | Riesgo=$%.2f | CierreSession=%02d:00 UTC",
               g_cachedVPP, RiskAmountUSD, SessionCloseHour);
   PrintFormat("  BE=%.0f%% TP=%.1fR/%.1fR/%.1fR | Días: Lun=%s Mar=%s Mié=%s Jue=%s Vie=%s",
               BE_BufferPct, TP1_RR, TP2_RR, TP3_RR,
               FilterMonday?"S":"N", FilterTuesday?"S":"N", FilterWednesday?"S":"N",
               FilterThursday?"S":"N", FilterFriday?"S":"N");
   Print("  Tabla de lotes:");
   double slArr[] = {8200, 10000, 12000, 16000, 20000};
   for(int i=0; i<ArraySize(slArr); i++) {
      double lR = RiskAmountUSD/(slArr[i]*g_cachedVPP);
      double lF = MathMax(MathMin(MathRound(lR/vStep)*vStep, vMax), vMin);
      PrintFormat("    SL=%5.0fpts -> lotes=%.3f -> riesgo=$%.2f",
                  slArr[i], lF, lF*slArr[i]*g_cachedVPP);
   }
   Print("==========================================");

   g_atrHandle = iATR(_Symbol, PERIOD_M5, ATR_Period);
   if(g_atrHandle == INVALID_HANDLE) { Print("Error handle ATR"); return INIT_FAILED; }

   if(EnableCSV) {
      string path = CSVFileName + ".csv";
      g_csvHandle = FileOpen(path, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
      if(g_csvHandle != INVALID_HANDLE) {
         FileSeek(g_csvHandle, 0, SEEK_END);
         if(FileTell(g_csvHandle)==0)
            FileWrite(g_csvHandle,"Fecha","Dia","Dir","Lotes","VPP","Riesgo$",
                      "Entry","SL","BE","TP1","TP2","TP3","SL_pts","ATR");
         FileFlush(g_csvHandle);
      }
   }

   // Panel visual inicial + historial
   if(VIS_Enable) {
      VisRedrawAll();  // incluye VisDrawMottoPanel + VisUpdatePanel internamente
   }
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   VisPurgeAll();
   if(g_csvHandle != INVALID_HANDLE) { FileFlush(g_csvHandle); FileClose(g_csvHandle); }
   if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
//  OnTick — lógica principal de trading
//+------------------------------------------------------------------+
void OnTick()
{
   datetime serverNow = TimeCurrent();
   datetime utcNow    = serverNow - ServerOffsetHours*3600;
   MqlDateTime utcDT; TimeToStruct(utcNow, utcDT);

   //--- Reset diario
   if(utcDT.day != g_lastResetDay) {
      g_lastResetDay  = utcDT.day;
      g_rangeFormed   = false; g_rangeAttempted=false;
      g_tradedToday   = false; g_brkPending=false; g_brkDir=0;
      g_rangeHigh = g_rangeLow = g_slDistance = g_cachedLots = 0;
      g_beActivated = g_tp2Hit = false; g_entryPrice = g_originalSL = 0;
      g_sessionClosePrinted = false;
      // Borrar solo el día anterior (no todo el histórico)
      if(vis_dayTag != "") VisDeleteDay(vis_dayTag);
      vis_dayTag   = VisMakeDayTag();
      vis_hasTrade = false;
      g_tradeDir = "";
      // Redibujar todo el histórico incluido el día anterior recién cerrado
      if(VIS_Enable) {
         VisRedrawAll();  // incluye VisDrawMottoPanel + VisUpdatePanel internamente
      }
   }

   //--- Cierre forzoso de sesión
   if(HasOpenPosition()) {
      bool mustClose = (utcDT.hour > SessionCloseHour) ||
                       (utcDT.hour == SessionCloseHour && utcDT.min >= SessionCloseMin);
      if(mustClose) {
         if(!g_sessionClosePrinted) {
            g_sessionClosePrinted = true;
            PrintFormat("SESSION_END: cerrando a las %02d:%02d UTC", utcDT.hour, utcDT.min);
         }
         ClosePosition("SESSION_END");
         return;
      }
      ManagePosition();
      // Actualizar P/L flotante en panel
      if(VIS_Enable && VIS_ShowLabel) {
         double floatPL = PositionGetDouble(POSITION_PROFIT);
         VisUpdatePanel(g_tradeDir, g_slDistance, floatPL, true, false, "");
      }
      return;
   }

   if(g_tradedToday) return;

   //--- Filtro de día — con mensaje visual
   if(!IsTradingDay(utcDT.day_of_week)) {
      if(VIS_Enable && VIS_ShowLabel)
         VisUpdatePanel("", 0, 0, false, true, "Día no operado");
      return;
   }

   datetime curBar = iTime(_Symbol, PERIOD_M5, 0);
   bool newBar     = (curBar != g_lastBarTime);
   if(newBar) g_lastBarTime = curBar;

   //--- Intentar formar el rango (solo 1 vez por día)
   if(!g_rangeFormed && !g_rangeAttempted) {
      int totalMin = utcDT.hour*60 + utcDT.min;
      if(totalMin >= 14*60+50) TryFormRange(utcDT);
   }
   if(!g_rangeFormed) return;

   //--- Ventana de entrada
   int totMin = utcDT.hour*60 + utcDT.min;
   if(totMin < 14*60+50 || totMin >= 14*60+50+EntryWindowEnd_Min) return;

   //--- Detectar ruptura
   if(!g_brkPending) {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(ask > g_rangeHigh) {
         g_brkPending=true; g_brkDir=1; g_brkBarTime=curBar;
         PrintFormat("RUPTURA UP: ask=%.2f > H=%.2f", ask, g_rangeHigh);
      } else if(bid < g_rangeLow) {
         g_brkPending=true; g_brkDir=-1; g_brkBarTime=curBar;
         PrintFormat("RUPTURA DN: bid=%.2f < L=%.2f", bid, g_rangeLow);
      }
   }

   //--- Confirmar en siguiente vela
   if(g_brkPending && newBar && curBar != g_brkBarTime) {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      bool ok = (g_brkDir==1 && ask>g_rangeHigh) || (g_brkDir==-1 && bid<g_rangeLow);
      if(ok) ExecuteTrade(g_brkDir);
      else { Print("Falsa ruptura — cancelada"); g_brkPending=false; g_brkDir=0; }
   }

   //--- Panel en espera de señal
   if(VIS_Enable && VIS_ShowLabel && !g_brkPending)
      VisUpdatePanel("", 0, 0, false, false, "");
}

//+------------------------------------------------------------------+
void TryFormRange(MqlDateTime &utcDT)
{
   datetime srvMid = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",
                                               utcDT.year, utcDT.mon, utcDT.day));
   datetime c1 = srvMid + (14+ServerOffsetHours)*3600 + 35*60;
   datetime c2 = srvMid + (14+ServerOffsetHours)*3600 + 40*60;
   datetime c3 = srvMid + (14+ServerOffsetHours)*3600 + 45*60;

   int i1=iBarShift(_Symbol,PERIOD_M5,c1,false);
   int i2=iBarShift(_Symbol,PERIOD_M5,c2,false);
   int i3=iBarShift(_Symbol,PERIOD_M5,c3,false);
   if(i1<0||i2<0||i3<0) return; // velas aún no disponibles — reintentar

   // Marcar como intentado — todos los exits siguientes imprimen 1 sola vez
   g_rangeAttempted = true;

   if(MathAbs((int)(iTime(_Symbol,PERIOD_M5,i1)-c1))>300 ||
      MathAbs((int)(iTime(_Symbol,PERIOD_M5,i2)-c2))>300 ||
      MathAbs((int)(iTime(_Symbol,PERIOD_M5,i3)-c3))>300)
   { Print("RANGE SKIP: Desfase de velas — verificar ServerOffsetHours"); return; }

   g_rangeHigh  = MathMax(iHigh(_Symbol,PERIOD_M5,i1),MathMax(iHigh(_Symbol,PERIOD_M5,i2),iHigh(_Symbol,PERIOD_M5,i3)));
   g_rangeLow   = MathMin(iLow(_Symbol, PERIOD_M5,i1),MathMin(iLow(_Symbol, PERIOD_M5,i2),iLow(_Symbol, PERIOD_M5,i3)));
   g_slDistance = (g_rangeHigh - g_rangeLow) / _Point;

   if(g_slDistance < MinSL_Points) {
      PrintFormat("RANGE SKIP: dist=%.0fpts < MinSL=%.0fpts (rango muy estrecho)", g_slDistance, MinSL_Points);
      if(VIS_Enable) VisUpdatePanel("",0,0,false,true,
         StringFormat("Rango filtrado (%.0fpts < %.0f)", g_slDistance, MinSL_Points));
      return;
   }
   if(g_slDistance > MaxSL_Points) {
      PrintFormat("RANGE SKIP: dist=%.0fpts > MaxSL=%.0fpts (rango muy amplio)", g_slDistance, MaxSL_Points);
      if(VIS_Enable) VisUpdatePanel("",0,0,false,true,
         StringFormat("Rango filtrado (%.0fpts > %.0f)", g_slDistance, MaxSL_Points));
      return;
   }
   if(ATR_FilterEnable && !CheckATRFilter()) return;

   g_cachedLots = CalculateLotSize(g_slDistance);
   if(g_cachedLots <= 0) { Print("RANGE SKIP: cálculo de lotes fallido"); return; }

   g_rangeFormed = true;
   vis_dayTag = VisMakeDayTag();
   PrintFormat("RANGE VÁLIDO: H=%.2f L=%.2f dist=%.0fpts lotes=%.3f riesgo=$%.2f",
               g_rangeHigh, g_rangeLow, g_slDistance, g_cachedLots, g_cachedLots*g_slDistance*g_cachedVPP);
   
}

//+------------------------------------------------------------------+
bool CheckATRFilter()
{
   double cur[]; ArraySetAsSeries(cur, true);
   if(CopyBuffer(g_atrHandle,0,1,1,cur) <= 0) return true;
   double base[]; ArraySetAsSeries(base, true);
   int copied = CopyBuffer(g_atrHandle,0,1,ATR_BaselineDays*78,base);
   if(copied < 10) return true;
   double sum=0; for(int i=0;i<copied;i++) sum+=base[i];
   double baseline = sum/copied;
   if(cur[0] < baseline*ATR_MinMultiplier) {
      PrintFormat("RANGE SKIP: ATR bajo (%.4f < %.4f baseline × %.1f)", cur[0], baseline, ATR_MinMultiplier);
      if(VIS_Enable) VisUpdatePanel("",0,0,false,true,"ATR filtrado (bajo)");
      return false;
   }
   if(cur[0] > baseline*ATR_MaxMultiplier) {
      PrintFormat("RANGE SKIP: ATR alto (%.4f > %.4f baseline × %.1f)", cur[0], baseline, ATR_MaxMultiplier);
      if(VIS_Enable) VisUpdatePanel("",0,0,false,true,"ATR filtrado (alto)");
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
void ExecuteTrade(int dir)
{
   if(g_cachedLots <= 0) return;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double slD = g_slDistance * _Point;

   if(dir == 1) {
      g_entryPrice = ask;
      g_originalSL = NormalizeDouble(ask - slD,                      _Digits);
      g_beLevel    = NormalizeDouble(ask + slD*(BE_BufferPct/100.0), _Digits);
      g_tp1Level   = NormalizeDouble(ask + slD*TP1_RR,               _Digits);
      g_tp2Level   = NormalizeDouble(ask + slD*TP2_RR,               _Digits);
      g_tp3Level   = NormalizeDouble(ask + slD*TP3_RR,               _Digits);
      if(trade.Buy(g_cachedLots,_Symbol,ask,g_originalSL,g_tp3Level,"BreakoutNY_BUY")) {
         g_tradedToday=true; g_brkPending=false; g_beActivated=false; g_tp2Hit=false;
         g_tradeDir = "buy";
         PrintFormat("BUY %.3f | SL=%.2f BE=%.2f TP1=%.2f TP2=%.2f TP3=%.2f",
                     g_cachedLots,g_originalSL,g_beLevel,g_tp1Level,g_tp2Level,g_tp3Level);
         vis_hasTrade = true; VisRedrawToday();
         LogTrade("BUY");
      }
   } else {
      g_entryPrice = bid;
      g_originalSL = NormalizeDouble(bid + slD,                      _Digits);
      g_beLevel    = NormalizeDouble(bid - slD*(BE_BufferPct/100.0), _Digits);
      g_tp1Level   = NormalizeDouble(bid - slD*TP1_RR,               _Digits);
      g_tp2Level   = NormalizeDouble(bid - slD*TP2_RR,               _Digits);
      g_tp3Level   = NormalizeDouble(bid - slD*TP3_RR,               _Digits);
      if(trade.Sell(g_cachedLots,_Symbol,bid,g_originalSL,g_tp3Level,"BreakoutNY_SELL")) {
         g_tradedToday=true; g_brkPending=false; g_beActivated=false; g_tp2Hit=false;
         g_tradeDir = "sell";
         PrintFormat("SELL %.3f | SL=%.2f BE=%.2f TP1=%.2f TP2=%.2f TP3=%.2f",
                     g_cachedLots,g_originalSL,g_beLevel,g_tp1Level,g_tp2Level,g_tp3Level);
         vis_hasTrade = true; VisRedrawToday();
         LogTrade("SELL");
      }
   }
}

//+------------------------------------------------------------------+
void ManagePosition()
{
   if(!HasOpenPosition()) return;
   double curSL  = PositionGetDouble(POSITION_SL);
   long   posTyp = PositionGetInteger(POSITION_TYPE);

   if(posTyp == POSITION_TYPE_BUY) {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(!g_beActivated && bid >= g_beLevel) {
         g_beActivated = true;
         double nSL = NormalizeDouble(g_entryPrice, _Digits);
         if(nSL > curSL+_Point) {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "") VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, nSL);
            PrintFormat("BE activado — SL movido a entrada %.2f", nSL);
         }
      }
      if(!g_tp2Hit && bid >= g_tp2Level) {
         g_tp2Hit = true;
         double nSL = NormalizeDouble(g_tp1Level, _Digits);
         if(nSL > curSL+_Point) {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "") VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, nSL);
            PrintFormat("TP2 alcanzado — SL asegurado en TP1 %.2f", nSL);
         }
         if(EnablePartials) DoPartialClose(TP2_ClosePct);
      }
   } else if(posTyp == POSITION_TYPE_SELL) {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(!g_beActivated && ask <= g_beLevel) {
         g_beActivated = true;
         double nSL = NormalizeDouble(g_entryPrice, _Digits);
         if(nSL < curSL-_Point) {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "") VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, nSL);
            PrintFormat("BE activado — SL movido a entrada %.2f", nSL);
         }
      }
      if(!g_tp2Hit && ask <= g_tp2Level) {
         g_tp2Hit = true;
         double nSL = NormalizeDouble(g_tp1Level, _Digits);
         if(nSL < curSL-_Point) {
            trade.PositionModify(_Symbol, nSL, g_tp3Level);
            if(VIS_Enable && vis_dayTag != "") VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, nSL);
            PrintFormat("TP2 alcanzado — SL asegurado en TP1 %.2f", nSL);
         }
         if(EnablePartials) DoPartialClose(TP2_ClosePct);
      }
   }
}

//+------------------------------------------------------------------+
void DoPartialClose(double pct)
{
   if(pct<=0||pct>100) return;
   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double cur   = PositionGetDouble(POSITION_VOLUME);
   double toClose = MathFloor(cur*pct/100.0/vStep)*vStep;
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
   // Borrar solo hoy y redibujar — preserva el histórico visible
   if(VIS_Enable && vis_dayTag != "") {
      VisDeleteDay(vis_dayTag);
      VisRedrawToday(); // redibuja el día con el resultado final en velas
      VisDrawMottoPanel();
   }
}

bool IsTradingDay(int dow)
{
   if(dow==0||dow==6) return false;
   if(dow==1&&!FilterMonday)    return false;
   if(dow==2&&!FilterTuesday)   return false;
   if(dow==3&&!FilterWednesday) return false;
   if(dow==4&&!FilterThursday)  return false;
   if(dow==5&&!FilterFriday)    return false;
   return true;
}

void LogTrade(string dir)
{
   if(!EnableCSV||g_csvHandle==INVALID_HANDLE) return;
   datetime utcNow = TimeCurrent()-ServerOffsetHours*3600;
   MqlDateTime dt; TimeToStruct(utcNow, dt);
   string dn[] = {"Dom","Lun","Mar","Mié","Jue","Vie","Sáb"};
   double atrBuf[]; ArraySetAsSeries(atrBuf, true);
   double atr=0; if(CopyBuffer(g_atrHandle,0,1,1,atrBuf)>0) atr=atrBuf[0];
   double risk = g_cachedLots*g_slDistance*g_cachedVPP;
   FileWrite(g_csvHandle,
             TimeToString(utcNow,TIME_DATE), dn[dt.day_of_week], dir,
             DoubleToString(g_cachedLots,3), DoubleToString(g_cachedVPP,6), DoubleToString(risk,2),
             DoubleToString(g_entryPrice,_Digits), DoubleToString(g_originalSL,_Digits),
             DoubleToString(g_beLevel,_Digits), DoubleToString(g_tp1Level,_Digits),
             DoubleToString(g_tp2Level,_Digits), DoubleToString(g_tp3Level,_Digits),
             DoubleToString(g_slDistance,0), DoubleToString(atr,4));
   FileFlush(g_csvHandle);
}


//+------------------------------------------------------------------+
//  MÓDULO VISUAL — idéntico al NAS100 v9.1 adaptado para DJI30
//  Fuente de verdad: BreakoutNY_NAS100_FP.mq5
//  Lógica: lee velas M5 con CopyRates — NO depende del historial de deals
//+------------------------------------------------------------------+

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
void VisLevel(const string name,
              datetime t1, datetime t2, double price,
              color clr, ENUM_LINE_STYLE style, int width,
              const string label)
{
   VisSegment(name, t1, t2, price, price, clr, style, width, false);
   datetime tLabel   = t2 + (datetime)(PeriodSeconds(PERIOD_M5));
   string   priceStr = DoubleToString(price, _Digits <= 5 ? 1 : _Digits);
   VisText(name + "_LBL", tLabel, price,
           " " + label + " " + priceStr,
           clr, 7, ANCHOR_LEFT_UPPER, false);
}

// Actualiza el precio de una línea ya dibujada (para SL dinámico BE/FASE2)
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
   string priceStr = DoubleToString(newPrice, _Digits <= 5 ? 1 : _Digits);
   ObjectSetString(0, lblName, OBJPROP_TEXT, lbl + priceStr + " ");
   ChartRedraw();
}

//===================================================================
//  DIBUJAR UN DÍA COMPLETO (rango + niveles si hubo ruptura)
//  Fuente de verdad: velas M5 via CopyRates — sin depender de deals
//===================================================================

bool VisGetCandle(const MqlRates &R[], int total,
                  datetime dayUTC,
                  int h, int m,
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
         hi = R[i].high;  lo = R[i].low;  barTime = R[i].time;
         return true;
      }
   }
   return false;
}

void VisDrawDay(const MqlRates &R[], int total, datetime dayUTC)
{
   // ── Obtener las 3 velas del rango (14:35 / 14:40 / 14:45 UTC) ──
   double h35,l35, h40,l40, h45,l45;
   datetime t35, t40, t45;
   if(!VisGetCandle(R, total, dayUTC, 14,35, h35,l35,t35)) return;
   if(!VisGetCandle(R, total, dayUTC, 14,40, h40,l40,t40)) return;
   if(!VisGetCandle(R, total, dayUTC, 14,45, h45,l45,t45)) return;

   // ── Calcular rango — idéntico a la lógica de trading ──────────
   double rH    = MathMax(h35, MathMax(h40, h45));
   double rL    = MathMin(l35, MathMin(l40, l45));
   double slD   = rH - rL;               // distancia en precio
   double slPts = slD / _Point;          // en puntos

   MqlDateTime dt; TimeToStruct(dayUTC, dt);
   string tag = StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);

   datetime tRangeEnd = t45 + 300;       // fin vela 14:45 (5 min)

   // ── Zona del rango — rectángulo + bordes ──────────────────────
   string nBox = VIS_PFX + "BOX_" + tag;
   if(ObjectFind(0, nBox) < 0)
      ObjectCreate(0, nBox, OBJ_RECTANGLE, 0, t35, rH, tRangeEnd, rL);
   ObjectSetInteger(0, nBox, OBJPROP_COLOR,      VIS_ColRange);
   ObjectSetInteger(0, nBox, OBJPROP_BGCOLOR,    VIS_ColRange);
   ObjectSetInteger(0, nBox, OBJPROP_FILL,       true);
   ObjectSetInteger(0, nBox, OBJPROP_BACK,       true);
   ObjectSetInteger(0, nBox, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nBox, OBJPROP_HIDDEN,     true);

   VisSegment(VIS_PFX+"RH_"+tag,
              t35, tRangeEnd, rH, rH,
              VIS_ColRangeBorder, STYLE_SOLID, 2, true);
   VisSegment(VIS_PFX+"RL_"+tag,
              t35, tRangeEnd, rL, rL,
              VIS_ColRangeBorder, STYLE_SOLID, 2, true);

   VisText(VIS_PFX+"LRHI_"+tag,
           t35, rH, "  RANGE HIGH",
           VIS_ColRangeBorder, 8, ANCHOR_LEFT_LOWER, false);
   VisText(VIS_PFX+"LRLO_"+tag,
           t35, rL, "  RANGE LOW",
           VIS_ColRangeBorder, 8, ANCHOR_LEFT_UPPER, false);

   // ── Buscar ruptura en ventana 14:50 – 14:50+EntryWindowEnd_Min ─
   double   eEntry=0, eSL=0, eTp1=0, eTp2=0, eTp3=0, eBE=0;
   string   eDir="";
   datetime eBreak=0;
   bool     broke=false;

   for(int i = total - 1; i >= 0; i--)  // orden cronológico
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      datetime barDay = StringToTime(
         StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
      if(barDay != dayUTC) continue;

      int totalMin = u.hour * 60 + u.min;
      int winStart = 14 * 60 + 50;
      int winEnd   = winStart + EntryWindowEnd_Min;
      bool inWin   = (totalMin >= winStart && totalMin < winEnd);
      if(!inWin) continue;

      if(R[i].high > rH)  // BUY breakout
      {
         // Con ConfirmOnClose: entrada = open de la vela siguiente
         double entryPx = (i + 1 < total) ? R[i+1].open : R[i].close;
         eEntry = entryPx;
         eDir   = "buy";
         eBreak = R[i].time;
         eSL    = NormalizeDouble(eEntry - slD,                          _Digits);
         eTp1   = NormalizeDouble(eEntry + slD * TP1_RR,                 _Digits);
         eTp2   = NormalizeDouble(eEntry + slD * TP2_RR,                 _Digits);
         eTp3   = NormalizeDouble(eEntry + slD * TP3_RR,                 _Digits);
         eBE    = NormalizeDouble(eEntry + slD * (BE_BufferPct / 100.0), _Digits);
         broke  = true;
         break;
      }
      if(R[i].low < rL)   // SELL breakout
      {
         double entryPx = (i + 1 < total) ? R[i+1].open : R[i].close;
         eEntry = entryPx;
         eDir   = "sell";
         eBreak = R[i].time;
         eSL    = NormalizeDouble(eEntry + slD,                          _Digits);
         eTp1   = NormalizeDouble(eEntry - slD * TP1_RR,                 _Digits);
         eTp2   = NormalizeDouble(eEntry - slD * TP2_RR,                 _Digits);
         eTp3   = NormalizeDouble(eEntry - slD * TP3_RR,                 _Digits);
         eBE    = NormalizeDouble(eEntry - slD * (BE_BufferPct / 100.0), _Digits);
         broke  = true;
         break;
      }
   }

   // ── Niveles de la operación ────────────────────────────────────
   if(broke)
   {
      bool     isBuy = (eDir == "buy");
      datetime tEnd  = eBreak + (datetime)(VIS_ExtendBars * PeriodSeconds(PERIOD_M5));

      // Flecha → 2 velas antes del rango — indica dirección de ruptura
      double   arrPx = isBuy ? rH : rL;
      datetime tArr  = t35 - (datetime)(2 * PeriodSeconds(PERIOD_M5));
      string   nArr  = VIS_PFX + "ARR_" + tag;
      if(ObjectFind(0, nArr) < 0)
         ObjectCreate(0, nArr, OBJ_ARROW, 0, tArr, arrPx);
      ObjectSetDouble(0,  nArr, OBJPROP_PRICE,      arrPx);
      ObjectSetInteger(0, nArr, OBJPROP_TIME,       tArr, 0);
      ObjectSetInteger(0, nArr, OBJPROP_ARROWCODE,  232);   // → Wingdings
      ObjectSetInteger(0, nArr, OBJPROP_COLOR,      isBuy ? VIS_ColTP3 : VIS_ColSL);
      ObjectSetInteger(0, nArr, OBJPROP_WIDTH,      3);
      ObjectSetInteger(0, nArr, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nArr, OBJPROP_HIDDEN,     true);

      // Línea vertical en la vela de ruptura
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

      // Marcador de cierre de sesión 17:00 UTC
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
      VisText(VIS_PFX+"SCL_"+tag, tClose17, eTp3,
              StringFormat(" %d:%02d UTC", SessionCloseHour, SessionCloseMin),
              C'100,100,160', 7, ANCHOR_LEFT_UPPER, false);
   }
   else
   {
      // Día sin ruptura — texto indicativo
      VisText(VIS_PFX+"NOBRK_"+tag, tRangeEnd + 300, (rH+rL)/2.0,
              "  sin ruptura",
              C'80,100,130', 7, ANCHOR_LEFT, false);
   }
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

   PrintFormat("VIS: Redibujando %d días históricos (últimos %d días)",
               nDays, VIS_LookbackDays);
   for(int i = 0; i < nDays; i++)
      VisDrawDay(R, copied, days[i]);

   VisDrawMottoPanel();
   VisUpdatePanel("", 0, 0, false, false, "");
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
//  PANEL FIJO — esquina superior derecha
//===================================================================

void VisUpdatePanel(string direction, double slPts, double netPL,
                    bool hasTrade, bool isFiltered, string filterReason)
{
   if(!VIS_Enable || !VIS_ShowLabel) return;

   MqlDateTime u; TimeToStruct(TimeCurrent() - (long)ServerOffsetHours*3600, u);
   string days[] = {"Dom","Lun","Mar","Mié","Jue","Vie","Sáb"};
   string dayStr  = days[u.day_of_week];
   string dateStr = StringFormat("%02d/%02d/%04d", u.day, u.mon, u.year);

   string line1, line2, line3, line4, line5;
   color  panelColor;

   if(isFiltered)
   {
      line1      = "BreakoutNY v4.1  |  " + _Symbol;
      line2      = dayStr + " " + dateStr;
      line3      = "★  " + filterReason;
      line4      = "Riesgo: $" + DoubleToString(RiskAmountUSD, 0) + "/trade";
      line5      = "";
      panelColor = C'100,100,140';
   }
   else if(!hasTrade && direction == "")
   {
      line1 = "BreakoutNY v4.1  |  " + _Symbol;
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
      bool isBuy   = (direction == "buy");
      string arrow = isBuy ? "▲ BUY" : "▼ SELL";
      string plStr = (netPL >= 0)
         ? "+ $" + DoubleToString(netPL, 0)
         : "- $" + DoubleToString(MathAbs(netPL), 0);
      line1 = "BreakoutNY v4.1  |  " + _Symbol + "  |  " + dayStr;
      line2 = arrow + "  |  SL " + DoubleToString(slPts, 1) + " pts" +
              "  |  TP3 " + DoubleToString(slPts * TP3_RR, 1) + " pts";
      line3 = "Riesgo $" + DoubleToString(RiskAmountUSD, 0) +
              "  |  BE " + DoubleToString(BE_BufferPct, 0) + "%";
      line4 = hasTrade ? ("P/L flotante:  " + plStr) : "Sin posición abierta";
      line5 = "";
      panelColor = isBuy ? VIS_ColTP3 : VIS_ColSL;
   }

   string pnames[] = {"PNL1","PNL2","PNL3","PNL4","PNL5"};
   string ptexts[5]; ptexts[0]=line1; ptexts[1]=line2;
   ptexts[2]=line3;  ptexts[3]=line4; ptexts[4]=line5;
   int    pyoffs[] = {15, 30, 45, 60, 75};
   int    pfonts[] = {9,  9,  8,  9,   8};

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
//  PANEL INFERIOR — frase + identidad del EA
//===================================================================

void VisDrawMottoPanel()
{
   if(!VIS_Enable) return;

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

   string nm3 = VIS_PFX + "MOTTO3";
   if(ObjectFind(0, nm3) < 0) ObjectCreate(0, nm3, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm3, OBJPROP_CORNER,    CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nm3, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, nm3, OBJPROP_YDISTANCE, 10);
   ObjectSetString(0,  nm3, OBJPROP_TEXT,
      StringFormat("BreakoutNY v4.1  ·  DJI30 FundingPips  ·  Magic %d  ·  Jose Yanez  ·  IS PF=1.609  ·  OOS PF=2.017  ·  MaxDD<4%%",
                   (int)MagicNumber));
   ObjectSetInteger(0, nm3, OBJPROP_COLOR,     C'55,75,110');
   ObjectSetInteger(0, nm3, OBJPROP_FONTSIZE,  7);
   ObjectSetString(0,  nm3, OBJPROP_FONT,      "Consolas");
   ObjectSetInteger(0, nm3, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, nm3, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, nm3, OBJPROP_BACK,      false);

   ChartRedraw();
}
//+------------------------------------------------------------------+
