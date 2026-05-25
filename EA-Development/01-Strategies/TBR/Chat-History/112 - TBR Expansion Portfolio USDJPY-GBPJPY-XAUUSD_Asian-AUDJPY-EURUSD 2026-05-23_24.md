# Chat 112 — TBR Expansión Portfolio: USDJPY · GBPJPY · XAUUSD Asian · AUDJPY · EURUSD
**Fecha:** 2026-05-23 / 2026-05-24
**Sesiones:** 2 (contexto comprimido entre sesiones)

---

## Resumen ejecutivo

Sesión de análisis masivo de instrumentos para expandir el portfolio TBR hacia 9 activos (3 cuentas de fondeo). Se completaron pipelines completos para USDJPY y GBPJPY (segunda meseta), se descartaron XAUUSD Asian, AUDJPY, y se inició el análisis de EURUSD.

---

## USDJPY — Pipeline COMPLETO

### P5458 — VIABLE (10/10) → DEMO
- **Config:** BUY, Hr=02:35srv (00:35 UTC), Range=6, RR=2.5, BE=0.60
- IS: PF=1.378, WR=49.1%, n=528, DD=3.05%
- OOS: PF=1.387, WR=45.6%, n=180, DD=3.11%
- WFA: PF=1.170, WR=45.2%, n=73 — positivo en 2026
- Degradación IS→OOS: -2.4% (prácticamente cero)
- Permutation IS z=3.42 / OOS z=1.97. Stress OOS PF=1.187. MC P(profit)=97%
- **Magic: 202508** | Set: `Optimizacion/USDJPY/Sets/TBR_USDJPY_P5458.set`

### P7389 — MARGINAL (9/10) → En espera Q3 2026
- **Config:** BOTH, Hr=03:50srv (01:50 UTC), Range=6, RR=3.0, BE=0.60
- OOS: PF=1.610 (excelente) pero WFA=0.970 (negativo)
- Hipótesis: SHORT pierde en 2026, BUY-only podría funcionar
- **Magic: 202507** reservado

---

## GBPJPY — Pipeline COMPLETO (sesión anterior)

### P110836 — VIABLE (11/11) — PASS PRIMARIO
- **Config:** BUY, Hr=08:55srv (06:55 UTC), Range=6, RR=2.5, BE=0.60
- IS: PF=1.250, OOS: PF=1.759, WFA: PF=1.333
- **Magic: 202510**

### P121378 — VIABLE pero WFA negativo (0.918)
- **Config:** BUY, Hr=09:00srv, Range=6, RR=3.0, BE=0.60
- **Magic: 202509**

### Correlación P110836 vs P121378 — ALTA
| Período | Correlación | Coincidencia días |
|---------|------------|-----------------|
| OOS 2025 | **0.795** | 91% |
| IS 2022-2024 | **0.889** | 92% |

**Decisión: NO correr ambas simultáneamente.** Solo P110836 en demo. P121378 archivado como backup.

---

## XAUUSD Sesión Asiática — NO VIABLE ❌

**Optimización:** 6,220 passes (TBR v1.1, Hr=2-9 srv, BUY/BOTH/SELL)

**Hallazgos del heatmap:**
- Edge exclusivamente BUY, cluster dominante Hr=07:55srv (London pre-open, 05:55 UTC)
- BE no mejora el edge (timeout-based, igual que NY)
- **Alerta recency bias:** Bck=1.02, Fwd=1.63 en top pass

**P14065 probado:** IS PF=1.022 — FALLA. Pipeline termina en IS.
**P52360 probado:** IS PF=1.088 — FALLA. Pipeline termina en IS.

Patrón consistente: IS 2022-2024 débil, OOS 2025 fuerte → edge reciente, no estructural.
**Conclusión: XAUUSD sesión asiática descartado. Solo NY (P1 #7129) para Q3 2026.**

---

## AUDJPY Sesión Asiática — NO VIABLE ❌

**Optimización:** 24,192 passes (TBR v1.1, Hr=0-8 srv, todas las direcciones)

- PF máximo en todo el espacio: **1.092**
- **0 passes con PF ≥ 1.10**
- PF mediana por hora: 0.52–0.81 (rango aleatorio)
- Sin ninguna hora ni dirección con edge consistente

**Razón fundamental:** AUDJPY = commodity currency (AUD) vs safe haven (JPY). Flujos opuestos durante sesión asiática → ruido, no directionalidad. TBR no aplica.

---

## EURUSD — En análisis (optimización en curso al cierre de jornada)

- **Parámetros:** Hr=7-16 srv, Min=0-55, Range=2-8, RR=1.5-4.5, Dir=BOTH/BUY/SELL
- **Total:** 17,640 passes | SessionEnd=18srv | MaxHold=2h
- Cubre London open (09:00-11:00srv) y NY open (15:30-17:00srv)
- **Estado:** Optimización corriendo al cierre — analizar en próxima sesión

---

## GBPUSD Sesión Londres — Pendiente

- Las 3 optimizaciones previas de GBPUSD tenían Hr=14 fijo (NY session only)
- Sesión Londres (Hr=7-13srv) nunca fue escaneada
- Parámetros listos para correr: Hr=7-13, SessionEnd=14, 12,348 passes
- **Oportunidad:** 2 passes GBPUSD (London + NY) con baja correlación esperada

---

## Estado portfolio TBR al 2026-05-24

| Instrumento | Pass | Magic | Estado |
|-------------|------|-------|--------|
| NAS100 | P63 LMX | 202501 | ✅ Live |
| SPX500 | P187 noJV | 202505 | ✅ Live |
| XAUUSD | P1 NY | 202502 | ⏳ Q3 2026 |
| GBPUSD | P958 nL | 202506 | ⏳ Demo condicional |
| GBPJPY | P110836 | 202510 | ⏳ Demo (correlación resuelta) |
| USDJPY | P5458 | 202508 | ⏳ Demo |
| USDJPY | P7389 | 202507 | ⏳ En espera Q3 2026 |
| GBPJPY | P121378 | 202509 | 🗄️ Archivado (corr=0.89 con P110836) |

**Instrumentos descartados:** EURJPY (Asian), AUDJPY (Asian), XAUUSD (Asian)

**Próximos a analizar:**
1. EURUSD — optimización corriendo (Hr=7-16 srv)
2. GBPUSD Londres — optimización pendiente (Hr=7-13 srv)
3. CADJPY o NZDJPY — siguiente si EURUSD/GBPUSD-L viables

**Objetivo:** 9 instrumentos para 3 cuentas de fondeo (distribución NY / Asiática / Europea)

---

## Archivos generados esta sesión

| Archivo | Tipo |
|---------|------|
| `tbr_usdjpy_full_pipeline.py` | Script pipeline completo USDJPY |
| `tbr_xauusd_asian_heatmap.py` | Script heatmap XAUUSD Asian |
| `tbr_audjpy_asian_heatmap.py` | Script heatmap AUDJPY Asian |
| `tbr_gbpjpy_correlation.py` | Script correlación P110836 vs P121378 |
| `Decisions/USDJPY_P5458_2026-05-23_Pipeline_VIABLE.md` | Decisión formal P5458 |
| `Decisions/USDJPY_P7389_2026-05-23_Pipeline_MARGINAL.md` | Decisión formal P7389 |
| `Analisis-MonteCarlo/GBPJPY/GBPJPY_Correlacion_P110836_P121378.png` | Gráfica correlación |
| `Analisis-MonteCarlo/AUDJPY/AUDJPY_Heatmap_HourMin.png` | Heatmap AUDJPY |
| `Analisis-MonteCarlo/XAUUSD/Asian_XAUUSD_Heatmap_HourMin.png` | Heatmap XAUUSD Asian |
| `Backtests/XAUUSD/IS_TBR_XAUUSD_Asian_P14065_2022-2024.xlsx` | Renombrado |
| `Backtests/XAUUSD/OOS_TBR_XAUUSD_Asian_P14065_2025.xlsx` | Renombrado |
| `Backtests/XAUUSD/IS_TBR_XAUUSD_Asian_P52360_2022-2024.xlsx` | Movido+renombrado |
| `Backtests/XAUUSD/OOS_TBR_XAUUSD_Asian_P52360_2025.xlsx` | Movido+renombrado |
