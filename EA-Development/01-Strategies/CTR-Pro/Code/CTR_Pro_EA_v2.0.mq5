//+------------------------------------------------------------------+
//|                                            CTR_Pro_EA_v2.0.mq5   |
//|                    CTR PRO - Liquidity Sweep Reversal System      |
//|                        Version 2.10  |  MQL5 / MetaTrader 5      |
//+------------------------------------------------------------------+
// v2.10 — Filtros de calidad de sweep:
//   - Filtro de mecha: mecha del sweep >= cuerpo * ratio
//   - Filtro de distancia mínima: penetración >= N ticks
//   Ambos desactivables para optimización independiente.
//+------------------------------------------------------------------+
#property copyright   "CTR Pro EA"
#property link        ""
#property version     "2.10"
#property description "CTR PRO v2.10 - Sweep + filtros de mecha y distancia"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+=================================================================+
//|  ENUMERACIONES                                                   |
//+=================================================================+
enum ENUM_TRADE_DIRECTION
{
   DIRECTION_BOTH = 0,  // Ambos (Compra y Venta)
   DIRECTION_BUY  = 1,  // Solo Compras
   DIRECTION_SELL = 2   // Solo Ventas
};

//+=================================================================+
//|  PARAMETROS DE ENTRADA                                           |
//+=================================================================+
input group "══════════ CONFIGURACION GENERAL ══════════"
input ENUM_TRADE_DIRECTION InpDirection   = DIRECTION_BUY; // Dirección de Operaciones
input int                  InpMaxDrawings = 10;            // Mantener últimos N dibujos
input double               InpRiskUSD     = 50.0;         // Riesgo por Operación (USD)
input int                  InpMaxPerDay   = 1;             // Máx. Operaciones por Día
input int                  InpMaxSpread   = 100;           // Máx. Spread (puntos)
input int                  InpSlippage    = 10;            // Slippage (puntos)

input group "══════════ STOP LOSS / TAKE PROFIT ══════════"
input bool                 InpDynamicSL   = true;          // SL Dinámico (anclado al sweep)
input int                  InpSLBuffer    = 20;            // Buffer SL bajo/sobre sweep (ticks)
input double               InpRR          = 3.0;          // RR — Ratio Riesgo/Recompensa
input double               InpSL_Pips     = 650.0;        // [Manual] Stop Loss (ticks)
input double               InpTP_Pips     = 1950.0;       // [Manual] Take Profit (ticks)

input group "══════════ CONFIRMACION DE SWEEP ══════════"
input bool                 InpWickFilter    = true;          // Activar Filtro de Mecha
input double               InpWickRatio     = 1.5;          // Mecha >= Cuerpo * ratio
input bool                 InpSweepFilter   = true;          // Activar Distancia Mínima Sweep
input int                  InpMinSweepTicks = 15;            // Penetración mínima (ticks)

input group "══════════ BREAK EVEN ══════════"
input bool                 InpBEEnable     = true;          // Activar Break Even
input double               InpBETriggerPct = 50.0;         // Activar BE al X% del recorrido al TP
input int                  InpBEBuffer     = 10;            // Buffer BE sobre entrada (ticks)

input group "══════════ TEMPORIZADOR DE OPERACION ══════════"
input bool                 InpTimerEnable  = true;          // Activar Temporizador
input int                  InpMaxMinutes   = 120;           // Tiempo máx en operación (min)

input group "══════════ DIAS DE OPERACION ══════════"
input bool                 InpMonday      = true;          // Operar Lunes
input bool                 InpTuesday     = true;          // Operar Martes
input bool                 InpWednesday   = true;          // Operar Miércoles
input bool                 InpThursday    = true;          // Operar Jueves
input bool                 InpFriday      = true;          // Operar Viernes

input group "══════════ HORARIO DE SESION (UTC) ══════════"
input int                  InpUTCStartHour = 16;           // Hora Inicio UTC
input int                  InpUTCStartMin  = 40;           // Minuto Inicio UTC
input int                  InpUTCEndHour   = 18;           // Hora Fin UTC
input int                  InpUTCEndMin    = 0;            // Minuto Fin UTC

//+=================================================================+
//|  CONSTANTES INTERNAS                                             |
//+=================================================================+
#define EA_MAGIC   202600
#define EA_PREFIX  "CTR2_"
#define PANEL_X    15
#define PANEL_Y    35
#define PANEL_W    235
#define PANEL_H    322

//+=================================================================+
//|  VARIABLES GLOBALES                                              |
//+=================================================================+
CTrade        g_trade;
CPositionInfo g_pos;

int      g_tradesToday = 0;
double   g_dailyProfit = 0.0;
datetime g_lastBarTime = 0;
datetime g_todayDate   = 0;
bool     g_paused      = false;
int      g_signalCount = 0;

//+=================================================================+
//|  INICIALIZACION                                                  |
//+=================================================================+
int OnInit()
{
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetExpertMagicNumber(EA_MAGIC);
   g_trade.SetAsyncMode(false);

   CreatePanel();

   string slLog = InpDynamicSL ?
                  StringFormat("DIN buffer:%d tks RR:%.1f", InpSLBuffer, InpRR) :
                  StringFormat("MAN SL:%.0f TP:%.0f tks", InpSL_Pips, InpTP_Pips);
   Print("CTR Pro EA v2.00 | ", _Symbol, " ", EnumToString(_Period),
         " | UTC ", InpUTCStartHour, ":", InpUTCStartMin,
         " | SL:", slLog);

   return INIT_SUCCEEDED;
}

//+=================================================================+
//|  DESINICIALIZACION                                               |
//+=================================================================+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, EA_PREFIX);
   Comment("");
}

//+=================================================================+
//|  TICK PRINCIPAL                                                  |
//+=================================================================+
void OnTick()
{
   CheckNewDay();
   UpdatePanel();

   if(InpTimerEnable) CheckTradeTimer();
   if(InpBEEnable)    CheckBreakEven();

   if(g_paused)                        return;
   if(!IsTradingDay())                 return;
   if(!IsInSession())                  return;
   if(g_tradesToday >= InpMaxPerDay)   return;

   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpread)           return;

   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime == g_lastBarTime)        return;
   g_lastBarTime = barTime;

   DetectLiquiditySweep();
}

//+=================================================================+
//|  FILTRO DE MECHA                                                 |
//+=================================================================+
// BUY: mecha inferior >= cuerpo * ratio → rechazo real hacia arriba
// SELL: mecha superior >= cuerpo * ratio → rechazo real hacia abajo
bool PassesWickFilter(bool isBuy)
{
   if(!InpWickFilter) return true;

   double open1  = iOpen (_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double high1  = iHigh (_Symbol, PERIOD_CURRENT, 1);
   double low1   = iLow  (_Symbol, PERIOD_CURRENT, 1);

   double body      = MathAbs(close1 - open1);
   if(body < _Point) body = _Point; // evitar división por doji

   double lowerWick = MathMin(open1, close1) - low1;
   double upperWick = high1 - MathMax(open1, close1);

   if(isBuy)  return (lowerWick >= body * InpWickRatio);
   else       return (upperWick >= body * InpWickRatio);
}

//+=================================================================+
//|  FILTRO DISTANCIA MINIMA DE SWEEP                                |
//+=================================================================+
// El sweep debe penetrar el nivel al menos N ticks — filtra roces.
bool PassesMinSweepFilter(bool isBuy, double refLevel)
{
   if(!InpSweepFilter || InpMinSweepTicks <= 0) return true;

   double minDist = InpMinSweepTicks * _Point;

   if(isBuy)
   {
      double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
      return ((refLevel - low1) >= minDist);
   }
   else
   {
      double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
      return ((high1 - refLevel) >= minDist);
   }
}

//+=================================================================+
//|  TEMPORIZADOR — CIERRE FORZADO                                   |
//+=================================================================+
void CheckTradeTimer()
{
   datetime now = TimeCurrent();
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Symbol() != _Symbol) continue;
      if(g_pos.Magic()  != EA_MAGIC) continue;

      int elapsedMin = (int)((now - g_pos.Time()) / 60);
      if(elapsedMin >= InpMaxMinutes)
      {
         PrintFormat("TIMER: Cerrando posición #%d tras %d minutos", g_pos.Ticket(), elapsedMin);
         g_trade.PositionClose(g_pos.Ticket());
      }
   }
}

//+=================================================================+
//|  BREAK EVEN                                                      |
//+=================================================================+
// Mueve el SL a entrada + buffer cuando el precio alcanza
// InpBETriggerPct % del recorrido entre entrada y TP.
void CheckBreakEven()
{
   double beBuffer = InpBEBuffer * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Symbol() != _Symbol) continue;
      if(g_pos.Magic()  != EA_MAGIC) continue;

      double entry   = g_pos.PriceOpen();
      double sl      = g_pos.StopLoss();
      double tp      = g_pos.TakeProfit();
      double beSL;

      if(g_pos.PositionType() == POSITION_TYPE_BUY)
      {
         beSL = entry + beBuffer;
         if(sl >= beSL) continue; // ya está en BE o mejor

         double tpDist     = tp - entry;
         double triggerPrice = entry + tpDist * (InpBETriggerPct / 100.0);

         if(SymbolInfoDouble(_Symbol, SYMBOL_BID) >= triggerPrice)
         {
            if(g_trade.PositionModify(g_pos.Ticket(), beSL, tp))
               PrintFormat("BE activado BUY #%d | nuevo SL:%.5f", g_pos.Ticket(), beSL);
         }
      }
      else if(g_pos.PositionType() == POSITION_TYPE_SELL)
      {
         beSL = entry - beBuffer;
         if(sl <= beSL) continue; // ya está en BE o mejor

         double tpDist      = entry - tp;
         double triggerPrice = entry - tpDist * (InpBETriggerPct / 100.0);

         if(SymbolInfoDouble(_Symbol, SYMBOL_ASK) <= triggerPrice)
         {
            if(g_trade.PositionModify(g_pos.Ticket(), beSL, tp))
               PrintFormat("BE activado SELL #%d | nuevo SL:%.5f", g_pos.Ticket(), beSL);
         }
      }
   }
}

//+=================================================================+
//|  DETECCION DE BARRIDO DE LIQUIDEZ                                |
//+=================================================================+
void DetectLiquiditySweep()
{
   double high1  = iHigh (_Symbol, PERIOD_CURRENT, 1);
   double low1   = iLow  (_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double high2  = iHigh (_Symbol, PERIOD_CURRENT, 2);
   double low2   = iLow  (_Symbol, PERIOD_CURRENT, 2);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- SEÑAL DE COMPRA
   if(InpDirection == DIRECTION_BOTH || InpDirection == DIRECTION_BUY)
   {
      bool sweepLow = (low1 < low2) && (close1 > low2);
      if(sweepLow
         && PassesWickFilter(true)
         && PassesMinSweepFilter(true, low2))
      {
         double entryBuy, slBuy, tpBuy, slDist;

         if(InpDynamicSL)
         {
            slBuy  = low1 - InpSLBuffer * _Point;
            slDist = ask - slBuy;
            tpBuy  = ask + slDist * InpRR;
         }
         else
         {
            slDist = InpSL_Pips * _Point;
            slBuy  = ask - slDist;
            tpBuy  = ask + InpTP_Pips * _Point;
         }
         entryBuy = ask;

         if(slDist <= 0.0) return;
         double lots = CalcLots(slDist);

         if(lots > 0.0 && g_trade.Buy(lots, _Symbol, entryBuy, slBuy, tpBuy, "CTR BUY"))
         {
            g_tradesToday++;
            DrawSignal(true, entryBuy, slBuy, tpBuy,
                       iTime(_Symbol, PERIOD_CURRENT, 1), low1, low2);
            PrintFormat("CTR BUY | Entry:%.5f SL:%.5f TP:%.5f Lots:%.2f | SLDist:%d tks RR:%.1f | SweepDist:%d tks",
                        entryBuy, slBuy, tpBuy, lots,
                        (int)(slDist/_Point),
                        InpDynamicSL ? InpRR : (InpTP_Pips/InpSL_Pips),
                        (int)((low2 - low1) / _Point));
         }
      }
   }

   //--- SEÑAL DE VENTA
   if(InpDirection == DIRECTION_BOTH || InpDirection == DIRECTION_SELL)
   {
      bool sweepHigh = (high1 > high2) && (close1 < high2);
      if(sweepHigh
         && PassesWickFilter(false)
         && PassesMinSweepFilter(false, high2))
      {
         double entrySell, slSell, tpSell, slDist;

         if(InpDynamicSL)
         {
            slSell = high1 + InpSLBuffer * _Point;
            slDist = slSell - bid;
            tpSell = bid - slDist * InpRR;
         }
         else
         {
            slDist = InpSL_Pips * _Point;
            slSell = bid + slDist;
            tpSell = bid - InpTP_Pips * _Point;
         }
         entrySell = bid;

         if(slDist <= 0.0) return;
         double lots = CalcLots(slDist);

         if(lots > 0.0 && g_trade.Sell(lots, _Symbol, entrySell, slSell, tpSell, "CTR SELL"))
         {
            g_tradesToday++;
            DrawSignal(false, entrySell, slSell, tpSell,
                       iTime(_Symbol, PERIOD_CURRENT, 1), high1, high2);
            PrintFormat("CTR SELL | Entry:%.5f SL:%.5f TP:%.5f Lots:%.2f | SLDist:%d tks RR:%.1f | SweepDist:%d tks",
                        entrySell, slSell, tpSell, lots,
                        (int)(slDist/_Point),
                        InpDynamicSL ? InpRR : (InpTP_Pips/InpSL_Pips),
                        (int)((high1 - high2) / _Point));
         }
      }
   }
}

//+=================================================================+
//|  CALCULO DE LOTES POR RIESGO EN USD                              |
//+=================================================================+
double CalcLots(double slDistPoints)
{
   if(slDistPoints <= 0.0) return 0.0;

   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lotStep  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(tickSize == 0 || tickVal == 0) return minLot;

   double pointVal = (tickVal / tickSize) * _Point;
   if(pointVal == 0) return minLot;

   double rawLots = InpRiskUSD / ((slDistPoints / _Point) * pointVal);
   double lots    = MathFloor(rawLots / lotStep) * lotStep;
   return MathMax(minLot, MathMin(maxLot, lots));
}

//+=================================================================+
//|  VERIFICAR NUEVO DIA (UTC)                                       |
//+=================================================================+
void CheckNewDay()
{
   MqlDateTime dt;
   TimeToStruct(TimeGMT(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));

   if(today != g_todayDate)
   {
      g_todayDate   = today;
      g_tradesToday = 0;
      g_dailyProfit = 0.0;
   }

   g_dailyProfit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(g_pos.SelectByIndex(i))
         if(g_pos.Symbol() == _Symbol && g_pos.Magic() == EA_MAGIC)
            g_dailyProfit += g_pos.Profit() + g_pos.Swap() + g_pos.Commission();
}

//+=================================================================+
//|  FILTRO DE DIA DE SEMANA (UTC)                                   |
//+=================================================================+
bool IsTradingDay()
{
   MqlDateTime dt;
   TimeToStruct(TimeGMT(), dt);
   switch(dt.day_of_week)
   {
      case 1: return InpMonday;
      case 2: return InpTuesday;
      case 3: return InpWednesday;
      case 4: return InpThursday;
      case 5: return InpFriday;
   }
   return false;
}

//+=================================================================+
//|  FILTRO DE SESION (UTC pura)                                     |
//+=================================================================+
bool IsInSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeGMT(), dt);
   int now   = dt.hour * 60 + dt.min;
   int start = InpUTCStartHour * 60 + InpUTCStartMin;
   int end   = InpUTCEndHour   * 60 + InpUTCEndMin;
   return (now >= start && now < end);
}

//+=================================================================+
//|  CERRAR POSICIONES                                               |
//+=================================================================+
void ClosePositions(bool onlyProfit)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(g_pos.SelectByIndex(i))
         if(g_pos.Symbol() == _Symbol && g_pos.Magic() == EA_MAGIC)
            if(!onlyProfit || g_pos.Profit() > 0)
               g_trade.PositionClose(g_pos.Ticket());
}

//+=================================================================+
//|  EVENTOS DEL GRAFICO (BOTONES)                                   |
//+=================================================================+
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == EA_PREFIX + "BTN_CLOSEALL")         ClosePositions(false);
      else if(sparam == EA_PREFIX + "BTN_CLOSEPROFIT") ClosePositions(true);
      else if(sparam == EA_PREFIX + "BTN_PAUSE")
      {
         g_paused = !g_paused;
         UpdatePanel();
      }
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      ChartRedraw(0);
   }
}

//+=================================================================+
//|  PANEL VISUAL — CREACION                                         |
//+=================================================================+
void CreatePanel()
{
   MakeRect(EA_PREFIX+"PNL_BG",     PANEL_X, PANEL_Y, PANEL_W, PANEL_H, C'12,16,28', C'40,60,130', 2);
   MakeRect(EA_PREFIX+"PNL_HEADER", PANEL_X, PANEL_Y, PANEL_W, 26,      C'20,30,70', C'40,60,130', 0);
   MakeLabel(EA_PREFIX+"PNL_ICON",  PANEL_X+10, PANEL_Y+5, "◈",       C'80,160,255', 11, true);
   MakeLabel(EA_PREFIX+"PNL_TITLE", PANEL_X+28, PANEL_Y+6, "CTR PRO",  clrWhite,     10, true);
   MakeLabel(EA_PREFIX+"PNL_VER",   PANEL_X+PANEL_W-55, PANEL_Y+8, "v2.10", C'80,100,160', 7, false);

   MakeRect(EA_PREFIX+"DIV1", PANEL_X+8, PANEL_Y+28, PANEL_W-16, 1, C'40,60,130', C'40,60,130', 0);

   int y = PANEL_Y + 34;
   MakeLabel(EA_PREFIX+"LBL_STATUS", PANEL_X+12, y, "Estado:",     C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_STATUS", PANEL_X+100, y, "● ACTIVO",   clrLime,        8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_SPREAD", PANEL_X+12, y, "Spread:",     C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_SPREAD", PANEL_X+100, y, "-- pts",     clrYellow,      8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_PROFIT", PANEL_X+12, y, "P/L Diario:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_PROFIT", PANEL_X+100, y, "$0.00",      clrWhite,       8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_TRADES", PANEL_X+12, y, "Trades hoy:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_TRADES", PANEL_X+100, y,
             "0 / "+IntegerToString(InpMaxPerDay), clrWhite, 8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_DIR",  PANEL_X+12, y, "Dirección:",  C'120,140,200', 8, false);
   string dirTxt = (InpDirection==DIRECTION_BUY) ? "▲ COMPRA" :
                   (InpDirection==DIRECTION_SELL)? "▼ VENTA"  : "◆ AMBOS";
   color  dirClr = (InpDirection==DIRECTION_BUY) ? clrLime :
                   (InpDirection==DIRECTION_SELL)? clrOrangeRed : clrCyan;
   MakeLabel(EA_PREFIX+"VAL_DIR",  PANEL_X+100, y, dirTxt, dirClr, 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_RISK",   PANEL_X+12, y, "Riesgo:",    C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_RISK",   PANEL_X+100, y,
             "$"+DoubleToString(InpRiskUSD,2), C'255,160,60', 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_SLMODE", PANEL_X+12, y, "Modo SL:",   C'120,140,200', 8, false);
   string slTxt = InpDynamicSL ?
                  "DIN RR:"+DoubleToString(InpRR,1) :
                  "MAN "+DoubleToString(InpSL_Pips,0)+"/"+DoubleToString(InpTP_Pips,0);
   color slClr  = InpDynamicSL ? C'80,220,180' : C'180,180,80';
   MakeLabel(EA_PREFIX+"VAL_SLMODE", PANEL_X+100, y, slTxt, slClr, 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_SES",  PANEL_X+12, y, "Sesión UTC:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_SES",  PANEL_X+100, y,
             StringFormat("%02d:%02d→%02d:%02d", InpUTCStartHour, InpUTCStartMin,
                          InpUTCEndHour, InpUTCEndMin), C'160,200,255', 8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_WICK",  PANEL_X+12, y, "Mecha:",      C'120,140,200', 8, false);
   string wickTxt = InpWickFilter ? "ON ratio:"+DoubleToString(InpWickRatio,1) : "OFF";
   color  wickClr = InpWickFilter ? C'80,220,180' : C'100,100,140';
   MakeLabel(EA_PREFIX+"VAL_WICK",  PANEL_X+100, y, wickTxt, wickClr, 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_SWEEP", PANEL_X+12, y, "Sweep mín:", C'120,140,200', 8, false);
   string swpTxt = InpSweepFilter ? "ON "+IntegerToString(InpMinSweepTicks)+"tks" : "OFF";
   color  swpClr = InpSweepFilter ? C'80,220,180' : C'100,100,140';
   MakeLabel(EA_PREFIX+"VAL_SWEEP", PANEL_X+100, y, swpTxt, swpClr, 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_BE",    PANEL_X+12, y, "Break Even:", C'120,140,200', 8, false);
   string beTxt = InpBEEnable ?
                  DoubleToString(InpBETriggerPct,0)+"% +"+IntegerToString(InpBEBuffer)+"tks" : "OFF";
   color  beClr = InpBEEnable ? C'80,200,255' : C'100,100,140';
   MakeLabel(EA_PREFIX+"VAL_BE",    PANEL_X+100, y, beTxt, beClr, 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_TIMER", PANEL_X+12, y, "Timer:",      C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_TIMER", PANEL_X+100, y,
             InpTimerEnable ? IntegerToString(InpMaxMinutes)+"min" : "OFF",
             InpTimerEnable ? C'255,160,60' : C'100,100,140', 8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_TOPEN", PANEL_X+12, y, "En operac.:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_TOPEN", PANEL_X+100, y, "--min",       clrWhite,       8, false);

   MakeRect(EA_PREFIX+"DIV2", PANEL_X+8, y+14, PANEL_W-16, 1, C'40,60,130', C'40,60,130', 0);

   y += 20;
   MakeLabel(EA_PREFIX+"LBL_LEVELS", PANEL_X+12, y, "Niveles:",   C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"IND_TP",     PANEL_X+80,  y, "● TP",      clrLime,        8, true);
   MakeLabel(EA_PREFIX+"IND_SL",     PANEL_X+118, y, "● SL",      clrRed,         8, true);
   MakeLabel(EA_PREFIX+"IND_IN",     PANEL_X+158, y, "● IN",      C'100,160,255', 8, true);

   MakeRect(EA_PREFIX+"DIV3", PANEL_X+8, y+14, PANEL_W-16, 1, C'40,60,130', C'40,60,130', 0);

   y += 20;
   MakeButton(EA_PREFIX+"BTN_CLOSEALL",    PANEL_X+8,   y, 68, 18, "Cerrar Todo", C'160,40,40', clrWhite);
   MakeButton(EA_PREFIX+"BTN_CLOSEPROFIT", PANEL_X+82,  y, 72, 18, "Cerrar +$",   C'30,120,70', clrWhite);
   MakeButton(EA_PREFIX+"BTN_PAUSE",       PANEL_X+161, y, 62, 18, "Pausar",      C'60,60,150', clrWhite);

   ChartRedraw(0);
}

//+=================================================================+
//|  PANEL VISUAL — ACTUALIZAR                                       |
//+=================================================================+
void UpdatePanel()
{
   bool inSes  = IsInSession() && IsTradingDay();
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   bool sprdOK = (spread <= InpMaxSpread);

   string stTxt; color stClr;
   if(g_paused)                         { stTxt="⏸ PAUSADO";    stClr=clrOrange; }
   else if(!inSes)                      { stTxt="◌ INACTIVO";   stClr=C'100,100,140'; }
   else if(!sprdOK)                     { stTxt="⚠ SPREAD!";    stClr=clrOrange; }
   else if(g_tradesToday>=InpMaxPerDay) { stTxt="✔ LÍMITE DÍA"; stClr=clrYellow; }
   else                                 { stTxt="● ACTIVO";     stClr=clrLime; }
   ObjectSetString (0, EA_PREFIX+"VAL_STATUS", OBJPROP_TEXT,  stTxt);
   ObjectSetInteger(0, EA_PREFIX+"VAL_STATUS", OBJPROP_COLOR, stClr);

   ObjectSetString (0, EA_PREFIX+"VAL_SPREAD", OBJPROP_TEXT,
                    IntegerToString((int)spread)+" pts");
   ObjectSetInteger(0, EA_PREFIX+"VAL_SPREAD", OBJPROP_COLOR, sprdOK?clrYellow:clrRed);

   color profClr = (g_dailyProfit >= 0) ? clrLime : clrRed;
   ObjectSetString (0, EA_PREFIX+"VAL_PROFIT", OBJPROP_TEXT,
                    (g_dailyProfit>=0?"+$":"-$")+DoubleToString(MathAbs(g_dailyProfit),2));
   ObjectSetInteger(0, EA_PREFIX+"VAL_PROFIT", OBJPROP_COLOR, profClr);

   ObjectSetString (0, EA_PREFIX+"VAL_TRADES", OBJPROP_TEXT,
                    IntegerToString(g_tradesToday)+" / "+IntegerToString(InpMaxPerDay));
   ObjectSetInteger(0, EA_PREFIX+"VAL_TRADES", OBJPROP_COLOR,
                    g_tradesToday>=InpMaxPerDay ? clrOrange : clrWhite);

   //--- Tiempo en operación abierta
   string timerTxt = "--min";
   color  timerClr = clrWhite;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(g_pos.SelectByIndex(i))
         if(g_pos.Symbol()==_Symbol && g_pos.Magic()==EA_MAGIC)
         {
            int elapsed = (int)((TimeCurrent() - g_pos.Time()) / 60);
            timerTxt = IntegerToString(elapsed)+"min";
            timerClr = (elapsed >= InpMaxMinutes*8/10) ? clrOrange : clrLime;
            break;
         }
   }
   ObjectSetString (0, EA_PREFIX+"VAL_TOPEN", OBJPROP_TEXT,  timerTxt);
   ObjectSetInteger(0, EA_PREFIX+"VAL_TOPEN", OBJPROP_COLOR, timerClr);

   ObjectSetString(0, EA_PREFIX+"BTN_PAUSE", OBJPROP_TEXT,
                   g_paused ? "▶ Reanudar" : "⏸ Pausar");
   ChartRedraw(0);
}

//+=================================================================+
//|  DIBUJAR SEÑAL                                                   |
//+=================================================================+
void DrawSignal(bool isBuy, double entry, double sl, double tp,
                datetime signalTime, double sweepExtreme, double prevLevel)
{
   g_signalCount++;
   string pfx = EA_PREFIX+"S"+IntegerToString(g_signalCount)+"_";
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 0);

   ObjArrow(pfx+"ARROW", signalTime, isBuy?sl*0.9998:sl*1.0002,
            isBuy?241:242, isBuy?clrLime:clrOrangeRed, 3);
   ObjText(pfx+"LABEL",  signalTime, isBuy?sl*0.9996:sl*1.0004, "CTR ENTRY", clrMagenta, 8);
   ObjHLine(pfx+"ENTRY_LINE", entry, C'100,160,255', STYLE_DASHDOT, 1);
   ObjHLine(pfx+"TP_LINE",    tp,    clrLime,        STYLE_SOLID,   1);
   ObjText (pfx+"TP_LABEL",   t1, tp, "TP:"+DoubleToString(tp,_Digits), clrLime, 8);
   ObjHLine(pfx+"SL_LINE",    sl,    clrRed,         STYLE_SOLID,   1);
   ObjText (pfx+"SL_LABEL",   t1, sl, "SL:"+DoubleToString(sl,_Digits), clrRed,  8);
   ObjTrendLine(pfx+"SWEEP_LINE", iTime(_Symbol,PERIOD_CURRENT,2), prevLevel,
                signalTime, prevLevel, C'220,80,120', STYLE_DOT, 1);
   ObjTrendLine(pfx+"DIAG_TP", signalTime, entry, t1, tp, C'255,160,40', STYLE_DOT, 1);
   ObjTrendLine(pfx+"DIAG_SL", signalTime, entry, t1, sl, C'255,80,80',  STYLE_DOT, 1);

   ChartRedraw(0);
   CleanOldSignals();
}

//+=================================================================+
//|  LIMPIAR SEÑALES ANTIGUAS                                        |
//+=================================================================+
void CleanOldSignals()
{
   int oldest = g_signalCount - InpMaxDrawings;
   if(oldest <= 0) return;
   string pfx    = EA_PREFIX+"S"+IntegerToString(oldest)+"_";
   string parts[] = {"ARROW","LABEL","ENTRY_LINE","TP_LINE","TP_LABEL",
                      "SL_LINE","SL_LABEL","SWEEP_LINE","DIAG_TP","DIAG_SL"};
   for(int i = 0; i < ArraySize(parts); i++)
      ObjectDelete(0, pfx+parts[i]);
}

//+=================================================================+
//|  HELPERS DE OBJETOS                                              |
//+=================================================================+
void MakeRect(string name,int x,int y,int w,int h,color bg,color border,int bw)
{
   ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);     ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);  ObjectSetInteger(0,name,OBJPROP_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,bw);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
}
void MakeLabel(string name,int x,int y,string txt,color clr,int fs,bool bold)
{
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,name,OBJPROP_TEXT,txt);     ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fs);
   ObjectSetString (0,name,OBJPROP_FONT,bold?"Arial Bold":"Arial");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,1);
}
void MakeButton(string name,int x,int y,int w,int h,string txt,color bg,color clr)
{
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);  ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);       ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetString (0,name,OBJPROP_TEXT,txt);      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);    ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,C'80,80,120');
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,7);
   ObjectSetString (0,name,OBJPROP_FONT,"Arial Bold");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,2);
}
void ObjHLine(string name,double price,color clr,ENUM_LINE_STYLE style,int width)
{
   ObjectCreate(0,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);  ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
}
void ObjArrow(string name,datetime t,double price,int code,color clr,int width)
{
   ObjectCreate(0,name,OBJ_ARROW,0,t,price);
   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,code); ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);    ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
}
void ObjText(string name,datetime t,double price,string txt,color clr,int fs)
{
   ObjectCreate(0,name,OBJ_TEXT,0,t,price);
   ObjectSetString (0,name,OBJPROP_TEXT,txt);     ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fs);  ObjectSetString(0,name,OBJPROP_FONT,"Arial Bold");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
}
void ObjTrendLine(string name,datetime t1,double p1,datetime t2,double p2,
                  color clr,ENUM_LINE_STYLE style,int width)
{
   ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);     ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
}
//+------------------------------------------------------------------+
//|  FIN DEL EA                                                       |
//+------------------------------------------------------------------+
