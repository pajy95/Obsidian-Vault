---
type: production-set
strategy: BreakoutNY
asset: XAUUSD
version: v2
status: production
validated: 2026-04-18
broker: FundingPips
---

# Set de Producción — XAUUSD Thu Only v2

## Parámetros MT5

| Parámetro | Valor |
|---|---|
| **EA** | BreakoutNY_v9_FundingPips_XAUUSD |
| **Símbolo** | XAUUSD |
| **Timeframe** | M5 |
| **MagicNumber** | 202409 |
| **RiskAmountUSD** | 12 |
| **ServerOffsetHours** | 2 |
| **BE_BufferPct** | 190 |
| **MinSL_Points** | 5.0 |
| **MaxSL_Points** | 19.0 |
| **FilterMonday** | false |
| **FilterTuesday** | false |
| **FilterWednesday** | false |
| **FilterThursday** | **true** |
| **FilterFriday** | false |
| **ConfirmOnClose** | true |
| **EntryMaxCandle** | 0 |
| **EnablePartials** | false |
| **TP1_RR** | 1.0 |
| **TP2_RR** | 2.0 |
| **TP3_RR** | 3.0 |
| **SessionCloseHour** | 19 |
| **SessionCloseMin** | 0 |

## Métricas validadas (Pass 98)

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 2.111 | **2.453** |
| Max DD | 5.48% | 3.01% |
| Trades | 63 | 35 |
| Retención OOS | — | **116.2%** |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

## Plateau confirmado (ThuOnly)

| Pass | PF IS | DD IS | PF OOS | Trades OOS | BE | MinSL | MaxSL |
|---|---|---|---|---|---|---|---|
| 24 | 2.420 | 4.98% | 2.810 | 18 | 180 | 5.0 | 10.0 |
| **98** | **2.111** | **5.48%** | **2.453** | **35** | **190** | **5.0** | **19.0** |
| 165 | 1.680 | 6.28% | 2.283 | 30 | 120 | 3.0 | 14.5 |
| 283 | 1.678 | 6.82% | 2.071 | 33 | 210 | 4.0 | 16.0 |

Pass 98 seleccionado por mayor número de trades OOS (35) con PF OOS robusto. Zona de plateau: MinSL 3.0–5.0 / MaxSL 10.0–19.0 / BE 120–210.

## Checklist de activación

- [ ] Confirmar símbolo XAUUSD disponible en cuenta FundingPips
- [ ] Verificar ServerOffsetHours = 2 (UTC+2 broker) — ajustar si broker usa UTC+3
- [ ] BE_BufferPct = 190 (valor real del backtest)
- [ ] Confirmar que primera entrada es SOLO el jueves siguiente al inicio
- [ ] Verificar que MagicNumber 202409 no colisiona con otro EA activo
- [ ] RiskAmountUSD = 12 para cuenta $5,000
- [ ] Monitorear primer trade para confirmar hora de entrada 14:50–15:15 UTC

## Contexto de selección

- **Cluster:** Thu Only — único día robusto en todos los regímenes
- **Pasadas analizadas:** 333 IS / 333 OOS (optimización v2)
- **Pass de referencia:** Pass 98 — BE=190, MinSL=5.0, MaxSL=19.0
- **Plateau SL:** MinSL 3.0–5.0 / MaxSL 10.0–19.0 mantienen PF OOS > 2.0
- **Archivos:** `Backtests/XAUUSD/IS_XAUUSD_ThuOnly_v2.xlsx` / `OOS_XAUUSD_ThuOnly_v2.xlsx`
- **Análisis:** `Analisis-MonteCarlo/XAUUSD/MonteCarlo_XAUUSD_ThuOnly_v2.png`
