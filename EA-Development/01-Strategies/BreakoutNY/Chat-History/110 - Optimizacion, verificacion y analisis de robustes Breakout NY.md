# 110 - Optimización, Verificación y Análisis de Robustez Breakout NY

**Fecha inicio:** 2026-04-13 | **Última actualización:** 2026-04-18
**Activos analizados:** NAS100, XAUUSD, DJI30, SP500
**Período IS:** 2021–2024 | **OOS:** 2025 | **WF:** 2026–presente

---

## Contexto de sesión

Sesión de optimización completa del portfolio BreakoutNY en 4 activos. Se ejecutaron optimizaciones en MT5 (IS y OOS/Forward), se analizaron clusters por combinación de días, se seleccionaron sets finales, y se generaron análisis de Monte Carlo y Robustez con gráficos.

---

## Criterios de filtrado aplicados

| Métrica | IS mínimo | OOS mínimo |
|---|---|---|
| Profit Factor | ≥ 1.40 | ≥ 1.40 |
| Equity DD% | ≤ 8% | ≤ 8% |
| Trades | ≥ 30 | ≥ 10 |
| Retención OOS | — | ≥ 75% |

---

## NAS100 — Set Final v1

**Archivos:** `Backtests/NAS100/IS_NAS100_MonTueFri_v1.xlsx` / `OOS_NAS100_MonTueFri_v1.xlsx`

### Set Recomendado — Pass 1220

| Parámetro | Valor |
|---|---|
| FilterMonday | true |
| FilterTuesday | true |
| FilterWednesday | false |
| FilterThursday | false |
| FilterFriday | true |
| MinSL_Points | 35 |
| MaxSL_Points | 120 |
| BE_BufferPct | 82 |
| ConfirmOnClose | true |

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 1.580 | 2.154 |
| Max DD | 2.57% | 1.42% |
| Trades | 294 | 82 |
| Win Rate | — | — |
| Retención OOS | — | **136.3%** |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

**Veredicto:** ✅ Production-ready. OOS supera IS. Plateau de SL confirmado.

---

## XAUUSD — Set Final v2

**Archivos:** `Backtests/XAUUSD/IS_XAUUSD_ThuOnly_v2.xlsx` / `OOS_XAUUSD_ThuOnly_v2.xlsx`

**Optimización v2:** IS 2022–2024 (excluido 2021 COVID-recovery), ConfirmOnClose=true, EntryMaxCandle=0.

### Set Recomendado — Pass 98 (operado con BE=100)

| Parámetro | Valor |
|---|---|
| FilterMonday | false |
| FilterTuesday | false |
| FilterWednesday | false |
| FilterThursday | true |
| FilterFriday | false |
| MinSL_Points | 5.0 |
| MaxSL_Points | 19.0 |
| BE_BufferPct | 100 |
| ConfirmOnClose | true |
| EntryMaxCandle | 0 |

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 2.002 | 2.536 |
| Max DD | 0.93% | 0.48% |
| Trades | 63 | 35 |
| Win Rate | 49.2% | 48.6% |
| RR promedio | 2.07:1 | 2.69:1 |
| PF Longs | 1.426 | 2.752 |
| PF Shorts | 2.904 | 2.394 |
| Retención OOS | — | **126.7%** |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

**Veredicto:** ✅ Mejor resultado del portfolio. DD máximo real 0.93% en 4 años. Sin reservas.

---

## DJI30 — Set Final v1

**Archivos:** `Backtests/DJI30/IS_DJI30_TueThuFri_v1.xlsx` / `OOS_DJI30_TueThuFri_v1.xlsx`

### Set Recomendado — Pass 655

| Parámetro | Valor |
|---|---|
| FilterMonday | false |
| FilterTuesday | true |
| FilterWednesday | false |
| FilterThursday | true |
| FilterFriday | true |
| MinSL_Points | 35 |
| MaxSL_Points | 120 |
| BE_BufferPct | 82 |

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 1.486 | 3.040 |
| Max DD | 1.63% | 0.53% |
| Trades | 150 | 49 |
| Retención OOS | — | **204.5%** |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

**Veredicto:** ✅ Production-ready. OOS extraordinario. Retención >200%.

---

## SP500 — Set v2 (NO activar aún)

**Archivos:** `Backtests/SP500/IS_SP500_MonTueWed_v2.xlsx` / `OOS_SP500_MonTueWed_v2.xlsx`

### Set v2 — Pass 75

| Parámetro | Valor |
|---|---|
| FilterMonday | true |
| FilterTuesday | true |
| FilterWednesday | true |
| FilterThursday | false |
| FilterFriday | false |
| MinSL_Points | 1000 |
| MaxSL_Points | 2000 |
| BE_BufferPct | 70 |
| ATR_FilterEnable | true |
| ATR_MaxMultiplier | 2 |
| ConfirmOnClose | true |

| Métrica | IS 2021–2024 | OOS 2025 |
|---|---|---|
| Profit Factor | 1.724 | 1.374 |
| Max DD | 1.22% | 1.74% |
| Trades | 99 | 43 |
| Win Rate | 30.3% | 27.9% |
| RR promedio | 1.95:1 | 2.18:1 |
| Retención OOS | — | 79.7% |
| P(Ruin DD≥10%) | 0.0% | 0.0% |

**Veredicto:** ⚠️ No activar. PF OOS 1.374 marginal, WR 27.9% exige alta disciplina, 2023 IS fue negativo. Monitorear en demo WF 2026 durante 3 meses antes de activar en cuenta prop.

---

## Comparativa Portfolio Final

| Activo | Días | PF IS | DD IS | PF OOS | DD OOS | Retención | Veredicto |
|---|---|---|---|---|---|---|---|
| **XAUUSD v2** | Jue | 2.002 | 0.93% | 2.536 | 0.48% | 126.7% | ✅ Activar |
| **NAS100 v1** | Lun+Mar+Vie | 1.580 | 2.57% | 2.154 | 1.42% | 136.3% | ✅ Activar |
| **DJI30 v1** | Mar+Jue+Vie | 1.486 | 1.63% | 3.040 | 0.53% | 204.5% | ✅ Activar |
| **SP500 v2** | Lun+Mar+Mie | 1.724 | 1.22% | 1.374 | 1.74% | 79.7% | ⚠️ Demo |

---

## Estructura de activación recomendada

| Activo | Estado | RiskAmountUSD | Prioridad |
|---|---|---|---|
| XAUUSD v2 | **Activar ahora** | $12 | 1 |
| NAS100 v1 | **Activar ahora** | $12 | 2 |
| DJI30 v1 | **Activar ahora** | $12 | 3 |
| SP500 v2 | Demo 3 meses | — | Pendiente |

---

## Archivos de backtesting organizados

```
Backtests/
├── XAUUSD/
│   ├── IS_XAUUSD_ThuFri_v1.xlsx
│   ├── OOS_XAUUSD_ThuFri_v1.xlsx
│   ├── IS_XAUUSD_ThuOnly_v1.xlsx
│   ├── OOS_XAUUSD_ThuOnly_v1.xlsx
│   ├── IS_XAUUSD_ThuOnly_v2.xlsx   ← SET ACTIVO
│   └── OOS_XAUUSD_ThuOnly_v2.xlsx  ← SET ACTIVO
├── NAS100/
│   ├── IS_NAS100_MonTueFri_v1.xlsx  ← SET ACTIVO
│   └── OOS_NAS100_MonTueFri_v1.xlsx ← SET ACTIVO
├── DJI30/
│   ├── IS_DJI30_TueThuFri_v1.xlsx  ← SET ACTIVO
│   └── OOS_DJI30_TueThuFri_v1.xlsx ← SET ACTIVO
└── SP500/
    ├── IS_SP500_MonTueWedFri_v1.xlsx
    ├── OOS_SP500_MonTueWedFri_v1.xlsx
    ├── IS_SP500_MonTueWed_v2.xlsx
    └── OOS_SP500_MonTueWed_v2.xlsx
```

---

## Gráficos generados

| Archivo | Descripción |
|---|---|
| `MonteCarlo_Portfolio_XAU_NAS_DJI.png` | Monte Carlo individual IS+OOS por activo (1000 sim) |
| `Portfolio_Combinado_XAU_NAS_DJI.png` | Profit distribution + equity curves combinadas |
| `Robustez_Portfolio_XAU_NAS_DJI.png` | R-Multiple + Rolling PF por activo |
| `MonteCarlo_XAUUSD_v2.png` | Monte Carlo detallado XAUUSD v2 |
| `Robustez_XAUUSD_v2.png` | Robustez detallada XAUUSD v2 |
| `MonteCarlo_SP500_v2.png` | Monte Carlo SP500 v2 (referencia) |
| `Robustez_SP500_v2.png` | Robustez SP500 v2 (referencia) |

---

## Pendientes

- [ ] WF 2026 en vivo: proveer datos cuando estén disponibles para los 3 activos activos
- [ ] SP500: re-evaluar en 3 meses con datos WF 2026 demo
- [ ] Análisis de correlación inter-activos (pendiente datos mensuales consolidados)
- [ ] Validar en cuenta real que BE_BufferPct=100 en XAUUSD actúa correctamente en trades cortos
