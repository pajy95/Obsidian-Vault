# TBR — Hipótesis de Investigación

> Documento vivo. Actualizar conforme avance el IS/OOS de cada configuración.

---

## Hipótesis Central

**H1 — Edge ORB universal**
El precio establece un rango de consolidación pre-sesión y tiende a romper y continuar en la dirección del breakout con frecuencia suficiente para generar un Profit Factor ≥ 1.4 ajustado por costos reales (spread + comisión + slippage).

**H2 — Normalización ATR**
Expresar los filtros de rango como múltiplos de ATR permite transferir los mismos umbrales entre activos de distinta magnitud de precio sin pérdida de selectividad. Un rango entre 0.3× y 1.5× ATR captura los días con movimiento válido en todos los activos del pipeline.

**H3 — Ventana temporal óptima**
Existe una ventana de tiempo específica por sesión donde el edge del breakout es estadísticamente superior. Fuera de esa ventana (breakouts tardíos), la relación SL/TP se deteriora significativamente. EntryMaxCandle captura esta restricción.

**H4 — Direccionalidad por activo**
Algunos activos tienen sesgo estructural que invalida uno de los lados (ej: NAS100 long-only en sesión NY). La confirmación de este sesgo debe surgir del IS, no de suponer.

---

## Configuraciones a investigar

### 1. NY Open Breakout (renovación BreakoutNY)

| Parámetro | Valor inicial |
|-----------|--------------|
| RangeStart | 14:35 UTC (3 velas M5 anteriores a NY open) |
| RangeEnd | 14:50 UTC |
| EntryWindow | 15 min post-rango |
| SessionClose | 17:00 UTC |
| MinRange_ATR | 0.3 |
| MaxRange_ATR | 1.5 |

**Activos a testear:** NAS100, DJI30, XAUUSD, SP500  
**Pregunta clave:** ¿El edge se mantiene con ATR normalizado vs parámetros absolutos?

---

### 2. London Open Breakout (ORB London)

| Parámetro | Valor inicial |
|-----------|--------------|
| RangeStart | 07:30 UTC (Asian range final) |
| RangeEnd | 08:00 UTC |
| EntryWindow | 30 min post-rango |
| SessionClose | 10:00 UTC |
| MinRange_ATR | 0.2 |
| MaxRange_ATR | 1.2 |

**Activos a testear:** EURUSD, GBPUSD  
**Pregunta clave:** ¿La sesión de Londres tiene edge comparable al NY Open en Forex?

---

### 3. Cascade Gate (NY Open intraday momentum)

| Parámetro | Valor inicial |
|-----------|--------------|
| RangeStart | 14:50 UTC |
| RangeEnd | 15:30 UTC (primera hora NY) |
| EntryWindow | 60 min post-rango |
| SessionClose | 17:00 UTC |
| MinRange_ATR | 0.5 |
| MaxRange_ATR | 2.0 |

**Activos a testear:** NAS100, SP500  
**Pregunta clave:** ¿Un rango más amplio (primera hora completa) mejora la calidad de señal en índices?

---

### 4. Tres Soldados (NY Open — patrón de impulso)

**Nota:** Tres Soldados es un patrón de velas, no un ORB puro. Investigar si puede modelarse como un breakout del rango de las 3 primeras velas NY con filtro de dirección por estructura de velas.

**Activos a testear:** US30  
**Pregunta clave:** ¿El patrón de 3 velas alcistas/bajistas sucesivas al open genera un edge quantificable como ORB?

---

### 5. Asian Open Breakout (exploratorio)

| Parámetro | Valor inicial |
|-----------|--------------|
| RangeStart | 00:00 UTC |
| RangeEnd | 02:00 UTC (primeras 2h sesión Asia) |
| EntryWindow | 60 min post-rango |
| SessionClose | 06:00 UTC |

**Activos a testear:** USDJPY  
**Estado:** Baja prioridad — solo investigar si las configuraciones 1-4 no completan el portfolio objetivo.

---

## Checklist de escepticismo (aplicar a cada configuración)

```
□ ¿El PF se mantiene con slippage 2× estimado?
□ ¿El resultado depende de 1–3 trades excepcionales?
□ ¿Funciona en años individuales o solo en el período completo?
□ ¿Los parámetros ATR son estables en ±30% de rango?
□ ¿Sample size > 30 trades en OOS? (preferible > 100)
□ ¿El edge supera spread + comisión + swap reales?
□ ¿Stress test paramétrico pasado?
□ ¿KS test IS vs OOS no detectó cambio de régimen?
```

---

## Log de investigación

| Fecha | Configuración | Resultado | Próxima acción |
|-------|--------------|-----------|----------------|
| 2026-05-09 | — | Repositorio creado | Iniciar IS NY Open en NAS100 con ATR normalizado |
