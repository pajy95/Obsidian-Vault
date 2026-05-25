//+------------------------------------------------------------------+
//|                                              CTR_Pro_EA_v1.mq5   |
//|                    CTR PRO - Liquidity Sweep Reversal System      |
//|                         Version 1.10  |  MQL5 / MetaTrader 5     |
//+------------------------------------------------------------------+
// Cambios v1.10 vs v1.00:
//   1. Filtro ATR activable/desactivable (InpATRFilter, InpATRPeriod,
//      InpATRMinMult, InpATRMaxMult)
//   2. Sesión en hora UTC pura (TimeGMT) — sin offset de servidor
//   3. Parámetros renombrados: InpUTCStartHour / InpUTCStartMin
//+------------------------------------------------------------------+
#property copyright   "CTR Pro EA"
#property link        ""
#property version     "1.10"
#property description "CTR PRO v1.10 - Sesión UTC + Filtro ATR"

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
input ENUM_TRADE_DIRECTION InpDirection   = DIRECTION_BUY;  // Dirección de Operaciones
input int                  InpMaxDrawings = 10;              // Mantener últimos N dibujos
input double               InpRiskUSD     = 50.0;           // Riesgo por Operación (USD)
input int                  InpMaxPerDay   = 1;               // Máx. Operaciones por Día
input int                  InpMaxSpread   = 100;             // Máx. Spread (puntos)
input int                  InpSlippage    = 10;              // Slippage (puntos)

input group "══════════ STOP LOSS / TAKE PROFIT ══════════"
input double               InpSL_Pips     = 840.0;          // Stop Loss (ticks)
input double               InpTP_Pips     = 1800.0;         // Take Profit (ticks)

input group "══════════ FILTRO ATR ══════════"
input bool                 InpATRFilter   = true;            // Activar Filtro ATR
input int                  InpATRPeriod   = 14;              // Período ATR
input double               InpATRMinMult  = 0.5;            // Mínimo ATR (multiplicador)
input double               InpATRMaxMult  = 3.0;            // Máximo ATR (multiplicador)

input group "══════════ DIAS DE OPERACION ══════════"
input bool                 InpMonday      = true;            // Operar Lunes
input bool                 InpTuesday     = true;            // Operar Martes
input bool                 InpWednesday   = true;            // Operar Miércoles
input bool                 InpThursday    = false;           // Operar Jueves
input bool                 InpFriday      = false;           // Operar Viernes

input group "══════════ HORARIO DE SESION (UTC) ══════════"
input int                  InpUTCStartHour = 13;             // Hora Inicio UTC
input int                  InpUTCStartMin  = 10;             // Minuto Inicio UTC
input int                  InpUTCEndHour   = 16;             // Hora Fin UTC
input int                  InpUTCEndMin    = 10;             // Minuto Fin UTC

//+=================================================================+
//|  CONSTANTES INTERNAS                                             |
//+=================================================================+
#define EA_MAGIC        202501
#define EA_PREFIX       "CTR_"
#define PANEL_X         15
#define PANEL_Y         35
#define PANEL_W         230
#define PANEL_H         240

//+=================================================================+
//|  VARIABLES GLOBALES                                              |
//+=================================================================+
CTrade        g_trade;
CPositionInfo g_pos;

int      g_tradesToday  = 0;
double   g_dailyProfit  = 0.0;
datetime g_lastBarTime  = 0;
datetime g_todayDate    = 0;
bool     g_paused       = false;
int      g_signalCount  = 0;

double   g_pipSize      = 0.0;
int      g_atrHandle    = INVALID_HANDLE;

//+=================================================================+
//|  INICIALIZACION                                                  |
//+=================================================================+
int OnInit()
{
   if(_Digits == 5 || _Digits == 3)
      g_pipSize = _Point * 10.0;
   else
      g_pipSize = _Point;

   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetExpertMagicNumber(EA_MAGIC);
   g_trade.SetAsyncMode(false);

   //--- Inicializar handle ATR
   if(InpATRFilter)
   {
      g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
      if(g_atrHandle == INVALID_HANDLE)
      {
         Print("ERROR: No se pudo crear el indicador ATR");
         return INIT_FAILED;
      }
   }

   CreatePanel();

   Print("CTR Pro EA v1.10 iniciado | Símbolo: ", _Symbol,
         " | TF: ", EnumToString(_Period),
         " | Sesión UTC: ", InpUTCStartHour, ":", InpUTCStartMin,
         " → ", InpUTCEndHour, ":", InpUTCEndMin,
         " | ATR Filter: ", InpATRFilter ? "ON" : "OFF");

   return INIT_SUCCEEDED;
}

//+=================================================================+
//|  DESINICIALIZACION                                               |
//+=================================================================+
void OnDeinit(const int reason)
{
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
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

   if(g_paused) return;
   if(!IsTradingDay()) return;
   if(!IsInSession()) return;
   if(g_tradesToday >= InpMaxPerDay) return;

   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(currentSpread > InpMaxSpread) return;

   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime == g_lastBarTime) return;
   g_lastBarTime = barTime;

   //--- Filtro ATR
   if(InpATRFilter && !PassesATRFilter()) return;

   DetectLiquiditySweep();
}

//+=================================================================+
//|  FILTRO ATR                                                      |
//+=================================================================+
bool PassesATRFilter()
{
   double atrBuf[1];
   if(CopyBuffer(g_atrHandle, 0, 1, 1, atrBuf) < 1)
   {
      Print("WARN: CopyBuffer ATR falló");
      return true; // No bloquear por error de datos
   }

   double atr     = atrBuf[0];
   double atrMin  = InpATRMinMult * atr;
   double atrMax  = InpATRMaxMult * atr;

   //--- Rango de la vela de barrido (vela[1])
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1  = iLow (_Symbol, PERIOD_CURRENT, 1);
   double range = high1 - low1;

   if(range < atrMin)
   {
      // Volatilidad insuficiente — sweep probablemente ruido
      return false;
   }
   if(range > atrMax)
   {
      // Volatilidad extrema — posible noticia, evitar
      return false;
   }

   return true;
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

   double slDist = InpSL_Pips * _Point;
   double tpDist = InpTP_Pips * _Point;

   //--- SEÑAL DE COMPRA
   if(InpDirection == DIRECTION_BOTH || InpDirection == DIRECTION_BUY)
   {
      bool sweepLow = (low1 < low2) && (close1 > low2);
      if(sweepLow)
      {
         double entryBuy = ask;
         double slBuy    = entryBuy - slDist;
         double tpBuy    = entryBuy + tpDist;
         double lots     = CalcLots(slDist);

         if(lots > 0.0)
         {
            if(g_trade.Buy(lots, _Symbol, entryBuy, slBuy, tpBuy, "CTR BUY"))
            {
               g_tradesToday++;
               DrawSignal(true, entryBuy, slBuy, tpBuy,
                          iTime(_Symbol, PERIOD_CURRENT, 1), low1, low2);
               PrintFormat("CTR BUY | Entry: %.5f | SL: %.5f | TP: %.5f | Lots: %.2f",
                           entryBuy, slBuy, tpBuy, lots);
            }
         }
      }
   }

   //--- SEÑAL DE VENTA
   if(InpDirection == DIRECTION_BOTH || InpDirection == DIRECTION_SELL)
   {
      bool sweepHigh = (high1 > high2) && (close1 < high2);
      if(sweepHigh)
      {
         double entrySell = bid;
         double slSell    = entrySell + slDist;
         double tpSell    = entrySell - tpDist;
         double lots      = CalcLots(slDist);

         if(lots > 0.0)
         {
            if(g_trade.Sell(lots, _Symbol, entrySell, slSell, tpSell, "CTR SELL"))
            {
               g_tradesToday++;
               DrawSignal(false, entrySell, slSell, tpSell,
                          iTime(_Symbol, PERIOD_CURRENT, 1), high1, high2);
               PrintFormat("CTR SELL | Entry: %.5f | SL: %.5f | TP: %.5f | Lots: %.2f",
                           entrySell, slSell, tpSell, lots);
            }
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
   lots = MathMax(minLot, MathMin(maxLot, lots));

   return lots;
}

//+=================================================================+
//|  VERIFICAR NUEVO DIA (usando hora UTC)                           |
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
   {
      if(g_pos.SelectByIndex(i))
         if(g_pos.Symbol() == _Symbol && g_pos.Magic() == EA_MAGIC)
            g_dailyProfit += g_pos.Profit() + g_pos.Swap() + g_pos.Commission();
   }
}

//+=================================================================+
//|  FILTRO DE DIA DE SEMANA (usando hora UTC)                       |
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
//|  FILTRO DE SESION HORARIA (hora UTC pura)                        |
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
   {
      if(g_pos.SelectByIndex(i))
         if(g_pos.Symbol() == _Symbol && g_pos.Magic() == EA_MAGIC)
            if(!onlyProfit || g_pos.Profit() > 0)
               g_trade.PositionClose(g_pos.Ticket());
   }
}

//+=================================================================+
//|  EVENTOS DEL GRAFICO (BOTONES)                                   |
//+=================================================================+
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == EA_PREFIX + "BTN_CLOSEALL")
         ClosePositions(false);
      else if(sparam == EA_PREFIX + "BTN_CLOSEPROFIT")
         ClosePositions(true);
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
//|  PANEL VISUAL - CREACION                                         |
//+=================================================================+
void CreatePanel()
{
   MakeRect(EA_PREFIX + "PNL_BG",
            PANEL_X, PANEL_Y, PANEL_W, PANEL_H,
            C'12,16,28', C'40,60,130', 2);

   MakeRect(EA_PREFIX + "PNL_HEADER",
            PANEL_X, PANEL_Y, PANEL_W, 26,
            C'20,30,70', C'40,60,130', 0);

   MakeLabel(EA_PREFIX + "PNL_ICON",
             PANEL_X + 10, PANEL_Y + 5,
             "◈", C'80,160,255', 11, true);
   MakeLabel(EA_PREFIX + "PNL_TITLE",
             PANEL_X + 28, PANEL_Y + 6,
             "CTR PRO", clrWhite, 10, true);
   MakeLabel(EA_PREFIX + "PNL_VER",
             PANEL_X + PANEL_W - 55, PANEL_Y + 8,
             "v1.10", C'80,100,160', 7, false);

   MakeRect(EA_PREFIX + "DIV1",
            PANEL_X + 8, PANEL_Y + 28, PANEL_W - 16, 1,
            C'40,60,130', C'40,60,130', 0);

   MakeLabel(EA_PREFIX + "LBL_STATUS", PANEL_X + 12, PANEL_Y + 34,
             "Estado:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX + "VAL_STATUS", PANEL_X + 90, PANEL_Y + 34,
             "ACTIVO", clrLime, 8, true);

   MakeLabel(EA_PREFIX + "LBL_SPREAD", PANEL_X + 12, PANEL_Y + 50,
             "Spread:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX + "VAL_SPREAD", PANEL_X + 90, PANEL_Y + 50,
             "-- pts", clrYellow, 8, false);

   MakeLabel(EA_PREFIX + "LBL_PROFIT", PANEL_X + 12, PANEL_Y + 66,
             "P/L Diario:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX + "VAL_PROFIT", PANEL_X + 90, PANEL_Y + 66,
             "$0.00", clrWhite, 8, true);

   MakeLabel(EA_PREFIX + "LBL_TRADES", PANEL_X + 12, PANEL_Y + 82,
             "Trades hoy:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX + "VAL_TRADES", PANEL_X + 90, PANEL_Y + 82,
             "0 / " + IntegerToString(InpMaxPerDay), clrWhite, 8, false);

   MakeLabel(EA_PREFIX + "LBL_DIR", PANEL_X + 12, PANEL_Y + 98,
             "Dirección:", C'120,140,200', 8, false);
   string dirTxt = (InpDirection == DIRECTION_BUY)  ? "▲ COMPRA" :
                   (InpDirection == DIRECTION_SELL) ? "▼ VENTA"  : "◆ AMBOS";
   color  dirClr = (InpDirection == DIRECTION_BUY)  ? clrLime    :
                   (InpDirection == DIRECTION_SELL) ? clrOrangeRed : clrCyan;
   MakeLabel(EA_PREFIX + "VAL_DIR", PANEL_X + 90, PANEL_Y + 98,
             dirTxt, dirClr, 8, true);

   MakeLabel(EA_PREFIX + "LBL_RISK", PANEL_X + 12, PANEL_Y + 114,
             "Riesgo:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX + "VAL_RISK", PANEL_X + 90, PANEL_Y + 114,
             "$" + DoubleToString(InpRiskUSD, 2), C'255,160,60', 8, true);

   MakeLabel(EA_PREFIX + "LBL_SES", PANEL_X + 12, PANEL_Y + 130,
             "Sesión UTC:", C'120,140,200', 8, false);
   string sesTxt = StringFormat("%02d:%02d → %02d:%02d UTC",
                                InpUTCStartHour, InpUTCStartMin,
                                InpUTCEndHour,   InpUTCEndMin);
   MakeLabel(EA_PREFIX + "VAL_SES", PANEL_X + 90, PANEL_Y + 130,
             sesTxt, C'160,200,255', 8, false);

   //--- Fila ATR
   MakeLabel(EA_PREFIX + "LBL_ATR", PANEL_X + 12, PANEL_Y + 146,
             "ATR Filter:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX + "VAL_ATR", PANEL_X + 90, PANEL_Y + 146,
             InpATRFilter ? "ON" : "OFF",
             InpATRFilter ? clrLime : C'100,100,140', 8, true);

   MakeRect(EA_PREFIX + "DIV2",
            PANEL_X + 8, PANEL_Y + 162, PANEL_W - 16, 1,
            C'40,60,130', C'40,60,130', 0);

   MakeLabel(EA_PREFIX + "LBL_LEVELS", PANEL_X + 12, PANEL_Y + 168,
             "Niveles:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX + "IND_TP", PANEL_X + 80,  PANEL_Y + 168,
             "● TP", clrLime, 8, true);
   MakeLabel(EA_PREFIX + "IND_SL", PANEL_X + 118, PANEL_Y + 168,
             "● SL", clrRed, 8, true);
   MakeLabel(EA_PREFIX + "IND_IN", PANEL_X + 158, PANEL_Y + 168,
             "● IN", C'100,160,255', 8, true);

   MakeRect(EA_PREFIX + "DIV3",
            PANEL_X + 8, PANEL_Y + 184, PANEL_W - 16, 1,
            C'40,60,130', C'40,60,130', 0);

   MakeButton(EA_PREFIX + "BTN_CLOSEALL",
              PANEL_X + 8,  PANEL_Y + 191, 68, 18,
              "Cerrar Todo", C'160,40,40', clrWhite);
   MakeButton(EA_PREFIX + "BTN_CLOSEPROFIT",
              PANEL_X + 82, PANEL_Y + 191, 72, 18,
              "Cerrar +$", C'30,120,70', clrWhite);
   MakeButton(EA_PREFIX + "BTN_PAUSE",
              PANEL_X + 161, PANEL_Y + 191, 62, 18,
              "Pausar", C'60,60,150', clrWhite);

   ChartRedraw(0);
}

//+=================================================================+
//|  PANEL VISUAL - ACTUALIZAR VALORES                               |
//+=================================================================+
void UpdatePanel()
{
   bool   inSes  = IsInSession() && IsTradingDay();
   long   spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   bool   sprdOK = (spread <= InpMaxSpread);

   string stTxt; color stClr;
   if(g_paused)                          { stTxt = "⏸ PAUSADO";   stClr = clrOrange; }
   else if(!inSes)                       { stTxt = "◌ INACTIVO";  stClr = C'100,100,140'; }
   else if(!sprdOK)                      { stTxt = "⚠ SPREAD!";   stClr = clrOrange; }
   else if(g_tradesToday >= InpMaxPerDay){ stTxt = "✔ LÍMITE DÍA";stClr = clrYellow; }
   else                                  { stTxt = "● ACTIVO";    stClr = clrLime; }

   ObjectSetString (0, EA_PREFIX + "VAL_STATUS", OBJPROP_TEXT,  stTxt);
   ObjectSetInteger(0, EA_PREFIX + "VAL_STATUS", OBJPROP_COLOR, stClr);

   color sprClr = sprdOK ? clrYellow : clrRed;
   ObjectSetString (0, EA_PREFIX + "VAL_SPREAD", OBJPROP_TEXT,
                    IntegerToString((int)spread) + " pts");
   ObjectSetInteger(0, EA_PREFIX + "VAL_SPREAD", OBJPROP_COLOR, sprClr);

   color profClr = (g_dailyProfit >= 0) ? clrLime : clrRed;
   string profTxt = (g_dailyProfit >= 0 ? "+$" : "-$") +
                    DoubleToString(MathAbs(g_dailyProfit), 2);
   ObjectSetString (0, EA_PREFIX + "VAL_PROFIT", OBJPROP_TEXT,  profTxt);
   ObjectSetInteger(0, EA_PREFIX + "VAL_PROFIT", OBJPROP_COLOR, profClr);

   color tradesClr = (g_tradesToday >= InpMaxPerDay) ? clrOrange : clrWhite;
   ObjectSetString (0, EA_PREFIX + "VAL_TRADES", OBJPROP_TEXT,
                    IntegerToString(g_tradesToday) + " / " + IntegerToString(InpMaxPerDay));
   ObjectSetInteger(0, EA_PREFIX + "VAL_TRADES", OBJPROP_COLOR, tradesClr);

   ObjectSetString(0, EA_PREFIX + "BTN_PAUSE", OBJPROP_TEXT,
                   g_paused ? "▶ Reanudar" : "⏸ Pausar");

   ChartRedraw(0);
}

//+=================================================================+
//|  DIBUJAR SEÑAL EN EL GRAFICO                                     |
//+=================================================================+
void DrawSignal(bool isBuy,
                double entry, double sl, double tp,
                datetime signalTime,
                double sweepExtreme, double prevLevel)
{
   g_signalCount++;
   string id  = IntegerToString(g_signalCount);
   string pfx = EA_PREFIX + "S" + id + "_";

   color arrowClr = isBuy ? clrLime       : clrOrangeRed;
   color tpClr    = clrLime;
   color slClr    = clrRed;
   color entryClr = C'100,160,255';
   color labelClr = clrMagenta;

   datetime t0 = signalTime;
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 0);

   int arrowCode = isBuy ? 241 : 242;
   ObjArrow(pfx + "ARROW", t0, isBuy ? sl * 0.9998 : sl * 1.0002, arrowCode, arrowClr, 3);

   ObjText(pfx + "LABEL", t0,
           isBuy ? sl * 0.9996 : sl * 1.0004,
           "CTR ENTRY", labelClr, 8);

   ObjHLine(pfx + "ENTRY_LINE", entry, entryClr, STYLE_DASHDOT, 1);
   ObjHLine(pfx + "TP_LINE",    tp,    tpClr,    STYLE_SOLID,   1);
   ObjText (pfx + "TP_LABEL",   t1, tp,
            "TP: " + DoubleToString(tp, _Digits), tpClr, 8);
   ObjHLine(pfx + "SL_LINE",    sl,    slClr,    STYLE_SOLID,   1);
   ObjText (pfx + "SL_LABEL",   t1, sl,
            "SL: " + DoubleToString(sl, _Digits), slClr, 8);

   datetime tPrev = iTime(_Symbol, PERIOD_CURRENT, 2);
   ObjTrendLine(pfx + "SWEEP_LINE", tPrev, prevLevel, t0, prevLevel,
                C'220,80,120', STYLE_DOT, 1);
   ObjTrendLine(pfx + "DIAG_TP", t0, entry, t1, tp,
                C'255,160,40', STYLE_DOT, 1);
   ObjTrendLine(pfx + "DIAG_SL", t0, entry, t1, sl,
                C'255,80,80',  STYLE_DOT, 1);

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

   string pfx   = EA_PREFIX + "S" + IntegerToString(oldest) + "_";
   string parts[] = {"ARROW","LABEL","ENTRY_LINE","TP_LINE","TP_LABEL",
                      "SL_LINE","SL_LABEL","SWEEP_LINE","DIAG_TP","DIAG_SL"};
   for(int i = 0; i < ArraySize(parts); i++)
      ObjectDelete(0, pfx + parts[i]);
}

//+=================================================================+
//|  HELPERS DE CREACION DE OBJETOS                                  |
//+=================================================================+
void MakeRect(string name, int x, int y, int w, int h,
              color bg, color border, int bw)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,       h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR,       border);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,       bw);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, name, OBJPROP_BACK,        false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,      0);
}

void MakeLabel(string name, int x, int y, string txt,
               color clr, int fontSize, bool bold)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
   ObjectSetString (0, name, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   fontSize);
   ObjectSetString (0, name, OBJPROP_FONT,       bold ? "Arial Bold" : "Arial");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,     1);
}

void MakeButton(string name, int x, int y, int w, int h,
                string txt, color bg, color clr)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,        w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,        h);
   ObjectSetString (0, name, OBJPROP_TEXT,         txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR,        clr);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,      bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'80,80,120');
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,     7);
   ObjectSetString (0, name, OBJPROP_FONT,         "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, name, OBJPROP_BACK,         false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,       2);
}

void ObjHLine(string name, double price, color clr,
              ENUM_LINE_STYLE style, int width)
{
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
}

void ObjArrow(string name, datetime t, double price,
              int code, color clr, int width)
{
   ObjectCreate(0, name, OBJ_ARROW, 0, t, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  code);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

void ObjText(string name, datetime t, double price,
             string txt, color clr, int fontSize)
{
   ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetString (0, name, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   fontSize);
   ObjectSetString (0, name, OBJPROP_FONT,       "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

void ObjTrendLine(string name,
                  datetime t1, double p1,
                  datetime t2, double p2,
                  color clr, ENUM_LINE_STYLE style, int width)
{
   ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
}

//+------------------------------------------------------------------+
//|  FIN DEL EA                                                       |
//+------------------------------------------------------------------+
