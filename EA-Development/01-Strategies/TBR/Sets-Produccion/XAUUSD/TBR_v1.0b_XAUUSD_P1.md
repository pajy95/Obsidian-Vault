---
type: production-set
strategy: TBR
asset: XAUUSD
version: v1.0b
pass: P1
pass_num: 7129
status: validado-IS-OOS
validated: 2026-05-11
broker: FundingPips
pipeline: IS → OOS → WFA (pendiente)
---

# Set de Producción — XAUUSD P1 v1.0b

## Parámetros MT5

| Parámetro | Valor | Nota |
|-----------|-------|------|
| **EA** | TBR_v1.0b.mq5 | |
| **Símbolo** | XAUUSD | |
| **Timeframe** | M5 | |
| **MagicNumber** | 202502 | No reutilizar |
| **TradeDirection** | 0 (DIR_BOTH) | Long + Short activos |
| **EntryMode** | 1 (MODE_BREAKOUT) | Órdenes stop pendientes |
| **RangeCandlesCount** | 3 | Velas M5 para formar el rango |
| **SessionStart_Hour** | **14** | UTC — crítico, no cambiar |
| **SessionStart_Min** | **45** | Rango inicia a las 16:45 server |
| **SessionEnd_Hour** | 18 | UTC = 20:00 server |
| **SessionEnd_Min** | 0 | |
| **ServerOffsetHours** | 2 | FundingPips UTC+2 |
| **RR** | **3.6** | |
| **RiskAmountUSD** | 12.5 | Para cuenta $5,000 |
| **SL_AtRangeExtreme** | true | SL en extremo opuesto del rango |
| **StopLevel_ExtraPoints** | 10 | Buffer sobre stop level del broker |
| **UseBreakeven** | false | Ineficaz en XAU (optimización confirma) |
| **BE_TriggerRR** | 1.0 | (inactivo) |
| **BE_BufferPct** | 2.0 | (inactivo) |
| **CloseAfterHours_Enable** | true | |
| **MaxHoldHours** | 4 | Session end (18 UTC) cierra primero |
| **SpreadFilter_Enable** | false | |
| **GapFilter_Enable** | false | |
| **TradeMonday** | true | |
| **TradeTuesday** | true | |
| **TradeWednesday** | true | |
| **TradeThursday** | true | |
| **TradeFriday** | true | |
| **EnableCSV** | true | |
| **EnableLog** | true | |
| **VIS_Enable** | true | |

## Mecánica de entrada

El EA forma el rango con las primeras 3 velas M5 de la sesión (14:45–15:00 UTC / 16:45–17:00 server). Coloca un **buy stop** encima del máximo y un **sell stop** debajo del mínimo. La primera orden que se activa abre el trade; la otra se cancela. Cierre por SL, TP, o session end (20:00 server).

## Resultados validados

| Período | n | PF real | WR (TP+SL) | Net | MaxDD |
|---------|---|---------|------------|-----|-------|
| **IS 2022-2024** | **770** | **1.214** | 11.9% | **+$831** | **8.15%** |
| **OOS 2025** | **254** | **1.606** | 14.7% | **+$780** | **1.80%** |
| WFA 2026 | 91 | 0.849 | 5.5% | -$136 | 8.73% |

> **Nota técnica:** El PF "real" incluye el P&L efectivo de los timeout trades (cierres de sesión).
> El motor de rentabilidad son los timeouts: IS timeout net = +$1,718 / OOS timeout net = +$998.
> El PF(TP+SL) puro es ~0.49 — el edge NO está en alcanzar el TP sino en la dirección del breakout.

## Veredicto IS/OOS — VIABLE (5/5)

| Criterio | Umbral | OOS 2025 |
|----------|--------|----------|
| PF OOS (real) ≥ 1.40 | ≥ 1.40 | 1.606 ✅ |
| Max DD OOS ≤ 10% | ≤ 10% | 1.80% ✅ |
| Trades OOS ≥ 30 | ≥ 30 | 254 ✅ |
| Rendimiento OOS/IS ≥ 50% | ≥ 50% | 132.3% ✅ |
| Net OOS > 0 | > 0 | +$780 ✅ |

## WFA 2026 — Pendiente de confirmación

WFA 2026 falla (PF=0.849), pero **dentro del rango histórico** de variación:
- PF mínimo histórico IS/OOS: 0.684 (2024Q2)
- PF promedio WFA 2026 (trimestral): 0.744
- 4/16 trimestres históricos también fueron hostiles (25%)

**Patrón 2026:** LONG roto (PF=0.374), SHORT funciona (PF=1.438).
Posible causa: incertidumbre macro/política 2026 genera reversiones en breakouts alcistas del oro.

Acción: esperar Q3 2026 para confirmar si es régimen transitorio o cambio estructural.

## Rendimiento por día (OOS 2025)

| Día | Net | WR | Estado |
|-----|-----|----|--------|
| Lunes | +$90 | 9.7% | Activo |
| Martes | +$211 | 12.1% | Activo |
| Miércoles | +$73 | 18.9% | Activo |
| Jueves | +$340 | 25.8% | Activo |
| Viernes | +$65 | 7.9% | Activo |

## Rendimiento por dirección (OOS 2025)

| Dirección | PF | WR | Net |
|-----------|----|----|-----|
| LONG | 1.794 | 16.9% | +$486 |
| SHORT | 1.435 | 12.6% | +$294 |

## Advertencias críticas

1. **SessionStart_Hour = 14 UTC** — FundingPips UTC+2 → entries a las 16:45 server. Verificar en reporte MT5 que las entradas aparecen en torno a las **17:00–17:10 server** (tras formarse el rango de 3 velas).
2. **TradeDirection = 0 (DIR_BOTH)** — el EA abre longs y shorts. No activar DIR_BUY solo.
3. **UseBreakeven = false** — la optimización sobre 2,744 passes mostró que BE nunca es óptimo en XAU.
4. **MagicNumber = 202502** — no reutilizar si se añaden más instancias.

## Checklist de activación

- [ ] Símbolo: XAUUSD M5
- [ ] TradeDirection = DIR_BOTH (0)
- [ ] EntryMode = MODE_BREAKOUT (1)
- [ ] SessionStart_Hour = 14 (verificar entradas ~17:00 server)
- [ ] RR = 3.6
- [ ] UseBreakeven = false
- [ ] Todos los días activos (L-V)
- [ ] RiskAmountUSD = 12.5 para cuenta $5,000
- [ ] MagicNumber = 202502 — confirmar no está en uso
- [ ] ServerOffsetHours = 2 — confirmar horario broker

## Archivos de referencia

- `Backtests/XAUUSD/IS_TBR_XAUUSD_P1_2022-2024.xlsx`
- `Backtests/XAUUSD/OOS_TBR_XAUUSD_P1_2025.xlsx`
- `Backtests/XAUUSD/WFA_TBR_XAUUSD_P1_2026.xlsx`
- `Optimizacion/XAUUSD/TBR_V1B_OP_XAUUSD_M5.xml`
- `scripts/tbr_xau_p2_analisis.py`
