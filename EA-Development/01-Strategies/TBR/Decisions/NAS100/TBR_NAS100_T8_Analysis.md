# TBR NAS100 — Análisis Test 8 (v1.2 MODE_CONFIRM M3)
> Fecha: 2026-05-10 | EA: TBR_v1 v1.2 | Veredicto: NO VIABLE — bug de sizing

---

## Configuración Test 8

| Parámetro | Valor |
|-----------|-------|
| EA | TBR_v1 v1.2 |
| Temporalidad | M3 |
| EntryMode | MODE_CONFIRM (0) |
| TradeDirection | BUY only (1) |
| RangeCandlesCount | 1 |
| RR | 3.0 |
| RiskAmountUSD | $12.50 fijo |
| SessionStart | 14:27 UTC |
| SessionEnd | 17:00 UTC |
| Días | Lun/Mié/Vie |
| Período | 2022.01.01 – 2026.12.31 |

---

## Resultados globales

| Métrica | Valor | Umbral | Estado |
|---------|-------|--------|--------|
| Profit Factor | **1.1709** | ≥ 1.40 | ✗ |
| Max DD | **21.29%** | ≤ 10% | ✗ |
| Total Trades | 571 | ≥ 30 | ✓ |
| Win Rate | 30.6% | — | — |

**NO VIABLE — persiste problema de sizing crítico.**

---

## Bug crítico identificado: sizing con SL_dist incorrecta

### Causa raíz

El lot se calcula en `CalculateRange()` usando:
```mql5
g_slDistance = g_rangeHigh - g_rangeLow;   // rango bruto de 1 vela M3
g_cachedLots = CalculateLotSize(g_slDistance);
```

Pero el SL real se coloca en `ExecuteTrade()`:
```mql5
g_slLevel    = NormalizeDouble(g_rangeLow - effectiveStop * _Point, g_digits);
g_slDistance = g_entryPrice - g_slLevel;   // SOBREESCRIBE g_slDistance
// SL_dist_real = (ask - rangeLow) + 10pts extra
//              ≈ breakout_distance + rango + extra
//              >> rango_bruto
```

### Magnitud del error (datos forenses T8 vs NR)

| Métrica | NR | T8 |
|---------|-----|-----|
| SL mediana (puntos) | 15.0 | 29.7 |
| Lot mediana | 0.04 | 0.07 |
| Lot esperado con $12.50 | 0.04 | **0.02** |
| Riesgo real/trade mediana | $13.52 | **$43.60** |
| Riesgo real/trade máximo | $21.10 | **$322.99** |
| Ratio riesgo real/configurado | 1.08x | **3.5x** |

### Por qué T8 lot = 0.07 si debería ser 0.02

1. Lot calculado con `sl_dist_rango ≈ 10-15 pts` → `floor(12.5/(12×20)) = 0.05`
2. SL real en ejecución ≈ 30 pts (rango + extra + breakout distance)
3. Riesgo real = `0.05 × 30 × 20 = $30` (2.4x el declarado)
4. El compounding eleva el balance → lots suben → riesgo se amplifica

**Verificación:** solo el **1.1% de los trades** (6/571) pasan el check `lot == floor(12.5/SL_dist/20)`. El 98.9% tiene un lot mayor al correcto.

---

## Comparativa T8 vs NR: tipos de salida

| Tipo | NR | T8 |
|------|-----|-----|
| TP | 33.3% | **19.4%** |
| SL | 66.7% | 68.7% |
| Timeout | 0.4% | **11.9%** |

T8 tiene 11.9% timeouts (vs 0.4% NR) — el RR=3.0 es inalcanzable en 2.5h de sesión M3 cuando el SL está a 30 pts.

---

## Lotaje NR vs TBR: diferencia estructural

| | NR | TBR v1.2 |
|--|-----|----------|
| SL calculado con | rango bruto | rango bruto |
| SL colocado en | rangeLow - extra | rangeLow - extra |
| **Lot calculado con** | **rango bruto** | **rango bruto** |
| **SL real entry→SL** | **~= rango bruto** | **>> rango bruto** |
| Causa diferencia | SL en buy stop ≈ SL_dist | Entry en market ≈ rangeHigh → SL_dist_real = rango + extra |

NR usa órdenes `buy stop` colocadas en `rangeHigh + extra`. El fill es exactamente en rangeHigh. El SL está en `rangeLow - extra`. La SL_dist del NR ≈ `2×extra + rango` pero el fill en el STOP es preciso al punto de ruptura. El TBR en MODE_CONFIRM entra en market (ask), que ya está por encima del rangeHigh cuando confirma — add gap de 1 vela adicional al SL_dist.

---

## Fix requerido en v1.3

**Mover el cálculo de lotaje al momento de la entrada, con la SL_dist real:**

```mql5
// En ExecuteTrade() — DESPUÉS de calcular g_slLevel y g_slDistance reales:
void ExecuteTrade(string direction)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int effectiveStop = MathMax(g_stopLevel, StopLevel_ExtraPoints);

   if(direction == "buy")
   {
      g_entryPrice = ask;
      g_slLevel    = NormalizeDouble(g_rangeLow - effectiveStop * _Point, g_digits);
      g_slDistance = g_entryPrice - g_slLevel;   // SL_dist REAL
      g_tpLevel    = NormalizeDouble(g_entryPrice + g_slDistance * RR, g_digits);

      // NUEVO: recalcular lots con SL_dist real antes de enviar la orden
      double lots = CalculateLotSize(g_slDistance);
      if(lots <= 0) return;

      if(!trade.Buy(lots, _Symbol, g_entryPrice, g_slLevel, g_tpLevel, "TBR BUY v1"))
      { ... }
   }
}
```

Con este fix:
- `lot = floor(12.5 / 30 / 20) = 0.02` (en lugar de 0.05-0.07)
- `riesgo_real = 0.02 × 30 × 20 = $12.00` (≈ $12.50 ✓)
- Distribución de lots similar a NR: 0.01–0.04

---

## Impacto esperado del fix

| Efecto | Antes (T8) | Después (T9 estimado) |
|--------|-----------|----------------------|
| Lot mediana | 0.07 | ~0.02-0.03 |
| Riesgo/trade | ~$44 | ~$12.50 |
| MaxDD (estimado) | 21.29% | <10% (target) |
| PF | 1.17 | desconocido |

El PF podría mejorar o no — la lógica de señal no cambia. Pero el DD debería caer dramáticamente porque el riesgo por trade quedará fijo en $12.50.

---

## Próxima acción obligatoria

**Test 9 — TBR v1.3** con fix de sizing:
1. Aplicar fix en `ExecuteTrade()`: recalcular lots con SL_dist real al momento de entrada
2. Aplicar mismo fix en `OnTradeTransaction()` para MODE_BREAKOUT
3. Compilar y ejecutar backtest M3, mismos parámetros que T8
4. Verificar que `riesgo_real ≈ $12.50` en el CSV de trades
5. Comparar PF y DD contra T8 y NR
