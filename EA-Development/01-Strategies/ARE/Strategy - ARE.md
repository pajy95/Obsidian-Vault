---
type: strategy
status: development
pair: EURUSD | XAUUSD | NAS100 | GBPUSD (multi-asset)
timeframe: M15
style: regime-adaptive (mean reversion + breakout)
risk_per_trade: USD-based 1%
created: 2026-05-01
updated: 2026-05-01
tags:
---

[[Estrategias]]

# Estrategia: ARE (Adaptive Regime Engine)

## Navegación

| Sección | Link |
|---------|------|
| Backtests IS/OOS | [[Backtests]] |
| Análisis y decisiones | [[Analysis]] |
| Análisis Monte Carlo | [[Analisis-MonteCarlo]] |
| Optimización MT5 | [[Optimizacion]] |
| Sets de producción | [[Sets-Produccion]] |
| Walk-Forward | [[WalkForward]] |
| Código fuente | [[Code]] |
| Historial de sesiones | [[Chat-History]] |
| Trade Journal | [[Trade-Journal]] |

## Estado rápido — 2026-05-01

| Fase | Status |
|------|--------|
| Diseño y especificación | ✅ Completo |
| Código MQL5 | 🔨 En desarrollo |
| Backtest IS (2015–2021) | ⏳ Pendiente |
| OOS (2022–2024) | ⏳ Pendiente |
| Walk-Forward (2025+) | ⏳ Pendiente |

**Primer activo de validación:** EURUSD M15
**Próximo paso:** Correr IS 2015–2021. Criterio aprobación: PF ≥ 1.5, DD < 20%, Trades > 500

---

## 1. Concepto

ARE es un EA **universal y auto-adaptativo** que detecta el régimen estadístico del mercado mediante el **Exponente de Hurst (R/S)** y ejecuta la lógica de trading apropiada para ese régimen:

- **H < 0.45** → mercado anti-persistente → **Mean Reversion**
- **H > 0.55** → mercado persistente → **Breakout**
- **H 0.45–0.55** → random walk → **No operar**

No tiene activo fijo, sesión fija ni parámetros hardcodeados por instrumento. Todo se normaliza con ATR.

---

## 2. Hipótesis

Los mercados financieros alternan entre dos regímenes estadísticos fundamentales:

1. **Anti-persistencia (H < 0.5):** El precio revierte hacia su media estadística. Las extensiones extremas (RSI en zonas extremas + precio fuera de Bollinger) son oportunidades de entrada en contra del movimiento reciente.

2. **Persistencia (H > 0.5):** El precio tiende a continuar en la dirección del impulso. Las rupturas de estructura (BOS) con momentum real representan continuaciones institucionales.

El Exponente de Hurst, calculado por el método Rescaled Range (R/S) sobre una ventana rolling de 200 barras, identifica en cuál régimen opera el mercado en cada momento. Los umbrales 0.45/0.55 son fijos por definición matemática — no son parámetros optimizables.

---

## 3. Edge Rationale

- El Hurst mide la **memoria del proceso estocástico**, no solo la volatilidad — distingue naturaleza del movimiento, no solo su intensidad
- Mean Reversion: extremos RSI + precio fuera de BB en régimen anti-persistente = probabilidad de retorno a media estadísticamente elevada
- Breakout: BOS con body ratio fuerte + (opcional) swing HH/HL = convicción institucional en régimen persistente
- Normalización ATR elimina diferencias entre activos — un parámetro funciona en XAUUSD y EURUSD sin modificación
- Sin EMA ni ADX: ambos indicadores introducen lag y paradojas (ADX dead zones documentadas en Cascade Gate)

---

## 4. Condiciones de Mercado Ideales

- **Activos:** Cualquier instrumento con datos limpios y spread razonable
- **Timeframe:** M15 (primario) — adaptable a M5, H1
- **Sesión:** Sin filtro obligatorio — el Hurst detecta el régimen en cualquier sesión
- **Evitar:** Eventos macro extremos (NFP, FOMC) — spreads amplios invalidan SL/TP ATR-based
- **Spread máximo recomendado:** 15 pts Forex / 30 pts Gold / 50 pts Índices

---

## 5. Arquitectura

```
MÓDULO 0: HURST EXPONENT (Regime Detector)
├── Método: Rescaled Range (R/S)
├── Ventana: 200 barras (rolling)
├── H < 0.45  →  MEAN REVERSION
├── H > 0.55  →  BREAKOUT
└── H 0.45–0.55  →  NO TRADE

MÓDULO 1: MEAN REVERSION (H < 0.45)
├── RSI(14) < 28  →  Long signal
├── RSI(14) > 72  →  Short signal
├── Close < BB_Lower(20,2)  /  Close > BB_Upper(20,2)
└── Vela de confirmación: rechazo (cierre contrario al extremo)

MÓDULO 2: BREAKOUT (H > 0.55)
├── BOS: Close > Highest(20) previo  /  Close < Lowest(20)
├── Body Ratio > 0.6  (cuerpo / rango total vela)
├── Body > 1.5 × ATR(14)  (momentum real)
└── [Opcional] Swing HH+HL  /  LH+LL  (activable con InpUseSwingFilter)

MÓDULO 3: RISK ENGINE (Universal)
├── SL = Entry ± ATR(14) × InpSL_ATR_Multi
├── TP = Entry ± ATR(14) × InpTP_ATR_Multi
├── Lot size: 1% riesgo USD-based
├── Max 1 posición activa por símbolo
└── DD halts: 3% daily / 6% total (via risk_manager.mqh)

MÓDULO 4: CSV LOGGER
└── ARE_[Symbol]_trades.csv — 21 columnas por trade
```

---

## 6. Parámetros del EA

```mql5
//--- REGIME DETECTOR
input int    InpHurst_Period        = 200;   // Hurst rolling window

//--- MEAN REVERSION
input int    InpRSI_Period          = 14;
input double InpRSI_OB              = 72.0;
input double InpRSI_OS              = 28.0;
input int    InpBB_Period           = 20;
input double InpBB_Dev              = 2.0;

//--- BREAKOUT
input int    InpBOS_Period          = 20;
input double InpBodyRatio_Min       = 0.6;
input double InpMomentum_ATR_Min    = 1.5;
input bool   InpUseSwingFilter      = true;
input int    InpSwing_Lookback      = 3;

//--- RISK ENGINE
input int    InpATR_Period          = 14;
input double InpSL_ATR_Multi        = 1.5;
input double InpTP_ATR_Multi        = 3.0;
input double InpRisk_Pct            = 1.0;

//--- EA CONFIG
input int    InpMagicNumber         = 77700;
input double InpMaxDailyDD          = 3.0;
input double InpMaxTotalDD          = 6.0;
```

**Parámetros optimizables:** 13
**Parámetros fijos (teoría/metodología):** 5 (umbrales Hurst, MagicNumber, DD halts)

---

## 7. Plan de Validación

| Fase | Período | Años | Propósito |
|------|---------|------|-----------|
| IS | 2015–2021 | 7 | Pre-COVID + COVID + bull post-pandemia |
| OOS | 2022–2024 | 3 | Bear 2022 + recovery + AI rally |
| WFA | 2025–presente | live | Walk-forward real |

### Activos (en orden de validación)

| Prioridad | Activo | TF | Razón |
|-----------|--------|----|-------|
| 1 | EURUSD | M15 | Más líquido, datos limpios, mayor muestra |
| 2 | XAUUSD | M15 | Activo principal del portfolio |
| 3 | NAS100 | M15 | Sesgo alcista estructural conocido |
| 4 | GBPUSD | M15 | Cross-validation independiente |

### Métricas mínimas de aprobación

| Métrica | IS | OOS | Descarte |
|---------|----|-----|---------|
| Profit Factor | > 1.5 | > 1.3 | < 1.2 |
| Max Drawdown | < 20% | < 25% | > 30% |
| Sharpe Ratio | > 1.0 | > 0.8 | — |
| Trades | > 500 | > 200 | < 150 |
| Degradación PF IS→OOS | — | < 30% | > 40% |

---

## 8. Archivos MQL5

```
Source/Experts/
└── ARE_v1.0.mq5              ← EA principal

Source/Include/
├── ARE_HurstEngine.mqh        ← Cálculo Hurst R/S
├── ARE_MeanReversion.mqh      ← Señales módulo MR
├── ARE_Breakout.mqh           ← Señales módulo BO + Swing filter
├── ARE_RiskEngine.mqh         ← Sizing ATR-based + SL/TP
├── ARE_CSVLogger.mqh          ← Log CSV por trade
└── risk_manager.mqh           ← v1.0 existente (reutilizado)
```

---

## 9. CSV Logger — Columnas

```
datetime_open, datetime_close, symbol, module,
hurst_value, regime_label,
rsi_at_entry, bb_dev_at_entry, atr_at_entry,
ema200_distance_pct,
sl_multi, tp_multi, rr_ratio,
entry_price, sl_price, tp_price,
exit_price, exit_type,
profit_usd, profit_r, duration_min
```

`profit_r` = profit_usd / riesgo_inicial → expectancy en R independiente del lot size

---

## 10. Decisiones de Diseño

| Decisión | Elegido | Descartado | Razón |
|----------|---------|------------|-------|
| Detector de régimen | Hurst R/S | ADX, ATR Ratio | ADX tiene dead zones y paradojas (documentado en Cascade Gate); Hurst mide naturaleza del proceso |
| Filtro macro breakout | Swing HH/HL (bool) | EMA 200 | EMA lagging — swing es price action puro sin lag |
| Normalización SL/TP | Múltiplos ATR | Pips fijos | Universalidad cross-asset |
| Umbrales Hurst | 0.45/0.55 fijos | Optimizables | Definidos por teoría matemática — optimizarlos es overfitting |
| Filtro C (Swing) | Parámetro bool | Siempre activo | Permite medir impacto aislado en optimización |
| Atribución módulos | CSV + comment orden | Solo historial MT5 | Análisis Python posterior por módulo |

---

## 11. Correlación con Portfolio Existente

| EA | Tipo | Correlación esperada con ARE |
|----|------|------------------------------|
| BreakoutNY | Breakout sesión NY | Baja — diferente TF, sin Hurst, sesión fija |
| CTR Pro | Liquidity sweep reversal | Baja — patrón específico 8:45 NY, M5/M10 |
| Donchian v1.1 | Trend-following | Media — módulo BO puede correlacionar en EURUSD |

---

## 12. Historial de Versiones

| Versión | Fecha | Cambios |
|---------|-------|---------|
| v1.0 | 2026-05-01 | Diseño inicial — Hurst R/S + MR + BO + CSV Logger |
