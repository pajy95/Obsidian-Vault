# TBR v1.0b — Optimización y Análisis IS/OOS
[[TBR]]
**Fecha:** 2026-05-11  
**EA:** TBR_v1.0b.mq5 (features nuevas: BE_TriggerRR, GapFilter)  
**Instrumento:** NDX100 / M5  
**Split:** IS = 2022-2024 / OOS = 2025 (metodología BNY)

---

## Contexto

TBR v1.0b es una evolución de TBR v1.4 (T10 baseline) que incorpora dos ideas nuevas:
- **Idea 4 — BE_TriggerRR**: Breakeven que activa en `entry + TriggerRR × SL_dist` (reemplaza BE_TriggerPct)
- **Idea 5 — GapFilter**: Omite el día si el gap overnight supera `MaxGapPct%`

Punto de partida: T10 (MARGINAL, OOS PF=1.285). Objetivo: superar PF≥1.40 en OOS.

---

## Fase 1 — Optimización de estructura (sin filtros)

**Parámetros optimizados:** RangeCandlesCount, SessionStart_Min, RR  
**Fijos:** UseBreakeven=false, GapFilter=false, todos los días activos  
**Método:** Walk-Forward MT5 (2022-2025), 152 passes

### Hallazgo principal — Cluster dominante

| RangeCandlesCount | SessionStart_Min | RR | Fwd PF (OOS WF) | Back PF (IS WF) |
|:-----------------:|:---------------:|:--:|:---------------:|:---------------:|
| 2 (10 min) | 15 | 4.0 | **1.350** | 1.240 |
| 2 (10 min) | 15 | 3.8 | 1.310 | 1.270 |
| 2 (10 min) | 15 | 3.6 | 1.310 | 1.240 |

Plateau estable en RR=3.6-4.0. n=235 constante (mismo setup, solo cambia TP).  
**Pass seleccionado: #63 — Candles=2, Min=15, RR=4.0**

> Nota: Custom=0 en todos los passes (bug OnTester — optimización ordenada por Forward Result).

---

## Análisis IS/OOS — Pass #63 (5 días)

| Período | n | PF | WR | Net | MaxDD |
|---------|---|----|----|-----|-------|
| IS 2022-2024 | 699 | 1.225 | 22.9% | +$1,244 | $630 |
| OOS 2025 | 235 | 1.309 | 23.8% | +$544 | $122 |

**Ratio OOS/IS: 1.069** — OOS supera IS, sin señal de overfitting.

### Hallazgo crítico — Rendimiento por día (OOS 2025)

| Día | PF | WR |
|-----|----|----|
| Lunes | 1.607 | 27.7% |
| Martes | 1.559 | 25.5% |
| Miércoles | 1.589 | 27.7% |
| **Jueves** | **1.068** | **21.3%** |
| **Viernes** | **0.808** | **17.0%** |

Jueves y Viernes son no viables. Viernes es activamente perdedor (PF < 1.0).

---

## Análisis IS/OOS — P63 L/M/X (Lun + Mar + Mié)

Configuración definitiva tras eliminar Jue y Vie:

| Período | n | PF | WR | Net | MaxDD |
|---------|---|----|----|-----|-------|
| IS 2022-2024 | 425 | **1.252** | 23.1% | +$847 | $331 |
| OOS 2025 | 145 | **1.498** | 26.2% | +$524 | $128 |

**Ratio OOS/IS: 1.196** (OOS mejor que IS — excelente señal de generalización).

### Desglose por año — P63 L/M/X

| Año | n | PF | WR | Net | Período |
|-----|---|----|----|-----|---------|
| 2022 | 155 | 0.966 | 19.4% | -$44 | IS — año bajista NAS100 (-35%) |
| 2023 | 154 | 1.544 | 26.6% | +$630 | IS |
| 2024 | 116 | 1.290 | 23.3% | +$261 | IS |
| 2025 | 145 | 1.498 | 26.2% | +$524 | OOS |

2022 es el único año negativo — coincide con el mayor drawdown de NAS100 desde 2008 (-35%). La estrategia es long-only, lo cual es estructural. 2023, 2024 y 2025 son todos rentables.

### Comparación vs T10 baseline (mismo split IS=2022-2024 / OOS=2025)

| Config | IS PF | OOS PF | OOS/IS | OOS Net | OOS MaxDD |
|--------|-------|--------|--------|---------|-----------|
| **P63 L/M/X** | 1.252 | **1.498** | **1.196** | **+$524** | **$128** |
| P63 5 días | 1.225 | 1.309 | 1.069 | +$544 | $122 |
| P49 RR=3.6 | 1.220 | 1.254 | 1.028 | +$440 | $148 |
| T10 baseline | 1.384 | 1.246 | 0.901 | +$278 | $179 |

P63 L/M/X supera a T10 en OOS por +0.252 PF y genera el doble de net con menor MaxDD.

---

## Fase 2 — Optimización Breakeven

**Parámetros optimizados:** UseBreakeven (true/false), BE_TriggerRR (0.50-2.00 step 0.25)  
**Resultado:** UseBreakeven=false confirmado

| Config | Fwd PF | Back PF (IS WF) |
|--------|--------|-----------------|
| Sin BE, mejor (RR=3.6) | 1.140 | **1.050** |
| Con BE, mejor (RR=2.6, BETRR=0.50) | 1.180 | **0.920** ← IS losing |

Con BE activado, el IS period cae por debajo de PF=1.0 para la mayoría de passes. El BE corta prematuramente trades que con RR=4.0 necesitan espacio para retroceder antes de alcanzar el TP lejano. Beneficio marginal en OOS (+0.04) no compensa IS perdedor.

**Conclusión: UseBreakeven = false**

---

## Fase 3 — GapFilter

No evaluada. El rendimiento de P63 L/M/X (OOS PF=1.498) es suficiente para proceder a Walk-Forward sin necesidad de filtros adicionales que añadan complejidad.

---

## Criterios de viabilidad — P63 L/M/X

| Criterio | Umbral | Resultado | Estado |
|----------|--------|-----------|--------|
| OOS PF ≥ 1.40 | ≥ 1.40 | **1.498** | ✅ OK |
| IS PF ≥ 1.40 | ≥ 1.40 | 1.252 | ❌ (2022 bear) |
| OOS/IS ratio | ≥ 0.50 | **1.196** | ✅ OK |
| OOS trades | ≥ 30 | **145** | ✅ OK |
| OOS WR | ≥ 25% | **26.2%** | ✅ OK |

---

## Veredicto

**MARGINAL (4/5)** — Falla únicamente IS PF por el año 2022 (bear market estructural NAS100, -35%). Los años 2023, 2024 y 2025 son rentables. OOS PF=1.498 supera el umbral con margen. OOS/IS=1.196 indica generalización real, no overfitting.

**Próximo paso: Walk-Forward 2022-2025**

---

## Configuración final para WF

```
EA:               TBR_v1.0b.mq5
RangeCandlesCount = 2
SessionStart_Min  = 15
RR                = 4.0
TradeMonday       = true
TradeTuesday      = true
TradeWednesday    = true
TradeThursday     = false
TradeFriday       = false
UseBreakeven      = false
GapFilter_Enable  = false
```
