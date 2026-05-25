---
type: strategy
status: suspended
pair: XAUUSD (primary)
timeframe: M10
style: liquidity-sweep reversal
risk_per_trade: USD-based (configurable)
created: 2026-04-12
updated: 2026-05-03
tags:
---
[[Estrategias]]

# Estrategia: CTR Pro (Counter Trend Reclaim)

## Navegación

| Sección | Link |
|---------|------|
| Backtests IS/OOS | [[Backtests]] |
| Análisis y decisiones | [[Analysis]] |
| Análisis Monte Carlo | [[Analisis-MonteCarlo]] |
| Optimización MT5 | [[Optimizacion]] |
| Sets de producción | [[Sets-Produccion]] |
| Walk-Forward | [[Walkforward]] |
| Código fuente | [[Code]] |
| Historial de sesiones | [[Chat History]] |
| Trade Journal | [[Trade-Journal]] |

## Estado rápido — 2026-05-03

> ⛔ **ESTRATEGIA SUSPENDIDA — 2026-05-03**
> Ninguna versión (v1.0 → v2.10) logró PF > 1.35 en IS con muestra estadísticamente suficiente.
> El patrón sweep vela[1] vs vela[2] en M10 es demasiado frecuente y no discrimina señales institucionales del ruido.
> Los resultados OOS positivos (PF ~2.0) se basaban en ~40 trades — insuficiente para validación estadística.

| Activo | Timeframe | Status | Resultado final |
|--------|-----------|--------|-----------------|
| XAUUSD | M10 | ⛔ Suspendido | Ninguna versión validada IS+OOS con muestra suficiente |

### Versiones desarrolladas

| Versión | Descripción | PF IS | PF OOS | Veredicto |
|---|---|---|---|---|
| v1.00 | Base, todos los días, 08:00–23:00 | 0.961 | 0.927 | ❌ Perdedor |
| v1.10 | UTC puro, Buy Only, ventana 16:40 | 1.934* | — | *solo 103 trades |
| v1.20/v1.21 | + Supertrend H1, filtros de mecha, timer | 0.862 | 1.971 | ❌ IS pierde, OOS 40 trades |
| v1.30 | + SL dinámico anclado al sweep | 0.680 | 2.240 | ❌ IS peor, OOS 40 trades |
| v2.00 | Base limpia, SL dinámico/manual, BE, timer | 0.87 | — | ❌ Sin edge en ninguna combinación |
| v2.10 | + filtro mecha + distancia mínima | 1.31 | — | ❌ Insuficiente |

### Razones de suspensión
1. El patrón sweep vela[1] vs vela[2] ocurre demasiado frecuentemente — no discrimina calidad
2. IS 2015–2025 destruido por régimen pre-2021 (diferente estructura de mercado)
3. Resultados OOS prometedores (~PF 2.0) se basan en 40 trades — varianza, no edge
4. Múltiples rondas de optimización y filtros no lograron estabilizar el IS

## Hipótesis

En la apertura de la sesión de Nueva York (8:45 AM EST / 13:45 UTC), se forma una **vela clave** que representa el equilibrio de precio antes de la activación institucional. Cuando las velas siguientes barren el High o el Low de esa vela clave y **cierran de vuelta dentro del rango**, se genera una señal de reversión institucional (liquidity sweep reversal). El precio que recupera el nivel barrido ("reclaim") confirma que el movimiento fue una caza de stops, no una ruptura real.

## Edge Rationale

- Los mínimos y máximos de la vela 8:45 AM NY acumulan órdenes stop de traders retail que entraron en la sesión previa
- Cuando el precio barre esos stops (liquidez), los institucionales ejecutan su posición real en dirección contraria
- El cierre de la vela de regreso dentro del rango confirma el rechazo y la trampa
- Es un patrón de Smart Money Concepts (SMC): liquidity sweep + reclaim = entrada de alta probabilidad
- El edge es en micro-reversiones de 1–3 minutos — no en tendencias intradiarias largas
- La especificidad horaria (8:45 NY exacta) filtra el ruido del resto de la sesión

## Condiciones de mercado ideales

- **Sesión:** Nueva York (apertura exacta 8:45 AM EST / 13:45 UTC)
- **Volatilidad:** Normal a alta — necesita suficiente movimiento para barrer stops y revertir
- **Mercado:** Funciona mejor en días con sesgo institucional claro (lunes, martes, jueves para NDX100; martes para GBPUSD)
- **Evitar:** Días NFP, FOMC, eventos macro extremos (spreads amplios invalidan la señal)
- **Spread:** Filtrar si spread > 15 pts (EURUSD) / 30 pts (XAUUSD/NDX100)

---

## Reglas de entrada

1. **Vela clave:** Identificar la vela M5/M10 que abre a las 8:45 AM NY (configurable por GMT offset del servidor)
2. **Niveles de referencia:** Marcar el HIGH y LOW de esa vela específica
3. **Señal BUY (CTR Long):**
   - La vela siguiente rompe por **debajo del Low** de la vela clave (sweep del mínimo)
   - Y esa misma vela **cierra por encima** del Low de la vela clave (reclaim)
   - Entrada en compra en el close o apertura de la siguiente vela
4. **Señal SELL (CTR Short):**
   - La vela siguiente rompe por **encima del High** de la vela clave (sweep del máximo)
   - Y esa misma vela **cierra por debajo** del High de la vela clave (reclaim)
   - Entrada en venta en el close o apertura de la siguiente vela
5. **Una sola operación por día** — no re-entries

**Variante CTR Reclaim:**
- Misma lógica, pero la entrada se ejecuta en la confirmación del reclaim (segunda vela que cierra dentro del rango), no en la primera. Mayor confirmación a cambio de peor precio de entrada.

---

## Reglas de salida

### Take Profit
- **TP fijo** expresado en ticks (points), configurable por activo:
  - EURUSD M5 (video original): 290 ticks (29 pips)
  - EURUSD M10 (.set file): 180 ticks (18 pips)
  - XAUUSD M10: 1800 ticks ($18)
  - NDX100 M10 v2.2: 290 ticks (2.90 pts × $20 = $58/lot)
  - NDX100 v3.7: 690 ticks
  - **NDX100 v3.8 (WFA): 925 ticks**

### Stop Loss
- **SL fijo** expresado en ticks (points), configurable por activo:
  - EURUSD M5: 110 ticks (11 pips) — RR 1:2.64
  - EURUSD M10: 90 ticks (9 pips) — RR 1:2.0
  - XAUUSD M10: 840 ticks ($8.40) — RR 1:2.14
  - NDX100 v2.2/v3.1: 110 ticks (1.10 pts × $20 = $22/lot)
- SL se coloca fuera de la vela clave en dirección opuesta a la entrada

### Breakeven
- Activable/desactivable — `EnableBreakeven`
- v3.7: habilitado
- **v3.8 (WFA): desactivado** — el WFA determinó que BE reduce el PF neto

### Cierre de sesión
- `SessionCloseHour` — posición se cierra si supera la ventana de trading
- Hold time típico v2.2: < 8 minutos (micro-scalp)
- Hold time v3.0 (SL×10): hasta 12 horas — confirmó que el edge NO escala

---

## Parámetros por versión/activo

### EURUSD — Video original (M5)

| Parámetro | Valor |
|---|---|
| Timeframe | M5 |
| Key candle | 8:45 AM NY → 13:45 UTC |
| Días activos | Lunes, Martes, Viernes |
| SL_ticks | 110 (11 pips) |
| TP_ticks | 290 (29 pips) |
| RR | 1:2.64 |
| MaxSpreadPoints | 30 |

### EURUSD — .set file real (M10)

| Parámetro | Valor |
|---|---|
| Timeframe | M10 |
| Key candle | 13:50 servidor UTC+2 → 8:50 NY |
| Días activos | Martes–Viernes |
| SL_ticks | 90 (9 pips) |
| TP_ticks | 180 (18 pips) |
| RR | 1:2.0 |
| Break-even | Desactivado |
| Parciales | Desactivados |

### XAUUSD — .set file real (M10)

| Parámetro | Valor |
|---|---|
| Timeframe | M10 |
| MagicNumber | 27012026 |
| Días activos | Lunes, Martes, Miércoles |
| SL_ticks | 840 ($8.40) |
| TP_ticks | 1800 ($18.00) |
| RR | 1:2.14 |
| Ventana entrada | 13:10–16:10 UTC (3 horas) |
| MaxSpreadPoints | 100 |
| Break-even | Desactivado |

### NDX100 — v2.2 (M10, FundingPips)

| Parámetro | Valor |
|---|---|
| Timeframe | M10 |
| GMT_Offset | 2 |
| Key candle | 8:45 NY → servidor 14:45 → snap M10: 14:40 |
| Días activos | Lunes, Martes, Jueves, Viernes |
| SL_ticks | 110 (1.10 pts) |
| TP_ticks | 290 (2.90 pts) |
| RiskPercent | 1.0% (bug: ~$5.50 real en $10k) |
| Lots aprox. | 0.25 |
| ValuePerPoint | $20/pt/lot (NDX100 FundingPips) |
| MaxSpreadPoints | 30 |

### NDX100 — v3.1 (M10, parámetros corregidos)

| Parámetro | Valor |
|---|---|
| SL_ticks | 110 |
| TP_ticks | 290 |
| RiskDollars | $100 |
| Lots calculados | 4.54 → `100 / (1.10 × 20)` |
| Ganancia por TP | ~$263 |
| Pérdida por SL | ~$100 |

### NDX100 — v3.7 vs v3.8 (WFA)

| Parámetro | v3.7 | v3.8 (WFA producción) |
|---|---|---|
| NY_Hour / Minute | 8:40 | **8:30** |
| TP_ticks | 690 | **925** |
| EnableBreakeven | true | **false** |
| MagicNumber | 3700 | **3800** |

### GBPUSD — v2.3

| Parámetro | Valor |
|---|---|
| Días activos | **Solo Martes** (optimizado comercialmente) |
| Key candle | 15:50 UTC+3 = 8:50 NY EDT |
| GMT_Offset | 3 (FundingPips verano) |
| AutoSafeMode | true (H1 range validation, SafePadPoints=6) |
| ToleranceMinutes | 1 |

---

## Position Sizing

- **Método:** USD-based — `RiskDollars` fijo OU `RiskPercent` del balance
- **Fórmula:** `lots = RiskDollars / (SL_distance_points × ValuePerPoint)`
- **ValuePerPoint NDX100:** $20/pt/lot (verificado empíricamente — `OrderCalcProfit` en MT5)
- Validar VPP con OrderCalcProfit antes de cualquier deploy — `SYMBOL_TRADE_TICK_VALUE` inestable en backtester
- Límites: `SYMBOL_VOLUME_MIN`, `SYMBOL_VOLUME_MAX`, `SYMBOL_VOLUME_STEP`
- Riesgo recomendado: $100/trade para cuenta de $10,000 (1%)

---

## Resultados de backtests

### NDX100 v2.2 — IS 2020–mid2023 (812 trades)

| Métrica | Resultado | Nota |
|---|---|---|
| Net Profit | +$690 | Con bug de lotaje ($5.50 real/trade) |
| Profit Factor | 1.31 | |
| Win Rate | 32.9% | > breakeven 27.5% ✓ |
| Avg Win | $10.92 | |
| Avg Loss | $4.08 | |
| Hold time máx | < 8 min | Micro-scalp confirmado |
| Trades | 812 | Corte en 2023-07-14 (data gap bug) |
| RR | 1:2.64 | |

**Proyección corregida** (con $100 riesgo real):
- Net Profit aprox. **+$12,545** en 2020–2023
- Max DD aprox. **26%** (manejable, no deseable para prop firm)

### NDX100 v3.0 — IS 2020–2025 (1,116 trades)

| Métrica | Resultado | Diagnóstico |
|---|---|---|
| Net Profit | −$1,318 | LOSING |
| Profit Factor | 0.93 | < 1.0 |
| Win Rate | 25.8% | < breakeven 27.2% ✗ |
| Avg Win | $61.38 | |
| Avg Loss | $22.94 | |
| Hold time máx | hasta 12 horas | Edge destruido |
| Trades | 1,116 | Período completo |
| RR | 1:2.68 | |

**Causa:** SL=1100/TP=2950 (10× expansión). WR cae de 32.9% a 25.8% — por debajo del breakeven matemático. El edge desaparece al escalar el SL.

### Análisis por año (NDX100 v3.0 vs v2.2)

| Año | v2.2 WR | v3.0 WR | v3.0 PF |
|---|---|---|---|
| 2020 | 36.5% | ~24% | <1.0 |
| 2021 | — | ~24% | <1.0 |
| 2022 | ~28% | worst year | <1.0 |
| 2023 | 36.6% | 28.6% | 1.073 |
| 2024 | — | <27% | <1.0 |
| 2025 | — | <27% | <1.0 |

2022 = año más difícil en ambas versiones (ciclo bajista NDX + agresividad Fed).

### NDX100 v3.7 IS+OOS

| Período | Degradación OOS vs IS |
|---|---|
| IS+OOS | −30.2% — **aceptable** (threshold WFA) |
| WFA | 4,806 combinaciones analizadas |

### Punto de equilibrio matemático (breakeven WR)

```
Breakeven WR = 1 / (1 + RR)
RR = 2.64 → Breakeven = 27.5%   (EURUSD M5, NDX100 v2.2)
RR = 2.0  → Breakeven = 33.3%   (EURUSD M10)
RR = 2.14 → Breakeven = 31.8%   (XAUUSD M10)
```

**WR > Breakeven WR → PROFITABLE. WR < Breakeven WR → LOSING.**

---

## Versiones del EA

| Versión | Activo | Estado | Notas clave |
|---|---|---|---|
| v1.0 | EURUSD M5 | Archivada | Fractal-based (incorrecto) |
| v1.1 | EURUSD/XAUUSD M10 | Archivada | Key candle correcto, .set alineado |
| v2.0 | EURUSD M5 | Archivada | Lógica key candle definitiva |
| v2.2 | NDX100 M10 | Archivada | PF=1.31, bug lotaje (100×), datos hasta 2023 |
| v2.3 | GBPUSD M5 | Archivada | Solo martes, AutoSafeMode |
| v3.0 | NDX100 M10 | Archivada | Bugs corregidos, SL×10 → perdedor |
| v3.1 | NDX100 M10 | Archivada | SL/TP v2.2 + lotaje correcto, data gap reaparece |
| **v3.7** | NDX100 M10 | **Validado IS+OOS** | WFA 4,806 combinaciones completado |
| **v3.8** | NDX100 M10 | **En construcción** | WFA params: NY 8:30, TP=925, BE=false |
| **CTR Pro** | XAUUSD M5 | **PRODUCCIÓN** | Dashboard, visual signals, session filters |
| CTR Reclaim | XAUUSD M5 | **Desarrollo** | Entrada en reclaim post-sweep (variante) |

---

## Decisiones clave

| # | Decisión | Justificación | Chat |
|---|---|---|---|
| 1 | La vela clave es UNA sola (8:45 AM NY), no fractales genéricos | Transcripción del video confirma explícitamente. v1.0 con fractal search en 30 barras era lógica incorrecta | 089 |
| 2 | SL/TP en ticks, NO en pips | .set files reales: SL=110 ticks ≠ 11 pips. Confusión causó múltiples versiones incorrectas | 089 |
| 3 | El edge VIVE en micro-reversiones (< 8 min hold) | v3.0 con SL×10 → hold time 12h → WR cae de 32.9% a 25.8% → perdedor | 099 |
| 4 | Expandir SL/TP 10× destruye el edge | v3.0: SL=1100, TP=2950 → WR=25.8% < breakeven 27.2%. No hay RR que compense WR < breakeven | 099 |
| 5 | Bug lotaje v2.2 (100× error) no explica la rentabilidad | v2.2 era rentable con $5.50 real/trade. El edge estructural es válido independiente del lotaje | 099 |
| 6 | Data gap bug: `todayStart` con timezone offset → corte 2023 | `todayStart` = medianoche servidor GMT+2/+3 ≠ día trading NY. v3.0 lo resolvió con sentinel `g_keyCandleTime` | 099 |
| 7 | Break-even desactivado en v3.8 (WFA resultado) | WFA 4,806 combinaciones muestra EnableBreakeven=false maximiza PF neto | 103, 105 |
| 8 | TP=925 ticks en v3.8 (de 690 en v3.7) | WFA encontró que TP más amplio mejora el PF sin sacrificar WR por encima del breakeven | 105 |
| 9 | NY_Minute=30 en v3.8 (de 40) | WFA determinó que 8:30 NY (server 15:30) captura mejor el sweep post-apertura | 105 |
| 10 | Solo Martes para GBPUSD | .set file comercial "Liquid Pours Xtreme" — optimizado sobre datos reales | 077 |
| 11 | AutoSafeMode + H1 range validation para GBPUSD | Previene error `10016 INVALID_STOPS` cuando SL calculado < 15% del rango H1 | 077 |
| 12 | OrderCalcProfit obligatorio para VPP (no SymbolInfoDouble) | `SYMBOL_TRADE_TICK_VALUE` inestable en backtester para CFDs. NDX100 = $20/pt/lot confirmado | 099 |
| 13 | v3.7 degradación OOS de −30.2% es aceptable | Diseñado para ese threshold en WFA. Degrada pero no pierde edge estructural | 103 |

---

## CTR Pro vs CTR Reclaim — Diferencia conceptual

| Aspecto | CTR Pro | CTR Reclaim |
|---|---|---|
| Señal de entrada | Primera vela sweep + cierra dentro del rango | Segunda vela confirma el reclaim del nivel barrido |
| Timing | Más agresivo, mejor precio de entrada | Mayor confirmación, peor precio |
| WR esperado | Mayor (entra antes del movimiento completo) | Menor (señales más limpias) |
| Status | Producción (XAUUSD M5) | Desarrollo (XAUUSD M5) |

---

## CTR Pro EA de producción — Features

Construido en Chat 102 como EA profesional completo (700 líneas MQL5):

**Lógica de detección:** `DetectLiquiditySweep()` analiza velas `[1]` y `[2]` en cada nueva barra:
- BUY: `low[1] < low[2]` AND `close[1] > low[2]` → mínimo barrido con recuperación
- SELL: `high[1] > high[2]` AND `close[1] < high[2]` → máximo barrido con rechazo

**Visualización:** Por cada señal se crean objetos en chart:
- Flecha de entrada (verde BUY / naranja SELL) + label "CTR ENTRY"
- Líneas horizontales: TP (verde), SL (rojo), Entry (punteada)
- Líneas diagonales punteadas: entry→TP y entry→SL
- `InpMaxDrawings` controla cuántos setups quedan visibles

**Dashboard interactivo:**
- Estado sistema (Activo/Inactivo/Pausado)
- Spread en tiempo real
- P/L diario acumulado
- Contador de operaciones / max por día
- Botones: "Cerrar Todo", "Cerrar +$" (solo ganancias), "Pausar/Reanudar"

**Filtros en cascada:** día de semana → sesión horaria → trades diarios → spread → nueva barra → patrón de sweep

### Parámetros configurables CTR Pro

| Parámetro | Default | Descripción |
|---|---|---|
| `InpDirection` | Both | Buy Only / Sell Only / Both |
| `InpSL_Pips` | 30 | SL en pips |
| `InpTP_Pips` | 60 | TP en pips |
| `InpRiskUSD` | 50 | Riesgo por trade en USD |
| `InpMaxPerDay` | 3 | Máx trades por día |
| `InpMaxSpread` | 30 | Filtro spread en pts |
| `InpSlippage` | 10 | Slippage en pts |
| `InpMaxDrawings` | 10 | Últimos N setups visibles |
| `InpStartHour` | 8 | Hora inicio sesión |
| `InpEndHour` | 17 | Hora fin sesión |
| `InpTrade[Mon-Fri]` | Configurable | Filtros por día |

### Ajustes recomendados por activo

| Parámetro | XAUUSD (default) | EURUSD | GBPUSD |
|---|---|---|---|
| `InpSL_Pips` | 30 | 10–15 | 12–18 |
| `InpTP_Pips` | 60 | 20–30 | 25–35 |
| `InpMaxSpread` | 30 pts | 15 pts | 20 pts |
| Hora inicio | 08:00 | 07:00 | 07:00 |
| Hora fin | 17:00 | 16:00 | 16:00 |

---

## Origen — Ingeniería inversa del EA comercial

La estrategia fue construida mediante ingeniería inversa de:
1. **Video YouTube** — screenshoots de configuración del CTR Reclaim v3.0 comercial
2. **Imágenes MQL5** — trades de ejemplo EURUSD con SL=11 pips, TP=29 pips (+$871/$923 por trade)
3. **Archivos .set originales** — revelan M10 real, SL/TP en ticks, días activos reales
4. **"Liquid Pours Xtreme MT5" (.set GBPUSD)** — variante comercial equivalente (Solo Martes)
5. **Transcripción del video** — confirma que la vela clave de 8:45 NY es el único nivel de referencia

**Lo que el video decía (incorrecto) vs realidad (.set files):**

| Parámetro | Video (incorrecto) | .set files (real) |
|---|---|---|
| Timeframe | M5 | M10 |
| Unidad SL/TP | Pips | Ticks |
| SL EURUSD | 11 pips | 90 ticks (9 pips) |
| TP EURUSD | 29 pips | 180 ticks (18 pips) |
| Días EURUSD | Lun/Mar/Vie | Mar-Vie |
| Breakeven | Activado | Desactivado |

---

## Bugs históricos documentados

| Bug | Versión | Descripción | Fix |
|---|---|---|---|
| Fractal detection incorrecto | v1.0 | Buscaba fractals en 30 barras — lógica incorrecta | v2.0: key candle fijo |
| SL/TP en pips vs ticks | v1.0–v1.1 | SL=11 pips ≠ SL=110 ticks | v1.1: unidades en ticks |
| Data gap `todayStart` | v2.2, v3.1 | Corte en 2023-07-14 por timezone mismatch | v3.0: sentinel `g_keyCandleTime` |
| Lotaje 100× error | v2.2 | $5.50/trade en lugar de $100 target | v3.0: `OrderCalcProfit` |
| SL×10 edge destruction | v3.0 | SL=1100/TP=2950 → WR=25.8% < breakeven | v3.1: back to SL=110/TP=290 |
| iBarShift bug | v3.0 | Uso incorrecto de iBarShift | v3.0: loop manual |
| Fill mode hardcodeado | v3.0 | Modo de llenado fijo | v3.0: `SymbolInfoInteger FILLING_MODE` |
| Data gap reintroducido | v3.1 | v3.1 re-introduce el bug de v2.2 | Pendiente en v3.x |
| OBJPROP_TRANSPARENCY | CTR Pro | Propiedad inexistente en MQL5 | Eliminada — usar canal alpha del color |

---

## Compliance FundingPips / FundedNext

| Regla | Límite | Estado CTR |
|---|---|---|
| Max daily loss | 5% | `DailyLossLimitUSD` configurable |
| Max total drawdown | 10% | `MaxDDFromPeak` configurable |
| Min trade duration | 2 min | Hold time típico 1–8 min ⚠ |
| No hedging | — | 1 trade por señal |
| No martingala | — | Lotaje fijo USD-based |

⚠ El hold time típico del CTR (< 8 min) puede acercarse al límite de 2 min en trades muy rápidos. Verificar en producción y configurar min hold si el broker lo requiere.

---

## Estado actual — 2026-05-03

⛔ **SUSPENDIDA** — Desarrollo detenido indefinidamente.

### Posibles caminos de retorno (si se retoma en el futuro)
1. **Cambiar la vela de referencia** — buscar swing high/low de las últimas N velas en lugar de vela[2] inmediata
2. **Cambiar el timeframe** — M30 o H1 produce sweeps menos frecuentes y más institucionales
3. **Desarrollar CTR Reclaim** — esperar segunda vela de confirmación del reclaim antes de entrar
4. **Análisis IS por año** — identificar en qué régimen exacto vive el edge antes de optimizar

---

## Archivos relacionados

```
Source/Experts/
  CTR_Pro_EA.mq5                  ← PRODUCCIÓN XAUUSD M5
  CTR_Reclaim_v2_2.mq5            ← NDX100, PF=1.31, referencia histórica
  CTR_Reclaim_v2_3_GBPUSD.mq5    ← GBPUSD, solo Martes
  CTR_Reclaim_v3_0.mq5            ← NDX100, SL×10 (archivado)
  CTR_Reclaim_v3_1.mq5            ← NDX100, SL/TP v2.2 corregido
  CTR_Reclaim_v3_7.mq5            ← NDX100, IS+OOS validado
  CTR_Reclaim_v3_8.mq5            ← NDX100, WFA params (en construcción)

09-Chat-History/md/CTR-Liquidity-Sweep/
  077 - Desarrollo de EA CTR para GBPUSD.md
  089 - Ingeniería inversa de una estrategia.md
  099 - CTR Reclaim EA v30 MQL5.md
  102 - Expert Advisor automatizado para patrones de rever.md
  103 - CTR Reclaim EA estado global y próximos pasos.md
  105 - Crear v38 con parámetros WFA.md
```

