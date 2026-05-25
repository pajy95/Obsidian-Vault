//+------------------------------------------------------------------+
//|                                       BreakoutNY_GER40_FP.mq5   |
//|              BreakoutNY EA v1.0 — FundingPips GER40             |
//|                                                                   |
//|  Adaptado del NAS100 v9.1 — Jose Yanez                          |
//|  Specs GER40 FundingPips:                                        |
//|    digits=2 | tickSize=0.01 | tickValue=0.01 EUR                 |
//|    VPP=29.2938 EUR/pt/lot | volMin=0.01 | volMax=10              |
//|                                                                   |
//|  Parámetros calibrados (P25/P75 de 1172 días):                   |
//|    MinSL_Points = 2700  (P25 rango diario)                       |
//|    MaxSL_Points = 5321  (P75 rango diario)                       |
//|                                                                   |
//|  ═══ TRADING ══════════════════════════════════════════════════  |
//|  · Breakout de las 3 velas 14:35 / 14:40 / 14:45 UTC           |
//|  · Ventana de entrada 14:50 – 15:05 UTC (configurable)         |
//|  · BreakEven con buffer configurable (BE_BufferPct)             |
//|  · Parciales en TP1 y TP2 (desactivados por defecto)            |
//|  · Filtros: día semana + rango MinSL/MaxSL + ATR                |
//|  · ConfirmOnClose: espera cierre de vela M5 antes de entrar     |
//|  · Solo LONGS por defecto (sesgo alcista DAX como NAS100)       |
//|                                                                   |
//|  ═══ VISUAL ════════════════════════════════════════════════════ |
//|  · Zona del rango (rectángulo + bordes HIGH/LOW)                |
//|  · Niveles exactos: SL, ENTRY, BE, TP1, TP2, TP3               |
//|  · Flecha de dirección + línea vertical en ruptura              |
//|  · Panel superior derecho: estado en tiempo real                |
//|  · SL se mueve dinámicamente al activarse BE y TP2              |
//|  · Marcador de cierre de sesión (17:00 UTC)                     |
//|  · Marca de cierre al salir de la posición                      |
//+------------------------------------------------------------------+
#property copyright "BreakoutNY GER40 v1.0 — Jose Yanez"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//===================================================================
//  PARÁMETROS DE ENTRADA
//===================================================================

input group "=== HORARIO ==="
input int    ServerOffsetHours  = 2;     // Offset servidor vs UTC — FundingPips UTC+2
input int    EntryWindowEnd_Min = 15;    // Minutos ventana desde 14:50 UTC (default=15 → cierra 15:05)
input int    SessionCloseHour   = 17;    // Hora cierre forzoso UTC
input int    SessionCloseMin    = 0;     // Minuto cierre forzoso UTC

input group "=== RIESGO ==="
input double RiskAmountUSD      = 50.0;  // Riesgo por operación en USD ($5K=13 · $25K=65)

input group "=== OBJETIVOS ==="
input double TP1_RR             = 1.0;   // TP1 — 1:1 SL (activa BE)
input double TP2_RR             = 2.0;   // TP2 — 1:2 SL (SL sube a TP1)
input double TP3_RR             = 3.0;   // TP3 — 1:3 SL (objetivo final)

input group "=== CIERRES PARCIALES ==="
input bool   EnablePartials     = false; // Backtesting IS/OOS: cierra todo en TP3
input int    TP1_ClosePct       = 40;    // % del lote a cerrar en TP1 (0-60)
input int    TP2_ClosePct       = 40;    // % del lote a cerrar en TP2 (0-60)

input group "=== BREAKEVEN ==="
input double BE_BufferPct       = 70.0;  // Buffer BE: % del SL como ganancia minima al activar
                                          // Rango optimo GER40: 50-90 (PARAMETRO DE OPTIMIZACION)

input group "=== FILTROS DE RANGO ==="
input double MinSL_Points       = 2700.0; // Rango minimo GER40 en pts (P25 calibrado=2700)
                                           // 1 punto GER40 = 0.01 unidades de precio
input double MaxSL_Points       = 5321.0; // Rango maximo GER40 en pts (P75 calibrado=5321)

input group "=== FILTROS DE DIA ==="
input bool   FilterMonday       = true;  // Operar lunes
input bool   FilterTuesday      = true;  // Operar martes
input bool   FilterWednesday    = false; // Operar miercoles — OPTIMIZAR
input bool   FilterThursday     = false; // Operar jueves — OPTIMIZAR
input bool   FilterFriday       = true;  // Operar viernes
                                          // Baseline: L+M+V (igual que NAS100)
                                          // Alternativa: M+X+J (mayor InRange% y media)

input group "=== DIRECCION ==="
input bool   FilterShorts       = true;  // true = solo LONGS (recomendado: DAX tiene sesgo alcista)
                                          // false = permite SELL (verificar en backtest)

input group "=== CONFIRMACION DE ENTRADA ==="
input bool   ConfirmOnClose     = true;  // Esperar cierre de vela M5 antes de entrar
                                          // true  = filtra mechas falsas (recomendado)
                                          // false = entrada inmediata en primer tick

input group "=== FILTRO ATR (VOLATILIDAD) ==="
input bool   ATR_FilterEnable   = true;  // Activar filtro ATR
input int    ATR_Period         = 14;    // Periodo ATR en M5
input double ATR_MaxMultiplier  = 2.0;   // Bloquea si ATR > baseline x este valor
input double ATR_MinMultiplier  = 0.5;   // Bloquea si ATR < baseline x este valor
input int    ATR_BaselineDays   = 20;    // Dias de lookback para calcular baseline ATR

input group "=== LOGGING ==="
input bool   EnableCSV          = true;
input string CSVFileName        = "BreakoutNY_GER40_trades";

input group "=== VISUAL ==="
input bool   VIS_Enable         = true;  // Activar modulo visual
input int    VIS_LookbackDays   = 25;    // Dias historicos a redibujar al iniciar
input int    VIS_ExtendBars     = 50;    // Velas que se extienden los niveles hacia la derecha
input bool   VIS_ShowBE         = true;  // Mostrar linea de BreakEven
input bool   VIS_ShowLabel      = true;  // Mostrar panel informativo en esquina
input color  VIS_ColRange       = C'14,25,52';    // Fondo zona de rango
input color  VIS_ColRangeBorder = C'55,115,215';  // Bordes HIGH/LOW del rango
input color  VIS_ColSL          = C'220,50,70';   // Stop Loss
input color  VIS_ColEntry       = C'195,208,230'; // Entrada
input color  VIS_ColBE          = C'0,195,218';   // BreakEven
input color  VIS_ColTP1         = C'228,188,38';  // TP1
input color  VIS_ColTP2         = C'228,128,28';  // TP2
input color  VIS_ColTP3         = C'28,208,128';  // TP3

input group "=== CONFIGURACION ==="
input ulong  MagicNumber        = 202403; // Magic number GER40 — no colisiona con NAS100(202401)/DJI30(202402)/XAU(202409)
input double EUR_USD_Fallback   = 1.08;   // Tasa EUR/USD fallback para backtester (Strategy Tester no provee EURUSD)
                                           // Actualizar segun condicion de mercado antes de backtestear
input double VPP_Fallback       = 29.2938; // VPP fallback EUR/pt/lot (FundingPips GER40)
                                            // El backtester reporta tv/ts=1.0 EUR en lugar del VPP real
                                            // Valor real FundingPips: 29.2938 EUR/pt/lot
                                            // Se activa cuando VPP calculado <= 2.0 EUR/pt

//===================================================================
//  VARIABLES GLOBALES
//===================================================================

CTrade        trade;
CPositionInfo posInfo;

#define VIS_PFX "BNYGER_"

// Estado diario
bool     rangeCalculated = false;
bool     tradeExecuted   = false;
bool     dayFiltered     = false;
bool     rangeFiltered   = false;
double   rangeHigh       = 0;
double   rangeLow        = 0;
double   slDistance      = 0;  // en unidades de precio GER40 (no en _Point)
datetime lastTradeDay    = 0;
double   cachedLots      = 0;

// Estado operacion activa
ulong    activeTicket    = 0;
double   entryPrice      = 0;
double   originalSL      = 0;
double   originalLots    = 0;
string   tradeDir        = "";
double   tp1Price        = 0;
double   tp2Price        = 0;
double   tp3Price        = 0;
double   bePrice         = 0;
bool     phase1Done      = false;
bool     phase2Done      = false;

// ConfirmOnClose state
bool     breakoutPending = false;
string   pendingDir      = "";
datetime pendingBarTime  = 0;

// Logging
int      csvHandle       = INVALID_HANDLE;
datetime log_OpenTime    = 0;
string   log_Weekday     = "";
bool     log_Phase1Hit   = false;
bool     log_Phase2Hit   = false;
double   log_SL_Pts      = 0;
double   log_ValuePerPoint   = 0;
double   log_LotsCalculated  = 0;
double   log_RiskReal_USD    = 0;
double   log_RangeHigh       = 0;
double   log_RangeLow        = 0;
double   log_SL_Final        = 0;
bool     log_BE_Activated    = false;
bool     log_ConfirmUsed     = false;

// OnTester stats
int      stat_total      = 0;
int      stat_wins       = 0;
int      stat_losses     = 0;
double   stat_grossProfit= 0;
double   stat_grossLoss  = 0;

// Visual
string   vis_dayTag      = "";
bool     vis_hasTrade    = false;

//===================================================================
//  FUNCIONES AUXILIARES
//===================================================================

void GetCurrentUTC(int &hour, int &minute)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, dt);
   hour = dt.hour; minute = dt.min;
}

int GetWeekdayUTC()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent() - (long)ServerOffsetHours * 3600, dt);
   return dt.day_of_week;
}

string WeekdayName(int wd)
{
   string n[] = {"Domingo","Lunes","Martes","Miercoles","Jueves","Viernes","Sabado"};
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

//===================================================================
//  CALCULO DE LOTE
//
//  PROBLEMA GER40: el broker reporta TickValue en EUR (divisa del
//  instrumento), pero la cuenta es USD. Sin conversión EUR→USD el
//  VPP queda subvalorado y el lotaje cae al mínimo (0.01).
//
//  SOLUCIÓN: después de calcular VPP en la divisa del instrumento,
//  convertir a USD usando el precio EURUSD si es necesario.
//
//  Cascada de métodos:
//    1. tv/ts válidos  → VPP_instr = tv/ts
//    2. tv=0           → VPP_instr = ContractSize × Point  (fallback CFD)
//    3. Conversión     → VPP_usd   = VPP_instr × EURUSD   (si profit=EUR y cuenta=USD)
//===================================================================

double CalculateLotSize(double slDistance_price)
{
   // slDistance_price = rangeHigh - rangeLow en unidades de precio
   // Para GER40 digits=2: 1 punto broker = _Point = 0.01 precio
   double slPts = slDistance_price / _Point;   // puntos del broker
   if(slPts <= 0) return 0;

   double tv  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double cs  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double pt  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ls  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double mn  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double mx  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double valuePerPoint = 0;

   if(tv > 0 && ts > 0)
      valuePerPoint = tv / ts;
   else if(cs > 0)
   {
      valuePerPoint = cs * pt;
      Print("INFO LotCalc: TickValue=0. Fallback: VPP=ContractSize x Point=", valuePerPoint);
   }
   else
   {
      Print("ERROR LotCalc: Datos insuficientes. TV=", tv, " TS=", ts, " CS=", cs);
      return mn;
   }

   if(valuePerPoint <= 0)
   {
      Print("ERROR LotCalc: valuePerPoint=0.");
      return mn;
   }

   // El backtester de MT5 reporta tv/ts = 0.01/0.01 = 1.0 EUR/pt para GER40,
   // que es el valor contable del tick, no el VPP real del CFD (29.2938 EUR/pt).
   // Si el VPP calculado es <= 2.0 EUR, claramente es el valor contable del tick
   // y no el VPP real — usar VPP_Fallback.
   if(valuePerPoint <= 2.0)
   {
      PrintFormat("LotCalc VPP FALLBACK: VPP calculado=%.4f EUR/pt (backtester). Usando VPP_Fallback=%.4f EUR/pt",
                  valuePerPoint, VPP_Fallback);
      valuePerPoint = VPP_Fallback;
   }

   // ── Conversión de divisa del instrumento → divisa de la cuenta ──
   // GER40: SYMBOL_CURRENCY_PROFIT = "EUR", cuenta = "USD"
   // Si no se convierte, VPP queda en EUR y el lotaje se calcula mal
   string profitCurrency  = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
   if(profitCurrency != accountCurrency)
   {
      // Buscar el cruce directo (ej. EURUSD) o inverso (ej. USDEUR)
      string pairDirect  = profitCurrency + accountCurrency;  // EURUSD
      string pairInverse = accountCurrency + profitCurrency;  // USDEUR
      double convRate    = 0;

      double bidDirect = SymbolInfoDouble(pairDirect, SYMBOL_BID);
      if(bidDirect > 0)
      {
         convRate = bidDirect;
         PrintFormat("LotCalc FX: %s=%s → convirtiendo VPP × %.5f (%s)",
                     profitCurrency, accountCurrency, convRate, pairDirect);
      }
      else
      {
         double bidInverse = SymbolInfoDouble(pairInverse, SYMBOL_BID);
         if(bidInverse > 0)
         {
            convRate = 1.0 / bidInverse;
            PrintFormat("LotCalc FX: %s=%s → convirtiendo VPP / %.5f (%s inverso)",
                        profitCurrency, accountCurrency, bidInverse, pairInverse);
         }
      }

      if(convRate <= 0)
      {
         convRate = EUR_USD_Fallback;
         PrintFormat("LotCalc FX FALLBACK: %s/%s no disponible (backtester). Usando EUR_USD_Fallback=%.5f",
                     profitCurrency, accountCurrency, convRate);
      }
      if(convRate > 0)
         valuePerPoint *= convRate;
   }

   // Riesgo = SL_pts × VPP_usd × lots  →  lots = RiskUSD / (SL_pts × VPP_usd)
   double lotsRaw  = RiskAmountUSD / (slPts * valuePerPoint);
   double lots     = MathFloor(lotsRaw / ls) * ls;
   lots            = MathMax(mn, MathMin(mx, lots));
   double realRisk = slPts * valuePerPoint * lots;

   log_ValuePerPoint  = valuePerPoint;
   log_RiskReal_USD   = realRisk;
   log_LotsCalculated = lotsRaw;

   // Verificacion de margen
   double freeMargin   = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginPerLot = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0,
                       SymbolInfoDouble(_Symbol, SYMBOL_ASK), marginPerLot))
      marginPerLot = SymbolInfoDouble(_Symbol, SYMBOL_ASK) * cs * 0.05;

   if(marginPerLot > 0)
   {
      double maxByMargin = MathFloor((freeMargin * 0.90) / marginPerLot / ls) * ls;
      maxByMargin = MathMax(mn, MathMin(mx, maxByMargin));
      if(lots > maxByMargin)
      {
         Print("AVISO Margen: lots=", DoubleToString(lots,2),
               " excede margen libre=$", DoubleToString(freeMargin,2),
               " max=", DoubleToString(maxByMargin,2), " lots. Reduciendo.");
         lots     = maxByMargin;
         realRisk = slPts * valuePerPoint * lots;
         log_RiskReal_USD = realRisk;
      }
   }

   PrintFormat("LotCalc | SL=%.0f pts | VPP(%s)=$%.4f/pt/lot | Raw=%.4f | Lots=%.2f | Risk=$%.2f | Margin/lot=$%.2f",
               slPts, accountCurrency, valuePerPoint, lotsRaw, lots, realRisk, marginPerLot);
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
         high = rates[i].high; low = rates[i].low; return true;
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
   if(lotsToClose < minLot) return trade.PositionClose(ticket);
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
//  LOGGING CSV
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
      "SL_Pts_broker","RR_TP1","RR_TP2","RR_TP3",
      "BE_Buffer_Pct","TP1_ClosePct","TP2_ClosePct",
      "Phase1Hit","Phase2Hit",
      "ExitType","ClosePrice","PnL_USD",
      "DayFiltered","RangeFiltered",
      "MinSL_Filter","MaxSL_Filter","EntryWindowEnd",
      "ValuePerPoint","LotsRaw","RiskReal_USD",
      "RangeHigh","RangeLow","SL_Final","BE_Activated",
      "ConfirmOnClose","FilterShorts");
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
      DoubleToString(entryPrice, _Digits), DoubleToString(originalSL, _Digits),
      DoubleToString(tp1Price,   _Digits), DoubleToString(tp2Price,   _Digits),
      DoubleToString(tp3Price,   _Digits), DoubleToString(originalLots, 2),
      DoubleToString(log_SL_Pts, 1),
      DoubleToString(TP1_RR,1), DoubleToString(TP2_RR,1), DoubleToString(TP3_RR,1),
      DoubleToString(BE_BufferPct, 1),
      IntegerToString(EnablePartials ? TP1_ClosePct : 0),
      IntegerToString(EnablePartials ? TP2_ClosePct : 0),
      log_Phase1Hit ? "1":"0", log_Phase2Hit ? "1":"0",
      exitType, DoubleToString(closePrice, _Digits), DoubleToString(pnl, 2),
      dayFlt?"1":"0", rngFlt?"1":"0",
      DoubleToString(MinSL_Points,0), DoubleToString(MaxSL_Points,0),
      IntegerToString(EntryWindowEnd_Min),
      DoubleToString(log_ValuePerPoint, 4), DoubleToString(log_LotsCalculated, 4),
      DoubleToString(log_RiskReal_USD, 2),
      DoubleToString(log_RangeHigh, _Digits), DoubleToString(log_RangeLow, _Digits),
      DoubleToString(log_SL_Final, _Digits),
      log_BE_Activated ? "1":"0", log_ConfirmUsed ? "1":"0",
      FilterShorts ? "1":"0");
}

void WriteFilteredRow(string reason)
{
   if(!EnableCSV || csvHandle == INVALID_HANDLE) return;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   string ds = StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day);
   FileWrite(csvHandle,
      ds, "", WeekdayName(GetWeekdayUTC()), "",
      "","","","","","","","","","",
      DoubleToString(BE_BufferPct,1),
      IntegerToString(TP1_ClosePct), IntegerToString(TP2_ClosePct),
      "0","0",
      "filtered_"+reason,"","0",
      reason=="day"?"1":"0", reason=="range"?"1":"0",
      DoubleToString(MinSL_Points,0), DoubleToString(MaxSL_Points,0),
      IntegerToString(EntryWindowEnd_Min));
}

//===================================================================
//  RESET DIARIO
//===================================================================

void DailyReset()
{
   rangeCalculated = false; tradeExecuted   = false;
   dayFiltered     = false; rangeFiltered   = false;
   rangeHigh       = 0;     rangeLow        = 0;     slDistance   = 0;
   cachedLots      = 0;
   activeTicket    = 0;     entryPrice      = 0;     originalSL   = 0;
   originalLots    = 0;     tradeDir        = "";
   tp1Price        = 0;     tp2Price        = 0;
   tp3Price        = 0;     bePrice         = 0;
   phase1Done      = false; phase2Done      = false;
   log_OpenTime    = 0;     log_Weekday     = "";
   log_Phase1Hit   = false; log_Phase2Hit   = false;
   log_SL_Pts      = 0;
   log_ValuePerPoint = 0;   log_LotsCalculated = 0;
   log_RiskReal_USD  = 0;   log_RangeHigh      = 0;
   log_RangeLow      = 0;   log_SL_Final       = 0;
   log_BE_Activated  = false; log_ConfirmUsed   = false;
   breakoutPending   = false; pendingDir        = "";
   pendingBarTime    = 0;
   vis_dayTag   = ""; vis_hasTrade = false;
}

//===================================================================
//  ██████╗  MODULO VISUAL
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
   ObjectSetInteger(0, name, OBJPROP_TIME,       t);
   ObjectSetDouble(0,  name, OBJPROP_PRICE,      price);
   ObjectSetString(0,  name, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   sz);
   ObjectSetString(0,  name, OBJPROP_FONT,       "Consolas");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, name, OBJPROP_BACK,       back);
}

// Nivel horizontal con etiqueta al lado derecho
void VisLevel(const string name,
              datetime t1, datetime t2, double price,
              color clr, ENUM_LINE_STYLE style, int width,
              const string label)
{
   VisSegment(name, t1, t2, price, price, clr, style, width, false);
   datetime tLabel   = t2 + (datetime)(PeriodSeconds(PERIOD_M5));
   // GER40 tiene digits=2 → mostrar con 2 decimales
   string   priceStr = DoubleToString(price, 2);
   VisText(name + "_LBL", tLabel, price,
           " " + label + " " + priceStr,
           clr, 7, ANCHOR_LEFT_UPPER, false);
}

// Mueve una linea ya dibujada (SL dinamico al activarse BE o TP2)
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
   ObjectSetString(0, lblName, OBJPROP_TEXT, lbl + DoubleToString(newPrice, 2) + " ");
   ChartRedraw();
}

// Busca una vela especifica (hora:min UTC) dentro del array de rates
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

//===================================================================
//  DIBUJAR UN DIA COMPLETO
//  Niveles calculados con la misma formula que el EA de trading
//  → visualizacion exactamente alineada con Entry/SL/BE/TP1/TP2/TP3
//===================================================================

void VisDrawDay(const MqlRates &R[], int total, datetime dayUTC)
{
   double h35,l35, h40,l40, h45,l45;
   datetime t35, t40, t45;
   if(!VisGetCandle(R, total, dayUTC, 14,35, h35,l35,t35)) return;
   if(!VisGetCandle(R, total, dayUTC, 14,40, h40,l40,t40)) return;
   if(!VisGetCandle(R, total, dayUTC, 14,45, h45,l45,t45)) return;

   double rH  = MathMax(h35, MathMax(h40, h45));
   double rL  = MathMin(l35, MathMin(l40, l45));
   double slD = rH - rL;   // slDistance en unidades de precio (igual que el EA)

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

   VisSegment(VIS_PFX+"RH_"+tag, t35, tRangeEnd, rH, rH, VIS_ColRangeBorder, STYLE_SOLID, 2, true);
   VisSegment(VIS_PFX+"RL_"+tag, t35, tRangeEnd, rL, rL, VIS_ColRangeBorder, STYLE_SOLID, 2, true);
   VisText(VIS_PFX+"LRHI_"+tag, t35, rH, "  RANGE HIGH", VIS_ColRangeBorder, 8, ANCHOR_LEFT_LOWER, false);
   VisText(VIS_PFX+"LRLO_"+tag, t35, rL, "  RANGE LOW",  VIS_ColRangeBorder, 8, ANCHOR_LEFT_UPPER, false);

   // Etiqueta con rango en puntos GER40 encima del rango
   double slPts = slD / _Point;
   VisText(VIS_PFX+"SLPTS_"+tag, t35, rH,
           StringFormat("  %.0f pts | SL=%.2f", slPts, slD),
           C'150,170,210', 7, ANCHOR_LEFT_LOWER, false);

   // Buscar ruptura en ventana 14:50 – 14:50+EntryWindowEnd_Min UTC
   double   eEntry=0, eSL=0, eTp1=0, eTp2=0, eTp3=0, eBE=0;
   string   eDir="";
   datetime eBreak=0;
   bool     broke=false;

   for(int i = total - 1; i >= 0; i--)
   {
      MqlDateTime u;
      TimeToStruct(R[i].time - (long)ServerOffsetHours * 3600, u);
      datetime barDay = StringToTime(
         StringFormat("%04d.%02d.%02d 00:00:00", u.year, u.mon, u.day));
      if(barDay != dayUTC) continue;

      bool inWin = (u.hour == 14 && u.min >= 50) ||
                   (u.hour == 15 && u.min <= EntryWindowEnd_Min);
      if(!inWin) continue;

      // BUY — solo si FilterShorts=true o si FilterShorts=false y es bullbreak
      if(R[i].high > rH && !FilterShorts)
      {
         // Con FilterShorts=false: el EA puede entrar en ambas direcciones
         // Si el precio rompe por arriba primero, es BUY
         double entryPx = (i + 1 < total) ? R[i+1].open : R[i].close;
         eEntry = entryPx; eDir = "buy"; eBreak = R[i].time;
         eSL  = NormalizeDouble(eEntry - slD,                          _Digits);
         eTp1 = NormalizeDouble(eEntry + slD * TP1_RR,                 _Digits);
         eTp2 = NormalizeDouble(eEntry + slD * TP2_RR,                 _Digits);
         eTp3 = NormalizeDouble(eEntry + slD * TP3_RR,                 _Digits);
         eBE  = NormalizeDouble(eEntry + slD * (BE_BufferPct / 100.0), _Digits);
         broke = true; break;
      }
      if(R[i].high > rH && FilterShorts)
      {
         // Solo LONGS
         double entryPx = (i + 1 < total) ? R[i+1].open : R[i].close;
         eEntry = entryPx; eDir = "buy"; eBreak = R[i].time;
         eSL  = NormalizeDouble(eEntry - slD,                          _Digits);
         eTp1 = NormalizeDouble(eEntry + slD * TP1_RR,                 _Digits);
         eTp2 = NormalizeDouble(eEntry + slD * TP2_RR,                 _Digits);
         eTp3 = NormalizeDouble(eEntry + slD * TP3_RR,                 _Digits);
         eBE  = NormalizeDouble(eEntry + slD * (BE_BufferPct / 100.0), _Digits);
         broke = true; break;
      }
      if(R[i].low < rL && !FilterShorts)
      {
         double entryPx = (i + 1 < total) ? R[i+1].open : R[i].close;
         eEntry = entryPx; eDir = "sell"; eBreak = R[i].time;
         eSL  = NormalizeDouble(eEntry + slD,                          _Digits);
         eTp1 = NormalizeDouble(eEntry - slD * TP1_RR,                 _Digits);
         eTp2 = NormalizeDouble(eEntry - slD * TP2_RR,                 _Digits);
         eTp3 = NormalizeDouble(eEntry - slD * TP3_RR,                 _Digits);
         eBE  = NormalizeDouble(eEntry - slD * (BE_BufferPct / 100.0), _Digits);
         broke = true; break;
      }
   }

   if(broke)
   {
      bool     isBuy = (eDir == "buy");
      datetime tEnd  = eBreak + (datetime)(VIS_ExtendBars * PeriodSeconds(PERIOD_M5));

      // Flecha de direccion — 2 velas antes del rango
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

      // Linea vertical en la vela de ruptura
      string nVL = VIS_PFX + "VL_" + tag;
      if(ObjectFind(0, nVL) < 0)
         ObjectCreate(0, nVL, OBJ_VLINE, 0, eBreak, 0);
      ObjectSetInteger(0, nVL, OBJPROP_COLOR,      isBuy ? C'40,140,80' : C'180,50,70');
      ObjectSetInteger(0, nVL, OBJPROP_STYLE,      STYLE_DOT);
      ObjectSetInteger(0, nVL, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, nVL, OBJPROP_BACK,       true);
      ObjectSetInteger(0, nVL, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nVL, OBJPROP_HIDDEN,     true);

      // Niveles alineados exactamente con la formula de trading
      // SL    = entry - slDistance     (BUY) | entry + slDistance (SELL)
      // BE    = entry + slD*(BE/100)   (BUY) | entry - slD*(BE/100) (SELL)
      // TP1   = entry + slD*TP1_RR    (BUY) | entry - slD*TP1_RR (SELL)
      // TP2   = entry + slD*TP2_RR    (BUY) | ...
      // TP3   = entry + slD*TP3_RR    (BUY) | ...
      VisLevel(VIS_PFX+"SL_" +tag, eBreak, tEnd, eSL,    VIS_ColSL,    STYLE_DASH,  2, "SL");
      VisLevel(VIS_PFX+"EN_" +tag, eBreak, tEnd, eEntry, VIS_ColEntry, STYLE_SOLID, 1, "ENTRY");
      if(VIS_ShowBE)
         VisLevel(VIS_PFX+"BE_" +tag, eBreak, tEnd, eBE,  VIS_ColBE,  STYLE_DOT,   1, "BE");
      VisLevel(VIS_PFX+"TP1_"+tag, eBreak, tEnd, eTp1, VIS_ColTP1, STYLE_SOLID, 1, "TP1");
      VisLevel(VIS_PFX+"TP2_"+tag, eBreak, tEnd, eTp2, VIS_ColTP2, STYLE_SOLID, 1, "TP2");
      VisLevel(VIS_PFX+"TP3_"+tag, eBreak, tEnd, eTp3, VIS_ColTP3, STYLE_SOLID, 3, "TP3");

      // Marcador de cierre de sesion
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
      VisText(VIS_PFX+"SCL_"+tag, tClose, eTp3,
              StringFormat(" %d:%02d UTC", SessionCloseHour, SessionCloseMin),
              C'100,100,160', 7, ANCHOR_LEFT_UPPER, false);
   }
   else
   {
      VisText(VIS_PFX+"NOBRK_"+tag, tRangeEnd + 300, (rH+rL)/2.0,
              "  sin ruptura", C'80,100,130', 7, ANCHOR_LEFT, false);
   }
}

//===================================================================
//  REDIBUJAR HISTORICO COMPLETO
//===================================================================

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

   for(int i = 0; i < nDays; i++)
      VisDrawDay(R, copied, days[i]);

   VisDrawMottoPanel();
   VisUpdatePanel("", 0, 0, false, false, "");
   ChartRedraw();
}

//===================================================================
//  REDIBUJAR SOLO EL DIA ACTUAL
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
//  PANEL SUPERIOR DERECHO
//===================================================================

void VisUpdatePanel(string direction, double slPts, double netPL,
                    bool hasTrade, bool isFiltered, string filterReason)
{
   if(!VIS_Enable || !VIS_ShowLabel) return;

   MqlDateTime u; TimeToStruct(TimeCurrent() - (long)ServerOffsetHours*3600, u);
   string dayNames[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
   string dayStr  = dayNames[u.day_of_week];
   string dateStr = StringFormat("%02d/%02d/%04d", u.day, u.mon, u.year);
   string dirMode = FilterShorts ? "Solo Long" : "Long+Short";

   string line1, line2, line3, line4, line5;
   color  panelColor;

   if(isFiltered)
   {
      line1      = "BreakoutNY GER40 v1.0  |  " + _Symbol;
      line2      = dayStr + " " + dateStr + "  |  " + dirMode;
      line3      = "  " + filterReason;
      line4      = "Riesgo: $" + DoubleToString(RiskAmountUSD, 0) + "/trade";
      line5      = "";
      panelColor = C'100,100,140';
   }
   else if(!hasTrade && direction == "")
   {
      line1 = "BreakoutNY GER40 v1.0  |  " + _Symbol;
      line2 = dayStr + " " + dateStr + "  |  Esperando 14:50 UTC";
      line3 = "Riesgo $" + DoubleToString(RiskAmountUSD,0) +
              "  |  SL " + DoubleToString(MinSL_Points,0) +
              "-" + DoubleToString(MaxSL_Points,0) + " pts  |  " + dirMode;
      line4 = "BE " + DoubleToString(BE_BufferPct,0) + "%" +
              "  TP1 1:" + DoubleToString(TP1_RR,0) +
              "  TP2 1:" + DoubleToString(TP2_RR,0) +
              "  TP3 1:" + DoubleToString(TP3_RR,0);
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
      line1 = "BreakoutNY GER40 v1.0  |  " + _Symbol + "  |  " + dayStr;
      line2 = arrow + "  |  SL " + DoubleToString(slPts, 0) + " pts" +
              "  |  TP3 " + DoubleToString(slPts * TP3_RR, 0) + " pts";
      line3 = "Riesgo $" + DoubleToString(RiskAmountUSD, 0) +
              "  |  BE " + DoubleToString(BE_BufferPct, 0) + "%" +
              "  |  " + dirMode;
      line4 = hasTrade ? ("P/L flotante:  " + plStr) : "Sin posicion abierta";
      line5 = "";
      panelColor = isBuy ? VIS_ColTP3 : VIS_ColSL;
   }

   string pnames[] = {"PNL1","PNL2","PNL3","PNL4","PNL5"};
   string ptexts[5]; ptexts[0]=line1; ptexts[1]=line2;
   ptexts[2]=line3;  ptexts[3]=line4; ptexts[4]=line5;
   int pyoffs[] = {15, 30, 45, 60, 75};
   int pfonts[] = {9,  9,  8,  9,   8};

   for(int i = 0; i < 5; i++)
   {
      if(ptexts[i] == "") { ObjectDelete(0, VIS_PFX+pnames[i]); continue; }
      string nm = VIS_PFX + pnames[i];
      if(ObjectFind(0, nm) < 0)
         ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER,     CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE,  12);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE,  pyoffs[i]);
      ObjectSetString(0,  nm, OBJPROP_TEXT,       ptexts[i]);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,      (i==0) ? C'195,208,230' : panelColor);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,   pfonts[i]);
      ObjectSetString(0,  nm, OBJPROP_FONT,       "Consolas");
      ObjectSetInteger(0, nm, OBJPROP_ANCHOR,     ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     false);
      ObjectSetInteger(0, nm, OBJPROP_BACK,       false);
   }
}

//===================================================================
//  PANEL INFERIOR — identidad del EA
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
      "\"MinSL=2700 pts  |  MaxSL=5321 pts  |  BE_BufferPct=70  |  Calibrado P25/P75 de 1172 dias\"");
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
      "\"VPP=29.2938 EUR/pt/lot  |  digits=2  |  tickSize=0.01  |  tickValue=0.01 EUR\"");
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
      StringFormat("BreakoutNY GER40 v1.0  |  FundingPips  |  Magic %d  |  Jose Yanez",
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
//  OnInit
//===================================================================

int OnInit()
{
   if(_Period != PERIOD_M5)
      { Alert("Ejecutar en M5"); return INIT_PARAMETERS_INCORRECT; }
   if(TP1_RR <= 0 || TP2_RR <= TP1_RR || TP3_RR <= TP2_RR)
      { Alert("TP1_RR < TP2_RR < TP3_RR deben ser crecientes."); return INIT_PARAMETERS_INCORRECT; }
   if(TP1_ClosePct < 0 || TP1_ClosePct > 60 || TP2_ClosePct < 0 || TP2_ClosePct > 60)
      { Alert("TP1/TP2_ClosePct deben estar entre 0 y 60."); return INIT_PARAMETERS_INCORRECT; }
   if(TP1_ClosePct + TP2_ClosePct >= 100)
      { Alert("TP1_ClosePct + TP2_ClosePct debe ser < 100."); return INIT_PARAMETERS_INCORRECT; }
   if(BE_BufferPct < 0 || BE_BufferPct > 200)
      { Alert("BE_BufferPct debe estar entre 0 y 200."); return INIT_PARAMETERS_INCORRECT; }
   if(MinSL_Points >= MaxSL_Points)
      { Alert("MinSL_Points debe ser < MaxSL_Points."); return INIT_PARAMETERS_INCORRECT; }

   trade.SetExpertMagicNumber(MagicNumber);
   InitCSV();

   // Diagnostico del simbolo
   double _tv  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double _ts  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double _cs  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double _pt  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double _mn  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double _mx  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double _vppCalc = (_tv > 0 && _ts > 0) ? _tv/_ts : _cs*_pt;
   bool   _vppFallbackActive = (_vppCalc <= 2.0);
   double _vpp = _vppFallbackActive ? VPP_Fallback : _vppCalc;
   string _met = _vppFallbackActive
      ? StringFormat("VPP FALLBACK (calculado=%.4f<=2.0, usando VPP_Fallback=%.4f)", _vppCalc, VPP_Fallback)
      : "ESTANDAR (TickValue/TickSize)";

   Print("=== BreakoutNY GER40 v1.0 — FundingPips ===");
   Print("--- SPECS DEL SIMBOLO: ", _Symbol, " ---");
   PrintFormat("  ContractSize    : %.2f", _cs);
   PrintFormat("  TickSize        : %.4f", _ts);
   PrintFormat("  TickValue       : %.4f EUR", _tv);
   PrintFormat("  Point           : %.4f", _pt);
   PrintFormat("  Digits          : %d", (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
   PrintFormat("  LotMin/Max/Step : %.2f / %.2f / %.2f", _mn, _mx,
               SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP));
   Print("  Metodo lotaje   : ", _met);
   PrintFormat("  VPP             : %.4f EUR/punto/lot", _vpp);
   Print("--- PARAMETROS ---");
   PrintFormat("  Riesgo          : $%.2f/trade", RiskAmountUSD);
   PrintFormat("  MinSL/MaxSL     : %.0f / %.0f pts GER40", MinSL_Points, MaxSL_Points);
   PrintFormat("  BE_BufferPct    : %.0f%%", BE_BufferPct);
   PrintFormat("  TP objetivos    : TP1=1:%.0f  TP2=1:%.0f  TP3=1:%.0f", TP1_RR, TP2_RR, TP3_RR);
   Print("  Direccion       : ", FilterShorts ? "Solo LONG (sesgo alcista DAX)" : "Long + Short");
   Print("  ConfirmOnClose  : ", ConfirmOnClose ? "SI" : "NO");
   PrintFormat("  Filtros dia     : L=%s M=%s X=%s J=%s V=%s",
               FilterMonday?"SI":"NO", FilterTuesday?"SI":"NO", FilterWednesday?"SI":"NO",
               FilterThursday?"SI":"NO", FilterFriday?"SI":"NO");
   PrintFormat("  Ventana entrada : 14:50 – 15:%02d UTC", EntryWindowEnd_Min);
   PrintFormat("  Cierre sesion   : %02d:%02d UTC", SessionCloseHour, SessionCloseMin);
   Print("  ATR Filter      : ", ATR_FilterEnable ? "ACTIVO" : "DESACTIVADO");
   // Conversión EUR→USD para tabla de diagnóstico
   string _profitCur  = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   string _accountCur = AccountInfoString(ACCOUNT_CURRENCY);
   double _convRate   = 1.0;
   if(_profitCur != _accountCur)
   {
      string _pairD = _profitCur + _accountCur;
      string _pairI = _accountCur + _profitCur;
      double _bidD  = SymbolInfoDouble(_pairD, SYMBOL_BID);
      double _bidI  = SymbolInfoDouble(_pairI, SYMBOL_BID);
      if(_bidD > 0)       { _convRate = _bidD;            PrintFormat("  FX conversión : %s = %.5f (%s)", _pairD, _bidD, _pairD); }
      else if(_bidI > 0)  { _convRate = 1.0 / _bidI;     PrintFormat("  FX conversión : 1/%s = %.5f (%s inverso)", _pairI, _convRate, _pairI); }
      else                { _convRate = EUR_USD_Fallback;  PrintFormat("  FX conversión : FALLBACK EUR_USD=%.5f (backtester)", EUR_USD_Fallback); }
   }
   double _vppUSD = _vpp * _convRate;
   PrintFormat("  VPP instrumento : %.4f %s/pt/lot", _vpp, _profitCur);
   PrintFormat("  VPP cuenta      : %.4f %s/pt/lot  (× %.5f)", _vppUSD, _accountCur, _convRate);

   Print("--- TABLA DE LOTES (referencia, VPP convertido a ", _accountCur, ") ---");
   double _ls = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int _slTests[] = {2700, 3700, 4500, 5321};
   for(int _ti = 0; _ti < 4; _ti++)
   {
      double _slT   = _slTests[_ti];
      double _lrT   = RiskAmountUSD / (_slT * _vppUSD);
      double _lnT   = MathMax(_mn, MathMin(_mx, MathFloor(_lrT/_ls)*_ls));
      double _riskT = _slT * _vppUSD * _lnT;
      double _tp1T  = _slT * TP1_RR * _vppUSD * _lnT;
      PrintFormat("  SL=%d pts: %.2f lots | Risk=$%.2f | TP1=$%.2f",
                  (int)_slT, _lnT, _riskT, _tp1T);
   }
   Print("==========================================");

   VisRedrawAll();
   VisDrawMottoPanel();

   return INIT_SUCCEEDED;
}

//===================================================================
//  OnDeinit
//===================================================================

void OnDeinit(const int reason)
{
   if(csvHandle != INVALID_HANDLE) FileClose(csvHandle);
   double pf = (stat_grossLoss != 0)
               ? stat_grossProfit / MathAbs(stat_grossLoss) : 0;
   Print("=== RESUMEN GER40 ===  Total:", stat_total,
         "  W:", stat_wins, "  L:", stat_losses,
         "  PF:", DoubleToString(pf, 3),
         "  Net: $", DoubleToString(stat_grossProfit + stat_grossLoss, 2));
   VisPurgeAll();
   ChartRedraw();
}

//===================================================================
//  OnTester
//===================================================================

double OnTester()
{
   return (stat_grossLoss != 0)
          ? stat_grossProfit / MathAbs(stat_grossLoss) : 0;
}

//===================================================================
//  OnTradeTransaction — CSV y visual al cerrar posicion
//===================================================================

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

   if(HasOpenPosition()) return;

   string exitType = "session";
   if(StringFind(comment,"tp") >= 0 || StringFind(comment,"TP") >= 0) exitType = "tp3";
   else if(StringFind(comment,"sl") >= 0 || StringFind(comment,"SL") >= 0)
      exitType = phase1Done ? "sl_be" : "sl";

   log_BE_Activated = phase1Done;
   if(PositionSelectByTicket(activeTicket))
      log_SL_Final = PositionGetDouble(POSITION_SL);
   else
      log_SL_Final = originalSL;

   stat_total++;
   WriteTradeRow(TimeToString(closeTime, TIME_DATE|TIME_MINUTES),
                 exitType, closePrice, profit,
                 dayFiltered, rangeFiltered);
   if(profit > 0) { stat_wins++;   stat_grossProfit += profit; }
   else           { stat_losses++; stat_grossLoss   += profit; }

   if(VIS_Enable && vis_dayTag != "")
   {
      color  clrClose = (exitType=="tp3")   ? VIS_ColTP3  :
                        (exitType=="sl_be") ? VIS_ColBE   :
                        (exitType=="sl")    ? VIS_ColSL   : VIS_ColEntry;
      string lbl      = (exitType=="tp3")   ? "TP3 OK"    :
                        (exitType=="sl_be") ? "SL@BE"     :
                        (exitType=="sl")    ? "SL"        :
                        IntegerToString(SessionCloseHour) + ":" +
                        StringFormat("%02d", SessionCloseMin);
      datetime tEnd = closeTime + (datetime)(6 * PeriodSeconds(PERIOD_M5));
      VisLevel(VIS_PFX+"CLS_"+vis_dayTag, closeTime, tEnd, closePrice,
               clrClose, STYLE_SOLID, 2, lbl);
      ChartRedraw();
   }

   tradeDir = ""; entryPrice = 0; activeTicket = 0;
}

//===================================================================
//  OnTick — logica principal
//===================================================================

void OnTick()
{
   int utcH, utcM;
   GetCurrentUTC(utcH, utcM);

   MqlDateTime sdt; TimeToStruct(TimeCurrent(), sdt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",
                                 sdt.year, sdt.mon, sdt.day));

   //=== RESET DIARIO ==================================================
   if(today != lastTradeDay)
   {
      DailyReset();
      lastTradeDay = today;
      vis_dayTag   = VisMakeDayTag();
      VisRedrawAll();
      VisDrawMottoPanel();
   }

   if(dayFiltered) return;

   //=== FILTRO: DIA DE SEMANA =========================================
   if(!rangeCalculated && !dayFiltered && !tradeExecuted &&
      utcH == 14 && utcM >= 50)
   {
      if(!IsTradingDayAllowed())
      {
         dayFiltered = true; tradeExecuted = true;
         Print("DIA FILTRADO: ", WeekdayName(GetWeekdayUTC()));
         WriteFilteredRow("day");
         VisUpdatePanel("", 0, 0, false, true, "Dia no operado");
         return;
      }
   }

   //=== PASO 1: CALCULAR RANGO (14:50 UTC) ============================
   if(!rangeCalculated && !tradeExecuted && utcH == 14 && utcM >= 50)
   {
      double h35,l35, h40,l40, h45,l45;
      bool ok = GetCandleAtUTC(14,35,h35,l35) &&
                GetCandleAtUTC(14,40,h40,l40) &&
                GetCandleAtUTC(14,45,h45,l45);
      if(!ok) { Print("AVISO: Velas del rango no encontradas."); return; }

      rangeHigh  = MathMax(h35, MathMax(h40, h45));
      rangeLow   = MathMin(l35, MathMin(l40, l45));
      slDistance = rangeHigh - rangeLow;   // en unidades de precio GER40
      double slPts = slDistance / _Point;  // en puntos del broker (= puntos GER40 para digits=2)

      // Filtro ATR
      if(ATR_FilterEnable)
      {
         int atrHandle = iATR(_Symbol, PERIOD_M5, ATR_Period);
         if(atrHandle != INVALID_HANDLE)
         {
            double atrNow[1];
            CopyBuffer(atrHandle, 0, 1, 1, atrNow);
            double currentATR = atrNow[0] / _Point;

            int barsBaseline = ATR_BaselineDays * 24 * 12;
            double atrBuf[]; ArrayResize(atrBuf, barsBaseline);
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
                  PrintFormat("ATR FILTRADO: actual=%.1f pts | base=%.1f | rango=[%.1f-%.1f]",
                              currentATR, baselineATR, atrMin, atrMax);
                  WriteFilteredRow("atr");
                  VisUpdatePanel("", 0, 0, false, true, "ATR filtrado");
                  return;
               }
               else
                  PrintFormat("ATR OK: actual=%.1f | base=%.1f | rango=[%.1f-%.1f]",
                              currentATR, baselineATR, atrMin, atrMax);
            }
         }
      }

      // Filtro de rango — en puntos GER40 (equivalente a slPts para digits=2)
      bool tooSmall = (MinSL_Points > 0 && slPts < MinSL_Points);
      bool tooLarge = (MaxSL_Points > 0 && slPts > MaxSL_Points);

      if(tooSmall || tooLarge)
      {
         rangeFiltered = true; tradeExecuted = true;
         log_SL_Pts  = slPts; log_Weekday = WeekdayName(GetWeekdayUTC());
         PrintFormat("RANGO FILTRADO: %.0f pts | Filtro: %.0f-%.0f pts",
                     slPts, MinSL_Points, MaxSL_Points);
         WriteFilteredRow("range");
         VisUpdatePanel("", 0, 0, false, true,
            "Rango filtrado (" + DoubleToString(slPts,0) + " pts)");
         return;
      }

      rangeCalculated = true;
      log_RangeHigh   = rangeHigh; log_RangeLow = rangeLow;
      cachedLots = CalculateLotSize(slDistance);

      PrintFormat("Rango OK: H=%.2f L=%.2f SL=%.0f pts | Lots=%.2f | ConfirmOnClose=%s | FilterShorts=%s",
                  rangeHigh, rangeLow, slPts,
                  cachedLots, ConfirmOnClose?"SI":"NO", FilterShorts?"SI":"NO");
      VisRedrawToday();
   }

   //=== PASO 2: BUSCAR ENTRADA =========================================
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
      datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);

      //--- FASE A: deteccion de ruptura ---------------------------------
      if(inWindow && !HasOpenPosition() && !breakoutPending)
      {
         bool bullBreak = (ask > rangeHigh);
         bool bearBreak = (bid < rangeLow) && !FilterShorts;

         if(bullBreak)
         {
            if(!ConfirmOnClose)
            {
               double sl = NormalizeDouble(ask - slDistance, _Digits);
               double tp = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
               if(trade.Buy(cachedLots, _Symbol, ask, sl, tp, "BreakoutNY GER40 BUY"))
               {
                  tradeExecuted = true;
                  entryPrice = ask; originalSL = sl;
                  originalLots = cachedLots; tradeDir = "buy";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(ask + slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(ask + slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(ask + slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts   = slDistance / _Point; log_ConfirmUsed = false;
                  PrintFormat(">>> BUY Entry=%.2f SL=%.2f BE=%.2f TP1=%.2f TP3=%.2f Lots=%.2f",
                              ask, sl, bePrice, tp1Price, tp3Price, cachedLots);
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
            else
            {
               breakoutPending = true;
               pendingDir      = "buy";
               pendingBarTime  = currentBarTime;
               PrintFormat(">>> BUY pendiente | vela=%s | ask=%.2f rH=%.2f",
                           TimeToString(currentBarTime, TIME_DATE|TIME_MINUTES), ask, rangeHigh);
            }
         }
         else if(bearBreak)
         {
            if(!ConfirmOnClose)
            {
               double sl = NormalizeDouble(bid + slDistance, _Digits);
               double tp = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
               if(trade.Sell(cachedLots, _Symbol, bid, sl, tp, "BreakoutNY GER40 SELL"))
               {
                  tradeExecuted = true;
                  entryPrice = bid; originalSL = sl;
                  originalLots = cachedLots; tradeDir = "sell";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(bid - slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(bid - slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(bid - slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts   = slDistance / _Point; log_ConfirmUsed = false;
                  PrintFormat(">>> SELL Entry=%.2f SL=%.2f BE=%.2f TP1=%.2f TP3=%.2f Lots=%.2f",
                              bid, sl, bePrice, tp1Price, tp3Price, cachedLots);
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
            else
            {
               breakoutPending = true;
               pendingDir      = "sell";
               pendingBarTime  = currentBarTime;
               PrintFormat(">>> SELL pendiente | vela=%s | bid=%.2f rL=%.2f",
                           TimeToString(currentBarTime, TIME_DATE|TIME_MINUTES), bid, rangeLow);
            }
         }
      }

      //--- FASE B: confirmacion al cierre de vela -----------------------
      if(breakoutPending && !tradeExecuted && !HasOpenPosition() &&
         currentBarTime > pendingBarTime)
      {
         bool stillValid = false;
         if(pendingDir == "buy"  && ask > rangeHigh) stillValid = true;
         if(pendingDir == "sell" && bid < rangeLow)  stillValid = true;

         if(!stillValid)
         {
            PrintFormat(">>> Breakout CANCELADO: vela revirtio al rango. Dir=%s ask=%.2f bid=%.2f",
                        pendingDir, ask, bid);
            breakoutPending = false; pendingDir = ""; pendingBarTime = 0;
         }
         else
         {
            if(pendingDir == "buy")
            {
               double sl = NormalizeDouble(ask - slDistance, _Digits);
               double tp = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
               if(trade.Buy(cachedLots, _Symbol, ask, sl, tp, "BreakoutNY GER40 BUY"))
               {
                  tradeExecuted = true; breakoutPending = false;
                  entryPrice = ask; originalSL = sl;
                  originalLots = cachedLots; tradeDir = "buy";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(ask + slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(ask + slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(ask + slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(ask + slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts   = slDistance / _Point; log_ConfirmUsed = true;
                  PrintFormat(">>> BUY CONFIRMADO Entry=%.2f SL=%.2f BE=%.2f TP1=%.2f TP3=%.2f Lots=%.2f",
                              ask, sl, bePrice, tp1Price, tp3Price, cachedLots);
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
            else
            {
               double sl = NormalizeDouble(bid + slDistance, _Digits);
               double tp = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
               if(trade.Sell(cachedLots, _Symbol, bid, sl, tp, "BreakoutNY GER40 SELL"))
               {
                  tradeExecuted = true; breakoutPending = false;
                  entryPrice = bid; originalSL = sl;
                  originalLots = cachedLots; tradeDir = "sell";
                  activeTicket = trade.ResultOrder();
                  tp1Price = NormalizeDouble(bid - slDistance * TP1_RR, _Digits);
                  tp2Price = NormalizeDouble(bid - slDistance * TP2_RR, _Digits);
                  tp3Price = NormalizeDouble(bid - slDistance * TP3_RR, _Digits);
                  bePrice  = NormalizeDouble(bid - slDistance * (BE_BufferPct/100.0), _Digits);
                  log_OpenTime = TimeCurrent(); log_Weekday = WeekdayName(GetWeekdayUTC());
                  log_SL_Pts   = slDistance / _Point; log_ConfirmUsed = true;
                  PrintFormat(">>> SELL CONFIRMADO Entry=%.2f SL=%.2f BE=%.2f TP1=%.2f TP3=%.2f Lots=%.2f",
                              bid, sl, bePrice, tp1Price, tp3Price, cachedLots);
                  vis_hasTrade = true; VisRedrawToday();
               }
            }
         }
      }

      // Ventana cerrada sin entrada
      if(!inWindow && !HasOpenPosition() && !breakoutPending && !tradeExecuted)
      {
         tradeExecuted = true;
         Print("Ventana cerrada sin breakout.");
         VisRedrawToday();
      }
      if(!inWindow && breakoutPending && !tradeExecuted)
      {
         Print("Ventana cerrada con breakout pendiente sin confirmar. Dir=", pendingDir);
         breakoutPending = false; tradeExecuted = true;
         VisRedrawToday();
      }
   }

   //=== PASO 3: GESTION BE + PARCIALES ================================
   if(tradeExecuted && HasOpenPosition() && entryPrice > 0)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // Fase 1: TP1 → cierre parcial + activar BE
      if(!phase1Done)
      {
         bool tp1Hit = (tradeDir=="buy"  && bid >= tp1Price) ||
                       (tradeDir=="sell" && ask <= tp1Price);
         if(tp1Hit)
         {
            phase1Done = true; log_Phase1Hit = true;
            if(EnablePartials && TP1_ClosePct > 0)
            {
               double toClose = NormalizeLots(originalLots * TP1_ClosePct / 100.0);
               if(toClose >= GetPositionLots()) toClose = 0;
               if(toClose > 0)
               {
                  ulong tk = GetPositionTicket();
                  if(ClosePartial(tk, toClose))
                     Print("FASE 1: Cerrado ", toClose, " lotes en TP1");
               }
            }
            if(ModifySL(bePrice))
            {
               Print("FASE 1: BE activado → SL=", DoubleToString(bePrice,2));
               if(VIS_Enable && vis_dayTag != "")
                  VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, bePrice);
            }
         }
      }

      // Fase 2: TP2 → cierre parcial + SL sube a TP1
      if(phase1Done && !phase2Done)
      {
         bool tp2Hit = (tradeDir=="buy"  && bid >= tp2Price) ||
                       (tradeDir=="sell" && ask <= tp2Price);
         if(tp2Hit)
         {
            phase2Done = true; log_Phase2Hit = true;
            if(EnablePartials && TP2_ClosePct > 0)
            {
               double curLots  = GetPositionLots();
               double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
               double toClose  = NormalizeLots(originalLots * TP2_ClosePct / 100.0);
               if(curLots - toClose < minLot)
                  toClose = NormalizeLots(curLots - minLot);
               if(toClose >= minLot)
               {
                  ulong tk = GetPositionTicket();
                  if(ClosePartial(tk, toClose))
                     Print("FASE 2: Cerrado ", toClose, " lotes en TP2");
               }
            }
            if(ModifySL(tp1Price))
            {
               Print("FASE 2: SL → TP1=", DoubleToString(tp1Price,2));
               if(VIS_Enable && vis_dayTag != "")
                  VisMoveLevel(VIS_PFX+"SL_"+vis_dayTag, tp1Price);
            }
         }
      }
   }

   //=== PASO 4: CIERRE FINAL DE SESION ================================
   bool pastCloseTime;
   if(SessionCloseMin == 0)
      pastCloseTime = (utcH >= SessionCloseHour);
   else
      pastCloseTime = (utcH > SessionCloseHour) ||
                      (utcH == SessionCloseHour && utcM >= SessionCloseMin);

   if(pastCloseTime && HasOpenPosition())
   {
      PrintFormat("Fin de sesion (%02d:%02d UTC) — cerrando posicion.", SessionCloseHour, SessionCloseMin);
      CloseAll();
   }

   //=== PANEL VISUAL EN TIEMPO REAL ===================================
   if(VIS_Enable && VIS_ShowLabel)
   {
      double floatPL = 0;
      if(HasOpenPosition() && activeTicket > 0 && PositionSelectByTicket(activeTicket))
         floatPL = PositionGetDouble(POSITION_PROFIT);
      VisUpdatePanel(tradeDir, slDistance / _Point, floatPL,
                     HasOpenPosition(), false, "");
   }
}
//+------------------------------------------------------------------+
