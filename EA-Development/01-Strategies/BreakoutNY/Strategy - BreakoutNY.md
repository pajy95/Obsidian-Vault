---
type: strategy
status: production
pair: NAS100 | XAUUSD | DJI30 (activos) | SP500 (demo)
timeframe: M5
style: breakout
risk_per_trade: USD-based (configurable)
created: 2026-04-12
updated: 2026-04-18
tags:
  - strategy
---
[[Estrategias]]
# Estrategia: BreakoutNY

## Hipótesis

La apertura de la sesión de Nueva York (9:35 AM EST / 14:35 UTC) genera un rango de compresión de precio en las primeras 3 velas de M5. Ese rango acumula liquidez institucional que, al ser roto, produce un movimiento direccional sostenido con momentum suficiente para un RR mínimo de 1:2.

## Edge Rationale

- La apertura de NY coincide con la entrada de volumen institucional masivo y el cierre de posiciones de la sesión de Londres
- El rango pre-NY (14:35–14:45 UTC) funciona como zona de equilibrio antes de que los market makers establezcan dirección
- NAS100 tiene sesgo estructural alcista — los longs tienen mayor probabilidad de seguimiento
- El filtro de rango (MinSL/MaxSL) descarta días de baja volatilidad (sin momentum) y días de noticias extremas (rango desordenado)
- La ventana de entrada (14:50–15:15 UTC) captura el primer impulso limpio sin overextension

## Condiciones de mercado ideales

- **Sesión:** Nueva York (14:35–17:00 UTC)
- **Volatilidad:** Media-alta. Rangos dentro de P25–P75 histórico del activo
- **Tendencia:** Breakout limpio del High (BUY) o Low (SELL) sin fakeout inmediato
- **Noticias:** Evitar días NFP, FOMC, CPI — rangos extremos invalidan el filtro MaxSL
- **Para NAS100:** Solo LONGS activos (los SHORTS degradan el performance histórico)

---

## Reglas de entrada

1. **Rango de referencia:** Calcular High máximo y Low mínimo de las 3 velas de M5 en 14:35, 14:40 y 14:45 UTC
2. **Señal de entrada:**
   - BUY: precio cierra por encima del High del rango (ConfirmOnClose=true)
   - SELL: precio cierra por debajo del Low del rango (ConfirmOnClose=true)
3. **Ventana de entrada válida:** 14:50 UTC → 15:15 UTC (solo una operación por día)
4. **Filtro de rango:** SL calculado debe estar dentro de [MinSL_Points, MaxSL_Points] — si está fuera, no se opera ese día
5. **ConfirmOnClose:** obligatorio siempre. El breakout se confirma únicamente en cierre de vela M5, nunca en el tick

---

## Reglas de salida

### Stop Loss
- SL = promedio del rango (High–Low) de las velas de 14:40 y 14:45 UTC, medido desde el precio de entrada
- Alternativa en versiones avanzadas (NAS100 v7/v8): SL = extremo opuesto del rango completo de las 3 velas

### Take Profit

**Versión simple (NAS100 MT4):**
- TP único = SL × RR_Factor (configurable, default 2.0)

**Versión con parciales (NAS100 v7/v8, XAUUSD, FundingPips):**
- TP1 = 1× SL → cierre del 40% de la posición
- TP2 = 2× SL → cierre del 40%
- TP3 = 3× SL → cierre del 20% restante

### Breakeven (BE)
- Al alcanzar TP1 (1:1): SL se mueve a precio de entrada + BE_BufferPct%
- `BE_BufferPct` configurable — valores probados: 20–23% (NAS100), 70% (XAUUSD Set E), 200–260% (XAUUSD Set G)
- Versión avanzada: fase adicional — al recorrer 80% del camino de TP1 a TP2, SL se mueve a TP1

### Cierre forzado por sesión
- SessionCloseHour = 17:00 UTC — REGLA NO NEGOCIABLE
- Cualquier posición abierta al llegar a las 17:00 UTC se cierra automáticamente

---

## Parámetros por activo

### NAS100 (producción)

| Parámetro | Valor producción | Notas |
|---|---|---|
| MagicNumber | 202401 | |
| MinSL_Points | 250 | puntos MT5 |
| MaxSL_Points | 450 | puntos MT5 |
| BE_BufferPct | 20–23% | |
| TP1_ClosePct | 40% | |
| TP2_ClosePct | 40% | |
| TP3_ClosePct | 20% | |
| FilterShorts | true | SOLO LONGS |
| SessionCloseHour | 17 | UTC — fijo |
| ConfirmOnClose | true | siempre |
| EntryMaxCandle | 0 | sin límite |

### XAUUSD — FundingPips (Set E / producción)

| Parámetro | Valor producción | Notas |
|---|---|---|
| MagicNumber | 202404 | |
| ContractSize | 100 oz | |
| TickValue | $0.01 → $1.00/lot/pt | VPP=$100/pt/lot vía OrderCalcProfit |
| MinSL_Points | 4.50 | precio USD |
| MaxSL_Points | 13.00 | precio USD |
| BE_BufferPct | 70% | |
| FilterMonday | false | |
| FilterTuesday | false | |
| FilterWednesday | false | |
| FilterThursday | true | único día en producción |
| FilterFriday | false | descartado (dependencia de régimen) |
| ConfirmOnClose | true | siempre |
| EntryMaxCandle | 0 | sin límite |
| RiskAmountUSD | 50 | para cuenta $10K |
| SessionCloseHour | 17 | UTC — fijo |

### SP500 / SPX500 — FundingPips

| Parámetro | Valor orientativo | Notas |
|---|---|---|
| MagicNumber | 202403 | |
| ContractSize | 50 | |
| VPP estimado | $0.50/pt | verificar con OrderCalcProfit |
| MinSL_Points | ~3,000 | provisional — calibrar con P25 |
| MaxSL_Points | ~8,000 | provisional — calibrar con P90 |
| FilterWednesday | true | medir primero |
| RiskAmountUSD | 50 | |

### US30 / DJ30H — FundingPips

| Parámetro | Valor | Notas |
|---|---|---|
| MagicNumber | 202402 | |
| ContractSize | 5 | |
| TickSize | 0.01 | |
| TickValue | 5.0 USD | |
| VPP | 500 USD/pt/lot | |

### EURUSD — FundingPips

| Parámetro | Valor | Notas |
|---|---|---|
| MagicNumber | 202405 | |
| ContractSize | 100,000 EUR | |
| Dígitos | 5 | pipSize = 0.0001 |
| VPP | ~$10/pip/lot | |
| MinSL_Pips | ~8–12 pips | calibrar con P25 |
| MaxSL_Pips | ~25–35 pips | calibrar con P75 |
| SpreadMax_Pips | 3.0 | filtro anti-noticias |
| SessionCloseHour | 17 | UTC — fijo |

---

## Position Sizing

- **Método:** USD-based — el lotaje se calcula automáticamente a partir del riesgo en USD y la distancia del SL
- **Fórmula:** `lots = RiskAmountUSD / (slDistance × valuePerPoint)`
- **valuePerPoint** = `TickValue / TickSize` (verificado con OrderCalcProfit en CFDs)
- Límites: respetar VolumeMin y VolumeMax del broker; si el margen requerido supera el 90% del capital disponible, escalar a la baja
- **Riesgo por trade:** $50–$100 USD según cuenta (1% por defecto)

---

## Resultados de backtests

### NAS100 — v7/v8 (MT5, FundingPips)

| Métrica | Resultado | Objetivo |
|---|---|---|
| Profit Factor | 1.46 | > 1.5 |
| Sharpe Ratio | 14.68 | > 1.0 |
| Max Drawdown | 9.25% | < 20% |
| Retorno | +37.1% | — |
| Período | 16.7 meses | — |
| Capital inicial | $5,000 | — |
| Trades/semana | ~2.35 | > 1 |

**Nota:** PF ligeramente por debajo del objetivo de 1.5, pero Sharpe excepcional y DD controlado. SHORTS desactivados por degradar el performance.

### DJI30 — Base validada (MT5, FundingPips)

| Métrica | IS (2021–2024) | OOS (validación) |
|---|---|---|
| Profit Factor | 1.609 | 2.017 |
| Max Drawdown | 3.97% | 3.93% |

DJI30 fue el activo base de validación. PF OOS > PF IS confirma robustez fuera de muestra.

### XAUUSD — Análisis IS/OOS (FundingPips)

**Distribución de rangos pre-NY (calibración 2024–2026, 365 días):**

| Percentil | Valor (USD) |
|---|---|
| P25 | $5.88 |
| P50 (mediana) | $9.06 |
| Media | $12.24 |
| P75 | $14.91 |
| P95 | $32.30 |
| Máximo | $81.21 |

La distribución es muy asimétrica (σ=$10.45) — el filtro MaxSL es crítico en XAUUSD.

**Análisis por día de semana (XAUUSD):**

| Día | Mediana | % dentro P25/P75 |
|---|---|---|
| Lunes | $9.64 | 43% — más volátil |
| Martes | $8.50 | 55% |
| Miércoles | $8.09 | 57% — más estable |
| Jueves | $9.66 | 50% |
| Viernes | $9.39 | 47% |

**Comparativa de sets OOS (2025–2026):**

| Set | Días activos | OOS Net | PF OOS | DD OOS | Trades |
|---|---|---|---|---|---|
| Set A | -M-J- | $6,114 | 1.697 | 5.14% | 78 |
| Set B | --XJ- | $5,913 | 1.792 | 4.52% | 60 |
| Set C / Set G | ---J- | $5,831 | 2.347 | 3.02% | 38 |

**Set E — IS/OOS completo (---JV, BE=70%, MinSL=4.5, MaxSL=13.0):**

| Período | PF | DD |
|---|---|---|
| IS 2021–2024 | 1.22 | marginal |
| OOS 2025–2026 | 2.66 | 2.97% |

Jueves: $924 de los $1,217 OOS totales (75.9% del P&L). Viernes positivo en OOS por régimen alcista 2025, pero destruye valor en IS 2022 (PF=0.35 en año bajista).

**Set G recomendado (análisis exhaustivo 3,175 pasadas):**

```
BE_BufferPct    = 260
MinSL_Points    = 4.5
MaxSL_Points    = 16.5
FilterThursday  = true  (todos los demás = false)
ConfirmOnClose  = true
EntryMaxCandle  = 0
RiskAmountUSD   = 50
```

**Set de producción actual (Set E solo Jueves, probado individualmente):**

```
BE_BufferPct    = 70
MinSL_Points    = 4.5
MaxSL_Points    = 13.0
FilterThursday  = true  (todos los demás = false)
ConfirmOnClose  = true
EntryMaxCandle  = 0
RiskAmountUSD   = 50
```

---

## Decisiones clave

| # | Decisión | Justificación | Chat |
|---|---|---|---|
| 1 | Solo LONGS para NAS100 | Los SHORTS degradan el performance histórico consistentemente | 062 |
| 2 | ConfirmOnClose=true siempre | No es optimizable — sin cierre de vela hay demasiados fakeouts | 062, 088 |
| 3 | SessionCloseHour=17 UTC fijo | No es input del usuario — protege hold time ≤ 2h05m para compliance FP | 080, 087 |
| 4 | EntryMaxCandle=0 (sin límite) | Limitar candle de entrada a 1–4 corta trades buenos. 90% breakouts < 15:05 pero los tardíos siguen siendo rentables | 108 |
| 5 | Jueves es el único día confiable en XAUUSD | Robustez en todos los regímenes (2021–2026). Viernes falla en lateralización/bear | 108 |
| 6 | Viernes descartado de producción XAUUSD | WR=0% en 2022 (11 trades). No es ajustable con parámetros — es riesgo de régimen | 108 |
| 7 | VPP vía OrderCalcProfit en CFDs | SymbolInfoDouble SYMBOL_TRADE_TICK_VALUE es inestable en el backtester para CFDs XCCY | 080, 087 |
| 8 | Optimización: buscar mesetas, no picos | Un parámetro óptimo aislado rodeado de pérdidas es ruido, no signal | 062 |
| 9 | Walk-Forward antes de cualquier producción | IS 12 meses → OOS 4+ meses. OOS PF ≥ 70% del IS PF para validar | 062 |
| 10 | BE_BufferPct=0 es bug crítico | Produce WR ficticio de 99% porque nunca activa el BE correctamente | 088 |

---

## Versiones del EA

| Versión | Activo | Plataforma | Broker | Status |
|---|---|---|---|---|
| v1–v5 (NAS100) | NAS100 | MT4 | FundedNext | Archivadas — no rentables |
| v6 (NAS100) | NAS100 | MT4 | FundedNext | Base de trabajo |
| v7/v8 (NAS100) | NAS100 | MT5 | FundingPips | PF=1.46 — referencia |
| v9.x (NAS100) | NAS100 | MT5 | FundingPips | Producción (solo longs) |
| v1.0 XAUUSD | XAUUSD | MT5 | FundingPips | Desarrollo / testing |
| v1.0 SP500 | SP500 | MT5 | FundingPips | Desarrollo |
| v1.0 US30 (DJ30H) | US30 | MT5 | FundingPips | Desarrollo |
| v1.0 EURUSD | EURUSD | MT5 | FundingPips | Desarrollo / calibrar |

---

## Archivos relacionados

```
Source/Experts/
  BreakoutNY_v4_DJI30_FP.mq5          ← base de todas las versiones FundingPips
  BreakoutNY_v9_NAS100_FP.mq5         ← producción NAS100
  BreakoutNY_v1_XAUUSD_FP.mq5
  BreakoutNY_v1_SP500_FP.mq5
  BreakoutNY_v1_US30_FP.mq5
  BreakoutNY_v1_EURUSD_FP.mq5

Source/Scripts/
  BreakoutNY_Calibrator_XAUUSD.mq5    ← export CSV con distribución de rangos
  BreakoutNY_Calibrator_SP500.mq5
  BreakoutNY_Calibrador_EURUSD.mq5
  BreakoutNY_RiskDiagnostic_XAUUSD.mq5
  BreakoutNY_RiskDiagnostic_SP500.mq5
```

---

## Compliance FundingPips

| Regla | Límite | Estado estrategia |
|---|---|---|
| Max daily drawdown | 5% | Controlado — DD OOS XAUUSD 3.02% |
| Max total drawdown | 10% | Controlado |
| Min trade duration | 2 min | Siempre cumplido (velas M5) |
| No hedging | — | Una posición por señal |
| No martingala | — | USD-based sizing fijo |
| Hold time máximo | ≤ 2h05m | SessionCloseHour=17 UTC garantiza esto |

---

## Estado actual — Actualizado 2026-04-30

| Activo | Set | Días | Status | RiskUSD | OOS PF |
|--------|-----|------|--------|---------|--------|
| **NAS100** | v1 Mon+Tue+Fri | L+M+V | ✅ **PRODUCCIÓN** ($5K) | $13 | 1.794 |
| **DJI30** | v1 Tue+Thu+Fri | M+J+V | 🟡 **MARGINAL** ($5K) | $12 | 1.475 |
| **XAUUSD** | Set E — Thu Only | solo Jue | ✅ **PRODUCCIÓN** ($5K) | $16 | 3.618 |
| SP500 | v2 Mon+Tue+Wed | L+M+X | ❌ **DESCARTADO** | — | 0.889 |
| GER40 | L+M+V | L+M+V | ❌ **DESCARTADO** | — | 1.986 |
| US30 | — | — | 🔧 Desarrollo | — | — |
| EURUSD | — | — | 🔧 Desarrollo | — | — |

**Balance cuenta operativa:** $4.879 (desde $5.000 — pérdidas por parámetros incorrectos previos a auditoría)

### Re-auditoría OOS 2025-2026 (16 meses reales)

| Activo | PF IS | PF OOS | DD OOS | Trades OOS | Retención | Veredicto |
|--------|-------|--------|--------|------------|-----------|-----------|
| NAS100 v1 | 1.580 | 1.794 | 1.80% | 86 | — | ✅ VIABLE |
| DJI30 v1 | 1.486 | 1.475 | 2.09% | 35 | — | 🟡 MARGINAL |
| XAUUSD Set E | 2.002 | 3.618 | 0.85% | 27 | 180.7% | ✅ VIABLE |
| SP500 v2 | 1.724 | 0.889 | 1.87% | 31 | 60.0% | ❌ NO VIABLE |
| GER40 v1 | 1.901 | 1.986 | 0.84% | 34 | 104.5% | ❌ DESCARTADO — historial 18% insuficiente |

### Monte Carlo Challenge $25K (escenario conservador)
- P(pasar ambas fases): **92%**
- Tiempo estimado: **~15 meses**
- Con 2 activos adicionales viables: **~7–9 meses**
- P(bust): **0.0%**

> Sets completos en `Sets-Produccion/`
> Monte Carlo y Robustez en `Analisis-MonteCarlo/`
> Análisis de sets en `Analysis/`
> Backtests por activo en `Backtests/[ACTIVO]/`

## Próximas acciones pendientes

1. **Segundo activo candidato:** identificar y evaluar (GER40 descartado por calidad de historial)
2. **Fase 3:** validación CTR Pro IS/OOS/WF
3. **Fase 0 pendiente:** fee cuenta, fecha inicio, screenshot dashboard, Master Rules
4. WalkForward: depositar reportes mensuales MT5 en `WalkForward/[ACTIVO]/`

---

## Notas adicionales

- **Optimización = pulir diamantes, no crear edge de cero.** Si el EA no es al menos break-even con parámetros razonables, ningún optimizador lo salva
- **Meseta vs pico:** un parámetro óptimo aislado rodeado de pérdidas adyacentes es artefacto de overfitting, no signal real. Buscar zonas donde múltiples valores cercanos dan PF > 1.3
- **Walk-Forward Efficiency Ratio objetivo:** OOS PF ≥ 70% IS PF
- **XAUUSD es el instrumento más difícil** de la familia: alta volatilidad, spreads 20–50 pts en NY, spikes en FOMC/geopolítica, distribución de rangos muy asimétrica (media $12 vs mediana $9)
- **Lunes en XAUUSD:** solo 43% de días dentro del filtro P25/P75 — el más volátil e impredecible
- **Miércoles en XAUUSD:** el más estable (57%) pero excluido en el set de producción
- La estrategia nació en DJI30 y se validó ahí primero (IS PF=1.609, OOS PF=2.017) antes de expandirse a otros activos


