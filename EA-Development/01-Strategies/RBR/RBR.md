---
title: "RBR — Range Bound Reversal"
date: 2026-05-23
version: 1.0
status: design
tags: [estrategia, mean-reversion, range-trading, IBS, price-action, MQL5, prop-firm]
related:
  - "[[TBR]]"
  - "[[Estrategias-Consolidadas-v3]]"
  - "[[Framework IS-OOS-WF]]"
  - "[[Prompt Maestro v3.0]]"
---

# RBR — Range Bound Reversal

## Concepto

Mean reversion sobre extremos de rango. El mercado pasa ~70% del tiempo en rangos laterales. Cuando el precio toca un extremo del rango con señal de rechazo confirmada (IBS + mecha), la estrategia entra en dirección contraria con target en el mid-point del rango.

**Complemento de régimen a [[TBR]]:** TBR gana en mercados trending con momentum. RBR gana en mercados laterales donde TBR falla. Operan en paralelo e independiente sobre los mismos instrumentos.

---

## Hipótesis central

Cuando el precio toca el extremo de un rango establecido (últimas N velas) con:
- IBS > 0.70 en zona baja → presión compradora confirmada → LONG
- IBS < 0.30 en zona alta → presión vendedora confirmada → SHORT
- Mecha de rechazo > 60% del rango de la vela → rechazo estructural del nivel

...el precio tiene expectativa positiva de retornar al mid del rango (equilibrio).

**Base teórica:** Auction Market Theory (AMT) — los mercados son subastas que buscan equilibrio. Los extremos del rango concentran órdenes limitadas que empujan el precio de regreso al área de valor.

---

## Instrumentos objetivo

Pendiente validación IS/OOS. Candidatos primarios (mismos que TBR):

| Instrumento | Prioridad | Justificación |
|---|---|---|
| NAS100 | Alta | Alta liquidez NY, complementa TBR NAS100 |
| SPX500 | Alta | Correlación alta con NAS100 — validar independiente |
| XAUUSD | Media | TBR XAUUSD en régimen adverso 2026 — RBR puede compensar |
| GBPUSD | Media | TBR GBPUSD con WFA negativo en 2026 |

---

## Lógica de operación

### Definición del rango
```
Range_High = Max(High, RangePeriod velas)
Range_Low  = Min(Low,  RangePeriod velas)
Range_Mid  = (Range_High + Range_Low) / 2
Range_Size = Range_High - Range_Low

Zona Alta = Range_High - (ZonePct × Range_Size)
Zona Baja = Range_Low  + (ZonePct × Range_Size)
```

### Señal de entrada
```
LONG  → precio en Zona Baja + IBS > IBS_LongThreshold  + mecha inferior > MinWickPct
SHORT → precio en Zona Alta + IBS < IBS_ShortThreshold + mecha superior > MinWickPct
```

### IBS (Internal Bar Strength)
```
IBS = (Close - Low) / (High - Low)
IBS = 1.0 → cierre en máximo de vela (presión compradora máxima)
IBS = 0.0 → cierre en mínimo de vela (presión vendedora máxima)
```

### Salidas
```
TP        → Range_Mid (equilibrio del rango)
SL        → más allá del extremo + SL_BufferPoints
Time Stop → cierre forzoso si después de N velas no hay progreso hacia TP
Sesión    → cierre forzoso al fin de sesión de trading (CloseAtSessionEnd)
```

---

## Parámetros del EA

### Rango
| Input | Default | Rango IS |
|---|---|---|
| RangePeriod | 20 | 10–30, paso 5 |
| ZonePct | 0.10 | 0.05–0.20, paso 0.05 |

### Confirmación de rechazo
| Input | Default | Rango IS |
|---|---|---|
| IBS_LongThreshold | 0.70 | 0.60–0.80, paso 0.05 |
| IBS_ShortThreshold | 0.30 | 0.20–0.40, paso 0.05 |
| MinWickPct | 0.60 | 0.40–0.70, paso 0.10 |

### Modo de entrada
| Input | Default | Opciones |
|---|---|---|
| EntryMode | MODE_CONFIRM | 0=Confirmación (market), 1=Límite (limit order) |
| LimitExpireBars | 3 | Velas antes de cancelar limit no ejecutado |

### Filtro de régimen
| Input | Default | Rango IS |
|---|---|---|
| UseRegimeFilter | true | — |
| RegimeMultiplier | 1.50 | 1.2–2.0, paso 0.2 |
| RegimePeriod | 20 | — |

### Sesión de rango (cálculo)
| Input | Default | Descripción |
|---|---|---|
| RangeSession_Start_Hour | 0 | Inicio cálculo rango (UTC) |
| RangeSession_Start_Min | 0 | |
| RangeSession_End_Hour | 9 | Fin cálculo rango (UTC) |
| RangeSession_End_Min | 0 | |

### Sesión de trading
| Input | Default | Descripción |
|---|---|---|
| TradeSession_Start_Hour | 14 | Tiempo servidor |
| TradeSession_Start_Min | 0 | |
| TradeSession_End_Hour | 17 | Tiempo servidor |
| TradeSession_End_Min | 0 | |
| ServerOffsetHours | 2 | Offset servidor vs UTC |
| CloseAtSessionEnd | true | Cerrar posición al fin de sesión |

### Gestión de posición
| Input | Default | Rango IS |
|---|---|---|
| SL_BufferPoints | 10.0 | — |
| UseTimeStop | true | — |
| TimeStopBars | 5 | 3–8, paso 1 |
| UseBreakeven | true | — |
| BE_TriggerPct | 0.50 | — |
| BE_BufferPoints | 2 | — |

### Dirección y días
| Input | Default |
|---|---|
| TradeDirection | DIR_BOTH (0=Both, 1=Buy, 2=Sell) |
| TradeMonday | true |
| TradeTuesday | true |
| TradeWednesday | true |
| TradeThursday | true |
| TradeFriday | true |
| ConfirmOnClose | true |

### Visualización
| Input | Default |
|---|---|
| ShowObjects | true |
| ShowDashboard | true |
| ColorRangeBox | clrDarkSlateGray |
| ColorZoneHigh | clrCrimson |
| ColorZoneLow | clrDodgerBlue |
| ColorMid | clrGold |

### Risk e identificación
| Input | Default |
|---|---|
| RiskAmountUSD | 10.0 |
| ExportCSV | true |
| CSVFileName | "RBR_Trades" |
| MagicNumber | 202511 |
| EA_Comment | "RBR_v1.0" |

---

## Pipeline de validación

| # | Paso | Herramienta | Estado |
|---|---|---|---|
| 1 | Optimización IS (2022–2024) | MT5 Optimizer | ⏳ Pendiente |
| 2 | IS Backtest | MT5 Backtest | ⏳ Pendiente |
| 3 | OOS (2025) | MT5 Backtest | ⏳ Pendiente |
| 4 | Días de semana | Script Python | ⏳ Pendiente |
| 5 | Permutation Test | Script Python | ⏳ Pendiente |
| 6 | WFA (2026) | MT5 Backtest | ⏳ Pendiente |
| 7 | Stress test costos | Script Python | ⏳ Pendiente |
| 8 | Robustez paramétrica | Script Python | ⏳ Pendiente |
| 9 | Monte Carlo | Script Python | ⏳ Pendiente |
| 10 | Correlación portfolio TBR | Script Python | ⏳ Pendiente |
| 11 | Gráficas | matplotlib fondo negro | ⏳ Pendiente |
| 12 | Set file | Archivo .set | ⏳ Pendiente |
| 13 | Demo | MT5 demo | ⏳ Pendiente |
| 14 | Live | Prop firm | ⏳ Pendiente |

---

## Archivos del repositorio

```
RBR/
├── Analysis/
│   └── [[RBR-Hipotesis]]           ← hipótesis y notas de diseño
├── Analisis-MonteCarlo/            ← resultados MC por instrumento
├── Backtests/                      ← CSVs MT5 por instrumento
├── Chat-History/                   ← conversaciones archivadas
├── Code/
│   └── RBR_v1.0.mq5               ← EA principal (pendiente codificación)
├── Decisions/
│   └── [[RBR-Decision-Log]]        ← veredictos IS/OOS/WFA por instrumento
├── Optimizacion/                   ← resultados .xml MT5 por instrumento
├── Sets-Produccion/                ← archivos .set validados
├── Trade-Journal/                  ← diario de operaciones demo/live
└── WalkForward/                    ← análisis WFA
```

---

## Estado actual

| Campo | Valor |
|---|---|
| Fase | Diseño completado — pendiente codificación |
| Fecha diseño | 2026-05-23 |
| Versión EA | v1.0 (en desarrollo) |
| Magic Number asignado | 202511 |
| Próximo paso | Codificar RBR_v1.0.mq5 |

---

## Notas de diseño

- RBR opera en paralelo con [[TBR]] — mismo instrumento, lógica independiente
- RiskAmountUSD reducido respecto a TBR ($10 vs $12.5) para controlar exposición combinada
- El filtro de régimen (UseRegimeFilter) es el componente más crítico — protege contra mercados trending donde RBR pierde
- Validar BE con y sin activar — el target (mid del rango) es corto y BE puede interferir
- EntryMode=Límite produce mejor RR pero menor confirmación — validar ambos en IS

---

*Soli Deo gloria.*
