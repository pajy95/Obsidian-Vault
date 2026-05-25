---
tags: [decision, TBR, EURJPY, no-viable]
fecha: 2026-05-19
estrategia: TBR v1.1
instrumento: EURJPY
timeframe: M5
sesion_testada: 09:00–14:00 server (UTC+2) → 07:00–12:00 UTC
periodo_IS: 2022-01-01 / 2025-12-31
servidor: FundingPips2-SIM
veredicto: NO VIABLE
---

# EURJPY TBR v1.1 — Decisión Formal

## Veredicto: NO VIABLE — DESCARTADO

## Parámetros optimizados

| Parámetro | Rango explorado |
|-----------|----------------|
| RangeCandlesCount | 2–6 velas |
| SessionStart_Min | 0–55 min |
| MaxHoldHours | 1–5 horas |
| RR | 1.5–3.5 |
| BE_TriggerRR | 0.4–1.0 |
| SessionStart_Hour | 9–14 (fijo en análisis) |
| TradeDirection | 0=BOTH / 1=BUY / 2=SELL |
| EntryMode | 0=Market / 1=Pending |

## Resultados de la optimización

| Métrica | Valor |
|---------|-------|
| Total passes analizados | 12,441 |
| Passes viables (OOS≥1.10, IS≥1.10, DD≤10%, trades≥100) | **0** |
| Mejor OOS PF encontrado | 1.130 (Pass 131811) |
| IS PF del mejor pass | 1.010 ❌ |
| Mediana OOS PF (12,441 passes) | 0.690 |
| Mediana IS PF | 0.930 |
| Mediana DD% | 8.76% |

### Top 5 passes por OOS PF

| Pass | OOS PF | IS PF | DD% | Trades | Dir | Candles | Hour:Min | MaxHold | RR | BE |
|------|--------|-------|-----|--------|-----|---------|----------|---------|----|----|
| 131811 | 1.130 | 1.010 | 4.00 | 257 | BOTH | 2 | 09:35 | 4h | 2.5 | 0.8 |
| 82686  | 1.120 | 1.020 | 2.60 | 257 | BOTH | 5 | 09:20 | 4h | 2.0 | 0.6 |
| 95523  | 1.100 | 0.990 | 4.58 | 257 | BOTH | 2 | 09:35 | 4h | 2.5 | 0.6 |
| 125764 | 1.100 | 0.960 | 3.67 | 199 | BUY  | 2 | 09:35 | 2h | 2.5 | 0.8 |
| 143907 | 1.100 | 1.050 | 4.61 | 257 | BOTH | 2 | 09:35 | 4h | 3.0 | 0.8 |

## Diagnóstico

La mediana de OOS PF en 12,441 combinaciones es **0.690** — la estrategia pierde dinero en el 
período forward en la amplia mayoría de configuraciones. No es ruido estadístico: es ausencia de 
edge estructural en EURJPY durante el horario 09:00–14:00 (server).

El mejor pass (OOS=1.130, Pass 131811) tiene IS=1.010, indicando que la pequeña ganancia en OOS 
es un artefacto de selección entre 12K intentos, no un patrón replicable.

**Razones del rechazo:**
1. Ningún pass cumple criterios mínimos simultáneamente (OOS≥1.10 + IS≥1.10)
2. IS PF mediano < 1.0 → la estrategia no captura edge ni en el período de entrenamiento
3. OOS PF mediano 0.69 → deterioro sistemático al salir del IS
4. 12,441 passes con máximo OOS=1.13 es una señal clara de ausencia de edge

## Archivos relacionados

- `Optimizacion/EURJPY/TBR_v1.1_EURJPY_M5_IS2022-2025_Ses09-14_NVIABLE.xml`

## Próximos pasos sugeridos

- Probar EURJPY en sesión Tokio (02:00–09:00 server) — JPY es más activo en Asia
- Probar GBPJPY en span Tokyo–London (objeto del análisis actual)
- No invertir más tiempo en EURJPY sesión 09–14 con TBR
