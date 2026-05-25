---
type: production-set
strategy: TBR
asset: XAUUSD
version: v1
pass: P2-BE-NoLunes
status: validado — pendiente demo
validated: 2026-05-12
broker: FundingPips
pipeline: IS → OOS → WFA → Robustez → MC → Demo
---

# Set de Producción — XAUUSD P2 BE sin Lunes v1

## Parámetros MT5

| Parámetro | Valor |
|---|---|
| **EA** | TBR_v1.0b.mq5 |
| **Símbolo** | XAUUSD |
| **Timeframe** | M5 |
| **MagicNumber** | 202502 |
| **RiskAmountUSD** | 12.5 |
| **TradeDirection** | 0 (DIR_BOTH = Long + Short) |
| **EntryMode** | 1 (BREAKOUT) |
| **RangeCandlesCount** | 3 |
| **SessionStart_Hour** | **14** ← crítico, no 15 |
| **SessionStart_Min** | 45 |
| **SessionEnd_Hour** | 17 |
| **SessionEnd_Min** | 0 |
| **ServerOffsetHours** | 2 |
| **RR** | 3.6 |
| **UseBreakeven** | true |
| **BE_TriggerRR** | 0.75 |
| **TradeMonday** | **false** ← filtro clave |
| **TradeTuesday** | true |
| **TradeWednesday** | true |
| **TradeThursday** | true |
| **TradeFriday** | true |
| **GapFilter_Enable** | false |
| **CloseAfterHours_Enable** | true |
| **MaxHoldHours** | 4 |

## Resultados validados

| Período | n | PF | WR | Net | DD% |
|---|---|---|---|---|---|
| **IS 2022–2024** | **617** | **1.294** | **50.2%** | **+$896** | **5.44%** |
| **OOS 2025** | **204** | **1.663** | **49.5%** | **+$690** | **1.89%** |
| **WFA 2026** | **72** | **1.030** | **41.7%** | **+$22** | **6.43%** |

### Desglose OOS por día (2025)

| Día | PF | WR | Net |
|-----|----|----|-----|
| Martes | 1.768 | 48.1% | +$212 |
| Miércoles | 1.266 | 48.0% | +$73 |
| Jueves | 2.838 | 58.8% | +$340 |
| Viernes | 1.213 | 43.1% | +$65 |

Jueves es el día más fuerte (PF=2.838 OOS).

## Estudios de Robustez

### Sensibilidad SessionEnd

| Delta | OOS PF | |
|-------|--------|-|
| SE -15 min | 0.977 | [!] FRAGIL — cae cerca de 1.0 |
| Baseline | 1.663 | [OK] |

**Alerta: esta estrategia es sensible a SessionEnd.** No mover SessionEnd_Hour=17 sin re-backtest.

### Hold Time (sesión-cierre = único bucket con edge)

Bucket dominante: trades >2.5h (cierre por sesión). Fast trades (<1h) destruyen valor.

## Monte Carlo (OOS+WFA, n=276, 5000 iter)

| Métrica | Valor | Límite | |
|---------|-------|--------|-|
| DD p95 | 7.5% | ≤15% | [OK] |
| P(DD>10%) | 0.6% | ≤20% | [OK] |
| Equity p5 | +1.8% | >0% | [OK] |
| P(equity neg.) | ~0% | — | [OK] |

**Veredicto MC: [MC OK]**

## Notas técnicas críticas

- **Bidireccional** (Long + Short). TradeDirection=0 = DIR_BOTH en el EA.
- **VPP XAUUSD = $100/punto/lote estándar** — el EA usa OrderCalcProfit(), no TickValue.
- **TradeMonday=false** es el filtro diferenciador. Sin este filtro, WFA cae de 1.030 → 0.848.
- **SessionEnd=17** es parámetro crítico. Sensibilidad confirmada: -15 min colapsa OOS a 0.977.
- **WFA 2026 marginal** (PF=1.030, Net=+$22) — régimen macro hostil en 2026. Tendencia a mejorar esperada fuera de régimen extremo.

## Advertencias críticas

1. **SessionStart_Hour = 14** (no 15). Verificar entradas a las 16:45 server time.
2. **TradeDirection = 0** — confirmar que el EA abre tanto LONG como SHORT.
3. **TradeMonday = false** — verificar que no opera los lunes.
4. **MagicNumber = 202502** — ver `CONTROL_MagicNumbers.md`.

## Checklist de activación

- [ ] SessionStart_Hour = 14 (verificar entradas a 16:45 server)
- [ ] TradeDirection = 0 (BOTH — Long y Short)
- [ ] EntryMode = 1 (BREAKOUT)
- [ ] RangeCandlesCount = 3
- [ ] SessionEnd_Hour = 17 (no modificar sin re-backtest)
- [ ] UseBreakeven = true, BE_TriggerRR = 0.75
- [ ] RR = 3.6
- [ ] TradeMonday = false
- [ ] RiskAmountUSD = 12.5 para cuenta $5,000
- [ ] MagicNumber = 202502 — verificar no esté activo en otra terminal
- [ ] ServerOffsetHours = 2

## Archivos de referencia

- `Backtests/XAUUSD/is_tbr_xauusd_p2_2022-2024_be_noL.xlsx` — IS (n=617, PF=1.294)
- `Backtests/XAUUSD/OOS_TBR_XAU_P2_2025_be_NOL.xlsx` — OOS (n=204, PF=1.663)
- `Backtests/XAUUSD/WFA_TBR_XAU_be_noL_2026.xlsx` — WFA (n=72, PF=1.030)
- `Optimizacion/XAUUSD/OP TBR XAU M5 BE.xml` — XML optimización con BE
- `Sets-Produccion/CONTROL_MagicNumbers.md` — registry de magic numbers
