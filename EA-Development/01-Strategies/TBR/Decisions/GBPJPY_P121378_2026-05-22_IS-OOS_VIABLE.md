---
tags: [decision, TBR, GBPJPY, viable, IS, OOS]
fecha: 2026-05-22
estrategia: TBR v1.1
instrumento: GBPJPY
timeframe: M5
pass: P121378
sesion: Asiática 09:00 server (07:00 UTC) — MaxHold 2h
periodo_IS: 2022-01-01 / 2024-12-31
periodo_OOS: 2025-01-01 / 2025-12-31
veredicto: VIABLE — avanza a Permutation Test
---

# GBPJPY TBR v1.1 — P121378 — IS / OOS

## Veredicto: VIABLE — Avanza a Permutation Test

## Parámetros del pass

| Parámetro | Valor |
|-----------|-------|
| TradeDirection | 1 — BUY only |
| EntryMode | 1 — Pending (stop order) |
| RangeCandlesCount | 6 |
| SessionStart_Hour | 9 (server UTC+2) = 07:00 UTC |
| SessionStart_Min | 0 |
| MaxHoldHours | 2 |
| RR | 3.0 |
| BE_TriggerRR | 0.6 |

## Resultados IS (2022–2024)

| Métrica | Valor | Criterio | Estado |
|---------|-------|----------|--------|
| Profit Factor | **1.441** | ≥ 1.10 | ✅ |
| Win Rate | 58.9% | — | ✅ |
| Total trades | 506 | ≥ 100 | ✅ |
| Net Profit | $633.20 | > 0 | ✅ |
| Avg Win / Avg Loss | $6.94 / $6.90 | — | — |
| RR real | 1.01 | — | WR-driven |

### IS por año

| Año | Trades | PF | Net |
|-----|--------|-----|-----|
| 2022 | 167 | 1.482 | $230.99 |
| 2023 | 153 | 1.777 | $338.90 |
| 2024 | 186 | 1.122 | $63.31 |

3/3 años positivos ✅

### IS por día de semana

| Día | Trades | PF | Net |
|-----|--------|-----|-----|
| Lunes | 102 | 1.615 | $159.12 |
| Martes | 98 | 1.245 | $79.44 |
| Miércoles | 100 | 1.339 | $95.26 |
| Jueves | 102 | 1.504 | $141.56 |
| Viernes | 104 | 1.545 | $157.82 |

5/5 días positivos — ningún día a excluir ✅

## Resultados OOS (2025)

| Métrica | Valor | Criterio | Estado |
|---------|-------|----------|--------|
| Profit Factor | **1.609** | ≥ 1.10 | ✅ |
| Win Rate | 62.3% | — | ✅ |
| Total trades | 167 | ≥ 100 | ✅ |
| Net Profit | $304.31 | > 0 | ✅ |
| RR real | 0.97 | — | WR-driven |

### OOS por día de semana

| Día | Trades | PF | Net |
|-----|--------|-----|-----|
| Lunes | 32 | 1.417 | $41.75 |
| Martes | 36 | 1.463 | $51.19 |
| Miércoles | 32 | 1.612 | $51.30 |
| Jueves | 34 | 2.196 | $110.91 |
| Viernes | 33 | 1.437 | $49.16 |

5/5 días positivos en OOS ✅ — Jueves es el día más fuerte (PF=2.196)

## IS → OOS

| Métrica | IS | OOS | Degradación |
|---------|-----|------|------------|
| PF | 1.441 | 1.609 | **-11.7%** (OOS mejor) |
| WR | 58.9% | 62.3% | mejora |
| Trades/año | ~169 | 167 | estable |

Degradación negativa = OOS supera al IS. Mejora moderada (+11%), no explosiva — aceptable.

## Naturaleza del edge

El edge es **Win Rate driven** (RR real ≈ 1.0). El BE_TriggerRR=0.6 lleva trades a BE cuando 
alcanzan el 60% del TP, preservando ganadores a costa de reducir el avg win. La fuente del edge 
es el sesgo direccional long de GBPJPY en sesión asiática tardía (JPY se debilita al acercarse 
London open — GBP sube).

## Próximos pasos (pipeline)

- [x] Optimización IS
- [x] IS Backtest — PF 1.441
- [x] OOS Backtest — PF 1.609
- [x] Días de semana — 5/5 OK, ninguno a excluir
- [ ] **Permutation Test** (IS y OOS) ← siguiente
- [ ] WFA 2026
- [ ] Stress test costos
- [ ] Robustez paramétrica
- [ ] Monte Carlo

## Archivos

- `Backtests/GBPJPY/IS_TBR_GBPJPY_M5_P121378.xlsx`
- `Backtests/GBPJPY/OOS_TBR_GBPJPY_M5_P121378.xlsx`
- `Optimizacion/GBPJPY/TBR_v1.1_GBPJPY_M5_IS2022-2025_Ses01-09_Asian.xml`
