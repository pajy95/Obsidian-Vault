//+------------------------------------------------------------------+
//|   BreakoutNY_Calibrador_EURUSD.mq5                               |
//|   Calibrador de Rangos NY — EURUSD — FundingPips                 |
//|                                                                   |
//|   PROPÓSITO:                                                      |
//|   Analiza los últimos N años de datos M5 del par activo y        |
//|   calcula la distribución estadística del rango de las 3 velas   |
//|   14:35 / 14:40 / 14:45 UTC (rango de apertura NY).             |
//|                                                                   |
//|   OUTPUT:                                                         |
//|   1. Log en el journal de MT5 con todos los percentiles          |
//|   2. CSV exportado: BreakoutNY_Calibracion_EURUSD.csv            |
//|                                                                   |
//|   USO:                                                            |
//|   1. Compilar y ejecutar como Script en gráfico EURUSD M5        |
//|   2. Revisar Journal: buscar "RESULTADO FINAL"                   |
//|   3. Usar P25 como MinSL_Pips y P75 como MaxSL_Pips en el EA   |
//+------------------------------------------------------------------+
#property copyright "BreakoutNY Calibrador v1.1"
#property version   "1.01"
#property script_show_inputs

//==================================================================
// INPUTS
//==================================================================
input int    ServerOffsetHours = 2;      // UTC+2 = FundingPips
input int    YearsToAnalyze    = 5;      // Años hacia atrás (mínimo 3)
input double MinSL_Test        = 8.0;    // Pips mínimos de referencia
input double MaxSL_Test        = 25.0;   // Pips máximos de referencia
input bool   ExportCSV         = true;   // Exportar CSV día a día
input bool   ShowDayStats      = true;   // Estadísticas por día de semana

//==================================================================
// Función auxiliar: percentil de un array YA ORDENADO
//==================================================================
double Percentile(double &arr[], double pct)
{
   int n = ArraySize(arr);
   if(n == 0) return 0;
   int idx = (int)MathFloor((n - 1) * pct / 100.0);
   idx = MathMax(0, MathMin(idx, n - 1));
   return arr[idx];
}

//==================================================================
// Función auxiliar: media de un array
//==================================================================
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
   // ── Detección automática de specs ────────────────────────────
   int    digits  = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipSize;
   if(digits == 3 || digits == 5)
      pipSize = 10.0 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   else
      pipSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double tickValue   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize2   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double vpp         = (tickSize2 > 0) ? tickValue / tickSize2 : 0;
   double valuePerPip = vpp * pipSize;

   Print("╔══════════════════════════════════════════════════════╗");
   Print("║  BreakoutNY Calibrador NY Range — v1.1              ║");
   Print("╚══════════════════════════════════════════════════════╝");
   Print("  Símbolo     : ", _Symbol);
   Print("  _Digits     : ", digits);
   Print("  pipSize     : ", DoubleToString(pipSize, 5));
   Print("  ValuePerPip : ", DoubleToString(valuePerPip, 2), " $/pip/lote");
   Print("  ServerOffset: UTC+", ServerOffsetHours);

   // ── Ventana de tiempo ─────────────────────────────────────────
   datetime endTime   = TimeCurrent();
   datetime startTime = endTime - (datetime)(YearsToAnalyze * 365 * 24 * 3600);
   Print("  Desde : ", TimeToString(startTime));
   Print("  Hasta : ", TimeToString(endTime));

   // ── Cargar datos M5 ───────────────────────────────────────────
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   int copied = CopyRates(_Symbol, PERIOD_M5, startTime, endTime, rates);
   if(copied < 100) {
      Print("ERROR: Solo ", copied, " barras. Descarga el histórico M5 completo.");
      return;
   }
   Print("Barras M5 cargadas: ", copied);

   // ── Arrays de recolección ─────────────────────────────────────
   double allRanges[];
   string allDates[];
   int    allWeekdays[];
   ArrayResize(allRanges,   0);
   ArrayResize(allDates,    0);
   ArrayResize(allWeekdays, 0);

   // Arrays PLANOS por día de semana (MQL5 no admite arrays de arrays)
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

   // ── Hora objetivo en servidor ─────────────────────────────────
   int targetHour = 14 + ServerOffsetHours;  // 16 para UTC+2
   int targetMin  = 45;

   string lastDate  = "";
   int    processed = 0;
   int    skipped   = 0;

   // ── Primer pase: recolectar rangos ───────────────────────────
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

      MqlDateTime dt1, dt2;
      TimeToStruct(rates[i-1].time, dt1);
      TimeToStruct(rates[i-2].time, dt2);
      if(dt1.day != barDT.day || dt1.mon != barDT.mon ||
         dt2.day != barDT.day || dt2.mon != barDT.mon)
      { skipped++; continue; }

      double hi = MathMax(rates[i].high,  MathMax(rates[i-1].high,  rates[i-2].high));
      double lo = MathMin(rates[i].low,   MathMin(rates[i-1].low,   rates[i-2].low));
      double rp = (hi - lo) / pipSize;

      if(rp <= 0.0 || rp > 200.0) { skipped++; continue; }

      // Agregar al array global
      int n = ArraySize(allRanges);
      ArrayResize(allRanges,   n + 1);
      ArrayResize(allDates,    n + 1);
      ArrayResize(allWeekdays, n + 1);
      allRanges[n]   = rp;
      allDates[n]    = thisDate;
      allWeekdays[n] = barDT.day_of_week;

      // Agregar al array del día (5 arrays separados — no array de arrays)
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
      Print("ERROR: Solo ", totalDays, " días válidos. Verifica el histórico M5.");
      return;
   }
   Print("Días procesados : ", processed);
   Print("Días omitidos   : ", skipped);

   // ── Ordenar para percentiles ──────────────────────────────────
   ArraySort(allRanges);

   // ── Percentiles globales ──────────────────────────────────────
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

   // ── Imprimir resultado ────────────────────────────────────────
   Print("╔══════════════════════════════════════════════════════╗");
   Print("║   RESULTADO FINAL — DISTRIBUCIÓN DE RANGOS NY       ║");
   Print("║   ", _Symbol, " | ", YearsToAnalyze, " años | n=", totalDays, " días           ║");
   Print("╚══════════════════════════════════════════════════════╝");
   Print("── Estadísticas globales ────────────────────────────────");
   Print("  n (días válidos)  : ", totalDays);
   Print("  Mínimo            : ", DoubleToString(pMin,  1), " pips");
   Print("  P5                : ", DoubleToString(p5,    1), " pips");
   Print("  P10               : ", DoubleToString(p10,   1), " pips");
   Print("  P20               : ", DoubleToString(p20,   1), " pips");
   Print("  P25               : ", DoubleToString(p25,   1), " pips  ← MinSL_Pips recomendado");
   Print("  P30               : ", DoubleToString(p30,   1), " pips");
   Print("  P40               : ", DoubleToString(p40,   1), " pips");
   Print("  Mediana (P50)     : ", DoubleToString(p50,   1), " pips");
   Print("  P60               : ", DoubleToString(p60,   1), " pips");
   Print("  P70               : ", DoubleToString(p70,   1), " pips");
   Print("  P75               : ", DoubleToString(p75,   1), " pips  ← MaxSL_Pips recomendado");
   Print("  P80               : ", DoubleToString(p80,   1), " pips");
   Print("  P90               : ", DoubleToString(p90,   1), " pips");
   Print("  P95               : ", DoubleToString(p95,   1), " pips");
   Print("  Máximo            : ", DoubleToString(pMax,  1), " pips");
   Print("  Media             : ", DoubleToString(media, 1), " pips");
   Print("  Desv. estándar    : ", DoubleToString(stdDev,1), " pips");
   Print("── Valor por trade ──────────────────────────────────────");
   Print("  ValuePerPip       : $", DoubleToString(valuePerPip, 2), "/pip/lote");
   Print("  Riesgo 1 lot P50  : $", DoubleToString(p50 * valuePerPip, 2));
   Print("── Parámetros recomendados para el EA ───────────────────");
   Print("  MinSL_Pips = ", DoubleToString(p25, 1), "   (P25)");
   Print("  MaxSL_Pips = ", DoubleToString(p75, 1), "   (P75)");
   Print("── Rango de test [", DoubleToString(MinSL_Test,1),
         "–", DoubleToString(MaxSL_Test,1), " pips] ──────────────");
   Print("  Días dentro rango : ", inRange, " / ", totalDays,
         "  (", DoubleToString(pctInRange, 1), "%)");
   Print("  Días fuera rango  : ", totalDays - inRange,
         "  (", DoubleToString(100.0 - pctInRange, 1), "%)");

   // ── Stats por día de semana ───────────────────────────────────
   if(ShowDayStats)
   {
      Print("── Estadísticas por día de semana ───────────────────────");
      Print(StringFormat("  %-12s %6s %6s %6s %6s %6s",
                         "Dia", "n", "Media", "P25", "P50", "P75"));

      if(ArraySize(dayRanges1) > 0) {
         ArraySort(dayRanges1);
         Print(StringFormat("  %-12s %6d %6.1f %6.1f %6.1f %6.1f", "Lunes",
               ArraySize(dayRanges1), Mean(dayRanges1),
               Percentile(dayRanges1,25), Percentile(dayRanges1,50), Percentile(dayRanges1,75)));
      }
      if(ArraySize(dayRanges2) > 0) {
         ArraySort(dayRanges2);
         Print(StringFormat("  %-12s %6d %6.1f %6.1f %6.1f %6.1f", "Martes",
               ArraySize(dayRanges2), Mean(dayRanges2),
               Percentile(dayRanges2,25), Percentile(dayRanges2,50), Percentile(dayRanges2,75)));
      }
      if(ArraySize(dayRanges3) > 0) {
         ArraySort(dayRanges3);
         Print(StringFormat("  %-12s %6d %6.1f %6.1f %6.1f %6.1f", "Miercoles",
               ArraySize(dayRanges3), Mean(dayRanges3),
               Percentile(dayRanges3,25), Percentile(dayRanges3,50), Percentile(dayRanges3,75)));
      }
      if(ArraySize(dayRanges4) > 0) {
         ArraySort(dayRanges4);
         Print(StringFormat("  %-12s %6d %6.1f %6.1f %6.1f %6.1f", "Jueves",
               ArraySize(dayRanges4), Mean(dayRanges4),
               Percentile(dayRanges4,25), Percentile(dayRanges4,50), Percentile(dayRanges4,75)));
      }
      if(ArraySize(dayRanges5) > 0) {
         ArraySort(dayRanges5);
         Print(StringFormat("  %-12s %6d %6.1f %6.1f %6.1f %6.1f", "Viernes",
               ArraySize(dayRanges5), Mean(dayRanges5),
               Percentile(dayRanges5,25), Percentile(dayRanges5,50), Percentile(dayRanges5,75)));
      }
   }

   Print("════════════════════════════════════════════════════════");
   Print("  ACCION: MinSL_Pips=", DoubleToString(p25, 1),
         "  MaxSL_Pips=", DoubleToString(p75, 1));
   Print("════════════════════════════════════════════════════════");

   // ── Exportar CSV ──────────────────────────────────────────────
   if(!ExportCSV) return;

   string csvName = "BreakoutNY_Calibracion_" + _Symbol + ".csv";
   int fh = FileOpen(csvName, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ",");
   if(fh == INVALID_HANDLE) {
      Print("ERROR CSV: ", GetLastError());
      return;
   }

   FileWrite(fh, "Date", "Weekday", "RangePips", "InRange", "BelowP25", "AboveP75");

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
      double rp = (hi - lo) / pipSize;
      if(rp <= 0.0 || rp > 200.0) continue;

      FileWrite(fh,
         thisDate,
         dowNames[barDT.day_of_week],
         DoubleToString(rp, 1),
         (rp >= MinSL_Test && rp <= MaxSL_Test) ? "1" : "0",
         (rp < p25)         ? "1" : "0",
         (rp > p75)         ? "1" : "0"
      );
   }

   // Resumen al final
   FileWrite(fh, "---", "RESUMEN", "", "", "", "");
   FileWrite(fh, "n_dias",       IntegerToString(totalDays), "", "", "", "");
   FileWrite(fh, "Media_pips",   DoubleToString(media,  1),  "", "", "", "");
   FileWrite(fh, "P25_pips",     DoubleToString(p25,    1),  "MinSL_Pips", "", "", "");
   FileWrite(fh, "Mediana_pips", DoubleToString(p50,    1),  "", "", "", "");
   FileWrite(fh, "P75_pips",     DoubleToString(p75,    1),  "MaxSL_Pips", "", "", "");
   FileWrite(fh, "P90_pips",     DoubleToString(p90,    1),  "", "", "", "");
   FileWrite(fh, "StdDev_pips",  DoubleToString(stdDev, 1),  "", "", "", "");
   FileWrite(fh, "Pct_en_rango", DoubleToString(pctInRange,1)+"%", "", "", "", "");

   FileFlush(fh);
   FileClose(fh);
   Print("CSV exportado: ", csvName, "  (en MQL5\\Files\\)");
}
//+------------------------------------------------------------------+
