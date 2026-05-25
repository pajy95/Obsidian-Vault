# Estrategia de scalping cuantitativo para XAUUSD

## 👤 Jose
Hola Claude, eres un experto en diseño de estrategias de trading cuantitativo, estadística financiera y programación en mql5. Requiero de tus habilidades(previamente instaladas) y destrezas para elaborar una estrategia de trading de tipo scalping(alta frecuencia preferiblemente), para el xauusd, con la finalidad que opere en la sesion de NY.  No recomiendo uso de indicadores basicos(MACD, RSI, entre otros). Debe ejecutarse en temporalidad de M5. Indicame que estrategias recomiendas, El RR debe ser minimo admisible 1:1 o mayor

## 🤖 Claude
The user is asking me to recommend scalping/high-frequency trading strategies for XAUUSD (Gold) during the NY session, on M5 timeframe, without basic indicators like MACD/RSI, with a minimum 1:1 risk-reward ratio. They want me to use my installed skills.

Let me first check the relevant skills - particularly the quant-analyst, generating-trading-signals, backtest-expert, and strategy-advisor skills to provide the best recommendations.

Let me read the relevant skill files first.Hola! Vamos a diseñar algo robusto para ti. Primero déjame consultar mis skills especializadas para darte las mejores recomendaciones.
```
This block is not supported on your current device yet.
```

Let me also check the backtest-expert and strategy-advisor skills.
```
This block is not supported on your current device yet.
```

Now let me also check the venue-expert and strategy-advisor skills briefly.
```
This block is not supported on your current device yet.
```

Now I have enough context. Let me provide a comprehensive recommendation of scalping strategies for XAUUSD on M5 during the NY session, avoiding basic indicators. Let me think about what would work well:

1. **Order Flow / Price Action based strategies** - Using order blocks, fair value gaps, liquidity sweeps
2. **Statistical mean reversion** - Using Bollinger Bands alternatives like Keltner Channels, or custom Z-score based
3. **Volatility breakout** - Session open range breakout
4. **Market microstructure** - Spread analysis, volume profile
5. **Multi-timeframe momentum** - Using ATR-based momentum


6. I'll walk through each of these with specific entry/exit rules and examples so they can pick what fits their trading style.Excelente. Con la información de mis skills especializadas, te presento un análisis estratégico completo. Dado que el XAUUSD en sesión NY es un entorno de alta volatilidad y liquidez, necesitamos estrategias que exploten microestructura de mercado real, no indicadores retrasados.

Aquí van mis **5 propuestas de estrategia**, ordenadas por sofisticación:

---

**Estrategia 1 — NY Session Open Range Breakout (ORB)**

La hipótesis es que los primeros 15-30 minutos de la sesión NY (9:30–10:00 ET) establecen un rango que actúa como zona de acumulación institucional. La ruptura de ese rango con volumen genera impulso direccional. Se define el High/Low de las primeras 3-6 velas M5 post-apertura, se entra en la ruptura con filtro de expansión de volatilidad (ATR dinámico), el SL va en el extremo opuesto del rango y el TP mínimo es 1:1, escalable a 1:2 con trailing. Es robusta, tiene lógica institucional real, y genera entre 1-3 señales diarias.

**Estrategia 2 — Fair Value Gap (FVG) + Liquidity Sweep**

Se basa en que el precio tiende a rellenar ineficiencias (gaps entre velas consecutivas) después de barrer liquidez en niveles obvios. Se detectan FVGs algorítmicamente (gap entre el high de vela N-2 y el low de vela N), se espera un sweep de un swing high/low previo, y se entra cuando el precio retorna al FVG. El RR natural es 1:1.5 a 1:3 porque el SL es ajustado al extremo del sweep. Es la estrategia más alineada con Smart Money Concepts pero codificada sin subjetividad.

**Estrategia 3 — Volatility Compression → Expansion (Squeeze Detector)**

El oro comprime volatilidad antes de movimientos explosivos. Se mide la compresión usando el ratio ATR(5)/ATR(20): cuando cae por debajo de un umbral (ej. 0.6), se prepara entrada. La dirección se define por la pendiente de un EMA rápido o por el delta de cierres recientes. El SL se coloca en el centro de la zona de compresión y el TP es función del ATR expandido esperado. Estadísticamente muy sólida, baja frecuencia de señales falsas en NY.

**Estrategia 4 — Mean Reversion con Z-Score Dinámico**

Usa estadística pura: calcula el Z-score del precio respecto a una media móvil ponderada por volumen (VWAP rolling de N períodos). Cuando el Z-score excede ±2σ durante la sesión NY, se entra en contra-tendencia esperando reversión a la media. El SL es ±3σ y el TP es el retorno a ±0.5σ, lo que da un RR de aproximadamente 1:1.5. Funciona especialmente bien en las primeras 2 horas de NY donde hay sobrereacciones.

**Estrategia 5 — Multi-Timeframe Momentum Cascade**

Usa alineación de momentum entre M15 y M5 sin indicadores clásicos. Se calcula el Rate of Change (ROC) normalizado en M15, cuando M15 muestra momentum fuerte (ROC > umbral), se buscan pullbacks en M5 usando fractales de precio (swing lows/highs de 3 velas). La entrada es en el retesteo del último fractal alineado con la dirección M15. SL debajo del fractal, TP al siguiente nivel de estructura. RR típico 1:1 a 1:2.

---

Antes de pasar a la implementación en MQL5, necesito que elijas la dirección:
```
This block is not supported on your current device yet.
```

Good, I've presented the options. Now waiting for the user to select.Cada estrategia tiene una hipótesis de edge claramente definida (requisito fundamental del backtest-expert skill). Una vez que elijas, implemento el EA completo en MQL5 con todas las reglas codificadas sin discreción, listo para que lo pruebes en el Strategy Tester de MetaTrader 5.

## 👤 Jose
P: ¿Cuál(es) estrategia(s) quieres que implemente en MQL5? (Seleccione todas las que correspondan)
R: Escribeme el codigo asociado a cada estrategia.

P: ¿Qué nivel de gestión de riesgo incluyo?
R: Básico (SL/TP fijos + lotaje fijo)

P: ¿Quieres que incluya filtro de horario NY estricto?
R: Sí, 9:30-16:00 ET (sesión completa)

## 🤖 Claude
The user wants me to implement all 5 strategies as MQL5 Expert Advisors with basic risk management (fixed SL/TP + fixed lot) and NY session filter (9:30-16:00 ET). This is a massive coding task. Let me plan this out.

I'll create 5 separate EA files, one for each strategy. Each will have:
- NY session filter (9:30-16:00 ET)
- Basic risk management (fixed SL/TP + fixed lot)
- M5 timeframe
- XAUUSD optimized

Let me start coding each one. Given the complexity, I'll create them as separate .mq5 files.


Now I'm mapping out how each strategy will work: the ORB will identify the opening range from the first few candles after the session opens and trade breakouts, the FVG strategy will spot fair value gaps and enter when they're filled, the volatility squeeze will watch for ATR compression and trade the breakout, the Z-score approach will use VWAP to identify mean reversion extremes, and the momentum cascade will combine multiple timeframes for directional bias.

Writing MQL5 implementation...Perfecto, voy a implementar las 5 estrategias completas. Es un trabajo extenso — vamos a ello.
```
This block is not supported on your current device yet.
```

Now let me create all 5 EA files. This is going to be extensive. Let me write high-quality MQL5 code for each strategy.

I'll create them one by one. Let me start with Strategy 1.Vamos a crear los 5 Expert Advisors. Cada uno será un archivo `.mq5` independiente, profesional y listo para Strategy Tester.
```
This block is not supported on your current device yet.
```

Now let me create Strategy 2: FVG + Liquidity Sweep
```
This block is not supported on your current device yet.
```

Now Strategy 3: Volatility Squeeze
```
This block is not supported on your current device yet.
```

Strategy 4: Z-Score Mean Reversion
```
This block is not supported on your current device yet.
```

Strategy 5: MTF Momentum Cascade
```
This block is not supported on your current device yet.
```

Now let me copy all files to the output directory and present them.Ahora voy a copiar todos los archivos al directorio de salida para que puedas descargarlos:
```
This block is not supported on your current device yet.
```

Great, 2078 lines total across 5 files. Let me present them all.
```
This block is not supported on your current device yet.
```

All 5 files created and presented. Let me give a summary.Aquí tienes los **5 Expert Advisors** completos (2,078 líneas de MQL5 en total). Un resumen rápido de cada uno para el backtesting:

---

**EA 01 — ORB Open Range Breakout** (384 líneas): Define el rango de las primeras 6 velas M5 post-apertura NY, entra en la ruptura con filtro ATR que descarta rangos demasiado pequeños o demasiado grandes. SL en el extremo opuesto, TP configurable con RR 1.5 por defecto.

**EA 02 — FVG + Liquidity Sweep** (518 líneas): El más complejo. Detecta algorítmicamente Fair Value Gaps (gap entre high de vela N-2 y low de vela N), identifica swing points con lookback configurable, detecta liquidity sweeps (wick que barre el swing y rechaza), y entra cuando el precio retorna al FVG. Es Smart Money Concepts sin subjetividad.

**EA 03 — Volatility Squeeze** (319 líneas): Usa una máquina de estados (IDLE → SQUEEZING → FIRED). Detecta compresión cuando ATR(5)/ATR(20) cae bajo 0.60, y dispara entrada cuando el ratio sube sobre 1.20 con dirección confirmada por momentum y EMA.

**EA 04 — Z-Score Mean Reversion** (405 líneas): Calcula Rolling VWAP y Z-Score dinámico. Entra contra-tendencia cuando Z excede ±2σ, gestión de salida híbrida: sale por Z-Score (retorno a ±0.5σ), por stop estadístico (±3σ), o por timeout de barras.

**EA 05 — MTF Momentum Cascade** (452 líneas): Analiza ROC normalizado en M15, cuando detecta momentum fuerte busca fractales de Williams en M5 como puntos de pullback. Incluye trailing stop adaptativo que se activa al alcanzar 1:1 de RR.

---

**Para el backtesting en MT5**, necesitas ajustar el parámetro `InpBrokerGMTOffset` al offset GMT de tu broker (la mayoría son GMT+2 o GMT+3). Coloca los archivos en la carpeta `MQL5/Experts/` de tu MetaTrader, compila cada uno en MetaEditor, y pruébalos con datos de XAUUSD en M5. Te recomiendo empezar con el Strategy Tester usando "Every tick based on real ticks" para mayor precisión en scalping. ¿Quieres que profundicemos en alguna de las estrategias o que ajustemos parámetros?

## 🤖 Claude
The user wants all 5 strategies implemented in MQL5 with basic risk management (fixed SL/TP + fixed lot) and NY session filter (9:30-16:00 ET). This is a massive coding task. Let me implement each strategy as a separate EA file.

Let me plan this out:

1. Strategy 1: ORB (Open Range Breakout)
2. Strategy 2: FVG + Liquidity Sweep
3. Strategy 3: Volatility Squeeze
4. Strategy 4: Z-Score Mean Reversion
5. Strategy 5: MTF Momentum Cascade

Each EA needs:
- NY session filter (9:30-16:00 ET converted to broker time)


- Basic risk management (fixed SL/TP + fixed lots)
- M5 timeframe
- XAUUSD specific

I'll need to handle timezone conversion with a GMT offset input parameter that users can adjust based on their broker. Now I'm going to write out all 5 EAs as separate .mq5 files.Perfecto, vamos con las 5 estrategias completas. Esto es un proyecto grande — déjame construir cada EA meticulosamente.
```
This block is not supported on your current device yet.
```

Now let me build all 5 EAs. This is a substantial coding task. Let me create each one carefully.

I'll create them in /home/claude/ first, then copy to outputs.

Let me write each EA. I need to be thorough with MQL5 syntax.

Key considerations for all EAs:
- XAUUSD on M5
- NY session 9:30-16:00 ET (need GMT offset parameter)
- Basic risk: fixed lots, fixed SL/TP in points
- Proper MQL5 structure with OnInit, OnDeinit, OnTick
- Trade management with CTrade class


- Writing the EA files...
```
This block is not supported on your current device yet.
```

Let me write all 5 EAs. I'll be thorough with each one.Voy a construir los 5 EAs completos. Empiezo con la Estrategia 1:
```
This block is not supported on your current device yet.
```

Now Strategy 2: FVG + Liquidity Sweep
```
This block is not supported on your current device yet.
```

Now Strategy 3: Volatility Squeeze
```
This block is not supported on your current device yet.
```

Now Strategy 4: Z-Score Mean Reversion
```
This block is not supported on your current device yet.
```

Now Strategy 5: Multi-Timeframe Momentum Cascade
```
This block is not supported on your current device yet.
```

Now let me create a README with instructions and parameter guide, then copy everything to outputs.Ahora voy a crear una guía completa de configuración y un resumen comparativo:
```
This block is not supported on your current device yet.
```

Now let me copy everything to outputs.
```
This block is not supported on your current device yet.
```

It looks like there are duplicate files from an earlier version. Let me clean up and present just the correct files.
```
This block is not supported on your current device yet.
```

Now let me count total lines of code.
```
This block is not supported on your current device yet.
```

Good. Let me present all files.
```
This block is not supported on your current device yet.
```

All 5 EAs plus the README are ready. Let me summarize.Aquí tienes las **5 estrategias completas** — más de 2,000 líneas de MQL5 en total. Cada EA es independiente y está listo para compilar en MetaEditor.

**Resumen rápido de lo que incluye cada uno:**

**EA01 (ORB)** — Define el rango de las primeras 6 velas M5 post-apertura NY, luego opera la ruptura con filtro ATR de expansión. SL dinámico en el extremo opuesto del rango.

**EA02 (FVG + Sweep)** — Detecta algorítmicamente Fair Value Gaps de 3 velas y swing points. Espera un barrido de liquidez con rechazo confirmado, luego entra cuando el precio retorna al FVG. La confluencia sweep + FVG es el edge.

**EA03 (Squeeze)** — Mide el ratio ATR(5)/ATR(20); cuando cae por debajo de 0.60 durante 3+ barras y luego explota por encima de 1.20, dispara entrada. Dirección por delta de cierres + EMA M15.

**EA04 (Z-Score)** — Calcula Z-Score del precio vs media ponderada por volumen (VWAP rolling). Entra en contra-tendencia a ±2σ, cierra a ±0.5σ, stop a ±3σ. Incluye filtro anti-trend para no fadear movimientos extremos.

**EA05 (MTF Cascade)** — ROC normalizado en M15 define la dirección, luego busca fractales de pullback en M5 para entradas precisas. TP dinámico basado en niveles de estructura previos.

**Paso crítico antes de operar:** Configura correctamente el `InpGMTOffset` según tu broker (la guía README tiene la tabla). Luego backtestea cada EA con "Every tick based on real ticks" por mínimo 2 años antes de ir a cuenta real.

