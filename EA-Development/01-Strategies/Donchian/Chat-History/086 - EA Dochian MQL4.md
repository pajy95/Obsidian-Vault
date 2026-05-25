# EA Dochian MQL4

## 👤 Jose
Hola claude. Solicito de tu ayuda como experto en desarrollo de estrategias rentables y experto en programacion en mql4.

## 🤖 Claude
 Jose is sharing a detailed prompt for developing a Donchian Channel EA in MQL4 and asking for my help as an expert in profitable strategy development and MQL4 programming. Let me ask what specifically he needs help with.¡Hola Jose! Leí el documento — es un prompt bien estructurado con metodología sólida (IS/OOS, CSV export, iteración progresiva). Me parece un punto de partida serio.

¿Con qué quieres que arranquemos?
```
This block is not supported on your current device yet.
```

Waiting for user response.Cuéntame también si esto va hacia una prop firm (FundingPips u otra) o es para cuenta propia — eso cambia bastante las restricciones de diseño.

## 👤 Jose
P: ¿Cuál es el primer paso en el que necesitas ayuda?
R: Necesito ayuda, recuerda que estamos desde el punto inicial y no tengo mucha informacion en general

P: ¿Tienes ya datos históricos de EURUSD listos, o partimos desde cero?
R: Sí, tengo datos en MT4

## 👤 Jose
P: ¿Cuál es el primer paso en el que necesitas ayuda?
R: Necesito ayuda, recuerda que estamos desde el punto inicial y no tengo mucha informacion en general

P: ¿Tienes ya datos históricos de EURUSD listos, o partimos desde cero?
R: Sí, tengo datos en MT4

## 🤖 Claude
 Jose wants to start from the beginning with the Donchian EA in MQL4. He has historical data in MT4. Let me ask a few more clarifying questions to understand his experience level and goals before diving in.Perfecto, arrancamos desde cero entonces. Antes de escribir una sola línea de código, necesito entender bien el contexto para no darte algo genérico que luego no sirva.
```
This block is not supported on your current device yet.
```

Waiting for responses.

## 👤 Jose
P: ¿Cuál es tu nivel de experiencia programando en MQL4/MQL5?
R: Intermedio (modifico EAs existentes)

P: ¿Este EA es para prop firm o cuenta propia?
R: Fundednext demo

P: ¿Por dónde prefieres empezar?
R: Primero definir bien la metodología IS/OOS

## 🤖 Claude
 Let me help Jose understand the IS/OOS methodology clearly before any coding. He's intermediate level, targeting FundedNext demo, and wants to start with methodology. Let me explain this in a clear, practical way tailored to his context.Buena decisión — la metodología es la base de todo. Si esto falla, el código no importa.

---

## Metodología IS/OOS para el EA Donchian — FundedNext

### ¿Por qué separar los datos?

El error más común en desarrollo de EAs es optimizar parámetros sobre **todos** los datos históricos y luego "descubrir" que el EA no funciona en live. Eso se llama **overfitting** o curve fitting. La solución es simple: el EA nunca puede "ver" los datos de validación durante la optimización.

---

### División de datos recomendada para EURUSD

```
TOTAL DE DATOS: Ene 2018 → hoy (≈7 años)

┌─────────────────────────────────────────────────┐
│  IN-SAMPLE (IS)        │  Ene 2018 – Dic 2021   │
│  Para optimizar        │  4 años / ~70% datos   │
├─────────────────────────────────────────────────┤
│  OUT-OF-SAMPLE (OOS)   │  Ene 2022 – Dic 2023   │
│  Para validar          │  2 años / ~20% datos   │
├─────────────────────────────────────────────────┤
│  WALK-FORWARD (WF)     │  Ene 2024 – hoy        │
│  Confirmación final    │  ~10% datos            │
└─────────────────────────────────────────────────┘
```

---

### El proceso paso a paso

**Paso 1 — Optimización (solo en IS)**
Corres el Strategy Tester de MT4 en modo optimización, únicamente con datos de 2018–2021. El objetivo es encontrar combinaciones de parámetros con **Profit Factor > 1.4** y **Drawdown < 20%**.

**Paso 2 — Selección de parámetros (criterio clave)**
No eliges los parámetros con el mayor beneficio en IS. Eliges los que muestran **consistencia** — es decir, varios sets de parámetros cercanos con resultados similares (robustez de vecindad).

**Paso 3 — Validación (OOS, sin tocar)**
Corres el EA con los parámetros elegidos en 2022–2023. **Sin re-optimizar nada.** Aquí es donde sabes si la estrategia tiene edge real.

**Paso 4 — Criterio de aceptación**
| Métrica | Criterio mínimo |
|---|---|
| PF en OOS vs IS | Degradación < 25% |
| Drawdown OOS | No supera el IS |
| Nº operaciones OOS | > 80 trades |

**Paso 5 — Walk-forward (2024–hoy)**
Si pasa el OOS, confirmas con el período más reciente. Si aquí falla, el mercado cambió de régimen — eso es información valiosa, no un fracaso.

---

### Regla de oro para FundedNext

> Una estrategia con PF=1.3 consistente en OOS **vale más** que una con PF=2.1 en IS y PF=0.9 en OOS.

FundedNext evalúa tu cuenta en condiciones de mercado **futuras**, no pasadas. El OOS simula exactamente eso.

---

### Próximo paso

Con esto claro, ¿avanzamos hacia la **estructura base del EA en MQL4**? Te propongo empezar con la versión más simple posible: Donchian puro con SL/TP fijo y el CSV export — sin filtros todavía. Los filtros los añadimos **después** de validar que el núcleo tiene edge.

¿Te parece bien ese orden?

## 👤 Jose
Inicia

## 🤖 Claude
 The user wants to start coding the EA. Let me build a solid MQL4 EA base for the Donchian Channel strategy with CSV export. Let me create a well-commented, clean MQL4 EA.

Key components:
1. Donchian Channel calculation (iHighest/iLowest)
2. Entry logic: Buy on breakout above upper band, Sell on breakout below lower band
3. ATR-based SL/TP
4. CSV export on trade close
5. FundedNext-compatible safeguards (daily DD limit, max lot size)
6. Session filter (optional)


7. Now I need to set up the parameter structure so everything's easy to tweak and optimize without touching the core logic.Perfecto. Vamos a construir la **versión base v1.0** — núcleo limpio, sin filtros, optimizable y con CSV export. Cada componente bien comentado para que puedas modificarlo.
```
This block is not supported on your current device yet.
```

Good, now let me present the file to the user.
```
This block is not supported on your current device yet.
```

Aquí está el EA base. Te explico lo que contiene y los próximos pasos:

---

### ¿Qué tiene esta v1.0?

**Lógica de entrada**
- BUY cuando el cierre de la vela anterior rompe el máximo de Donchian
- SELL cuando rompe el mínimo — ambos desactivables con `EnableBuy/EnableSell`

**Gestión de riesgo**
- Lote calculado automáticamente por % de cuenta (`RiskPercent`)
- SL y TP basados en ATR — se adaptan a la volatilidad del mercado
- Límite de lote máximo para cumplir con FundedNext

**Protección de cuenta**
- Circuit breaker de DD diario (default 4%) y total (default 8%)
- Cierra todas las posiciones y detiene el EA automáticamente

**CSV Export**
- Genera automáticamente `Donchian_EURUSD_M15_YYYY.MM.DD.csv`
- Una fila por trade cerrado con todos los datos para análisis

---

### Cómo instalarlo en MT4

1. Copia el archivo en: `MetaTrader 4/MQL4/Experts/`
2. Abre MetaEditor → Compila (F7) → Sin errores
3. Arrastra el EA al gráfico EURUSD en M15

---

### Próximo paso recomendado

Antes de optimizar, hay que correr un **primer backtest sin optimización** en el período IS (2018–2021) con los parámetros default para ver la línea base. ¿Quieres que te guíe paso a paso en cómo configurar el Strategy Tester para ese primer run?

## 👤 Jose
Elimina el circuit breaker, estamos revisando datos, se necesita observar y evaluar parametros. Eres un trader cuantitativo

## 🤖 Claude
 The user wants me to remove the circuit breaker (drawdown protection) from the EA since we're in backtesting/evaluation mode. Makes sense - circuit breakers interfere with data collection during optimization.Correcto. En fase de análisis el circuit breaker distorsiona los resultados — necesitamos ver el comportamiento real de la estrategia sin interrupciones artificiales.
```
This block is not supported on your current device yet.
```

Now I'll create v1.1 with the circuit breaker completely removed - clean version for data analysis.Procedo a limpiar el código. Elimino todo lo relacionado con drawdown limits, variables de protección y `CloseAllPositions` — versión limpia para observación pura.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

**Cambios respecto a v1.0:**

Todo lo eliminado: `CheckDrawdownLimits()`, `CloseAllPositions()`, `g_eaEnabled`, `MaxDailyDrawdown`, `MaxTotalDrawdown`, `g_startBalance`, `g_lastDayCheck` — el EA corre sin ninguna interrupción artificial.

**Agregado para análisis cuantitativo:**
- `UseFixedLot` + `FixedLotSize` — opción de lote fijo para que los resultados del backtest sean comparables entre runs sin que el compounding distorsione la lectura
- El CSV ahora también registra `DonchianPeriod`, `ATRMultSL`, `ATRMultTP` en cada fila — útil cuando corres múltiples sets de parámetros y consolidas los CSVs en Python/Excel
- `UseSessionFilter = false` por defecto — ve todo el mercado primero, el filtro lo añadimos después si los datos lo justifican

---

**Configuración recomendada para el primer backtest:**

```
Par:           EURUSD
Timeframe:     M15
Período IS:    01/01/2018 — 31/12/2021
Modo:          Every tick (basado en ticks reales)
UseFixedLot:   true  → FixedLotSize = 0.10
GenerateCSV:   true
EnableBuy:     true
EnableSell:    true
UseSessionFilter: false
```

Lote fijo en esta fase para que el PF y el drawdown reflejen la estrategia pura, no el compounding. ¿Tienes datos de calidad en MT4 para EURUSD M15 desde 2018?

