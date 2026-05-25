---
type: walkforward-index
strategy: CTR Pro
updated: 2026-04-30
---
[[Strategy - CTR Pro]]
# Walk-Forward 2026 — CTR Pro

Registro de resultados reales en vivo desde 2026. Cada activo tiene su subcarpeta con reportes mensuales extraídos del MT5 (Statement o Report).

## Regla de monitoreo

Revisar mensualmente. Si el PF acumulado WF cae por debajo de **1.20** con ≥ 30 trades, pausar el activo y revisar parámetros.

## Estado actual

| Activo | Estado | Trades WF | PF WF acumulado | Último reporte |
|--------|--------|-----------|----------------|----------------|
| XAUUSD M5 | ⚠️ En producción (sin IS/OOS formal) | — | — | — |
| NDX100 M10 v3.8 | ⏳ Pendiente — v3.8 en construcción | — | — | — |

## Estructura de archivos

Depositar en cada subcarpeta los reportes MT5 con el formato:
```
WF_[ACTIVO]_[YYYY-MM].xlsx
```
Ejemplo: `XAUUSD/WF_XAUUSD_2026-05.xlsx`

## Umbral de re-optimización

Si al acumular 60+ trades en WF el PF está entre 1.00–1.20, ejecutar nueva optimización con IS extendido hasta el presente y repetir el proceso IS/OOS con los datos frescos.

## Notas

- WF XAUUSD inicia cuando IS/OOS Fase 3 esté completado
- WF NDX100 inicia cuando v3.8 esté construido y desplegado
