---
type: chat-history
session: 001
date: 2026-05-01
topic: Diseño completo y especificación ARE v1.0
status: completed
---

# Sesión 001 — Diseño y Especificación ARE v1.0

**Fecha:** 2026-05-01
**Resultado:** Especificación completa aprobada — lista para codificación

---

## Resumen de la sesión

En esta sesión se diseñó desde cero la estrategia **Adaptive Regime Engine (ARE)**, una estrategia universal para cualquier activo basada en detección de régimen estadístico mediante el Exponente de Hurst.

---

## Decisiones tomadas

### 1. Concepto central
- Estrategia universal — sin activo fijo, sin sesión fija
- Detector de régimen: **Hurst Exponent (R/S)** sobre 200 barras rolling
- Dos módulos de trading: Mean Reversion (H < 0.45) y Breakout (H > 0.55)
- Zona muerta: H 0.45–0.55 = no operar (random walk)

### 2. ADX descartado como detector de régimen
- **Razón:** Dead zones documentadas en Cascade Gate (ADX [29.2–35.7] → 45.6% WR, peor que rangos inferiores)
- **Razón:** Lagging, no direccional, ambiguo en transiciones
- **ATR Ratio también descartado** — el usuario señaló que sería redundante (análisis posterior: no es redundante técnicamente, pero el Hurst es superior porque mide la *naturaleza* del proceso, no solo la intensidad)
- **Hurst elegido** porque H=0.5 es el umbral teórico de random walk — los umbrales no son parámetros optimizables → elimina una dimensión de overfitting

### 3. EMA 200 descartada como filtro de breakout
- **Razón:** Lagging — confirma breakout con información pasada, no agrega valor sobre el BOS ya ocurrido
- **Alternativas evaluadas:**
  - A) HTF BOS (H1/H4) — descartado: reduce trade count, alta complejidad
  - B) Body Ratio — **elegido**: mide convicción instantánea, cero lag
  - C) Swing HH/HL — **elegido como opcional**: price action puro, parametrizado con `InpUseSwingFilter`
  - D) ATR Expansion — descartado como filtro principal, puede usarse como soporte futuro
- **Combinación final:** B + C (C activable/desactivable)

### 4. Parámetros SL/TP variables
- SL y TP como múltiplos de ATR: `InpSL_ATR_Multi` y `InpTP_ATR_Multi`
- Permite barrer combinaciones de RR en optimización → mapa de calor RR vs PF

### 5. Período de backtest ampliado
- IS: 2015–2021 (7 años — incluye pre-COVID, COVID shock, bull post-pandemia)
- OOS: 2022–2024 (3 años — bear FED hawkish + recovery + AI rally)
- Razón: OOS corto fue el problema detectado en BreakoutNY (decay H1 vs H2 2025)

### 6. CSV Logger con atribución por módulo
- Cada trade loguea: módulo origen, Hurst value al entry, RSI, ATR, profit_R
- Campo `comment` de la orden también incluye módulo + Hurst
- Permite análisis Python separado por módulo → atribución de performance

### 7. Filtro C parametrizado
- `InpUseSwingFilter = true/false`
- `InpSwing_Lookback = 3` (barras de lookback para pivot)
- Permite comparar en optimización impacto aislado del filtro

---

## Parámetros finales aprobados

```mql5
input int    InpHurst_Period        = 200;
input int    InpRSI_Period          = 14;
input double InpRSI_OB              = 72.0;
input double InpRSI_OS              = 28.0;
input int    InpBB_Period           = 20;
input double InpBB_Dev              = 2.0;
input int    InpBOS_Period          = 20;
input double InpBodyRatio_Min       = 0.6;
input double InpMomentum_ATR_Min    = 1.5;
input bool   InpUseSwingFilter      = true;
input int    InpSwing_Lookback      = 3;
input int    InpATR_Period          = 14;
input double InpSL_ATR_Multi        = 1.5;
input double InpTP_ATR_Multi        = 3.0;
input double InpRisk_Pct            = 1.0;
input int    InpMagicNumber         = 77700;
input double InpMaxDailyDD          = 3.0;
input double InpMaxTotalDD          = 6.0;
```

---

## Condiciones de entrada aprobadas

### Mean Reversion LONG
1. Hurst(200) < 0.45
2. RSI(14) < 28
3. Close < BB_Lower(20, 2.0)
4. Vela de confirmación: cierre > open

### Breakout LONG
1. Hurst(200) > 0.55
2. Close > Highest(20 barras previas)
3. Body Ratio = (Close-Open)/(High-Low) > 0.6
4. (Close-Open) > 1.5 × ATR(14)
5. [Si InpUseSwingFilter=true] Swing[-1].High > Swing[-2].High AND Swing[-1].Low > Swing[-2].Low

---

## Archivos a crear

```
Source/Include/ARE_HurstEngine.mqh
Source/Include/ARE_MeanReversion.mqh
Source/Include/ARE_Breakout.mqh
Source/Include/ARE_RiskEngine.mqh
Source/Include/ARE_CSVLogger.mqh
Source/Experts/ARE_v1.0.mq5
```

---

## Próximos pasos

1. Codificar todos los .mqh en orden
2. Ensamblar ARE_v1.0.mq5
3. Backtest IS EURUSD M15 2015–2021
4. Si PF > 1.5: proceder a OOS 2022–2024
5. Validar en XAUUSD, NAS100, GBPUSD
