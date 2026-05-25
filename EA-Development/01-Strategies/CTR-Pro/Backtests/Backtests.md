# Backtests — CTR Pro

[[Strategy - CTR Pro]]

> ⛔ **ESTRATEGIA SUSPENDIDA — 2026-05-03**

Resultados IS/OOS de todos los activos validados para CTR Pro. Última actualización: **2026-05-03**.

```
Backtests/
├── XAUUSD/
│   ├── IS 2021-2025.xlsx    ← IS ejecutado (v1.00, configuración incorrecta)
│   ├── OOS 2021-2025.xlsx   ← OOS ejecutado (v1.00, configuración incorrecta)
│   └── (pendiente) IS+OOS con set candidato v1.10
├── NDX100/     ← IS/OOS M10 v3.7 validado | v3.8 en construcción
├── EURUSD/     ← IS/OOS M10 referencia histórica (v1.1)
└── GBPUSD/     ← IS solo Martes (v2.3 comercial)
```

---

## Período de validación

- **IS:** 2021.01.01 → 2024.12.31
- **OOS:** 2025.01.01 → 2025.12.31
- **Walk-Forward:** 2026-presente

---

## XAUUSD M10 — v1.00 ❌ PERDEDOR (configuración incorrecta)

> Backtest ejecutado con parámetros mal configurados: todos los días activos, horario 08:00–23:00, SL/TP originales sin optimizar, ambas direcciones (Longs + Shorts).

### IS 2021–2025 (v1.00)

| Métrica | Valor | Veredicto |
|---|---|---|
| Beneficio Neto | **-$1,297** | ❌ Perdedor |
| Profit Factor | **0.961** | ❌ < 1.0 |
| Win Rate total | **31.33%** | ❌ Bajo breakeven (31.8%) |
| Win Rate Longs | **34.09%** | ✅ Sobre breakeven |
| Win Rate Shorts | **28.49%** | ❌ Bajo breakeven |
| Total Trades | 1,130 | ✅ Muestra suficiente |
| DD Máximo balance | **35.47%** | ❌ Inaceptable |
| Sharpe | -0.32 | ❌ Negativo |
| Hold time medio | **16 horas** | ⚠️ No es scalp |
| Hold time mínimo | 34 min | ✅ Pasa regla 2 min |

### OOS 2025 (v1.00)

| Métrica | Valor | Veredicto |
|---|---|---|
| Beneficio Neto | **-$624** | ❌ Perdedor |
| Profit Factor | **0.927** | ❌ < 1.0 |
| Win Rate total | **30.56%** | ❌ Bajo breakeven |
| Win Rate Longs | **32.65%** | ✅ Sobre breakeven |
| Win Rate Shorts | **28.37%** | ❌ Bajo breakeven |
| Total Trades | 288 | ✅ Muestra suficiente |
| DD Máximo balance | **30.78%** | ❌ Inaceptable |
| Sharpe | -0.99 | ❌ Negativo |
| Hold time medio | **4 horas** | ⚠️ Mejoró vs IS |

### Diagnóstico v1.00

| Problema | Causa | Fix en v1.10 |
|---|---|---|
| PF < 1.0 | Shorts activos (WR=28% < breakeven) | `InpDirection=Buy Only` |
| DD > 30% | Horario sin filtrar (08:00–23:00) | Ventana UTC correcta |
| Hold time 16h IS | Operando fuera de ventana NY | Hora 16 UTC confirmada |
| SL/TP sub-óptimos | 840/1800 fuera de meseta | 650/1950 del WFA |

---

## Resumen final — Por qué ninguna versión fue validada

| Versión | IS PF | OOS PF | Trades OOS | Veredicto |
|---|---|---|---|---|
| v1.00 | 0.961 | 0.927 | 288 | ❌ Pierde en ambos |
| v1.10 | 1.934* | — | — | *103 trades, no corrió OOS formal |
| v1.20 | 0.862 | 1.971 | 40 | ❌ IS pierde, OOS insuficiente |
| v1.30 | 0.680 | 2.240 | 40 | ❌ IS peor, OOS insuficiente |
| v2.00 | 0.870 | — | — | ❌ Sin edge en ninguna combinación |
| v2.10 | 1.310 | — | — | ❌ Insuficiente |

**OOS con 40 trades no es validación estadística.** Con RR=3 y varianza normal, 5 trades ganadores seguidos producen PF=2.0 sin edge real.

---

## XAUUSD M10 — v1.10 ⛔ SUSPENDIDA (OOS nunca ejecutado)

**Set candidato** seleccionado de optimización 2026-05-01 (3,419 pasadas):

| Parámetro | Valor |
|---|---|
| SL | 650 ticks |
| TP | 1950 ticks |
| RR | **1:3.0** |
| Breakeven WR mínimo | **25.0%** (mejora vs 31.8% original) |
| Días | Lunes + Viernes |
| Hora UTC | 16:40 |
| ATR Filter | OFF |
| Dirección | Buy Only |

**Resultado IS (pasada 1937):**
- PF = **1.934**
- Profit = **$2,703**
- DD = **10.98%**
- Trades = 103

**Resultado pasada vecina (pass 902 — mismos SL/TP, Min=30):**
- PF = **1.642** — confirma robustez de la meseta

**OOS pendiente:** Correr 2025.01.01–2025.12.31 con estos parámetros exactos.
**Criterio aprobación OOS:** PF ≥ 1.35 (≥ 70% de 1.934)

---

## NDX100 M10 — v3.7 ✅ VALIDADO IS+OOS

| Período | PF | Degradación |
|---|---|---|
| IS 2020-2023 | — | — |
| OOS | −30.2% vs IS | Dentro del threshold WFA |

- WFA completo: 4.806 combinaciones analizadas
- **v3.8 (WFA):** NY=8:30, TP=925, BE=false, MN=3800 — en construcción

### NDX100 v2.2 — referencia histórica (bug lotaje)

| Métrica | Valor | Nota |
|---|---|---|
| Net Profit | +$690 | Bug lotaje: $5.50 real/trade |
| Profit Factor | 1.31 | |
| Win Rate | 32.9% | > breakeven 27.5% ✓ |
| Trades | 812 | Corte 2023-07-14 (data gap) |
| Hold time máx | < 8 min | Micro-scalp confirmado |

**Proyección corregida ($100 riesgo real):** Net Profit ~$12,545 en 2020–2023

---

## EURUSD M10 — referencia histórica (v1.1)

| Parámetro | Valor |
|---|---|
| SL | 90 ticks (9 pips) |
| TP | 180 ticks (18 pips) |
| RR | 1:2.0 |
| Breakeven WR mínimo | 33.3% |
| Días activos | Martes–Viernes |

---

## Punto de equilibrio matemático

```
Breakeven WR = 1 / (1 + RR)
RR = 3.0  → Breakeven = 25.0%   (XAUUSD v1.10 set candidato) ✅ MEJOR
RR = 2.64 → Breakeven = 27.5%   (NDX100 v2.2)
RR = 2.14 → Breakeven = 31.8%   (XAUUSD v1.00 original)
RR = 2.0  → Breakeven = 33.3%   (EURUSD M10)
```

**WR > Breakeven WR → PROFITABLE. WR < Breakeven WR → LOSING.**
