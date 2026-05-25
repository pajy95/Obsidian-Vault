//+------------------------------------------------------------------+
//|                                            CTR_Pro_EA_v1.2.mq5   |
//|                    CTR PRO - Liquidity Sweep Reversal System      |
//|                        Version 1.30  |  MQL5 / MetaTrader 5      |
//+------------------------------------------------------------------+
// Cambios v1.30 vs v1.21:
//   6. SL dinámico anclado al extremo del sweep + buffer en ticks
//      — SL_BUY = low[1] - buffer | SL_SELL = high[1] + buffer
//      — el riesgo real refleja la profundidad del barrido institucional
//   7. TP calculado por RR sobre la distancia real entry→SL
//      — TP = entry + (slDist * InpRR) para BUY
//      — el lotaje usa la distancia real → riesgo USD constante
//   El modo manual (InpDynamicSL=false) preserva comportamiento anterior
//   con InpSL_Pips y InpTP_Pips fijos desde la entrada.
//+------------------------------------------------------------------+
#property copyright   "CTR Pro EA"
#property link        ""
#property version     "1.30"
#property description "CTR PRO v1.30 - SL dinámico anclado al sweep + RR"

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

enum ENUM_ST_TIMEFRAME
{
   ST_TF_CURRENT = 0,  // Mismo timeframe
   ST_TF_H1      = 1,  // H1
   ST_TF_H4      = 2,  // H4
   ST_TF_D1      = 3   // D1
};

//+=================================================================+
//|  PARAMETROS DE ENTRADA                                           |
//+=================================================================+
input group "══════════ CONFIGURACION GENERAL ══════════"
input ENUM_TRADE_DIRECTION InpDirection    = DIRECTION_BUY;  // Dirección de Operaciones
input int                  InpMaxDrawings  = 10;             // Mantener últimos N dibujos
input double               InpRiskUSD      = 50.0;          // Riesgo por Operación (USD)
input int                  InpMaxPerDay    = 1;              // Máx. Operaciones por Día
input int                  InpMaxSpread    = 100;            // Máx. Spread (puntos)
input int                  InpSlippage     = 10;             // Slippage (puntos)

input group "══════════ STOP LOSS / TAKE PROFIT ══════════"
input bool                 InpDynamicSL    = true;           // SL Dinámico (anclado al sweep)
input int                  InpSLBuffer     = 20;             // Buffer SL bajo/sobre sweep (ticks)
input double               InpRR           = 3.0;           // RR — Ratio Riesgo/Recompensa
input double               InpSL_Pips      = 650.0;         // [Manual] Stop Loss (ticks)
input double               InpTP_Pips      = 1950.0;        // [Manual] Take Profit (ticks)

input group "══════════ FILTRO ATR (VELA DE BARRIDO) ══════════"
input bool                 InpATRFilter    = false;          // Activar Filtro ATR vela sweep
input int                  InpATRPeriod    = 14;             // Período ATR
input double               InpATRMinMult   = 0.5;           // Mínimo rango sweep (x ATR)
input double               InpATRMaxMult   = 3.0;           // Máximo rango sweep (x ATR)

input group "══════════ FILTRO SUPERTREND (TENDENCIA) ══════════"
input bool                 InpSTFilter     = true;           // Activar Filtro Supertrend
input ENUM_ST_TIMEFRAME    InpSTTimeframe  = ST_TF_H1;      // Timeframe Supertrend
input int                  InpSTPeriod     = 10;             // Período ATR del Supertrend
input double               InpSTMultiplier = 3.0;           // Multiplicador Supertrend

input group "══════════ FILTRO RANGO VELA REFERENCIA ══════════"
input bool                 InpRefCandleFilter = true;        // Activar Filtro Rango Vela Ref
input double               InpRefCandleMinATR = 0.5;        // Rango mínimo vela[2] (x ATR)

input group "══════════ CONFIRMACION DE SWEEP ══════════"
input bool                 InpWickFilter   = true;           // Activar Filtro de Mecha
input double               InpWickRatio    = 1.5;           // Mecha >= Cuerpo * ratio
input int                  InpMinSweepTicks = 15;           // Penetración mínima (ticks)

input group "══════════ TEMPORIZADOR DE OPERACION ══════════"
input bool                 InpTimerEnable  = true;           // Activar Temporizador
input int                  InpMaxMinutes   = 120;            // Tiempo máx en operación (min)

input group "══════════ DIAS DE OPERACION ══════════"
input bool                 InpMonday       = true;           // Operar Lunes
input bool                 InpTuesday      = true;           // Operar Martes
input bool                 InpWednesday    = true;           // Operar Miércoles
input bool                 InpThursday     = true;           // Operar Jueves
input bool                 InpFriday       = true;           // Operar Viernes

input group "══════════ HORARIO DE SESION (UTC) ══════════"
input int                  InpUTCStartHour = 16;             // Hora Inicio UTC
input int                  InpUTCStartMin  = 40;             // Minuto Inicio UTC
input int                  InpUTCEndHour   = 18;             // Hora Fin UTC
input int                  InpUTCEndMin    = 0;              // Minuto Fin UTC

//+=================================================================+
//|  CONSTANTES INTERNAS                                             |
//+=================================================================+
#define EA_MAGIC        202502
#define EA_PREFIX       "CTR_"
#define PANEL_X         15
#define PANEL_Y         35
#define PANEL_W         235
#define PANEL_H         315

//+=================================================================+
//|  VARIABLES GLOBALES                                              |
//+=================================================================+
CTrade        g_trade;
CPositionInfo g_pos;

int      g_tradesToday   = 0;
double   g_dailyProfit   = 0.0;
datetime g_lastBarTime   = 0;
datetime g_todayDate     = 0;
bool     g_paused        = false;
int      g_signalCount   = 0;

double   g_pipSize       = 0.0;
int      g_atrHandle     = INVALID_HANDLE;
int      g_atrSTHandle   = INVALID_HANDLE; // ATR para Supertrend

// Supertrend — estado calculado en cada barra
double   g_stUpperBand   = 0.0;
double   g_stLowerBand   = 0.0;
bool     g_stBullish     = true; // true = tendencia alcista

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

   //--- ATR para filtro de vela sweep
   if(InpATRFilter || InpRefCandleFilter)
   {
      g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
      if(g_atrHandle == INVALID_HANDLE)
      {
         Print("ERROR: No se pudo crear ATR principal");
         return INIT_FAILED;
      }
   }

   //--- ATR para Supertrend (en TF superior)
   if(InpSTFilter)
   {
      ENUM_TIMEFRAMES stTF = GetSuperTrendTF();
      g_atrSTHandle = iATR(_Symbol, stTF, InpSTPeriod);
      if(g_atrSTHandle == INVALID_HANDLE)
      {
         Print("ERROR: No se pudo crear ATR Supertrend");
         return INIT_FAILED;
      }
   }

   CreatePanel();

   string slModeLog = InpDynamicSL ?
                      StringFormat("DIN buffer:%d tks RR:%.1f", InpSLBuffer, InpRR) :
                      StringFormat("MAN SL:%.0f TP:%.0f tks", InpSL_Pips, InpTP_Pips);
   Print("CTR Pro EA v1.30 | ", _Symbol, " ", EnumToString(_Period),
         " | UTC ", InpUTCStartHour, ":", InpUTCStartMin,
         " | SL:", slModeLog,
         " | ST:", InpSTFilter ? "ON" : "OFF",
         " | Timer:", InpTimerEnable ? IntegerToString(InpMaxMinutes) + "min" : "OFF");

   return INIT_SUCCEEDED;
}

//+=================================================================+
//|  DESINICIALIZACION                                               |
//+=================================================================+
void OnDeinit(const int reason)
{
   if(g_atrHandle   != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
   if(g_atrSTHandle != INVALID_HANDLE) IndicatorRelease(g_atrSTHandle);
   ObjectsDeleteAll(0, EA_PREFIX);
   Comment("");
}

//+=================================================================+
//|  TIMEFRAME DEL SUPERTREND                                        |
//+=================================================================+
ENUM_TIMEFRAMES GetSuperTrendTF()
{
   switch(InpSTTimeframe)
   {
      case ST_TF_H1: return PERIOD_H1;
      case ST_TF_H4: return PERIOD_H4;
      case ST_TF_D1: return PERIOD_D1;
      default:       return PERIOD_CURRENT;
   }
}

//+=================================================================+
//|  TICK PRINCIPAL                                                  |
//+=================================================================+
void OnTick()
{
   CheckNewDay();
   UpdatePanel();

   //--- Temporizador: cierre forzado de posición abierta
   if(InpTimerEnable) CheckTradeTimer();

   if(g_paused) return;
   if(!IsTradingDay()) return;
   if(!IsInSession()) return;
   if(g_tradesToday >= InpMaxPerDay) return;

   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(currentSpread > InpMaxSpread) return;

   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime == g_lastBarTime) return;
   g_lastBarTime = barTime;

   //--- Actualizar Supertrend en cada nueva barra
   if(InpSTFilter) UpdateSuperTrend();

   //--- Filtro ATR vela de sweep
   if(InpATRFilter && !PassesATRFilter()) return;

   DetectLiquiditySweep();
}

//+=================================================================+
//|  SUPERTREND — CALCULO                                            |
//+=================================================================+
// Supertrend clásico:
//   UpperBand = (High+Low)/2 + Multiplier * ATR
//   LowerBand = (High+Low)/2 - Multiplier * ATR
// Dirección: si Close > UpperBand(prev) → bullish; si Close < LowerBand(prev) → bearish
// No requiere indicador externo — calculado nativamente.
void UpdateSuperTrend()
{
   ENUM_TIMEFRAMES stTF = GetSuperTrendTF();
   int lookback = InpSTPeriod + 5;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(g_atrSTHandle, 0, 0, lookback, atrBuf) < lookback) return;

   double highArr[], lowArr[], closeArr[];
   ArraySetAsSeries(highArr,  true);
   ArraySetAsSeries(lowArr,   true);
   ArraySetAsSeries(closeArr, true);
   if(CopyHigh (_Symbol, stTF, 0, lookback, highArr)  < lookback) return;
   if(CopyLow  (_Symbol, stTF, 0, lookback, lowArr)   < lookback) return;
   if(CopyClose(_Symbol, stTF, 0, lookback, closeArr) < lookback) return;

   // Calcular bandas para barra[1] (última cerrada) usando ATR de barra[1]
   double hl2    = (highArr[1] + lowArr[1]) / 2.0;
   double atr1   = atrBuf[1];
   double upper  = hl2 + InpSTMultiplier * atr1;
   double lower  = hl2 - InpSTMultiplier * atr1;

   // Ajuste de bandas: no reducir el lower si ya era mayor, no ampliar el upper si ya era menor
   // Para simplificar el cálculo en una función sin estado persistente usamos barra[2] como referencia
   double hl2_2  = (highArr[2] + lowArr[2]) / 2.0;
   double atr2   = atrBuf[2];
   double upper2 = hl2_2 + InpSTMultiplier * atr2;
   double lower2 = hl2_2 - InpSTMultiplier * atr2;

   // Ajuste estándar de bandas
   if(lower > lower2 || closeArr[2] < lower2) lower = lower;
   else lower = lower2;

   if(upper < upper2 || closeArr[2] > upper2) upper = upper;
   else upper = upper2;

   g_stUpperBand = upper;
   g_stLowerBand = lower;

   // Dirección basada en cierre de barra[1] vs bandas ajustadas
   if(closeArr[1] > g_stUpperBand)      g_stBullish = true;
   else if(closeArr[1] < g_stLowerBand) g_stBullish = false;
   // Si está entre bandas: mantener dirección anterior
}

//+=================================================================+
//|  SUPERTREND — FILTRO                                             |
//+=================================================================+
bool PassesSuperTrendFilter(bool isBuy)
{
   if(!InpSTFilter) return true;
   // Buy solo si Supertrend es alcista; Sell solo si es bajista
   if(isBuy  && !g_stBullish) return false;
   if(!isBuy &&  g_stBullish) return false;
   return true;
}

//+=================================================================+
//|  FILTRO ATR — RANGO VELA DE SWEEP                                |
//+=================================================================+
bool PassesATRFilter()
{
   double atrBuf[1];
   if(CopyBuffer(g_atrHandle, 0, 1, 1, atrBuf) < 1) return true;

   double atr   = atrBuf[0];
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1  = iLow (_Symbol, PERIOD_CURRENT, 1);
   double range = high1 - low1;

   if(range < InpATRMinMult * atr) return false;
   if(range > InpATRMaxMult * atr) return false;
   return true;
}

//+=================================================================+
//|  FILTRO RANGO VELA DE REFERENCIA                                 |
//+=================================================================+
// La vela[2] es el nivel de referencia cuyo High/Low fue barrido.
// Si su rango es muy pequeño, no hay liquidez real acumulada — es ruido.
bool PassesRefCandleFilter()
{
   if(!InpRefCandleFilter) return true;

   double atrBuf[1];
   if(CopyBuffer(g_atrHandle, 0, 2, 1, atrBuf) < 1) return true;

   double atr   = atrBuf[0];
   double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
   double low2  = iLow (_Symbol, PERIOD_CURRENT, 2);
   double range2 = high2 - low2;

   return (range2 >= InpRefCandleMinATR * atr);
}

//+=================================================================+
//|  CONFIRMACION DE SWEEP POR MECHA                                 |
//+=================================================================+
// La mecha de rechazo debe ser significativamente mayor al cuerpo.
// BUY sweep: mecha inferior (low1 a open/close mín) >= cuerpo * ratio
// SELL sweep: mecha superior (high1 a open/close máx) >= cuerpo * ratio
bool PassesWickFilter(bool isBuy)
{
   if(!InpWickFilter) return true;

   double open1  = iOpen (_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double high1  = iHigh (_Symbol, PERIOD_CURRENT, 1);
   double low1   = iLow  (_Symbol, PERIOD_CURRENT, 1);

   double body  = MathAbs(close1 - open1);
   double lowerWick, upperWick;

   lowerWick = MathMin(open1, close1) - low1;
   upperWick = high1 - MathMax(open1, close1);

   // Evitar división por cuerpo cero (doji)
   if(body < _Point) body = _Point;

   if(isBuy)
      return (lowerWick >= body * InpWickRatio);
   else
      return (upperWick >= body * InpWickRatio);
}

//+=================================================================+
//|  CONFIRMACION DE SWEEP POR DISTANCIA MINIMA                      |
//+=================================================================+
// El sweep debe penetrar el nivel al menos InpMinSweepTicks ticks.
// Evita señales donde el precio apenas roza el high/low de referencia.
bool PassesMinSweepFilter(bool isBuy, double refLevel)
{
   if(InpMinSweepTicks <= 0) return true;

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
         && PassesSuperTrendFilter(true)
         && PassesRefCandleFilter()
         && PassesWickFilter(true)
         && PassesMinSweepFilter(true, low2))
      {
         double entryBuy, slBuy, tpBuy, slDist;

         if(InpDynamicSL)
         {
            // SL anclado al mínimo del sweep + buffer
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
            PrintFormat("CTR BUY | Entry:%.5f SL:%.5f TP:%.5f Lots:%.2f | SLDist:%d tks RR:%.1f | ST:%s SweepDist:%d tks",
                        entryBuy, slBuy, tpBuy, lots,
                        (int)(slDist/_Point), InpDynamicSL?InpRR:(InpTP_Pips/InpSL_Pips),
                        g_stBullish ? "BULL" : "BEAR",
                        (int)((low2 - low1) / _Point));
         }
      }
   }

   //--- SEÑAL DE VENTA
   if(InpDirection == DIRECTION_BOTH || InpDirection == DIRECTION_SELL)
   {
      bool sweepHigh = (high1 > high2) && (close1 < high2);
      if(sweepHigh
         && PassesSuperTrendFilter(false)
         && PassesRefCandleFilter()
         && PassesWickFilter(false)
         && PassesMinSweepFilter(false, high2))
      {
         double entrySell, slSell, tpSell, slDist;

         if(InpDynamicSL)
         {
            // SL anclado al máximo del sweep + buffer
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
                        (int)(slDist/_Point), InpDynamicSL?InpRR:(InpTP_Pips/InpSL_Pips),
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
   {
      if(g_pos.SelectByIndex(i))
         if(g_pos.Symbol() == _Symbol && g_pos.Magic() == EA_MAGIC)
            g_dailyProfit += g_pos.Profit() + g_pos.Swap() + g_pos.Commission();
   }
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
      if(sparam == EA_PREFIX + "BTN_CLOSEALL")        ClosePositions(false);
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
   MakeRect(EA_PREFIX + "PNL_BG",
            PANEL_X, PANEL_Y, PANEL_W, PANEL_H,
            C'12,16,28', C'40,60,130', 2);
   MakeRect(EA_PREFIX + "PNL_HEADER",
            PANEL_X, PANEL_Y, PANEL_W, 26,
            C'20,30,70', C'40,60,130', 0);
   MakeLabel(EA_PREFIX + "PNL_ICON",  PANEL_X+10, PANEL_Y+5,  "◈", C'80,160,255', 11, true);
   MakeLabel(EA_PREFIX + "PNL_TITLE", PANEL_X+28, PANEL_Y+6,  "CTR PRO", clrWhite, 10, true);
   MakeLabel(EA_PREFIX + "PNL_VER",   PANEL_X+PANEL_W-55, PANEL_Y+8, "v1.30", C'80,100,160', 7, false);

   MakeRect(EA_PREFIX+"DIV1", PANEL_X+8, PANEL_Y+28, PANEL_W-16, 1, C'40,60,130', C'40,60,130', 0);

   int y = PANEL_Y + 34;
   MakeLabel(EA_PREFIX+"LBL_STATUS", PANEL_X+12, y, "Estado:",     C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_STATUS", PANEL_X+100, y, "ACTIVO",      clrLime,       8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_SPREAD", PANEL_X+12, y, "Spread:",     C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_SPREAD", PANEL_X+100, y, "-- pts",      clrYellow,     8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_PROFIT", PANEL_X+12, y, "P/L Diario:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_PROFIT", PANEL_X+100, y, "$0.00",       clrWhite,      8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_TRADES", PANEL_X+12, y, "Trades hoy:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_TRADES", PANEL_X+100, y,
             "0 / "+IntegerToString(InpMaxPerDay), clrWhite, 8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_DIR",    PANEL_X+12, y, "Dirección:",  C'120,140,200', 8, false);
   string dirTxt = (InpDirection==DIRECTION_BUY) ? "▲ COMPRA" :
                   (InpDirection==DIRECTION_SELL)? "▼ VENTA"  : "◆ AMBOS";
   color  dirClr = (InpDirection==DIRECTION_BUY) ? clrLime :
                   (InpDirection==DIRECTION_SELL)? clrOrangeRed : clrCyan;
   MakeLabel(EA_PREFIX+"VAL_DIR",    PANEL_X+100, y, dirTxt, dirClr, 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_RISK",   PANEL_X+12, y, "Riesgo:",     C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_RISK",   PANEL_X+100, y,
             "$"+DoubleToString(InpRiskUSD,2), C'255,160,60', 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_SLMODE", PANEL_X+12, y, "Modo SL:",    C'120,140,200', 8, false);
   string slModeTxt = InpDynamicSL ?
                      "DIN RR:"+DoubleToString(InpRR,1) :
                      "MAN "+DoubleToString(InpSL_Pips,0)+"/"+DoubleToString(InpTP_Pips,0);
   color  slModeClr = InpDynamicSL ? C'80,220,180' : C'180,180,80';
   MakeLabel(EA_PREFIX+"VAL_SLMODE", PANEL_X+100, y, slModeTxt, slModeClr, 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_SES",    PANEL_X+12, y, "Sesión UTC:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_SES",    PANEL_X+100, y,
             StringFormat("%02d:%02d→%02d:%02d",InpUTCStartHour,InpUTCStartMin,
                          InpUTCEndHour,InpUTCEndMin), C'160,200,255', 8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_ST",     PANEL_X+12, y, "Supertrend:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_ST",     PANEL_X+100, y,
             InpSTFilter ? "ON" : "OFF",
             InpSTFilter ? clrLime : C'100,100,140', 8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_STDIR",  PANEL_X+12, y, "ST Dir:",     C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_STDIR",  PANEL_X+100, y, "---",         clrWhite,      8, true);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_TIMER",  PANEL_X+12, y, "Timer:",      C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_TIMER",  PANEL_X+100, y,
             InpTimerEnable ? IntegerToString(InpMaxMinutes)+"min" : "OFF",
             InpTimerEnable ? C'255,160,60' : C'100,100,140', 8, false);

   y += 16;
   MakeLabel(EA_PREFIX+"LBL_TOPEN",  PANEL_X+12, y, "En operac.:", C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"VAL_TOPEN",  PANEL_X+100, y, "--min",       clrWhite,      8, false);

   MakeRect(EA_PREFIX+"DIV2", PANEL_X+8, y+14, PANEL_W-16, 1, C'40,60,130', C'40,60,130', 0);

   y += 20;
   MakeLabel(EA_PREFIX+"LBL_LEVELS", PANEL_X+12, y, "Niveles:",    C'120,140,200', 8, false);
   MakeLabel(EA_PREFIX+"IND_TP",     PANEL_X+80,  y, "● TP",       clrLime,       8, true);
   MakeLabel(EA_PREFIX+"IND_SL",     PANEL_X+118, y, "● SL",       clrRed,        8, true);
   MakeLabel(EA_PREFIX+"IND_IN",     PANEL_X+158, y, "● IN",       C'100,160,255',8, true);

   MakeRect(EA_PREFIX+"DIV3", PANEL_X+8, y+14, PANEL_W-16, 1, C'40,60,130', C'40,60,130', 0);

   y += 20;
   MakeButton(EA_PREFIX+"BTN_CLOSEALL",    PANEL_X+8,   y, 68, 18, "Cerrar Todo", C'160,40,40',  clrWhite);
   MakeButton(EA_PREFIX+"BTN_CLOSEPROFIT", PANEL_X+82,  y, 72, 18, "Cerrar +$",   C'30,120,70',  clrWhite);
   MakeButton(EA_PREFIX+"BTN_PAUSE",       PANEL_X+161, y, 62, 18, "Pausar",      C'60,60,150',  clrWhite);

   ChartRedraw(0);
}

//+=================================================================+
//|  PANEL VISUAL — ACTUALIZAR                                       |
//+=================================================================+
void UpdatePanel()
{
   bool  inSes  = IsInSession() && IsTradingDay();
   long  spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   bool  sprdOK = (spread <= InpMaxSpread);

   string stTxt; color stClr;
   if(g_paused)                           { stTxt="⏸ PAUSADO";   stClr=clrOrange; }
   else if(!inSes)                        { stTxt="◌ INACTIVO";  stClr=C'100,100,140'; }
   else if(!sprdOK)                       { stTxt="⚠ SPREAD!";   stClr=clrOrange; }
   else if(g_tradesToday>=InpMaxPerDay)   { stTxt="✔ LÍMITE DÍA";stClr=clrYellow; }
   else                                   { stTxt="● ACTIVO";    stClr=clrLime; }
   ObjectSetString (0,EA_PREFIX+"VAL_STATUS",OBJPROP_TEXT, stTxt);
   ObjectSetInteger(0,EA_PREFIX+"VAL_STATUS",OBJPROP_COLOR,stClr);

   ObjectSetString (0,EA_PREFIX+"VAL_SPREAD",OBJPROP_TEXT,
                    IntegerToString((int)spread)+" pts");
   ObjectSetInteger(0,EA_PREFIX+"VAL_SPREAD",OBJPROP_COLOR, sprdOK?clrYellow:clrRed);

   color profClr = (g_dailyProfit>=0)?clrLime:clrRed;
   ObjectSetString (0,EA_PREFIX+"VAL_PROFIT",OBJPROP_TEXT,
                    (g_dailyProfit>=0?"+$":"-$")+DoubleToString(MathAbs(g_dailyProfit),2));
   ObjectSetInteger(0,EA_PREFIX+"VAL_PROFIT",OBJPROP_COLOR,profClr);

   ObjectSetString (0,EA_PREFIX+"VAL_TRADES",OBJPROP_TEXT,
                    IntegerToString(g_tradesToday)+" / "+IntegerToString(InpMaxPerDay));
   ObjectSetInteger(0,EA_PREFIX+"VAL_TRADES",OBJPROP_COLOR,
                    g_tradesToday>=InpMaxPerDay?clrOrange:clrWhite);

   //--- Supertrend dirección
   if(InpSTFilter)
   {
      string stDir = g_stBullish ? "▲ ALCISTA" : "▼ BAJISTA";
      color  stDirClr = g_stBullish ? clrLime : clrOrangeRed;
      ObjectSetString (0,EA_PREFIX+"VAL_STDIR",OBJPROP_TEXT, stDir);
      ObjectSetInteger(0,EA_PREFIX+"VAL_STDIR",OBJPROP_COLOR,stDirClr);
   }

   //--- Tiempo en operación abierta
   string timerTxt = "--min";
   color  timerClr = clrWhite;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(g_pos.SelectByIndex(i))
         if(g_pos.Symbol()==_Symbol && g_pos.Magic()==EA_MAGIC)
         {
            int elapsed = (int)((TimeCurrent() - g_pos.Time()) / 60);
            timerTxt = IntegerToString(elapsed) + "min";
            timerClr = (elapsed >= InpMaxMinutes*8/10) ? clrOrange : clrLime;
            break;
         }
   }
   ObjectSetString (0,EA_PREFIX+"VAL_TOPEN",OBJPROP_TEXT, timerTxt);
   ObjectSetInteger(0,EA_PREFIX+"VAL_TOPEN",OBJPROP_COLOR,timerClr);

   ObjectSetString(0,EA_PREFIX+"BTN_PAUSE",OBJPROP_TEXT,
                   g_paused?"▶ Reanudar":"⏸ Pausar");
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

   datetime t0 = signalTime;
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 0);

   ObjArrow(pfx+"ARROW", t0, isBuy?sl*0.9998:sl*1.0002,
            isBuy?241:242, isBuy?clrLime:clrOrangeRed, 3);
   ObjText(pfx+"LABEL", t0, isBuy?sl*0.9996:sl*1.0004, "CTR ENTRY", clrMagenta, 8);
   ObjHLine(pfx+"ENTRY_LINE", entry, C'100,160,255', STYLE_DASHDOT, 1);
   ObjHLine(pfx+"TP_LINE",    tp,    clrLime,         STYLE_SOLID,  1);
   ObjText (pfx+"TP_LABEL",   t1, tp, "TP:"+DoubleToString(tp,_Digits), clrLime, 8);
   ObjHLine(pfx+"SL_LINE",    sl,    clrRed,           STYLE_SOLID,  1);
   ObjText (pfx+"SL_LABEL",   t1, sl, "SL:"+DoubleToString(sl,_Digits), clrRed,  8);
   ObjTrendLine(pfx+"SWEEP_LINE", iTime(_Symbol,PERIOD_CURRENT,2), prevLevel,
                t0, prevLevel, C'220,80,120', STYLE_DOT, 1);
   ObjTrendLine(pfx+"DIAG_TP", t0,entry, t1,tp, C'255,160,40', STYLE_DOT, 1);
   ObjTrendLine(pfx+"DIAG_SL", t0,entry, t1,sl, C'255,80,80',  STYLE_DOT, 1);

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
   string pfx   = EA_PREFIX+"S"+IntegerToString(oldest)+"_";
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
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);  ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width); ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
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
   ObjectSetString (0,name,OBJPROP_TEXT,txt);      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fs);   ObjectSetString(0,name,OBJPROP_FONT,"Arial Bold");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
}
void ObjTrendLine(string name,datetime t1,double p1,datetime t2,double p2,
                  color clr,ENUM_LINE_STYLE style,int width)
{
   ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);      ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);    ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
}
//+------------------------------------------------------------------+
//|  FIN DEL EA                                                       |
//+------------------------------------------------------------------+
