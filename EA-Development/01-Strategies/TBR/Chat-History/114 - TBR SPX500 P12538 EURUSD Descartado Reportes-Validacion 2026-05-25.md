# Chat 114 — TBR: EURUSD IS=2022 Verificado · EURUSD DESCARTADO · SPX500 P12538 VIABLE 13/13 · Reportes-Validacion
**Fecha:** 2026-05-25
**Sesiones:** 1 (continuación de Chat 113, contexto comprimido)

---

## Resumen ejecutivo

Sesión de verificación del nuevo archivo EURUSD IS=2022-2024, pipeline completo P269914 (DESCARTADO 7/12), análisis de nueva optimización SPX500 Hr=14 exclusivo (P12538 VIABLE 13/13), creación de set file con Magic 202513, cálculo de correlación vs P187 (0.661 MODERADA), actualización del registro de MN, y renombre de carpeta `Analisis-MonteCarlo` → `Reportes-Validacion`.

---

## EURUSD IS=2022-2024 — Verificación de período

### Problema identificado
El archivo XML nuevo `tbr eurusd m5 ny.xml` mostraba en su título "2025.01.01-2025.12.31" — igual que el archivo exploratorio. El usuario confirmó directamente en MT5 que el IS era 2022-2024 y el OOS era 2025.

### Método de verificación
Se comparó el mismo Pass (P41200) entre ambos archivos:
- Archivo exploratorio: Bck=0.93
- Archivo nuevo: Bck=1.14

Valores distintos de Bck (IS) con el mismo Pass prueban que los IS son diferentes, a pesar de títulos idénticos en XML. Comportamiento inconsistente del exportador de MT5.

### Renombre aplicado
`tbr eurusd m5 ny.xml` → `TBR_v1.1_EURUSD_M5_IS2022-2024_OOS2025_Hr11-15.xml`

**Nota crítica:** El título del XML mostrando solo el período OOS (no combinado) es comportamiento distinto al observado en DJI30/SPX500. En EURUSD el exportador de MT5 mostró solo el Forward period en el título.

---

## EURUSD Pipeline — P269914 DESCARTADO

### Parámetros del pass
- **Dir:** BUY
- **Sesión:** Hr=14:15srv
- **RangeCandlesCount:** 3
- **RR:** 4.5
- **UseBreakeven:** TRUE (verificado por variación de BE_TriggerRR=0.80 produciendo PF distinto)
- **BE_TriggerRR:** 0.80
- **MaxHoldHours:** 4h

### Detección de UseBreakeven
Se confirmó que UseBreakeven=TRUE comparando passes con BE_TriggerRR=0.80 vs BE_TriggerRR=0.20 manteniendo todo igual — valores de IS_PF distintos → BE activo en la optimización.

### Corrección de ubicación de archivos
Los backtests estaban en `Backtests/DJI30/` por error. Se movieron a `Backtests/EURUSD/` antes de correr el pipeline.

### Veredicto: DESCARTADO (7/12)
Criterios fallidos:
- Permutation OOS: p=0.27 (necesita p<0.05) — no significativo
- Monte Carlo OOS: P(profit)=72.6% (necesita >90%) — edge insuficiente
- WFA: PF<1.0

Sin edge robusto en EURUSD Hr=11-15srv con IS=2022-2024. Instrumento descartado de la hoja de ruta TBR.

---

## Stress test — Nota sobre cálculo de spread

El usuario preguntó cómo se calcula el spread en el stress test. Se reconoció que la reducción del 7.5% en ganancias / aumento del 7.5% en pérdidas es una **aproximación proporcional**, no el spread real en puntos. Para ORB con stop orders, el spread es un costo fijo por trade. Este punto quedó pendiente de mejora futura.

---

## Nueva optimización SPX500 — Hr=14 exclusivo

### Archivo analizado
`Optimizacion/SPX500/tbr sp500.xml`
- Período: IS=2022-2024, OOS=2025
- SessionStart_Hour FIJO en 14 (no variable)
- Total passes: 4,838

### Hallazgos del heatmap
- IS_PF mediana: 1.250
- Todos los passes IS≥1.20 son BUY
- Cluster dominante: **BUY Min=20 Range=1** (IS_med=1.460, OOS_med=1.450)
- Top pass: P12538 (BUY, Min=20, Range=1, RR=4.5, BE_TriggerRR=0.20, Hold=3h)

### UseBreakeven=TRUE confirmado
BE_TriggerRR varía en la optimización → diferentes IS_PF → UseBreakeven activo.

---

## SPX500 P12538 — Pipeline Completo VIABLE 13/13

### Parámetros
| Param | Valor |
|-------|-------|
| Dir | BUY |
| SessionStart | 14:20 srv |
| SessionEnd | 17:00 srv (igual que P187, no 18:00) |
| RangeCandlesCount | 1 |
| RR | 4.5 |
| UseBreakeven | true |
| BE_TriggerRR | 0.20 |
| MaxHoldHours | 3h |
| TradeDays | Lu/Ma/Mi (sin Jue ni Vie) |

### Resultados IS/OOS/WFA

| Período | PF | n | WR | DD% |
|---------|----|----|-----|-----|
| IS 2022-2024 | 1.708 | ~320 | — | — |
| OOS 2025 | 1.601 | ~105 | — | 2.28% |
| WFA 2026 | 1.279 | — | — | — |

### Análisis días de semana
- **Jueves DESTRUYE EDGE** en WFA: PF=0.041 — justificación sólida para filtro noJV
- Lunes/Martes/Miércoles: PF>1.20 en todos los períodos
- El filtro noJV es sistemáticamente justificado en SPX500 NY (confirmado tanto en P187 como en P12538)

### Veredicto: VIABLE 13/13

---

## Correlación P12538 vs P187

**Método:** Daily P&L resampled, aplicar filtro noJV a ambas series, Pearson sobre días comunes de trading.

**Resultado:** corr = **0.661** — MODERADA

**Interpretación:**
- Misma sesión (14:00-17:00 srv), mismo instrumento (SPX500), mismo horario → correlación esperada
- 0.661 no es lo suficientemente alta para ser redundante, pero no es despreciable
- **Recomendación:** cuenta separada o reducir RiskAmountUSD a $8-9 cada una si misma cuenta

---

## Set file creado

`Sets-Produccion/SPX500/TBR_v1.1_SPX500_P12538_noJV.set`
- MagicNumber: **202513**
- Incluye: UseBreakeven=true, BE_TriggerRR=0.20, MaxHoldHours=3, SessionEnd=17:00
- CRÍTICO: SessionEnd=17:00 (no 18:00 como NAS100/DJI30)

---

## Registro Magic Numbers — Actualización

`Sets-Produccion/CONTROL_MagicNumbers.md` actualizado:
- **202512:** DJI30 P11944 — EN CUENTA (live 2026-05-25)
- **202513:** SPX500 P12538 noJV — VIABLE 13/13, pendiente demo
- Próximo disponible: **202514**
- Notas agregadas: GBPJPY archivados, SPX500 dual-pass corr=0.661, EURUSD DESCARTADO

---

## Renombre de carpeta: Reportes-Validacion

### Problema
`Analisis-MonteCarlo/` era un nombre demasiado estrecho para una carpeta que contiene: heatmaps, histogramas, análisis de correlación, gráficas de pipeline, y resultados Monte Carlo.

### Opciones evaluadas
El usuario rechazó: Graficas, Analisis-Graficas, Outputs, Charts, Reportes, Evidencia, Resultados.

### Selección
**Reportes de Validacion** → implementado como `Reportes-Validacion/`

### Scripts actualizados (15 archivos)
- tbr_audjpy_asian_heatmap.py
- tbr_dji30_heatmap.py
- tbr_dji30_pipeline.py
- tbr_eurusd_heatmap.py
- tbr_eurusd_is2022_heatmap.py
- tbr_eurusd_pipeline.py
- tbr_gbpjpy_correlation.py
- tbr_gbpjpy_p110836_analysis.py
- tbr_gbpjpy_p110836_full_pipeline.py
- tbr_gbpjpy_second_plateau.py
- tbr_gbpusd_spx500_charts.py
- tbr_permutation_test.py
- tbr_usdjpy_full_analysis.py
- tbr_usdjpy_full_pipeline.py
- tbr_xauusd_asian_heatmap.py

Todos actualizados de `Analisis-MonteCarlo` → `Reportes-Validacion` en la variable `OUT_DIR`.

---

## Estado del portfolio al cierre de sesión

| Instrumento | Pass | Magic | Estado |
|-------------|------|-------|--------|
| NAS100 | P63 LMX | 202501 | ✅ LIVE |
| SPX500 | P187 noJV | 202505 | ✅ LIVE |
| DJI30 | P11944 | 202512 | ✅ EN CUENTA |
| SPX500 | P12538 noJV | 202513 | ⏳ VIABLE 13/13 — pendiente demo |
| GBPUSD | P958 nL | 202506 | ⏳ Demo condicional (≥$4,900) |
| XAUUSD | P1 #7129 | 202502 | ⏳ Q3 2026 |
| GBPJPY | P110836 | 202510 | ⏳ Demo |
| USDJPY | P5458 | 202508 | ⏳ Demo |

### Descartados
- EURUSD: P269914 — 7/12, Perm OOS p=0.27, MC P(profit)=72.6%
- AUDJPY: 0 passes PF≥1.10
- XAUUSD Asian: IS PF<1.10

---

## Próximos pasos

1. **GBPUSD Londres** — optimización corriendo (Hr=7-13srv). Analizar cuando complete.
2. **SPX500 P12538** — activar demo. Decidir cuenta (separada o misma con risk reducido).
3. **CADJPY/NZDJPY** — pendiente tras GBPUSD-L.
4. **Stress test mejora** — considerar usar spread real en puntos en lugar de aproximación proporcional.
