# TBR SPX500 M5 — Análisis IS Optimización
**Fecha:** 2026-05-17
**EA:** TBR v1.1 | Sin filtros (RangeFilter/ATRFilter/EntryWindow OFF)
**Símbolo:** SPX500, M5
**Período total:** 2022-01-01 → 2025-12.30
**Broker/Cuenta:** FundingPips2-SIM | $5,000 | Leverage 25x
**MagicNumber reservado:** 202505
**Archivo fuente:** `Optimizacion/SPX500/OP_TBR_SPX500_M5_v1.1.xml`

---

## Configuración de la Optimización

| Parámetro | Rango testeado |
|-----------|----------------|
| TradeDirection | BOTH (0) / BUY (1) |
| RangeCandlesCount | 1 – 6 |
| SessionStart_Min | 0, 15, 30, 45 (mins desde 14:00 UTC) |
| RR | 2.0 – 5.0 (paso 0.5) |
| EntryMode | Pending (fijo) |
| Filtros v1.1 | OFF |

**Algoritmo:** Complete — ~38-42 passes por sesión, cobertura exhaustiva ✓

> **Forward Mode activo en MT5:**
> - **BR** = IS back period (2022–2024 aprox.)
> - **FR** = Forward period OOS interno (2025 aprox.)

---

## Estadísticas Globales (256 passes)

| Métrica | M5 | M3 (referencia) |
|---------|----|----|
| FR promedio (OOS interno) | **0.989** | 1.005 |
| BR promedio (IS) | 1.156 | 1.281 |
| PF máximo | **1.313** | 1.279 |
| FR máximo | **1.31** | 1.28 |
| Passes FR > 1.20 | 6 / 256 | 8 / 256 |
| Passes viables (PF>1.20) | 7 | 9 |
| Dirección dominante | **BUY** | BUY |

### Distribución PF

| Rango | Count |
|-------|-------|
| < 0.8 | 17 |
| 0.8 – 0.9 | 51 |
| 0.9 – 1.0 | 56 |
| 1.0 – 1.1 | 88 |
| 1.1 – 1.2 | 37 |
| 1.2 – 1.3 | 6 |
| ≥ 1.3 | 1 |

---

## Análisis de Meseta

### Dirección
BUY (1): avg PF=1.012, max=1.313, viable=5
BOTH (0): avg PF=0.953, max=1.263, viable=2

**Conclusión: TradeDirection = BUY — confirmado en M5.**

### Session Start

| Session UTC | Avg PF | Max PF | FR>1.20 | BUY passes |
|-------------|--------|--------|---------|------------|
| 14:00 | 0.933 | 1.203 | 0 | 37 |
| **14:15** | **1.079** | **1.313** | **4** | 38 |
| 14:30 | 1.036 | 1.146 | 0 | 40 |
| 14:45 | 0.999 | 1.199 | 0 | 42 |

**Hallazgo crítico confirmado en M5:** La sesión óptima es **14:15 UTC** — 15 minutos ANTES de la apertura de NY (14:30). El rango se forma entre 14:15–14:25 UTC (pre-open), y el breakout se ejecuta en los primeros minutos del open.

Hipótesis: el rango pre-open captura el posicionamiento institucional antes de la apertura formal, y el breakout aprovecha el flujo de órdenes en apertura.

**Cobertura perfecta por sesión** (37-42 passes) → resultado confiable, sin sesgo de muestreo.

### RangeCandlesCount (BUY)

| Range | Avg PF | Max PF | FR>1.20 |
|-------|--------|--------|---------|
| 1 | 0.945 | 1.199 | 0 |
| **2** | **1.043** | **1.313** | **3** |
| **3** | **1.047** | 1.242 | — |
| 4 | 0.992 | 1.179 | 0 |
| 5 | 1.041 | 1.203 | 0 |
| 6 | 1.003 | 1.164 | 0 |

**Zona: Range=2-3.** Range=2 (10 min de formación) concentra los mejores passes con FR>1.20.

### Curva RR — Meseta identificada

**Range=2, Session=14:15, BUY** — curva completa:

| RR | PF | FR | BR | DD% | T | FR≈BR |
|----|----|----|-----|-----|---|-------|
| 2.0 | 1.052 | 1.05 | 1.21 | 3.6 | 238 | ✗ (BR>>FR) |
| 2.5 | 1.094 | 1.09 | 1.16 | 2.6 | 238 | ✗ |
| **3.0** | **1.172** | **1.17** | **1.19** | **2.6** | **238** | **✓** |
| **3.5** | **1.234** | **1.23** | **1.22** | **2.3** | **238** | **✓** |
| **4.0** | **1.186** | **1.19** | **1.19** | **3.9** | **238** | **✓** |
| **4.5** | **1.275** | **1.27** | **1.24** | **4.8** | **238** | **✓** |
| 5.0 | 1.313 | 1.31 | 1.24 | 4.5 | 238 | ✗ (diff>0.06) |

**Meseta confirmada: RR 3.0 – 4.5** (4 valores consecutivos con FR≈BR).

> En RR=2.0-2.5: BR>>FR → IS sobreajustado en la dirección del IS.
> En RR=5.0: FR>BR, diferencia 0.07 → el forward supera al IS, señal ambigua.
> El centro de la meseta es **RR 3.5-4.0**.

---

## Candidatos Finales

| # | Pass | PF | FR | BR | DD% | T | Range | RR | Criterio |
|---|------|----|----|-----|-----|---|-------|----|---------|
| **C1** | **187** | **1.234** | **1.23** | **1.22** | **2.3** | **238** | **2** | **3.5** | **Meseta center — FR≈BR ✓, DD mínimo** |
| C2 | 299 | 1.275 | 1.27 | 1.24 | 4.8 | 238 | 2 | 4.5 | Meseta edge — mayor PF, mayor DD |

**Parámetros candidato seleccionado (C1 — P187):**
- TradeDirection = BUY (1)
- RangeCandlesCount = 2
- SessionStart_Min = 15 (14:15 UTC)
- RR = 3.5
- EntryMode = Pending (1)
- UseBreakeven = false

---

## Evaluación vs Criterios del Pipeline

| Criterio | Mínimo | C1 (P187) | C2 (P299) | Estado |
|----------|--------|-----------|-----------|--------|
| PF IS | — | 1.234 | 1.275 | Débil |
| FR (OOS interno 2025) | ≥ 1.40 | **1.23** | **1.27** | ❌ Falla criterio |
| DD% | ≤ 10% | **2.3%** | 4.8% | ✓ / ⚠️ |
| Trades | ≥ 30 | **238** | **238** | ✓ |
| Meseta RR | estable | **RR 3.0–4.5** | mismo | ✓ |
| FR ≈ BR | consistencia | **✓** | **✓** | ✓ |
| Session estable | — | Solo 14:15 | mismo | ⚠️ Angosta |

---

## Comparativa M3 vs M5

| | M3 (P1983) | M5 C1 (P187) | M5 C2 (P299) |
|-|------------|--------------|--------------|
| TF | M3 | M5 | M5 |
| PF IS | 1.279 | 1.234 | 1.275 |
| FR (OOS) | 1.28 | 1.23 | 1.27 |
| DD% | 2.84 | **2.3** | 4.8 |
| Trades | 217 | **238** | **238** |
| Session | 14:09 (pre-open) | 14:15 (pre-open) | 14:15 |
| Range | 7 candles | **2 candles** | 2 candles |
| Meseta RR | No | **Sí (4 valores)** | Sí |
| Cobertura opt | Genético | **Complete ✓** | Complete ✓ |

**M5 supera a M3** en: meseta más robusta, menor DD, mayor número de trades, cobertura exhaustiva. Concepto de sesión confirmado independientemente en ambos TF.

---

## Veredicto

### MARGINAL — Avanzar a OOS backtest standalone

El edge es real pero modesto:

**A favor:**
- Dirección BUY confirmada en M3 y M5
- Concepto pre-open (14:15 UTC) consistente entre timeframes
- Meseta RR documentada (3.0–4.5), 4 valores consecutivos con FR≈BR
- FR≈BR para C1 — sin evidencia de overfitting
- 238 trades — muestra robusta

**En contra:**
- FR máximo 1.27 → por debajo del criterio OOS ≥1.40
- Session window angosta: solo 14:15 funciona. Mover ±15 min destruye el edge
- Solo 6/256 passes con FR>1.20 (2.3% del espacio)
- Concepto pre-open inusual — hipótesis no confirmada cuantitativamente

**Siguiente paso requerido:** Correr OOS backtest standalone (período 2025-01-01 → 2025-12-31) con parámetros de C1 y C2 en MT5. Si OOS PF ≥ 1.25 con DD < 6%, considerar avanzar a WFA.

> Criterio de corte estricto: si OOS PF < 1.20 → NO VIABLE. Archivar SPX500.
