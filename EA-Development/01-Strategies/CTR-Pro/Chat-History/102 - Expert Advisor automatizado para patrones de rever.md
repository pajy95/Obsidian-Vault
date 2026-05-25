# Expert Advisor automatizado para patrones de reversión con liquidez

## 👤 Jose
Hola Claude, quiero desarrollar un Expert Advisor totalmente automatizado diseñado para operar patrones estructurados de reversión con control de riesgo estricto y lógica de ejecución profesional.
El sistema identifica barridos de liquidez entre máximos y mínimos recientes y ejecuta operaciones únicamente cuando el precio confirma una posible reversión.
Esta versión incluye gestión avanzada de posiciones, filtros de sesión y un panel informativo en tiempo real.
Lógica de la Estrategia
CTR Pro detecta barridos de liquidez(A la hora/minuto indicada de inicio) a corto plazo:
• Compra: El mínimo previo es superado y el precio cierra nuevamente por encima, e • Venta: El máximo previo es superado y el precio cierra nuevamente por debajo
La estrategia está diseñada para evitar el sobretrading y ejecuta solo una operación por señal válida.
Gestión de Riesgo y Operaciones
Incluye:
• Stop Loss y Take Profit configurables • Cálculo automático de lotaje basado en porcentaje de riesgo • Límite máximo de operaciones por día • Filtro de spread • Filtro de horario de sesión
Todos los parámetros son personalizables.
Panel Integrado en el Gráfico
El dashboard muestra:
• Estado del sistema (Activo / Inactivo) • Monitoreo del spread • Beneficio diario acumulado • Contador de operaciones
• Indicador visual de TP, SL, IN. • Botones de control manual (Cerrar todo / Cerrar ganancias / Pausar)
Recomendaciones de Uso
Las variables que incluira dentro de los parametros editables seran: - Buy Only, Sell Only, Ambos.
* Mantener solo los ultimos N dibujos.
* Riesgo por Operacion en USD.
* Cantidad maxima de trades por dia
* Maximos puntos de Spread
* Slippage puntos
* SL en pips
* TP en pips
* Operar Lunes
* - Operar Martes
* Operar miercoles
* Operar jueves
* Operar viernes
* Hora de Inicio
* Minutos de Inicio
* Hora de Fin
* Minuto de Fin
En la imagen anexa, te indico como debe verse visualmente

## 🤖 Claude
 The user wants to develop a fully automated Expert Advisor (EA) for MetaTrader 5 (MQL5) called "CTR Pro" that detects liquidity sweeps and executes reversal trades. Let me analyze the image and the requirements carefully.

From the image, I can see:
1. Left panel: A BUY trade (CTR ENTRY with green up arrow) - price swept below a low, then closed back above → long entry, with TP and SL marked, showing +$1032.59 profit
2. Middle panel: Another BUY trade (CTR ENTRY) - similar pattern, price swept low then reversed up, TP: 1.16375, SL: 1.16105


3. Right panel: A SELL trade (CTR ENTRY with orange down arrow) - price swept above a high, then closed back below → short entry, SL: 1.16525, TP: 1.16255

The visual setup includes entry arrows in green for buys and orange for sells, horizontal TP and SL lines, entry level markers, pink dashed lines indicating the sweep zones, and connecting dashed lines to the profit/loss targets with "CTR ENTRY" labels.

Now I'm building the MQL5 EA code to implement this liquidity sweep detection and reversal trading strategy, starting with the core logic for identifying when price breaks through support or resistance and then reverses back.

Writing the EA code... Setting up the input parameters for the EA's core trading logic, including trade direction, risk management settings, and stop loss/take profit levels.

Now I'm defining the trading schedule with day-of-week filters and session time windows to control when the EA operates.

Defining global variables... Setting up the expert advisor initialization with trade parameters and dashboard creation, then handling deinitialization by cleaning up all UI objects. Now I'm working through the main tick function—resetting daily counters, updating the dashboard display, and applying various filters like pause state, trading day validation, session timing, daily trade limits, and spread checks before evaluating new bar conditions.

Continuing with the liquidity sweep detection logic... I'm checking if the current candle dipped below the previous low but closed above it—a bullish reversal signal. If that condition is met and buy signals are enabled, I calculate the entry price, stop loss, and take profit levels, then execute the trade if position sizing is valid.

Now I'm handling the opposite scenario for sell signals, where the candle spikes above the previous high but closes below it, indicating a bearish reversal. I'm setting up the entry, stop loss, and take profit for short positions using the same logic.

Defining the lot size calculation function... Setting up the signal drawing function with a counter to track each signal, then creating visual markers on the chart for the entry point, take profit, and stop loss levels with appropriate colors and arrow styles. Setting up the take-profit line with its label and price display, then moving on to configure the stop-loss line... Still writing the drawing code... Writing utility functions... Now I'm iterating through all open positions to sum up the daily profit from trades matching this symbol and magic number, then moving on to build the dashboard interface with a background panel and title elements.

Building the dashboard layout... Still writing panel labels... Building the panel UI... Updating the dashboard values... Finishing the trades display with the max trades limit, then updating the pause button text to toggle between "Reanudar" and "Pausar" before redrawing the chart. Now I'm setting up the chart event handler to process button clicks, starting with the close all positions button.

Still writing event handlers... Finishing the rectangle setup and creating a text label helper...

Now I'm building helper functions for UI elements — setting up a label creator that positions text on the chart with customizable fonts and colors, then moving into a button creation function. Finishing the button styling with font properties and making it non-selectable. Now I'm thinking about how to make this more complete and polished—I need to add the visual elements from the chart like the dashed entry line, solid green TP line, solid red SL line, connecting dashes, and the entry label. I'm also realizing the sweep detection logic needs to check if the previous candle sweeps the high or low of the candle before it. and then closing back inside. I should use candles 1 and 2 (index from current bar).

Also, I notice in the chart there seem to be pink dashed diagonal lines connecting the entry to the TP/SL levels - these are trend lines drawn from entry point to TP/SL. Let me implement those properly.

Now I'm looking more carefully at each chart example to get the visual details right. The buy signals show a green up arrow with "CTR ENTRY" text in pink, then horizontal lines for TP (green solid with label) and SL (red solid with label), plus a dashed line marking the entry level itself. The sell signals follow the same pattern but with a down arrow instead. I can see diagonal dashed lines tracing the price movement from entry through to the TP and SL levels, which I'll need to draw as trend lines connecting those points.
```
This block is not supported on your current device yet.
```

Now let me write the complete MQL5 EA code. This will be a comprehensive file. Let me structure it properly.Ahora voy a construir el EA completo. Déjame analizar la imagen y crear todo el código.
```
This block is not supported on your current device yet.
```

Now let me copy it to outputs and present it.
```
This block is not supported on your current device yet.
```

Great, 700 lines. Now let me create a visual preview of the panel and strategy logic.Ahora te muestro un preview visual del panel y la lógica:
```
This block is not supported on your current device yet.
```

Now let me create the visual preview of the EA panel and the strategy logic.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

El EA está listo — **700 líneas** de MQL5 completamente estructurado. Aquí el resumen de lo que contiene:

---

**Detección de barridos** — `DetectLiquiditySweep()` analiza las velas `[1]` y `[2]` en cada nueva barra:
- **BUY**: `low[1] < low[2]` AND `close[1] > low[2]` → mínimo barrido con recuperación
- **SELL**: `high[1] > high[2]` AND `close[1] < high[2]` → máximo barrido con rechazo

**Gestión de riesgo** — `CalcLots()` calcula el lotaje exacto basado en USD de riesgo vs distancia del SL en puntos usando el tick value del broker, con floor al step mínimo.

**Dibujos en chart** — Por cada señal se crean 10 objetos con prefix único (`CTR_S{N}_*`): flecha de entrada, label "CTR ENTRY", línea TP/SL/Entry, líneas diagonales punteadas entry→TP y entry→SL, y la línea de barrido (el nivel previo que fue perforado). El sistema elimina automáticamente los dibujos más antiguos al superar `InpMaxDrawings`.

**Panel interactivo** — Los 3 botones funcionan via `OnChartEvent`: "Cerrar Todo" cierra todas las posiciones del EA, "Cerrar +$" solo cierra las rentables, y "Pausar/Reanudar" suspende la lógica sin remover el EA.

**Filtros combinados** en cascada: día de semana → sesión horaria → trades diarios → spread → nueva barra → y finalmente el patrón de barrido.

Para instalar: copiar `CTR_Pro_EA.mq5` a `MQL5/Experts/` en tu directorio de datos de MT5, compilar en MetaEditor, y arrastrar al gráfico deseado.

## 👤 Jose
segun el simbolo EURUSD, como debo ajustarlo al EA

## 🤖 Claude
 The user is showing GBPUSD symbol specs but asking about EURUSD adjustment. Key specs visible:
- Digits: 5
- Contract size: 100,000 GBP
- Spread: Floating
- Stop level: 0
- Margin currency: GBP
- Profit currency: USD
- Calculation: Forex No Leverage
- Min volume: 0.01
- Max volume: 20
- Volume step: 0.01

For EURUSD, the specs are similar but contract size is 100,000 EUR. The EA's pip calculation and lot sizing should work fine since it uses `_Digits`, `_Point`, tick value, etc. dynamically.


Now I'm checking what needs adjusting for EURUSD specifically—the EA already handles 5-digit brokers correctly, but I should tune the stop loss and take profit parameters since EURUSD typically trades with tighter spreads (1-3 pips) compared to gold, and adjust the SL/TP values accordingly, probably around 10-20 pips for the stop loss.Viendo las specs del símbolo, el EA ya maneja automáticamente la mayoría de parámetros via `SymbolInfo*()`. Solo necesitas ajustar los **inputs** al abrir el EA en el gráfico EURUSD/GBPUSD:

---

**Lo que el EA detecta SOLO** (no necesitas cambiar nada en código):

| Propiedad | Valor visto | Cómo lo usa el EA |
|---|---|---|
| Dígitos: 5 | → pip = `_Point × 10` | ✅ ya calculado en `OnInit()` |
| Vol. mínimo: 0.01 | → `SYMBOL_VOLUME_MIN` | ✅ en `CalcLots()` |
| Vol. máximo: 20 | → `SYMBOL_VOLUME_MAX` | ✅ en `CalcLots()` |
| Paso volumen: 0.01 | → `SYMBOL_VOLUME_STEP` | ✅ en `CalcLots()` |
| Tick value USD | → rentabilidad por lote | ✅ automático |

---

**Los inputs que SÍ debes ajustar** (Forex ≠ XAUUSD):

| Parámetro | XAUUSD (default) | EURUSD/GBPUSD recomendado |
|---|---|---|
| `InpSL_Pips` | 30 | **10 – 15 pips** |
| `InpTP_Pips` | 60 | **20 – 30 pips** |
| `InpMaxSpread` | 30 pts | **15 pts** (EURUSD es muy tight) |
| `InpRiskUSD` | $50 | sin cambio necesario |
| `InpMaxPerDay` | 3 | sin cambio necesario |
| Hora inicio | 08:00 | **07:00** (apertura Londres) |
| Hora fin | 17:00 | **16:00** (antes del cierre NY overlap) |

---

**Una nota importante sobre el Spread flotante:**

El símbolo muestra **Spread: Flotante**, lo que significa que en noticias o apertura de sesión puede dispararse. Con `InpMaxSpread = 15` ya lo filtras, pero para GBPUSD sube a **20 pts** porque su spread natural es algo mayor que EURUSD.

El EA no requiere ningún cambio de código — solo configura los inputs al arrastrarlo al chart y estará calibrado correctamente para el instrumento.

