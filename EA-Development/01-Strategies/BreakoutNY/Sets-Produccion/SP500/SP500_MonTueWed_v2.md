---
type: production-set
strategy: BreakoutNY
asset: SP500
version: v2
status: demo-observation
validated: 2026-04-18
broker: FundingPips
---

# Set de Referencia — SP500 Mon+Tue+Wed v2

> ⚠️ **Estado: DEMO únicamente.** No activar en cuenta prop hasta completar 3 meses de WF 2026 con PF acumulado ≥ 1.40 y ≥ 30 trades. Re-evaluar en julio 2026.

## Parámetros MT5

| Parámetro | Valor |
|---|---|
| **EA** | BreakoutNY_v1_SP500_FP |
| **Símbolo** | SPX500 (puede ser SP500, US500 según broker) |
| **Timeframe** | M5 |
| **MagicNumber** | 202403 |
| **RiskAmountUSD** | 8 (reducido por PF OOS marginal) |
| **ServerOffsetHours** | 2 |
| **BE_BufferPct** | 70 |
| **MinSL_Points** | 1000 |
| **MaxSL_Points** | 2000 |
| **FilterMonday** | **true** |
| **FilterTuesday** | **true** |
| **FilterWednesday** | **true** |
| **FilterThursday** | false |
| **FilterFriday** | false |
| **ConfirmOnClose** | true |
| **ATR_FilterEnable** | true |
| **ATR_Period** | 14 |
| **ATR_MaxMultiplier** | 2 |
| **ATR_MinMultiplier** | 0.3 |
| **ATR_BaselineDays** | 20 |
| **EntryMaxCandle** | 0 |
| **SessionCloseHour** | 23 |
| **SessionCloseMin** | 0 |

## Métricas validadas

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 1.724 | 1.374 ⚠️ |
| Max DD | 1.22% | 1.74% |
| Trades | 99 | 43 |
| Win Rate | 30.3% | 27.9% |
| RR promedio | 1.95:1 | 2.18:1 |
| Retención OOS | — | 79.7% |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

## Por qué no está activo

| Problema | Detalle |
|---|---|
| PF OOS marginal | 1.374 — por debajo del umbral de 1.40 |
| WR bajo | 27.9% — rachas de 6–8 pérdidas consecutivas esperables |
| 2023 negativo | Único año IS con resultado negativo — riesgo de réplica |
| Plateau débil | Solo 1 pasada con DD IS ≤ 8% y Tr OOS ≥ 30 en su cluster |

## Criterios para activar en producción

- [ ] WF 2026 demo: PF acumulado ≥ 1.40
- [ ] WF 2026 demo: mínimo 30 trades completados
- [ ] WF 2026 demo: DD máximo acumulado ≤ 5%
- [ ] Fecha mínima de evaluación: julio 2026

## Archivos de referencia

- **Backtest:** `Backtests/SP500/IS_SP500_MonTueWed_v2.xlsx` / `OOS_SP500_MonTueWed_v2.xlsx`
- **Optimización:** `Optmizacion/SP500/OP_SP500_v2.xml` / `FR_SP500_v2.xml`
- **Análisis:** `Analisis-MonteCarlo/MonteCarlo_SP500_MonTueWed_v2.png`
