# TBR SPX500 M3 — Análisis IS Optimización
**Fecha:** 2026-05-17
**EA:** TBR v1.1
**Símbolo:** SPX500, M3
**Período total:** 2022-01-01 → 2025-12-30
**Broker/Cuenta:** FundingPips2-SIM | Depósito $5,000 | Apalancamiento 25x
**MagicNumber reservado:** 202505
**Archivo fuente:** `Optimizacion/SPX500/OP_TBR_SPX500_M3_v1.1.xml`

---

## Configuración de la Optimización

| Parámetro | Rango testeado |
|-----------|----------------|
| TradeDirection | BUY (1) / BOTH (0) |
| RangeCandlesCount | 1 – 7 |
| SessionStart_Min | 6 – 57 (paso 3, mins desde 14:00 UTC) |
| RR | 2.0 – 5.0 (paso 0.5) |
| EntryMode | Pending (fijo) |
| Filtros v1.1 | OFF (optimización base) |

**Algoritmo:** Genético (256 passes de ~1,666 combinaciones posibles)

> **Nota:** El modo Forward de MT5 estaba activo.
> - **BR (Back Result)** = IS period (período de optimización)
> - **FR (Forward Result)** = Forward period (OOS interno de MT5)

---

## Hallazgos Globales

| Métrica | Valor |
|---------|-------|
| Total passes | 256 |
| FR promedio (OOS interno) | **1.005** — esencialmente breakeven |
| BR promedio (IS) | 1.281 |
| Passes con FR > 1.20 | 8 / 256 (3.1%) |
| Passes viables (PF>1.20, DD<8%, T≥30) | 9 |
| PF máximo alcanzado | **1.279** |
| Dirección dominante | **BUY** — avg PF 1.026 vs BOTH 0.917 |

### Distribución PF

| Rango | Count |
|-------|-------|
| < 0.8 | 6 |
| 0.8 – 0.9 | 27 |
| 0.9 – 1.0 | 93 |
| 1.0 – 1.1 | 88 |
| 1.1 – 1.2 | 33 |
| 1.2 – 1.3 | **9** |
| ≥ 1.3 | 0 |

---

## Análisis de Meseta

### Dirección
BUY domina con consistencia. BOTH = destruye el edge (avg PF 0.917). SELL no fue testeado.

**Conclusión: TradeDirection = BUY (1) — fijo.**

### Session Start (minutes from 14:00 UTC)

| Session UTC | Avg PF | Max PF | PF>1.20 | Obs |
|-------------|--------|--------|---------|-----|
| 14:09 | **1.189** | **1.279** | 3 | Mejor zona — poco muestreado por genético |
| 14:12 | 1.221 | 1.221 | — | 1 pass solamente |
| 14:18 | 1.174 | 1.213 | 2 | Zona secundaria |
| 14:30 | 1.074 | 1.078 | 0 | NY open — pobre |
| 14:45 | 1.042 | 1.221 | — | Pico aislado, avg bajo |
| 14:48+ | < 1.02 | < 1.20 | 0 | Zona muerta |

**Hallazgo clave:** El edge está en la ventana **PRE-open** (14:09-14:18 UTC), **no** en el NY open (14:30). El rango se forma antes de la apertura y el breakout se ejecuta en los primeros minutos post-open.

### RR (BUY passes)

| RR | Avg PF | Max PF | PF>1.20 |
|----|--------|--------|---------|
| 2.0 | 1.039 | 1.135 | 0 |
| 2.5 | 1.043 | 1.181 | 0 |
| 3.0 | 1.039 | 1.178 | 0 |
| 3.5 | 1.009 | 1.132 | 0 |
| 4.0 | 1.013 | 1.178 | 0 |
| 4.5 | 1.022 | 1.221 | 3 |
| 5.0 | **1.028** | **1.279** | 5 |

**Sin meseta.** El edge solo emerge en RR ≥ 4.5. No hay zona plana estable.

### RangeCandlesCount (BUY passes)

| Range | Avg PF | Max PF | Obs |
|-------|--------|--------|-----|
| 1 | 1.092 | 1.203 | |
| 2 | 1.122 | 1.221 | |
| 3 | 1.060 | 1.213 | |
| 4 | 1.027 | 1.169 | |
| 5 | 1.005 | 1.221 | |
| 6 | 0.993 | 1.228 | |
| 7 | 1.010 | **1.279** | |

**Sin meseta clara.** Max PF disperso. Avg PF decrece con candles mayores.

---

## Candidato Identificado

**Zona de interés:** Session=14:09, BUY, Range 6-7, RR 4.5-5.0

| Pass | FR | BR | PF | DD% | Trades | Range | RR |
|------|----|----|-----|-----|--------|-------|----|
| **1983** | 1.28 | 1.26 | 1.279 | 2.84 | 217 | 7 | 5.0 |
| 1981 | 1.23 | 1.26 | 1.228 | 2.91 | 228 | 6 | 5.0 |
| 1663 | 1.21 | 1.24 | 1.212 | 2.97 | 217 | 7 | 4.5 |
| — | 1.18 | 1.25 | 1.176 | 2.93 | 228 | 6 | 4.5 |
| — | 1.17 | 1.23 | 1.171 | 3.37 | 237 | 5 | 4.5 |

**Parámetros candidato (Pass 1983):**
- TradeDirection = BUY (1)
- RangeCandlesCount = 7
- SessionStart_Min = 9 (14:09 UTC)
- RR = 5.0
- EntryMode = Pending (1)

---

## Evaluación vs Criterios del Pipeline

| Criterio | Mínimo | SPX500 IS | Estado |
|----------|--------|-----------|--------|
| PF IS | — | 1.279 | Débil |
| PF Forward (OOS interno) | ≥ 1.40 | **1.28** | ❌ FALLA |
| DD% | ≤ 10% | 2.84% | ✓ |
| Trades | ≥ 30 | 217 | ✓ |
| Meseta RR | estable | Solo ≥4.5 | ❌ Frágil |
| Meseta Session | estable | Solo 14:09 ±9min | ❌ Muy angosta |
| FR avg (OOS) | > 1.0 | 1.005 | ⚠️ Breakeven global |

---

## Veredicto

### MARGINAL — Requiere confirmación antes de avanzar a OOS

El edge existe pero es **débil y frágil**:
- PF máximo IS = 1.279, sin margen suficiente para absorber degradación OOS
- Forward result (OOS interno) = 1.28 para el mejor pass — aún por debajo del criterio ≥1.40
- Sólo 8/256 passes con FR > 1.20 (3.1%)
- La sesión óptima (14:09 UTC) es pre-open, concepto no-standard para TBR, y fue poco muestreado por el algoritmo genético
- Sin meseta robusta en RR ni Range

### Alternativas disponibles

**Opción A — Re-optimización dirigida (RECOMENDADA si se quiere continuar):**
Correr Complete Algorithm (no genético) con:
- SessionStart_Min: 6 → 18, paso 3 (5 valores)
- RangeCandlesCount: 5 → 8, paso 1 (4 valores)
- RR: 4.0 → 5.5, paso 0.5 (4 valores)
- EntryMode: BUY (fijo)
- Total: 80 combinaciones — exhaustivo en minutos

Si esta re-run confirma la meseta, avanzar a OOS.

**Opción B — ARCHIVAR:**
SPX500 ya está cubierto por NAS100 en el portfolio TBR (correlación alta, mismo edge US equity). No agrega diversificación real. Destinar recursos a otros instrumentos.

---

## Próximo paso

Pendiente decisión del trader: ¿Opción A (re-optimizar) o Opción B (archivar)?
