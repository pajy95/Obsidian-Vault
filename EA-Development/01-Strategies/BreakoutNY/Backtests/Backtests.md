# Backtests — BreakoutNY

[[Strategy - BreakoutNY]]

Resultados IS/OOS de todos los activos del portfolio BreakoutNY. Última actualización: **2026-04-29**.

```
Backtests/
├── NAS100/     ← IS_NAS100_MonTueFri_v1.xlsx | OOS_NAS100_MonTueFri_v1.xlsx | Backtest NAS100 01_01_2025 - 28_04_2026.xlsx
├── DJI30/      ← IS_DJI30_TueThuFri_v1.xlsx  | OOS_DJI30_TueThuFri_v1.xlsx  | Backtest dji30 01_01_2025 - 28_04_2026.xlsx
├── XAUUSD/     ← IS/OOS v1 y v2 (ThuOnly, ThuFri, Set E, Set G, Set E+LXJ)
├── SP500/      ← IS/OOS v1, v2, v2 Abril — DESCARTADO
└── GER40/      ← Pendiente backtesting 2026-04-30
```

---

## Resumen IS/OOS por activo

### Período de validación
- **IS:** 2021-01-01 → 2024-12-31
- **OOS:** 2025-01-01 → 2026-04-28
- **Re-auditoría OOS reciente:** 2025-01-01 → 2026-04-28 (16 meses)

---

### NAS100 — v1 Mon+Tue+Fri ✅ VIABLE

| Período | PF | DD eq | Trades | Retención |
|---------|-----|-------|--------|-----------|
| IS 2021-2024 | 1.580 | 2.57% | 294 | — |
| OOS 2025 | 2.154 | 1.42% | 82 | 136.3% |
| Re-val 2025-2026 | 1.794 | 1.80% | 86 | — |

- Días activos: Lunes + Martes + Viernes
- BE=82 | MinSL=35 | MaxSL=120 | ATR mult 0.5–2.0
- Solo LONGS — shorts degradan el rendimiento estructuralmente
- RiskAmountUSD=$13 (cuenta $5K)
- **Edge Decay OOS:** PF H1=2.581 → PF H2=1.228 (-52.4%) — señal de normalización, no de pérdida de edge
- Racha perdedora máxima OOS: 6 consecutivos / -$78.68

---

### DJI30 — v1 Tue+Thu+Fri 🟡 MARGINAL

| Período | PF | DD eq | Trades | Retención |
|---------|-----|-------|--------|-----------|
| IS 2021-2024 | 1.486 | 1.63% | 150 | — |
| OOS 2025 | 3.040 | 0.53% | 49 | 204.5% |
| Re-val 2025-2026 | 1.475 | 2.09% | 35 | — |

- Días activos: Martes + Jueves + Viernes
- BE=20 | MinSL=6000 | MaxSL=30000 | ATR mult 0.3–2.0
- RiskAmountUSD=$12 (cuenta $5K)
- OOS 2025 (3.04) era outlier — OOS 2025-2026 (1.475) se alinea con IS histórico (1.486) ✅
- **Edge Decay OOS:** PF H1=1.336 → PF H2=1.738 (+30.1%) — edge mejorando en período reciente
- Racha perdedora máxima OOS: 3 consecutivos / -$51.98
- Mantener en $5K operativa, no incorporar al challenge $25K hasta más datos 2026

---

### XAUUSD — Set E (solo Jueves) ✅ VIABLE

| Período | PF | DD eq | Trades | Retención |
|---------|-----|-------|--------|-----------|
| IS 2021-2024 | 2.002 | 0.93% | 63 | — |
| OOS 2025 | 2.536 | 0.48% | 35 | 126.7% |
| Re-val 2025-2026 (Set E) | 3.618 | 0.85% | 27 | 180.7% |

Sets evaluados en re-auditoría 2026-04-29:

| Set | Días | PF OOS | DD eq | Trades | Veredicto |
|-----|------|--------|-------|--------|-----------|
| Set E | solo Jue | 3.618 | 0.85% | 27 | ✅ PRODUCCIÓN |
| Set G | solo Jue | 3.035 | 0.95% | 33 | 🔬 Demo paralelo |
| Set E+LXJ | L+X+J | 1.791 | 2.12% | 177 | ❌ Diluye edge |

- BE=70 | MinSL=4.5 | MaxSL=13.0 | EntryMaxCandle=0 | solo Jueves
- RiskAmountUSD=$16 (cuenta $5K)
- **Edge Decay OOS:** PF H1=6.047 → PF H2=2.338 (-61.3%) — normalización desde PF extremo inicial
- Racha perdedora máxima OOS: 2 consecutivos / -$22.27
- Referencia: `Analysis/XAUUSD_set_analysis_2026-04-29.md`

---

### SP500 — v2 Mon+Tue+Wed ❌ NO VIABLE — DESCARTADO

| Versión | IS PF | OOS PF | Retención | Veredicto |
|---------|-------|--------|-----------|-----------|
| v1 L+M+X+V | 1.481 | 0.991 | 66.9% | ❌ |
| v2 L+M+X | 1.724 | 1.374 | 79.7% | ❌ |
| v2 Abril (2021-2026) | 1.481 | 0.889 | 60.0% | ❌ |

- OOS destruye capital en todas las versiones
- Retención con tendencia negativa: 66.9% → 79.7% → 60.0%
- Consistente con análisis previo (chat 088): IS plateau honesto PF=1.24-1.30
- **Decisión:** Excluido del challenge $25K permanentemente
- Referencia: `Analysis/SP500_verdict_2026-04-29.md`

---

### GER40 — ❌ DESCARTADO (2026-04-30)

| Período | PF | DD eq | Trades | Retención |
|---------|-----|-------|--------|-----------|
| IS 2021-2024 | 1.901 | 0.80% | 72 | — |
| OOS 2025-2026 | 1.986 | 0.84% | 34 | 104.5% |

- Días activos: L+M+V | BE=70 | MinSL=2700 | MaxSL=5321 | Solo LONGS
- Métricas IS/OOS superan todos los criterios de viabilidad
- **Razón de descarte: calidad de historial = 18%** — insuficiente para tomar decisiones de capital real
- El broker FundingPips no provee ticks reales de calidad para GER40
- Decisión: no operar con datos no confiables independientemente del resultado numérico

---

## Portfolio combinado OOS 2025-2026

| Métrica | Valor |
|---------|-------|
| Trades totales | 148 (86 NAS + 35 DJI + 27 XAU) |
| Trades/mes | 9.2 |
| Net Profit | $813.89 |
| Expectancy | $4.34/trade |
| Profit Factor | 1.931 |
| Win Rate | 46.6% |
| Avg win / Avg loss | $24.46 / -$13.24 |

**Contribución al profit:**
- NAS100: 57% del profit (motor principal)
- XAUUSD: 31% (calidad — mayor expectancy/trade: $9.46)
- DJI30: 11% (diversificación)

---

## Objetivo de expansión — 2 activos adicionales

Decisión 2026-04-29: incorporar al menos **2 activos más** para recortar el tiempo del challenge de 15 meses a ~8-10 meses sin sacrificar calidad de edge.

**Pipeline de evaluación:**
1. **GER40** — backtesting 2026-04-30 (prioridad alta)
2. **Segundo candidato TBD** — evaluar tras GER40

Criterio: PF IS ≥ 1.5 | Retención OOS ≥ 75% | DD ≤ 5% | mínimo 4 trades/mes

