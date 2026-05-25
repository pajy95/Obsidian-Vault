# Análisis Monte Carlo y Robustez — BreakoutNY

[[Analisis-MonteCarlo]]

Análisis probabilístico de robustez y riesgo de ruina para el portfolio BreakoutNY. 1,000 simulaciones bootstrap con seed=42. Ruin = DD ≥ 10% (límite FundingPips).

---

## Estructura

```
Analisis-MonteCarlo/
├── Portfolio/
│   ├── MonteCarlo_Portfolio_XAUUSD_NAS100_DJI30.png
│   ├── Portfolio_Combinado_XAUUSD_NAS100_DJI30.png
│   └── Robustez_Portfolio_XAUUSD_NAS100_DJI30.png
├── XAUUSD/
│   ├── MonteCarlo_XAUUSD_ThuOnly_v2.png
│   └── Robustez_XAUUSD_ThuOnly_v2.png
├── NAS100-DJI30/
│   ├── MonteCarlo_NAS100_DJI30_v1.png
│   └── Robustez_NAS100_DJI30_v1.png
└── SP500/
    ├── MonteCarlo_SP500_MonTueWed_v2.png
    └── Robustez_SP500_MonTueWed_v2.png
```

---

## Portfolio/

Análisis combinado de los 3 activos en producción: XAUUSD + NAS100 + DJI30.

### MonteCarlo_Portfolio_XAUUSD_NAS100_DJI30.png
Simulaciones Monte Carlo del portfolio combinado. Muestra la distribución de curvas de equity bajo 1,000 escenarios de reordenamiento aleatorio de trades. Evidencia la diversificación y reducción de volatilidad al combinar los 3 activos.

### Portfolio_Combinado_XAUUSD_NAS100_DJI30.png
Curva de equity real IS+OOS del portfolio combinado con breakdown por activo. Permite ver la contribución individual de cada activo al resultado total y la continuidad IS→OOS.

### Robustez_Portfolio_XAUUSD_NAS100_DJI30.png
Análisis de robustez del portfolio: distribución de R-Múltiplos, Rolling PF (ventana 15–20 trades) y métricas de estabilidad. Confirma que el edge se mantiene consistente a lo largo del tiempo.

---

## XAUUSD/

### MonteCarlo_XAUUSD_ThuOnly_v2.png
Monte Carlo individual XAUUSD ThuOnly v2. P(Ruin DD≥10%) = 0.0%. PF OOS = 2.536, DD OOS = 0.48%. El set más estable del portfolio en términos de drawdown.

### Robustez_XAUUSD_ThuOnly_v2.png
Análisis de robustez XAUUSD v2: distribución de R-Múltiplos y Rolling PF. Confirma consistencia del edge operando solo los jueves.

---

## NAS100-DJI30/

Análisis conjunto de NAS100 y DJI30 — se generaron en el mismo script por ser los dos activos optimizados en la misma sesión (sesión 110).

### MonteCarlo_NAS100_DJI30_v1.png
Monte Carlo individual para NAS100 MonTueFri v1 y DJI30 TueThuFri v1.
- NAS100: P(Ruin) = 0.0%, PF OOS = 2.154, DD OOS = 1.42%
- DJI30: P(Ruin) = 0.0%, PF OOS = 3.040, DD OOS = 0.53%

### Robustez_NAS100_DJI30_v1.png
Análisis de robustez NAS100 y DJI30: R-Múltiplos y Rolling PF. DJI30 muestra la mayor retención OOS del portfolio (204.5%).

---

## SP500/

Set en observación demo — no en producción.

### MonteCarlo_SP500_MonTueWed_v2.png
Monte Carlo SP500 MonTueWed v2. P(Ruin) = 0.0%, pero PF OOS = 1.374 — por debajo del umbral de 1.40 requerido para producción. Retención OOS = 79.7%.

### Robustez_SP500_MonTueWed_v2.png
Análisis de robustez SP500 v2. Muestra la degradación de performance en 2023 (año negativo en IS) y la marginalidad del edge en OOS.

---

## Resultados consolidados

| Activo | PF IS | PF OOS | DD OOS | Retención | P(Ruin) | Estado |
|---|---|---|---|---|---|---|
| XAUUSD ThuOnly v2 | 2.002 | 2.536 | 0.48% | 126.7% | 0.0% | ✅ Producción |
| NAS100 MonTueFri v1 | 1.580 | 2.154 | 1.42% | 136.3% | 0.0% | ✅ Producción |
| DJI30 TueThuFri v1 | 1.486 | 3.040 | 0.53% | 204.5% | 0.0% | ✅ Producción |
| SP500 MonTueWed v2 | 1.724 | 1.374 | 1.74% | 79.7% | 0.0% | 🔬 Demo |

---

## Scripts

| Script | Salida |
|---|---|
| `scripts/montecarlo_portfolio.py` | Portfolio/, XAUUSD/, NAS100-DJI30/ |
| `scripts/montecarlo_xau_v2.py` | XAUUSD/ |
| `scripts/sp500_v2_analysis.py` | SP500/ |

---

## Metodología

- **Bootstrap resampling:** 1,000 simulaciones, seed=42
- **Ruin:** DD acumulado ≥ 10% (límite total FundingPips)
- **Rolling PF:** ventana de 15–20 trades — detecta degradación de edge en el tiempo
- **Retención OOS:** (PF OOS / PF IS) × 100% — mínimo aceptable 75%
