---
type: montecarlo-result
strategy: TBR
asset: NAS100
config: P63 L/M/X
n_simulaciones: 10000
pool: OOS 2025 (145) + WFA 2026 (52) = 197 trades
account: 5000
validated: 2026-05-11
status: VIABLE
---

# Monte Carlo NAS100 — P63 L/M/X

## Pool de trades
- EV por trade: +$3.60
- Std: $23.07
- WR real: 25.9%

## Escenario 1 — Periodo tipo OOS (145 trades, ~1 año)

| Percentil | Net Profit | MaxDD | MaxDD % |
|---|---|---|---|
| P5 (pesimista) | **+$73** | $90 | 1.8% |
| P50 (mediana) | +$519 | $151 | 3.0% |
| P95 (optimista) | +$988 | $282 | 5.6% |

- P(Net > 0): **97.3%**
- P(DD ≥ 10% / ruin): **0.05%**

## Escenario 2 — Periodo tipo WFA (52 trades, ~4 meses)

| Percentil | Net Profit | MaxDD | MaxDD % |
|---|---|---|---|
| P5 (pesimista) | -$79 | $57 | 1.1% |
| P50 (mediana) | +$178 | $103 | 2.1% |
| P95 (optimista) | +$466 | $202 | 4.0% |

- P(Net > 0): **86.7%**
- P(DD ≥ 10% / ruin): **0.00%**

## Rachas de pérdidas

| Percentil | Racha máx consecutiva |
|---|---|
| P50 (típico) | 12 trades |
| P95 (extremo) | 19 trades |
| P99 (peor caso) | 24 trades |

Pérdida estimada en racha P95 (19 SL seguidos): ~$192 (3.8% cuenta)

## Veredicto — VIABLE (4/4)

| Criterio | Estado |
|---|---|
| P(ruin DD≥10%) < 5% | 0.05% ✅ |
| P(Net>0) > 75% | 97.3% ✅ |
| P5 Net > -10% cuenta | +$73 ✅ |
| P95 MaxDD < 10% | 5.6% ✅ |
