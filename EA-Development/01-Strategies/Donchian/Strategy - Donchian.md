---
type: strategy
status: forward-testing
pair: EURUSD
timeframe: M15
style: trend-following breakout
platform: MT4 (MQL4)
account: FundedNext demo
risk_per_trade: 1% (configurable)
created: 2026-04-12
tags:
---

# Estrategia: Donchian Channel EA

## Descripción General

EA de **trend-following por ruptura de canal** basado en el indicador Donchian Channel. La premisa es simple: cuando el precio rompe el máximo o mínimo del canal formado en las últimas N velas, se activa una señal de impulso en esa dirección. No predice movimientos — sigue la ruptura del rango.

Desarrollado específicamente para **EURUSD M15 en MT4** sobre cuenta demo FundedNext, con una metodología cuantitativa rigurosa de IS/OOS/Walk-forward desde cero.

---

## Hipótesis

Los canales Donchian representan zonas de consolidación. Cuando el precio rompe el máximo del canal (Donchian High), los vendedores con stops en esa zona son eliminados y el impulso alcista se libera — y viceversa en ruptura del mínimo. El edge proviene de la asimetría estadística de los breakouts de consolidación frente al ruido intracanal.

---

## Activo y Timeframe

| Campo | Valor |
|---|---|
| Activo | EURUSD |
| Timeframe | M15 |
| Plataforma | MetaTrader 4 (MQL4) |
| Cuenta | FundedNext demo |
| Sesión | Configurable (filtro activable) |

---

## Reglas de Entrada

### Señal BUY
```
Close[1] > iHighest(Symbol, Period, MODE_HIGH, DonchianPeriod, 2)
```
→ El **cierre de la vela anterior** supera el máximo Donchian del período  
→ Entrada en compra al precio actual (barra nueva)

### Señal SELL
```
Close[1] < iLowest(Symbol, Period, MODE_LOW, DonchianPeriod, 2)
```
→ El **cierre de la vela anterior** quiebra el mínimo Donchian del período  
→ Entrada en venta al precio actual (barra nueva)

**Notas de implementación:**
- La señal se evalúa **en apertura de nueva barra** (no tick a tick) → evita ruido intracandle
- El lookback comienza en la barra `[2]` (no en la barra de la señal) → evita lookahead bias
- `EnableBuy` y `EnableSell` permiten activar/desactivar cada dirección de forma independiente

---

## Reglas de Salida

### Stop Loss
- **Basado en ATR:** `SL = ATR(ATRPeriod) × ATRMultSL`
- Se adapta automáticamente a la volatilidad vigente
- Colocado fuera del rango normal de fluctuación para cada régimen

### Take Profit
- **Basado en ATR:** `TP = ATR(ATRPeriod) × ATRMultTP`
- RR configurable vía el ratio `ATRMultTP / ATRMultSL`

### Criterio de robustez RR
- El Donchian breakout tiene WR típicamente baja (40-50% en tendencia)
- Requiere RR ≥ 1.5:1 para ser rentable estructuralmente
- Comenzar optimización con `ATRMultSL=1.5`, `ATRMultTP=2.5` → RR ~1.67:1

---

## Parámetros de Entrada

### Canal Donchian
| Parámetro | Descripción | Default |
|---|---|---|
| `DonchianPeriod` | Número de velas para el canal | 20 |

### ATR (Volatilidad)
| Parámetro | Descripción | Default |
|---|---|---|
| `ATRPeriod` | Período del ATR | 14 |
| `ATRMultSL` | Multiplicador ATR para Stop Loss | 1.5 |
| `ATRMultTP` | Multiplicador ATR para Take Profit | 2.5 |

### Gestión de Riesgo
| Parámetro | Descripción | Default |
|---|---|---|
| `RiskPercent` | % del balance a arriesgar por trade | 1.0% |
| `MaxLotSize` | Límite máximo de lote | configurable |
| `UseFixedLot` | Activar lote fijo en lugar de % | false |
| `FixedLotSize` | Tamaño fijo de lote (análisis) | 0.10 |

### Filtros de Dirección
| Parámetro | Descripción | Default |
|---|---|---|
| `EnableBuy` | Habilitar señales de compra | true |
| `EnableSell` | Habilitar señales de venta | true |

### Filtro de Sesión (opcional)
| Parámetro | Descripción | Default |
|---|---|---|
| `UseSessionFilter` | Activar filtro de sesión horaria | false |

### Configuración General
| Parámetro | Descripción | Default |
|---|---|---|
| `MagicNumber` | Identificador único del EA | configurable |
| `GenerateCSV` | Exportar trades a CSV | true |

---

## Versiones del EA

### v1.0 — Base con circuit breaker

**Características:**
- Lógica Donchian + ATR SL/TP completa
- Lote dinámico por `RiskPercent` **y** opción de lote fijo
- Filtro de sesión horaria (desactivado por default)
- Circuit breaker de DD diario (default 4%) y DD total (default 8%)
- CSV export automático: `Donchian_EURUSD_M15_YYYY.MM.DD.csv`
- Protección FundedNext built-in

**Parámetros eliminados en v1.1:**
- `MaxDailyDrawdown` (4%)
- `MaxTotalDrawdown` (8%)
- `CheckDrawdownLimits()`, `CloseAllPositions()`, `g_eaEnabled`

---

### v1.1 — Observación cuantitativa limpia (versión actual)

**Decisión:** Circuit breaker completamente eliminado para que el backtesting refleje el comportamiento real de la estrategia sin interrupciones artificiales.

**Razón del cambio:**
> En fase de análisis, el circuit breaker distorsiona los resultados — el DD registrado no corresponde al edge real de la estrategia sino a la interrupción del EA. Para tomar decisiones de parámetros correctas, se necesita ver el comportamiento sin límites impuestos.

**Cambios respecto a v1.0:**

| Elemento | v1.0 | v1.1 |
|---|---|---|
| Circuit breaker | ✅ Activo | ❌ Eliminado |
| Lote fijo | ✅ Opción | ✅ Mejorado |
| CSV — metadatos | Parcial | Incluye `DonchianPeriod`, `ATRMultSL`, `ATRMultTP` por fila |
| `UseSessionFilter` | Configurable | false (default) — ver todo primero |

**CSV mejorado en v1.1:** Cada fila incluye los parámetros del run, útil para consolidar múltiples CSVs de diferentes sets de optimización en Python/Excel sin perder el contexto de configuración.

**Estado actual:** Forward testing.

---

## Metodología IS/OOS/Walk-Forward

### División de datos

```
TOTAL: Ene 2018 → presente (≈7 años)

┌─────────────────────────────────────────────────┐
│  IN-SAMPLE (IS)        │  Ene 2018 – Dic 2021   │
│  Para optimizar        │  4 años / ~70% datos   │
├─────────────────────────────────────────────────┤
│  OUT-OF-SAMPLE (OOS)   │  Ene 2022 – Dic 2023   │
│  Para validar          │  2 años / ~20% datos   │
├─────────────────────────────────────────────────┤
│  WALK-FORWARD (WF)     │  Ene 2024 – presente   │
│  Confirmación final    │  ~10% datos            │
└─────────────────────────────────────────────────┘
```

### Proceso de optimización

**Paso 1 — Backtest base (sin optimización)**
- Parámetros default en IS (2018–2021)
- Objetivo: establecer la línea base del comportamiento

**Paso 2 — Optimización (solo IS)**
- Parámetros a optimizar: `DonchianPeriod`, `ATRMultSL`, `ATRMultTP`
- Target IS: PF > 1.4, DD < 20%
- Criterio de selección: **robustez de vecindad** — no el máximo absoluto, sino sets de parámetros donde combinaciones cercanas tienen resultados similares

**Paso 3 — Validación OOS (sin re-optimizar)**
- Correr los parámetros seleccionados en 2022–2023
- No tocar nada. El OOS se evalúa solo una vez

**Paso 4 — Walk-forward (2024–presente)**
- Si pasa OOS, confirmar en datos más recientes
- Si falla: el mercado cambió de régimen — información valiosa, no fracaso

### Criterios de aceptación

| Métrica | Criterio mínimo |
|---|---|
| Degradación PF (OOS vs IS) | < 25% |
| Drawdown OOS | ≤ DD en IS |
| Trades OOS | > 80 |
| PF OOS mínimo | > 1.20 |

### Configuración para primer backtest

```
Par:           EURUSD
Timeframe:     M15
Período IS:    01/01/2018 — 31/12/2021
Modo:          Every tick (basado en ticks reales)
UseFixedLot:   true → FixedLotSize = 0.10
GenerateCSV:   true
EnableBuy:     true
EnableSell:    true
UseSessionFilter: false
```

> **Lote fijo en fase IS:** Evita que el compounding distorsione la lectura del PF y DD. El lote dinámico se activa después, en fase de forward testing con el set validado.

---

## Parámetros a Optimizar

### Grid de optimización recomendado (IS)

| Parámetro | Mínimo | Máximo | Step |
|---|---|---|---|
| `DonchianPeriod` | 10 | 50 | 5 |
| `ATRMultSL` | 1.0 | 3.0 | 0.5 |
| `ATRMultTP` | 1.5 | 5.0 | 0.5 |

### Análisis adicional recomendado

1. **Dirección:** Correr `EnableBuy=true, EnableSell=false` y viceversa — EURUSD no tiene el sesgo alcista fuerte de XAUUSD, pero puede haber asimetría por régimen
2. **Sesión:** Una vez con edge validado, añadir `UseSessionFilter=true` y evaluar si London o NY mejoran el PF sin reducir trades por debajo de 80 en OOS
3. **Día de la semana:** Analizar PF por día (misma metodología que ORB/CTR) para identificar días negativos

---

## Compliance FundedNext (MT4)

| Regla | Límite | Implementación |
|---|---|---|
| Max daily DD | 5% | v1.0: `MaxDailyDrawdown=4%` (con buffer). v1.1: sin límite (análisis) |
| Max total DD | 10% | v1.0: `MaxTotalDrawdown=8%`. v1.1: sin límite |
| Min trade duration | 2 min | No afecta M15 (duración mínima de un trade = 1 barra = 15 min) |
| No hedging | — | EA abre solo 1 posición por símbolo |
| No martingala | — | Lote por RiskPercent, no escalado |

> **Para challenge FundedNext:** Reactivar el circuit breaker de v1.0 con `MaxDailyDrawdown=3.5%` y `MaxTotalDrawdown=7%` — margen de seguridad doble respecto al límite oficial.

---

## Decisiones Clave del Proyecto

### 1. MQL4 en lugar de MQL5
La cuenta demo de FundedNext es MT4 → el EA debe ser MQL4. La lógica es directamente portable a MQL5 si se cambia de plataforma.

### 2. Primero el núcleo, después los filtros
Regla metodológica estricta: no añadir filtros de sesión, tendencia u otros hasta confirmar que el Donchian puro tiene edge estadístico en IS. Los filtros se añaden **como refinamiento**, no como parche.

### 3. Circuit breaker eliminado en v1.1
Para observación cuantitativa limpia. El circuit breaker se reintroducirá en la versión de producción (challenge) con parámetros conservadores.

### 4. Lote fijo durante backtest/optimización
`UseFixedLot=true, FixedLotSize=0.10` en todas las fases de análisis. El lote dinámico (`RiskPercent`) se activa solo en la versión de producción con el set validado.

### 5. CSV con metadatos de parámetros por fila
Cada fila del CSV incluye `DonchianPeriod`, `ATRMultSL`, `ATRMultTP` — diseño para consolidar múltiples runs de optimización en un análisis Python/Excel sin perder el contexto de qué parámetros generó cada trade.

### 6. Robustez de vecindad como criterio de selección
No elegir el set de parámetros con el PF más alto en IS. Elegir el que muestra resultados consistentes en combinaciones cercanas (vecindad paramétrica). Minimiza el riesgo de overfitting a un pico aislado.

---

## Estado Actual

| Fase | Estado |
|---|---|
| Código v1.0 base | ✅ Completado |
| Código v1.1 (sin circuit breaker) | ✅ Completado |
| Primer backtest IS (baseline) | ⏳ Pendiente |
| Optimización IS (2018–2021) | ⏳ Pendiente |
| Validación OOS (2022–2023) | ⏳ Pendiente |
| Walk-forward (2024–hoy) | ⏳ Pendiente |
| Análisis por dirección | ⏳ Pendiente |
| Análisis por sesión | ⏳ Pendiente |
| Versión challenge FundedNext | ⏳ Pendiente (post-validación OOS) |

**Estado global (CLAUDE.md):** Forward testing  
*(Nota: CLAUDE.md indica "forward testing" — lo que puede significar que el backtest básico se completó y se está monitoreando en demo. La documentación de análisis no está registrada en los chats disponibles.)*

---

## Próximos Pasos Recomendados

1. Correr **primer backtest IS baseline** (parámetros default, lote fijo 0.10)
2. Revisar la distribución del P&L y WR por dirección antes de optimizar
3. Correr **optimización IS** sobre el grid `DonchianPeriod × ATRMultSL × ATRMultTP`
4. Seleccionar set por robustez de vecindad (no por PF máximo)
5. **Validar en OOS 2022–2023** — criterio go/no-go
6. Si pasa: añadir filtro de sesión, analizar PF por día de semana
7. Construir versión challenge con circuit breaker reactivado

---

## Archivos del Proyecto

| Archivo | Descripción |
|---|---|
| `Source/Experts/Donchian_EURUSD_v1_0.mq4` | Base con circuit breaker |
| `Source/Experts/Donchian_EURUSD_v1_1.mq4` | Sin circuit breaker — observación cuantitativa limpia |

---

## Referencias

- Chat 086: Desarrollo completo desde cero — metodología IS/OOS, v1.0 y v1.1

*Última actualización: 2026-04-12*

