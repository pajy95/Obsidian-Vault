---
title: "Portafolio Consolidado de Estrategias de Trading — v3.0"
date: 2026-05-20
version: 3.0
tags: [estrategia, investigacion, price-action, sin-indicadores, prop-firm, MQL5, calendar-anomaly, statistical-arbitrage, microestructura, order-flow]
status: draft
supersedes: "v2.0 (2026-05-20) + Documento de Microestructura v1.0"
related:
  - "[[BreakoutNY]]"
  - "[[CTR Pro]]"
  - "[[Prompt Maestro v3.0]]"
  - "[[Framework IS-OOS-WF]]"
---

# Portafolio Consolidado de Estrategias de Trading v3.0

> [!info] Sobre este documento
> Este documento fusiona dos fuentes previas:
> - **v2.0**: 10 estrategias con respaldo académico peer-reviewed (calendar anomalies, intraday periodicity, FX flow).
> - **Documento de Microestructura v1.0**: 10 estrategias clásicas de price action / order flow (Market Making, Stat Arb, ORB, Tape Reading, etc.).
>
> **Proceso de consolidación:**
> 1. Se identificaron redundancias directas entre documentos.
> 2. Se eliminó la estrategia redundante más débil (ver sección de Redundancias).
> 3. Se conservaron 15 estrategias únicas (de 20 posibles), organizadas en 4 tiers.
>
> **Portafolio activo excluido** (ya en producción/validación): [[BreakoutNY]], [[CTR Pro]].

---

## Análisis de Redundancias y Decisiones de Consolidación

Las siguientes redundancias fueron detectadas entre los dos documentos:

| Estrategia v2.0 | Estrategia Microestructura v1.0 | Decisión | Justificación |
|---|---|---|---|
| **Post-News Fade** (retenida v2.0) | **Event-Driven / News Impact Trading** | **ELIMINAR v1.0** | Son la misma hipótesis: fade/breakout del rango post-news. La v2.0 tiene regla de fade explícita (rejection candle tras spike >3× ATR M1), la v1.0 opera el breakout del post-news range. El fade-the-spike tiene mayor respaldo empírico que el breakout del mini-rango. La v2.0 incluye ya las cautelas de slippage y prop firm. |
| **NAS100/US500 Pairs Z-Score** (v2.0) | **Statistical Arbitrage / Pairs Trading** (v1.0) | **MANTENER AMBAS** | No redundantes: v2.0 es intradía M15 sobre un par específico (NAS100/US500) ya validado para el portafolio de Jose. v1.0 es el framework general de stat arb sobre acciones/ETFs (horizonte swing 2-20 días). Lógicas distintas de holding period y universo de instrumentos. |
| **Breakout Estructural** (v1.0) | BreakoutNY (portafolio activo) | **ARCHIVAR** | Ya cubierto por BreakoutNY en producción. No añade diversificación incremental. Se retira del presente documento. |
| **ORB genérico** (v1.0) | BreakoutNY (portafolio activo) | **ARCHIVAR** | Idem. El ORB fue explícitamente descartado en v2.0 ("ORB-5 Stocks-in-Play: ya cubierto por BreakoutNY"). |

**Resultado**: 15 estrategias únicas (v2.0 original 10 + 6 de Microestructura v1.0 no redundantes - 1 eliminada Event-Driven).

---

## Resumen Ejecutivo — 15 Estrategias

### Tier A — Respaldo académico peer-reviewed sólido (6 estrategias, heredadas de v2.0)

| # | Estrategia | Activos | TF | Eventos/año | PF esperado | DD esp. | Rank |
|---|---|---|---|---|---|---|---|
| 1 | **Pre-FOMC Drift** | US500, NAS100 | M30-H1 | 8 | 2.0–2.8 | 4–7% | ⭐⭐⭐⭐⭐ |
| 2 | **Overnight Drift Europeo** | US500, NAS100, GER40 | M15-H1 | ~250 | 1.5–1.9 | 5–8% | ⭐⭐⭐⭐⭐ |
| 3 | **First→Last Half-Hour** | US500, NAS100 | M30 | ~250 | 1.5–1.8 | 5–8% | ⭐⭐⭐⭐⭐ |
| 4 | **EIA Crude Wednesday** | USOIL | M30 | ~52 | 1.7–2.1 | 7–10% | ⭐⭐⭐⭐ |
| 5 | **WMR 4PM Fix Reversal** | EURUSD, GBPUSD | M5-M15 | ~250 + 12 EOM | 1.4–1.8 | 4–7% | ⭐⭐⭐⭐ |
| 6 | **Heston Daily Periodicity** | NAS100, US500, GER40 | M30 | continuo | 1.4–1.7 | 5–8% | ⭐⭐⭐⭐ |

### Tier B — Soporte académico moderado o adaptado (3 estrategias, heredadas de v2.0)

| # | Estrategia | Activos | TF | Eventos/año | PF esperado | DD esp. | Rank |
|---|---|---|---|---|---|---|---|
| 7 | **Month/Quarter-End FX Flow** | EURUSD, GBPUSD, AUDUSD | M15-H1 | 12–16 | 1.6–2.0 | 5–9% | ⭐⭐⭐⭐ |
| 8 | **Pre-ECB Drift** | GER40, EURUSD | H1 | 8 | 1.8–2.4 | 5–8% | ⭐⭐⭐⭐ |
| 9 | **NAS100/US500 Pairs Z-Score** | NAS100+US500 | M15 | ~150 | 1.4–1.7 | 4–7% | ⭐⭐⭐ |

### Tier C — Microestructura avanzada (5 estrategias, heredadas de v1.0 Microestructura)

> [!warning] Nota de infraestructura
> Las estrategias Tier C requieren datos de Level II / tick data / co-location que exceden las capacidades actuales del setup retail/prop-firm estándar. Prioridad baja para desarrollo inmediato.

| # | Estrategia | Activos | TF | Infraestructura req. | Rank |
|---|---|---|---|---|---|
| 10 | **Market Making Algorítmico** | ES, NQ, BTC/USDT | Microseg.–min. | Co-location, Level II | ⭐⭐⭐ |
| 11 | **Statistical Arbitrage (Swing)** | Acciones mismo sector | 2–20 días | API broker, screening | ⭐⭐⭐ |
| 12 | **Order Flow / Liquidity Imbalance** | ES, NQ, AAPL | 1–5 min | Level II, DOM, tick | ⭐⭐⭐ |
| 13 | **Range Trading / Mean Reversion** | SPY, EUR/CHF, Utilities | 15min–4H | Estándar | ⭐⭐⭐ |
| 14 | **Tape Reading Algorítmico** | ES, NQ, BTC | Segundos–2 min | Tick data, <50ms latencia | ⭐⭐ |

### Tier D — Event-driven con cautela (1 estrategia)

| # | Estrategia | Activos | TF | Eventos/año | PF esperado | Rank |
|---|---|---|---|---|---|---|
| 15 | **Post-News Fade** | EURUSD, XAUUSD, NAS100 | M1–M5 | ~24 | 1.6–2.4 | ⭐⭐⭐ |

---

## Matriz de Correlación Esperada — 15 Estrategias (cualitativa)

> [!warning] Pares de alta correlación a vigilar
> - **First→Last Half-Hour ↔ Heston Periodicity = 0.6**: ambas explotan estructura intraday NY cash. Implementar **una de las dos** primero en producción.
> - **WMR Fix Reversal ↔ EOM FX Flow = 0.5**: misma anomalía Fix-related. En días EOM, el riesgo se duplica si ambas activas simultáneamente.
> - **Pre-FOMC ↔ Post-News Fade = 0.4**: ambas event-driven en FOMC days.
> - **Order Flow ↔ Tape Reading = 0.5**: lógicas muy similares, solo difieren en timeframe. Si ambas se implementan, no activar simultáneamente.
> - **Market Making ↔ Order Flow = 0.3**: comparten infraestructura de Level II; correlación operacional más que de señal.

---

## Estrategias Detalladas — Tier A y B (v2.0, completo)

### 1. Pre-FOMC Drift Strategy

> [!tip] Síntesis
> Paper más citado sobre anomalías en torno a anuncios FOMC. S&P 500 sube ~49 bps en las 24 horas anteriores. Solo 8 eventos/año pero edge enorme por evento. Fuente: Lucca & Moench (2015), *Journal of Finance*.

**Hipótesis central:** En las 24 horas previas al anuncio FOMC, el SPX (y NAS100, GER40) acumula drift positivo medible. Claim falsificable: retorno close-to-close del D-1 FOMC + retorno intradía hasta 14:00 ET supera con t > 2.0 al retorno promedio de días no-FOMC.

**Reglas de entrada:**
1. Calendario FOMC del año (8 reuniones programadas).
2. **Entry long**: market order a las **15:00 ET del D-1 FOMC**.
3. **Filtro VIX opcional**: tamaño completo si VIX > 15; reducir 50% si VIX < 12.

**Reglas de salida:**
- **Exit obligatorio**: 14:00 ET del día FOMC (D-0), previo al anuncio.
- **SL**: 1.5% del precio de entrada.
- Sin TP fijo — time exit.

**Instrumentos:** US500 (paper original), NAS100 (confirmado vía QQQ), GER40 (spillover parcial).

**Risk management:** 1.0–1.5% por trade. 8 trades/año por instrumento → correr US500 + NAS100 + GER40 simultáneos = 24 trades/año.

**Performance esperada:** Win rate 65–75%; Sharpe portfolio (3 instrumentos) 1.0–1.4; edge anual estimado 4–8%.

**Modos de fallo:** Fed surprise hawkish anticipada (drift se invierte); crisis events (marzo 2020); regime change (Fed en hold permanente).

**Compatibilidad prop firm:** ✅ Excelente. Holding ~23h sin overnight risk al cash. FundingPips/FundedNext sin restricciones.

**Implementación MQL5:** 10–14 horas. Baja complejidad.

**Validación:** IS 2018–2021 (t > 2.0 en SPX); OOS 2022–2023 (PF > 1.5, ≥60% trades profitable); WF 2024–presente rolling 12m/3m.

---

### 2. European Open Overnight Drift

> [!tip] Síntesis
> Casi el 100% del equity premium americano se gana en una ventana de 1 hora al abrir Europa. Fuente: Boyarchenko, Larsen & Whelan (2020/2022), FRB-NY Staff Report 917.

**Hipótesis central:** ES/NQ presentan drift positivo persistente entre 02:00 y 03:00 ET (apertura Frankfurt/Londres). Claim falsificable: retorno medio en esa ventana es estadísticamente >0 con t > 3.0.

**Reglas de entrada:**
1. **Entry long**: market order a las **02:00 ET** (07:00 GMT estándar; 06:00 GMT DST).
2. **Filtro de amplificación**: si cierre US del D-1 fue selloff (< –0.5%), entry con tamaño 1.5×.

**Reglas de salida:**
- **Exit obligatorio**: 03:00 ET.
- **SL**: 0.7% del precio de entrada.

**Instrumentos:** US500 (paper original), NAS100 (probable extensión — validar), GER40 (mecánica distinta, validar separado).

**Risk management:** 0.5–0.75% por trade. ~250 trades/año.

**Performance esperada:** Win rate 55–60%; Avg R 0.10–0.15; Sharpe 0.8–1.2.

**Modos de fallo:** Continuación del selloff desde Asia (>2%); news europeo entre 02:00–03:00 ET; errores de DST en timezone handling.

**Compatibilidad prop firm:** ✅ Compatible.

**Implementación MQL5:** 8–12 horas. Baja complejidad (el DST handling es lo crítico).

---

### 3. First→Last Half-Hour Momentum

> [!tip] Síntesis
> El retorno de la primera media hora predice el retorno de la última media hora. Fuente: Gao, Han, Li & Zhou (2018), *Journal of Financial Economics* 129(2).

**Hipótesis central:** r1 (open → 10:00 ET) predice positivamente r13 (15:30–16:00 ET). Slope = 6.94, significativo al 1%.

**Aviso del paper:** NO existe este efecto en forex o commodities. Solo US500 y NAS100.

**Reglas de entrada:**
1. A las 10:00 ET calcular `r1 = (price_10am - prev_close) / prev_close`.
2. Filtro: |r1| > 0.10%.
3. Entry market en dirección sign(r1); variante refinada: esperar pullback a VWAP.

**Reglas de salida:**
- **Time exit obligatorio**: 15:55 ET.
- SL: 1.5× ATR(14) M30.

**Instrumentos:** US500, NAS100 únicamente.

**Risk management:** 0.5–0.75% por trade.

**Correlación a vigilar:** Correlación 0.6 con Heston Periodicity (#6). Implementar **una de las dos** primero.

**Implementación MQL5:** 8–12 horas. Baja complejidad.

---

### 4. EIA Crude Wednesday Momentum

> [!tip] Síntesis
> Tras release EIA (miércoles 10:30 ET / 15:30 GMT), el retorno de la 3ª media hora predice el retorno de la última media hora en crude oil. Fuente: Indriawan et al. (2021), SSRN 3822093.

**Reglas de entrada:**
1. Solo miércoles con release EIA.
2. Calcular `r3` = return de la vela M30 que contiene el release.
3. Filtro: |r3| > 0.30%.
4. Entry siguiente vela M30 en dirección sign(r3).

**Reglas de salida:**
- Time exit 21:00 GMT.
- SL 1.5× ATR(14) M30.

**Instrumentos:** USOIL primario; UKOIL secundario.

**Risk management:** 1.0–1.5% por trade. ~52 trades/año.

**Performance esperada:** Win rate 55–60%; Avg R 0.8–1.2; ~4 trades/mes.

**Implementación MQL5:** 10–14 horas. Media complejidad.

---

### 5. WMR 4PM London Fix Reversal

> [!tip] Síntesis
> Negative serial correlation pre/post el WMR Fix (16:00 GMT), amplificada en EOM. Fuente: Evans (2014/2018), *Journal of Banking and Finance*; Marsh, Panagiotou & Payne (2017).

**Hipótesis central:** La correlación serial entre retorno pre-fix (15:55–16:00 GMT) y post-fix (16:00–16:05 GMT) es significativamente negativa, especialmente en EOM.

**Reglas de entrada:**
1. Calcular pre-fix move: retorno entre 15:50–15:59 GMT.
2. Filtro de magnitud: pre-fix move ≥ 0.15%.
3. **Entry contraria**: a las 16:01 GMT, dirección **opuesta** al pre-fix move.
4. Filtro EOM: tamaño 1.5× en último día hábil del mes.

**Reglas de salida:**
- Time exit: 16:30 GMT.
- SL: 0.20% del precio de entrada.
- TP1: 50% del pre-fix move; TP2: 100% retracement.

**Instrumentos:** EURUSD, GBPUSD, USDJPY (más documentados); XAUUSD (LBMA overlap).

**Risk management:** 1.0% días normales; 1.5% EOM.

**Modos de fallo:** Días con news mayor 15:30–17:00 GMT (filtrar); cambios metodológicos Fix post-2015; edge reducido post-FCA scandal (2014).

**Correlación a vigilar:** Correlación 0.5 con EOM FX Flow (#7). En días EOM, gestionar como uno o el otro, no ambos.

**Implementación MQL5:** 14–18 horas. Timing precision crítico.

---

### 6. Heston-Korajczyk-Sadka Daily Periodicity

> [!tip] Síntesis
> Las velas M30 tienden a tener retornos correlacionados con la misma vela M30 del día anterior, persistiendo hasta 40 días. Fuente: Heston, Korajczyk & Sadka (2010), *Journal of Finance* 65(4); confirmación OOS: Haendler et al. (2025), SSRN 5749704.

**Hipótesis central:** `r(H,D) = α + β × r(H,D-1) + ε` produce β > 0 con t > 2.0 en índices.

**Reglas de entrada:**
1. Para cada vela M30 actual (hora H), calcular `μ(H) = mean(r(H, D-k), k=1..20)`.
2. Entry long si μ(H) > +0.10%; entry short si μ(H) < -0.10%.

**Reglas de salida:**
- Exit al cierre de la vela M30 (30 min holding).
- SL: 1× ATR(14) M30.

**Instrumentos:** NAS100, US500 (paper original); GER40 (extensión — validar).

**Risk management:** 0.5% por trade. Alta frecuencia (~6 señales/día/instrumento).

**Crítico:** Edge muy pequeño por trade. Los costos CFD (spread) pueden consumir la alpha si no se validan con spreads realistas.

**Correlación a vigilar:** Correlación 0.6 con First→Last Half-Hour (#3). No implementar ambas simultáneamente.

**Implementación MQL5:** 14–20 horas. Media complejidad.

---

### 7. Month/Quarter-End FX Rebalancing Flow

> [!tip] Síntesis
> Los gestores institucionales ejecutan hedging FX en el WMR Fix el último día del mes. El flow es estimable; produce reversión post-EOM. Fuente: Melvin & Prins (2015), *Journal of International Money and Finance*.

**Hipótesis central:** Cuando US equities outperforman foreign equities, gestores no-US venden USD al EOM Fix → presión bajista en USD → reversión post-Fix.

**Reglas de entrada:**
1. Identificar último día hábil del mes.
2. Calcular `equity_perf_month` (US500 mes). Si |perf| < 2% → no trade.
3. Si perf > +2%: señal USD selling en Fix → anticipar EURUSD up pre-Fix, reversion post-Fix.
4. EOQ multiplier (marzo, jun, sep, dic): tamaño 1.5×.
5. Entry a las **16:01 GMT EOM** en dirección opuesta al pre-Fix flow observado.

**Reglas de salida:**
- TP: 50% retracement del pre-Fix move.
- SL: 0.30%.
- Time exit: cierre NY siguiente día.

**Instrumentos:** EURUSD, GBPUSD (paper); AUDUSD, NZDUSD (exposure Asia-Pacific).

**Risk management:** 1.5% EOM normal; 2.0% EOQ. ~16 trades/año.

**Compatibilidad prop firm:** ✅ Compatible.

**Implementación MQL5:** 18–24 horas. Media-Alta complejidad (calendar logic robusto).

---

### 8. Pre-ECB Drift Strategy

> [!tip] Síntesis
> Análogo europeo del Pre-FOMC Drift. DAX/STOXX 50 muestran drift positivo en el día previo al ECB press conference. Fuente: QuantPedia (jun 2025); respaldo microestructural: Altavilla et al. (2019), *Journal of Monetary Economics*.

**Hipótesis central:** Retorno close-to-close del D-1 ECB es estadísticamente positivo con t > 2.0 vs días no-ECB.

**Caveat:** Evidencia más débil que Pre-FOMC. No peer-reviewed directo. Tratar como hipótesis con threshold conservador (CI lower bound > 1.2 requerido en bootstrap).

**Reglas de entrada:**
1. Calendario ECB anual (8 reuniones).
2. **Entry long**: 08:00 CET (07:00 GMT) del D-1 ECB.

**Reglas de salida:**
- **Exit obligatorio**: 17:30 CET (16:30 GMT) D-1 ECB (cierre cash Xetra).
- Holding ~9h. SL: 1.0%.

**Instrumentos:** GER40 primario; EURUSD secundario.

**Risk management:** 1.0–1.5% por trade. 8 trades/año por instrumento.

**Compatibilidad prop firm:** ✅ Compatible (verificar reglas ECB específicas).

**Implementación MQL5:** 10–14 horas.

---

### 9. NAS100/US500 Pairs Z-Score Intraday Mean Reversion

> [!tip] Síntesis
> Pairs trading intradía sobre el ratio NAS100/US500. Cuando el spread Z-score excede ±2σ, revierte con expectancy positiva. Base: Gatev, Goetzmann & Rouwenhorst (2006), *Review of Financial Studies*.

**Hipótesis central:** `log(NAS100) - β × log(US500)` con β ≈ 1.05–1.15 es estacionario intradía. Z-score > ±2σ → reversión con expectancy > 0 neta de costos.

**Reglas de entrada:**
1. Hedge ratio rolling: regresión OLS 30 días, `log(NAS100) = α + β × log(US500)`.
2. Z-score: media y std móvil del spread últimas 100 velas M15 (~25h).
3. Z < -2.0: long NAS100 / short US500. Z > +2.0: inverso.
4. Solo cash session NY (14:30–21:00 GMT).

**Reglas de salida:**
- TP: Z cruza 0.
- SL: Z alcanza ±3.0.
- Time exit: 20:55 GMT.

**Risk management:** 1.0% capital total (0.5% por leg). Ambas legs cuentan para daily loss limit del prop firm.

**Modos de fallo:** Cointegration breakdown (tech sector decoupling); news asimétrica (CPI afecta tech más que broad market); costos dobles (dos spreads + dos comisiones).

**Compatibilidad prop firm:** ⚠️ Verificar. Combined drawdown de ambas legs puede acercarse al daily limit.

**Implementación MQL5:** 24–32 horas. Alta complejidad.

---

## Estrategias Detalladas — Tier C (Microestructura v1.0)

> [!important] Prerequisitos de infraestructura
> Las estrategias Tier C requieren datos que no están disponibles en el setup estándar MQL5/MT5 con broker retail:
> - Level II (profundidad de orden book real)
> - Tick data con timestamp microsegundo
> - Latencia < 50–100ms garantizada
> - En el caso de Market Making: co-location o VPS premium cercano a exchange
>
> Se documentan aquí por completitud y como roadmap futuro. Para desarrollo inmediato, priorizar Tier A y B.

---

### 10. Market Making Algorítmico (Liquidity Provision)

**Hipótesis central:** El precio oscila alrededor de un mid-price de equilibrio. Al cotizar simultáneamente en bid y ask, se captura el spread mientras se gestiona el inventory risk.

**Base teórica:** Glosten-Milgrom (1985), Avellaneda-Stoikov (2008).

**Reglas de entrada:**
- Mid-price = (best_bid + best_ask) / 2
- Spread óptimo = base_spread + (volatility_multiplier × σ_short_term)
- Orden límite de compra en mid_price – spread/2; de venta en mid_price + spread/2
- Actualizar cotizaciones cada 50–500ms

**Reglas de salida:**
- Cancelación inmediata: precio se mueve > X ticks; desequilibrio severo en order book (>70% un lado); límite de inventario alcanzado.
- Cierre forzoso al final de sesión.

**Instrumentos óptimos:** ES, NQ, CL (futuros); EUR/USD en ECN; BTC/USDT en CEX.

**Gestión de riesgo:**
- Inventory limits: ±$50,000 o ±5 contratos exposición neta.
- Kill switch automático ante pérdida de conectividad.
- Spread widening 3×–5× durante FOMC/CPI.
- Daily loss limit: 2% del capital.

**Performance típica:** Win rate >65%; Sharpe 2.0–4.0 en condiciones normales; alta frecuencia (cientos/miles de trades/día).

**Modos de fallo críticos:** Adverse selection (flujo tóxico institucional); flash crashes (acumulación de inventario equivocado); errores de software (Knight Capital scenario, $440M en 45 min, 2012).

**Prerequisito de infraestructura:** Co-location o VPS <1ms al exchange. Level II real. Prácticamente inviable en setup retail MT5.

---

### 11. Statistical Arbitrage / Pairs Trading (Swing)

**Hipótesis central:** Dos activos altamente correlacionados por fundamentos mantienen un spread estable a largo plazo. Las desviaciones son estacionarias y reversibles.

**Base teórica:** Cointegración Engle-Granger (1987).

**Reglas de entrada:**
- Identificar par cointegrado: ADF test (p-value < 0.05).
- Z-score del spread = (Spread – mean) / σ.
- Long A / Short B: Z-score < –2.0. Short A / Long B: Z-score > +2.0.

**Reglas de salida:**
- Cierre cuando Z-score regresa a ±0.5.
- Stop loss: Z-score > ±3.5 (correlación rota).
- Time stop: 20–30 días sin convergencia.

**Instrumentos óptimos:** KO/PEP, XOM/CVX, JPM/BAC; ETFs SPY/QQQ, EEM/VWO; WTI/Brent; Oro/Plata.

**Gestión de riesgo:**
- Hedge ratio dinámico con regresión OLS móvil de 60 días.
- Stop de correlación: si rolling 30d cae por debajo de 0.60, liquidar ambas posiciones.
- Máximo 5% del capital por par; operar 5–10 pares simultáneos.

**Performance típica:** Sharpe 1.2–1.8; win rate 55–65%; rentabilidad anualizada 8–15%; drawdowns < 12%. Market neutral (beta ~0).

**Diferencia vs Estrategia #9:** Esta estrategia es swing (2–20 días), sobre universo de acciones/ETFs/commodities. La #9 es intradía M15, solo NAS100/US500. Complementarias, no redundantes.

**Modos de fallo:** Ruptura de correlación por M&A o quiebra; regime change estructural; look-ahead bias en hedge ratios.

---

### 12. Order Flow / Liquidity Imbalance

**Hipótesis central:** El precio a corto plazo se mueve hacia donde existe el desequilibrio de liquidez. Si hay acumulación de órdenes de compra agresivas sin contraparte en el ask, la presión compradora empujará el precio al alza.

**Base teórica:** Microestructura de mercado, análisis DOM/Level II; teoría de price discovery.

**Reglas de entrada:**
- Volume Delta por barra: Delta = Ask_Volume – Bid_Volume
- CVD (Cumulative Volume Delta) de las últimas N barras.
- Long: CVD > umbral positivo Y precio cerca de soporte (Volume Profile).
- Short: CVD < umbral negativo Y precio cerca de resistencia.

**Reglas de salida:**
- Cierre cuando CVD cruza hacia neutralidad.
- Stop loss si precio rompe soporte/resistencia con CVD confirmando dirección opuesta.
- Target: siguiente High Volume Node (HVN) del Volume Profile.

**Instrumentos óptimos:** ES, NQ, CL, GC; AAPL, TSLA, NVDA (alto volumen intradía); BTC, ETH en exchanges con profundidad real.

**Gestión de riesgo:**
- Riesgo por trade: 0.5–1% del capital.
- Máximo 3 trades consecutivos en misma dirección.
- Filtro de noticias: no operar 5 min antes/después de eventos de alto impacto.

**Modos de fallo:** Spoofing/HFT adversarial; datos de baja calidad (OTC forex no refleja mercado interbancario real); overfitting al DOM histórico.

**Prerequisito:** Level II real. En MT5 con broker retail, el DOM no es representativo.

---

### 13. Range Trading / Mean Reversion de Precio Puro

**Hipótesis central:** Los mercados pasan ~70% del tiempo en rangos. Después de un movimiento direccional, el precio tiene alta probabilidad de revertir hacia el área de mayor volumen (Value Area). Base: Auction Market Theory (AMT).

**Reglas de entrada:**
- Rango de últimas 20–30 barras: Range = Max(High,20) – Min(Low,20).
- Upper Zone = Max – 0.1 × Range; Lower Zone = Min + 0.1 × Range.
- Long: precio toca Lower Zone + barra de rechazo (close > open, mecha inferior larga) + IBS < 0.3.
- Short: precio toca Upper Zone + rechazo + IBS > 0.7.

**Reglas de salida:**
- Target: mid-point del rango o POC del Volume Profile.
- Stop loss: más allá del extremo del rango + 1 ATR.
- Time stop: cerrar después de 5 barras sin movimiento hacia target.

**Instrumentos óptimos:** SPY, DIA (consolidación); EUR/CHF, AUD/NZD (rangos FX); Utilities, REITs.

**Gestión de riesgo:**
- Riesgo: 1% por trade.
- Filtro de régimen: no operar si el rango de 20 días está expandiéndose > 1.5× (régimen de tendencia).
- Máximo 3 pares/índices simultáneos.

**Performance típica:** Win rate 60–70%; Sharpe 1.0–1.5 en mercados laterales.

**Modos de fallo:** Breakout por noticias inesperadas; rangos anidados (rango dentro de rango más grande); overfitting al umbral de IBS.

**Ventaja vs Tier A/B:** Esta es la única estrategia Tier C operacionalmente viable con infraestructura estándar MT5. No requiere Level II. Candidata a desarrollo si el portafolio necesita una estrategia mean-reversion.

---

### 14. Tape Reading Algorítmico (Time & Sales Analysis)

**Hipótesis central:** El flujo de órdenes ejecutadas en tiempo real revela la intención de participantes grandes antes de que se refleje en el precio. Un aumento súbito del tamaño de lotes en una dirección anticipa movimientos de segundos a minutos.

**Reglas de entrada:**
- Velocidad de trades: Trades_per_second = count(trades en últimos 5 seg).
- Avg_Lot_Size = mean(volume de últimos 20 trades).
- Long: 3+ trades consecutivos en ask con lotes > 2× Avg_Lot_Size + precio subiendo > 2 ticks en 5 seg.
- Short: inverso.

**Reglas de salida:**
- Cierre cuando velocidad de trades cae > 50% desde el pico.
- Stop loss: 3–5 ticks o lote grande en dirección opuesta.
- Time stop: 60 segundos sin nuevo momentum.

**Instrumentos:** ES, NQ (tape denso y transparente); AAPL, MSFT, SPY; BTC en exchanges con tape real.

**Gestión de riesgo:**
- 0.3–0.5% por trade. Máximo 10 trades/hora. Kill switch tras 3 stops consecutivos.

**Modos de fallo críticos:** Iceberg orders no detectables; latencia > 50ms destruye el edge; datos de tape agregados distorsionan la señal.

**Prerequisito:** Tick data con timestamp granular. Latencia < 50ms garantizada. Incompatible con setup estándar MT5/broker retail.

---

## Estrategia Tier D

### 15. Post-News Fade

> [!tip] Síntesis
> Fade del primer spike post-news mayor (NFP, CPI, FOMC). La más arriesgada del portafolio. Reemplaza y consolida el "Event-Driven / News Impact Trading" del documento de microestructura (que operaba el breakout del mini-rango post-news — lógica inferior por mayor slippage en la dirección del momentum).

**Por qué se eligió el Fade sobre el Breakout post-news:** El spike inicial post-news generalmente representa sobrereacción (papers: Boyarchenko et al. 2020 documentan reversión post-selloff asimétrica). Operar en dirección del breakout post-news implica entrar cuando el slippage ya fue absorbido por el mercado y el momentum puede estar agotado. El fade captura el retorno hacia el pre-news price con mayor R esperado.

**Hipótesis central:** Tras spike news-driven > 3× ATR M1 con rejection candle, revierte parcialmente hacia pre-news price.

**Reglas de entrada:**
- Spike > 3× ATR(20) M1 dentro de los primeros 5 min post-release.
- Primera vela M5 cierra mostrando rejection pattern (mecha > 60% del rango de la vela).
- Entry stop en break de la wick de rechazo.

**Reglas de salida:**
- SL: 1 pip más allá del extremo del spike.
- TP1: pre-news price; TP2: 50% beyond pre-news.
- Time exit: 60 minutos.

**Instrumentos:** EURUSD, GBPUSD, XAUUSD (FOMC); NAS100 (CPI/FOMC).

**Performance esperada:** Win rate 50–60%; Avg R 1.5–2.5; ~6–8 trades/mes.

**Compatibilidad prop firm:** ⚠️ Verificar reglas. FundingPips Zero (Instant) prohíbe news trading. FundingPips 1-Step/2-Step lo permite en evaluación. FundedNext: profits excluded si trade dentro de 5h antes / 5 min después de high-impact news en funded.

**Implementación MQL5:** 30–45 horas. Alta complejidad (spike detection, rejection pattern, timing de noticias).

---

## Roadmap de Construcción del Portafolio

### Fase 1 — Tier 1 Priority (Meses 1–5, ~40h MQL5 total)

1. **Pre-FOMC Drift** sobre NAS100 + US500 (~10–14h)
2. **European Open Overnight Drift** sobre NAS100 + US500 (~8–12h)
3. **First→Last Half-Hour** sobre US500 (~8–12h) ← o Heston Periodicity, no ambas
4. **EIA Crude Wednesday** sobre USOIL (~10–14h)

### Fase 2 — Tier 2 (Meses 6–10)

5. **Month/Quarter-End FX Flow** — EURUSD, GBPUSD (~18–24h)
6. **WMR 4PM Fix Reversal** — EURUSD, GBPUSD (~14–18h)

### Fase 3 — Investigar / paper trading (Meses 11–15)

7. **Pre-ECB Drift** sobre GER40 (~10–14h)
8. **Heston Daily Periodicity** si se eligió First→Last en Fase 1; sino intercambiar

### Fase 4 — Alta cautela / validación extensa

9. **NAS100/US500 Pairs Z-Score** (~24–32h) — si CI bootstrap PF > 1.4
10. **Post-News Fade** (~30–45h) — solo si slippage realista viable en broker activo

### Tier C (Microestructura) — Roadmap futuro / infraestructura distinta

Estrategias 10, 11, 12, 13, 14 — Evaluar cuando la infraestructura lo permita. Excepción: **Range Trading (#13)** puede desarrollarse con MT5 estándar — candidata de prioridad media si se necesita estrategia mean-reversion complementaria en el portafolio.

---

## Framework de Validación

Aplicar [[Prompt Maestro v3.0]] y [[Framework IS-OOS-WF]] con los siguientes criterios:

**Criterios de paso (Tier A/B):**
- IS 2018–2021: optimizar máximo 1–2 parámetros. Documentar parameter plateau ±20%.
- OOS 2022–2023: PF ≥ 1.5 mínimo / ≥ 2.0 objetivo; DD < 10%; ≥60% años profitable; t-test R-multiples: t > 2.0, Cohen's d > 0.15; **Bootstrap CI (1000 iter) PF: lower bound > 1.0**.
- WF 2024–presente: rolling 12m IS / 3m OOS.
- **Auto-abandono**: si CI bootstrap incluye 1.0 → descartar.

**Criterios conservadores (Tier C/D y estrategias de respaldo académico débil como Pre-ECB):**
- CI lower bound > 1.2 requerido.

---

## Referencias Académicas

### Peer-reviewed

- Gao, L., Han, Y., Li, S. Z., & Zhou, G. (2018). "Market Intraday Momentum." *Journal of Financial Economics*, 129(2), 394–414.
- Lucca, D. O., & Moench, E. (2015). "The Pre-FOMC Announcement Drift." *Journal of Finance*, 70(1), 329–371.
- Heston, S. L., Korajczyk, R. A., & Sadka, R. (2010). "Intraday Patterns in the Cross-Section of Stock Returns." *Journal of Finance*, 65(4), 1369–1407.
- Boyarchenko, N., Larsen, L. C., & Whelan, P. (2020/2022). "The Overnight Drift." FRB-NY Staff Report 917.
- Evans, M. D. D. (2018). "Forex Trading and the WMR Fix." *Journal of Banking and Finance* 87, 5–17.
- Marsh, I. W., Panagiotou, P., & Payne, R. (2017). "The WMR Fix and its Impact on Currency Markets." Norges Bank WP.
- Melvin, M., & Prins, J. (2015). "Equity Hedging and Exchange Rates at the London 4pm Fix." *JIMF*.
- Gatev, E., Goetzmann, W. N., & Rouwenhorst, K. G. (2006). "Pairs Trading." *Review of Financial Studies* 19(3).
- Indriawan, I., Lien, D., Wen, Z., & Xu, Y. (2021). "Intraday Return Predictability in Crude Oil: EIA Announcements." SSRN 3822093.
- Altavilla, C. et al. (2019). "Measuring Euro Area Monetary Policy." *Journal of Monetary Economics*.
- Haendler, C., Heston, S. L., Korajczyk, R. A., & Sadka, R. (2025). "The Intra-Day Stock Return Periodicity Puzzle." SSRN 5749704.
- Engle, R. F., & Granger, C. W. J. (1987). "Co-integration and Error Correction." *Econometrica* 55(2).
- Glosten, L. R., & Milgrom, P. R. (1985). "Bid, Ask and Transaction Prices in a Specialist Market." *Journal of Financial Economics* 14(1).
- Avellaneda, M., & Stoikov, S. (2008). "High-frequency Trading in a Limit Order Book." *Quantitative Finance*.

### Working papers / replications

- QuantSeeker (Feb 2025). "Trading the Fed: The Pre-FOMC Drift is Alive."
- QuantPedia (Jun 2025). "Uncovering the Pre-ECB Drift and Its Trading Strategy Applications."
- BNY iFlow Research (mensual). "Month-end Rebalancing Analysis."

### Libros de referencia

- Chan, E. (2013). *Algorithmic Trading: Winning Strategies and Their Rationale*. Wiley.
- Lopez de Prado, M. (2018). *Advances in Financial Machine Learning*. Wiley.
- Vidyamurthy, G. (2004). *Pairs Trading: Quantitative Methods and Analysis*. Wiley.
- Steidlmayer, J. P. (1985). *Market Profile*. CBOT.

---

> [!info] Status del documento
> **Draft v3.0** — 2026-05-20. Fusión de v2.0 + Documento de Microestructura v1.0. Próxima revisión tras backtest preliminar de Fase 1 (Pre-FOMC + Overnight Drift sobre US500/NAS100).

> [!tip] Marco del autor
> *"Templanza en la ejecución, desapego al resultado, honestidad en la auto-evaluación."* Las 15 estrategias son hipótesis a falsar, no promesas. Las marcadas Tier A tienen base académica sólida pero **aún así pueden fallar OOS**. Cuando los datos hablen, escucharlos. *Soli Deo gloria.*
