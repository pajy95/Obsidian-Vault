# Estrategia de trading para EURUSD

## 👤 Jose
Vamos a elaborar esta estrategia para el EURUSD

## 🤖 Claude

```
This block is not supported on your current device yet.
```

Perfecto. Aquí está el análisis completo y el plan de adaptación de BreakoutNY para EURUSD.

---

## BreakoutNY → EURUSD: Análisis de Adaptabilidad

### Lo que cambia fundamentalmente

La imagen muestra las specs del EURUSD en tu broker. Las diferencias críticas vs XAUUSD:

| Parámetro | XAUUSD | EURUSD |
|---|---|---|
| ContractSize | 100 oz | 100,000 EUR |
| Dígitos | 2 | 5 |
| _Point | 0.01 | 0.00001 |
| TickValue | $0.01/lot | ~$1/pip/lot (varía por XCCY) |
| VolumeMax | 5 | 20 |
| Cálculo | CFD | Forex No Leverage |
| Spread | Variable | Flotante |
| VPP real | $100/lot/pt | $10/lot/pip |

El bug de `SYMBOL_TRADE_TICK_VALUE` que te golpeó en XAUUSD **también existe en Forex XCCY** porque la divisa de beneficio es USD pero la divisa base es EUR. El OrderCalcProfit fix es obligatorio aquí también.

---

### La pregunta crítica antes de escribir una sola línea de código

**¿El EURUSD tiene un breakout estadísticamente relevante en la apertura de NY (14:50 UTC)?**

Esta es la hipótesis que hay que probar PRIMERO. No asumir que porque funciona en NAS100/XAUUSD va a funcionar en EURUSD.

Los motivos por los que PODRÍA funcionar:
- NY open es el evento de mayor liquidez en Forex. La apertura de Londres+NY overlap termina, y el mercado digiere órdenes institucionales
- EURUSD tiene el mayor volumen del mundo → los breakouts son más "limpios" y menos propensos a fakeouts
- El rango pre-NY en Forex suele comprimirse durante la sesión asiática/madrugada europea

Los motivos por los que PODRÍA fallar:
- EURUSD es mucho más eficiente que XAUUSD. Menos sesgo direccional por jornada
- El rango pre-NY en EURUSD es mucho más pequeño en pips relativos (XAUUSD mueve $9 en un rango que es ~0.03% del precio; EURUSD mueve quizás 15-20 pips en un rango que es ~0.13%)
- Sin el bullish bias estructural que tenía NAS100 (que fue tu insight clave: deshabilitar SHORTs)

---

### Adaptaciones técnicas necesarias

**1. VPP (crítico)**
```mql5
// Igual que XAUUSD pero VPP ≈ $10/lot/pip para EURUSD
double ask0 = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
double profitTest = 0;
bool calcOK = OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, 1.0, 
                              ask0, ask0 + 0.00010, profitTest); // 10 pips
if(calcOK && profitTest > 0)
    g_valuePerPoint = profitTest / 10.0; // valor por pip
else
    g_valuePerPoint = 10.0; // fallback: $10/pip/lot estándar
```

**2. MinSL / MaxSL en precio real (pips, no puntos de broker)**

En XAUUSD MinSL=$4.5 equivalía a 4.5 puntos de precio ($4.5 de rango). En EURUSD hay que pensar en pips:
- Un rango pre-NY típico de EURUSD: **15–30 pips** (0.0015–0.0030)
- MinSL razonable de entrada: **~10 pips** (0.0010)
- MaxSL razonable: **~40 pips** (0.0040)

El EA ya compara slDistance directamente en precio, así que si tienes MinSL=0.0010 y MaxSL=0.0040 funciona idéntico. Pero los parámetros de optimización cambian completamente.

**3. MagicNumber**

Ya tienes 202401–202404 ocupados. Usar **202405** para EURUSD.

**4. ConfirmOnClose, EnablePartials, SessionCloseHour**

Sin cambios. Estas reglas son independientes del instrumento.

---

### Plan de desarrollo recomendado

```
Fase 0 → Adaptar StatAnalyzer para EURUSD (1-2h)
Fase 1 → Correr análisis estadístico (¿cuánto histórico M5 tienes?)
Fase 2 → Decidir si el edge existe antes de hacer IS/OOS
Fase 3 → Solo si Fase 2 es positivo: optimización IS/OOS
Fase 4 → Forward test 4 semanas
```

**El paso más importante es la Fase 1.** Si el StatAnalyzer dice que el Max Favorable Ratio promedio es < 1.5× el rango, el TP3 no va a funcionar y hay que replantear la estrategia o descartarla para este instrumento.

---

### Mi recomendación antes de empezar a codear

Antes de tocar el EA, necesito saber:

1. **¿Cuánto histórico M5 de EURUSD tienes disponible en FundingPips MT5?** (el StatAnalyzer va a necesitarlo)
2. **¿El EURUSD de FundingPips opera con spread flotante típico de cuántos pips?** (visible en la imagen como "Flotante" pero sin valor)
3. **¿Cuál es tu objetivo con EURUSD?** ¿Diversificación del portfolio, o es que el prop firm te pide operar Forex también?

Con esos datos te doy el spec completo del StatAnalyzer adaptado y empezamos la Fase 0 con datos reales, no suposiciones.

