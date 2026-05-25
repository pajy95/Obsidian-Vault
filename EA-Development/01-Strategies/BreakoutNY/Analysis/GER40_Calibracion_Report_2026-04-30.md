# GER40 — Reporte de Calibración BreakoutNY
**Fecha:** 2026-04-30 | **Periodo:** 2021-09-16 → 2026-04-29 | **N:** 1,172 días

---

## Resumen de Estadísticas Globales

| Métrica | Valor |
|---------|-------|
| n_dias | 1,172 |
| Media | 4,347 pts |
| P25 (MinSL_Points) | **2,700 pts** |
| Mediana P50 | 3,733 pts |
| P75 (MaxSL_Points) | **5,321 pts** |
| P90 | 7,600 pts |
| StdDev | 2,391 pts |
| VPP | 29.2938 EUR/punto/lote |

---

## Análisis por Día de Semana

| Día | N | Media | P25 | P50 | P75 | InRange% | <P25% |
|-----|---|-------|-----|-----|-----|----------|-------|
| Lun | 229 | 3,949 | 2,421 | 3,415 | 4,839 | 49.3% | 30.1% |
| Mar | 238 | 4,317 | 2,664 | 3,690 | 5,262 | 51.3% | 25.2% |
| Mie | 235 | 4,203 | 2,623 | 3,700 | 5,000 | 53.2% | 26.0% |
| Jue | 237 | 4,598 | 2,870 | 4,029 | 5,760 | 46.8% | 22.8% |
| Vie | 233 | 4,656 | 3,004 | 3,950 | 5,770 | 50.2% | 20.2% |

**InRange%** = días con rango entre P25 y P75 (zona óptima de operación BreakoutNY).

**Observaciones clave:**
- **Jueves y Viernes** tienen las medias más altas (4,598 y 4,656 pts) y los P25 más altos → menor porcentaje de días con rangos demasiado pequeños
- **Miércoles** tiene el mayor InRange% (53.2%) — más días en zona óptima
- **Lunes** tiene el mayor porcentaje de días con rango bajo <P25 (30.1%) → más días donde el breakout puede fallar por rango insuficiente
- Todos los días muestran comportamiento similar; no hay un día dominante estructuralmente

---

## Análisis por Año — Régimen de Volatilidad

| Año | N | Media | P25 | P50 | P75 | >P75% | <P25% | Régimen |
|-----|---|-------|-----|-----|-----|-------|-------|---------|
| 2021 (parcial) | 75 | 3,590 | 2,100 | 3,150 | 4,530 | 17.3% | 38.7% | Baja vol |
| 2022 | 257 | 5,029 | 3,400 | 4,720 | 6,200 | 38.9% | 10.1% | **Alta vol** |
| 2023 | 254 | 3,149 | 2,120 | 2,986 | 3,723 | 7.1% | 44.1% | **Baja vol** |
| 2024 | 254 | 3,556 | 2,321 | 3,144 | 4,288 | 12.6% | 37.0% | Baja-media |
| 2025 | 251 | 5,170 | 3,371 | 4,535 | 6,137 | 34.3% | 11.2% | **Alta vol** |
| 2026 (parcial) | 81 | 6,563 | 4,164 | 5,842 | 8,844 | 54.3% | 2.5% | **Muy alta vol** |

**Implicaciones para IS/OOS:**
- **IS 2021-2024:** Incluye regímenes mixtos — 2022 alta vol (guerra Ucrania), 2023-2024 baja vol. IS robusto si el EA funciona en ambos regímenes.
- **OOS 2025-2026:** Régimen de alta volatilidad (aranceles Trump, geopolítica). PF OOS puede inflarse por condiciones extremas — verificar PF 2023-2024 específicamente.
- **2023 es el año trampa:** 44.1% de días bajo P25. Si la estrategia sobrevive 2023, tiene robustez ante rangos pequeños.

---

## Frecuencia Operativa Estimada

| Combinación de Días | Días/mes | Trades/mes estimados* |
|---------------------|----------|----------------------|
| L+M+X+J+V (todos) | 21.7 | ~8-12 |
| L+M+V (baseline NAS100) | 13.0 | ~5-7 |
| M+J+V | 13.1 | ~5-7 |
| L+M+J | 13.0 | ~5-7 |
| M+X+J | 13.1 | ~5-7 |
| M+X+J+V | 17.4 | ~7-9 |

*Estimado con WR típico BreakoutNY de 45-55% y filtro de rango activo.

**Objetivo portfolio:** ≥ 4 trades/mes para justificar inclusión. Cualquier combinación de 3+ días lo cumple.

---

## Parámetros para Backtesting MT5

### Parámetros de Filtro de Rango (Calibrados)

| Parámetro | Valor | Fuente |
|-----------|-------|--------|
| **MinSL_Points** | **2,700** | P25 del periodo completo |
| **MaxSL_Points** | **5,321** | P75 del periodo completo |

> **Nota sobre unidades:** GER40 en FundingPips tiene digits=2 → 1 punto = 0.01 unidades de precio. MinSL=2700 pts = 27.00 de precio. MaxSL=5321 pts = 53.21 de precio.

### Parámetros de Entrada Recomendados (Baseline)

```
Symbol:              GER40 (verificar nombre exacto: GER40 / DE40 / DAX40)
Timeframe:           M5
ServerOffsetHours:   2
EntryWindowEnd_Min:  15
ConfirmOnClose:      true
EnablePartials:      false
ATR_FilterEnable:    true
ATR_MaxMultiplier:   2.0
ATR_MinMultiplier:   0.5
MinSL_Points:        2700
MaxSL_Points:        5321
BE_BufferPct:        [OPTIMIZAR — probar 50, 70, 82]
MagicNumber:         202403
```

### Filtros de Día — Combinación Recomendada

**Opción A — Baseline NAS100 (L+M+V):** Inicio conservador, máxima comparabilidad con NAS100.
```
FilterMonday:    true
FilterTuesday:   true
FilterWednesday: false
FilterThursday:  false
FilterFriday:    true
```

**Opción B — M+X+J (Miércoles alto InRange + Jue/Vie alta media):**
```
FilterMonday:    false
FilterTuesday:   true
FilterWednesday: true
FilterThursday:  true
FilterFriday:    false
```

**Recomendación:** Backtestear Opción A primero. Si PF IS < 1.5, probar Opción B. La selección final debe basarse en IS/OOS, no en la calibración de rangos.

---

## Criterios de Aceptación (≥ para incluir en portfolio)

| Métrica | Mínimo |
|---------|--------|
| PF IS (2021-2024) | ≥ 1.5 |
| PF OOS (2025-2026) | ≥ 1.5 |
| Retención OOS/IS | ≥ 75% |
| DD OOS máximo | ≤ 5% |
| Trades OOS/mes | ≥ 4 |
| WR OOS | ≥ 40% |

**Nota 2023:** Verificar PF específicamente en 2023 (régimen de baja vol). Si PF 2023 > 1.0, la estrategia es robusta ante el peor escenario GER40.

---

## Plan de Backtesting

1. **IS:** 2021-01-01 → 2024-12-31 (usar 2021-09-16 como inicio real por disponibilidad de datos)
2. **OOS:** 2025-01-01 → 2026-04-30
3. **Optimización en IS:** BE_BufferPct (rango: 40-90, paso 5) | NO re-optimizar MinSL/MaxSL
4. **Validación OOS:** aplicar parámetros IS sin modificar
5. **Walk-Forward:** opcional si PF OOS ≥ 1.5
6. **Carpeta de resultados:** `Backtests/GER40/`

---

*Generado desde: `Analysis/BreakoutNY_Calibracion_GER40.csv` (1,172 días)*
