---
type: strategy
status: development
pair: NDX100 (primary) | GBPUSD
timeframe: M10
style: liquidity-sweep reversal (reclaim confirmation)
risk_per_trade: USD-based (configurable)
created: 2026-04-12
tags:
---

# Estrategia: CTR Reclaim

## Origen

Ingeniería inversa de la estrategia comercial **CTR (Counter Trend Reclaim)** identificada en YouTube y MQL5 Market. El patrón central es un **liquidity sweep reversal** — el precio barre un mínimo o máximo reciente para cazar stops y luego se recupera ("reclaims") el nivel barrido, señalando que el movimiento fue una trampa institucional, no una ruptura real.

**Diferencia vs CTR Pro:**
CTR Pro entra en la vela que confirma el reclaim inmediatamente. CTR Reclaim espera una **confirmación adicional** (segunda vela que cierra dentro del rango), sacrificando precio de entrada por mayor certeza estadística. En la práctica de desarrollo, el término se usa para toda la familia de EAs basados en este concepto aplicados principalmente a NDX100.

---

## Hipótesis

En un horario específico de la sesión de Nueva York, se forma una **vela clave** (key candle) cuyos High y Low acumulan órdenes stop de retail. Cuando las velas posteriores barren esos niveles y cierran de regreso dentro del rango de la key candle, los institucionales están ejecutando posiciones en la dirección opuesta. El edge vive en los **primeros 1–3 minutos post-sweep** — no en tendencias intradiarias largas.

**Hallazgo crítico:** El edge desaparece cuando se expanden los parámetros SL/TP. Con SL=110/TP=290 ticks (micro-reversión instantánea) el WR=32.9% supera el breakeven. Con SL=1100/TP=2950 (10x más grande) el WR cae a 25.8%, por debajo del breakeven de 27.2%. **El edge es de scalp, no de swing.**

---

## Activos y Timeframes

| Activo | TF | Sesión | Cuenta |
|---|---|---|---|
| **NDX100** | M10 | NY (08:45 EDT) | FundingPips |
| GBPUSD | M10 | NY (08:45 EDT) | FundedNext |

---

## Lógica de la Estrategia

### Paso 1 — Identificar la Key Candle

- El EA escanea la barra que abre a la **hora + minuto configurados** en hora NY
- Se convierte a hora servidor: `server_hour = NY_hour + 4 + GMT_Offset` (verano) / `+ 5 + GMT_Offset` (invierno)
- **FundingPips server:** GMT+3 en verano → servidor 15:40–15:45
- Los niveles High y Low de esa vela se marcan como **niveles de referencia del día**
- `g_keyCandleTime` se actualiza como sentinel (no se resetea en el daily reset — solo los contadores de trades)

### Paso 2 — Detección del Sweep + Reclaim

En cada nueva barra cerrada posterior a la key candle, el EA verifica:

**Señal BUY:**
```
Low[1]   < Low[2]    → sweep del mínimo previo (caza de stops bajistas)
Close[1] > Low[2]    → cierre de vuelta por encima → reclaim confirmado
```

**Señal SELL:**
```
High[1]  > High[2]   → sweep del máximo previo (caza de stops alcistas)
Close[1] < High[2]   → cierre de vuelta por debajo → reclaim confirmado
```

> Nota: En implementaciones más simples (v2.2), `Low[2]` es el Low de la key candle. En versiones más complejas (v3.x), se usan fractales o lookback configurable para detectar el swing relevante.

### Paso 3 — Entrada

- Se verifica que el spread esté dentro del límite (`MaxSpreadPoints`)
- Se calcula el lotaje basado en el riesgo USD configurado
- Se coloca orden de mercado con SL y TP en ticks desde el precio de entrada

### Paso 4 — Gestión

- **Breakeven opcional** (activable/desactivable): mover SL al precio de entrada al alcanzar X ticks de ganancia
- **Una sola operación por día** (opcionalmente configurable)
- Cancelación y reset diario en apertura de nueva sesión

---

## Parámetros de Entrada

### Sesión y Timing
| Parámetro | Descripción | NDX100 Default |
|---|---|---|
| `NY_Hour` | Hora de la key candle en NY | 8 |
| `NY_Minute` | Minuto de la key candle en NY | 40–45 |
| `GMT_Offset` | Offset GMT del servidor broker | 3 (verano FundingPips) |

### Riesgo
| Parámetro | Descripción | v2.2 | v3.x |
|---|---|---|---|
| `RiskMode` | RISK_PERCENT / RISK_FIXED_USD | RISK_PERCENT | RISK_FIXED_USD |
| `RiskPercent` | % del balance a arriesgar | 1.0% | — |
| `RiskDollars` | USD fijos por trade | — | $25–$100 |
| `SL_ticks` | Stop Loss en ticks desde entrada | 110 | 110–690 |
| `TP_ticks` | Take Profit en ticks desde entrada | 290 | 290–925 |

### Filtros
| Parámetro | Descripción | Default |
|---|---|---|
| `MaxSpreadPoints` | Spread máximo en puntos | 30 (v2.2) / 300 (v3.0) |
| `SlippagePoints` | Slippage máximo en puntos | 10 (v2.2) / 150 (v3.0) |
| `TradeThursday` | Habilitar/deshabilitar jueves | true (v2.2) / false (v3.0) |
| `TradeSunday` | Habilitar domingo | false |
| `EnableBreakeven` | Activar breakeven | true (v3.7) / false (v3.8) |
| `MaxDDFromPeak` | Límite DD desde equity peak | $1,000 |
| `DailyLossLimitUSD` | Límite pérdida diaria | $500 |

---

## Especificaciones del Contrato NDX100

### Valor empírico (FundingPips backtest)

```
Valor por punto por lote estándar: $20
Cálculo verificado en dos versiones independientes:
  - v2.2: 0.25 lots × 1.10 pts × $20/pt = $5.50/trade ✓
  - v3.0: 0.11 lots × 11.00 pts × $20/pt = $24.20/trade ✓
```

### Lotaje correcto con $100 riesgo, SL=110 ticks

```
SL_distancia = 110 ticks × 0.01 (_Point) = 1.10 puntos de precio
Loss por lote = 1.10 pts × $20/pt = $22/lot
Lots = $100 / $22 = 4.54 lots
Win @ TP=290 ticks = 4.54 × 2.90 × $20 = $263.32
R:R real = 1:2.63
```

### Advertencia sobre TickValue especificado vs empírico

El valor teórico `TickValue×(PipSize/TickSize)` da $5/pt/lot pero el empírico es $20/pt/lot. Discrepancia persistente — **usar siempre el valor empírico verificado en backtest** o el parámetro `ManualValuePerPoint=20.0`.

---

## Versiones Desarrolladas

### v2.2 — Primera versión validada

**Origen:** Versión comercial replicada / ingeniería inversa  
**Activo:** NDX100 M10  
**Parámetros:**

```
NY_Hour=8, NY_Minute=45, GMT_Offset=2
SL_ticks=110, TP_ticks=290  →  RR 1:2.64
RiskPercent=1.0%
MaxSpreadPoints=30, SlippagePoints=10
TradeThursday=true
```

**Resultados (2020–2023):**

| Métrica | Valor |
|---|---|
| Net Profit | +$690 |
| WR | **32.9%** |
| PF | 1.31 |
| Breakeven WR | 27.5% |
| Total Trades | 812 |
| Avg Win | $10.92 |
| Avg Loss | -$4.08 |
| RR | 2.64:1 |

**Bug conocido — Lotaje:**  
Cálculo de lots incorrecto → riesgo real = $5.50/trade (no $100). Los resultados escalados correctamente proyectarían +$12,545 en el mismo período con el lotaje correcto.

**Bug conocido — Data gap:**  
`ScanForKeyCandle()` usaba `todayStart` (medianoche servidor) como límite → operaciones cortadas en 2023-07-14. Después de esa fecha el EA deja de encontrar key candles.

---

### v3.0 — Bugs corregidos, parámetros expandidos

**Activo:** NDX100 M10  
**Bugs corregidos en esta versión:**

| Bug | Descripción | Corrección |
|---|---|---|
| #1 — Risk | `CalcLots()` usaba fórmula incorrecta | `OrderCalcProfit(ORDER_TYPE_BUY, ...)` exclusivamente |
| #2 — Data gap | `ScanForKeyCandle()` dependía de `todayStart` (medianoche servidor) | Loop itera barras recientes y se detiene cuando `barTime <= g_keyCandleTime` |
| #3 — iBarShift | Función no disponible | Loop manual para encontrar `keyCandleBar` |
| #4 — Fill mode | Modo de llenado fijo | Auto-detect con `SymbolInfoInteger(SYMBOL_FILLING_MODE)` |
| #5 — TypeFilling | Variable no persistente | `g_fillMode` almacenada globalmente |
| #6 — Minuto snap | Desalineación con TF | `g_serverMinute = (NY_Minute / tfMinutes) * tfMinutes` |
| #7 — Day reset | Usaba `TimeCurrent()` en lugar de tiempo de barra | `iTime(_Symbol, _Period, 0)` |

**Parámetros (replicando EA comercial):**

```
NY_Hour=8, NY_Minute=40, GMT_Offset=3
SL_ticks=1100, TP_ticks=2950  ← 10x más grande que v2.2 (ERROR)
RiskMode=RISK_FIXED_USD, RiskDollars=25
MaxSpreadPoints=300, SlippagePoints=150
TradeThursday=false, TradeSunday=false
```

**Resultados (2020–2025, 5 años completos):**

| Métrica | Valor |
|---|---|
| Net Profit | **-$1,318.40** |
| WR | **25.8%** |
| PF | **0.931** |
| Breakeven WR | 27.2% |
| Total Trades | 1,116 |
| Avg Win | $61.38 |
| Avg Loss | -$22.94 |
| Max Hold Time | ~12 horas |
| DD | -$1,752.30 (17%) |

**Diagnóstico:** Los parámetros 10x más grandes destruyen el edge. El WR cae 7pp por debajo del breakeven. Solo 2023 fue marginalmente rentable (PF=1.073, WR=28.6%).

---

### v3.1 — Parámetros v2.2 + lotaje correcto

**Combinación:** código v3.0 (bugs corregidos) + parámetros v2.2 (tight SL/TP) + $100 riesgo

```
RiskDollars=100
SL_ticks=110, TP_ticks=290
MaxSpreadPoints=30, SlippagePoints=10
TradeThursday=true
```

**Lotaje proyectado:** `100 / (1.10 × $20) = 4.54 lots`  
**Ganancia por TP:** 4.54 × 2.90 × $20 = **$263.32 por trade**

**Problema #1 persistente:** Data gap — corte en 2023-07-14 igual que v2.2. Causa probable: DST (cambio de horario verano/invierno en el broker). El `GMT_Offset` fijo no compensa el cambio de GMT+3 a GMT+2 en invierno.

**Problema #2:** Lotaje real sigue siendo ~$5.28 por trade (no $100). El `OrderCalcProfit` en el backtester no retorna el valor correcto en las condiciones específicas de FundingPips.

**Recomendación final del análisis:** Usar `ManualValuePerPoint=20.0` como parámetro de entrada explícito.

---

### v3.7 — Versión validada IS+OOS

**Estado:** Validada con framework IS+OOS completo  
**Degradación IS→OOS:** -30.2% (aceptable, borde real confirmado)  
**WFA completado:** 4,806 combinaciones analizadas  
**Causa raíz del problema de margen:** Identificada y documentada (no es bug de código)

---

### v3.8 — Versión WFA (pendiente de backtest)

**Origen:** Parámetros derivados del Walk-Forward Analysis sobre 4,806 combinaciones

**Cambios respecto a v3.7:**

| Parámetro | v3.7 | v3.8 |
|---|---|---|
| `NY_Hour` | 8 | 8 |
| `NY_Minute` | 40 | **30** |
| `TP_ticks` | 690 | **925** |
| `EnableBreakeven` | true | **false** |
| `MagicNumber` | 3700 | **3800** |

**Racional del WFA:**
- Minuto 30 en lugar de 40: captura el rango 5 minutos antes → key candle más temprana en la apertura NY
- TP 925 vs 690: amplía el target un 34% → aprovecha el momentum completo del sweep
- BE desactivado: con RR más amplio, el breakeven puede cerrar prematuramente trades ganadores

---

### GBPUSD v2.3 — Adaptación Forex

**Base:** v2.2 con ajustes para GBPUSD  
**Referencia:** Set file de "Liquid Pours Xtreme MT5" (configuración optimizada)  
**Parámetros del set file:**

```
NY_Hour=8, NY_Minute=45, GMT_Offset=3 → server 15:45
Solo martes (TradeTuesday=true, resto=false)
RiskPercent=1.0%
AutoSafeMode=true (SafeModeFromTF=H1 para backtesting realista)
SafePadPoints=6
SL_ticks=150 (placeholder, optimizable 1000-50000)
TP_ticks=50 (placeholder, optimizable 1000-200000)
```

**Diferencias vs NDX100:**
- 1 pip = 10 ticks (GBPUSD 5 dígitos)
- Sin ContractSize especial — pip value standard
- Spread más alto → `SafePadPoints` para absorber spread en modo tester

---

## Análisis de Rendimiento por Año (v3.0, NDX100)

| Año | WR | PF | Trades | Rentable |
|---|---|---|---|---|
| 2020 | ~24.0% | < 1.0 | ~200 | ❌ |
| 2021 | ~24.5% | < 1.0 | ~200 | ❌ |
| 2022 | ~24.0% | < 1.0 | ~200 | ❌ (peor año) |
| 2023 | **28.6%** | **1.073** | ~200 | ✅ (único) |
| 2024 | ~25.0% | < 1.0 | ~150 | ❌ |
| 2025 | ~25.0% | < 1.0 | ~100 | ❌ |

**Conclusión:** Con parámetros amplios (SL=1100, TP=2950), el edge solo surge esporádicamente. Con parámetros micro (SL=110, TP=290), el edge es consistente: 2020 WR=36.5%, 2022 WR=28%, 2023 WR=36.6%.

---

## Comportamiento del Contrato (NDX100 / FundingPips)

### Comportamiento del lotaje en backtesting

El backtester de MT5 y FundingPips tienen un comportamiento no estándar con `OrderCalcProfit` para NDX100:

- **Teórico:** TickValue=$0.05, TickSize=0.01, ContractSize=5 → debería dar $5/pt/lot
- **Empírico:** $20/pt/lot consistente en ambas versiones validadas
- **SYMBOL_VOLUME_MAX posible:** ~0.25 lots en cuenta demo FundingPips → caps el cálculo cuando el target supera ese límite
- **Síntoma observado:** Lots decrecen de 0.24 (2020) a 0.14 (2023) con `RISK_FIXED_USD=100` → sugiere VOLUME_MAX dinámico basado en precio del subyacente o leverage disponible

### Bug de DST (Daylight Saving Time)

El EA usa `GMT_Offset` fijo. FundingPips cambia GMT+3 (verano) ↔ GMT+2 (invierno). Este cambio no ocurre en la misma fecha que el cambio de NY (EDT/EST). Resultado: durante ciertos períodos el offset calculado es incorrecto y el EA no encuentra la key candle → **trading se corta en julio 2023** (coincide con la transición horaria donde los offsets divergen).

**Solución en v3.8+:** Calcular `GMT_Offset` dinámicamente desde la diferencia entre `TimeCurrent()` y `TimeGMT()`, o hacer el parámetro ajustable estacionalmente.

---

## Decisiones Clave del Proyecto

### 1. Edge micro, no macro
El CTR Reclaim es un scalp de micro-reversión de 1–3 minutos. No escala a parámetros de swing trading. Toda optimización debe mantener SL ≤ 200 ticks en NDX100.

### 2. Fractal-based swing detection
Para detectar el swing relevante a barrer, se usan **fractales con N=3 barras a cada lado**. Este método alinea con la lógica institucional (los fractales representan puntos donde se acumula liquidez). La detección se confirma N barras después del swing, introduciendo ~15 min de delay en M5 (aceptable).

### 3. v3.0 vs v2.2 — "El edge no escala"
La expansión 10x de SL/TP fue el error central del diseño de v3.0. Los parámetros del EA comercial no son directamente aplicables porque el EA comercial puede tener lógica de entrada diferente, o cherry-picking de períodos. **Regla fija:** SL_ticks ≤ 200, RR ≥ 2:1.

### 4. TradeThursday=false en v3.0+
Jueves mostró peor comportamiento en NDX100 en el período 2022-2025. Sin análisis estadístico formal por día todavía — pendiente para v3.8.

### 5. EnableBreakeven=false en v3.8
El WFA encontró que con TP=925 ticks, el breakeven corta trades que irían a completar el objetivo. Consistente con el hallazgo del ORB: en estrategias de breakout/reversal con RR > 2:1, el BE puede ser contraproducente.

### 6. No usar el lotaje de v2.2 como referencia de P&L
Los resultados de v2.2 ($690 net) representan ~$5.50 de riesgo real por trade, no $100. Para comparativas de performance, escalar los resultados por factor 18.18x (= $100/$5.50). El P&L equivalente sería **+$12,545** con riesgo correcto.

---

## Framework de Backtesting

### Períodos
| Período | Rango | Propósito |
|---|---|---|
| In-Sample (IS) | 2021.01.01 – 2025.12.31 | Optimización |
| Forward | 2026.01.01+ | Monitoreo walk-forward |

### Configuración recomendada MT5
```
Símbolo:     NDX100
Timeframe:   M10
Mode:        Every tick based on real ticks (o Open prices para velocidad)
Depósito:    $5,000–$10,000
Leverage:    1:25 (FundingPips default)
InpShowVisuals: false (obligatorio para velocidad)
```

### WFA completado (v3.7 → v3.8)
- **Combinaciones analizadas:** 4,806
- **Parámetros barridos:** NY_Minute, TP_ticks, EnableBreakeven
- **Candidato ganador:** NY_Min=30, TP=925, BE=false

---

## Estado Actual y Próximos Pasos

### Estado
- ✅ v3.7 validada IS+OOS, degradación -30.2%
- ✅ WFA 4,806 combinaciones completado
- ✅ Causa raíz bug de margen identificada
- ⏳ v3.8 pendiente de backtest con parámetros WFA
- ⏳ Análisis por día (Lun/Mar/Mie/Jue/Vie) para v3.8 no realizado aún
- ⏳ GBPUSD v2.3 pendiente de backtest IS/OOS formal

### Orden de prioridades
1. **Correr backtest de v3.8** con parámetros WFA en período IS 2021–2025
2. **Análisis por día** en v3.8 — identificar días negativos como se hizo con ORB
3. Si DD OOS < 8% y PF > 1.20: forward test demo FundingPips 30 días
4. **GBPUSD:** backtest IS 2021–2023, OOS 2024, con set file como referencia de optimización

---

## Compliance Prop Firm

### FundingPips (NDX100)
- Max daily DD: 5%
- Max total DD: 10%
- Min trade duration: 2 min
- `DailyLossLimitUSD = 500` → protección built-in en v3.1+
- `MaxDDFromPeak = 1000` → protección built-in

### FundedNext (GBPUSD)
- Max daily DD: 5%
- Max total DD: 10%
- Min trade duration: 2 min

---

## Archivos del Proyecto

| Archivo | Descripción |
|---|---|
| `Source/Experts/CTR_Reclaim_v2_2.mq5` | Primera versión validada — NDX100 M10 |
| `Source/Experts/CTR_Reclaim_v3_0.mq5` | Bugs corregidos, parámetros 10x (no rentable) |
| `Source/Experts/CTR_Reclaim_v3_1.mq5` | v3.0 + parámetros v2.2 + $100 riesgo |
| `Source/Experts/CTR_Reclaim_v3_7.mq5` | Versión validada IS+OOS |
| `Source/Experts/CTR_Reclaim_v3_8.mq5` | Pendiente — parámetros WFA |
| `Source/Experts/CTR_Reclaim_GBPUSD_v2_3.mq5` | Adaptación GBPUSD |

---

## Referencias

- Chat 089: Ingeniería inversa de la estrategia CTR (YouTube + imágenes MQL5)
- Chat 102: EA automatizado para patrones de reversión — CTR Pro / arquitectura base
- Chat 099: CTR Reclaim EA v3.0 — análisis v2.2 vs v3.0, diagnóstico del bug de lotaje
- Chat 103: Estado global v3.7 + resumen WFA → parámetros v3.8
- Chat 105: Generación de v3.8 con parámetros WFA
- Chat 077: Adaptación GBPUSD v2.3 con set file de "Liquid Pours Xtreme MT5"

*Última actualización: 2026-04-12*

