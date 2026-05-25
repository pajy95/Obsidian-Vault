---
title: "10 Estrategias de Trading sin Indicadores Rezagados v2.0 — EA Research Roadmap"
date: 2026-05-20
version: 2.0
tags: [estrategia, investigacion, price-action, sin-indicadores, prop-firm, MQL5, calendar-anomaly, statistical-arbitrage, intermarket]
status: draft
supersedes: "v1.0 (2026-05-20)"
related:
  - "[[BreakoutNY]]"
  - "[[CTR Pro]]"
  - "[[Prompt Maestro v3.0]]"
  - "[[Framework IS-OOS-WF]]"
---

# 10 Estrategias de Trading sin Indicadores Rezagados v2.0

> [!info] Cambios respecto a v1.0
> Esta versión reemplaza 7 de las 10 estrategias originales por nuevas con (a) respaldo académico peer-reviewed reciente (2018–2025), (b) reglas deterministamente codificables sin juicio discrecional, y (c) baja correlación con el portafolio activo de Jose ([[BreakoutNY]] y [[CTR Pro]]).
>
> **Retenidas de v1.0** (3): First→Last Half-Hour Momentum (Gao 2018), EIA Crude Wednesday (Indriawan 2021), Post-News Fade.
>
> **Descartadas** (7): ORB-5 Stocks-in-Play (ya cubierto por BreakoutNY), ICT Silver Bullet (no codificable deterministamente), Asian Sweep + London Reversal (ICT-based), Crabel NR7 (degradación documentada: CAGR 7.8%, DD 25% sobre SPY 1993–presente), Turtle Soup (1996, sobre-conocido), Gap Fill (overcrowded), Initial Balance Breakout (esencialmente ORB en otra ventana).
>
> **Nuevas** (7): Pre-FOMC Drift, Overnight Drift Europeo, WMR 4PM Fix Reversal, Month/Quarter-End FX Rebalancing, NAS100/US500 Statistical Pair Trade, Heston-Korajczyk-Sadka Daily Periodicity, Pre-ECB Drift.

---

## Resumen Ejecutivo

Las 10 estrategias se distribuyen así por nivel de soporte empírico:

**Tier A — Respaldo académico peer-reviewed sólido y reciente** (6 estrategias):
- First→Last Half-Hour Momentum (Gao, Han, Li & Zhou 2018, *JFE*)
- EIA Crude Wednesday (Indriawan et al. 2021)
- Pre-FOMC Drift (Lucca & Moench 2015, *JF*; confirmado 2025)
- European Open Overnight Drift (Boyarchenko, Larsen & Whelan 2020/2022, NY Fed SR 917)
- Heston-Korajczyk-Sadka Daily Periodicity (Heston, Korajczyk & Sadka 2010, *JF*; Haendler et al. 2025 OOS)
- WMR 4PM Fix Reversal (Evans 2014/2018; Marsh, Panagiotou et al. 2017)

**Tier B — Soporte académico moderado o adaptado** (3 estrategias):
- Month/Quarter-End FX Rebalancing (Melvin & Prins 2015)
- Pre-ECB Drift (extensión de Lucca-Moench logic; Altavilla et al. 2019 microestructura)
- NAS100/US500 Pairs Trade Intraday (Gatev, Goetzmann & Rouwenhorst 2006 base; adaptación intradía)

**Tier C — Event-driven con cautela** (1 estrategia):
- Post-News Fade (NFP/CPI/FOMC spike reversal)

### Tabla Comparativa

| # | Estrategia | Tier | Activos | TF | Eventos/año | PF esperado | DD esperado | Rank |
|---|-----------|------|--------|----|-------------|-------------|-------------|------|
| 1 | **Pre-FOMC Drift** | A | US500, NAS100 | M30-H1 | 8 | 2.0–2.8 | 4–7% | ⭐⭐⭐⭐⭐ |
| 2 | **Overnight Drift Europeo** | A | US500, NAS100, GER40 | M15-H1 | ~250 | 1.5–1.9 | 5–8% | ⭐⭐⭐⭐⭐ |
| 3 | **First→Last Half-Hour** *(retenida)* | A | US500, NAS100 | M30 | ~250 | 1.5–1.8 | 5–8% | ⭐⭐⭐⭐⭐ |
| 4 | **EIA Crude Wednesday** *(retenida)* | A | USOIL | M30 | ~52 | 1.7–2.1 | 7–10% | ⭐⭐⭐⭐ |
| 5 | **WMR 4PM Fix Reversal** | A | EURUSD, GBPUSD | M5-M15 | ~250 + 12 (mes) | 1.4–1.8 | 4–7% | ⭐⭐⭐⭐ |
| 6 | **Heston Daily Periodicity** | A | NAS100, US500, GER40 | M30 | continuo | 1.4–1.7 | 5–8% | ⭐⭐⭐⭐ |
| 7 | **Month/Quarter-End FX Flow** | B | EURUSD, GBPUSD, AUDUSD | M15-H1 | 12-16 | 1.6–2.0 | 5–9% | ⭐⭐⭐⭐ |
| 8 | **Pre-ECB Drift** | B | GER40, EURUSD | H1 | 8 | 1.8–2.4 | 5–8% | ⭐⭐⭐⭐ |
| 9 | **NAS100/US500 Pairs Z-Score** | B | NAS100+US500 | M15 | ~150 | 1.4–1.7 | 4–7% | ⭐⭐⭐ |
| 10 | **Post-News Fade** *(retenida)* | C | EURUSD, XAUUSD, NAS100 | M1-M5 | ~24 | 1.6–2.4 | 8–13% | ⭐⭐⭐ |

---

## 1. Pre-FOMC Drift Strategy 🆕

> [!tip] Síntesis
> El paper más citado sobre anomalías en torno a anuncios de política monetaria. S&P 500 sube ~49 bps en las 24 horas anteriores al anuncio FOMC. Solo 8 eventos/año pero edge enorme por evento.

### Hipótesis central
En las 24 horas previas al anuncio FOMC programado, el SPX (y por extensión NAS100, GER40) acumula un drift positivo medible. **Claim falsificable**: el retorno close-to-close del día previo al FOMC más el retorno intradía hasta las 14:00 ET del día del FOMC supera con significancia estadística (t>2.0) al retorno promedio de días no-FOMC.

### Background teórico
- **Lucca & Moench (2015)** — *"The Pre-FOMC Announcement Drift"*, **Journal of Finance**, Vol. 70, No. 1, pp. 329–371 (originalmente FRB-NY Staff Report No. 512, 2011). Verbatim: *"since the Federal Open Market Committee (FOMC) began announcing its monetary policy decisions after scheduled meetings in 1994, excess returns on U.S. stocks have on average been more than 30 times larger on announcement days than on other days"*. El SPX sube ~49 bps en las 24 horas pre-FOMC. Magnitud: *"these pre-FOMC gains have accounted for over half of the total annual realized excess stock market returns"*.
- **QuantSeeker (Feb 2025)** confirmación OOS: *"the pre-FOMC price drift, first documented by Lucca and Moench (2015), remains persistent... The results hold across different ETFs, including SPY, QQQ... the strategy has continued to generate positive risk-adjusted returns in recent years, despite the effect being published over a decade ago"*.
- **Condición de amplificación**: el drift es más fuerte cuando VIX está alto. Lucca-Moench: *"Pre-FOMC returns are higher in periods when the slope of the Treasury yield curve is low, implied equity market volatility is high, and when past pre-FOMC returns have been high"*.

### Reglas de entrada (deterministas)
1. Calendario FOMC del año (8 reuniones programadas, dates conocidas con meses de antelación).
2. **Entry long**: market order a las **15:00 ET del día previo al FOMC** (D-1, hora de NY cash session afternoon).
3. **Filtro opcional VIX**: tomar el trade solo si VIX > 15 (paper documenta amplificación). Si VIX < 12, reducir tamaño 50%.
4. Sin filtros adicionales — la estrategia es pura calendar anomaly.

### Reglas de salida
- **Exit obligatorio**: market close a las **14:00 ET del día FOMC** (D-0, justo antes del anuncio típicamente a las 14:00-14:30 ET).
- **SL**: 1.5% del precio de entrada (≈ 1.5× σ diario típico en SPX).
- **No TP** — deja correr hasta time exit.

### Instrumentos óptimos
**US500** (paper original), **NAS100** (paper confirma extensión a QQQ). **GER40** funciona parcialmente vía spillover pero con menor magnitud — paper documenta también pre-FOMC effect en TSX y NIKKEI más débil.

### Timeframe
M30-H1 para entry/exit. Bias en D1.

### Sesión / ventana
Entry: 15:00 ET día previo (D-1).
Exit: 14:00 ET día FOMC (D-0).
Holding ~23 horas.

### Risk management
**1.0–1.5% por trade**. Solo 8 trades/año por instrumento → si te late mucho, puedes correr US500 + NAS100 + GER40 simultáneos (24 trades/año total).

### Performance esperada
- Win rate: 65–75% (paper: drift positivo en mayoría amplia de eventos).
- Avg R: 0.3–0.5 por trade.
- Sharpe esperado portfolio (3 instrumentos): 1.0–1.4.
- **Edge anual estimado**: 4–8% del capital con riesgo 1%/trade.

### Modos de fallo conocidos
- **Fed surprise hawkish anticipada**: cuando el mercado anticipa hawkish surprise, el drift se invierte. Excluir reuniones tras Fed minutes muy hawkish (Lucca-Moench filtra esto vía term structure).
- **Crisis events**: marzo 2020, septiembre 2008 — drift puede desaparecer. El paper documenta que en estos eventos el effect persiste pero con mayor volatilidad.
- **Regime change**: si Fed entra en "permanent hold" sin sorpresas durante 1+ año, drift puede disiparse.

### Stress test
- **Slippage x2**: bajo impacto (entry/exit en horas de alta liquidez).
- **News sensitivity**: la estrategia ES news-driven; cuidado con CPI/NFP que caigan dentro del holding period — filtrar.
- **Regime sensitivity**: media. Paper cubre 1994–2011, replications hasta 2025. Edge es persistente pero variable.

### Validation roadmap
- **IS 2018–2021**: confirmar drift positivo con t > 2.0 en SPX.
- **OOS 2022–2023**: PF > 1.5, ≥60% trades profitable.
- **WF 2024–presente**: rolling 12m IS / 3m OOS.
- **Crítico**: validar específicamente que post-2020 (era post-COVID) el edge persiste.

### Compatibilidad prop firm
✅ **Excelente**. Holding ~23h sin overnight risk al cash market. FundingPips/FundedNext sin restricciones específicas (no es news trading directo — entras la víspera).

### Implementación
- **Complejidad**: Baja.
- **Estimación MQL5**: 10–14 horas (FOMC calendar integration, time-zone handling, position management).

### Sinergia
**Cero correlación con [[BreakoutNY]] y [[CTR Pro]]** (event-based, timeframe distinto, instrumento similar pero ventana diferente). Esta es la estrategia "ancla" del portafolio nuevo.

---

## 2. European Open Overnight Drift 🆕

> [!tip] Síntesis
> Casi el 100% del equity premium americano se gana en una ventana de 1 hora al abrir Europa. Anomalía estructural rigurosa peer-reviewed.

### Hipótesis central
El precio de US equity futures (ES, NQ) presenta un drift positivo persistente entre 02:00 y 03:00 ET (= 07:00–08:00 GMT, apertura Frankfurt/Londres mayorista). **Claim falsificable**: el retorno medio en la ventana 02:00–03:00 ET es estadísticamente >0 con t>3.0, y representa una fracción mayoritaria del retorno diario.

### Background teórico
- **Boyarchenko, Larsen & Whelan (2020, revisado Aug 2022)** — *"The Overnight Drift"*, **Federal Reserve Bank of New York Staff Report No. 917** (también CEPR Discussion Paper DP14462). Resultado verbatim: *"almost 100 percent of the U.S. equity premium is earned during a one-hour window between 2:00 a.m. and 3:00 a.m. (EST), which we dub the 'overnight drift'"*.
- Mecanismo documentado: *"Consistent with models of inventory risk, we demonstrate a strong relationship with order imbalances at the close of the preceding U.S. trading day. Rationalizing unconditionally positive 'overnight drift' returns, we uncover an asymmetric reaction to demand shocks: market selloffs generate robust positive overnight reversals, while reversals following market rallies are much more modest"*.
- **Aplicación práctica**: dealers necesitan offloadear inventario nocturno; la apertura europea provee la primera ventana de liquidez de tamaño institucional, generando un risk premium temporal.

### Reglas de entrada (deterministas)
1. **Entry long** market order a las **02:00 ET** (07:00 GMT en horario estándar de invierno; 06:00 GMT en horario de verano DST). **Atención al DST**: paper documenta experimento natural usando DST como exógeno.
2. **Filtro de amplificación**: si el cierre US del día previo fue selloff (US500 < -0.5%), entry con tamaño 1.5× (paper documenta asimetría — reversals tras selloffs son más fuertes).

### Reglas de salida
- **Exit obligatorio**: 03:00 ET (08:00 GMT estándar, 07:00 GMT DST).
- **SL**: 0.7% del precio de entrada (1× σ horario típico).
- Holding ~1 hora máximo.

### Instrumentos óptimos
**US500** (paper original sobre ES). **NAS100** (probable extensión pero validar). **GER40** funciona pero ya está en sesión cash, mecánica distinta.

### Timeframe
M15 para señal; M5 para fill precision.

### Sesión / ventana
**02:00–03:00 ET estricto** (Killzone London open desde la perspectiva de futuros US).

### Risk management
0.5–0.75% por trade. Trade rápido (~1h), cumulative exposure baja.

### Performance esperada
- Win rate: 55–60% (paper documenta positive drift ~250 días/año).
- Avg R: 0.10–0.15 por trade.
- Frecuencia: ~250 trades/año.
- **Sharpe esperado**: 0.8–1.2 (Sharpe alto del paper se logra con leverage; en cuentas prop firm con limits, esperar más modesto).

### Modos de fallo
- **Days post-major US sell-off (>2%)**: amplificación puede invertirse si Asia continúa el selloff.
- **News europeo entre 02:00 y 03:00 ET**: ECB minutes, German ZEW etc. — filtrar.
- **DST transitions**: marzo y noviembre. Cuidado con timezone calculation.

### Stress test
- **Slippage x2**: bajo. Volumen en ES/NQ a las 02:00 ET es ~10% del intraday volume pero suficiente.
- **Spread**: ligeramente más amplio que durante US cash, modelar +20%.
- **News sensitivity**: media.
- **Regime sensitivity**: paper cubre 1990s–2022, edge persistente.

### Validation roadmap
- IS 2018–2021 sobre US500 (NAS100, GER40).
- OOS 2022–2023.
- WF rolling.
- **Crítico**: validar el DST handling — error común que cambia toda la estadística.

### Compatibilidad prop firm
✅ Compatible. Holding 1 hora, fuera de news window principal. FundingPips/FundedNext: sin issues.

### Implementación
- **Complejidad**: Baja.
- **Estimación MQL5**: 8–12 horas (timezone + DST robustez).

### Sinergia
**Independiente** de BreakoutNY y CTR Pro. Ventana temporal completamente distinta (madrugada ET). Excelente diversificación temporal del portafolio.

---

## 3. First→Last Half-Hour Momentum *(retenida v1.0)*

> [!tip] Síntesis
> El paper de Gao, Han, Li & Zhou (2018, *JFE*) — la estrategia con mayor solidez académica para indices US.

### Hipótesis central
El retorno de la primera media hora del día (open → 10:00 ET) predice positivamente el retorno de la última media hora (15:30–16:00 ET).

### Background teórico
- **Gao, Han, Li & Zhou (2018)** — *"Market Intraday Momentum"*, **Journal of Financial Economics**, 129(2), 394–414 (DOI 10.1016/j.jfineco.2018.05.009). Verbatim: *"the first half-hour return, r1, positively predicts the last half-hour return, r13, with a scaled (by 100) slope of 6.94, statistically significant at the 1% level"*. Sharpe documentado: 1.08; en alta vol R² sube a 3.3%.
- **Aviso explícito del paper**: NO existe momentum intradía análogo en forex o commodities en los datasets que probaron (Gao et al. 2018, sección Robustness). *"Overall, intraday momentum does not appear to exist in currency markets or commodity futures markets"*. Por tanto **esta estrategia es solo para US500 y NAS100**.

### Reglas de entrada
1. A las 10:00 ET (cash open + 30 min), calcular `r1 = (price_10am - prev_close) / prev_close`.
2. Filtro |r1| > 0.10%.
3. Entry market en dirección sign(r1) en algún punto entre 10:00 y 15:30 ET; variante refinada: esperar pullback a VWAP.

### Reglas de salida
- **Time exit obligatorio**: 15:55 ET.
- SL: 1.5× ATR(14) M30.
- Sin TP fijo.

### Instrumentos óptimos
US500, NAS100 únicamente (paper específico).

### Timeframe / sesión
M30; cash session NY 14:30–21:00 GMT.

### Risk management
0.5–0.75% por trade.

### Performance esperada
Win rate 52–56%, avg R 0.10–0.20, Sharpe 0.8–1.1.

### Implementación
Baja complejidad. 8–12 horas MQL5.

### Sinergia
Diversifica BreakoutNY (timeframe y lógica distintos). Conserva sinergia con Pre-FOMC Drift (estrategias de days diferentes).

---

## 4. EIA Crude Wednesday Momentum *(retenida v1.0)*

> [!tip] Síntesis
> La única estrategia del set con paper peer-reviewed específico sobre crude oil intraday.

### Hipótesis central
Tras release EIA (miércoles 10:30 ET), el retorno de la 3ª media hora predice positivamente el retorno de la última media hora en crude oil.

### Background teórico
- **Indriawan, Lien, Wen & Xu (2021)** — *"Intraday Return Predictability in the Crude Oil Market: The Role of EIA Inventory Announcements"*, SSRN 3822093. Verbatim: *"returns on the third half-hour on EIA announcement days can significantly and positively predict the returns in the last half-hour"*.

### Reglas de entrada
1. Solo miércoles con release EIA.
2. Calcular `r3` = return de la vela M30 que contiene el release (14:30 GMT verano / 15:30 GMT invierno).
3. Filtro |r3| > 0.30%.
4. Entry siguiente vela M30 en dirección sign(r3).

### Reglas de salida
- Time exit 21:00 GMT.
- SL 1.5× ATR(14) M30.

### Instrumentos óptimos
USOIL primario; UKOIL secundario (correlación alta pero EIA es US-specific).

### Timeframe / sesión
M30; solo miércoles.

### Risk management
1.0–1.5% por trade.

### Performance esperada
Win rate 55–60%, avg R 0.8–1.2, ~4 trades/mes.

### Implementación
Media complejidad. 10–14 horas MQL5.

### Sinergia
Independiente del resto (oil asset class único en el portafolio).

---

## 5. WMR 4PM London Fix Reversal 🆕

> [!tip] Síntesis
> Anomalía estructural en torno al "London 4pm Fix" — el benchmark FX más importante del mundo. Negative serial correlation pre/post fix peer-reviewed.

### Hipótesis central
En el minuto inmediatamente antes y después de las 16:00 GMT (London Fix WMR/Refinitiv), los precios FX presentan comportamiento atípico: pre-fix movimiento direccional, post-fix reversión parcial. El efecto se amplifica el último día hábil del mes. **Claim falsificable**: la correlación serial entre retorno pre-fix (15:55–16:00 GMT) y post-fix (16:00–16:05 GMT) es significativamente negativa, especialmente en EOM.

### Background teórico
- **Evans (2014, 2018)** — *"Forex Trading and the WMR Fix"*, **Journal of Banking and Finance** 87, 5–17 (también working paper). Verbatim sobre 21 pares FX a lo largo de una década (2000–2013): *"the behavior of spot rates in the minutes immediately before and after 4:00 pm are quite unlike that observed at other times. Pre- and post-Fix changes in spot rates are extraordinarily volatile and exhibit strong negative serial correlation, particularly on the last trading day of each month. These statistical features appear pervasive, they are present across all 21 currency pairs throughout the decade"*.
- **Marsh, Panagiotou & Payne (2017)** — *"The WMR Fix and its Impact on Currency Markets"*. Verbatim: *"During the 60 second calculation window of the Fix, there is an extreme concentration of interbank trading activity not present during any other point in time of the day generating order flow spikes for both the spot and the futures markets... active liquidation of positions at the Fix is apparent"*.
- **Melvin & Prins (2015)** documentan que portfolio managers ejecutan hedging FX en EOM en el Fix → flow predecible.

### Reglas de entrada (deterministas)
1. **Marcar pre-fix move**: retorno entre 15:50 GMT y 15:59 GMT (ventana de 9 minutos antes del fix).
2. **Filtro de magnitud**: pre-fix move debe ser ≥ 0.15% (filtra ruido).
3. **Entry contraria**: a las 16:01 GMT exacto, market order en dirección **opuesta** al pre-fix move.
4. **Filtro EOM amplificación**: si es último día hábil del mes, tamaño de posición 1.5×.

### Reglas de salida
- **Time exit obligatorio**: 16:30 GMT (30 min post-fix).
- **SL**: 0.20% del precio de entrada.
- **TP1**: 50% del pre-fix move (en dirección reverso).
- **TP2**: 100% del pre-fix move retracement.

### Instrumentos óptimos
**EURUSD, GBPUSD, USDJPY** (los más documentados en literatura). XAUUSD también muestra fix effects (LBMA price discovery overlap).

### Timeframe
M5 para detección de pre-fix move; M1 para entry precision.

### Sesión / ventana
**15:50–16:30 GMT estricto** (London Fix window y post-fix reversal window).

### Risk management
1.0% por trade en días normales; 1.5% en EOM.

### Performance esperada
- Win rate: 55–62% (negative serial correlation no es perfecta).
- Avg R: 0.5–0.8.
- Frecuencia: ~250 trades/año (cualquier día con pre-fix move >0.15%) + 12 EOM amplified.

### Modos de fallo
- **Días con news mayor entre 15:30–17:00 GMT** (US data): el pre-fix move puede ser fundamental, no flow-driven. Filtrar.
- **Cambios metodológicos del Fix**: en 2015 WM/Refinitiv extendió la ventana de cálculo de 1 min a 5 min para reducir manipulación. Validar que el effect persiste post-2015.
- **Reduced edge post-FCA scandal (2014)**: la investigación regulatoria redujo la collusion entre dealers; efecto puede haber decrecido en magnitud aunque persista en signo.

### Stress test
- **Slippage x2**: alto impacto. La ventana 16:00–16:01 GMT tiene spread temporal widening. Modelar +50% spread.
- **News sensitivity**: alta. Filtros estrictos.
- **Regime sensitivity**: paper cubre 2000–2013; replications muestran persistencia post-2015 con magnitud reducida.

### Validation roadmap
- IS 2018–2021 sobre EURUSD, GBPUSD.
- OOS 2022–2023: criterio paso PF > 1.4 (reduced edge post-FCA acceptable).
- WF 2024–presente.
- **Crítico**: separar performance EOM vs non-EOM en backtest.

### Compatibilidad prop firm
✅ Compatible. No es scalping puro (holding 30 min). FundingPips/FundedNext sin issues específicos.

### Implementación
- **Complejidad**: Media.
- **Estimación MQL5**: 14–18 horas (timing precision crítico).

### Sinergia
**Independiente** del resto. Replaces conceptualmente el Asian Sweep de v1.0 pero con base académica sólida en lugar de lore ICT.

---

## 6. Heston-Korajczyk-Sadka Daily Periodicity (Adaptación a Índices) 🆕

> [!tip] Síntesis
> Las velas M30 tienden a tener retornos correlacionados con la misma vela M30 del día anterior. Patrón persistente hasta 40 días según el paper original. Pura estadística.

### Hipótesis central
El retorno de la vela M30 que comienza a la hora H del día D está positivamente correlacionado con el retorno de la vela M30 que comienza a la hora H del día D-1 (y persiste hasta D-40). **Claim falsificable**: regresión `r(H,D) = α + β × r(H,D-1) + ε` produce β > 0 con t > 2.0 en índices.

### Background teórico
- **Heston, Korajczyk & Sadka (2010)** — *"Intraday Patterns in the Cross-Section of Stock Returns"*, **Journal of Finance**, 65(4), 1369–1407. Verbatim: *"We find a striking pattern of return continuation at half-hour intervals that are exact multiples of a trading day, and this effect lasts for at least 40 trading days. Volume, order imbalance, volatility, and bid-ask spreads exhibit similar patterns, but do not explain the return patterns"*.
- **Haendler, Heston, Korajczyk & Sadka (2025)** — *"The Intra-Day Stock Return Periodicity Puzzle"*, SSRN 5749704. Confirmación OOS: *"We demonstrate the patterns persist out-of-sample... Our proxies for institutional trading—changes in lendable shares, VWAP-like trading, and index inclusion—are the most significant explanatory variables. Overall, the results suggest that open periodicity is driven by VWAP trading while close periodicity by market-on-close trading"*.
- **Caveat de adaptación**: paper original es sobre cross-section de acciones individuales. Adaptación a índices CFD (NAS100, US500, GER40) **requiere validación específica** — el mecanismo (institutional execution scheduling, VWAP trading) opera en stocks individuales, debería transmitirse al índice agregado pero con menor magnitud.

### Reglas de entrada (deterministas)
1. Cash session NY/Frankfurt dividida en 13 velas M30 (NYSE: 9:30–16:00; Frankfurt: 9:00–17:30).
2. Para cada vela M30 actual (hora H), calcular media de retornos en la misma vela M30 hora H durante los últimos 20 días hábiles: `μ(H) = mean(r(H, D-1), r(H, D-2), ..., r(H, D-20))`.
3. **Entry long** si `μ(H) > +0.10%` durante esa vela actual; **entry short** si `μ(H) < -0.10%`.
4. Posición ya colocada al inicio de la vela H.

### Reglas de salida
- **Exit obligatorio**: cierre de la vela M30 (30 min holding).
- SL: 1× ATR(14) M30.

### Instrumentos óptimos
**NAS100, US500** (paper original sobre US equity); **GER40** (extensible vía equity overlap).

### Timeframe
M30 estricto.

### Sesión
Cash session del instrumento (US: 14:30–21:00 GMT; GER40: 08:00–16:30 GMT).

### Risk management
0.5% por trade. Alta frecuencia (~13 velas × ~50% trade signals = 6 potential trades/día/instrumento).

### Performance esperada
- Win rate: 52–55%.
- Avg R: 0.05–0.10 por trade.
- Frecuencia: ~3–6 trades/día/instrumento.
- Crítico: **edge muy pequeño por trade**; depende de frecuencia y costos bajos.

### Modos de fallo
- **High-cost CFD spreads**: si spread en NAS100 es 1.5 puntos y avg R es 0.05R con SL ATR(14)=12 puntos, los costos consumen 1.5/12 = 12.5% por trade. Validar costos antes de live.
- **Regime change**: el paper documenta persistence pero magnitude varies; en crisis weeks the patterns invert.
- **Mid-day low volume bins**: el effect es más fuerte en bins del open y close (paper 2025 lo confirma); bins de mediodía pueden no funcionar.

### Stress test
- **Slippage x2**: crítico. Modelar realísticamente; si edge cae a 0.03R por trade, la estrategia no es viable.
- **Spread x1.5**: similar.
- **News sensitivity**: media. Filtrar días con news durante el bin.

### Validation roadmap
- IS 2018–2021: validar β > 0 con t > 2.0 sobre NAS100 + US500.
- OOS 2022–2023: PF > 1.3 (target moderado dado magnitud edge).
- WF 2024–presente.
- **Crítico**: backtest con spreads/comisiones realistas. Si CI bootstrap del PF incluye 1.0 → abandonar.

### Compatibilidad prop firm
✅ Compatible pero **cuidado**: alta frecuencia (~6 trades/día/instrumento × 3 instrumentos = 18 trades/día). Algunos prop firms tienen limits informales sobre "scalping" o número de trades — verificar términos específicos.

### Implementación
- **Complejidad**: Media.
- **Estimación MQL5**: 14–20 horas (rolling window estadístico, multi-bin management).

### Sinergia
Diversifica BreakoutNY (alta frecuencia vs media frecuencia). Posible **correlación moderada con First→Last Half-Hour** (ambas explotan misma estructura de mercado pero en bins distintos).

---

## 7. Month/Quarter-End FX Rebalancing Flow 🆕

> [!tip] Síntesis
> Los gestores institucionales ejecutan hedging FX en el WMR Fix el último día del mes. El flow es estimable por la performance equity del mes; produce reversión post-EOM.

### Hipótesis central
Cuando US equities outperforman foreign equities durante un mes, los gestores no-US deben vender USD al EOM Fix para rebalancear hedges → presión bajista en USD en el Fix del último día hábil. Tras el Fix, el flow termina y el USD revierte parcialmente. **Claim falsificable**: el retorno del FX major (e.g. EURUSD) entre Fix(EOM) y Fix(EOM+1 día) muestra reversion estadísticamente significativa hacia la dirección opuesta al pre-Fix flow.

### Background teórico
- **Melvin & Prins (2015)** — *"Equity Hedging and Exchange Rates at the London 4pm Fix"*, **Journal of International Money and Finance**. Estudio del flow predictable. Verbatim por Marsh-Panagiotou: *"Melvin and Prins (2015) describe how currency hedging by international equity portfolio managers generates a flow of Fix orders, and estimate a simple model for this flow at the end of each month. They then show that intraday returns are positively related to their estimated flows before the Fix and negative related after the Fix"*.
- **BNY Mellon iFlow research (publicado mensual, ej. marzo 2025)**: modelos comerciales del flow basados en equity outperformance + realized FX flows. Confirma persistencia institucional.
- **Quarter-end amplification**: muchos fondos rebalancean quarterly (no monthly), generando flow más fuerte en finales de marzo, junio, septiembre, diciembre.

### Reglas de entrada (deterministas)
1. **Identificar EOM**: último día hábil del mes (excluir festivos US/UK/EU).
2. **Estimar el flow signal**: 
   - Calcular `equity_perf_month = (US500_close_EOM - US500_close_EOM-1mes) / US500_close_EOM-1mes`.
   - Si `equity_perf_month > +2%` → señal de USD selling en Fix EOM (esperar EURUSD up pre-Fix, reversion post-Fix).
   - Si `equity_perf_month < -2%` → señal de USD buying en Fix EOM (inverso).
   - Si `|equity_perf_month| < 2%` → no trade.
3. **Quarter-end multiplier**: si EOM es también EOQ (marzo, junio, sep, dic), multiplicar el signal × 1.5.
4. **Entry**: a las **16:01 GMT del EOM** (justo post-Fix), market order **en dirección opuesta al pre-Fix flow esperado**. Ejemplo: si esperabas USD selling y viste EURUSD subir 0.4% en últimas 2 horas pre-Fix → short EURUSD post-Fix.

### Reglas de salida
- **TP**: 50% retracement del pre-Fix move.
- **SL**: 0.30% (más amplio que estrategia 5 porque holding es más largo).
- **Time exit**: cierre del día siguiente NY (24h post-entry).

### Instrumentos óptimos
**EURUSD, GBPUSD** (paper documenta majors). AUDUSD y NZDUSD también funcionan por exposure significativo de portfolios globales a Asia-Pacific. USDJPY más ruidoso (BoJ intervention windows).

### Timeframe
H1 para signal; M15 para entry execution.

### Sesión
**EOM 16:00 GMT — siguiente día NY close (~21:00 GMT D+1)**.

### Risk management
1.5% por trade en EOM normal; 2.0% en EOQ. Riesgo absoluto del mes contenido a ~3% (1 EOM trade).

### Performance esperada
- Win rate: 55–65%.
- Avg R: 0.8–1.5.
- Frecuencia: 12 EOM + 4 EOQ amplified = 16 trades/año.
- **Edge anual**: 6–12% del capital con risk 1.5%/trade.

### Modos de fallo
- **EOM coincide con news mayor**: si NFP cae el EOM (raro pero posible), filtrar.
- **Holidays**: si EOM es feriado en US o UK, el Fix se mueve a día anterior. Implementar calendar handling robusto.
- **Equity outperformance ambigua**: si US y foreign equities muevan en mismo signo, el signal es débil. Filtrar |perf| < 2%.
- **Edge institucional crowded**: la estrategia es bien conocida en sell-side; muchos traders intentan front-runear el flow, lo que puede reducir o invertir el effect en años recientes.

### Stress test
- **Slippage x2**: medio impacto.
- **News sensitivity**: alta cerca del Fix; filtrar.
- **Regime sensitivity**: paper cubre datos hasta 2010; replicaciones post-2015 muestran reduced magnitude pero persistente.

### Validation roadmap
- IS 2018–2021: validar reversion post-EOM-Fix con t > 2.0.
- OOS 2022–2023: PF > 1.5.
- WF 2024–presente.
- **Crítico**: documentar performance EOM normal vs EOQ separadamente.

### Compatibilidad prop firm
✅ Compatible. 16 trades/año, sin scalping, FundingPips/FundedNext OK.

### Implementación
- **Complejidad**: Media-Alta. Calendar logic robusto, multiple instruments.
- **Estimación MQL5**: 18–24 horas.

### Sinergia
**Sinergia con WMR Fix Reversal (#5)**: misma anomalía Fix-related, escalas temporales distintas. Implementarlas juntas duplica exposure a same risk factor — gestionar como uno o el otro, no ambos simultáneos en EOM. Independiente de BreakoutNY y CTR Pro.

---

## 8. Pre-ECB Drift Strategy 🆕

> [!tip] Síntesis
> Análogo europeo del Pre-FOMC Drift. DAX y STOXX 50 muestran drift positivo en el día previo al ECB press conference.

### Hipótesis central
En el día previo (D-1) al ECB monetary policy press conference (jueves a las 13:45 CET / 12:45 GMT habitualmente), DAX y STOXX 50 acumulan drift positivo. **Claim falsificable**: el retorno close-to-close del D-1 ECB es estadísticamente positivo, t > 2.0 vs días no-ECB.

### Background teórico
- **QuantPedia (junio 2025)** — *"Uncovering the Pre-ECB Drift and Its Trading Strategy Applications"*. Verbatim: *"European equity markets tend to exhibit a strong and consistent upward drift on the day before the ECB's scheduled press conference. The reason for this timing difference lies in logistics: since the ECB typically speaks at 14:15 CET (8:15 a.m. EST), well before the major U.S. markets open, investors often front-run the potential market-friendly signals from the central bank"*. Histogramas y equity curves D-1 positivas para DAX y STOXX 50.
- **Altavilla, Brugnolini, Gürkaynak, Motto & Ragusa (2019)** — *"Measuring Euro Area Monetary Policy"*, **Journal of Monetary Economics** — provee la euro area monetary policy event-study database con intraday FX/equity reactions; sustento microestructural.
- **Caveat**: la evidencia académica del pre-ECB drift es **más débil** que la del Pre-FOMC. Lucca-Moench (2015) cubrió pre-FOMC con datos hasta 2011 y publicó en JF; el pre-ECB ha sido documentado por practitioners (QuantPedia) y por extensión de la logic Altavilla. **Tratar como hipótesis menos firmemente establecida**.

### Reglas de entrada
1. Calendario ECB anual (8 reuniones programadas).
2. **Entry long** market order a las **08:00 CET (07:00 GMT) del D-1 ECB** (apertura Frankfurt).
3. Sin filtros adicionales en la primera implementación.

### Reglas de salida
- **Exit obligatorio**: 17:30 CET (16:30 GMT) del D-1 ECB (cierre cash Xetra).
- Holding ~9h.
- SL: 1.0% del precio de entrada.

### Instrumentos óptimos
**GER40 (DAX)** primario, **EURUSD** secundario (correlación inversa con DAX en risk-on/off — testear).

### Timeframe
H1 entry/exit; D1 bias.

### Sesión
D-1 ECB cash Frankfurt session.

### Risk management
1.0–1.5% por trade. 8 trades/año por instrumento.

### Performance esperada
- Win rate: 60–70% (QuantPedia muestra histograma sesgado positivo).
- Avg R: 0.4–0.6.
- Sharpe esperado: 0.9–1.3.
- **Edge anual estimado**: 3–6% por instrumento.

### Modos de fallo
- **ECB surprise dovish anticipada**: similar al pre-FOMC, si mercado anticipa surprise hawkish el drift se invierte.
- **EU crisis events**: Italy political crisis, Brexit referendum, etc.
- **Edge no confirmado peer-reviewed**: si QuantPedia data se basa en sample limitada, edge puede no ser robust.

### Stress test
- Slippage x2: bajo impacto (H1 entries).
- News sensitivity: filtrar otros ECB officials speaking pre-meeting.
- Regime: validar en distintos ECB cycle phases (hiking vs cutting vs hold).

### Validation roadmap
- IS 2018–2021 sobre GER40.
- OOS 2022–2023: PF > 1.5. **Especial atención al CI bootstrap dado que el edge no es peer-reviewed**.
- WF 2024–presente.
- **Crítico**: si CI lower bound < 1.2, abandonar.

### Compatibilidad prop firm
✅ Compatible. ECB es press conference, no scheduled news en el mismo sentido que NFP — pero verificar reglas específicas.

### Implementación
- Complejidad: Baja.
- Estimación MQL5: 10–14 horas.

### Sinergia
**Sinergia con Pre-FOMC Drift**: same family de calendar anomaly strategies. Implementar ambas → ~16 trades/año total event-driven. Independiente del resto del portafolio.

---

## 9. NAS100/US500 Pairs Z-Score Intraday Mean Reversion 🆕

> [!tip] Síntesis
> Pairs trading clásico aplicado al ratio NAS100/US500. Cuando el spread se desvía de su media móvil, revierte intradía.

### Hipótesis central
NAS100 y US500 son altamente cointegrados (sectorialmente: tech-heavy vs broad market). El log-spread `log(NAS100) - β × log(US500)` con β ≈ 1.05–1.15 (hedge ratio rolling) es estacionario intradía. Cuando el Z-score del spread excede ±2σ, revierte hacia 0 con expectancy positiva. **Claim falsificable**: estrategia long-short long NAS100 / short US500 cuando Z < -2 (o inversa cuando Z > 2) produce expectancy > 0 neta de costos.

### Background teórico
- **Gatev, Goetzmann & Rouwenhorst (2006)** — *"Pairs Trading: Performance of a Relative-Value Arbitrage Rule"*, **Review of Financial Studies** 19(3). Paper seminal sobre pairs trading. Documenta excess returns sustained desde 1962 sobre US equities.
- **Caldeira & Moura (2013)** y extensiones modernas aplican el framework a ETFs e índices.
- **QuantStart**: *"In this article we are going to consider our first intraday trading strategy... We are going to be making use of two Exchange Traded Funds (ETFs), SPY and IWM, which are traded on the New York Stock Exchange (NYSE) and attempt to represent the US stock market indices, the S&P500 and the Russell 2000 respectively... The ratio of long to short can be defined in many ways such as utilising statistical cointegrating time series techniques"*. NAS100/US500 es análogo más limpio aún (ambas large-cap, alto overlap).
- **Caveat retail**: prop firms generalmente no permiten "true" pairs trading con offsetting positions — sí permiten dos trades independientes en correlated instruments. La P&L será la suma, sin netting de margin.

### Reglas de entrada (deterministas)
1. **Calcular hedge ratio rolling**: cada día, regresión OLS de últimos 30 días close-to-close: `log(NAS100) = α + β × log(US500) + ε`. β típicamente 1.05–1.15.
2. **Calcular spread M15**: en cada vela M15, `spread = log(NAS100) - β × log(US500)`.
3. **Calcular Z-score**: usando media y std móvil del spread últimas 100 velas M15 (~25h cash session).
4. **Entry long-short**:
   - Si Z < -2.0 → long NAS100 y short US500 (en lots equivalentes ajustados por point value).
   - Si Z > +2.0 → short NAS100 y long US500.
5. Solo durante cash session NY (14:30–21:00 GMT).

### Reglas de salida
- **TP**: cuando Z cruza 0 (mean reversion completa).
- **SL**: si Z se mueve a ±3.0 (continuación adversa), close ambas posiciones.
- **Time exit**: cierre forzado 20:55 GMT (5 min pre cash close).

### Instrumentos óptimos
**NAS100 + US500 simultáneo**. Alternativas: NAS100/GER40 (correlación menor pero positiva).

### Timeframe
M15 estricto.

### Sesión
Cash session NY.

### Risk management
**Posición combinada**: 1.0% de capital total (0.5% por leg). Importante: ambos legs cuentan para los limits del prop firm; si FundingPips daily loss limit es 5% y ambas legs van mal, la combined drawdown puede llegar fácil a 2% en una mala sesión.

### Performance esperada
- Win rate: 60–70% (mean reversion strategies tienden a high win rate, low avg R).
- Avg R: 0.3–0.5 por combined trade.
- Frecuencia: ~3 trades/día (combined).
- Sharpe esperado: 0.7–1.0.

### Modos de fallo
- **Cointegration breakdown**: si tech sector decouple de broad market sostenidamente (e.g. dot-com bubble dynamics), el spread no revierte y diverge. Crítico monitorear hedge ratio stability.
- **News asimétrica**: si CPI específicamente afecta tech (Fed policy implications) más que broad market → spread se mueve por fundamentales no reversion.
- **High costs**: dos legs = dos spreads + dos comisiones. Validate cost <0.1R por trade.

### Stress test
- **Slippage x2**: medio. Modelar ambos legs.
- **Spread**: factor crítico, simular x1.5.
- **Regime sensitivity**: validar período 2020 marzo (cointegration broke briefly).
- **Hedge ratio shock**: si β cambia >20% entre rolling windows, abandonar trade y reset.

### Validation roadmap
- IS 2018–2021: validar Z-score reversion con t > 2.0 sobre M15 NAS100/US500.
- OOS 2022–2023: PF > 1.4 (target moderado por costos).
- WF 2024–presente.
- **Crítico**: monitorear cointegration tests (Engle-Granger, Johansen) en rolling window.

### Compatibilidad prop firm
⚠️ **Verificar**: muchos prop firms permiten posiciones simultáneas en instruments distintos sin issue. Pero el **combined drawdown** cuenta para daily/total loss limits. FundingPips daily 5% → ambas legs perdiendo 2.5% cada una = breach.

### Implementación
- **Complejidad**: Alta. Cointegration test, hedge ratio rolling, dual-instrument position management, dual-leg risk.
- **Estimación MQL5**: 24–32 horas.

### Sinergia
Diversifica BreakoutNY (mean reversion vs breakout — anti-correlación natural). Sin overlap con CTR Pro (XAUUSD).

---

## 10. Post-News Fade *(retenida v1.0, con cautelas reforzadas)*

> [!tip] Síntesis
> Fade del primer spike post-news mayor (NFP, CPI, FOMC). Estrategia más arriesgada del set.

### Hipótesis central
Tras spike news-driven > 3× ATR M1 con rejection candle, revierte parcialmente hacia pre-news price.

### Background teórico
- Practitioner research multiple (Robotwealth, FXEmpire, 2023–2025).
- **Caveat académico mantenido**: hay literatura mixta. Boyarchenko et al. (2020) documentan asimetría reversion en equities post-selloffs. NO hay consenso peer-reviewed sobre fade-the-news directo.

### Reglas (resumen — ver v1.0 para detalle)
- Spike > 3× ATR(20) M1 dentro de 5 min post-release.
- First M5 candle close debe mostrar rejection pattern.
- Entry stop en break de la wick de rechazo.
- SL: 1 pip más allá del extremo del spike.
- TP1: pre-news price; TP2: 50% beyond.
- Time exit 60 min.

### Instrumentos óptimos
EURUSD, GBPUSD, XAUUSD (FOMC), NAS100 (CPI/FOMC).

### Performance esperada
Win rate 50–60%, avg R 1.5–2.5, ~6–8 trades/mes.

### Compatibilidad prop firm
⚠️ **Verificar reglas news**. FundingPips Zero (Instant) prohíbe news trading. FundingPips 1-Step/2-Step lo permite en evaluación. FundedNext: profits excluded si trade dentro de 5h antes / 5 min después de high-impact news en funded.

### Implementación
Alta complejidad. 30–45 horas MQL5.

---

## Análisis Cross-Strategy

### Matriz de correlación esperada (cualitativa)

| | Pre-FOMC | Overnight | First-Last | EIA | WMR Fix | Heston | EOM Flow | Pre-ECB | Pairs | News Fade |
|--|--|--|--|--|--|--|--|--|--|--|
| **Pre-FOMC** | 1.0 | 0.2 | 0.3 | 0.0 | 0.1 | 0.2 | 0.1 | 0.3 | 0.1 | 0.4 |
| **Overnight Drift** | 0.2 | 1.0 | 0.3 | 0.0 | 0.0 | 0.3 | 0.0 | 0.2 | 0.2 | 0.1 |
| **First→Last 1/2h** | 0.3 | 0.3 | 1.0 | 0.0 | 0.0 | **0.6** | 0.0 | 0.2 | 0.3 | 0.2 |
| **EIA Crude** | 0.0 | 0.0 | 0.0 | 1.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.1 |
| **WMR Fix Reversal** | 0.1 | 0.0 | 0.0 | 0.0 | 1.0 | 0.0 | **0.5** | 0.1 | 0.0 | 0.1 |
| **Heston Periodicity** | 0.2 | 0.3 | **0.6** | 0.0 | 0.0 | 1.0 | 0.0 | 0.1 | 0.4 | 0.1 |
| **EOM/Quarter Flow** | 0.1 | 0.0 | 0.0 | 0.0 | **0.5** | 0.0 | 1.0 | 0.1 | 0.0 | 0.1 |
| **Pre-ECB Drift** | 0.3 | 0.2 | 0.2 | 0.0 | 0.1 | 0.1 | 0.1 | 1.0 | 0.1 | 0.2 |
| **Pairs Z-Score** | 0.1 | 0.2 | 0.3 | 0.0 | 0.0 | 0.4 | 0.0 | 0.1 | 1.0 | 0.1 |
| **News Fade** | 0.4 | 0.1 | 0.2 | 0.1 | 0.1 | 0.1 | 0.1 | 0.2 | 0.1 | 1.0 |

> [!warning] Correlaciones a vigilar
> - **First→Last Half-Hour ↔ Heston Periodicity = 0.6**: ambas explotan estructura intraday del cash NY. Implementar **una de las dos** en producción, no ambas.
> - **WMR Fix Reversal ↔ EOM Flow = 0.5**: same anomaly Fix-related, escala temporal distinta. En EOM days el riesgo se duplica si ambas activas.
> - **Pre-FOMC ↔ Post-News Fade = 0.4**: ambas event-driven en FOMC days. En FOMC day el riesgo se concentra.

### Recomendación de construcción de portafolio

**Tier 1 — Desarrollar primero (meses 1–5)**:
1. **Pre-FOMC Drift** ★★★★★ — solidez académica máxima (Lucca-Moench JF), implementación baja complejidad, ~8 trades/año pero edge enorme por trade.
2. **European Open Overnight Drift** ★★★★★ — solidez académica máxima (NY Fed SR 917), ~250 trades/año, riesgo controlado.
3. **First→Last Half-Hour** ★★★★★ — retenida, solidez académica máxima (Gao JFE).

**Tier 2 — Desarrollar después (meses 6–10)**:
4. **EIA Crude Wednesday** ★★★★ — retenida, diversificación oil class.
5. **Month/Quarter-End FX Flow** ★★★★ — peer-reviewed, ~16 trades/año, edge institucional.
6. **WMR 4PM Fix Reversal** ★★★★ — peer-reviewed, alta frecuencia, sinergia con #5.

**Tier 3 — Investigar / paper trading antes de live (meses 11–15)**:
7. **Pre-ECB Drift** ★★★★ — soporte académico moderado, replica el framework #1 para Europa.
8. **Heston Daily Periodicity** ★★★★ — soporte académico fuerte pero adaptación a indices CFD requiere validación cuidadosa.

**Tier 4 — Especulativas / alta cautela**:
9. **NAS100/US500 Pairs Trade** ★★★ — complejidad alta, prop firm risk management complejo.
10. **Post-News Fade** ★★★ — operacionalmente riesgosa, validar slippage realista.

### Selección recomendada del portafolio Top 4 para próximos 6 meses

Considerando solidez académica + baja correlación + complejidad de implementación + sinergia con [[BreakoutNY]] y [[CTR Pro]]:

1. **Pre-FOMC Drift** sobre NAS100 + US500 (~10-14h MQL5 development)
2. **European Open Overnight Drift** sobre NAS100 + US500 (~8-12h)
3. **EIA Crude Wednesday** sobre USOIL (~10-14h)
4. **First→Last Half-Hour** sobre US500 (~8-12h)

Total: ~40h de desarrollo MQL5 para 4 estrategias con respaldo peer-reviewed sólido, baja correlación cruzada, y baja correlación con portafolio activo. Estimación realista: 2 meses de desarrollo paralelo a operación de BreakoutNY/CTR Pro.

---

## Framework de Validación

Aplicar [[Framework IS-OOS-WF]] con criterios estrictos:

> [!info] Criterios de paso por estrategia
> 1. **IS 2018–2021** (4 años): optimizar 1–2 parámetros máximo. Documentar parameter plateau ±20%.
> 2. **OOS 2022–2023** (2 años): sin re-optimizar. Aceptar si:
>    - PF ≥ 1.5 (mínimo) / ≥ 2.0 (objetivo)
>    - DD < 10% (target)
>    - ≥60% años profitable
>    - t-test R-multiples: t > 2.0, Cohen's d > 0.15
>    - **Bootstrap CI (1000 iter) del PF: lower bound > 1.0**
> 3. **WF 2024–presente**: rolling 12m IS / 3m OOS.
> 4. **Auto-abandono**: si CI bootstrap incluye 1.0 → descartar.

Para estrategias **Tier C** (Post-News Fade, NAS100/US500 Pairs, posiblemente Pre-ECB), aplicar **threshold conservador**: CI lower bound > 1.2 requerido.

Ver [[Prompt Maestro v3.0]] para hypothesis-first methodology y documentation requirements.

---

## Referencias

### Peer-reviewed papers
- Gao, L., Han, Y., Li, S. Z., & Zhou, G. (2018). "Market Intraday Momentum." *Journal of Financial Economics*, 129(2), 394–414.
- Lucca, D. O., & Moench, E. (2015). "The Pre-FOMC Announcement Drift." *Journal of Finance*, 70(1), 329–371.
- Heston, S. L., Korajczyk, R. A., & Sadka, R. (2010). "Intraday Patterns in the Cross-Section of Stock Returns." *Journal of Finance*, 65(4), 1369–1407.
- Boyarchenko, N., Larsen, L. C., & Whelan, P. (2020/2022). "The Overnight Drift." FRB-NY Staff Report 917 / CEPR DP14462.
- Evans, M. D. D. (2018). "Forex Trading and the WMR Fix." *Journal of Banking and Finance* 87, 5–17.
- Marsh, I. W., Panagiotou, P., & Payne, R. (2017). "The WMR Fix and its Impact on Currency Markets." Norges Bank Working Paper.
- Melvin, M., & Prins, J. (2015). "Equity Hedging and Exchange Rates at the London 4pm Fix." *Journal of International Money and Finance*.
- Gatev, E., Goetzmann, W. N., & Rouwenhorst, K. G. (2006). "Pairs Trading: Performance of a Relative-Value Arbitrage Rule." *Review of Financial Studies* 19(3).
- Indriawan, I., Lien, D., Wen, Z., & Xu, Y. (2021). "Intraday Return Predictability in the Crude Oil Market: The Role of EIA Inventory Announcements." SSRN 3822093.
- Altavilla, C., Brugnolini, L., Gürkaynak, R. S., Motto, R., & Ragusa, G. (2019). "Measuring Euro Area Monetary Policy." *Journal of Monetary Economics*.
- Haendler, C., Heston, S. L., Korajczyk, R. A., & Sadka, R. (2025). "The Intra-Day Stock Return Periodicity Puzzle." SSRN 5749704.

### Working papers / replications
- QuantSeeker (Feb 2025). "Trading the Fed: The Pre-FOMC Drift is Alive."
- QuantPedia (Jun 2025). "Uncovering the Pre-ECB Drift and Its Trading Strategy Applications."
- BNY iFlow Research (mensual). "Month-end Rebalancing Analysis."

### Books reference
- Chan, E. (2013). *Algorithmic Trading: Winning Strategies and Their Rationale*. Wiley.
- Lopez de Prado, M. (2018). *Advances in Financial Machine Learning*. Wiley.
- Vidyamurthy, G. (2004). *Pairs Trading: Quantitative Methods and Analysis*. Wiley.

---

> [!info] Status del documento
> **Draft v2.0** — 2026-05-20. Próxima revisión tras backtest preliminar de Tier 1 strategies (Pre-FOMC + Overnight Drift sobre US500/NAS100).

> [!tip] Marco de fe del autor
> *"Templanza en la ejecución, desapego al resultado, honestidad en la auto-evaluación."* Las 10 estrategias son hipótesis a falsar, no promesas. Las marcadas Tier A tienen base académica sólida pero **aún así pueden fallar OOS** en años recientes. Cuando los datos hablen, escucharlos. *Soli Deo gloria.*
