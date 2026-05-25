---
type: walkforward-index
strategy: BreakoutNY
updated: 2026-04-18
---
[[Strategy - BreakoutNY]]
# Walk-Forward 2026 — BreakoutNY Portfolio

Registro de resultados reales en vivo desde 2026. Cada activo tiene su subcarpeta con reportes mensuales extraídos del MT5 (Statement o Report).

## Regla de monitoreo

Revisar mensualmente. Si el PF acumulado WF cae por debajo de **1.20** con ≥ 30 trades, pausar el activo y revisar parámetros.

## Estado actual

| Activo | Estado | Trades WF | PF WF acumulado | Último reporte |
|---|---|---|---|---|
| XAUUSD v2 | ⏳ Pendiente inicio | — | — | — |
| NAS100 v1 | ⏳ Pendiente inicio | — | — | — |
| DJI30 v1 | ⏳ Pendiente inicio | — | — | — |
| SP500 v2 | 🔬 Demo observación | — | — | — |

## Estructura de archivos

Depositar en cada subcarpeta los reportes MT5 con el formato:
```
WF_[ACTIVO]_[YYYY-MM].xlsx
```
Ejemplo: `XAUUSD/WF_XAUUSD_2026-05.xlsx`

## Umbral de re-optimización

Si al acumular 60+ trades en WF el PF está entre 1.00–1.20, ejecutar nueva optimización con IS extendido hasta el presente y repetir el proceso IS/OOS con los datos frescos.
