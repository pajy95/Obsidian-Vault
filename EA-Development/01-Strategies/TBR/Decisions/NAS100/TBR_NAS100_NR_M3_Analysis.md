# NAS100 V1 NR M3 — Análisis de Retención y Riesgo
> Fecha: 2026-05-09 | EA: New Rate Ultra | Veredicto: MARGINAL

---

## Configuración

| Parámetro | Valor |
|-----------|-------|
| EA | New Rate Ultra (distinto a TBR_v1) |
| Temporalidad | M3 |
| Trade_Direction | LONG ONLY (1) |
| Range_Candles | 1 vela |
| Session Start | 16:27 servidor |
| Auto_End_Time | true (cierra a 09:30 servidor) |
| Max_Hold_Time | **4 horas (ACTIVADO)** |
| Breakeven | DESACTIVADO |
| RR | 3.0 |
| RiskPercent | 0.25% del balance |
| Días | Lun, Mie, Vie (Mar y Jue OFF) |
| Historia | 31% ticks reales ← advertencia |

---

## Resultados generales

| Métrica | Valor | Umbral | Estado |
|---------|-------|--------|--------|
| Profit Factor | **1.4356** | ≥ 1.40 | ✓ JUSTO |
| Profit Neto | +$1,918.63 | positivo | ✓ |
| Max DD % | **5.84%** | ≤ 10% | ✓ |
| Win Rate | 33.3% | — | coherente con RR 3x |
| RR Real | **2.87x** | — | ✓ cercano al configurado |
| Total Trades | 474 | ≥ 30 | ✓ |
| Avg Win | $40.02 | — | — |
| Avg Loss | **-$13.94** | — | ✓ contenido |
| Max pérdida 1 trade | **-$25.34** | — | ✓ controlado |

---

## Análisis de Retención — RESUELTO vs Tests anteriores

### Distribución de duración

| Bucket | Trades | % | Avg Profit | TP% | SL% |
|--------|--------|---|------------|-----|-----|
| 0–5 min | 335 | **71%** | +$1.26 | 28% | 72% |
| 5–15 min | 85 | 18% | +$8.57 | 40% | 60% |
| 15–30 min | 28 | 6% | +$18.23 | 61% | 39% |
| 30–60 min | 19 | 4% | +$6.88 | 42% | 58% |
| 1–2 h | 4 | 1% | +$10.41 | 50% | 50% |
| 2–4 h | 1 | 0% | +$37.88 | 100% | 0% |
| > 4 h | 2 | 0% | +$23.03 | 0%/0% (timeout) | — |

**Estadísticas:**
- Mediana: **2 minutos**
- Media: **7 minutos**
- p90: **17 minutos**
- p95: **31 minutos**
- Máximo: **240 minutos (= 4h exactas, el timeout)**
- Trades cerrados por timeout (≥4h): **2 de 474 = 0.4%**

### Diagnóstico de retención

El problema de retención está **completamente resuelto** en este EA:
- `Max_Hold_Time = 4h ACTIVADO` funciona como circuit breaker
- El 71% de los trades se resuelven en menos de 5 minutos
- El 89% cierran en menos de 15 minutos
- **El 99.6% de los trades permanece dentro del día**
- Cero trades overnight, cero trades multi-día

Contraste directo con Tests anteriores (TBR_v1):
| | TBR Test 1 | TBR Test 2 | NR M3 |
|-|-----------|-----------|-------|
| Max retención | 24.8 días | 20.6 días | **4 horas** |
| Mediana | 239 min | 135 min | **2 min** |
| Trades overnight | 27.5% | 17.3% | **0%** |

---

## Análisis de Riesgo — CONTROLADO

### Riesgo teórico vs real

| Métrica | Valor |
|---------|-------|
| RiskPercent | 0.25% del balance |
| Riesgo teórico/trade | ~$12.50 sobre $5,000 |
| Avg Loss real | **$13.94** (1.1x teórico) |
| Max pérdida 1 trade | **$25.34** (2.0x teórico) |
| Trades con loss > 2x | 0 (max posible: $25.34) |

**El riesgo es coherente y contenido.** A diferencia de TBR_v1 donde el avg loss era 3.8–4.0x el riesgo teórico, aquí el riesgo real es prácticamente igual al configurado.

La razón: el lotaje se calcula correctamente sobre el SL real, y el `Max_Hold_Time = 4h` actúa de cierre forzoso que acota la pérdida máxima posible.

### Lotaje

| Métrica | Valor |
|---------|-------|
| Lote mínimo | 0.01 |
| Lote mediano | 0.05 |
| Lote medio | 0.05 |
| Lote máximo | 0.26 |
| Pérdidas con lote > 0.10 | 16 trades |

---

## Por año

| Año | Trades | Net P&L | PF | Win Rate | Avg dur |
|-----|--------|---------|-----|---------|---------|
| 2022 (parcial) | 12 | +$100 | 2.21 | 42% | 6 min |
| 2023 | 148 | +$838 | **1.70** | 36% | 7 min |
| 2024 | 140 | +$316 | **1.24** | 29% | 9 min |
| 2025 | 139 | +$585 | **1.41** | 34% | 7 min |
| 2026 (parcial) | 35 | +$80 | 1.21 | 31% | 4 min |

**Todos los años son positivos** — señal de robustez temporal. El PF baja de 1.70 (2023) a 1.24 (2024), indicando degradación parcial pero sin año negativo.

---

## Advertencias críticas

### 1. Historia: solo 31% ticks reales
El backtester usó 31% de ticks reales y el resto interpolados.
Para un EA que opera en M3 con trades de mediana 2 minutos, esto es **significativo**:
- El fill de órdenes pendientes (BUY STOP) depende de la resolución de ticks
- Los SL/TP en trades de 1–5 minutos pueden estar sobreestimados en calidad
- **Repetir con 90–100% ticks reales antes de avanzar**

### 2. PF 1.4356 — margen mínimo sobre el umbral
Solo 0.04 puntos sobre el umbral de 1.40. La degradación 2023→2024 (1.70→1.24) sugiere que el edge se está erosionando. El período 2024–2026 en conjunto:
- 2024: PF 1.24 (bajo umbral)
- 2025: PF 1.41 (sobre umbral por poco)
- 2026: PF 1.21 (bajo umbral)

### 3. Período es OOS no IS
Este test corre de 2022 a 2026 — es el período que en la metodología del portfolio corresponde a OOS y Walk-Forward, **no IS**. Si el edge se optimizó sobre este período, los resultados pueden estar sobreajustados.

### 4. Concentración de ganancias — NO es problema aquí
Top 10 trades = 8% del gross profit → distribución sana, no dependencia de trades excepcionales.

---

## Veredicto

**MARGINAL** — supera los umbrales mínimos en el período evaluado pero con señales de alerta:

| Criterio | Estado |
|----------|--------|
| PF ≥ 1.40 | ✓ (1.4356, margen mínimo) |
| DD ≤ 10% | ✓ (5.84%) |
| Trades ≥ 30 | ✓ (474) |
| Rentabilidad año a año | ✓ (todos positivos) |
| Retención controlada | ✓ (mediana 2min, max 4h) |
| Riesgo real ≈ configurado | ✓ (1.1x) |
| Calidad de datos | ⚠️ 31% ticks reales |
| PF período reciente 2024–26 | ⚠️ tendencia decreciente |
| Período evaluado (IS vs OOS) | ⚠️ necesita clarificación |

**Próxima acción obligatoria:** repetir con 90%+ ticks reales y clarificar si este período fue usado en optimización.
