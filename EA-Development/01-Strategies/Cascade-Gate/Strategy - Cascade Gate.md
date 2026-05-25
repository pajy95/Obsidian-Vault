---
type: strategy
status: development
pair: NAS100 (primary) | SP500 | US30
timeframe: M5
style: momentum / multi-filter cascade (long-only)
platform: MT5 (MQL5)
account: FundingPips
risk_per_trade: 1%
created: 2026-04-12
tags:
  - strategy
---
[[Estrategias]]
# Estrategia: Cascade Gate

## Descripción General

EA de **momentum intradiario con filtrado en cascada** diseñado exclusivamente para índices americanos (NAS100, SP500, US30) durante la apertura de la sesión de Nueva York. El nombre describe su arquitectura: una secuencia de "puertas" (gates) que el mercado debe pasar en cascada para que se ejecute un trade. Si cualquier filtro falla, no hay entrada.

Derivado de la ingeniería inversa del EA comercial `US30_EA_v9.mq5` como referencia base, adaptado progresivamente para NAS100 y SP500 en FundingPips.

---

## Hipótesis

Los índices americanos (especialmente NAS100 y SP500) tienen un **sesgo estructural alcista** a largo plazo que se amplifica en la apertura de la sesión NY. En los primeros 90 minutos post-apertura, el precio combina momentum institucional, liquidez máxima del día y continuación de gaps overnight. Los 7–12 filtros en cascada descartan entornos de ruido, consolidación y falsos breakouts, dejando únicamente configuraciones donde varios indicadores institucionales convergen.

**Long-only:** Los índices americanos no tienen el mismo edge en cortos. Estrategia exclusivamente compradora.

---

## Activos y Sesión

| Activo | Símbolo FP | Contrato | TF | Sesión objetivo |
|---|---|---|---|---|
| **NAS100** | NDX100 | Variable | M5 | NY open 09:30–11:00 AM ET |
| **SP500** | SPX500 | 50 | M5 | NY open 09:35–11:05 AM ET |
| **US30** | US30 | — | M5 | NY open (exploración) |

**Broker:** FundingPips · Servidor: **UTC+2 fijo** (sin ajuste DST propio)  
**NYSE en hora servidor:**
- Invierno (EST): NYSE abre 09:30 ET = 14:30 UTC = **16:30 servidor**
- Verano (EDT): NYSE abre 09:30 ET = 13:30 UTC = **15:30 servidor**

> **El broker es UTC+2 fijo — el ajuste DST viene del mercado, no del servidor.** El EA detecta automáticamente cuándo aplica verano/invierno USA mediante `GetNthSunday()` y usa las ventanas correctas en hora servidor.

---

## Los 7 Filtros en Cascada (NAS100 v1.x)

Cada filtro imprime en el Journal el motivo de rechazo para diagnóstico. El trade se ejecuta **solo si los 7 pasan**.

| # | Filtro | Condición | Log de rechazo |
|---|---|---|---|
| F1 | **ADX** | ADX ≥ 35 (tendencia fuerte) | `[F1-ADX] BLOQUEADO — ADX=X.X < 35.0` |
| F2 | **EMA M5** | EMA9 > EMA21 > EMA50, Close > EMA200 | `[F2-EMA] BLOQUEADO — ...` |
| F3 | **H1 Trend** | Close > EMA50_H1 | `[F3-H1] BLOQUEADO — ...` |
| F4 | **MACD** | Histograma > 0 | `[F4-MACD] BLOQUEADO — ...` |
| F5 | **ATR range** | ATR en precio entre `ATR_Min` y `ATR_Max` | `[F5-ATR] BLOQUEADO — ATR=X.X (rango A-B)` |
| F6 | **FVG** | Fair Value Gap alcista dentro del lookback | `[F6-FVG] BLOQUEADO — ...` |
| F7 | **Vela** | Última vela cerrada es alcista (Close > Open) | `[F7-VELA] BLOQUEADO — ...` |

**MACD — implementación correcta en MQL5:**
```mql5
// INCORRECTO (v1.0): CopyBuffer(h_MACD, 2, ...)  ← buffer 2 no existe
// CORRECTO (v1.1+):
CopyBuffer(h_MACD, 0, 1, 1, macdMain)  // Main line
CopyBuffer(h_MACD, 1, 1, 1, macdSig)   // Signal line
double histograma = macdMain[0] - macdSig[0]
```

---

## Reglas de Entrada y Salida

### Entrada
- Verificar que todos los filtros F1–F7 pasen
- Verificar sesión NY activa (`Inp_SessWinter_H:M` o `Inp_SessSummer_H:M`)
- Verificar `MaxTradesPerDay` no alcanzado
- Verificar que no hay cooldown activo post-pérdida
- Ejecutar **orden de mercado BUY**

### Stop Loss y Take Profit
```
SL = ATR(14) × ATR_MultSL    (default: ×1.0)
TP = ATR(14) × ATR_MultTP    (default: ×1.5 → RR 1.5:1)
```

### Breakeven
```
BE activo si: profit ≥ SL × BE_MinR   (default: 30% del SL)
BE evaluado: a los BE_Candles cerradas  (default: 20 velas)
```

### Gestión adicional
- **Cooldown:** pausa tras pérdida por X tiempo configurable
- **Streak pause:** suspensión temporal tras N pérdidas consecutivas
- **MaxTradesPerDay = 2** por defecto

---

## Parámetros de Entrada

### Sesión
| Parámetro | Descripción | NAS100 Default |
|---|---|---|
| `Inp_SessWinter_H` | Hora inicio sesión invierno (servidor) | 16 |
| `Inp_SessWinter_M` | Minuto inicio invierno | 30 |
| `Inp_SessSummer_H` | Hora inicio sesión verano (servidor) | 15 |
| `Inp_SessSummer_M` | Minuto inicio verano | 30 |
| `Inp_SessDurationMin` | Duración sesión en minutos | 90 |

### Filtros de mercado
| Parámetro | Descripción | Default |
|---|---|---|
| `ADX_MinLevel` | ADX mínimo para confirmar tendencia | 35 |
| `ATR_MinPrice` | ATR mínimo en precio del índice | 5.0 (NAS) / 3.0 (SP5) |
| `ATR_MaxPrice` | ATR máximo en precio del índice | 50.0 (NAS) / 22.0 (SP5) |
| `FVG_MinSize` | Tamaño mínimo del FVG en pts | 3.0 |
| `FVG_MaxDistance` | Distancia máxima del FVG en pts | 50.0 |
| `Inp_MACD_MinHistPts` | Histograma MACD mínimo | 0.0 |

### Riesgo y gestión
| Parámetro | Descripción | Default |
|---|---|---|
| `RiskPercent` | % del balance a arriesgar | 1.0% |
| `ATR_MultSL` | Multiplicador ATR para SL | 1.0 |
| `ATR_MultTP` | Multiplicador ATR para TP | 1.5 |
| `BE_MinR` | R mínimo para activar BE | 0.30 |
| `BE_Candles` | Velas para evaluar BE | 20 |
| `MaxTradesPerDay` | Trades máximos diarios | 2 |

### Filtros de día (SP500)
| Parámetro | Default | Nota |
|---|---|---|
| `AllowWednesday` | true | Análisis pendiente por activo |
| `AllowFriday` | true | Verificar primer hora |

### Identificación
| Parámetro | NAS100 | SP500 |
|---|---|---|
| `MagicNumber` | 202611 | 680003 |
| `InpCSVName` | `"NAS_TG_FP_v1"` | — |

---

## Versiones Desarrolladas

### EA de Referencia — `US30_EA_v9.mq5`

Versión comercial validada como referencia del concepto. Resultados conocidos sobre NAS100:

**RoboForex (UTC+2, servidor = UTC):**

| Métrica | Valor |
|---|---|
| Trades (5 años) | 491 |
| Win Rate | 45.4% |
| Profit Factor | 1.211 |
| Net Profit | +$8,715 (+87.2%) |
| Max DD | 17.76% |
| Trades/año promedio | ~82 |

**FundingPips (mismo parámetro NYStart=17, erróneo):**

| Métrica | Valor |
|---|---|
| Trades (5 años) | 154 |
| Win Rate | 42.86% |
| Profit Factor | 1.105 |
| Net Profit | +$1,031 (+10.3%) |
| Max DD | 13.21% |

**Causa raíz de la divergencia:** El parámetro `InpNYStart=17` tiene significados opuestos en cada broker:
- RoboForex (UTC+2): `17:00 servidor = 15:00 UTC = 10:00 AM NY` ← dentro de apertura NYSE
- FundingPips (UTC): `17:00 UTC = 12:00 PM NY` ← 2.5 horas después de apertura

El 83% de las oportunidades de RoboForex ocurren en la ventana 15:00–17:00 UTC que FundingPips nunca captura con su configuración original.

**Corrección:** `InpNYStart=14, InpNYEnd=17` en FundingPips (UTC fixed).

---

### NAS100_TG_v1.0 — Primera implementación desde cero

**Arquitectura:** 787 líneas, 7 filtros en cascada, DST automático, CSV output  
**Problema:** 0 trades en todos los backtests

**Bug #1 — MACD buffer inexistente (causa raíz de 0 trades):**
```mql5
// v1.0 ROTO: CopyBuffer(h_MACD, 2, ...) → buffer 2 no existe en iMACD
// iMACD solo tiene buffer 0 (Main) y buffer 1 (Signal)
// CopyBuffer falla silenciosamente → histograma nunca pasa el filtro
```

**Bug #2 — Sesión expresada en horas enteras:**
```
Inp_SessionStartWinter=14 → ventana 14:00–15:30 UTC (30 min antes de NYSE open)
NYSE abre 14:30 UTC → primeros 30 min del momentum se pierden
```

**Bug #3 — ATR convertido a ticks:**
```
NDX100 _Point = 0.01
ATR real ≈ 33.92 → ATR_ticks = 33.92 / 0.01 = 3,392
Threshold ATR_Max = 80 → 3,392 >> 80 → filtro siempre falla
```

---

### NAS100_TG_v1.1 — Corrección de bugs 1–3

| Bug | v1.0 | v1.1 |
|---|---|---|
| MACD buffer | `CopyBuffer(h, 2, ...)` → falla | `CopyBuffer(h, 0, ...)` Main + `CopyBuffer(h, 1, ...)` Signal → histograma manual |
| Sesión granularidad | Horas enteras (14:00) | `H + M` separados → 14:30 exacto |
| ATR unidades | Dividido por `_Point` → 3,392 | Precio del índice → 33.92 |
| CSV | Ruta inaccesible | `FILE_COMMON` + confirmación en log |

**Sesiones v1.1:**
```
Invierno: Inp_SessWinter_H=14, Inp_SessWinter_M=30 → 14:30 UTC ✓
Verano:   Inp_SessSummer_H=13, Inp_SessSummer_M=30 → 13:30 UTC ✓
```

**Problema detectado en v1.1:** Sesión correcta en UTC pero broker es UTC+2.  
`14:30 servidor (UTC+2) = 12:30 UTC = 07:30 AM NY` ← mercado cerrado.

---

### NAS100_TG_v1.2 — Corrección definitiva de sesión + ATR

**Bug #4 — Sesión 2 horas antes de NYSE:**
```
v1.1: Inp_SessWinter_H=14 → 14:30 servidor UTC+2 = 12:30 UTC = 07:30 NY
v1.2: Inp_SessWinter_H=16 → 16:30 servidor UTC+2 = 14:30 UTC = 09:30 NY ✓
v1.2: Inp_SessSummer_H=15 → 15:30 servidor UTC+2 = 13:30 UTC = 09:30 NY (EDT) ✓
```

**Bug #5 — ATR en ticks inflados (confirmado con logs):**
```
Journal v1.1: [F5-ATR] ATR=3392.0 pts (rango 5.0-80.0)
Fix v1.2:     ATR comparado directamente en precio del índice
              ATR_MaxPrice=50.0 = 50 puntos reales de NAS100
              Funciona sin importar el valor de _Point
```

**Resultados v1.2 en backtest FundingPips (NDX100, 2021–2026):**

| Métrica | Valor |
|---|---|
| Trades (5 años) | **59** |
| Win Rate | 39% |
| Profit Factor | **0.95** |
| Net Profit | -$171 |
| Max DD | 8.54% |
| Trades/año | ~12 (target: ~82) |

**Diagnóstico v1.2:** EA funciona correctamente — los filtros son demasiado restrictivos para FP's NDX100. Trade count 59 vs target 82/año (×7 diferencia). FVG filter probablemente es el mayor eliminador de trades. ADX=35 posiblemente demasiado alto.

---

### CascadeGate_SPX500_v1.00

**Adaptación de NAS100 para SPX500.** Parámetros estimados escalados desde NAS100 (~3–4× menos volátil en M5):

| Parámetro | NAS100 | SP500 (estimado) |
|---|---|---|
| ATR_Min | 5.0 | 3.0 |
| ATR_Max | 50.0 | 22.0 |
| FVG_MinSize | 3.0 | 0.5–1.5 |
| SL×, TP×, BE | Igual (invariantes) | Sin cambio |
| Day filters | ADX-driven | Pendiente de calibración |

**Invariantes no tocados (de NAS100 v6.0 base):** `SL×1.5`, `TP×2.25`, `BE_MinR=0.30`, `BE_Candles=20`, cooldown, streak pause.

---

## Metodología de Calibración (Fase 0)

Antes de optimizar, un **script calibrador** (`CascadeGate_SP500_Calibrator.mq5`) analiza los datos IS para extraer percentiles reales de ATR y ADX durante la sesión NYSE. Este paso elimina estimaciones y parametriza con datos reales del activo.

### Proceso del calibrador

1. Cargar N barras M5 del período IS
2. Filtrar únicamente barras dentro de la ventana de sesión
3. Extraer distribución de ATR(14) → percentiles P05, P35, P50, P95
4. Extraer distribución de ADX(14) → percentiles P20, P38, P50, P70
5. Construir grid WR_proxy por bucket ATR×ADX (4×4)
6. Identificar "combo tóxico" (zona donde WR_proxy < 47%)
7. Generar CSV con resultados para análisis

### Requisitos de barras M5

| Activo | Tipo | Barras/día | 5 años necesita |
|---|---|---|---|
| NAS100 | Market hours (6.5h) | ~78 | ~100,000 |
| SPX500 | 24/5 CFD | ~288 | ~400,000–500,000 |

> **Error común con SPX500:** Con `Inp_BarsToAnalyze=200,000` solo se cubren ~6 meses del IS si el instrumento opera 24/5. Usar **400,000–500,000** o cambiar a filtro por fecha.

### Resultados calibración SP500 (parciales — solo H2 2023)

| Métrica | Valor |
|---|---|
| ATR P05 | 1.54 pts |
| ATR P35 | 2.81 pts |
| ATR P50 | 3.26 pts |
| ATR P95 | **5.89 pts** |
| ADX Media | 30.40 |
| ADX P38 | 24.85 |
| Dead zone identificada | ADX [29.2–35.7] → WR_proxy=45.6% |
| Cobertura del IS | ~20% del esperado (problema de barras) |

> ⚠️ **Resultados parciales:** Calibración solo cubrió ~6 meses (H2 2023), no los 3 años IS planificados. Los percentiles ATR son útiles como escala, pero los dead zones requieren el IS completo para ser confiables.

---

## Framework IS/OOS

### NAS100
| Período | Rango | Propósito |
|---|---|---|
| IS | 2021.01.01 – 2025.12.31 | Optimización + calibración |
| Forward | 2026.01.01+ | Walk-forward |

### SP500
| Período | Rango | % datos |
|---|---|---|
| IS | 2021.01.01 – 2023.12.31 | 57% |
| OOS | 2024.01.01 – 2026.03.31 | 43% |

**Razón del split 57/43 SP500:** El IS incluye 2022 (mercado bajista) para validar robustez en condiciones adversas. El OOS tiene 27 meses para distinguir edge de ruido.

### Criterios de aceptación OOS
| Métrica | Criterio |
|---|---|
| Degradación WR (OOS vs IS) | < 10 pp |
| Degradación PF (OOS vs IS) | < 25% |
| DD OOS | ≤ DD IS |
| Trades OOS | > 50 |

---

## Decisiones Clave del Proyecto

### 1. Long-only — sesgo estructural alcista
Los cortos degradan el performance en todos los índices americanos analizados (NAS100, SP500, US30). El análisis estadístico del edge se concentra exclusivamente en posiciones largas. Consistente con la decisión en BreakoutNY.

### 2. FVG como filtro — pendiente de validación de impacto
El filtro FVG es el candidato principal a eliminar trade count. Con v1.2 generando 59 trades (target 82/año), desactivar `FVG filter` debe ser el primer experimento de la Iteración 2. Comparar con/sin FVG para medir el trade count y el PF.

### 3. ADX threshold: evaluar 25–30 en lugar de 35
Con FundingPips NDX100, ADX=35 puede ser demasiado selectivo. La calibración de SP500 sugiere que el percentil P38 de ADX está en 24.85 — un umbral de 25–28 podría ser más apropiado para FP's data.

### 4. ATR en precio del índice, no en ticks
Lección aprendida en v1.1→v1.2: nunca dividir ATR por `_Point` para convertir a "points" — produce valores inflados por 100x en NDX100 (_Point=0.01). El ATR siempre se compara directamente en precio del activo. Thresholds son ahora propios de cada activo.

### 5. Sesión en hora servidor, no UTC
El EA usa `TimeCurrent()` que devuelve hora del servidor (UTC+2 para FundingPips). Los parámetros de sesión deben expresarse en **hora servidor**, no UTC. Simplifica la lógica y elimina conversiones de zona horaria en el EA.

### 6. No trailing stop, no breakeven agresivo
El sistema de referencia `v9.mq5` no usa trailing stop ni BE agresivo. El BE se activa conservadoramente (BE_MinR=0.30, 20 velas) para no cortar trades que eventualmente alcanzan TP. Consistente con la decisión de CTR Reclaim y ORB.

### 7. Calibrador como paso previo obligatorio (Fase 0)
Para SP500 (y cualquier activo nuevo), el calibrador debe ejecutarse **antes** del EA. No asumir que los percentiles de NAS100 aplican. Cada activo tiene distribución propia de ATR y ADX durante la sesión NYSE.

### 8. Invariantes heredados del sistema de referencia
`SL×1.5`, `TP×2.25`, `BE_MinR=0.30`, `BE_Candles=20`, cooldown y streak pause son constantes del sistema que no se tocan en adaptaciones de activo. Solo los filtros de mercado (ATR thresholds, ADX level, FVG params) varían.

---

## Bugs Documentados y Fixes

| Bug | Versión | Descripción | Fix |
|---|---|---|---|
| #1 MACD buffer | v1.0 | `CopyBuffer(h, 2, ...)` → buffer 2 no existe en iMACD | Buffer 0+1, histograma manual |
| #2 Sesión granularidad | v1.0 | Solo horas enteras, no puede expresar 14:30 | Parámetros H + M separados |
| #3 ATR en ticks | v1.0 | Dividir por `_Point` → 3,392 en vez de 33.92 | ATR en precio del activo |
| #4 Sesión UTC vs servidor | v1.1 | Sesión en UTC pero broker es UTC+2 → opera 2h antes de NYSE | Parámetros en hora servidor |
| #5 ATR inflado (confirmado log) | v1.1 | Mismo que #3, confirmado en journal `ATR=3392.0` | Eliminar `/`_Point`, usar precio |
| #6 Calibrador barras insuficientes | SP500 | 200k barras cubre solo ~6 meses en instrumento 24/5 | 400k–500k barras mínimo |
| #7 Variables undeclared | SP500 Calib | Uso de `atrH/adxH` antes de declaración | Mover bloque diagnóstico post-declaración |

---

## Próximos Pasos

### NAS100 — Iteración 2 (prioridad alta)
1. **Desactivar FVG filter** → correr backtest IS, medir impacto en trade count
2. **Bajar ADX threshold** de 35 a 25–28 → medir trade count y WR
3. Si trade count ≥ 50/año con PF ≥ 1.20: avanzar a análisis IS/OOS formal
4. Análisis por hora dentro de la sesión (16:30–17:30 vs 17:30–18:30)

### SP500 — Calibración (prioridad media)
1. **Aumentar barras calibrador** a 400,000–500,000 y re-ejecutar
2. Con IS completo: identificar dead zones reales ATR×ADX
3. Optimizar EA SP500 con percentiles calibrados
4. IS (2021–2023) → OOS (2024–2026)

### US30 — Exploración (backlog)
1. Analizar CSV generado por script Python (`us30_analyzer.py`)
2. Decidir si el edge justifica un EA independiente o adaptar Cascade Gate

---

## Estado Actual

| Activo | Estado | Última versión | PF último BT |
|---|---|---|---|
| NAS100 | EA funcionando, filtros demasiado restrictivos | v1.2 | 0.95 (59 trades/5y) |
| SP500 | EA + calibrador construidos, calibración incompleta | v1.00 | Pendiente |
| US30 | Script de datos Python construido, sin EA | — | — |

---

## Compliance FundingPips

| Regla | Límite | Implementación |
|---|---|---|
| Max daily DD | 5% | Cooldown + MaxTradesPerDay=2 |
| Max total DD | 10% | Streak pause |
| Min trade duration | 2 min | No afecta (SL×ATR típicamente > 5 min resolución) |
| No hedging | — | Long-only, 1 posición por símbolo |
| No martingala | — | RiskPercent fijo |

---

## Archivos del Proyecto

| Archivo | Descripción |
|---|---|
| `Source/Experts/NAS100_TG_v1.mq5` | Primera implementación — 7 filtros (bugs en MACD y sesión) |
| `Source/Experts/NAS100_TG_v1_1.mq5` | Corrección MACD + sesión UTC correcta |
| `Source/Experts/NAS100_TG_v1_2.mq5` | Corrección sesión servidor + ATR en precio |
| `Source/Experts/CascadeGate_SPX500_v1.mq5` | EA SP500 con estimados NAS100 escalados |
| `Source/Scripts/CascadeGate_SP500_Calibrator.mq5` | Calibrador FASE 0 para SP500 |
| `Source/Scripts/NAS100_DataCollector.mq5` | Collector M5 data (69 columnas, CSV) |
| `Source/Scripts/us30_analyzer.py` | Analizador Python MT5 para US30 |
| Referencia: `US30_EA_v9.mq5` | EA comercial base del sistema |

---

## Referencias

- Chat 060: Análisis divergencia RoboForex vs FundingPips — diagnóstico sesión UTC+2
- Chat 092: Cascade Gate SP500 — plan IS/OOS, calibrador, EA v1.00
- Chat 095: Investigación estrategias NAS100 — script data collector M5
- Chat 096: Cascade Gate NAS100 — EA v1.0→v1.2, bugs MACD/sesión/ATR
- Chat 097: Investigación estrategias US30 — script Python analyzer

*Última actualización: 2026-04-12*

[[060 - Diferencia de parametros entre FP y RB Cascade Gate]]
[[Decision - Cascade Gate FVG filter]]
[[092 - Cascade Gate SP500viable]]
[[092 - Cascade Gate SP500viable]]
## 