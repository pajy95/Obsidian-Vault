# Sets-Produccion — BreakoutNY

[[Strategy - BreakoutNY]]

Parámetros de producción validados para cada activo del portfolio BreakoutNY. Última actualización: **2026-04-29**.

```
Sets-Produccion/
├── NAS100/   → NAS100_MonTueFri_v1.md
├── DJI30/    → DJI30_TueThuFri_v1.md
├── XAUUSD/   → XAUUSD_ThuOnly_v2.md  (Set E definitivo)
├── SP500/    → SP500_MonTueWed_v2.md  ← DESCARTADO
└── GER40/    → pendiente backtesting 2026-04-30
```

---

## Estado del portfolio — 2026-04-29

| Activo | Set | Días | Risk/trade | Status | OOS PF | Cuenta |
|--------|-----|------|-----------|--------|--------|--------|
| NAS100 | v1 Mon+Tue+Fri | L+M+V | $13 | ✅ Producción | 1.794 | $5K |
| DJI30 | v1 Tue+Thu+Fri | M+J+V | $12 | 🟡 Marginal ($5K) | 1.475 | $5K |
| XAUUSD | Set E Thu Only | solo Jue | $16 | ✅ Producción | 3.618 | $5K |
| SP500 | v2 Mon+Tue+Wed | L+M+X | — | ❌ Descartado | 0.889 | — |
| GER40 | TBD | TBD | TBD | 🔬 Backtesting | — | — |

**Parámetros comunes:** ServerOffsetHours=2 | EntryWindowEnd_Min=15 | ConfirmOnClose=true | EnablePartials=false

---

## NAS100 — v1 Mon+Tue+Fri

- **EA:** BreakoutNY Universal FP / BreakoutNY_NAS100_FP
- **MagicNumber:** 202401
- **RiskAmountUSD:** $13 (cuenta $5K) | $65 (challenge $25K)

| Parámetro | Valor |
|-----------|-------|
| BE_BufferPct | 82 |
| MinSL_Points | 35 |
| MaxSL_Points | 120 |
| FilterMonday | true |
| FilterTuesday | true |
| FilterWednesday | false |
| FilterThursday | false |
| FilterFriday | true |
| ATR_FilterEnable | true |
| ATR_MaxMultiplier | 2.0 |
| ATR_MinMultiplier | 0.5 |
| EnablePartials | false |

**⚠️ CRÍTICO:** Solo LONGS. FilterShorts=true obligatorio. Shorts degradan el rendimiento estructuralmente.

**Métricas OOS 2025-2026:** PF=1.794 | DD=1.80% | Trades=86 | WR=48.8%

---

## DJI30 — v1 Tue+Thu+Fri

- **EA:** BreakoutNY Universal FP / BreakoutNY_v1_DJI30_FP
- **MagicNumber:** 202402
- **RiskAmountUSD:** $12 (cuenta $5K) | $60 (challenge $25K)

| Parámetro | Valor |
|-----------|-------|
| BE_BufferPct | 20 |
| MinSL_Points | 6000 |
| MaxSL_Points | 30000 |
| FilterMonday | false |
| FilterTuesday | true |
| FilterWednesday | false |
| FilterThursday | true |
| FilterFriday | true |
| ATR_FilterEnable | true |
| ATR_MaxMultiplier | 2.0 |
| ATR_MinMultiplier | 0.3 |
| EnablePartials | false |

**Nota:** PF OOS 2025 (3.04) era outlier. PF real reciente (1.475) alineado con IS histórico (1.486). Mantener en $5K operativa. No incorporar al challenge hasta más datos 2026.

**Métricas OOS 2025-2026:** PF=1.475 | DD=2.09% | Trades=35 | WR=28.6%

---

## XAUUSD — Set E (solo Jueves) — DEFINITIVO

- **EA:** Breakout NY XAU V9 FP / BreakoutNY Universal FP
- **MagicNumber:** 202409
- **RiskAmountUSD:** $16 (cuenta $5K) | $80 (challenge $25K)

| Parámetro | Valor |
|-----------|-------|
| BE_BufferPct | 70 |
| MinSL_Points | 4.5 |
| MaxSL_Points | 13.0 |
| EntryMaxCandle | 0 |
| FilterMonday | false |
| FilterTuesday | false |
| FilterWednesday | false |
| FilterThursday | true |
| FilterFriday | false |
| ConfirmOnClose | true |
| EnablePartials | false |

**Justificación Set E vs alternativas:**

| Set | PF IS | PF OOS | DD OOS | Trades | Veredicto |
|-----|-------|--------|--------|--------|-----------|
| Set E (solo Jue) | 2.002 | 3.618 | 0.85% | 27 | ✅ PRODUCCIÓN |
| Set G (solo Jue, MaxSL=16.5) | — | 3.035 | 0.95% | 33 | 🔬 Demo |
| Set E+LXJ (L+X+J) | 1.744 | 1.791 | 2.12% | 177 | ❌ Diluye edge |

**Métricas OOS 2025-2026:** PF=3.618 | DD=0.85% | Trades=27 | WR=63.0% | Retención=180.7%

Referencia completa: `Analysis/XAUUSD_set_analysis_2026-04-29.md`

---

## SP500 — DESCARTADO ❌

- **Motivo:** OOS destruye capital en todas las versiones evaluadas
- **Mejor resultado OOS:** PF=1.374 (v2, retención 79.7%) — ya por debajo del mínimo
- **Resultado más reciente (Abril 2026):** PF=0.889, Net=-$19.66, retención 60.0%
- **Decisión:** Excluido permanentemente del portfolio BreakoutNY
- Referencia: `Analysis/SP500_verdict_2026-04-29.md`

---

## GER40 — Pendiente 🔬

- Backtesting inicia: 2026-04-30
- Dejar archivos en: `Backtests/GER40/`
- IS: 2021-01-01 → 2024-12-31 | OOS: 2025-01-01 → hoy
- Baseline de días: L+M+V (igual que NAS100)
- Confirmar símbolo exacto en FundingPips (GER40 / DE40 / DAX40)
- Criterios mínimos: PF IS ≥ 1.5 | Retención ≥ 75% | DD ≤ 5% | ≥ 4 trades/mes
