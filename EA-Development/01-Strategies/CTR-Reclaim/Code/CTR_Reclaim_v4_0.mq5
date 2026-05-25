//+------------------------------------------------------------------+
//|  CTR Reclaim EA v4.0                                             |
//|  Liquidity Sweep Reversal — NDX100 M10 — Multi-Activo            |
//|                                                                  |
//|  CAMBIOS vs v3.7:                                                |
//|                                                                  |
//|  [NUEVO] TP y SL dinámicos basados en el rango de la key candle  |
//|                                                                  |
//|    SL = RangoKeyCandle × MultiplSL                               |
//|    TP = RangoKeyCandle × MultiplTP                               |
//|                                                                  |
//|    El RR es constante por construcción: MultiplTP / MultiplSL    |
//|    Los niveles se adaptan a la volatilidad real del día.         |
//|    Días con key candle estrecha se filtran con RangoMinimoPoints. |
//|                                                                  |
//|  [NUEVO] Parámetros renombrados completamente al español         |
//|  [NUEVO] Filtro RangoMinimoPoints — no operar si el rango        |
//|          de la key candle es demasiado pequeño                   |
//|  [NUEVO] Filtro RangoMaximoPoints — no operar si el rango        |
//|          es anormalmente grande (gap, news spike)                |
//|  [NUEVO] MagicNumber default 4000                                |
//|                                                                  |
//|  FÓRMULA DE RIESGO (sin cambios vs v3.7):                        |
//|    Lots = RiesgoUSD / (SL_precio × CalcValorPorPunto())          |
//|    NDX100 FP: $20/punto/lot verificado empíricamente             |
//|    SL_precio = RangoKeyCandle × MultiplSL                        |
//|                                                                  |
//|  CONFIGURACIÓN PARA EL BACKTEST:                                 |
//|  - Símbolo: NDX100, TF: M10                                      |
//|  - Período IS:  2021.01.01 — 2023.12.31                          |
//|  - Período OOS: 2024.01.01 — 2025.12.31                          |
//|  - Capital: $10,000 | Apalancamiento: 1:20 (FundingPips)         |
//+------------------------------------------------------------------+
#property copyright "CTR Reclaim v4.0"
#property version   "4.00"
#property strict

#include <Trade\Trade.mqh>

//──────────────────────────────────────────────
// ENUMS
//──────────────────────────────────────────────
enum ENUM_DIRECCION
{
   AMBAS  = 0,   // Ambas direcciones
   SOLO_LONG  = 1,   // Solo compras
   SOLO_SHORT = 2    // Solo ventas
};

//──────────────────────────────────────────────
// INPUTS
//──────────────────────────────────────────────

input group "=== GESTIÓN DE RIESGO ==="
// Fórmula: Lotes = RiesgoUSD / (SL_precio × ValorPorPunto)
// ValorPorPunto se calcula automáticamente desde datos del broker:
//   Método 1: TickValue / TickSize  (broker reporta datos correctos)
//   Método 2: ContractSize          (fallback si TickValue=0, ej. FP NDX100)
// No requiere configuración manual — funciona con cualquier activo.
input double   RiesgoUSD            = 50.0;   // Riesgo fijo en USD por operación

input group "=== PROTECCIÓN (Prop Firm) ==="
input bool     ActivarLimitePerdidaDiaria = true;
input double   LimitePerdidaDiariaUSD     = 500.0;   // 5% de $10k
input bool     ActivarMaxDD               = true;
input double   MaxDDDesdeInicialUSD       = 1000.0;  // 10% de $10k

input group "=== TRADE ==="
input int            NumeroMagico        = 4000;   // Número mágico del EA
input int            MaxOperacionesDia   = 1;      // Máximo de operaciones por día
input int            MaxSpreadPuntos     = 300;    // Spread máximo permitido en puntos
input int            SlippagePuntos      = 10;     // Slippage máximo en puntos
input ENUM_DIRECCION TipoDireccion       = AMBAS;  // Dirección permitida

input group "=== KEY CANDLE — TIMING ==="
input int   HoraNY       = 8;    // Hora de apertura de la key candle (hora NY)
input int   MinutoNY     = 30;   // Minuto de apertura de la key candle (hora NY)
// OffsetGMT eliminado — se calcula dinámicamente via TimeCurrent()-TimeGMT() (fix DST)

input group "=== TP/SL DINÁMICO — RANGO KEY CANDLE ==="
// TP = RangoKeyCandle × MultiplTP  |  SL = RangoKeyCandle × MultiplSL
// RR implícito = MultiplTP / MultiplSL (constante por construcción)
// Ejemplo con MultiplSL=0.30 y MultiplTP=0.90:
//   Key candle de 100 puntos → SL=30pts, TP=90pts → RR=1:3.0
//   Key candle de 150 puntos → SL=45pts, TP=135pts → RR=1:3.0 (siempre)
input double MultiplSL          = 0.30;    // Multiplicador SL sobre rango key candle
input double MultiplTP          = 0.90;    // Multiplicador TP sobre rango key candle
input double RangoMinimoPoints  = 50.0;   // Rango mínimo key candle en precio (NDX100=50, XAUUSD=5)
input double RangoMaximoPoints  = 500.0;  // Rango máximo key candle en precio (NDX100=500, XAUUSD=50)

input group "=== SEÑAL — VENTANA DE BARRAS ==="
// WindowMinBar=3: validado en OOS — barras 1-2 tienen WR < breakeven
// WindowMaxBar=8: zona óptima confirmada en WFA
input int   VentanaBarraMin     = 3;   // Barra mínima post-key candle [estructural=3]
input int   VentanaBarraMax     = 8;   // Barra máxima post-key candle

input group "=== DÍAS DE TRADING ==="
input bool   OperarDomingo    = false;  // Operar domingo
input bool   OperarLunes      = false;  // Operar lunes  [OFF — PF=0.516 OOS]
input bool   OperarMartes     = true;   // Operar martes
input bool   OperarMiercoles  = true;   // Operar miércoles
input bool   OperarJueves     = true;   // Operar jueves
input bool   OperarViernes    = true;   // Operar viernes
input bool   OperarSabado     = false;  // Operar sábado

input group "=== BREAKEVEN ==="
input bool   ActivarBreakeven      = false;  // Activar breakeven
// Trigger como fracción del TP dinámico: 0.50 = mover SL cuando precio recorre 50% del TP
input double BE_FraccionTP         = 0.50;   // Fracción del TP para activar BE (0.0-1.0)
input int    BE_OffsetPuntos       = 2;      // Puntos de colchón sobre entrada al mover SL

input group "=== DISPLAY ==="
input bool   MostrarDashboard  = true;
input bool   DibujarNiveles    = true;
input bool   ModoDebug         = true;
input bool   ExportarCSV       = true;

//──────────────────────────────────────────────
// ESTADO GLOBAL
//──────────────────────────────────────────────
CTrade   m_trade;

datetime g_tiempoKeyCandle  = 0;
double   g_highKeyCandle    = 0;
double   g_lowKeyCandle     = 0;
double   g_rangoKeyCandle   = 0;   // en puntos (precio)

// SL/TP calculados al detectar la key candle del día
double   g_slPuntos         = 0;
double   g_tpPuntos         = 0;

bool     g_señalActiva      = false;
int      g_dirSeñal         = 0;    // 1=BUY, -1=SELL
datetime g_tiempoBarraSeñal = 0;
double   g_sweepOpen=0, g_sweepHigh=0, g_sweepLow=0, g_sweepClose=0;
int      g_barrasDesdeKey   = 0;

// Estadísticas por barra (diagnóstico)
int      g_bskCount[13];
int      g_bskWins[13];

datetime g_ultimoDiaBarTiempo = 0;
int      g_operacionesHoy     = 0;
double   g_pnlDiario          = 0;
bool     g_bloqueadoDiario    = false;

int      g_totalOperaciones   = 0;
int      g_totalGanadas       = 0;
int      g_totalPerdidas      = 0;
double   g_gananciaBruta      = 0;
double   g_perdidaBruta       = 0;
double   g_pnlAcumulado       = 0;
double   g_balanceInicial     = 0;
double   g_equityPico         = 0;
double   g_maxDD              = 0;

datetime g_tiempoApertura     = 0;
double   g_precioApertura     = 0;
double   g_lotesApertura      = 0;
int      g_bskApertura        = 0;

// g_horaServidor / g_minutoServidor eliminados — se calculan dinámicamente en BuscarKeyCandle()

ENUM_ORDER_TYPE_FILLING g_modoFill;

string   g_csvFile            = "";
int      g_csvHandle          = INVALID_HANDLE;
string   g_resFile            = "";

// Diagnóstico de flujo
int      g_filtradosPorMinBar    = 0;
int      g_filtradosPorSpread    = 0;
int      g_filtradosPorRangoMin  = 0;
int      g_filtradosPorRangoMax  = 0;
int      g_keyCandles            = 0;
int      g_sweepsDetectados      = 0;
int      g_señalesActivadas      = 0;
int      g_intentosTrading       = 0;
int      g_fallosTrading         = 0;

string   OBJ_PREFIX = "CTR40_";

//──────────────────────────────────────────────
// INIT
//──────────────────────────────────────────────
int OnInit()
{
   int tfMin = PeriodSeconds(_Period) / 60;
   if(tfMin < 1) tfMin = 1;

   // Validaciones
   if(VentanaBarraMin > VentanaBarraMax)
   {
      Alert("[CTR4.0] VentanaBarraMin > VentanaBarraMax. Corregir parámetros.");
      return INIT_FAILED;
   }
   if(MultiplSL <= 0 || MultiplTP <= 0)
   {
      Alert("[CTR4.0] MultiplSL y MultiplTP deben ser > 0.");
      return INIT_FAILED;
   }
   if(MultiplTP <= MultiplSL)
      PrintFormat("[CTR4.0] AVISO: MultiplTP (%.2f) <= MultiplSL (%.2f) — RR < 1:1",
                  MultiplTP, MultiplSL);

   // Fill mode
   long ff = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((ff & SYMBOL_FILLING_IOC) != 0)       g_modoFill = ORDER_FILLING_IOC;
   else if((ff & SYMBOL_FILLING_FOK) != 0)   g_modoFill = ORDER_FILLING_FOK;
   else                                       g_modoFill = ORDER_FILLING_RETURN;

   m_trade.SetExpertMagicNumber(NumeroMagico);
   m_trade.SetDeviationInPoints(SlippagePuntos);
   m_trade.SetTypeFilling(g_modoFill);

   g_balanceInicial = AccountInfoDouble(ACCOUNT_BALANCE);
   g_equityPico     = AccountInfoDouble(ACCOUNT_EQUITY);

   ArrayInitialize(g_bskCount, 0);
   ArrayInitialize(g_bskWins,  0);

   double rr = MultiplTP / MultiplSL;
   double beWR = 100.0 / (1.0 + rr);

   Print("╔══════════════════════════════════════════════╗");
   PrintFormat("║  CTR Reclaim v4.0 — %s M%d", _Symbol, tfMin);
   Print(     "║  TP/SL dinámico basado en rango de key candle");
   PrintFormat("║  MultiplSL=%.2f | MultiplTP=%.2f | RR implícito=1:%.2f",
               MultiplSL, MultiplTP, rr);
   PrintFormat("║  RangoMin=%.1f pts | RangoMax=%.1f pts",
               RangoMinimoPoints, RangoMaximoPoints);
   PrintFormat("║  BE WR mínima=%.1f%% | RiesgoUSD=$%.2f | VPP=$%.2f (auto)",
               beWR, RiesgoUSD, CalcValorPorPunto());
   Print(     "║  ─────────────────────────────────────────");
   PrintFormat("║  Key candle: NY %02d:%02d | Offset calculado dinámicamente (fix DST)",
               HoraNY, MinutoNY);
   PrintFormat("║  Ventana: barras [%d, %d] | Lunes=%s | BE=%s",
               VentanaBarraMin, VentanaBarraMax,
               OperarLunes?"ON":"OFF", ActivarBreakeven?"ON":"OFF");
   PrintFormat("║  Días: %s%s%s%s%s",
               OperarLunes?"Lun ":"", OperarMartes?"Mar ":"",
               OperarMiercoles?"Mie ":"", OperarJueves?"Jue ":"",
               OperarViernes?"Vie":"");
   Print("╚══════════════════════════════════════════════╝");

   if(ExportarCSV)
   {
      g_csvFile = "CTR_v40_" + _Symbol + "_M" + IntegerToString(tfMin) +
                  "_" + IntegerToString(NumeroMagico) + ".csv";
      g_resFile = "CTR_v40_RESUMEN_" + _Symbol + "_" +
                  IntegerToString(NumeroMagico) + ".csv";

      g_csvHandle = FileOpen(g_csvFile,
                             FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ',');
      if(g_csvHandle != INVALID_HANDLE)
      {
         FileWriteString(g_csvHandle,
            "NumOp,FechaAbre,HoraAbre,FechaCierre,HoraCierre,DiaSemana,Direccion,"
            "KeyHigh,KeyLow,RangoPuntos,SL_puntos,TP_puntos,RR,"
            "SweepOpen,SweepHigh,SweepLow,SweepClose,BarrasDesdeKey,"
            "Entrada,SL_precio,TP_precio,Lotes,RiesgoReal,GananciaMaxima,Spread_pts,"
            "Profit,Resultado,DuracionMin,"
            "Balance,PnLAcumulado,DD_USD,WinRate_pct,PF\n");
         FileFlush(g_csvHandle);
         PrintFormat("[CTR4.0] CSV trades: MQL5\\Files\\Common\\%s", g_csvFile);
      }
      else
         PrintFormat("[CTR4.0] Advertencia: no se pudo abrir CSV. Error=%d", GetLastError());
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
   static datetime ultimaBarra = 0;
   datetime barrActual = iTime(_Symbol, _Period, 0);
   bool esNuevaBarra = (barrActual != ultimaBarra);
   if(esNuevaBarra) ultimaBarra = barrActual;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > g_equityPico) g_equityPico = eq;
   double dd = g_equityPico - eq;
   if(dd > g_maxDD) g_maxDD = dd;

   VerificarResetDiario(barrActual);
   VerificarProtecciones();

   if(esNuevaBarra)
   {
      BuscarKeyCandle();
      if(g_tiempoKeyCandle > 0 && !g_señalActiva) BuscarSweep();
      if(g_señalActiva && !g_bloqueadoDiario &&
         g_operacionesHoy < MaxOperacionesDia && EsDiaDeTrading())
         EjecutarSeñal();
   }

   if(ActivarBreakeven) GestionarBreakeven();
   if(MostrarDashboard)  ActualizarDashboard();
}

//──────────────────────────────────────────────
// RESET DIARIO
//──────────────────────────────────────────────
void VerificarResetDiario(datetime barrActual)
{
   MqlDateTime dt; TimeToStruct(barrActual, dt);
   datetime sello = StringToTime(StringFormat("%04d.%02d.%02d 00:00",
                                  dt.year, dt.mon, dt.day));
   if(sello == g_ultimoDiaBarTiempo) return;

   if(ModoDebug && g_ultimoDiaBarTiempo > 0)
      PrintFormat("[CTR4.0] Nuevo día | ops=%d | PnL=$%.2f | acum=$%.2f | DD=$%.2f",
                  g_operacionesHoy, g_pnlDiario, g_pnlAcumulado,
                  g_balanceInicial - AccountInfoDouble(ACCOUNT_EQUITY));

   g_ultimoDiaBarTiempo = sello;
   g_operacionesHoy     = 0;
   g_pnlDiario          = 0;
   g_bloqueadoDiario    = false;
   g_señalActiva        = false;
   g_dirSeñal           = 0;

   if(DibujarNiveles)
   {
      string nm = OBJ_PREFIX + "DL_" + IntegerToString((int)barrActual);
      if(ObjectFind(0, nm) < 0)
      {
         ObjectCreate(0, nm, OBJ_VLINE, 0, barrActual, 0);
         ObjectSetInteger(0, nm, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(0, nm, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, nm, OBJPROP_BACK,  true);
      }
   }
}

//──────────────────────────────────────────────
// PROTECCIONES
//──────────────────────────────────────────────
void VerificarProtecciones()
{
   if(g_bloqueadoDiario) return;

   if(ActivarLimitePerdidaDiaria && g_pnlDiario <= -MathAbs(LimitePerdidaDiariaUSD))
   {
      g_bloqueadoDiario = true;
      PrintFormat("[CTR4.0] Límite pérdida diaria alcanzado: $%.2f (límite $%.2f)",
                  g_pnlDiario, LimitePerdidaDiariaUSD);
      return;
   }
   if(ActivarMaxDD)
   {
      double ddAhora = g_balanceInicial - AccountInfoDouble(ACCOUNT_EQUITY);
      if(ddAhora >= MathAbs(MaxDDDesdeInicialUSD))
      {
         g_bloqueadoDiario = true;
         PrintFormat("[CTR4.0] Max DD desde inicial alcanzado: $%.2f (límite $%.2f)",
                     ddAhora, MaxDDDesdeInicialUSD);
      }
   }
}

//──────────────────────────────────────────────
// BUSCAR KEY CANDLE
// Hereda fix de data gap de v3.0 (sin todayStart)
// NUEVO v4.0: calcula g_slPuntos y g_tpPuntos en puntos de precio
//             y aplica filtros de rango mínimo/máximo
//──────────────────────────────────────────────
void BuscarKeyCandle()
{
   int total = Bars(_Symbol, _Period);
   if(total < 2) return;

   // Fix DST: calcular hora servidor dinámicamente en cada llamada.
   // TimeCurrent() es hora servidor; TimeGMT() es UTC real.
   // La diferencia da el offset real del broker en este momento,
   // compensando automáticamente cambios de verano/invierno de NY y del broker.
   int offsetBroker  = (int)((TimeCurrent() - TimeGMT()) / 3600);
   int tfMin         = PeriodSeconds(_Period) / 60;
   if(tfMin < 1) tfMin = 1;
   // NY es UTC-4 (verano EDT) o UTC-5 (invierno EST)
   // hora_servidor = HoraNY + abs(UTC_NY) + offsetBroker
   // Durante EDT (NY=UTC-4): hora_servidor = HoraNY + 4 + offsetBroker
   // Durante EST (NY=UTC-5): hora_servidor = HoraNY + 5 + offsetBroker
   // MqlDateTime del tiempo de barra ya está en hora servidor → comparamos directo
   // Calculamos qué hora servidor corresponde a HoraNY en este momento
   datetime ahoraGMT    = TimeGMT();
   datetime ahoraNY     = ahoraGMT - 4 * 3600;   // EDT base (se ajusta abajo)
   MqlDateTime dtGMT; TimeToStruct(ahoraGMT, dtGMT);
   // DST americano: segundo domingo de marzo al primer domingo de noviembre
   bool esDST_NY = (dtGMT.mon > 3 && dtGMT.mon < 11) ||
                   (dtGMT.mon == 3  && dtGMT.day >= 8  && dtGMT.day_of_week == 0 && dtGMT.hour >= 7) ||
                   (dtGMT.mon == 11 && dtGMT.day <= 7  && dtGMT.day_of_week == 0 && dtGMT.hour <  6);
   int offsetNY     = esDST_NY ? -4 : -5;   // UTC-4 verano, UTC-5 invierno
   int horaServidor = (HoraNY - offsetNY + offsetBroker) % 24;
   int minutoServidor = (MinutoNY / tfMin) * tfMin;

   for(int i = 1; i < MathMin(total, 500); i++)
   {
      datetime bt = iTime(_Symbol, _Period, i);
      if(bt == 0) continue;
      if(g_tiempoKeyCandle > 0 && bt <= g_tiempoKeyCandle) break;

      MqlDateTime dt; TimeToStruct(bt, dt);
      if(dt.hour != horaServidor || dt.min != minutoServidor) continue;
      if(!EsDiaDeTradingDT(dt)) break;

      double kHigh       = iHigh(_Symbol, _Period, i);
      double kLow        = iLow (_Symbol, _Period, i);
      double rangoPrecio = kHigh - kLow;         // en precio absoluto
      double rangoPoints = rangoPrecio / _Point; // en ticks (para log)

      // Filtro rango mínimo — RangoMinimoPoints en precio absoluto
      // NDX100 FP (_Point=0.01): rango típico 50–300 → default 50.0
      // XAUUSD   (_Point=0.01): rango típico  5– 40 → usar 5.0
      if(rangoPrecio < RangoMinimoPoints)
      {
         g_filtradosPorRangoMin++;
         if(ModoDebug)
            PrintFormat("[CTR4.0] Key candle RECHAZADA rango=%.1f pts < mínimo=%.1f pts | %s",
                        rangoPoints, RangoMinimoPoints,
                        TimeToString(bt, TIME_DATE|TIME_MINUTES));
         break;
      }

      // Filtro rango máximo — gaps o spikes de noticias (mismo precio absoluto)
      if(rangoPrecio > RangoMaximoPoints)
      {
         g_filtradosPorRangoMax++;
         if(ModoDebug)
            PrintFormat("[CTR4.0] Key candle RECHAZADA rango=%.1f pts > máximo=%.1f pts | %s",
                        rangoPoints, RangoMaximoPoints,
                        TimeToString(bt, TIME_DATE|TIME_MINUTES));
         break;
      }

      g_tiempoKeyCandle  = bt;
      g_highKeyCandle    = kHigh;
      g_lowKeyCandle     = kLow;
      g_rangoKeyCandle   = rangoPrecio;   // en precio (para GetLotes y EjecutarSeñal)

      // Calcular SL y TP dinámicos como fracción del rango
      g_slPuntos = g_rangoKeyCandle * MultiplSL;
      g_tpPuntos = g_rangoKeyCandle * MultiplTP;

      double rrReal = MultiplTP / MultiplSL;
      double beWR   = 100.0 / (1.0 + rrReal);

      if(ModoDebug)
         PrintFormat("[CTR4.0] Key candle: %s H=%.2f L=%.2f Rango=%.1fpts | SL=%.1fpts TP=%.1fpts RR=1:%.2f BE=%.1f%%",
                     TimeToString(bt, TIME_DATE|TIME_MINUTES),
                     g_highKeyCandle, g_lowKeyCandle, rangoPoints,
                     g_slPuntos / _Point, g_tpPuntos / _Point, rrReal, beWR);

      if(DibujarNiveles)
      {
         DrawHLine(OBJ_PREFIX+"KH_"+IntegerToString((int)bt),
                   g_highKeyCandle, clrDodgerBlue, STYLE_DASH);
         DrawHLine(OBJ_PREFIX+"KL_"+IntegerToString((int)bt),
                   g_lowKeyCandle,  clrOrangeRed,  STYLE_DASH);
      }

      g_señalActiva = false;
      g_dirSeñal    = 0;
      g_keyCandles++;
      break;
   }
}

//──────────────────────────────────────────────
// BUSCAR SWEEP
// Misma lógica estructural que v3.7
// Solo acepta señales en barras [VentanaBarraMin, VentanaBarraMax]
//──────────────────────────────────────────────
void BuscarSweep()
{
   if(g_tiempoKeyCandle == 0) return;

   // Localizar key candle (loop manual — evita iBarShift)
   int kcBarra = -1;
   int total   = Bars(_Symbol, _Period);
   for(int i = 0; i < total; i++)
      if(iTime(_Symbol, _Period, i) == g_tiempoKeyCandle) { kcBarra = i; break; }
   if(kcBarra < 0) return;

   int sbIdx = 1;
   int bsk   = kcBarra - sbIdx;

   if(bsk < VentanaBarraMin || bsk > VentanaBarraMax)
   {
      if(bsk > 0 && bsk < VentanaBarraMin && ModoDebug)
      {
         double sH = iHigh(_Symbol, _Period, sbIdx);
         double sL = iLow (_Symbol, _Period, sbIdx);
         double sC = iClose(_Symbol, _Period, sbIdx);
         bool habriaTrade = (sL < g_lowKeyCandle && sC > g_lowKeyCandle) ||
                            (sH > g_highKeyCandle && sC < g_highKeyCandle);
         if(habriaTrade)
         {
            g_filtradosPorMinBar++;
            PrintFormat("[CTR4.0] Señal en barra %d filtrada por VentanaBarraMin=%d (total: %d)",
                        bsk, VentanaBarraMin, g_filtradosPorMinBar);
         }
      }
      return;
   }

   datetime sbTiempo = iTime(_Symbol, _Period, sbIdx);
   if(sbTiempo == g_tiempoBarraSeñal) return;

   double sO = iOpen (_Symbol, _Period, sbIdx);
   double sH = iHigh (_Symbol, _Period, sbIdx);
   double sL = iLow  (_Symbol, _Period, sbIdx);
   double sC = iClose(_Symbol, _Period, sbIdx);

   bool bull = (sL < g_lowKeyCandle  && sC > g_lowKeyCandle  && TipoDireccion != SOLO_SHORT);
   bool bear = (sH > g_highKeyCandle && sC < g_highKeyCandle && TipoDireccion != SOLO_LONG);
   if(!bull && !bear) return;

   g_señalActiva       = true;
   g_dirSeñal          = bull ? 1 : -1;
   g_tiempoBarraSeñal  = sbTiempo;
   g_sweepsDetectados++;
   g_señalesActivadas++;
   g_sweepOpen  = sO; g_sweepHigh = sH;
   g_sweepLow   = sL; g_sweepClose = sC;
   g_barrasDesdeKey = bsk;

   PrintFormat("[CTR4.0] SEÑAL %s | %s | barra=%d/%d | SL=%.1fpts TP=%.1fpts RR=1:%.2f",
               g_dirSeñal > 0 ? "COMPRA" : "VENTA",
               TimeToString(sbTiempo, TIME_DATE|TIME_MINUTES),
               bsk, VentanaBarraMax,
               g_slPuntos / _Point, g_tpPuntos / _Point,
               MultiplTP / MultiplSL);
}

//──────────────────────────────────────────────
// EJECUTAR SEÑAL
//──────────────────────────────────────────────
void EjecutarSeñal()
{
   if(!g_señalActiva) return;
   g_intentosTrading++;

   long sp = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(sp > MaxSpreadPuntos)
   {
      if(ModoDebug)
         PrintFormat("[CTR4.0] Spread=%d > %d — señal descartada", (int)sp, MaxSpreadPuntos);
      g_filtradosPorSpread++;
      g_señalActiva = false;
      return;
   }

   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entrada, slPrecio, tpPrecio;

   if(g_dirSeñal > 0)
   {
      entrada  = ask;
      slPrecio = NormalizeDouble(entrada - g_slPuntos, _Digits);
      tpPrecio = NormalizeDouble(entrada + g_tpPuntos, _Digits);
   }
   else
   {
      entrada  = bid;
      slPrecio = NormalizeDouble(entrada + g_slPuntos, _Digits);
      tpPrecio = NormalizeDouble(entrada - g_tpPuntos, _Digits);
   }

   double lotes    = GetLotes();
   double riesgoR  = lotes * g_slPuntos * CalcValorPorPunto();
   double ganMaxR  = lotes * g_tpPuntos * CalcValorPorPunto();

   bool ok = g_dirSeñal > 0
             ? m_trade.Buy (lotes, _Symbol, entrada, slPrecio, tpPrecio, "CTR40_BUY")
             : m_trade.Sell(lotes, _Symbol, entrada, slPrecio, tpPrecio, "CTR40_SELL");

   if(ok)
   {
      g_operacionesHoy++; g_totalOperaciones++;
      g_señalActiva    = false;
      g_tiempoApertura = iTime(_Symbol, _Period, 0);
      g_precioApertura = entrada;
      g_lotesApertura  = lotes;
      g_bskApertura    = g_barrasDesdeKey;

      if(g_barrasDesdeKey >= 0 && g_barrasDesdeKey <= 12)
         g_bskCount[g_barrasDesdeKey]++;

      PrintFormat("[CTR4.0] ✓ #%d %s | lotes=%.2f | barra=%d | entrada=%.2f | SL=%.2f | TP=%.2f | riesgo=$%.2f | RR=1:%.2f",
                  g_totalOperaciones, g_dirSeñal > 0 ? "COMPRA" : "VENTA",
                  lotes, g_barrasDesdeKey, entrada, slPrecio, tpPrecio,
                  riesgoR, MultiplTP / MultiplSL);

      if(DibujarNiveles)
      {
         DrawHLine(OBJ_PREFIX+"E_"+IntegerToString((int)g_tiempoApertura),
                   entrada, g_dirSeñal > 0 ? clrLime : clrRed, STYLE_SOLID);
         DrawHLine(OBJ_PREFIX+"T_"+IntegerToString((int)g_tiempoApertura),
                   tpPrecio, clrGold, STYLE_DOT);
         DrawHLine(OBJ_PREFIX+"S_"+IntegerToString((int)g_tiempoApertura),
                   slPrecio, clrOrangeRed, STYLE_DOT);
      }

      if(ExportarCSV && g_csvHandle != INVALID_HANDLE)
      {
         MqlDateTime dt; TimeToStruct(g_tiempoApertura, dt);
         string dias[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
         string fila = StringFormat(
            "%d,%s,%s,,,,%s,%.5f,%.5f,%.1f,%.4f,%.4f,%.2f,"
            "%.5f,%.5f,%.5f,%.5f,%d,"
            "%.5f,%.5f,%.5f,%.2f,%.2f,%.2f,%d,"
            ",ABIERTA,,%.2f,%.2f,%.2f,,\n",
            g_totalOperaciones,
            TimeToString(g_tiempoApertura, TIME_DATE),
            TimeToString(g_tiempoApertura, TIME_MINUTES),
            dias[dt.day_of_week],
            g_highKeyCandle, g_lowKeyCandle, g_rangoKeyCandle / _Point,
            g_slPuntos / _Point, g_tpPuntos / _Point, MultiplTP / MultiplSL,
            g_sweepOpen, g_sweepHigh, g_sweepLow, g_sweepClose,
            g_barrasDesdeKey,
            entrada, slPrecio, tpPrecio, lotes, riesgoR, ganMaxR, (int)sp,
            AccountInfoDouble(ACCOUNT_BALANCE),
            g_pnlAcumulado,
            g_balanceInicial - AccountInfoDouble(ACCOUNT_EQUITY));
         FileWriteString(g_csvHandle, fila);
         FileFlush(g_csvHandle);
      }
   }
   else
   {
      PrintFormat("[CTR4.0] Trade fallido: %d %s",
                  m_trade.ResultRetcode(), m_trade.ResultComment());
      g_fallosTrading++;
      g_señalActiva = false;
   }
}

//──────────────────────────────────────────────
// CALC VALOR POR PUNTO
// Mismo sistema que BreakoutNY — automático, sin input manual.
// Retorna USD por lote por 1 punto de precio.
// Método 1: tv/ts  (broker correcto)
// Método 2: ContractSize (fallback para brokers CFD que reportan TickValue=0)
//──────────────────────────────────────────────
double CalcValorPorPunto()
{
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double cs = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   if(tv > 0 && ts > 0)
      return tv / ts;

   if(cs > 0)
   {
      PrintFormat("[CTR4.0] TickValue=0 — usando ContractSize=%.2f como VPP", cs);
      return cs;
   }

   Print("[CTR4.0] ERROR CalcValorPorPunto: sin datos de broker. Retorna 0.");
   return 0;
}

//──────────────────────────────────────────────
// GET LOTES
// Fórmula: Lotes = RiesgoUSD / (SL_precio × ValorPorPunto)
//
// SL_precio = g_slPuntos (precio absoluto, ej NDX100: 15.0 puntos)
// ValorPorPunto = calculado automáticamente desde datos del broker
//
// Ejemplo NDX100 FP: VPP=$20, SL=15pts, Riesgo=$50
//   Lotes = 50 / (15 × 20) = 0.1666 → 0.16 lots
//   Riesgo real = 0.16 × 15 × 20 = $48 ✓
//──────────────────────────────────────────────
double GetLotes()
{
   if(g_slPuntos <= 0)
   {
      Print("[CTR4.0] ERROR GetLotes: g_slPuntos = 0");
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   }

   double vpp   = CalcValorPorPunto();
   if(vpp <= 0)
   {
      Print("[CTR4.0] ERROR GetLotes: ValorPorPunto = 0. Usando lote mínimo.");
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   }

   double vMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vStep <= 0) vStep = 0.01;

   // Paso 1 — lotes por riesgo
   double lotesRaw = RiesgoUSD / (g_slPuntos * vpp);
   double lotes    = MathFloor(lotesRaw / vStep) * vStep;
   lotes           = MathMax(vMin, MathMin(vMax, lotes));

   // Paso 2 — cap por margen real del broker
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double margenPorLot = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, ask, margenPorLot) || margenPorLot <= 0)
   {
      // Fallback margen: precio × ContractSize / apalancamiento
      double cs = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      double lv = (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
      if(cs > 0 && lv > 0) margenPorLot = (ask * cs) / lv;
   }

   if(margenPorLot > 0)
   {
      double margenLibre  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      double maxPorMargen = MathFloor((margenLibre * 0.90) / margenPorLot / vStep) * vStep;
      maxPorMargen        = MathMax(vMin, MathMin(vMax, maxPorMargen));

      if(lotes > maxPorMargen)
      {
         PrintFormat("[CTR4.0] Cap margen: objetivo=%.4f → reducido a %.4f lotes "
                     "(libre=$%.0f, margen/lot=$%.0f)",
                     lotes, maxPorMargen, margenLibre, margenPorLot);
         lotes = maxPorMargen;
      }
   }

   PrintFormat("[CTR4.0] Lotes: VPP=$%.2f | SL=%.4f pts | objetivo=%.4f → final=%.4f | riesgo=$%.2f | win=$%.2f",
               vpp, g_slPuntos, lotesRaw, lotes,
               lotes * g_slPuntos * vpp,
               lotes * g_tpPuntos * vpp);

   return lotes;
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
   if(HistoryDealGetInteger(dT, DEAL_MAGIC)  != NumeroMagico) return;
   if(HistoryDealGetString (dT, DEAL_SYMBOL) != _Symbol)      return;

   ENUM_DEAL_ENTRY de = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dT, DEAL_ENTRY);
   if(de != DEAL_ENTRY_OUT && de != DEAL_ENTRY_OUT_BY) return;

   double profit = HistoryDealGetDouble(dT, DEAL_PROFIT)
                 + HistoryDealGetDouble(dT, DEAL_SWAP)
                 + HistoryDealGetDouble(dT, DEAL_COMMISSION);

   g_pnlDiario    += profit;
   g_pnlAcumulado += profit;
   if(profit > 0) { g_totalGanadas++;   g_gananciaBruta += profit; }
   else           { g_totalPerdidas++;  g_perdidaBruta  += profit; }

   if(g_bskApertura >= 0 && g_bskApertura <= 12 && profit > 0)
      g_bskWins[g_bskApertura]++;

   double wr  = g_totalOperaciones > 0 ? 100.0 * g_totalGanadas  / g_totalOperaciones : 0;
   double pf  = g_perdidaBruta     != 0 ? MathAbs(g_gananciaBruta / g_perdidaBruta) : 0;
   string res2 = profit > 0 ? "GANADA" : (profit < 0 ? "PERDIDA" : "BE");

   datetime tiempoCierre = (datetime)HistoryDealGetInteger(dT, DEAL_TIME);
   int duracionMin = g_tiempoApertura > 0 ? (int)((tiempoCierre - g_tiempoApertura) / 60) : 0;
   double ddAhora  = g_balanceInicial - AccountInfoDouble(ACCOUNT_EQUITY);

   PrintFormat("[CTR4.0] %s | P/L=$%.2f | barra=%d | RR=1:%.2f | WR=%.1f%% | PF=%.3f | acum=$%.2f | DD=$%.2f",
               res2, profit, g_bskApertura, MultiplTP / MultiplSL,
               wr, pf, g_pnlAcumulado, ddAhora);

   if(ExportarCSV && g_csvHandle != INVALID_HANDLE)
   {
      MqlDateTime dtC; TimeToStruct(tiempoCierre, dtC);
      string dias[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
      double riesgoR = g_lotesApertura * g_slPuntos * CalcValorPorPunto();
      double ganMaxR = g_lotesApertura * g_tpPuntos * CalcValorPorPunto();

      string fila = StringFormat(
         "%d,%s,%s,%s,%s,%s,%s,%.5f,%.5f,%.1f,%.4f,%.4f,%.2f,"
         "%.5f,%.5f,%.5f,%.5f,%d,"
         "%.5f,,,%.2f,%.2f,%.2f,,"
         "%.2f,%s,%d,%.2f,%.2f,%.2f,%.1f,%.3f\n",
         g_totalOperaciones,
         TimeToString(g_tiempoApertura, TIME_DATE),
         TimeToString(g_tiempoApertura, TIME_MINUTES),
         TimeToString(tiempoCierre,     TIME_DATE),
         TimeToString(tiempoCierre,     TIME_MINUTES),
         dias[dtC.day_of_week], res2,
         g_highKeyCandle, g_lowKeyCandle, g_rangoKeyCandle / _Point,
         g_slPuntos / _Point, g_tpPuntos / _Point, MultiplTP / MultiplSL,
         g_sweepOpen, g_sweepHigh, g_sweepLow, g_sweepClose, g_bskApertura,
         g_precioApertura, g_lotesApertura, riesgoR, ganMaxR,
         profit, res2, duracionMin,
         AccountInfoDouble(ACCOUNT_BALANCE),
         g_pnlAcumulado, ddAhora, wr, pf);
      FileWriteString(g_csvHandle, fila);
      FileFlush(g_csvHandle);
   }
}

//──────────────────────────────────────────────
// OnTester — resumen y análisis BSK
//──────────────────────────────────────────────
double OnTester()
{
   double wr  = g_totalOperaciones > 0 ? 100.0 * g_totalGanadas / g_totalOperaciones : 0;
   double pf  = g_perdidaBruta     != 0 ? MathAbs(g_gananciaBruta / g_perdidaBruta) : 0;
   double rr  = MultiplTP / MultiplSL;
   double beW = 100.0 / (1.0 + rr);

   if(g_csvHandle != INVALID_HANDLE)
   { FileClose(g_csvHandle); g_csvHandle = INVALID_HANDLE; }

   if(!ExportarCSV) return pf;

   int fh = FileOpen(g_resFile, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ',');
   if(fh == INVALID_HANDLE)
   {
      PrintFormat("[CTR4.0] No se pudo crear resumen. Error=%d", GetLastError());
      return pf;
   }

   double lotes    = GetLotes();
   double riesgoR  = lotes * g_slPuntos * CalcValorPorPunto();
   double ganMaxR  = lotes * g_tpPuntos * CalcValorPorPunto();

   FileWriteString(fh, "CTR Reclaim v4.0 — Resumen Backtest\n");
   FileWriteString(fh, StringFormat("Simbolo,%s\n",                     _Symbol));
   FileWriteString(fh, StringFormat("Balance inicial,$%.2f\n",           g_balanceInicial));
   FileWriteString(fh, StringFormat("Balance final,$%.2f\n",             g_balanceInicial + g_pnlAcumulado));
   FileWriteString(fh, StringFormat("Profit neto,$%.2f\n",               g_pnlAcumulado));
   FileWriteString(fh, StringFormat("Total operaciones,%d\n",            g_totalOperaciones));
   FileWriteString(fh, StringFormat("Ganadas,%d\n",                      g_totalGanadas));
   FileWriteString(fh, StringFormat("Perdidas,%d\n",                     g_totalPerdidas));
   FileWriteString(fh, StringFormat("Win Rate,%.2f%%\n",                 wr));
   FileWriteString(fh, StringFormat("Profit Factor,%.4f\n",              pf));
   FileWriteString(fh, StringFormat("Ganancia bruta,$%.2f\n",            g_gananciaBruta));
   FileWriteString(fh, StringFormat("Perdida bruta,$%.2f\n",             g_perdidaBruta));
   FileWriteString(fh, StringFormat("Max DD,$%.2f\n",                    g_maxDD));
   FileWriteString(fh, StringFormat("RR implícito,1:%.2f\n",             rr));
   FileWriteString(fh, StringFormat("BE Win Rate,%.2f%%\n",              beW));
   FileWriteString(fh, StringFormat("Edge WR-BE,%.2f%%\n",               wr - beW));
   FileWriteString(fh, StringFormat("MultiplSL,%.2f\n",                  MultiplSL));
   FileWriteString(fh, StringFormat("MultiplTP,%.2f\n",                  MultiplTP));
   FileWriteString(fh, StringFormat("RangoMinimoPoints,%.1f\n",          RangoMinimoPoints));
   FileWriteString(fh, StringFormat("RangoMaximoPoints,%.1f\n",          RangoMaximoPoints));
   FileWriteString(fh, StringFormat("RiesgoUSD,$%.2f\n",                 RiesgoUSD));
   FileWriteString(fh, StringFormat("ValorPorPunto,$%.2f (auto)\n",      CalcValorPorPunto()));
   FileWriteString(fh, StringFormat("VentanaBarraMin,%d\n",              VentanaBarraMin));
   FileWriteString(fh, StringFormat("VentanaBarraMax,%d\n",              VentanaBarraMax));
   FileWriteString(fh, StringFormat("OperarLunes,%s\n",                  OperarLunes?"si":"no"));
   FileWriteString(fh, StringFormat("ActivarBreakeven,%s\n",             ActivarBreakeven?"si":"no"));
   FileWriteString(fh, StringFormat("BE_FraccionTP,%.2f\n",              BE_FraccionTP));
   FileWriteString(fh, StringFormat("MaxSpreadPuntos,%d\n",              MaxSpreadPuntos));
   FileWriteString(fh, StringFormat("FiltradosPorVentanaMin,%d\n",       g_filtradosPorMinBar));
   FileWriteString(fh, StringFormat("FiltradosPorSpread,%d\n",           g_filtradosPorSpread));
   FileWriteString(fh, StringFormat("FiltradosPorRangoMin,%d\n",         g_filtradosPorRangoMin));
   FileWriteString(fh, StringFormat("FiltradosPorRangoMax,%d\n",         g_filtradosPorRangoMax));
   FileWriteString(fh, StringFormat("KeyCandlesEncontradas,%d\n",        g_keyCandles));
   FileWriteString(fh, StringFormat("SweepsDetectados,%d\n",             g_sweepsDetectados));
   FileWriteString(fh, StringFormat("SeñalesActivadas,%d\n",             g_señalesActivadas));
   FileWriteString(fh, StringFormat("IntentosTrading,%d\n",              g_intentosTrading));
   FileWriteString(fh, StringFormat("FallosTrading,%d\n",                g_fallosTrading));
   FileWriteString(fh, "\n");

   FileWriteString(fh, "=== ANÁLISIS BARRAS DESDE KEY ===\n");
   FileWriteString(fh, "Barra,Operaciones,Ganadas,WR_pct,WR_minima\n");
   for(int b = 1; b <= 12; b++)
   {
      if(g_bskCount[b] == 0) continue;
      double bWR  = 100.0 * g_bskWins[b] / g_bskCount[b];
      string flag = bWR > beW + 5.0 ? " FUERTE" : (bWR < beW ? " DEBIL" : "");
      FileWriteString(fh, StringFormat("Barra %d,%d,%d,%.1f%%,%.1f%%%s\n",
                                       b, g_bskCount[b], g_bskWins[b], bWR, beW, flag));
   }
   FileWriteString(fh, "\n");
   FileWriteString(fh, StringFormat("=== TRADES ===\nVer archivo: %s\n", g_csvFile));
   FileClose(fh);

   Print("╔══════════════════════════════════════════════╗");
   PrintFormat("║  BACKTEST FINALIZADO — CTR v4.0 — %s", _Symbol);
   PrintFormat("║  Operaciones: %d | WR: %.1f%% [BE=%.1f%%] | Edge: %+.1f%%",
               g_totalOperaciones, wr, beW, wr - beW);
   PrintFormat("║  PF: %.4f | Neto: $%.2f | MaxDD: $%.2f",
               pf, g_pnlAcumulado, g_maxDD);
   PrintFormat("║  MultiplSL=%.2f | MultiplTP=%.2f | RR=1:%.2f",
               MultiplSL, MultiplTP, rr);
   PrintFormat("║  DIAGNÓSTICO: Keys=%d | Sweeps=%d | Señales=%d | Intentos=%d | Fallos=%d",
               g_keyCandles, g_sweepsDetectados, g_señalesActivadas,
               g_intentosTrading, g_fallosTrading);
   PrintFormat("║  Filtrados VentaMin=%d: %d | Spread: %d | RangoMin: %d | RangoMax: %d",
               VentanaBarraMin, g_filtradosPorMinBar, g_filtradosPorSpread,
               g_filtradosPorRangoMin, g_filtradosPorRangoMax);
   Print(     "║  Análisis por barra:");
   for(int b = 1; b <= 12; b++)
   {
      if(g_bskCount[b] == 0) continue;
      double bWR = 100.0 * g_bskWins[b] / g_bskCount[b];
      PrintFormat("║    Barra %d: %d ops | WR=%.1f%% | Edge=%+.1f%%",
                  b, g_bskCount[b], bWR, bWR - beW);
   }
   Print("╚══════════════════════════════════════════════╝");

   return pf;
}

//──────────────────────────────────────────────
// BREAKEVEN DINÁMICO
// Trigger = fracción configurable del TP dinámico del día
//──────────────────────────────────────────────
void GestionarBreakeven()
{
   if(g_tpPuntos <= 0) return;

   double triggerPrecio = g_tpPuntos * BE_FraccionTP;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != NumeroMagico) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)      continue;

      double op = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double cp = PositionGetDouble(POSITION_PRICE_CURRENT);
      long   pt = PositionGetInteger(POSITION_TYPE);

      if(pt == POSITION_TYPE_BUY)
      {
         double objetivo = op + triggerPrecio;
         double nuevoSL  = op + BE_OffsetPuntos * _Point;
         if(cp >= objetivo && sl < nuevoSL - _Point)
         {
            m_trade.PositionModify(ticket, nuevoSL, PositionGetDouble(POSITION_TP));
            PrintFormat("[CTR4.0] BE COMPRA #%I64u → SL=%.2f (trigger=%.1f%%TP)",
                        ticket, nuevoSL, BE_FraccionTP * 100);
         }
      }
      else if(pt == POSITION_TYPE_SELL)
      {
         double objetivo = op - triggerPrecio;
         double nuevoSL  = op - BE_OffsetPuntos * _Point;
         if(cp <= objetivo && (sl > nuevoSL + _Point || sl == 0))
         {
            m_trade.PositionModify(ticket, nuevoSL, PositionGetDouble(POSITION_TP));
            PrintFormat("[CTR4.0] BE VENTA #%I64u → SL=%.2f (trigger=%.1f%%TP)",
                        ticket, nuevoSL, BE_FraccionTP * 100);
         }
      }
   }
}

//──────────────────────────────────────────────
// DASHBOARD
//──────────────────────────────────────────────
void ActualizarDashboard()
{
   double wr   = g_totalOperaciones > 0 ? 100.0 * g_totalGanadas / g_totalOperaciones : 0;
   double pf   = g_perdidaBruta     != 0 ? MathAbs(g_gananciaBruta / g_perdidaBruta) : 0;
   double rr   = MultiplTP / MultiplSL;
   double beWR = 100.0 / (1.0 + rr);
   long   sp   = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double ddAhora = g_balanceInicial - AccountInfoDouble(ACCOUNT_EQUITY);

   string estado = g_bloqueadoDiario ? "BLOQUEADO" :
                   (g_señalActiva ? (g_dirSeñal > 0 ? "SENAL COMPRA" : "SENAL VENTA") :
                   (g_tiempoKeyCandle > 0 ? "KEY CANDLE SET" : "ESPERANDO"));

   double lotes   = GetLotes();
   double riesgoR = lotes * g_slPuntos * CalcValorPorPunto();
   double ganMaxR = lotes * g_tpPuntos * CalcValorPorPunto();

   string beStr = ActivarBreakeven
                  ? StringFormat("BE ON (%.0f%% TP)", BE_FraccionTP * 100)
                  : "BE OFF";

   Comment(StringFormat(
      "CTR Reclaim v4.0 — %s\n"
      "Estado: %s\n"
      "Key: NY %02d:%02d (DST auto)  |  Ventana barras: [%d, %d]\n"
      "Rango hoy: %.1f pts  |  SL=%.1fpts  TP=%.1fpts  RR=1:%.2f  %s\n"
      "Riesgo=$%.2f → Lotes=%.2f | P.máxima=$%.2f\n"
      "Spread: %d/%d pts | Ops hoy: %d/%d\n"
      "Sesión: %d ops | WR=%.1f%% [BE=%.1f%%] | PF=%.3f\n"
      "PnL día: $%.2f | Total: $%.2f\n"
      "DD: $%.2f | MaxDD: $%.2f\n"
      "Filtros — VentaMin: %d | Spread: %d | RangoMin: %d | RangoMax: %d",
      _Symbol,
      estado,
      HoraNY, MinutoNY, VentanaBarraMin, VentanaBarraMax,
      g_rangoKeyCandle / _Point, g_slPuntos / _Point, g_tpPuntos / _Point, rr, beStr,
      RiesgoUSD, lotes, ganMaxR,
      (int)sp, MaxSpreadPuntos, g_operacionesHoy, MaxOperacionesDia,
      g_totalOperaciones, wr, beWR, pf,
      g_pnlDiario, g_pnlAcumulado,
      ddAhora, g_maxDD,
      g_filtradosPorMinBar, g_filtradosPorSpread,
      g_filtradosPorRangoMin, g_filtradosPorRangoMax
   ));
}

//──────────────────────────────────────────────
// HELPERS
//──────────────────────────────────────────────
bool EsDiaDeTrading()
{
   MqlDateTime dt; TimeToStruct(iTime(_Symbol, _Period, 0), dt);
   return EsDiaDeTradingDT(dt);
}
bool EsDiaDeTradingDT(MqlDateTime &dt)
{
   switch(dt.day_of_week)
   {
      case 0: return OperarDomingo;
      case 1: return OperarLunes;
      case 2: return OperarMartes;
      case 3: return OperarMiercoles;
      case 4: return OperarJueves;
      case 5: return OperarViernes;
      case 6: return OperarSabado;
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
