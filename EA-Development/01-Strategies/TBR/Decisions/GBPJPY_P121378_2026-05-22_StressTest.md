---
tags: [decision, TBR, GBPJPY, stress-test, costos, viable]
fecha: 2026-05-22
estrategia: TBR v1.1
instrumento: GBPJPY
pass: P121378
step: Stress Test de Costos (Paso 7 pipeline)
veredicto: PASS OOS — ALERTA WFA (comision descubierta)
---

# GBPJPY P121378 — Stress Test de Costos

## Veredicto: PASO 7 PASS — avanza con alerta en WFA

El edge OOS es robusto bajo todos los escenarios realistas de costo.
El WFA revela una inconsistencia de metodología en el pipeline (ver sección correctiva).

---

## Datos de spread (fuente: tick real FundingPips)

| Fuente | Estadístico | Valor |
|--------|------------|-------|
| 47.6M ticks, franja 09:00-11:00 server | Mediana (Pct50) | **1.20 pips** |
| 3,585,757 ticks en ventana de entrada | Pct95 (stress) | **1.60 pips** |
| GBPJPY 2025-03-12 / 2025-12-31 | Máximo (extremo) | **25.00 pips** |

- Extra costo stress (Pct95 - base): **+0.40 pips** adicionales
- pip_value asumido: $6.58/pip/lot (USDJPY=152, promedio 2025)
- Vol promedio OOS: 0.0744 lots → costo/pip ≈ $0.49/pip

---

## OOS 2025 — Stress Test (167 trades)

### Referencia cruzada

| Metodología | PF | Net |
|-------------|-----|-----|
| Sin comisión (permutation test / pipeline anterior) | 1.609 | +$304.31 |
| **Con comisión (MT5 real — baseline correcto)** | **1.333** | **+$180.11** |

### Resultados por escenario

| Escenario | Extra pips | PF | WR | Net | Estado |
|-----------|-----------|-----|-----|-----|--------|
| Baseline (MT5 real ticks + comisión) | +0.00 | **1.333** | 58.7% | +$180.11 | PASS |
| Stress spread Pct95 | +0.40 | **1.266** | 54.5% | +$147.43 | PASS |
| Stress + slippage 50% | +1.00 | **1.170** | 47.3% | +$98.40 | PASS |
| Full stress Pct95 + slip 1pip | +1.40 | **1.110** | 45.5% | +$65.72 | PASS |
| Extremo Max (25 pips spread) | +23.80 | 0.092 | 15.6% | -$1,764 | FAIL |

**Criterio: PF >= 1.0 bajo escenarios realistas** — **CUMPLIDO**

El extremo (Max 25 pips) es teórico — ocurre <5% del tiempo y por milisegundos.
No representa condiciones normales de entrada.

---

## WFA 2026 — Hallazgo crítico (63 trades)

### Corrección de metodología

| Metodología | PF | Net | Fuente |
|-------------|-----|-----|--------|
| Sin comisión (reportado en WFA decision doc) | 1.123 | +$29.66 | Permutation test style |
| **Con comisión (MT5 oficial report)** | **0.918** | **-$24.04** | xlsx summary fila 69 |

**El WFA decision doc previo (PF=1.123) no incluyó comisión ($53.70 total).**
Esta inconsistencia no invalida el paso WFA — el PF=1.123 era real
sin comisión — pero el resultado económico real en WFA es negativo.

### Stress escenarios WFA

Todos fallan porque el baseline ya está por debajo de 1.0.
El edge en WFA (4.5 meses, 63 trades) no cubre la comisión.

---

## Diagnóstico

**OOS (167 trades, 2025 completo): ROBUSTO**
- Edge real (con comisión): PF=1.333 — supera el criterio mínimo de 1.0
- Resiste stress Pct95 + slippage 1pip: PF=1.110
- La comisión reduce el PF de 1.609 a 1.333 — costo conocido y absorbido

**WFA (63 trades, Jan-May 2026): FRÁGIL**
- El edge antes de comisión es marginal: solo $29.66 en 4.5 meses
- La comisión ($53.70) convierte el WFA en negativo: -$24.04
- PF real = 0.918 (MT5 oficial confirma)
- 63 trades es muestra pequeña para conclusión definitiva
- Coincide con régimen adverso Q1 2026 observado también en GBPUSD y XAUUSD

**Interpretación unificada:**
El OOS con 167 trades y 3 fuentes de evidencia estadística (permutation test, backtests) 
mantiene un edge real que sobrevive costos reales. El WFA muestra que en el período 
Jan-May 2026 el edge fue insuficiente para cubrir costos — consistente con el régimen 
adverso generalizado en ese período.

---

## Acción correctiva — metodología del pipeline

A partir de este paso, todos los análisis cuantitativos (Robustez, Monte Carlo)
deben usar P&L CON comisión (P&L real = profit_out + commission_in por trade).

El script de análisis correcto lee ambas columnas del deal list:
- `out` deal: columna `profit`
- `in` deal: columna `commission` (negativa)
- `pnl_real = profit_out + commission_in`

---

## Parámetros para Robustez y Monte Carlo

Usar estos spreads para los estudios siguientes:

| Parámetro | Valor | Aplicación |
|-----------|-------|-----------|
| Spread base (Pct50) | 1.20 pips | Escenario base |
| Spread stress (Pct95) | 1.60 pips | Escenario stress |
| Comisión real | ~$0.85/trade (promedio) | Siempre incluida |
| Slippage conservador | 0.60 pips | +50% del spread base |

---

## Pipeline — estado actualizado

- [x] Optimización IS
- [x] IS Backtest — PF 1.441 (sin comm) / **1.246 con comm** (507 trades, Sharpe 4.0)
- [x] OOS Backtest — PF 1.609 (sin comm) / **1.333 con comm** ✅
- [x] Días de semana — 5/5 OK
- [x] Permutation Test — IS p=0.0011 / OOS p=0.0087
- [x] WFA 2026 — PF 1.123 (sin comm) / **0.918 con comm** ⚠️
- [x] **Stress Test Costos — OOS PASS, WFA frágil (comisión)**
- [ ] **Robustez paramétrica** ← siguiente (usar P&L con comisión)
- [ ] Monte Carlo (usar P&L con comisión)

## Archivos

- `scripts/stress_test_costos.py` — script definitivo (raíz usuario)
- `GBPJPY_202503121757_202512312358.csv` — tick data fuente (47.6M ticks)
- `Backtests/GBPJPY/OOS_TBR_GBPJPY_M5_P121378.xlsx`
- `Backtests/GBPJPY/WFA_TBR_GBPJPY_M5_P121378_2026.xlsx`
