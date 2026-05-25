---
type: decision
strategy: ARE
date: 2026-05-01
status: confirmed
---

# Decision — ARE Diseño Inicial v1.0

## Decisión

Desarrollar ARE como estrategia universal basada en Hurst Exponent para detección de régimen, con dos módulos independientes (Mean Reversion y Breakout), normalización ATR cross-asset y CSV logger de atribución.

## Contexto

Portfolio actual (BreakoutNY + CTR Pro) tiene correlación elevada entre estrategias — ambas orientadas a NY session, ambas en XAUUSD/índices. ARE aporta:
1. Timeframe diferente (M15 vs M5/M10)
2. Lógica diferente (régimen estadístico vs patrón horario específico)
3. Multi-activo sin recodificación
4. Baja correlación esperada = diversificación real

## Alternativas descartadas

| Alternativa | Descarte |
|-------------|---------|
| ADX como detector de régimen | Dead zones documentadas en Cascade Gate, lag, paradojas |
| EMA 200 como filtro de breakout | Lagging, no agrega información sobre BOS ya ocurrido |
| ATR Ratio como detector | Usuario lo consideró redundante; Hurst superior en naturaleza |
| Solo módulo Breakout | Perdería edge en mercados ranging (mayoría del tiempo) |
| Filtro C (Swing) siempre activo | Reduce trade count; mejor dejarlo parametrizable |

## Riesgos identificados

1. **Overfitting doble** — dos módulos con parámetros independientes. Mitigación: IS 7 años, WFA obligatorio
2. **Lag en cambio de régimen** — Hurst llega tarde a transiciones. Mitigación: zona muerta 0.45–0.55 actúa como buffer
3. **"Universal" = mediocre en todo** — riesgo real. Mitigación: validación independiente por activo, PF mínimo estricto
4. **Mean reversion en tendencia fuerte** — RSI < 28 en free-fall no es oversold. Mitigación: Hurst < 0.45 debe ser el guardián principal

## Validación requerida antes de producción

- IS PF > 1.5 en mínimo 2 activos
- OOS PF > 1.3 con degradación < 30%
- Trades OOS > 200 por activo
- Monte Carlo favorable (misma metodología que BreakoutNY)
