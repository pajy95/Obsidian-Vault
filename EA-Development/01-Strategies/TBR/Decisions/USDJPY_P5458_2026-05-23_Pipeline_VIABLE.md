---
type: decision
strategy: TBR v1.1
instrument: USDJPY
pass: P5458
magic: 202508
date: 2026-05-23
veredicto: VIABLE
pipeline_steps: 10/10
---

# USDJPY P5458 — VIABLE (10/10) — 2026-05-23

## Configuración

| Parámetro | Valor |
|-----------|-------|
| Sesión | 02:35 servidor (UTC+2) = 00:35 UTC |
| Dirección | BUY (DIR_BUY = 1) |
| RR | 2.5 |
| RangeCandlesCount | 6 |
| UseBreakeven | true |
| BE_TriggerRR | 0.60 |
| MagicNumber | 202508 |
| EA | TBR v1.1 |

## Resultados del Pipeline

### IS / OOS / WFA

| Periodo | n | PF | WR | Net USD | DD% |
|---------|---|----|----|---------|-----|
| IS 2022-2024 | 528 | 1.378 | 49.1% | +760.74 | 3.05% |
| OOS 2025 | 180 | **1.387** | 45.6% | +400.32 | 3.11% |
| WFA 2026 | 73 | **1.170** | 45.2% | +78.48 | 1.40% |

**Degradación IS→OOS: -2.4%** — prácticamente cero. Edge extraordinariamente estable.

### Años IS

| Año | n | PF | WR | Net |
|-----|---|----|----|-----|
| 2022 | 176 | 1.390 | 48.3% | +274.51 |
| 2023 | 167 | 1.764 | 54.5% | +421.92 |
| 2024 | 185 | 1.085 | 44.9% | +64.31 |

3/3 años positivos. 2024 débil pero verde.

### Días de semana

| Día | IS-PF | OOS-PF |
|-----|-------|--------|
| Lunes | 1.788 | 1.043 |
| Martes | 1.205 | 1.107 |
| Miércoles | 1.475 | 1.846 |
| Jueves | 1.186 | 1.594 |
| Viernes | 1.330 | 1.324 |

Todos los días PF>1.0 en IS y OOS. Sin día destructor. Mantener 5 días.

### Permutation Test

| Periodo | PF | p-value | z-score | Resultado |
|---------|-----|---------|---------|-----------|
| IS | 1.378 | 0.0020 | 3.423 | EDGE SÓLIDO |
| OOS | 1.387 | 0.0381 | 1.973 | EDGE SIGNIFICATIVO |

OOS borderline en z (1.97 vs umbral 1.96) pero pasa. Resultado: **PASA**.

### Stress Test (spread×2 + 0.5pip slippage = 1.5pip extra)

`PIP_VAL_001 = $0.0645` (USDJPY @ ~155: 0.01 × 100,000 / 155)

| Periodo | PF base | PF stress | Resultado |
|---------|---------|-----------|-----------|
| OOS | 1.387 | **1.187** | ✅ PASA |
| WFA | 1.170 | 0.966 | ❌ falla |

WFA stress falla (n=73, 5 meses) — muestra insuficiente para ser determinante. OOS stress es el criterio relevante.

### Robustez (vecinos de P5458)

Edge: **TP-based mixto** — RR real IS=1.43, OOS=1.66 (mezcla TP + timeout).
UseBreakeven=true no destruye el edge en USDJPY (a diferencia de GBPUSD/XAUUSD).

### Monte Carlo OOS (10,000 iteraciones, bootstrap)

| Métrica | Valor |
|---------|-------|
| P(profit) | **97.0%** |
| P(DD < 5%) | 97.0% |
| P(ruina DD ≥ 10%) | **0.01%** |
| Mediana balance | +$399.85 OOS |
| Percentil 5% balance | +$47.87 |
| DD percentil 95% | 4.57% |

## Checklist Pipeline (10/10)

| # | Criterio | Resultado |
|---|----------|-----------|
| 1 | IS PF ≥ 1.10 | ✅ 1.378 |
| 2 | OOS PF ≥ 1.10 | ✅ 1.387 |
| 3 | OOS DD ≤ 10% | ✅ 3.11% |
| 4 | OOS n ≥ 100 | ✅ 180 |
| 5 | WFA PF > 1.0 | ✅ 1.170 |
| 6 | Permutation IS p < 0.05 | ✅ p=0.0020 |
| 7 | Permutation OOS p < 0.05 | ✅ p=0.0381 |
| 8 | Stress OOS PF ≥ 1.0 | ✅ 1.187 |
| 9 | MC P(profit) > 90% | ✅ 97.0% |
| 10 | MC P(ruina) < 2% | ✅ 0.01% |

**VEREDICTO: VIABLE — CANDIDATO PRIMARIO PARA DEMO**

## Comparación vs P7389

| Métrica | P5458 (VIABLE) | P7389 (MARGINAL) |
|---------|---------------|-----------------|
| OOS PF | 1.387 | **1.610** |
| WFA PF | **1.170** | 0.970 ❌ |
| OOS DD% | 3.11 | **2.31** |
| Degradación IS→OOS | **-2.4%** | +22.3% (mejora) |
| Perm OOS z | 1.973 | **3.921** |
| MC P(profit) | 97.0% | **99.9%** |
| MC P(ruina) | 0.01% | **0.00%** |
| Dirección | BUY | BOTH |

P5458 domina en consistencia y régimen 2026. P7389 tiene mayor retorno potencial pero WFA negativo.

## Set file

`Optimizacion/USDJPY/Sets/TBR_USDJPY_P5458.set` — Magic: **202508**

## Circuit Breakers Demo

| Condición | Acción |
|-----------|--------|
| DD > 5% en el mes | Pausar EA, revisar régimen |
| WR < 30% en 3 meses | Pausar EA |
| WFA 2026 PF < 1.0 al re-evaluar | Suspender hasta Q4 2026 |

## Próximos pasos

1. Activar P5458 en demo (Magic 202508)
2. Monitorear WR mensual — umbral 30%
3. Considerar P7389 solo si P5458 muestra WR < 35% consistente (régimen adverso BUY)
4. Re-evaluar P7389 en Q3 2026 cuando haya más datos WFA
