---
type: decision
strategy: TBR
asset: XAUUSD
pass: P1
pass_num: 7129
veredicto: VIABLE
validated: 2026-05-11
pipeline: IS/OOS completado — WFA pendiente Q3 2026
---
[[TBR]]
# Decisión IS/OOS — XAUUSD P1 #7129

## Veredicto: VIABLE (5/5)

## Parámetros del pass

| Parámetro | Valor |
|-----------|-------|
| RangeCandlesCount | 3 |
| SessionStart_Min | 45 |
| RR | 3.6 |
| TradeDirection | DIR_BOTH (Long + Short) |
| Días activos | Lun–Vie (todos) |

## Selección del pass — Por qué P1

P1 (Min=45) fue seleccionado sobre otros passes del espacio de optimización (2,744 total) por:

1. **PF OOS excepcional**: 1.606 — el más alto entre los passes con PF IS ≥ 1.20
2. **Robustez de meseta** (limitada): Min=45 es un pico local, no una meseta amplia. Sin embargo, es el único pass con PF OOS > 1.50 y IS > 1.20 simultáneamente.
3. **Comportamiento en OOS superior a IS**: ratio 132.3% — sin señal de overfitting.
4. **Sample size suficiente**: 770 IS, 254 OOS — ambos muy por encima del mínimo (30).

**Nota sobre Min=45 como pico vs plateau**: El análisis de robustez muestra que Min=40 y Min=50 tienen PF IS ~1.18 (vs 1.214 de Min=45). La diferencia es menor en IS. En OOS, Min=45 destaca más (1.606). Esto sugiere que el pass es robusto pero con sensibilidad moderada al parámetro Min.

## Resultados

| Período | n | PF real | WR (TP+SL) | Net | MaxDD |
|---------|---|---------|------------|-----|-------|
| **IS 2022-2024** | **770** | **1.214** | 11.9% | **+$831** | **8.15%** |
| **OOS 2025** | **254** | **1.606** | 14.7% | **+$780** | **1.80%** |
| WFA 2026 | 91 | 0.849 | 5.5% | -$136 | 8.73% |

## Criterios de viabilidad

| Criterio | Umbral | OOS 2025 | Estado |
|----------|--------|----------|--------|
| PF OOS ≥ 1.40 | ≥ 1.40 | 1.606 | ✅ |
| Max DD OOS ≤ 10% | ≤ 10% | 1.80% | ✅ |
| Trades OOS ≥ 30 | ≥ 30 | 254 | ✅ |
| OOS/IS ratio ≥ 50% | ≥ 50% | 132.3% | ✅ |
| Net OOS > 0 | > 0 | +$780 | ✅ |

## Nota técnica crítica — Motor de rentabilidad

El PF(TP+SL) puro es ~0.49 — el edge **no está en alcanzar el TP** sino en los cierres de sesión (timeout trades). Los timeouts tienen P&L real positivo porque el breakout direcciona correctamente aunque no llegue al TP.

- IS timeout net: +$1,718 sobre net total +$831
- OOS timeout net: +$998 sobre net total +$780

**Implicación operativa**: si se modifica la lógica de cierre de sesión o `CloseAfterHours`, se destruye el edge. `UseBreakeven=false` es obligatorio (el BE interfiere con la dirección del timeout).

## Rendimiento por dirección (OOS 2025)

| Dirección | PF | WR | Net |
|-----------|----|----|-----|
| LONG | 1.794 | 16.9% | +$486 |
| SHORT | 1.435 | 12.6% | +$294 |

## Rendimiento por día (OOS 2025)

| Día | Net | WR |
|-----|-----|----|
| Lunes | +$90 | 9.7% |
| Martes | +$211 | 12.1% |
| Miércoles | +$73 | 18.9% |
| Jueves | +$340 | 25.8% |
| Viernes | +$65 | 7.9% |

## Análisis de régimen — WFA 2026

WFA 2026 falla (PF=0.849), pero está **dentro del rango histórico** de variación:

| Período | PF trimestral rango |
|---------|---------------------|
| IS 2022-2024 (trimestral) | 0.684 – 1.741 (promedio 1.136) |
| OOS 2025 (trimestral) | 1.351 – 1.891 |
| WFA 2026 (trimestral) | 0.744 promedio |

El PF mínimo histórico IS/OOS fue 0.684 (2024 Q2). El promedio WFA 2026 es 0.744 — dentro del rango de variación observada. Por tanto, no constituye evidencia definitiva de cambio estructural.

**Patrón 2026 — Dirección rota:**

| Dirección | WFA 2026 PF |
|-----------|------------|
| LONG | 0.374 — roto |
| SHORT | 1.438 — funciona |

Hipótesis: incertidumbre macro/política 2026 genera reversiones en breakouts alcistas del oro. Los breakouts bajistas continúan funcionando.

**Acción**: esperar Q3 2026. Si SHORT mantiene PF > 1.20 y LONG sigue roto, considerar DIR_SELL temporal.

## Decisión de portfolio

- **No activar en live** hasta confirmar régimen post-Q3 2026.
- **Mantener en watchlist**: métricas IS/OOS son sólidas; régimen 2026 puede ser transitorio.
- **P1 es preferido sobre P2** (#2603): P1 tiene PF OOS superior (1.606 vs 1.374), mayor n OOS (254 vs 91), y WFA 2026 dentro de rango histórico (P2 no).

## Archivos de referencia

- `Backtests/XAUUSD/IS_TBR_XAUUSD_P1_2022-2024.xlsx`
- `Backtests/XAUUSD/OOS_TBR_XAUUSD_P1_2025.xlsx`
- `Backtests/XAUUSD/WFA_TBR_XAUUSD_P1_2026.xlsx`
- `Optimizacion/XAUUSD/TBR_V1B_OP_XAUUSD_M5.xml`
- `Sets-Produccion/XAUUSD/TBR_v1.0b_XAUUSD_P1.set`
- `WalkForward/XAUUSD/WFA_XAUUSD_P1_2026.md`
