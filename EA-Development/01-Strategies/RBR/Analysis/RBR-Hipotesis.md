---
title: "RBR — Hipótesis y Notas de Diseño"
date: 2026-05-23
tags: [RBR, hipotesis, mean-reversion, IBS, AMT]
related:
  - "[[RBR]]"
  - "[[Estrategias-Consolidadas-v3]]"
---

# RBR — Hipótesis y Notas de Diseño

## Hipótesis principal

**H0 (nula):** Los retornos desde el extremo del rango hacia el mid-point no difieren estadísticamente de retornos aleatorios de igual magnitud.

**H1 (alternativa):** Cuando el precio toca el extremo del rango con rechazo confirmado (IBS + mecha), el retorno esperado hacia el mid-point es positivo con p < 0.05 en IS y OOS.

**Claim falsificable:** En mercado lateral (RegimeFilter activo), las entradas con IBS > 0.70 en zona baja y IBS < 0.30 en zona alta producen PF ≥ 1.10 en OOS con t > 2.0 sobre los R-múltiples.

---

## Base teórica

### Auction Market Theory (AMT)
El mercado es una subasta continua que busca precio de equilibrio (fair value). Cuando el precio se aleja del equilibrio:
- Los participantes con órdenes límite en los extremos presionan el precio de regreso
- El Value Area (zona de mayor volumen) actúa como atractor
- El mid-point del rango aproxima el fair value intraday

### IBS (Internal Bar Strength)
Desarrollado por la literatura de reversión de corto plazo. Mide la posición del cierre dentro del rango de la vela:
```
IBS = (Close - Low) / (High - Low)
```
- IBS alto en zona baja → la vela rechazó el nivel y cerró fuerte → presión compradora
- IBS bajo en zona alta → la vela rechazó el nivel y cerró débil → presión vendedora

---

## Preguntas abiertas antes de IS

1. **¿Qué período de rango es más robusto?**
   - Hipótesis: RangePeriod entre 15–25 formará meseta en IS
   - Períodos muy cortos (<10) capturan ruido intradía
   - Períodos muy largos (>30) el rango pierde relevancia intraday

2. **¿El filtro de régimen mejora o reduce el edge?**
   - Si el edge existe independientemente del régimen → el filtro reduce frecuencia sin beneficio
   - Si el edge colapsa en tendencia → el filtro es esencial
   - Validar: PF con filtro OFF vs ON en IS

3. **¿EntryMode=Límite vs Confirmación — cuál es más robusto?**
   - Límite: mejor precio, menor win rate esperado
   - Confirmación: peor precio, mayor win rate esperado
   - Ambos deben producir PF > 1.10 en OOS para ser viables

4. **¿El BE interfiere con el edge?**
   - El target (mid del rango) es relativamente corto
   - BE al 50% podría cerrarse en ruido antes de llegar al target
   - Validar: PF con BE OFF vs ON en OOS

5. **¿Correlación con TBR en los mismos instrumentos?**
   - Objetivo: correlación de retornos diarios < 0.40
   - Si correlación > 0.60 → RBR no agrega diversificación real
   - Calcular en Paso 10 del pipeline con retornos OOS

---

## Modos de fallo esperados

| Modo de fallo | Condición | Mitigación |
|---|---|---|
| Breakout contra posición | Rango se rompe con fuerza mientras hay posición abierta | SL más allá del extremo + buffer |
| Falsa señal en tendencia | RegimeFilter no detecta el régimen correctamente | Ajustar RegimeMultiplier en IS |
| Edge consumido por spread | Spread CFD erosiona el margen por trade | Stress test costos (Paso 7) |
| Rango insignificante | Range_Size demasiado pequeño → SL y TP sub-óptimos | Filtro: no operar si Range_Size < mínimo de puntos |
| Solapamiento de señales | Múltiples señales en misma sesión | Una posición máxima por sesión |

---

## Decisiones de diseño tomadas

| Decisión | Alternativa descartada | Razón |
|---|---|---|
| TP = Range_Mid fijo | TP en puntos fijo | El mid es el equilibrio natural — no parametrizar agrega robustez |
| SL más allá del extremo del rango | SL en ATR | El extremo del rango tiene significado estructural; ATR es redundante |
| Una posición por sesión | Múltiples entradas | Evita acumulación de riesgo en días con muchas señales |
| Sin trailing stop | Trailing activo | El edge es de reversión al mid, no de seguimiento de tendencia |
| RangePeriod fijo (no adaptativo) | ATR-adaptive range | Simplicidad primero; adaptativos aumentan overfitting en IS |

---

## Registro de cambios al diseño

| Fecha | Cambio | Razón |
|---|---|---|
| 2026-05-23 | Diseño inicial v1.0 | — |

