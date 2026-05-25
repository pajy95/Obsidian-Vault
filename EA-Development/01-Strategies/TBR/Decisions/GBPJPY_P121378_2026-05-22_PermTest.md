---
tags: [decision, TBR, GBPJPY, permutation-test, viable]
fecha: 2026-05-22
estrategia: TBR v1.1
instrumento: GBPJPY
pass: P121378
step: Permutation Test (Paso 5 pipeline)
veredicto: AVANZA — edge confirmado IS y OOS
---

# GBPJPY P121378 — Permutation Test

## Veredicto: PIPELINE AVANZA ✅

Edge estadísticamente confirmado en IS y OOS. No es aleatoriedad.

## Resultados (10,000 permutaciones, seed=42)

| Periodo | Trades | Net real | PF | p-value | z-score | Veredicto |
|---------|--------|----------|----|---------|---------|-----------|
| IS (2022–2024) | 506 | $633.20 | 1.441 | **0.0011** | **3.046** | EDGE SOLIDO |
| OOS (2025) | 167 | $304.31 | 1.609 | **0.0087** | **2.314** | EDGE SIGNIFICATIVO |

## Interpretación

**IS — EDGE SOLIDO (p<0.01, z>2.58)**
Probabilidad de obtener este resultado por azar: 0.11%. El edge en el período de entrenamiento
es estadísticamente robusto a nivel de confianza del 99%.

**OOS — EDGE SIGNIFICATIVO (p<0.05, z>1.96)**
Probabilidad de obtener este resultado por azar: 0.87%. El edge se mantiene fuera de muestra
con confianza del 99.1%. z=2.314 no alcanza el umbral SOLIDO (2.58) — muestra OOS más pequeña
(167 trades vs 506 IS) reduce el poder estadístico, lo cual es esperado y aceptable.

## Criterios del pipeline

| Criterio | IS | OOS | Estado |
|---------|----|-----|--------|
| p < 0.05 | 0.0011 ✅ | 0.0087 ✅ | CUMPLE |
| z > 1.96 | 3.046 ✅ | 2.314 ✅ | CUMPLE |
| Pasa en ambos periodos | — | — | ✅ |

## Pipeline — estado actualizado

- [x] Optimización IS
- [x] IS Backtest — PF 1.441
- [x] OOS Backtest — PF 1.609
- [x] Días de semana — 5/5 OK
- [x] **Permutation Test — IS p=0.0011 z=3.046 / OOS p=0.0087 z=2.314** ✅
- [ ] **WFA 2026** ← siguiente
- [ ] Stress test costos
- [ ] Robustez paramétrica
- [ ] Monte Carlo

## Script utilizado

`scripts/tbr_permutation_test.py` — acepta cualquier xlsx de MT5
