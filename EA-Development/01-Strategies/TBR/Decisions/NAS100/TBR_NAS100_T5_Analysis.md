# TBR NAS100 M5 — Análisis Test 5 (v1.1 MODE_CONFIRM)
> Fecha: 2026-05-09 | EA: TBR_v1 v1.1 | Veredicto: NO VIABLE — bug de sesión

---

## Configuración Test 5

| Parámetro | Valor |
|-----------|-------|
| EA | TBR_v1 v1.1 |
| Temporalidad | M5 |
| EntryMode | MODE_CONFIRM (0) |
| TradeDirection | BUY only (1) |
| RR | 2.0 |
| RiskAmountUSD | $50 fijo |
| CloseAfterHours_Enable | true |
| MaxHoldHours | 4 |
| SessionStart | 14:30 UTC |
| SessionEnd | 17:00 UTC |
| UseBreakeven | false |
| TradeTue | false, TradeThu | false, TradeSat | true |
| Historia | **99% ticks reales** |

---

## Resultados globales

| Métrica | Valor | Umbral | Estado |
|---------|-------|--------|--------|
| Profit Factor | **1.069** | ≥ 1.40 | ✗ |
| Profit Neto | +$962 | positivo | ✓ |
| Max DD % | **26.03%** | ≤ 10% | ✗ |
| Win Rate | 57.6% | — | — |
| RR Real | **0.79x** | — | peor que 1:1 |
| Avg Loss vs conf | **1.7x** | ~1.0x | ✗ |
| Max Loss 1 trade | **$329 (6.6x conf)** | — | ✗ |
| Total Trades | 396 | ≥ 30 | ✓ |

**NO VIABLE — falla en PF, DD, y RR real.**

---

## Bug crítico identificado: entradas post-SessionEnd

**72% de los trades (285/396) entran después de las 17:00 UTC**, cuando `SessionEnd=17:00 UTC`.

### Distribución por hora de entrada

| Hora | Trades | Net | PF | Estado |
|------|--------|-----|-----|--------|
| 16:xx UTC | 111 | +$1,332 | 1.32 | ✓ dentro de sesión |
| 17:xx UTC | 226 | -$282 | 0.97 | ✗ fuera de sesión |
| 18:xx UTC | 59 | -$87 | 0.92 | ✗ fuera de sesión |

El único bloque rentable (16:xx, PF=1.32) aún está bajo el umbral de 1.40.
Los 285 trades post-sesión producen net -$370 y destruyen el resultado.

### Causa raíz del bug

En `MODE_CONFIRM`:
1. Breakout detectado a las 16:58 UTC → `g_breakoutPending = true`
2. El tick de confirmación llega en la apertura de la siguiente vela M5 (17:03 UTC)
3. El check de `SessionEnd` en `OnTick()` se evalúa al inicio del tick
4. **La lógica de confirmación** `else if(currentBarTime > g_pendingBarTime)` no verificaba si `now >= g_sessionEndTime`
5. Resultado: el EA ejecuta la entrada a las 17:03, 17:20, 18:00, 18:30 UTC

### Fix aplicado en v1.2

```mql5
else if(currentBarTime > g_pendingBarTime)
{
   // Nueva vela formada — verificar que la confirmación llega dentro de sesión
   if(now >= g_sessionEndTime)
   {
      // Descartar señal — el breakout venció la ventana de sesión
      g_breakoutPending = false;
      g_pendingDir      = "";
      g_pendingBarTime  = 0;
   }
   else
   {
      // Validar y ejecutar
      bool stillValid = ...;
   }
}
```

---

## Análisis de retención

| Bucket | Trades | % | Avg Profit | Diagnóstico |
|--------|--------|---|------------|-------------|
| 0-5 min | 1 | 0% | -$94 | — |
| 5-15 min | 18 | 5% | -$62 | SL 61% |
| 15-30 min | 32 | 8% | -$76 | SL 59% |
| 30-60 min | 61 | 15% | -$35 | SL 41% |
| 1-2h | 173 | 44% | +$6 | Timeout 83% |
| 2-4h | 111 | 28% | +$52 | Timeout 99% |

**El 77% cierra por Timeout** (avg +$31.77) — el RR 2.0x es inalcanzable en 2.5h de sesión.
Los trades son marginalmente rentables pero el TP nunca se alcanza.

---

## Análisis por día

| Día | Trades | Net | PF | Estado |
|-----|--------|-----|-----|--------|
| Lunes | 136 | -$690 | 0.87 | ✗ destruye resultado |
| Miércoles | 124 | +$1,595 | 1.44 | ✓ único día viable |
| Viernes | 136 | +$58 | 1.01 | ✗ breakeven |

---

## Comparativa tres tests

| Métrica | NR M3 | TBR T4 Breakout | TBR T5 Confirm |
|---------|-------|---------|---------|
| PF | 1.4356 ✓ | 1.0639 ✗ | 1.0691 ✗ |
| Max DD % | 5.84% ✓ | 31.13% ✗ | 26.03% ✗ |
| Avg Loss vs conf | 1.1x ✓ | 1.3x | 1.7x ✗ |
| Max Loss vs conf | 2.0x ✓ | 4.8x ✗ | 6.6x ✗ |
| % Timeout | 0% | 34% | 77% |
| Timeout avg profit | +$23 | +$42 | +$32 |

---

## Cambios aplicados en v1.2 (código)

1. **BUG FIX** — `MODE_CONFIRM`: descartar señal si confirmación llega post-`SessionEnd`
2. **Default `UseBreakeven=false`** — BE colapsa el RR real como demostrado en tests anteriores
3. **`OnTester()` custom** — maximiza `PF × (1 - DD/100)`, rechaza runs con < 30 trades o DD > 10%
4. **Version bump** → v1.2

---

## Configuración para Test 6 (próximo)

Con el bug corregido en v1.2, el próximo test debe aislar el día más rentable y explorar RR reducido:

| Parámetro | Recomendado | Razón |
|-----------|-------------|-------|
| EntryMode | MODE_CONFIRM | Confirmado correcto en v1.2 |
| TradeDirection | DIR_BUY | NAS100 sesgo alcista |
| SessionStart | 14:30 UTC | Mantener |
| SessionEnd | 17:00 UTC | Mantener |
| RR | **1.0–1.5x** | 77% timeout con RR 2.0 — el TP es inalcanzable |
| TradeMonday | false | PF 0.87, net -$690 |
| TradeTuesday | false | Mantener off |
| TradeWednesday | true | PF 1.44, único día viable |
| TradeThursday | false | Mantener off |
| TradeFriday | **false** | PF 1.01, breakeven |
| TradeSaturday | false | Sin sentido NAS100 |
| MaxHoldHours | 2 | Con sesión 2.5h, 4h timeout no añade valor |

---

## Veredicto

**NO VIABLE** — contaminado por bug de sesión post-SessionEnd.

| Criterio | Estado |
|----------|--------|
| PF ≥ 1.40 | ✗ (1.069) |
| DD ≤ 10% | ✗ (26.03%) |
| RR real coherente | ✗ (0.79x) |
| Bug de sesión | ✗ corregido en v1.2 |

**Próxima acción obligatoria:** ejecutar Test 6 con TBR v1.2 (bug corregido), `RR=1.2–1.5`, solo Miércoles, verificar que no hay entradas post-17:00 UTC.
