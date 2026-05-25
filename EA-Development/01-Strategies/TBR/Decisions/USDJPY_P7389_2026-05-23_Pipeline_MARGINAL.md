---
type: decision
strategy: TBR v1.1
instrument: USDJPY
pass: P7389
magic: 202507
date: 2026-05-23
veredicto: MARGINAL
pipeline_steps: 9/10
---

# USDJPY P7389 — MARGINAL (9/10) — 2026-05-23

## Configuración

| Parámetro | Valor |
|-----------|-------|
| Sesión | 03:50 servidor (UTC+2) = 01:50 UTC |
| Dirección | BOTH (DIR_BOTH = 0) |
| RR | 3.0 |
| RangeCandlesCount | 6 |
| UseBreakeven | true |
| BE_TriggerRR | 0.60 |
| MagicNumber | 202507 |
| EA | TBR v1.1 |

## Resultados del Pipeline

### IS / OOS / WFA

| Periodo | n | PF | WR | Net USD | DD% |
|---------|---|----|----|---------|-----|
| IS 2022-2024 | 775 | 1.316 | 43.1% | +1,189.05 | 4.20% |
| OOS 2025 | 257 | **1.610** | 46.7% | +980.29 | 2.31% |
| WFA 2026 | 91 | **0.970** | 35.2% | -19.64 | 3.68% |

OOS es el mejor periodo — mejora sobre IS. WFA 2026 apenas negativo ($-19.64 en 91 trades).

### Años IS

| Año | n | PF | WR | Net |
|-----|---|----|----|-----|
| 2022 | 258 | 1.116 | 39.1% | +166.58 |
| 2023 | 258 | 1.600 | 47.7% | +697.12 |
| 2024 | 259 | 1.280 | 42.5% | +325.35 |

3/3 años positivos.

### Días de semana

| Día | IS-PF | OOS-PF |
|-----|-------|--------|
| Lunes | 1.461 | 1.096 |
| Martes | 1.221 | 1.922 |
| Miércoles | 1.578 | 2.315 |
| Jueves | 1.247 | 1.296 |
| Viernes | 1.121 | 1.690 |

Todos los días PF>1.0 en IS y OOS.

### Permutation Test

| Periodo | PF | p-value | z-score | Resultado |
|---------|-----|---------|---------|-----------|
| IS | 1.316 | 0.0007 | 3.590 | EDGE SÓLIDO |
| OOS | 1.610 | 0.0010 | 3.921 | EDGE SÓLIDO |

Edge estadístico muy sólido — z>3.5 en ambos periodos.

### Stress Test

| Periodo | PF base | PF stress | Resultado |
|---------|---------|-----------|-----------|
| OOS | 1.610 | **1.361** | ✅ PASA |
| WFA | 0.970 | 0.783 | ❌ falla |

### Monte Carlo OOS (10,000 iteraciones)

| Métrica | Valor |
|---------|-------|
| P(profit) | **99.9%** |
| P(DD < 5%) | 97.9% |
| P(ruina DD ≥ 10%) | **0.00%** |
| DD percentil 95% | 4.39% |

MC excelente — mejor que P5458.

## Checklist Pipeline (9/10)

| # | Criterio | Resultado |
|---|----------|-----------|
| 1 | IS PF ≥ 1.10 | ✅ 1.316 |
| 2 | OOS PF ≥ 1.10 | ✅ 1.610 |
| 3 | OOS DD ≤ 10% | ✅ 2.31% |
| 4 | OOS n ≥ 100 | ✅ 257 |
| 5 | WFA PF > 1.0 | ❌ **0.970** |
| 6 | Permutation IS p < 0.05 | ✅ p=0.0007 |
| 7 | Permutation OOS p < 0.05 | ✅ p=0.0010 |
| 8 | Stress OOS PF ≥ 1.0 | ✅ 1.361 |
| 9 | MC P(profit) > 90% | ✅ 99.9% |
| 10 | MC P(ruina) < 2% | ✅ 0.00% |

**VEREDICTO: MARGINAL — No avanza a demo todavía**

## Diagnóstico del WFA negativo

WFA 2026: WR=35.2% (vs OOS 46.7%) — caída de 11.5 puntos en win rate.

**Hipótesis más probable:** la dirección SHORT está perdiendo en 2026. P7389 opera BOTH (long+short). El régimen USDJPY 2026 puede ser adverso para shorts en sesión Tokyo (0:00-02:00 UTC): JPY carry-trade sigue activo, sesgo estructural LONG en USDJPY es más fuerte.

Sin separación Long/Short del WFA, no se puede confirmar. El test correcto sería comparar P7389 BUY-only vs P5458 BUY-only en WFA.

**Contexto:** WFA $-19.64 en 91 trades es una pérdida casi cero — podría ser ruido estadístico del período (5 meses). P5458 en el mismo periodo: WFA PF=1.170, n=73 trades.

## Estado: En espera

- Mantener magic 202507 reservado
- No activar en demo hasta que WFA 2026 acumule más datos (re-evaluar Q3 2026)
- Si P5458 muestra señales de fallo en demo: re-evaluar P7389 con datos adicionales de 2026
- Alternativa futura: backtest BUY-only con los parámetros de P7389 (Hr=03:50, RR=3.0, Range=6)
