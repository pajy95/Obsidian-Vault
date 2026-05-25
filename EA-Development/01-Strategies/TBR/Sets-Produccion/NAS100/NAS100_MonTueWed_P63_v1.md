---
type: production-set
strategy: TBR
asset: NAS100
version: v1
pass: P63
status: demo
validated: 2026-05-11
broker: FundingPips
pipeline: IS → OOS → WFA → Demo
---

# Set de Producción — NAS100 Lun+Mar+Mié P63 v1

## Parámetros MT5

| Parámetro | Valor |
|---|---|
| **EA** | TBR_v1.0b.mq5 |
| **Símbolo** | NAS100 |
| **Timeframe** | M5 |
| **MagicNumber** | 202501 |
| **RiskAmountUSD** | 12.5 |
| **RangeCandlesCount** | 2 |
| **SessionStart_Hour** | **14** ← crítico, no 15 |
| **SessionStart_Min** | 15 |
| **SessionEnd_Hour** | 18 |
| **SessionEnd_Min** | 0 |
| **ServerOffsetHours** | 2 |
| **RR** | 4.0 |
| **TradeMonday** | true |
| **TradeTuesday** | true |
| **TradeWednesday** | true |
| **TradeThursday** | **false** |
| **TradeFriday** | **false** |
| **UseBreakeven** | false |
| **GapFilter_Enable** | false |
| **CloseAfterHours_Enable** | true |
| **MaxHoldHours** | 4 |

## Resultados validados

| Período | n | PF | WR | Net | MaxDD |
|---|---|---|---|---|---|
| IS 2022 | 155 | 0.966 | 19.4% | -$44 | — |
| IS 2023 | 154 | 1.544 | 26.6% | +$630 | — |
| IS 2024 | 116 | 1.290 | 23.3% | +$261 | — |
| **IS 2022-2024** | **425** | **1.252** | **23.1%** | **+$847** | **$331** |
| **OOS 2025** | **145** | **1.498** | **26.2%** | **+$524** | **$128** |
| **WFA 2026** | **52** | **1.422** | **25.0%** | **+$163** | **$83** |

## Criterios WFA — 6/6 VIABLE

| Criterio | Umbral | Resultado |
|---|---|---|
| PF ≥ 1.20 | ≥ 1.20 | 1.422 ✅ |
| WR ≥ 20% | ≥ 20% | 25.0% ✅ |
| Trades ≥ 20 | ≥ 20 | 52 ✅ |
| Net > 0 | > 0 | +$163 ✅ |
| PF_WF / PF_OOS ≥ 0.50 | ≥ 0.50 | 0.950 ✅ |

## Rendimiento por día (OOS 2025)

| Día | PF | WR | Decisión |
|---|---|---|---|
| Lunes | 1.607 | 27.7% | Activo |
| Martes | 1.559 | 25.5% | Activo |
| Miércoles | 1.589 | 27.7% | Activo |
| Jueves | 1.068 | 21.3% | **Desactivado** |
| Viernes | 0.808 | 17.0% | **Desactivado** |

## Advertencia crítica

**SessionStart_Hour = 14** (no 15). Un WFA inicial con H=15 produjo WR=0% y PF=0.727 por operar 1 hora tarde. Verificar siempre que las entradas aparezcan a las **16:25 server time** en el reporte MT5.

## Checklist de activación

- [ ] SessionStart_Hour = 14 (verificar entradas a 16:25 server)
- [ ] TradeThursday = false, TradeFriday = false
- [ ] UseBreakeven = false
- [ ] RiskAmountUSD = 12.5 para cuenta $5,000
- [ ] MagicNumber 202501 — no en uso por otro EA
- [ ] ServerOffsetHours = 2 — confirmar horario broker

## Archivos de referencia

- `Backtests/NAS100/IS tbr nas100 v1b pass63 no JV.xlsx`
- `Backtests/NAS100/OOS tbr nas100 v1b pass63 no JV.xlsx`
- `Backtests/NAS100/WFA TBR NAS100 2026.xlsx`
- `Optimizacion/NAS100/TBR B V1.xml`
- `Optimizacion/NAS100/TBR B V1 be.xml`
- `Decisions/NAS100/TBR_NAS100_v1b_Optimization_Analysis.md`
