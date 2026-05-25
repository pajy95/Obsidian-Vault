---
tags: [decision, TBR, EURJPY, no-viable]
fecha: 2026-05-20
estrategia: TBR v1.1
instrumento: EURJPY
timeframe: M5
sesion_testada: 00:00–09:00 server (UTC+2) → 22:00–07:00 UTC (sesión Tokyo completa)
periodo_IS: 2022-01-01 / 2025-12-31
servidor: FundingPips2-SIM
veredicto: NO VIABLE
---

# EURJPY TBR v1.1 — Sesión Tokyo — Decisión Formal

## Veredicto: NO VIABLE — DESCARTADO DEFINITIVO

## Parámetros optimizados

| Parámetro | Rango explorado |
|-----------|----------------|
| SessionStart_Hour | 0–9 (sesión completa Tokyo) |
| SessionStart_Min | 0–55 min |
| RangeCandlesCount | 2–6 velas |
| MaxHoldHours | 1–5 horas |
| RR | 1.5–3.5 |
| BE_TriggerRR | 0.4–1.0 |
| TradeDirection | 0=BOTH / 1=BUY / 2=SELL |
| EntryMode | 0=Market / 1=Pending |

## Resultados

| Métrica | Valor |
|---------|-------|
| Total passes analizados | 20,736 |
| Passes viables (criterios completos) | **1** |
| Mejor OOS PF | 1.240 (sin filtro) / 1.130 (con filtros) |
| IS PF del único viable | 1.130 |
| Degradación IS→OOS | 0.0% (coincidencia numérica — sospechoso) |
| Mediana OOS PF (20K passes) | 0.750 |
| Mediana IS PF | 0.910 |
| Meseta en único viable | **NO — pico aislado** |

### Único pass viable (Pass 240781) — rechazado

| Parámetro | Valor |
|-----------|-------|
| OOS PF | 1.130 |
| IS PF | 1.130 |
| DD% | 4.51% |
| Trades | 232 |
| Sharpe | 1.704 |
| Dir | BUY only |
| EntryMode | Market |
| Candles | 6 |
| Hour:Min | 02:45 server |
| MaxHold | 4h |
| RR | 3.0 |
| BE_TriggerRR | 0.8 |

## Diagnóstico

1 pass de 20,736 cumple criterios — sesgo de selección extremo, no evidencia de edge.
El único viable es un pico aislado sin vecinos estables — falla la prueba de meseta.
IS=OOS=1.130 exactos con degradación 0.0% es matemáticamente sospechoso.
OOS mediana 0.750 confirma pérdida sistemática en el período forward.

## Conclusión EURJPY — CIERRE DEFINITIVO

Ambas sesiones han sido exploradas exhaustivamente:

| Sesión | Passes | Viables | Veredicto |
|--------|--------|---------|-----------|
| 09:00–14:00 server (Londres) | 12,441 | 0 | NO VIABLE |
| 00:00–09:00 server (Tokyo) | 20,736 | 1 (pico) | NO VIABLE |
| **TOTAL** | **33,177** | **0 reales** | **DESCARTADO** |

**EURJPY no tiene edge con TBR v1.1 en ningún horario. No invertir más tiempo en este instrumento.**

## Archivos relacionados

- `Optimizacion/EURJPY/TBR_v1.1_EURJPY_M5_IS2022-2025_Ses09-14_NVIABLE.xml`
- `Optimizacion/EURJPY/TBR_v1.1_EURJPY_M5_IS2022-2025_Ses00-09_NVIABLE.xml`
- `Decisions/EURJPY_2026-05-19_NVIABLE.md` (sesión Londres)
