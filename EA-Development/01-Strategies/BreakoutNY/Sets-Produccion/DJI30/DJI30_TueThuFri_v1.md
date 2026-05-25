---
type: production-set
strategy: BreakoutNY
asset: DJI30
version: v1
status: production
validated: 2026-04-18
broker: FundingPips
---

# Set de Producción — DJI30 Tue+Thu+Fri v1

## Parámetros MT5

| Parámetro | Valor |
|---|---|
| **EA** | BreakoutNY_v4_DJI30_FP (v4.1) |
| **Símbolo** | DJI30 (puede ser US30, DJ30H según broker) |
| **Timeframe** | M5 |
| **MagicNumber** | 202402 |
| **RiskAmountUSD** | 12 |
| **ServerOffsetHours** | 2 |
| **BE_BufferPct** | 20 |
| **MinSL_Points** | 6000 |
| **MaxSL_Points** | 30000 |
| **FilterMonday** | false |
| **FilterTuesday** | **true** |
| **FilterWednesday** | false |
| **FilterThursday** | **true** |
| **FilterFriday** | **true** |
| **ConfirmOnClose** | true |
| **EntryMaxCandle** | 0 |
| **ATR_FilterEnable** | true |
| **ATR_Period** | 14 |
| **ATR_MaxMultiplier** | 2.0 |
| **ATR_MinMultiplier** | 0.3 |
| **ATR_BaselineDays** | 20 |
| **EnablePartials** | false |
| **TP1_RR** | 1.0 |
| **TP2_RR** | 2.0 |
| **TP3_RR** | 3.0 |
| **SessionCloseHour** | 17 |
| **SessionCloseMin** | 0 |

> ⚠️ **Nota escala MinSL/MaxSL:** DJI30 usa puntos MT5 donde 1 punto = 0.01 USD. MinSL=6000 equivale a 60 USD de rango mínimo. No confundir con la escala de NAS100.

## Métricas validadas

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 1.708 | **5.469** |
| Max DD | 5.41% | **2.23%** |
| Trades | 125 | 33 |
| Retención OOS | — | **204.5%** (referencia sesión 110) |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

## Plateau confirmado

| Pass | PF IS | DD IS | PF OOS | Trades OOS | BE | MinSL | MaxSL |
|---|---|---|---|---|---|---|---|
| 655 | 1.708 | 5.41% | **5.469** | 33 | 20 | 6000 | 30000 |
| 750 | 1.806 | 5.37% | 5.218 | 32 | 20 | 6000 | 22500 |
| 740 | 1.806 | 5.37% | 5.218 | 32 | 20 | 6000 | 22000 |
| 632 | 1.806 | 5.37% | 5.218 | 32 | 20 | 6000 | 23500 |
| 544 | 1.724 | 5.05% | 5.218 | 30 | 20 | 6000 | 18000 |

Zona robusta: BE=20, MinSL=6000, MaxSL=18000–30000 — todos los vecinos mantienen PF OOS > 5.0.

## Checklist de activación

- [ ] Confirmar nombre exacto del símbolo DJI30 en cuenta FundingPips (US30, DJ30H, DJI30)
- [ ] Verificar VPP con OrderCalcProfit — ContractSize × Point = 5 × 0.01 = $0.05/punto/lote
- [ ] ServerOffsetHours = 2 — confirmar horario broker
- [ ] MagicNumber 202402 — no debe estar en uso por otro EA
- [ ] BE_BufferPct = 20 — valor real del backtest (no 82 como NAS100)
- [ ] MinSL = 6000 / MaxSL = 30000 — escala puntos MT5 DJI30
- [ ] ATR_FilterEnable = true — activo en el EA
- [ ] Lunes y Miércoles desactivados — verificar en parámetros
- [ ] RiskAmountUSD = 12 para cuenta $5,000

## Contexto de selección

- **Cluster:** Tue+Thu+Fri — Pass 655 seleccionado como referencia
- **Plateau SL:** MinSL 6000 fijo, MaxSL 18000–30000 sin degradación (PF OOS > 5.0 en todos)
- **BE plateau:** BE=20 óptimo — valores superiores degradan OOS
- **Nota:** La retención excepcional en OOS indica año 2025 muy favorable para DJI30. Usar como señal de robustez, no de rendimiento esperado
- **Archivos de backtest:** `Backtests/DJI30/IS_DJI30_TueThuFri_v1.xlsx` / `OOS_DJI30_TueThuFri_v1.xlsx`
- **Análisis:** `Analisis-MonteCarlo/NAS100-DJI30/MonteCarlo_NAS100_DJI30_v1.png`
