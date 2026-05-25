//+------------------------------------------------------------------+
//|   BreakoutNY_Calibrador_GER40.mq5                                |
//|   Calibrador de Rangos NY — GER40 — FundingPips                  |
//|                                                                   |
//|   PROPÓSITO:                                                      |
//|   Analiza los últimos N años de datos M5 del GER40 y             |
//|   calcula la distribución estadística del rango de las 3 velas   |
//|   14:35 / 14:40 / 14:45 UTC (rango de apertura NY).             |
//|                                                                   |
//|   GER40 SPECS (FundingPips):                                      |
//|   Dígitos: 2 | TickSize: 0.01 | TickValue: 0.01 EUR              |
//|   VPP: 1.0 EUR/punto/lote | Volumen mín: 0.01                    |
//|   El rango se mide en PUNTOS (no pips) — 1 punto = 0.01          |
//|                                                                   |
//|   OUTPUT:                                                         |
//|   1. Log en Journal con percentiles y estadísticas por día        |
//|   2. CSV: BreakoutNY_Calibracion_GER40.csv (en MQL5\Files\)      |
//|                                                                   |
//|   USO:                                                            |
//|   1. Compilar y ejecutar como Script en gráfico GER40 M5          |
//|   2. Revisar Journal: buscar "RESULTADO FINAL"                    |
//|   3. Usar P25 como MinSL_Points y P75 como MaxSL_Points en el EA |
//+------------------------------------------------------------------+
#property copyright "BreakoutNY Calibrador GER40 v1.0"
#property version   "1.00"
#property script_show_inputs

//==================================================================
// INPUTS
//==================================================================
input int    ServerOffsetHours = 2;       // UTC+2 = FundingPips
input int    YearsToAnalyze    = 5;       // Años hacia atrás (mínimo 3)
input double MinSL_Test        = 30.0;    // Puntos mínimos de referencia (baseline)
input double MaxSL_Test        = 150.0;   // Puntos máximos de referencia (baseline)
input bool   ExportCSV         = true;    // Exportar CSV día a día
input bool   ShowDayStats      = true;    // Estadísticas por día de semana

//==================================================================
// Auxiliares
//==================================================================
double Percentile(double &arr[], double pct)
{
   int n = ArraySize(arr);
   if(n == 0) return 0;
   int idx = (int)MathFloor((n - 1) * pct / 100.0);
   idx = MathMax(0, MathMin(idx, n - 1));
   return arr[idx];
}

double Mean(double &arr[])
{
   int n = ArraySize(arr);
   if(n == 0) return 0;
   double s = 0;
   for(int i = 0; i < n; i++) s += arr[i];
   return s / n;
}

//==================================================================
// OnStart
//==================================================================
void OnStart()
{
   // ── Specs del símbolo ─────────────────────────────────────────
   int    digits    = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);    // 0.01
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   // VPP = EUR por punto por lote
   double vpp = (tickSize > 0) ? tickValue / tickSize : 0.0;

   Print("╔══════════════════════════════════════════════════════╗");
   Print("║  BreakoutNY Calibrador NY Range — GER40 v1.0        ║");
   Print("╚══════════════════════════════════════════════════════╝");
   Print("  Símbolo      : ", _Symbol);
   Print("  Dígitos      : ", digits);
   Print("  Point size   : ", DoubleToString(pointSize, 4));
   Print("  TickValue    : ", DoubleToString(tickValue, 4));
   Print("  TickSize     : ", DoubleToString(tickSize,  4));
   Print("  VPP (EUR/pt) : ", DoubleToString(vpp, 4), " EUR/punto/lote");
   Print("  ServerOffset : UTC+", ServerOffsetHours);
   Print("  NOTA: Rango medido en PUNTOS (digits=2, 1 pt = 0.01)");

   // ── Ventana temporal ─────────────────────────────────────────
   datetime endTime   = TimeCurrent();
   datetime startTime = endTime - (datetime)(YearsToAnalyze * 365 * 24 * 3600);
   Print("  Desde : ", TimeToString(startTime));
   Print("  Hasta : ", TimeToString(endTime));

   // ── Cargar datos M5 ──────────────────────────────────────────
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   int copied = CopyRates(_Symbol, PERIOD_M5, startTime, endTime, rates);
   if(copied < 100) {
      Print("ERROR: Solo ", copied, " barras. Descarga el histórico M5 completo.");
      return;
   }
   Print("Barras M5 cargadas: ", copied);

   // ── Arrays globales ───────────────────────────────────────────
   double allRanges[];
   string allDates[];
   int    allWeekdays[];
   ArrayResize(allRanges,   0);
   ArrayResize(allDates,    0);
   ArrayResize(allWeekdays, 0);

   // Arrays por día de semana
   double dayRanges1[]; // Lunes
   double dayRanges2[]; // Martes
   double dayRanges3[]; // Miércoles
   double dayRanges4[]; // Jueves
   double dayRanges5[]; // Viernes
   ArrayResize(dayRanges1, 0);
   ArrayResize(dayRanges2, 0);
   ArrayResize(dayRanges3, 0);
   ArrayResize(dayRanges4, 0);
   ArrayResize(dayRanges5, 0);

   // ── Hora objetivo (14:45 UTC → +ServerOffset en servidor) ─────
   int targetHour = 14 + ServerOffsetHours;  // 16 para UTC+2
   int targetMin  = 45;

   string lastDate  = "";
   int    processed = 0;
   int    skipped   = 0;

   // ── Recolectar rangos ─────────────────────────────────────────
   for(int i = 2; i < copied - 1; i++)
   {
      MqlDateTime barDT;
      TimeToStruct(rates[i].time, barDT);

      if(barDT.hour != targetHour || barDT.min != targetMin) continue;

      string thisDate = StringFormat("%04d.%02d.%02d",
                                     barDT.year, barDT.mon, barDT.day);
      if(thisDate == lastDate) continue;
      lastDate = thisDate;

      if(barDT.day_of_week == 0 || barDT.day_of_week == 6) continue;

      // Verificar que las 3 velas son del mismo día
      MqlDateTime dt1, dt2;
      TimeToStruct(rates[i-1].time, dt1);
      TimeToStruct(rates[i-2].time, dt2);
      if(dt1.day != barDT.day || dt1.mon != barDT.mon ||
         dt2.day != barDT.day || dt2.mon != barDT.mon)
      { skipped++; continue; }

      // Rango en puntos (High-Low de las 3 velas / point)
      double hi = MathMax(rates[i].high,  MathMax(rates[i-1].high,  rates[i-2].high));
      double lo = MathMin(rates[i].low,   MathMin(rates[i-1].low,   rates[i-2].low));
      double rp = (hi - lo) / pointSize;

      // Filtro: descartar rangos inválidos o extremos (>2000 pts = >20 puntos precio)
      if(rp <= 0.0 || rp > 20000.0) { skipped++; continue; }

      int n = ArraySize(allRanges);
      ArrayResize(allRanges,   n + 1);
      ArrayResize(allDates,    n + 1);
      ArrayResize(allWeekdays, n + 1);
      allRanges[n]   = rp;
      allDates[n]    = thisDate;
      allWeekdays[n] = barDT.day_of_week;

      int dow = barDT.day_of_week;
      if(dow == 1) { int nd = ArraySize(dayRanges1); ArrayResize(dayRanges1, nd+1); dayRanges1[nd] = rp; }
      if(dow == 2) { int nd = ArraySize(dayRanges2); ArrayResize(dayRanges2, nd+1); dayRanges2[nd] = rp; }
      if(dow == 3) { int nd = ArraySize(dayRanges3); ArrayResize(dayRanges3, nd+1); dayRanges3[nd] = rp; }
      if(dow == 4) { int nd = ArraySize(dayRanges4); ArrayResize(dayRanges4, nd+1); dayRanges4[nd] = rp; }
      if(dow == 5) { int nd = ArraySize(dayRanges5); ArrayResize(dayRanges5, nd+1); dayRanges5[nd] = rp; }

      processed++;
   }

   int totalDays = ArraySize(allRanges);
   if(totalDays < 10) {
      Print("ERROR: Solo ", totalDays, " días válidos. Verifica el histórico M5 del GER40.");
      return;
   }
   Print("Días procesados : ", processed);
   Print("Días omitidos   : ", skipped);

   // ── Percentiles ───────────────────────────────────────────────
   ArraySort(allRanges);

   double p5   = Percentile(allRanges,  5);
   double p10  = Percentile(allRanges, 10);
   double p20  = Percentile(allRanges, 20);
   double p25  = Percentile(allRanges, 25);
   double p30  = Percentile(allRanges, 30);
   double p40  = Percentile(allRanges, 40);
   double p50  = Percentile(allRanges, 50);
   double p60  = Percentile(allRanges, 60);
   double p70  = Percentile(allRanges, 70);
   double p75  = Percentile(allRanges, 75);
   double p80  = Percentile(allRanges, 80);
   double p90  = Percentile(allRanges, 90);
   double p95  = Percentile(allRanges, 95);
   double pMax = allRanges[totalDays - 1];
   double pMin = allRanges[0];
   double media = Mean(allRanges);

   double varSum = 0;
   for(int i = 0; i < totalDays; i++) varSum += MathPow(allRanges[i] - media, 2);
   double stdDev = MathSqrt(varSum / totalDays);

   int inRange = 0;
   for(int i = 0; i < totalDays; i++)
      if(allRanges[i] >= MinSL_Test && allRanges[i] <= MaxSL_Test) inRange++;
   double pctInRange = 100.0 * inRange / totalDays;

   // ── Output ────────────────────────────────────────────────────
   Print("╔══════════════════════════════════════════════════════╗");
   Print("║   RESULTADO FINAL — DISTRIBUCIÓN DE RANGOS NY       ║");
   Print("║   GER40 | ", YearsToAnalyze, " años | n=", totalDays, " días               ║");
   Print("╚══════════════════════════════════════════════════════╝");
   Print("── Estadísticas globales (en PUNTOS) ────────────────────");
   Print("  n (días válidos)  : ", totalDays);
   Print("  Mínimo            : ", DoubleToString(pMin,  0), " pts");
   Print("  P5                : ", DoubleToString(p5,    0), " pts");
   Print("  P10               : ", DoubleToString(p10,   0), " pts");
   Print("  P20               : ", DoubleToString(p20,   0), " pts");
   Print("  P25               : ", DoubleToString(p25,   0), " pts  ← MinSL_Points recomendado");
   Print("  P30               : ", DoubleToString(p30,   0), " pts");
   Print("  P40               : ", DoubleToString(p40,   0), " pts");
   Print("  Mediana (P50)     : ", DoubleToString(p50,   0), " pts");
   Print("  P60               : ", DoubleToString(p60,   0), " pts");
   Print("  P70               : ", DoubleToString(p70,   0), " pts");
   Print("  P75               : ", DoubleToString(p75,   0), " pts  ← MaxSL_Points recomendado");
   Print("  P80               : ", DoubleToString(p80,   0), " pts");
   Print("  P90               : ", DoubleToString(p90,   0), " pts");
   Print("  P95               : ", DoubleToString(p95,   0), " pts");
   Print("  Máximo            : ", DoubleToString(pMax,  0), " pts");
   Print("  Media             : ", DoubleToString(media, 0), " pts");
   Print("  Desv. estándar    : ", DoubleToString(stdDev,0), " pts");
   Print("── Valor por trade ──────────────────────────────────────");
   Print("  VPP               : ", DoubleToString(vpp, 4), " EUR/punto/lote");
   Print("  Riesgo 1 lot P50  : ", DoubleToString(p50 * vpp, 2), " EUR");
   Print("  Riesgo 1 lot P75  : ", DoubleToString(p75 * vpp, 2), " EUR");
   Print("── Parámetros recomendados para el EA ───────────────────");
   Print("  MinSL_Points = ", DoubleToString(p25, 0), "   (P25)");
   Print("  MaxSL_Points = ", DoubleToString(p75, 0), "   (P75)");
   Print("── Rango de test [", DoubleToString(MinSL_Test,0),
         "–", DoubleToString(MaxSL_Test,0), " pts] ────────────────");
   Print("  Días dentro rango : ", inRange, " / ", totalDays,
         "  (", DoubleToString(pctInRange, 1), "%)");
   Print("  Días fuera rango  : ", totalDays - inRange,
         "  (", DoubleToString(100.0 - pctInRange, 1), "%)");

   // ── Stats por día de semana ───────────────────────────────────
   if(ShowDayStats)
   {
      Print("── Estadísticas por día de semana (en puntos) ───────────");
      Print(StringFormat("  %-12s %6s %6s %6s %6s %6s",
                         "Dia", "n", "Media", "P25", "P50", "P75"));

      if(ArraySize(dayRanges1) > 0) {
         ArraySort(dayRanges1);
         Print(StringFormat("  %-12s %6d %6.0f %6.0f %6.0f %6.0f", "Lunes",
               ArraySize(dayRanges1), Mean(dayRanges1),
               Percentile(dayRanges1,25), Percentile(dayRanges1,50), Percentile(dayRanges1,75)));
      }
      if(ArraySize(dayRanges2) > 0) {
         ArraySort(dayRanges2);
         Print(StringFormat("  %-12s %6d %6.0f %6.0f %6.0f %6.0f", "Martes",
               ArraySize(dayRanges2), Mean(dayRanges2),
               Percentile(dayRanges2,25), Percentile(dayRanges2,50), Percentile(dayRanges2,75)));
      }
      if(ArraySize(dayRanges3) > 0) {
         ArraySort(dayRanges3);
         Print(StringFormat("  %-12s %6d %6.0f %6.0f %6.0f %6.0f", "Miercoles",
               ArraySize(dayRanges3), Mean(dayRanges3),
               Percentile(dayRanges3,25), Percentile(dayRanges3,50), Percentile(dayRanges3,75)));
      }
      if(ArraySize(dayRanges4) > 0) {
         ArraySort(dayRanges4);
         Print(StringFormat("  %-12s %6d %6.0f %6.0f %6.0f %6.0f", "Jueves",
               ArraySize(dayRanges4), Mean(dayRanges4),
               Percentile(dayRanges4,25), Percentile(dayRanges4,50), Percentile(dayRanges4,75)));
      }
      if(ArraySize(dayRanges5) > 0) {
         ArraySort(dayRanges5);
         Print(StringFormat("  %-12s %6d %6.0f %6.0f %6.0f %6.0f", "Viernes",
               ArraySize(dayRanges5), Mean(dayRanges5),
               Percentile(dayRanges5,25), Percentile(dayRanges5,50), Percentile(dayRanges5,75)));
      }
   }

   Print("════════════════════════════════════════════════════════");
   Print("  ACCION: MinSL_Points=", DoubleToString(p25, 0),
         "  MaxSL_Points=", DoubleToString(p75, 0));
   Print("  Cargar estos valores en BreakoutNY_Universal_FP en gráfico GER40");
   Print("════════════════════════════════════════════════════════");

   // ── CSV ───────────────────────────────────────────────────────
   if(!ExportCSV) return;

   string csvName = "BreakoutNY_Calibracion_GER40.csv";
   int fh = FileOpen(csvName, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ",");
   if(fh == INVALID_HANDLE) {
      Print("ERROR CSV: ", GetLastError());
      return;
   }

   FileWrite(fh, "Date", "Weekday", "RangePoints", "InRange", "BelowP25", "AboveP75");

   string dowNames[] = {"Dom","Lun","Mar","Mie","Jue","Vie","Sab"};
   string lastDate2  = "";

   for(int i = 2; i < copied - 1; i++)
   {
      MqlDateTime barDT;
      TimeToStruct(rates[i].time, barDT);
      if(barDT.hour != targetHour || barDT.min != targetMin) continue;

      string thisDate = StringFormat("%04d.%02d.%02d",
                                     barDT.year, barDT.mon, barDT.day);
      if(thisDate == lastDate2) continue;
      lastDate2 = thisDate;
      if(barDT.day_of_week == 0 || barDT.day_of_week == 6) continue;

      MqlDateTime dt1, dt2;
      TimeToStruct(rates[i-1].time, dt1);
      TimeToStruct(rates[i-2].time, dt2);
      if(dt1.day != barDT.day || dt1.mon != barDT.mon ||
         dt2.day != barDT.day || dt2.mon != barDT.mon) continue;

      double hi = MathMax(rates[i].high,  MathMax(rates[i-1].high,  rates[i-2].high));
      double lo = MathMin(rates[i].low,   MathMin(rates[i-1].low,   rates[i-2].low));
      double rp = (hi - lo) / pointSize;
      if(rp <= 0.0 || rp > 20000.0) continue;

      FileWrite(fh,
         thisDate,
         dowNames[barDT.day_of_week],
         DoubleToString(rp, 0),
         (rp >= MinSL_Test && rp <= MaxSL_Test) ? "1" : "0",
         (rp < p25) ? "1" : "0",
         (rp > p75) ? "1" : "0"
      );
   }

   // Resumen
   FileWrite(fh, "---", "RESUMEN", "", "", "", "");
   FileWrite(fh, "n_dias",        IntegerToString(totalDays),       "", "", "", "");
   FileWrite(fh, "Media_pts",     DoubleToString(media,  0),        "", "", "", "");
   FileWrite(fh, "P25_pts",       DoubleToString(p25,    0), "MinSL_Points", "", "", "");
   FileWrite(fh, "Mediana_pts",   DoubleToString(p50,    0),        "", "", "", "");
   FileWrite(fh, "P75_pts",       DoubleToString(p75,    0), "MaxSL_Points", "", "", "");
   FileWrite(fh, "P90_pts",       DoubleToString(p90,    0),        "", "", "", "");
   FileWrite(fh, "StdDev_pts",    DoubleToString(stdDev, 0),        "", "", "", "");
   FileWrite(fh, "VPP_EUR",       DoubleToString(vpp,    4),        "", "", "", "");
   FileWrite(fh, "Pct_en_rango",  DoubleToString(pctInRange,1)+"%", "", "", "", "");

   FileFlush(fh);
   FileClose(fh);
   Print("CSV exportado: ", csvName, "  (en MQL5\\Files\\)");
}
//+------------------------------------------------------------------+
