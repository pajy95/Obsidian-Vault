---
type: production-set
strategy: BreakoutNY
asset: NAS100
version: v1
status: production
validated: 2026-04-18
broker: FundingPips
---

# Set de Producción — NAS100 Mon+Tue+Fri v1

## Parámetros MT5

| Parámetro | Valor |
|---|---|
| **EA** | BreakoutNY_NAS100_FP |
| **Símbolo** | NAS100 |
| **Timeframe** | M5 |
| **MagicNumber** | 202401 |
| **RiskAmountUSD** | 12 |
| **ServerOffsetHours** | 2 |
| **BE_BufferPct** | 82 |
| **MinSL_Points** | 35 |
| **MaxSL_Points** | 120 |
| **FilterMonday** | **true** |
| **FilterTuesday** | **true** |
| **FilterWednesday** | false |
| **FilterThursday** | false |
| **FilterFriday** | **true** |
| **FilterShorts** | **true** — SOLO LONGS |
| **ConfirmOnClose** | true |
| **EntryMaxCandle** | 0 |
| **EnablePartials** | false |
| **TP1_RR** | 1.0 |
| **TP2_RR** | 2.0 |
| **TP3_RR** | 3.0 |
| **SessionCloseHour** | 17 |
| **SessionCloseMin** | 0 |

## Métricas validadas (Pass 1220)

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 1.678 | **1.720** |
| Max DD | 8.22% | 4.65% |
| Trades | 229 | 68 |
| Profit OOS | — | **$944** |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

## Plateau confirmado (MonTueFri)

| Pass | PF IS | DD IS | PF OOS | DD OOS | Trades OOS | BE | MinSL | MaxSL |
|---|---|---|---|---|---|---|---|---|
| **1220** | **1.678** | **8.22%** | **1.720** | **4.65%** | **68** | **82** | **35** | **120** |
| 1582 | 1.678 | 8.22% | 1.700 | 4.67% | 67 | 82 | 35 | 118 |
| 1516 | 1.671 | 8.03% | 1.699 | 4.62% | 65 | 21 | 39 | 120 |
| 403 | 1.543 | 7.78% | 1.689 | 4.79% | 42 | 42 | 59 | 118 |

Pass 1220 seleccionado por mayor profit OOS en $ con plateau robusto. Zona estable: BE 21–82, MinSL 35–59, MaxSL 118–120.

## Checklist de activación

- [ ] Confirmar **FilterShorts = true** — error crítico documentado en WF 2026-04-07 (4 shorts ejecutados por este parámetro en false)
- [ ] Verificar símbolo NAS100 (puede ser NAS100m, US100, USTEC según broker)
- [ ] ServerOffsetHours = 2 — confirmar horario broker
- [ ] MagicNumber 202401 — no debe estar en uso por otro EA
- [ ] BE_BufferPct = 82, MinSL = 35, MaxSL = 120
- [ ] Miércoles y Jueves desactivados — confirmar en parámetros
- [ ] RiskAmountUSD = 12 para cuenta $5,000

## Contexto de selección

- **Cluster:** Mon+Tue+Fri — identificado entre 3,477 pasadas IS
- **Pass de referencia:** Pass 1220 — mayor profit OOS ($944) del cluster
- **Plateau:** BE 21–82, MinSL 35–59, MaxSL 118–120 — todos con PF OOS > 1.69
- **Key insight:** Solo longs — FilterShorts=true obligatorio. Shorts destruyen performance
- **Advertencia WF:** 2026-04-07 se detectaron 4 shorts por FilterShorts=false
- **Archivos:** `Backtests/NAS100/IS_NAS100_MonTueFri_v1.xlsx` / `OOS_NAS100_MonTueFri_v1.xlsx`
- **Análisis:** `Analisis-MonteCarlo/NAS100-DJI30/MonteCarlo_NAS100_DJI30_v1.png`
