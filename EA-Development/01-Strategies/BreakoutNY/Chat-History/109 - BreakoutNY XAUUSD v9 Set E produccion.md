---
type: chat-history
date: 2026-04-12
strategy: BreakoutNY
pair: XAUUSD
session_topic: Revisión EA v9 XAUUSD — Set E producción — parámetros IS/OOS
status: backtest-pendiente
tags:
---

# Chat 109 — BreakoutNY XAUUSD v9 Set E Producción

## Contexto de la sesión

Sesión dedicada a revisar el estado del BreakoutNY para XAUUSD. Se analizaron todas las estrategias activas del portfolio y se determinó que BreakoutNY es la más cercana a ser viable y rentable con edge fuerte.

---

## Hallazgos principales

### Estado del portfolio (ranking por viabilidad)

| Estrategia | Estado | Razón |
|---|---|---|
| **BreakoutNY** | Más sólida | IS/OOS completado en múltiples activos. DJI30 PF OOS=2.017 supera IS |
| CTR Pro | Edge real | NDX100 v3.7 WFA completado, v3.8 en construcción |
| ORB XAUUSD | Potencial | PF OOS=1.34 pero DD 6.97% supera límite FP del 5% |
| Donchian | Más verde | Backtest IS baseline ni siquiera corrido |

### Código recibido: BreakoutNY_v9_FundingPips_XAUUSD.mq5

El EA fue entregado por Jose. Es la **v9.0 V3** — versión basada en análisis estadístico de 362 días (Oct 2024 – Mar 2026). Arquitectura sólida con todos los bug fixes históricos aplicados correctamente.

**Bug fixes confirmados en el código:**
- VPP via `OrderCalcProfit` (no `SymbolInfoDouble` — inestable en backtester CFD)
- `slDistance` en precio real (no `× _Point`)
- `ACCOUNT_MARGIN_FREE` (no deprecated `ACCOUNT_FREEMARGIN`)
- `cachedLots` calculado una sola vez al detectar rango
- `ConfirmOnClose` con doble fase: detección en vela N + confirmación en vela N+1
- `FilterXxx`: true=OPERA, false=SALTA

---

## Discrepancia detectada: V3 vs Set E

El código entregado tiene parámetros de la V3 (análisis 362 días), **no** los del Set E validado IS/OOS 2021–2026.

| Parámetro | Código v9 V3 | Set E producción | Estado |
|---|---|---|---|
| `BE_BufferPct` | 100 | **70** | ⚠️ diferente |
| `MinSL_Points` | 5.50 | **4.5** | ⚠️ diferente |
| `MaxSL_Points` | 15.0 | **13.0** | ⚠️ diferente |
| `EntryMaxCandle` | 2 | **0** | ⚠️ diferente |
| `FilterThursday` | true | true | ✅ correcto |
| `FilterFriday` | false | false | ✅ correcto |
| `ConfirmOnClose` | true | true | ✅ correcto |
| `RiskAmountUSD` | 75 | **50** | ⚠️ diferente |

---

## Decisión de la sesión

Ir con **Set E** (IS/OOS validado 2021–2026) en lugar de los parámetros V3.

Razón: Set E tiene validación IS/OOS completa con desglose anual. Los parámetros V3 se basan en 362 días solamente (Oct 2024–Mar 2026), período que coincide con el régimen alcista fuerte de XAUUSD 2025 — potencialmente sobre-optimizado a ese régimen.

---

## Parámetros Set E — configurar manualmente en MetaEditor

```
=== HORARIO ===
ServerOffsetHours  = 2
EntryWindowEnd_Min = 15

=== RIESGO ===
RiskAmountUSD      = 50

=== OBJETIVOS ===
TP1_RR             = 1.0
TP2_RR             = 2.0
TP3_RR             = 3.0

=== CIERRES PARCIALES ===
EnablePartials     = false
TP1_ClosePct       = 40
TP2_ClosePct       = 40

=== BREAKEVEN ===
BE_BufferPct       = 70

=== FILTROS DE RANGO ===
MinSL_Points       = 4.5
MaxSL_Points       = 13.0

=== FILTROS DE DÍA ===
FilterMonday       = false
FilterTuesday      = false
FilterWednesday    = false
FilterThursday     = true
FilterFriday       = false
ConfirmOnClose     = true

=== FILTRO DE VELA ===
EntryMaxCandle     = 0

=== CONFIG ===
MagicNumber        = 202409
```

---

## Backtests pendientes

Jose va a correr los backtests y reportar los resultados en la próxima sesión.

### Run 1 — IS (In-Sample)
- Período: `2021.01.01 → 2024.12.31`
- Modo: Every tick (ticks reales)
- Depósito inicial: $5,000

### Run 2 — OOS (Out-of-Sample)
- Período: `2025.01.01 → 2026.04.11`
- Mismos parámetros exactos
- Depósito inicial: $5,000

### Métricas a reportar
- Net Profit, Profit Factor, Max DD%, Sharpe Ratio
- Total trades
- Desglose por año (especialmente 2022 y 2023 — años difíciles)
- Screenshot equity curve si es posible

---

## Métricas de referencia (análisis previo chat 108)

### Set E IS/OOS referencia

| Período | PF | DD | Trades |
|---|---|---|---|
| IS 2021–2024 | 1.22 | marginal | — |
| OOS 2025–2026 | 2.66 | 2.97% | 46 |

- Jueves: $924 de $1,217 OOS totales (75.9% del P&L)
- Viernes: descartado — PF=0.35 en IS 2022 (riesgo de régimen)

---

## Set G — pendiente para sesión futura

Candidato superior identificado en análisis exhaustivo de 3,175 pasadas. **No tiene backtest IS 2021–2026 con ConfirmOnClose=true y EntryMaxCandle=0 activos.**

```
BE_BufferPct    = 260
MinSL_Points    = 4.5
MaxSL_Points    = 16.5
FilterThursday  = true  (todos los demás = false)
ConfirmOnClose  = true
EntryMaxCandle  = 0
RiskAmountUSD   = 50
```

Acción: correr IS 2021–2026 + OOS 2025–2026 con estos parámetros. Si PF IS > 1.5 y DD < 5%, reemplaza al Set E como set de producción.

---

## Próximos pasos

1. Jose corre backtest IS + OOS del Set E con los parámetros exactos de arriba
2. Reportar métricas aquí en la siguiente sesión
3. Con resultados en mano: decidir activar Set E en demo (próximo jueves)
4. Correr Set G en paralelo para comparar

---

