---
type: optimization-index
strategy: ARE
updated: 2026-05-01
---

# ARE — Optimización

## Parámetros optimizables

| Parámetro | Default | Rango sugerido | Módulo |
|-----------|---------|----------------|--------|
| InpHurst_Period | 200 | 100 / 150 / 200 / 250 | Regime |
| InpRSI_Period | 14 | 10 / 14 / 21 | MR |
| InpRSI_OB | 72 | 68 / 72 / 75 / 78 | MR |
| InpRSI_OS | 28 | 22 / 25 / 28 / 32 | MR |
| InpBB_Period | 20 | 15 / 20 / 25 | MR |
| InpBB_Dev | 2.0 | 1.8 / 2.0 / 2.2 / 2.5 | MR |
| InpBOS_Period | 20 | 10 / 15 / 20 / 25 | BO |
| InpBodyRatio_Min | 0.6 | 0.5 / 0.6 / 0.7 | BO |
| InpMomentum_ATR_Min | 1.5 | 1.0 / 1.5 / 2.0 | BO |
| InpSwing_Lookback | 3 | 2 / 3 / 4 / 5 | BO |
| InpSL_ATR_Multi | 1.5 | 1.0 / 1.5 / 2.0 / 2.5 | Risk |
| InpTP_ATR_Multi | 3.0 | 2.0 / 3.0 / 4.0 / 5.0 | Risk |

## Parámetros fijos (NO optimizar)

| Parámetro | Valor | Razón |
|-----------|-------|-------|
| Umbral Hurst TREND | 0.55 | Definido por teoría matemática |
| Umbral Hurst REVERT | 0.45 | Definido por teoría matemática |
| InpRisk_Pct | 1.0 | Metodología portfolio |
| InpMaxDailyDD | 3.0 | Prop firm compliance |
| InpMaxTotalDD | 6.0 | Prop firm compliance |

## Orden recomendado de optimización

1. Optimizar módulos por separado: primero MR solo (`InpUseSwingFilter=false`, desactivar BO), luego BO solo
2. Comparar PF módulo MR vs módulo BO independiente
3. Optimizar Risk (SL/TP multi) sobre el set ganador
4. Combinar y verificar que combined PF > individual PF
