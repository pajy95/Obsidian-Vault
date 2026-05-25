# TBR NAS100 M5 — Análisis IS v1 (2018–2021)
> Fecha: 2026-05-09 | Autor: Claude Code | Veredicto: NO VIABLE (configuraciones actuales)

---

## Parámetros evaluados

| Parámetro | Test 1 | Test 2 | Test 3 |
|-----------|--------|--------|--------|
| SessionStart | 14:50 UTC | 14:50 UTC | 14:30 UTC |
| SessionEnd | 23:00 UTC | 23:00 UTC | 17:00 UTC |
| RangeCandlesCount | 3 | 3 | 3 |
| TradeDirection | BOTH | BOTH | BOTH |
| EntryMode | CONFIRM | CONFIRM | CONFIRM |
| RR | 2.0 | 2.0 | 2.0 |
| RiskPct | 0.5% | 0.5% | 0.5% |
| UseBreakeven | true (50% TP, 5% buffer) | true | true |
| Diferencia clave | Sesión extendida hasta noche | Sesión extendida hasta noche | Sesión corta NY estricta |

---

## Resultados comparados

| Métrica | Test 1 | Test 2 | Test 3 | Umbral |
|---------|--------|--------|--------|--------|
| Profit Factor | **0.93** | **1.04** | **0.99** | ≥ 1.40 |
| Profit Neto | -$2,386 | +$1,122 | -$253 | positivo |
| Gross Win | $30,507 | $30,342 | $22,684 | — |
| Gross Loss | $32,893 | $29,220 | $22,937 | — |
| Win Rate | 46.5% | 51.0% | 50.6% | — |
| Avg Win | $106.67 | $95.12 | $65.18 | — |
| Avg Loss | -$99.98 | -$95.49 | -$67.46 | — |
| RR Real | **1.07x** | **1.00x** | **0.97x** | — |
| Max DD % | **117.8%** | **89.6%** | **58.6%** | ≤ 10% |
| Total Trades | 615 | 625 | 688 | ≥ 30 |

**Veredicto: NO VIABLE — ninguna configuración supera el PF mínimo de 1.40.**

---

## Problema 1: Riesgo real vs riesgo configurado

El EA usa `RiskPct = 0.5%` del balance = ~$25 por trade sobre $5,000 iniciales.
**El riesgo real observado es entre 2.7x y 3.8x el riesgo teórico:**

| | Test 1 | Test 2 | Test 3 |
|-|--------|--------|--------|
| Riesgo teórico/trade | ~$25 | ~$25 | ~$25 |
| Avg Loss real | **$99.98** | **$95.49** | **$67.46** |
| Múltiplo real | **4.0x** | **3.8x** | **2.7x** |
| Max pérdida 1 trade | **$987** | **$1,218** | **$719** |
| Trades con loss > 2x | 33.8% | 36.0% | 26.9% |
| Trades con loss > 4x | 14.5% | 12.6% | 8.9% |

### Causa raíz: el SL no respeta el riesgo % configurado

El SL se calcula como `RangeLow - stopBuffer` (extremo del rango), independientemente del riesgo.
Si el rango del día es grande, el SL queda lejos y el lotaje sube. Pero el compounding del balance
hace que en períodos de balance bajo, el lotaje se reduzca — generando asimetría de riesgo.

**El EA necesita una lógica de riesgo fijo en USD (`RiskAmountUSD`) en lugar de `RiskPct`.**
Esto elimina la variabilidad del lotaje por balance y alinea con el estándar del portfolio.

---

## Problema 2: Tiempo de retención — posiciones sin cierre de sesión

Con `SessionEnd = 23:00 UTC` (Tests 1 y 2), el EA permite retención de hasta **596 horas** (24.8 días).
Con `SessionEnd = 17:00 UTC` (Test 3), la retención máxima baja a **130 minutos** — coherente con intraday.

| Retención | Test 1 | Test 2 | Test 3 |
|-----------|--------|--------|--------|
| Mediana | 239 min (4h) | 135 min (2.25h) | 105 min (1.75h) |
| p90 | 4,268 min (71h) | 1,454 min (24h) | 130 min |
| Max | **35,641 min (24.8 días)** | **29,733 min (20.6 días)** | **130 min** |
| Trades > 17h overnight | 27.5% | 17.3% | 0% |
| Trades > 24h multi-día | 19.2% | 10.9% | 0% |

### Causa raíz: `CloseAfterHours_Enable = false` + sesión nocturna

En Tests 1 y 2, `SessionEnd = 23:00 UTC` permite que una posición abierta a las 15:00 UTC
no cierre en toda la noche, el día siguiente, y días posteriores si el precio nunca toca SL/TP.
Esto genera:
- Retención overnight (swap/rollover no modelado correctamente en backtester)
- El backtester MT5 puede ejecutar SL/TP en gaps — no representativo de mercado real
- Resultados contaminados por movimientos nocturnos post-sesión NY

**El Test 3 (SessionEnd = 17:00 UTC) resuelve el problema de retención pero sigue siendo NO VIABLE por PF.**

---

## Análisis por año (Test 2 — mejor de los tres)

| Año | Trades | Net P&L | PF | Win Rate |
|-----|--------|---------|-----|---------|
| 2019 | 177 | +$1,408 | 1.20 | 54% |
| 2020 | 232 | **-$2,952** | **0.80** | 47% |
| 2021 | 216 | +$2,666 | 1.37 | 53% |

2020 destruye el resultado: bear market COVID + volatilidad extrema = el ORB pierde consistencia.
El PF máximo anual (1.37 en 2021) aún no supera el umbral mínimo de 1.40.

---

## Análisis de exit types

| Exit | Test 1 | Test 2 | Test 3 |
|------|--------|--------|--------|
| SL | 71% (436) | 71% (442) | 29% (201) |
| TP | 29% (179) | 29% (182) | **5% (34)** |
| SessionEnd | 0% | 0% | **66% (453)** |
| Avg profit SessionEnd (T3) | — | — | +$23.91 |

**Test 3 revela el problema estructural:** con sesión corta (14:30–17:00 UTC), el 66% de los
trades cierran por `SessionEnd` a precio de mercado antes de alcanzar SL o TP.
El TP solo se alcanza en el 5% de los trades — el RR de 2.0x es demasiado ambicioso para
una ventana de solo 2.5 horas.

---

## Diagnóstico consolidado

| Problema | Test 1 | Test 2 | Test 3 | Solución |
|----------|--------|--------|--------|----------|
| Riesgo real 3-4x el configurado | Sí | Sí | Sí | Usar `RiskAmountUSD` fijo |
| Retención multi-día | Grave (24.8 días) | Grave (20.6 días) | Resuelto | SessionEnd 17:00 + `CloseAfterHours` |
| PF < 1.40 | 0.93 | 1.04 | 0.99 | Ver próxima acción |
| RR real << RR configurado | 1.07x | 1.00x | 0.97x | RR más bajo o sesión más larga |
| 2020 destruye resultado | -4229 | -2952 | -1340 | Filtro de régimen / volatilidad |
| TP rate 5% con sesión corta | — | — | Sí | RR reducido (1.0–1.5x) |

---

## Próximas acciones (prioridad)

1. **Cambiar `RiskPct` → `RiskAmountUSD` en el código** — elimina el problema de riesgo variable
2. **Fijar `SessionEnd = 17:00 UTC` + `CloseAfterHours_Enable = true, MaxHoldHours = 2`** — intraday estricto
3. **Reducir RR de 2.0 a 1.2–1.5** — con sesión corta el TP de 2R es inalcanzable en 2.5h
4. **Test con `TradeDirection = DIR_BUY` (long-only)** — sesgo alcista histórico del NAS100
5. **Investigar filtro de volatilidad** — 2020 es el año problemático, un filtro ATR podría excluirlo
6. **Repetir IS con configuración corregida** antes de declarar edge real o ausencia de edge

---

## Checklist de escepticismo

- [x] ¿PF se mantiene con slippage 2x? — No aplica, PF < 1 ya con slippage estándar
- [x] ¿Resultado depende de 1–3 trades excepcionales? — No, la pérdida es distribuida
- [x] ¿Funciona en años individuales? — **No**: 2020 es negativo en los 3 tests
- [x] ¿Sample size > 30? — Sí (615–688 trades)
- [x] ¿El edge supera costos reales? — No (PF < 1 en 2 de 3 tests)
- [ ] ¿Stress test paramétrico? — Pendiente
- [ ] ¿KS test IS vs OOS? — No aplica hasta tener IS viable
