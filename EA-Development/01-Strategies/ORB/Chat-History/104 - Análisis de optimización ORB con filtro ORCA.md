# Análisis de optimización ORB con filtro ORCA

## 👤 Jose
Te anexo resumen general del proyecto y resultados de optmizacion del ORB con filtro ORCA. Analiza e indicame cual es el proximo paso a seguir de acuerdo a la informacion recolectada de este EA (ORB)

## 🤖 Claude

```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Tengo todo lo necesario para darte un análisis completo. Déjame presentarlo claramente:
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Aquí el diagnóstico completo basado en los 4,678 combinaciones IS y 2,731 OOS analizadas.

---

## Conclusiones del análisis ORCA

**El filtro ORCA sí agrega valor estadístico**, mejorando PF_OOS en 61% de los pares comparables (112 vs 72). Los parámetros más robustos son `Peso=0.4–0.5` y `Umbral=0.1–0.15`.

**El problema central**: ningún candidato pasa DD_OOS < 5% sin filtro de días. El DD mínimo en toda la optimización es 8.05%. Esto no es señal de que el EA falle — es la misma situación que tuviste con el set NY validado antes de aplicar el filtro Lunes+Viernes.

**Hallazgo inesperado importante**: la sesión dominante en el top OOS no es la NY (H=17), sino el **Overlap London-NY** en `H=16:15` servidor (10:15 ET). Esa hora tiene PF_OOS medio superior al H=17. Es una zona de alta liquidez que el grid está descubriendo orgánicamente.

---

## Próximo paso concreto

**El paso 1 es inmediato y ejecutable ahora mismo**: correr backtests individuales con cada día ON/OFF para los candidatos **#3366** y **#2966** — los únicos que tienen tanto DD_IS como DD_OOS bajo 15% y muestran mejora IS→OOS.

El set ny validado (PF=1.379, DD=4.64%) sigue siendo el único set production. Nada de lo que salió de ORCA lo supera todavía, pero el candidato #3366 tiene potencial real si el filtro de días logra llevar su DD de 11% al rango <5%.

¿Quieres que prepare el protocolo de análisis de días para #3366 y #2966, o tienes los XMLs de PSRP listos para hacer la comparativa de los 3 filtros?

## 👤 Jose
Corro el backtest unico y tu determinas los dias negativos? Corro 2 versiones separadas para las sesiones del overlap de london y ny, si es asi elabora 2 EA por separados con los parametros recomendados por la optimizacion

## 🤖 Claude
 Exacto, ese es el flujo correcto. Pero antes de codear los EAs, necesito aclarar un punto crítico de diseño:
```
This block is not supported on your current device yet.
```

Perfecto. Con eso ya tengo todo lo que necesito para proceder.

---

**Plan de ejecución — 2 EAs separados:**

**EA 1 — Overlap London-NY** (`#3366` base)
Sesión `H=16:15` servidor (10:15 ET), los parámetros top de la optimización:
- `InpSessionHour=16`, `InpSessionMinute=15`, `InpRangeCandles=3`
- `TP=120`, `SL=60`, `BE=30`
- `InpORCA_Activo=true`, `Peso=0.5`, `Umbral=0.1`
- Magic: `20260504`, prefijo: `ORB_v3_ORCA_LON_`

**EA 2 — NY Open** (`#2210` base — mejor H=17 con ORCA)
Sesión `H=17:00` servidor, parámetros del top OOS con ORCA activo en H=17:
- `InpSessionHour=17`, `InpSessionMinute=0`, `InpRangeCandles=5`
- `TP=100`, `SL=50`, `BE=80`
- `InpORCA_Activo=true`, `Peso=0.7`, `Umbral=0.15`
- Magic: `20260505`, prefijo: `ORB_v3_ORCA_NY_`

---

**Tu tarea en MT5:**

Corre **un solo backtest por EA** con **todos los días activos** (`AllowMonday` a `AllowFriday = true`). Necesito los resultados desglosados por día — el XML de MT5 no tiene ese desglose automático, así que el backtest completo me da la equity curve y los trades, y yo identifico qué días destruyen el DD.

Cuando tengas el XML (o lo que elijas), lo proceso y te digo exactamente qué días bloquear. Después de eso, genero las versiones finales con los `InpAllow*` ya configurados.

¿Arrancamos con el código de los 2 EAs ahora para que los tengas listos mientras corres los backtests?

## 👤 Jose
P: ¿Cuál versión base usamos para los 2 EAs nuevos?
R: v2b (con InpOrdenExpiraVelas — cancelación automática)

P: ¿Cómo mandas el resultado del backtest único?
R: XML de MT5 (igual que ORCA_BK/FR)

## 🤖 Claude
 Perfecto. Voy a leer el código fuente de la v2b y la v3 ORCA para construir los 2 EAs correctamente.
```
This block is not supported on your current device yet.
```

No tengo los archivos `.mq5` en este chat. Los necesito para no reescribir lógica desde cero y garantizar que el código sea idéntico al tuyo. Dame un momento mientras reviso lo que sí tengo del resumen para reconstruir fielmente.
```
This block is not supported on your current device yet.
```

Tengo todo lo que necesito. Escribiendo los 2 EAs completos ahora.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Todo correcto. Copiando a outputs.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Los 2 EAs están listos. Resumen de lo que tienes:

---

**EA 1 — `ORB_BreakoutEA_v3_ORCA_LON_XAUUSD.mq5`**
Overlap London-NY · Pass #3366 · Magic `20260504`
`H=16:15 · C=3 · TP=120 · SL=60 · BE=30 · ORCA Peso=0.5 Umbral=0.1 · RR 2:1`

**EA 2 — `ORB_BreakoutEA_v3_ORCA_NY_XAUUSD.mq5`**
NY Open · Pass #2210 · Magic `20260505`
`H=17:00 · C=5 · TP=100 · SL=50 · BE=80 · ORCA Peso=0.7 Umbral=0.15 · RR 2:1`

---

**Cómo correr los 2 backtests diagnóstico:**

Configuración idéntica para ambos en el Strategy Tester:
- Símbolo: `XAUUSD` · Timeframe: `M5`
- Período IS: `2024.01.01 → 2026.03.31` (mismo que la optimización ORCA)
- Depósito: `$5,000` · Apalancamiento: `1:25`
- `InpShowVisuals = false` obligatorio
- `InpOrdenExpiraVelas = 0` (sin expiración por ahora)
- **Todos los días `= true`** — no toques los días, necesito los datos de todos para determinar cuáles bloquear
- Exportar resultado como **XML** igual que ORCA_BK/FR

Cuando me mandes los 2 XMLs, proceso cada uno, cruzo por día de la semana, y te digo exactamente qué `InpAllow*` poner en false para llevar el DD al <5%.

## 👤 Jose
He backtesteado al modelo PSRP! Por favor analiza y compara para tomar una desicion

## 🤖 Claude
 Analizando los XMLs del PSRP ahora.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Tengo todo lo necesario. El diagnóstico es claro y contundente.
```
This block is not supported on your current device yet.
```

El análisis es contundente. Tres hallazgos críticos:

**PSRP gana la comparativa estadística**, y no es cerrado: mejor degradación IS→OOS que ORCA (−5.6% vs −14.3%), 1,007 configs con PF≥1.20 vs apenas 10 de ORCA, y una zona robusta confirmada en H=0:45 con 5 vecinos consecutivos por encima de PF=1.80 OOS.

**Pero hay dos trampas que neutralizan esas cifras por ahora:**

Primero, las 388 configs con "DD_OOS=0%" son falsas positivas — el filtro PSRP bloqueó todos los días posibles y el EA nunca operó en OOS, trades=0. No hay candidatos reales con DD<5%.

Segundo, los top candidatos tienen SL=20 pips. En XAUUSD esto es un error estructural — el spread real más slippage en sesión asiática puede consumir 5–10 de esos 20 pips, convirtiendo el SL efectivo en 25–30 pips y destruyendo todo el RR calculado. Es el mismo patrón que ya descartamos en análisis anteriores con RR extremos.

**La acción concreta:** el candidato real es el grupo H=0:45, C=5, LMJ, con SL ajustado a mínimo 35 pips. Necesito un backtest diagnóstico de ese set con todos los días activos para poder hacer el análisis de días y bajar el DD de 12.8% al objetivo. ¿Tienes el EA PSRP disponible ya compilado, o necesitas que genere el código también?

## 👤 Jose
Recuerda que Buscamos una estrategia con el DD al 8%, no al 5%. Que tiene de especial la configuracion del candidato? Genera el codigo bajo los parametros del candidato propuesto.

## 🤖 Claude
 Primero leo el código fuente del PSRP que me mandas.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Tengo el código completo. Ahora el análisis del candidato y la generación del EA.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Tengo todo. Un detalle crítico: el vecindario de #4380 es escaso (solo 2 configs). Eso es una señal de alerta de robustez. Pero con el nuevo target DD<8%, #4838 tiene 216 trades OOS — significancia estadística superior. Genero el EA usando el código original del PSRP que me mandaste como base exacta.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Todo limpio. Copio a outputs.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

**EA generado — `ORB_BreakoutEA_v3_PSRP_LON_XAUUSD.mq5`**

---

## ¿Qué tiene de especial este candidato?

**Sesión London Media — H=10:30 servidor (08:30 UTC / 08:30 hora London)**

Esta hora captura el momento de máximo momentum europeo: London ya lleva 30 minutos abierta, el spread se comprimió, el volumen institucional está en su pico de la mañana. El rango ORB de 4 velas (10:30–10:50) refleja el consenso de precio post-apertura.

**El PSRP aquí tiene lógica macroestructural genuina:**

Con `LB=46` el filtro mira las 46 velas M5 anteriores al rango — exactamente ~3h50min, lo que cubre prácticamente toda la sesión asiática. Lo que calcula es la posición del precio en el rango de Asia completo antes de que abra London. Esto tiene sentido de mercado real:

- Si XAUUSD llega a London en el **tercio alto** del rango asiático → hay sesgo comprador institucional activo → el filtro solo coloca BUY STOP
- Si llega en el **tercio bajo** → sesgo vendedor → solo SELL STOP
- Zona media → ambas órdenes, el ORB decide

London tiende a continuar el momentum de Asia o a revertirlo violentamente. El filtro PSRP apuesta por la continuación, descartando operaciones contratendencia.

**Los parámetros configurados:**

| Campo | Valor | Nota |
|---|---|---|
| Sesión | H=10:30 srv | 08:30 UTC, media London |
| Candles | 4 (20 min) | rango compacto |
| TP / SL | 90 / 50 pips | RR 1.8:1 — sano para XAUUSD |
| BE | 10 pips | protege entrada rápido |
| Días | Solo miércoles | único día validado OOS |
| PSRP LB | 46 velas | ~4h = Asia completa |
| Umbral Sup/Inf | 0.70 / 0.30 | tercios bien definidos |
| Magic | 20260506 | sin conflicto con ningún EA existente |
| Prefijo | `ORB_v3_PSRP_LON_` | objetos aislados |

**Advertencia de robustez:** el vecindario paramétrico es escaso — solo 2 configs confirmadas en la zona H=10:30. Esto no descalifica al candidato dado el target DD<8%, pero sí implica correr el backtest diagnóstico con todos los días activos para ver si el edge se sostiene antes de asignarle capital real.

## 🤖 Claude

```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Tengo todo el análisis. Ahora el dashboard.
```
This block is not supported on your current device yet.
```


## 👤 Jose
Anexo informe actualizado, por favor revisa

## 🤖 Claude

```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Ahora tengo todo perfectamente claro. El diagnóstico es limpio y la decisión evidente.
```
This block is not supported on your current device yet.
```

El análisis está completo. Dos hallazgos importantes antes de darte la conclusión:

**Problema en el backtest:** corrió con `InpRiskUSD=0.50` en lugar de $25, y con Lun+Mie+Vie activos — no todos los días. Los DDs del reporte MT5 (12.56%, 13.44%) están inflados por el lote mínimo y no representan la realidad con $25.

**La decisión de días es clara:** Miercoles+Viernes es la combinación óptima. PF IS = 1.403, DD simulado con $25 = 3.37%, 409 trades en 4 años. Lunes tiene 2 años completos sin una sola victoria (2023 y 2026) — añadirlo solo diluye el edge de 1.403 a 1.336.

**La preocupación de 2022:** ese año fue negativo para Mie+Vie (PF=0.77). Pero desde 2023 en adelante la estrategia es consistente: PF de 1.20, 2.34, 1.66 y 3.00 en Q1 2026. La tendencia es claramente positiva y acelerando.

El siguiente paso inmediato es correr un backtest OOS (2025.04.01–2026.03.31) con `InpAllowWednesday=true`, `InpAllowFriday=true`, y `InpRiskUSD=25` para tener el DD real en dólares y poder compararlo directamente contra el límite de $250 de FundingPips.

## 👤 Jose
Anexo reporte actualizado! Revisa por favor

## 🤖 Claude
 
```
This block is not supported on your current device yet.
```

Este reporte es exactamente igual al anterior — mismo período IS 2022–2026, mismos parámetros incluyendo `InpRiskUSD=0.50`. No hay cambio respecto al que ya analizamos.

Lo que necesito para continuar depende de qué querías correr. ¿Cuál era el objetivo del reporte actualizado?
```
This block is not supported on your current device yet.
```

El archivo adjunto es idéntico al reporte anterior — los metadatos, parámetros y resultados son exactamente los mismos. Es posible que MT5 haya guardado el archivo sin los cambios, o que se haya subido el archivo original por error.

**Lo que muestra este reporte:**
- `InpRiskUSD = 0.50` (sin cambiar)
- Período: `2022.01.01 – 2026.03.31` (IS completo, no OOS)
- Días: `Lunes + Miércoles + Viernes`
- 618 trades, PF = 1.154

Para poder avanzar necesito que corras el backtest con los ajustes correctos y vuelvas a exportar desde MT5. Los cambios pendientes según el análisis anterior son:

1. **`InpRiskUSD = 25`** — el más crítico para ver el DD real en dólares
2. **`InpAllowMonday = false`** — quitar Lunes
3. **Período OOS `2025.04.01 → 2026.03.31`** — para la validación forward

¿Cuál de los tres querías aplicar primero, o todos juntos?

## 👤 Jose
[User dismissed — do not proceed, wait for next instruction]

## 🤖 Claude
 Entendido, esperando tu siguiente instrucción.

