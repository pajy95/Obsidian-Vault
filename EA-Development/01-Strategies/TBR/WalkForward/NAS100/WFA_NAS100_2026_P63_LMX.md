---
type: walkforward-result
strategy: TBR
asset: NAS100
config: P63 L/M/X
period: 2026-01-05 / 2026-05-06
status: VIABLE
validated: 2026-05-11
---
[[TBR]]
# Walk-Forward NAS100 — P63 L/M/X — 2026

## Resultado

**VIABLE (6/6)** — PF=1.422 | WR=25.0% | Net=+$163 | MaxDD=$83 | n=52

## Detalle mensual

| Mes | n | PF | WR | Net | Cum |
|---|---|---|---|---|---|
| Enero | 12 | 1.527 | 33.3% | +$49 | +$49 |
| Febrero | 11 | 3.368 | 45.5% | +$144 | +$194 |
| Marzo | 13 | 0.822 | 15.4% | -$20 | +$174 |
| Abril | 13 | 0.908 | 15.4% | -$9 | +$165 |
| Mayo | 3 | 0.901 | 0.0% | -$2 | +$163 |

## Lección aprendida

El primer WFA fue inválido por `SessionStart_Hour=15` (debía ser 14). Con H=15 las entradas se producían a las 17:25 server en lugar de 16:25, generando WR=0% y PF=0.727. Corregido el parámetro, el WFA pasó 6/6.

## Archivo de backtest

`Backtests/NAS100/WFA TBR NAS100 2026.xlsx`
