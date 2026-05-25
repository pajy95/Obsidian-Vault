# Optmizacion — BreakoutNY

[[Strategy - BreakoutNY]]

Archivos de optimización MT5 por activo. Cada activo tiene dos tipos de archivo: `OP_` (pasadas de optimización IS) y `FR_` (Forward Results — resultados OOS correspondientes). Los archivos están en formato XML o XLSX según la versión.

---

## Estructura de archivos

```
Optmizacion/
├── DJI30/
│   ├── OP_DJI30_v1.xml       ← pasadas IS optimización DJI30
│   └── FR_DJI30_v1.xml       ← forward results OOS DJI30
├── NAS100/
│   ├── OP_NAS100_v1.xlsx     ← pasadas IS optimización NAS100
│   └── FR_NAS100_v1.xlsx     ← forward results OOS NAS100
├── SP500/
│   ├── OP_SP500_v1.xml       ← v1 descartada (OOS negativo)
│   ├── FR_SP500_v1.xml       ← v1 descartada
│   ├── OP_SP500_v2.xml       ← pasadas IS optimización SP500 v2 (189 pasadas)
│   └── FR_SP500_v2.xml       ← forward results OOS SP500 v2
└── XAUUSD/
    ├── OP_XAUUSD_v1.xlsx     ← v1 descartada
    ├── FR_XAUUSD_v1.xlsx     ← v1 descartada
    ├── OP_XAUUSD_v2.xml      ← pasadas IS optimización XAUUSD v2 (333 pasadas)
    └── FR_XAUUSD_v2.xml      ← forward results OOS XAUUSD v2
```

---

## DJI30

### OP_DJI30_v1.xml
Grid de optimización IS 2021–2024 para DJI30. Parámetros optimizados: BE_BufferPct, MinSL_Points, MaxSL_Points, combinaciones de días de semana.

- **Pasadas analizadas:** cluster seleccionado Tue+Thu+Fri (N=27 pasadas en plateau)
- **Pass de referencia:** Pass 655 — PF IS=1.708, PF OOS=5.469
- **Criterio de selección:** DD IS ≤ 8%, plateau con vecinos PF OOS > 1.20

### FR_DJI30_v1.xml
Resultados forward OOS 2025 correspondientes a las pasadas de OP_DJI30_v1. Permite verificar la retención IS→OOS por pasada individual.

---

## NAS100

### OP_NAS100_v1.xlsx
Grid de optimización IS 2021–2024 para NAS100. Cluster seleccionado: Mon+Tue+Fri con FilterShorts=true.

- **Parámetros finales:** BE=82, MinSL=35, MaxSL=120
- **Nota crítica:** FilterShorts=true es obligatorio — sin este filtro el set degrada significativamente

### FR_NAS100_v1.xlsx
Resultados forward OOS 2025 para NAS100. PF OOS=2.154 con retención del 136.3% sobre IS.

---

## SP500

### OP_SP500_v1.xml / FR_SP500_v1.xml
Versión 1 — **descartada.** IS 2021–2024 con FilterFriday=true. OOS 2025 resultó negativo. Problema identificado: shorts fallando en 2022 (mercado bajista) y BE demasiado agresivo.

### OP_SP500_v2.xml
Grid de optimización IS 2022–2024 para SP500 v2 (189 pasadas). Cambios respecto a v1: IS recortado (excluye 2021), solo longs, ATR filter activado, MinSL/MaxSL ajustados.

- **Cluster seleccionado:** Mon+Tue+Wed
- **Parámetros finales:** BE=70, MinSL=1000, MaxSL=2000, ATR_FilterEnable=true

### FR_SP500_v2.xml
Forward OOS 2025 SP500 v2. PF OOS=1.374 — por debajo del umbral de 1.40. Motivo por el cual el set está en demo y no en producción.

---

## XAUUSD

### OP_XAUUSD_v1.xlsx / FR_XAUUSD_v1.xlsx
Versión 1 — **descartada.** Superada por v2 en métricas IS y OOS.

### OP_XAUUSD_v2.xml
Grid de optimización IS 2021–2024 para XAUUSD v2 (333 pasadas). Parámetros optimizados: BE_BufferPct, MinSL_Points, MaxSL_Points, filtros de días.

- **Cluster seleccionado:** ThuOnly — único día robusto en todos los regímenes
- **Parámetros finales:** BE=100, MinSL=5.0, MaxSL=19.0, FilterThursday=true

### FR_XAUUSD_v2.xml
Forward OOS 2025 XAUUSD v2. PF OOS=2.536 con retención del 126.7% y DD OOS=0.48%. Mejor set del portfolio en términos de estabilidad de DD.

---

## Metodología de selección de set

1. Filtrar pasadas con DD IS ≤ 8% y PF IS ≥ 1.40
2. Identificar clusters por combinación de días (día-filtro)
3. Aplicar criterio plateau: los parámetros vecinos también deben tener PF OOS > 1.20
4. Seleccionar el cluster con mayor retención OOS y trades suficientes (≥ 30 en OOS)
5. Verificar que PF OOS ≥ 75% del PF IS (Walk-Forward Efficiency Ratio)
