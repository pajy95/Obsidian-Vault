# Desarrollo de EA para EUR/USD

## 👤 Jose
Te anexo la informacion necesaria para desarrollar el EA para EUR/USD.

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

Perfecto. Tengo todo el código fuente y las specs de la imagen. Procedo a construir el EA completo.

**Specs confirmadas (imagen MT5 FundingPips EURUSD):**
- Dígitos: 5 → pipSize = 10 × _Point = 0.0001
- ContractSize: 100,000 EUR
- VolumeMin: 0.01 / VolumeMax: 20 / VolumeStep: 0.01
- Divisa de beneficio: USD ✅ (cuenta en USD, par directo)
- Spread: Flotante
- MagicNumber: 202404
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

EA completo. Aquí el resumen de todo lo que se adaptó y por qué:

---

## Cambios aplicados vs versión XAUUSD

**[FX-1] MinSL/MaxSL en pips** — El filtro de rango ahora usa `g_slPips = g_slDistance / g_pipSize`. Los 8–25 pips de rango típico en EURUSD no tienen ninguna relación con los $5.50–$15 de XAUUSD. Valores iniciales orientativos — **deben calibrarse** con el script calibrador.

**[FX-2] SpreadMax_Pips = 3.0** — Verificación en tres momentos: al confirmar el breakout (Fase B), como fallback sin ConfirmOnClose, y una última vez dentro de `ExecuteTrade` antes de abrir. Si el spread supera el umbral en Fase B, el EA espera otra vela en lugar de cancelar definitivamente.

**[FX-3] pipSize automático** — Detecta `_Digits` en OnInit. EURUSD (5 dígitos) → `pipSize = 0.0001`. Si en algún momento usas USDJPY (3 dígitos) → `pipSize = 0.01`. Sin hardcode.

**[FX-4] VPP via TickValue/TickSize** — Para XAUUSD usábamos `OrderCalcProfit` porque `TickValue` era inestable en el backtester MT5 para CFDs XCCY. En EURUSD (par directo, USD cotizado) `TickValue/TickSize` es estable → método directo, más limpio. El OnInit imprime el `valuePerPip` esperado de $10.00 para verificación visual inmediata.

**[FX-5] Filtro de rango en pips** — En XAUUSD `g_slDistance` se comparaba directamente en unidades de precio (que coincidían con dólares por la estructura del contrato). En EURUSD eso no funciona: un rango de 0.0015 no dice nada sin contexto. El filtro ahora compara `g_slPips`.

**[FX-6] CSV con pips** — `SL_Pips` y `RangePips` en lugar de `SL_Pts`. Columna extra `SpreadAtEntry_Pips`. Columna `ATR_OK` para auditar cuántos días filtró el ATR.

**[FX-7] SessionClose fijo 17:00 UTC** — No es input. En XAUUSD podías argumentar extenderlo. En Forex: riesgo de swap triple los miércoles si cruzas medianoche + pérdida del momentum NY.

**[FX-8] Label visual** — Muestra SL en pips y riesgo en $, no el `g_slDistance` en unidades de precio que es ilegible en EURUSD.

**[FX-9] MagicNumber 202404** — Tabla del documento maestro.

---

## Próximo paso antes del backtest

Necesitas el **script calibrador** para definir los valores reales de `MinSL_Pips` y `MaxSL_Pips`. Con los valores orientativos actuales (8–25 pips) el backtest correrá, pero si el percentil real P25 del EURUSD en ese horario es 12 pips, estarías perdiendo setups válidos. ¿Quieres que genere el calibrador como Fase 2?

## 👤 Jose
Genera el calibrador primero!

## 🤖 Claude

```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Listo. Guía de uso completa:

---

## Cómo ejecutarlo

1. Copiar `BreakoutNY_Calibrador_EURUSD.mq5` a `MQL5\Scripts\` en tu carpeta de MT5
2. Compilar en MetaEditor (F7) — sin errores esperados
3. Abrir el gráfico EURUSD M5
4. Antes de correrlo: **Herramientas → Centro Histórico → EURUSD M5 → Descargar todo** (máximo histórico disponible)
5. En Navigator → Scripts → arrastrar al gráfico → configuras `YearsToAnalyze = 5` (o más si tienes datos)
6. Revisar el **Journal** de MT5 buscando `RESULTADO FINAL`

---

## Qué leerás en el output

El script imprime esto en el journal:

```
RESULTADO FINAL — DISTRIBUCIÓN DE RANGOS NY
  n (días válidos)  : ~1250 (5 años × ~250 días)
  P25               : X.X pips  ← MinSL_Pips recomendado
  Mediana (P50)     : X.X pips
  P75               : X.X pips  ← MaxSL_Pips recomendado
  
  Estadísticas por día de semana:
  Día          n    Media   P25  Mediana   P75
  Lunes      250    15.2   9.1    14.5   21.3
  Martes     248    13.8   8.4    13.1   19.7
  ...

  ACCIÓN: Usar MinSL_Pips=X.X y MaxSL_Pips=X.X en el EA.
```

También exporta un CSV a `MQL5\Files\BreakoutNY_Calibracion_EURUSD.csv` con cada día individual — útil para abrirlo en Excel y ver la distribución histograma o filtrar por año.

---

## Lo que defines tras el calibrador

| Parámetro | Fuente | Lógica |
|-----------|--------|--------|
| `MinSL_Pips` | P25 del calibrador | Descarta días sin volatilidad suficiente para momentum |
| `MaxSL_Pips` | P75 del calibrador | Descarta días de volatilidad extrema (noticias tipo NFP) |

Con ese rango [P25–P75] el EA operará **aproximadamente el 50% de los días** — que es exactamente lo que queremos: la franja de días con rango "normal" donde el breakout de apertura NY tiene más probabilidad de seguimiento.

Cuando tengas los números del calibrador, los metemos en el EA y arrancamos el backtest de Fase 3.

## 👤 Jose
corrige esos errores

## 🤖 Claude
 Veo los errores. El problema central es que MQL5 **no soporta arrays de arrays** (`double dayRanges[6][]`). Hay que reemplazar esa estructura con arrays planos indexados. Corrijo todo:
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

Corregido. El problema raíz era uno solo con múltiples síntomas:

**MQL5 no soporta arrays de arrays** (`double dayRanges[6][]`). El compilador lo interpretaba como un array de `void*` o similar, generando en cascada todos los errores que veías: `invalid array access`, `cannot convert double to void[]`, `invalid index value`.

La solución fue reemplazar el array bidimensional por **5 arrays planos independientes** — uno por día de semana — con nombres explícitos (`dayRanges1` a `dayRanges5`). Más verboso pero perfectamente válido en MQL5.

Otros cambios menores de esta versión:
- Renombré la variable local `tickSize` a `tickSize2` para evitar colisión con el nombre del input (aunque en este caso no había input con ese nombre, es buena práctica)
- Eliminé el macro `#define PERCENTILE` y lo reemplacé por la función `Percentile()` — más limpio y sin riesgo de evaluación múltiple

Ahora debería compilar con **0 errores**. Sustitúyelo en `MQL5\Scripts\` y prueba F7.

## 👤 Jose
Por favor revisa y dime si existe un error

## 🤖 Claude
 Déjame leer los dos archivos XML primero.
```
This block is not supported on your current device yet.
```



## 👤 Jose
Por favor revisa y dime si existe un error

## 👤 Jose
Por favor revisa y dime si existe un error

## 🤖 Claude
 Déjame leer ambos XMLs primero.
```
This block is not supported on your current device yet.
```



## 🤖 Claude
 Déjame leer ambos archivos XML del backtester.
```
This block is not supported on your current device yet.
```


```
This block is not supported on your current device yet.
```

Los archivos XML no llegaron al servidor — solo están los que subiste antes. Esto pasa a veces cuando el archivo es grande o el upload falla silenciosamente.

¿Puedes intentar subirlos de nuevo? Si el problema persiste, también puedes:

1. **Copiar el contenido XML** directamente en el chat (si no es muy largo)
2. **Tomar un screenshot** del reporte en MT5 — puedo leer los números directamente de la imagen

Lo que más me interesa ver para detectar errores:

- **Total trades** y período del backtest
- **Profit Factor**, **Net Profit**, **Max DD**
- **Buy vs Sell** — cantidad y resultado por separado
- Si hay trades con **lotes anómalos** (demasiado grandes o pequeños)
- Si el **SL_Pips** en el CSV está en un rango razonable (8–25 pips esperado)

## 👤 Jose
Por favor revisa y dime si existe un error

## 🤖 Claude
 
```
This block is not supported on your current device yet.
```



## 👤 Jose
Por favor revisa y dime si existe un error

## 👤 Jose
Por favor revisa y dime si existe un error

