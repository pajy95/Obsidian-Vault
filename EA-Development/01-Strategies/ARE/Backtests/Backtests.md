---
type: backtests-index
strategy: ARE
updated: 2026-05-01
---

# ARE — Backtests

## Plan de validación

| Fase | Período | Activo | TF | Status |
|------|---------|--------|----|--------|
| IS | 2015–2021 | EURUSD | M15 | ⏳ Pendiente |
| IS | 2015–2021 | XAUUSD | M15 | ⏳ Pendiente |
| IS | 2015–2021 | NAS100 | M15 | ⏳ Pendiente |
| IS | 2015–2021 | GBPUSD | M15 | ⏳ Pendiente |
| OOS | 2022–2024 | EURUSD | M15 | ⏳ Pendiente |
| OOS | 2022–2024 | XAUUSD | M15 | ⏳ Pendiente |
| OOS | 2022–2024 | NAS100 | M15 | ⏳ Pendiente |
| OOS | 2022–2024 | GBPUSD | M15 | ⏳ Pendiente |

## Criterios de aprobación

| Métrica | IS mínimo | OOS mínimo | Descarte |
|---------|-----------|------------|---------|
| Profit Factor | > 1.5 | > 1.3 | < 1.2 |
| Max Drawdown | < 20% | < 25% | > 30% |
| Sharpe Ratio | > 1.0 | > 0.8 | — |
| Trades | > 500 | > 200 | < 150 |
| Degradación PF | — | < 30% | > 40% |

## Subcarpetas

- [[EURUSD/]]
- [[XAUUSD/]]
- [[NAS100/]]
- [[GBPUSD/]]
