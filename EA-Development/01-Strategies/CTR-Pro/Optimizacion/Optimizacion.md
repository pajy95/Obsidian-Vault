# Optimizacion — CTR Pro

[[Strategy - CTR Pro]]

> ⛔ **ESTRATEGIA SUSPENDIDA — 2026-05-03**

Archivos de optimización MT5 por activo. Última actualización: **2026-05-03**.

```
Optimizacion/
├── XAUUSD/
│   ├── OPT CRT PRO XAU.xml     ← Optimización v1.10 completada 2026-05-01
│   ├── OP_XAUUSD_M5_v1.xml     ← pendiente exportar set ganador
│   └── FR_XAUUSD_M5_v1.xml     ← pendiente OOS
└── NDX100/
    ├── OP_NDX100_v3.7.xml       ← WFA 4.806 combinaciones completado
    └── FR_NDX100_v3.7.xml       ← forward results OOS v3.7
```

---

## XAUUSD M10 — Optimización v1.10 ✅ COMPLETADA (2026-05-01)

### Configuración de la pasada
| Campo | Valor |
|---|---|
| EA | CTR_Pro_EA_v1.mq5 |
| Símbolo | XAUUSD |
| Timeframe | **M10** |
| Período | 2021.01.01 – 2025.12.31 |
| Servidor | FundingPips2-SIM (Build 5833) |
| Depósito | $5,000 USD |
| Apalancamiento | 1:25 |
| Total pasadas | 3,419 |
| Pasadas válidas (Trades≥60, DD≤20%, PF>1.0) | **586** |

**Parámetros optimizados:** InpSL_Pips, InpTP_Pips, InpATRFilter, InpATRMinMult, InpATRMaxMult, InpMonday–InpFriday, InpUTCStartHour, InpUTCStartMin

**Parámetros fijos:** InpDirection=Buy Only, InpMaxPerDay=1, InpMaxSpread=100, InpRiskUSD=50

---

## Análisis de mesetas — Hallazgos clave

### Meseta 1 — Hora UTC de inicio: 16:xx es dominante

| Hora UTC | N válidas | PF_avg | PF_max |
|---|---|---|---|
| **16** | **222** | **1.256** | **1.934** |
| 12 | 218 | 1.218 | 1.600 |
| 14 | 30 | 1.143 | 1.425 |
| 13 | 90 | 1.128 | 1.480 |
| 15 | 26 | 1.064 | 1.193 |

**Conclusión:** Hora 16 UTC (12:00 NY EDT) domina en PF_avg y PF_max. Hora 12 UTC es la segunda opción viable. Horas 13–15 son zona de transición con menor consistencia. La hora 15 UTC es la peor (justo antes de la apertura NY — spread y movimientos erráticos pre-apertura).

### Meseta 2 — Minuto de inicio: 40 y 50 son los más robustos

| Minuto | N válidas | PF_avg | PF_max |
|---|---|---|---|
| **40** | **150** | **1.250** | **1.934** |
| **50** | **139** | **1.231** | **1.535** |
| 30 | 123 | 1.206 | 1.642 |
| 10 | 62 | 1.170 | 1.600 |
| 20 | 48 | 1.161 | 1.480 |
| 0 | 64 | 1.134 | 1.393 |

**Conclusión:** Minuto 40 es el más robusto (mayor N y mayor PF_avg). Minuto 50 es segundo. Minutos 0 y 20 son los más débiles — zona de ruido.

### Meseta 3 — SL: zona 550–700 ticks es la óptima

| SL (ticks) | N válidas | PF_avg | PF_max |
|---|---|---|---|
| **650** | **67** | **1.279** | **1.934** |
| **550** | **11** | **1.270** | **1.784** |
| 400 | 15 | 1.263 | 1.714 |
| **700** | **53** | **1.259** | **1.727** |
| 350 | 11 | 1.242 | 1.766 |
| 500 | 14 | 1.236 | 1.405 |
| 600 | 18 | 1.218 | 1.463 |
| 800 | 31 | 1.197 | 1.498 |
| 750 | 52 | 1.196 | 1.582 |
| 900–1000 | — | 1.17–1.19 | — |

**Conclusión:** Meseta clara en SL 550–700. El SL original de 840 está fuera de la zona óptima — demasiado amplio para este timeframe. Núcleo de la meseta: **SL = 650** con el mayor PF promedio y máximo de toda la optimización.

### Meseta 4 — TP: zona 1700–1950 ticks

| TP (ticks) | N válidas | PF_avg | PF_max |
|---|---|---|---|
| **1700** | **47** | **1.266** | **1.826** |
| **1900** | **87** | **1.255** | **1.766** |
| **1950** | **65** | **1.248** | **1.934** |
| 1850 | 43 | 1.231 | 1.498 |
| 2000 | 56 | 1.229 | 1.535 |
| 1800 | 25 | 1.208 | 1.389 |
| 1750 | 41 | 1.198 | 1.458 |

**Conclusión:** Meseta en 1700–1950. El TP original de 1800 está dentro pero no es el óptimo — 1700 y 1900/1950 superan a 1800. RR con SL=650/TP=1900 = **1:2.92** (mejora el RR original de 2.14).

### Meseta 5 — Días: Lunes es el más valioso

| Combinación días | N | PF_avg | PF_max |
|---|---|---|---|
| **Lun + Jue + Vie** | **22** | **1.337** | **1.586** |
| **Lun + Jue** | **37** | **1.308** | **1.826** |
| **Lun + Vie** | **29** | **1.272** | **1.934** |
| Lun + Mie + Vie | 12 | 1.261 | 1.573 |
| Lun + Mar + Jue + Vie | 17 | 1.237 | 1.463 |
| Jue + Vie | 39 | 1.226 | 1.531 |
| Mar + Jue | 67 | 1.224 | 1.600 |
| Mie + Jue | 68 | 1.209 | 1.480 |

**Conclusión:** Lunes aparece en las 3 combinaciones top. El Miércoles (original) no aparece en las mejores combinaciones — confirma que era el día que degradaba. Combinaciones más robustas por N: **Lun+Jue** (37 pasadas) y **Lun+Vie** (29 pasadas).

### Meseta 6 — ATR Filter: sin ventaja estadística clara

| ATR Filter | N | PF_avg | PF_max |
|---|---|---|---|
| **false** | **321** | **1.216** | **1.934** |
| true | 265 | 1.198 | 1.784 |

**Conclusión:** ATR Filter desactivado tiene PF_avg superior. El mejor resultado absoluto (PF=1.934) viene con ATRFilter=false. El filtro ATR no aporta ventaja estadística global en esta optimización — puede estar siendo demasiado restrictivo para XAUUSD M10.

---

## Zona de meseta principal — Top 20 pasadas

Criterio: Hora=16, Min=30–50, SL=550–750, TP=1700–2000

| Pass | PF | Profit | DD% | Trades | SL | TP | ATR | Mon | Tue | Wed | Thu | Fri | H | Min |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1937 | **1.934** | $2,703 | 11.0% | 103 | 650 | 1950 | OFF | ✅ | ❌ | ❌ | ❌ | ✅ | 16 | 40 |
| 1326 | 1.826 | $2,315 | 13.5% | 103 | 650 | 1700 | OFF | ✅ | ❌ | ❌ | ✅ | ❌ | 16 | 40 |
| 1622 | 1.784 | $2,554 | 13.0% | 102 | 550 | 1700 | ON | ✅ | ❌ | ❌ | ✅ | ❌ | 16 | 40 |
| 1583 | 1.766 | $2,999 | 13.8% | 103 | 350 | 1900 | OFF | ✅ | ❌ | ❌ | ✅ | ❌ | 16 | 40 |
| 1874 | 1.727 | $2,155 | 14.0% | 102 | 700 | 1700 | ON | ✅ | ❌ | ❌ | ✅ | ❌ | 16 | 40 |
| 1803 | 1.714 | $2,660 | 14.5% | 103 | 400 | 1900 | OFF | ✅ | ❌ | ❌ | ✅ | ❌ | 16 | 40 |
| 902 | 1.642 | $1,975 | 11.0% | 103 | 650 | 1950 | OFF | ✅ | ❌ | ❌ | ❌ | ✅ | 16 | 30 |
| 1878 | 1.586 | $2,703 | 15.2% | 154 | 650 | 1900 | ON | ✅ | ❌ | ❌ | ✅ | ✅ | 16 | 30 |
| 850 | 1.582 | $2,518 | 17.9% | 154 | 750 | 1900 | ON | ✅ | ❌ | ❌ | ✅ | ✅ | 16 | 40 |
| 802 | 1.535 | $2,383 | 12.2% | 154 | 750 | 2000 | OFF | ✅ | ❌ | ✅ | ✅ | ❌ | 16 | 50 |

**N pasadas en zona meseta:** 47 | **PF promedio:** 1.364

---

## Set candidato — v1.10 (pendiente validación OOS)

Seleccionado por: mayor PF, DD < 15%, vecinos robustos (pass 902 con mismos SL/TP/días confirma meseta)

| Parámetro | Valor | Razón |
|---|---|---|
| `InpSL_Pips` | **650** | Centro de meseta SL |
| `InpTP_Pips` | **1950** | Mayor PF en la zona TP |
| `InpATRFilter` | **false** | Sin ventaja estadística en esta pasada |
| `InpUTCStartHour` | **16** | Hora dominante en toda la optimización |
| `InpUTCStartMin` | **40** | Minuto más robusto |
| `InpMonday` | **true** | Día más valioso |
| `InpTuesday` | false | No aparece en top combinaciones |
| `InpWednesday` | false | Confirma degradación (día FOMC) |
| `InpThursday` | false | Pasa 1937 sin Jue es el mejor |
| `InpFriday` | **true** | Segundo día del set ganador |
| `InpDirection` | Buy Only | Confirmado por IS/OOS |
| `InpMaxPerDay` | 1 | Por diseño |
| `InpRiskUSD` | 50 | Base de comparación |

**RR implícito:** 650/1950 = **1:3.0** (mejora significativa vs 840/1800 = 1:2.14 original)

---

## Conclusión — 2026-05-03

Optimizaciones adicionales (v2.0 sweep puro, v2.10 con filtros mecha+distancia) confirmaron que el patrón no tiene edge estabilizable en IS con muestra suficiente. Desarrollo suspendido.

---

## NDX100 M10 — v3.7 ✅ COMPLETADO

### OP_NDX100_v3.7.xml
Grid WFA con 4.806 combinaciones analizadas. Parámetros explorados: NY_Hour/Minute, TP_ticks, EnableBreakeven.

**Resultados WFA:**
- NY_Minute=30 (de 40) — 8:30 NY captura mejor el sweep post-apertura
- TP=925 ticks (de 690) — TP más amplio mejora PF sin sacrificar WR sobre breakeven
- EnableBreakeven=false — BE reduce el PF neto en micro-scalp con RR > 2.0
- Degradación OOS: **-30.2%** — dentro del threshold aceptable

---

## Metodología de selección de set

1. Filtrar pasadas con DD IS ≤ 15% y PF IS ≥ 1.40
2. Agrupar por parámetro individual — identificar mesetas (zonas con PF_avg elevado y N alto)
3. Criterio plateau: parámetros vecinos deben tener PF OOS > 1.20
4. Seleccionar combinación con mayor PF en la intersección de todas las mesetas
5. Verificar PF OOS ≥ 70% del PF IS (Walk-Forward Efficiency Ratio)
