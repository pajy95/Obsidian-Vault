# Analysis — CTR Pro

[[Strategy - CTR Pro]]

> ⛔ **ESTRATEGIA SUSPENDIDA — 2026-05-03**

Análisis de edge, robustez y decisiones cuantitativas para CTR Pro. Última actualización: **2026-05-03**.

```
Analysis/
├── Analysis.md               ← este índice
├── XAUUSD_OPT_v1.10.md      ← pendiente documentar OOS
└── NDX100_WFA_v3.7.md        ← pendiente documentar
```

---

## Estado del análisis por activo

| Activo | IS | OOS | WFA | Monte Carlo | Estado |
|--------|-----|-----|-----|-------------|--------|
| XAUUSD M10 | ✅ Optimización 3,419 pasadas | ⏳ Pendiente con set candidato | ⏳ Pendiente | ⏳ Pendiente | Set candidato definido |
| NDX100 M10 | ✅ v3.7 | ✅ -30.2% decay | ✅ 4.806 comb. | ⏳ Pendiente | v3.8 en construcción |
| EURUSD M10 | Referencia | Referencia | — | — | Archivado |
| GBPUSD M5 | Solo Martes | — | — | — | Archivado |

---

## Hallazgos críticos — Optimización XAUUSD M10 (2026-05-01)

### 1. Los Shorts destruyen el edge — CONFIRMADO

- Win Rate Longs IS: **34.09%** → sobre breakeven ✅
- Win Rate Shorts IS: **28.49%** → bajo breakeven ❌
- Win Rate Longs OOS: **32.65%** → sobre breakeven ✅
- Win Rate Shorts OOS: **28.37%** → bajo breakeven ❌
- **Regla fija:** CTR Pro XAUUSD opera exclusivamente en Buy Only. XAUUSD tiene sesgo alcista estructural igual que NAS100.

### 2. La hora UTC 16:xx es la ventana óptima — NO la apertura NY directa

- La apertura de NY es las 13:30 UTC (9:30 AM NY)
- La ventana 16:00 UTC corresponde a las 12:00 PM NY (mediodía NY)
- Interpretación: el edge no es en la apertura exacta de NY sino en la consolidación post-apertura (~2.5h después)
- Hora 15 UTC (peor resultado) coincide con el ruido pre-consolidación
- **Implicación:** La "key candle" no es la vela de apertura — es la vela de mediodía NY cuando el mercado ya absorbió la liquidez de apertura

### 3. Hora 16 UTC + Minuto 40 = núcleo de la meseta

- PF promedio hora 16: **1.256** (mejor de todas las horas)
- PF promedio min 40: **1.250** (mejor de todos los minutos)
- Intersección 16:40 UTC produce el mejor resultado absoluto: PF=**1.934**
- Pasada vecina (16:30, mismos otros params) PF=**1.642** → confirma robustez

### 4. SL 550–700 es la meseta de stop loss

- SL 650 tiene el mayor PF_avg (1.279) y mayor PF_max (1.934) de todos los valores
- SL 550 y 700 tienen PF_avg similar (1.270 y 1.259) → plateau confirmado
- SL 840 original cae fuera de esta meseta (zona 800–1000 tiene PF_avg 1.17–1.20)
- El SL más pequeño permite mayor RR manteniendo WR sobre breakeven

### 5. TP 1700–1950 es la meseta de take profit

- TP 1700 tiene PF_avg=1.266 (mejor), TP 1950 tiene PF_max=1.934 (mejor absoluto)
- TP 1800 original tiene PF_avg=1.208 — dentro de la meseta pero no en el núcleo
- TP 2000 sigue siendo viable (PF_avg=1.229) — la meseta es amplia hacia arriba
- Con SL=650 y TP=1950: **RR = 1:3.0** (vs 1:2.14 original)

### 6. Miércoles confirma degradación — ELIMINADO

- El Miércoles no aparece en ninguna de las 5 mejores combinaciones de días
- Lunes aparece en las 3 combinaciones top
- Hipótesis: Miércoles es pre-FOMC en muchos casos → spreads amplios + movimientos erráticos invalidan el patrón

### 7. ATR Filter no aporta ventaja estadística en XAUUSD M10

- ATRFilter=false: PF_avg=1.216, PF_max=1.934
- ATRFilter=true: PF_avg=1.198, PF_max=1.784
- El mejor resultado absoluto viene con ATR desactivado
- Posible causa: los multiplicadores optimizados no capturan bien la dinámica de volatilidad de XAUUSD en M10
- Decisión: dejar ATRFilter=false en set de producción. Reevaluar en segunda optimización más fina.

### 8. El edge vive en micro-reversiones (< 8 min hold) — CONFIRMADO

- v1.00 con horario 08:00–23:00: hold time medio = **16 horas** → comportamiento de swing, no scalp
- Con ventana 16:40 UTC (correcta): hold time debería reducirse a < 2 horas
- La expansión de horario destruye el edge igual que la expansión de SL/TP en NDX100

---

## Decisiones analíticas clave (históricas)

### El edge vive en micro-reversiones (< 8 min hold time)
- v3.0 con SL×10 → hold time 12h → WR cae de 32.9% a 25.8% → perdedor
- El edge es específico a la ventana de 1–3 velas post-sweep

### Vela clave: una sola referencia (8:45 AM NY)
- Transcripción del video confirma explícitamente — no es fractal genérico
- v1.0 con fractal search en 30 barras era lógica incorrecta

### SL/TP en ticks, NO en pips
- .set files reales: SL=110 ticks ≠ 11 pips
- Confusión causó múltiples versiones incorrectas

### Break-even desactivado en v3.8 (WFA resultado NDX100)
- WFA 4.806 combinaciones: EnableBreakeven=false maximiza PF neto
- BE reduce el PF en estrategias de micro-reversión con RR > 2.0

---

## Set candidato v1.10 — Parámetros validados IS

| Parámetro | Valor | Meseta confirmada |
|---|---|---|
| SL | 650 | ✅ Centro meseta 550–700 |
| TP | 1950 | ✅ Centro meseta 1700–2000 |
| RR | 1:3.0 | ✅ Mejor que original 1:2.14 |
| Breakeven WR | 25.0% | ✅ Más holgado |
| Hora UTC | 16 | ✅ Mejor hora (N=222, PF_avg=1.256) |
| Minuto UTC | 40 | ✅ Mejor minuto (N=150, PF_avg=1.250) |
| Días | Lun + Vie | ✅ Combinación top 3 |
| ATR Filter | OFF | ✅ Sin ventaja estadística |

**PF IS pasada principal:** 1.934
**PF IS pasada vecina (robustez):** 1.642

---

## Conclusión final — 2026-05-03

### Por qué se suspende

| Problema | Evidencia |
|---|---|
| Patrón demasiado frecuente | Cientos de señales/mes sin discriminación de calidad |
| IS nunca estabilizado | Ninguna versión logró PF > 1.35 en IS con N > 200 trades |
| OOS basado en varianza | PF ~2.0 OOS con solo 40 trades — no es edge estadístico |
| Filtros no ayudan | Agregar Supertrend, mecha, distancia mínima no mejora IS |
| Régimen pre-2021 | 2015–2020 destruye cualquier set optimizado en 2021–2024 |

### Veredicto
El concepto de sweep vela[1] vs vela[2] en M10 **no tiene edge demostrable** en XAUUSD con muestra estadísticamente válida. El desarrollo queda suspendido indefinidamente.
