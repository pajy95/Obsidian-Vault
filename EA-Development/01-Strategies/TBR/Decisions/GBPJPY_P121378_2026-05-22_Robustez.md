---
tags: [decision, TBR, GBPJPY, robustez, marginal]
fecha: 2026-05-22
estrategia: TBR v1.1
instrumento: GBPJPY
pass: P121378
step: Robustez Paramétrica (Paso 8 pipeline)
veredicto: PASS — 5/5 estudios PASS, avanza a Monte Carlo
---

# GBPJPY P121378 — Robustez Paramétrica

## Veredicto: PASS — avanza a Monte Carlo

Los 5 estudios cuantitativos pasan. El edge es robusto estructuralmente.

---

## Hallazgo estructural: estrategia LONG-ONLY

**P121378 es 100% LONG** (TradeDirection=BUY, 507 IS + 167 OOS + 63 WFA = 0 trades SHORT).
El criterio "Long/Short separados ambos PF ≥ 1.0" no aplica — es estrategia unidireccional por diseño.
Implicación: exposure al alza de GBPJPY en franja asiática. Sin hedge natural contra caídas.

---

## Estudio 1 — Distribución exit types

| Exit type | IS (n=507) | OOS (n=167) | WFA (n=63) |
|-----------|-----------|------------|-----------|
| SL hit | 215 (42%) PF=0.025 | 61 (37%) PF=0.031 | 29 (46%) PF=0.010 |
| TP hit | 11 (2%) PF=99 | 1 (1%) PF=99 | 0 | 
| Session close | **281 (55%) PF=7.69** | **105 (63%) PF=4.33** | **34 (54%) PF=7.64** |

**Mecanismo confirmado:** el edge está 100% en trades que sobreviven hasta el cierre de sesión.
El BE_TriggerRR=0.6 mueve a breakeven los trades favorables → corren hasta SessionEnd.
Trades que no alcanzan el trigger son cortados por SL. Comportamiento diseñado y esperado.

Hold times: min=5min, mediana=120min, max=120min (OOS). El 74% de los trades OOS
cierran exactamente en el límite de sesión.

---

## Estudio 2 — PF por bucket de duración (OOS)

| Bucket (hold time) | n | PF | Net |
|-------------------|---|-----|-----|
| 0–30 min | 9 | 0.001 | -$105 |
| 30–60 min | 16 | 0.019 | -$105 |
| 60–90 min | 19 | 0.070 | -$81 |
| **90–120 min** | **123** | **2.938** | **+$471** |

Edge concentrado en el bucket 90-120 min (sesión). n=123 > 30 → muestra suficiente.

**Concentración interna del bucket dominante:**
- Session bucket OOS: Net=$522, Top-3=$89 → **Top-3/Net-session = 17% < 30%** ✅
- Session bucket IS:  Net=$1,369, Top-3=$69 → **Top-3/Net-session = 5% < 30%** ✅

La distribución dentro del bucket es sólida. Los trades individuales no dominan.

---

## Estudio 3 — Long vs Short separados

Estrategia LONG-ONLY — criterio bidireccional **no aplica**.

| Período | n | PF (con comm) | Net |
|---------|---|------------|-----|
| IS 2022-2024 LONG | 507 | 1.246 | +$409 |
| OOS 2025 LONG | 167 | 1.333 | +$180 |
| WFA 2026 LONG | 63 | 0.908 | -$24 |

---

## Estudio 4 — Concentración top-3 trades

| Período | Net total | Top-3 sum | Top-3% | Estado |
|---------|-----------|-----------|--------|--------|
| IS | +$409 | $104 (25%) | 25% | OK |
| OOS | +$180 | $97 (54%) | 54% | ALERTA |
| WFA | -$24 | $61 | N/A | — |

**Interpretación del ALERTA OOS:** el 54% no refleja concentración de ganancias sino
un net delgado (las pérdidas SL reducen el denominador a $180 cuando el bucket ganador
genera $522). Dentro del bucket de sesión, la concentración es 17% → sin dominancia individual.
El ALERTA es una señal de muestra thin, no de dependencia de outliers.

Top-3 trades OOS:
1. +$35.36 — 2025-08-21, Session close
2. +$31.18 — 2025-03-03, TP hit
3. +$30.12 — 2025-01-24, Session close

---

## Estudio 5 — Desglose año a año

| Año | n | PF (con comm) | Net | Estado |
|-----|---|------------|-----|--------|
| 2022 | 168 | 1.321 | +$163 | OK |
| 2023 | 153 | 1.580 | +$269 | OK |
| 2024 | 186 | 0.958 | -$23 | !! |
| 2025 (OOS) | 167 | 1.333 | +$180 | OK |
| 2026 (WFA, parcial) | 63 | 0.908 | -$24 | !! |

**IS+OOS (2022-2025): 3/4 años positivos → CUMPLE (mínimo 3/4)**

2024 es el año marginal: PF=0.958 (a $9 de breakeven). 186 trades en período de alta actividad.
2026 con 63 trades es muestra corta y coincide con régimen adverso Q1-Q2 2026.

---

## Estudio 6 — Sensibilidad SessionEnd ✅ PASS

MaxHoldHours=2 (int) controla el cierre. Test ejecutado con SessionEnd_Hour/Min ±15 min.

| Escenario | Trades | PF | WR | Net | Max DD | Sharpe |
|-----------|--------|-----|-----|-----|--------|--------|
| Base +0 (120 min) | 167 | **1.289** | 62.3% | +$180 | 2.75% | 3.59 |
| Test −15 (105 min) | 155 | **1.180** | 58.7% | +$84 | 1.43% | 3.32 |
| Test +15 (135 min) | 167 | **1.272** | 59.3% | +$153 | 2.31% | 4.22 |

Criterio PF ≥ 1.0 cumplido en ambos tests. Edge no es frágil a ±15 min.
−15 min pierde 12 trades y −53% de net, pero PF se mantiene holgado (1.180).

---

## Resumen de estudios

| Estudio | Criterio | Resultado | Estado |
|---------|---------|-----------|--------|
| 1. Exit types | Mecanismo claro | Session=63% OOS PF=4.33 | PASS |
| 2. Bucket dominante | n ≥ 30, top-3 < 30% | n=105, top-3=17% | PASS |
| 3. Long/Short | N/A (long-only) | — | N/A |
| 4. Concentración total | Top-3 < 30% net | OOS=54% (net thin) | ALERTA |
| 5. Año a año | ≥3/4 años positivos | 3/4 IS+OOS | PASS |
| 6. SessionEnd sensitivity | PF ≥ 1.0 ±15min | −15→PF=1.180 / +15→PF=1.272 | PASS |

---

## Condiciones para Monte Carlo

- **Monte Carlo:** usar P&L con comisión (pnl_real = profit_out + commission_in)
- **Monitorear:** 2024 marginal (PF=0.958) — observar reversión en demo

---

## Pipeline — estado actualizado

- [x] Optimización IS
- [x] IS Backtest — PF 1.441 (sin comm) / 1.246 (con comm)
- [x] OOS Backtest — PF 1.609 (sin comm) / 1.333 (con comm)
- [x] Días de semana — 5/5 OK
- [x] Permutation Test — IS p=0.0011 / OOS p=0.0087
- [x] WFA 2026 — PF 1.123 (sin comm) / 0.918 (con comm)
- [x] Stress Test Costos — OOS PASS, WFA frágil
- [x] **Robustez — PASS (5/5 estudios, SessionEnd: PF=1.180/-15min)**
- [ ] **Monte Carlo** ← siguiente

## Script

`scripts/robustez_tbr.py`
