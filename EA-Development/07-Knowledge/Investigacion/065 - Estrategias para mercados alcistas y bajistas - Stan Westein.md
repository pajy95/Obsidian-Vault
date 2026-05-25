# Estrategias para mercados alcistas y bajistas

[[Estrategias]]

## 👤 Jose
Hola Claude. Hace un tiempo atras me lei este libro: Secretos para ganar en los mercados alcistas y bajistas

## 🤖 Claude
The user is mentioning a book they read: "Secretos para ganar en los mercados alcistas y bajistas" (Secrets for winning in bull and bear markets). This is likely the Spanish translation of Stan Weinstein's "Secrets for Profiting in Bull and Bear Markets."

Let me respond naturally, acknowledging the book.¡Hola Jose! Sí, ese es un clásico — *"Secrets for Profiting in Bull and Bear Markets"* de **Stan Weinstein**. Es un libro muy respetado, especialmente por su enfoque en el análisis de etapas (Stage Analysis) y el uso de la media móvil de 30 semanas para identificar en qué fase se encuentra una acción: acumulación, avance, distribución o declive.

Es un marco bastante sólido para entender la estructura del mercado desde una perspectiva más macro. ¿Qué te pareció? ¿Hay algo del libro que quieras discutir o aplicar a tu trading algorítmico?

## 👤 Jose
En Base a la estrategia, realiza una investigacion profunda para determinar si es rentable operarla en pleno 2026, a que activo seria bueno operarla?  De ser positiva su rentabilidad, crear un EA para MT5.

## 🤖 Claude
The user wants me to research Stan Weinstein's Stage Analysis strategy to determine if it's profitable in 2026, which assets to apply it to, and then create an MQL5 EA for MT5.

Let me ask a couple of clarifying questions to make sure the research and EA are tailored well.Excelente idea, Jose. Antes de lanzar la investigación, quiero afinar algunos detalles para que el research y el EA queden lo más alineados posible con lo que buscas:
```
This block is not supported on your current device yet.
```

Waiting for user responses to proceed.Esto me ayudará a enfocar bien la investigación y luego construir un EA sólido y alineado con tu estilo de trading.

## 👤 Jose
P: ¿Qué tipo de activos te interesan para operar esta estrategia? (Seleccione todas las que correspondan)
R: Acciones/ETFs (SPY, QQQ, etc.), Índices CFD (US30, NAS100, US500), Forex (pares mayores), Commodities (XAUUSD, Petróleo)

P: ¿Qué timeframe prefieres para el EA?
R: Déjalo a criterio del research

P: ¿El EA debe operar en ambas direcciones o solo longs en alcista?
R: Ambas direcciones

## 🤖 Claude
The user wants a deep research into whether Stan Weinstein's Stage Analysis strategy is profitable in 2026, across multiple asset classes (stocks/ETFs, indices CFD, forex, commodities), both directions, with timeframe left to research. Then if profitable, build an EA for MT5.

This is a clear and detailed request. Let me launch the research task right away.Perfecto Jose, tienes una visión amplia — todos los activos, ambas direcciones, y timeframe a criterio del análisis. Voy a lanzar una investigación profunda sobre la rentabilidad de la estrategia de Stage Analysis de Weinstein en el contexto actual de 2026.
```
This block is not supported on your current device yet.
```

Your Weinstein Stage Analysis research report is ready. It covers the four-stage framework mechanics, backtested performance data (440+ trades over 23 years), asset class suitability rankings for 2026, optimal timeframe analysis, and long vs. short bias findings. The report concludes with a specific MT5 Expert Advisor architecture recommendation centered on XAUUSD daily charts, including entry filters, stop-loss logic, position sizing parameters, and key implementation considerations for automating the strategy.
```
Viewing artifacts created via the Analysis Tool web feature preview isn’t yet supported on mobile.
```



## 👤 Jose
En español

## 🤖 Claude
The user wants the research report in Spanish. Let me also now proceed to build the EA based on the research findings. But first, let me re-read what they asked - they said "En español" which means they want the report in Spanish. Let me translate the artifact and then proceed to build the EA.

Actually, looking back at the conversation, the user asked me to:
1. Do deep research on whether Weinstein's strategy is profitable in 2026 ✓
2. Determine which asset to trade it on ✓
3. If profitable, create an EA for MT5

The research concluded it IS profitable, especially on XAUUSD daily charts. So I need to:


1. Translate the report to Spanish first
2. Then build the EA in MT5

Let me start with the translation since that's the immediate request, and I can follow up with the EA development afterward.Voy a traducir el reporte completo al español y luego procederemos con la creación del EA.
```
This block is not supported on your current device yet.
```

Now let me present the file and then ask if they want me to proceed with building the EA.
```
This block is not supported on your current device yet.
```

Good, now the report is in Spanish. The research concluded positively - the strategy IS profitable, especially on XAUUSD daily charts. The user originally asked me to create an EA if the research was positive. Let me ask if they want me to proceed with building the EA now.Ahí tienes el reporte completo en español, Jose. El resumen ejecutivo es claro:

**Veredicto: SÍ es rentable en 2026**, especialmente en **XAUUSD (oro) en gráficos diarios con SMA de 200 días y sesgo largo**. El oro ha subido de $2,000 a $5,000+ en una tendencia alcista textual de Etapa 2, y las materias primas muestran el comportamiento tendencial más fuerte entre todas las clases de activos.

Dado que el research es positivo, ¿quieres que proceda a construir el EA en MQL5? La arquitectura sería:

- **Activo principal**: XAUUSD en D1
- **Motor central**: SMA 200 como clasificador de etapas (máquina de estados)
- **Filtros**: Confirmación de volumen (2× promedio), pendiente de MA, ADX > 20, MA50 > MA200
- **Stops**: Híbrido ATR(14) × 2.5 + swing low
- **Position sizing**: 1% de riesgo por trade
- **Dirección**: Long principal + shorts opcionales con 50% del tamaño en Etapa 4

## 👤 Jose
Necesito que me seas sincero. Si es posible que sea rentable esta estrategia?

## 🤖 Claude
Jose is asking me to be honest about whether this strategy can actually be profitable. He wants a sincere, no-BS assessment. Let me give him a straight, honest answer based on what the research actually shows, without sugarcoating.

Let me think about this carefully:

1. Weinstein's Stage Analysis is essentially a trend-following system based on moving averages
2. The backtesting evidence is real but has caveats
3. The strategy has known weaknesses
4. Automating discretionary elements is a real challenge

Let me be direct and honest.Te voy a ser completamente directo, Jose.

**La respuesta corta: Sí, puede ser rentable. Pero no de la forma glamurosa que el reporte sugiere.**

Hay que separar lo real de lo exagerado. Lo que SÍ está probado es que las estrategias de trend-following basadas en medias móviles largas (como la SMA de 200 días) han funcionado consistentemente durante más de 100 años, y la evidencia académica de Faber, AQR y Bulkowski es legítima. No es que "ganas más" que buy-and-hold — es que **pierdes mucho menos en las caídas**, y eso compuesto a lo largo del tiempo te pone adelante.

Ahora, lo que necesitas escuchar con honestidad:

**El 80% de la ventaja de Weinstein es discrecional.** Identificar la "calidad de la base", evaluar si la resistencia superior es real, y el análisis sectorial top-down son cosas que un trader experimentado hace con los ojos — no una máquina de estados con pendiente de MA y volumen. Un EA solo puede capturar una versión simplificada de esto.

**Lo que realmente estás construyendo es un sistema de cruces de MA con filtros.** Llamarlo "Weinstein Stage Analysis EA" es ponerle un nombre bonito a lo que en esencia es: comprar cuando el precio cruza arriba de la SMA 200 con confirmación de volumen y ADX, y vender cuando cruza abajo. Eso no es malo — de hecho funciona — pero hay que ser claros sobre lo que es.

**El oro en $5,000+ es un arma de doble filo.** Sí, la tendencia es fuerte. Pero entrar a un trend-following en un activo que ya subió 150% significa que tus primeras señales probablemente sean re-entradas después de pullbacks, no la captura del movimiento grande. Y si el conflicto geopolítico se resuelve, la reversión puede ser brutal y rápida — más rápida que lo que una SMA de 200 períodos puede detectar.

**La tasa de acierto real será 35-45%, no 69% ni 81%.** Esos números de Bulkowski son de operaciones manuales seleccionadas con criterio discrecional. Un EA automatizado genera muchas más señales, incluyendo las falsas que un humano habría filtrado. Vas a tener rachas de 5-8 pérdidas consecutivas y eso es normal.

**El spread y el swap en XAUUSD comen margen.** En D1, tus trades duran semanas o meses. El swap nocturno en gold CFD, dependiendo de tu broker, puede costar $3-8 por lote por noche. Eso es un drag real sobre el rendimiento que los backtests académicos no capturan.

Dicho todo esto — **¿funciona la idea base? Sí.** Un sistema que dice "compra cuando el precio está arriba de la MA de largo plazo con momentum confirmado, y sal cuando se rompe" tiene edge positivo demostrado en commodities. El oro específicamente tiende bien en temporalidades largas. Y tu ventaja real versus un trader discrecional es que el EA ejecuta sin emoción y no se salta los stops.

Mi recomendación sincera: lo construimos, lo backtestamos en el Strategy Tester de MT5 con datos reales de tu broker, y **dejamos que los números hablen** antes de poner dinero real. Si el Profit Factor sale arriba de 1.3 y el drawdown está por debajo del 15% en un backtest de 3-5 años, tienes algo viable. Si no, iteramos.

¿Procedemos con esa mentalidad realista?

## 👤 Jose
Procede manteniendo el sesgo realista y honesto! Por otro lado en que otros activos y temporalidades puede ejecutarse?

## 🤖 Claude
Jose wants me to proceed with building the EA while maintaining a realistic and honest bias. He also wants to know what other assets and timeframes the strategy can work on. Let me first read the relevant skill files, then build a solid EA.

Let me think about the multi-asset, multi-timeframe angle honestly:

**Assets that genuinely work with MA-based trend following:**
1. XAUUSD (Gold) - D1 - Primary recommendation, strong trending behavior
2. US Oil/WTI (USOIL) - D1 - Commodities trend well
3. US indices (US500, NAS100) - D1/W1 - But currently range-bound


4. Major forex pairs - D1 - Weakest fit, though USDJPY and GBPUSD show some trending potential

I should be straightforward about the strengths and limitations of each asset before diving into the EA build, and I'll want to check the backtest expert skill file to ensure I'm following best practices.Buena pregunta. Antes de construir, vamos a ser honestos sobre dónde tiene y dónde NO tiene edge este tipo de sistema.
```
This block is not supported on your current device yet.
```

Good research. Now let me read the skill files before building the EA.Perfecto, ahora con datos frescos. Déjame leer las skill files necesarias antes de construir el EA.
```
This block is not supported on your current device yet.
```

Now let me build the EA. Let me be thorough and honest about multi-asset compatibility. I'll create a well-structured EA that's parametric enough to work on multiple assets.Ahora déjame ser completamente transparente sobre los activos y temporalidades antes de construir el EA.

Aquí va la verdad cruda basada en la evidencia:

**Donde SÍ funciona el trend-following con MA 200 (con datos reales):**
```
This block is not supported on your current device yet.
```

Now let me create a comprehensive visualization showing asset suitability, then build the EA.Aquí va el mapa de realidad sobre activos y temporalidades:
```
This block is not supported on your current device yet.
```

Now let me build the EA. I need to be practical and create something that's robust, multi-asset capable, and honest about what it is.Siendo brutalmente honesto: el trend-following funciona mejor en commodities como azúcar, café, algodón y gasolina, y nunca se ha encontrado valor real en estrategias de tendencia para acciones a menos que uses temporalidades de al menos 100 días. El índice MLM usa solo la media móvil de 200 días en 25 mercados de commodities y ha demostrado muy buenos retornos ajustados al riesgo durante muchas décadas.

En resumen: el EA lo diseñaré **multi-activo y parametrizable**, pero siendo claros en que su terreno natural es commodities en D1, funciona aceptablemente en índices, y en forex es el más débil.

Ahora construyo el EA:
```
This block is not supported on your current device yet.
```

Now let me build the EA. I'll create a comprehensive, well-commented MQL5 Expert Advisor. Let me think about the design:

Key design decisions:
1. Multi-asset: parametrizable for XAUUSD, US500, US30, NAS100, USDJPY, etc.
2. D1 timeframe primary
3. SMA 200 as core stage classifier
4. Volume confirmation using tick volume (with honest caveat)
5. ADX filter for trend strength
6. ATR-based stops
7. Percentage risk position sizing
8. Long bias with optional shorts
9. Trailing stop using MA or swing low


Writing the Expert Advisor code...
```
This block is not supported on your current device yet.
```

Now let me verify the file compiles conceptually and copy it to outputs.
```
This block is not supported on your current device yet.
```

Good, 906 lines. Let me copy to outputs and present.
```
This block is not supported on your current device yet.
```

Now present the file.
```
This block is not supported on your current device yet.
```

Good. Now let me give Jose a clear, honest summary of what to do next.Ahí tienes el EA, Jose. 906 líneas, completamente comentado en español, con una guía de backtesting integrada al final del código.

Lo que necesitas saber antes de ponerlo en el Strategy Tester:

**Activos en orden de probabilidad de éxito** (de mayor a menor):

XAUUSD D1 es el candidato principal — tendencia clara de Etapa 2, commodities tienden más fuerte que cualquier otra clase. Luego XAGUSD D1 y WTI/USOIL D1 como alternativas en commodities. Después US500 y NAS100 en D1, pero sabiendo que los índices son más mean-reverting. Y por último USDJPY D1 como el "menos malo" de forex.

**Lo que NO hacer**: no optimizar buscando el máximo profit. Busca mesetas — si el EA es rentable con MA entre 150 y 250, con ATR entre 2.0 y 3.0, y con ADX entre 15 y 25, entonces tienes edge real. Si solo funciona con MA exactamente en 197 y ATR en 2.37, es curve-fitting y no sobrevivirá en live.

**Primer paso**: backtest con parámetros default en XAUUSD D1, modelo "Every tick based on real ticks", mínimo 2021-2026. Si el Profit Factor sale arriba de 1.3 y el drawdown está por debajo del 20%, iteramos desde ahí.

¿Quieres que ajustemos algo del EA antes de que lo lleves al Strategy Tester?

