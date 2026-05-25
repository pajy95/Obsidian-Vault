# Strategy — Opening Range Breakout (ORB)

[[Estrategias]]


## Descripción General

EA totalmente automatizado diseñado para capturar rupturas de rango intradía con disciplina. Opera capturando el rango de precio en las primeras N velas de una sesión y ejecutando exactamente en el punto de ruptura con órdenes pendientes. Filosófico en simplicidad: una operación por día, sin reentradas, sin sobreoperar.

**Concepto central:** El mercado define un rango de consenso en la apertura de cada sesión. Cuando el precio rompe ese rango, el momentum institucional suele continuar en esa dirección.

---

## Activos y Variantes

| Variante | Activo | Sesión | Cuenta | Estado |
|---|---|---|---|---|
| ORB XAUUSD | XAUUSD | NY (17:00 srv) | FundingPips | Development/Testing |
| ORB EURUSD | EURUSD | London (08:00 GMT) | FundedNext | Development |

---

## Lógica de Entrada y Salida

### Construcción del Rango
1. El EA espera el inicio de la sesión configurada (hora + minutos)
2. Escanea las primeras **N velas cerradas** (M5 por defecto) después del inicio de sesión
3. Registra el **High máximo** y **Low mínimo** de esas velas → ese es el Opening Range
4. Al completarse el rango, coloca **Buy Stop** en el High y **Sell Stop** en el Low

### Entrada
- **Buy Stop** en RangeHigh: entrada en ruptura alcista
- **Sell Stop** en RangeLow: entrada en ruptura bajista
- En cuanto se activa una orden, la opuesta se **cancela inmediatamente**
- Verificación de distancia mínima al precio actual (SYMBOL_TRADE_STOPS_LEVEL)

### Salida
- **Take Profit**: nivel fijo en pips (desde entrada)
- **Stop Loss**: nivel fijo en pips (desde entrada)
- **Breakeven**: mueve SL al precio de entrada cuando el trade alcanza X pips de ganancia
- Cancelación de pendientes al final del día si no se activaron

### Filtro de Dirección (v1.1+)
```
ENUM_ORB_DIRECTION:
  DIR_BOTH      → coloca BUY STOP y SELL STOP (default)
  DIR_BUY_ONLY  → solo BUY STOP
  DIR_SELL_ONLY → solo SELL STOP
```

---

## Parámetros de Entrada

### Configuración de Sesión
| Parámetro | Descripción | XAUUSD Default | EURUSD Default |
|---|---|---|---|
| `InpSessionHour` | Hora inicio sesión (servidor) | 17 (NY) / 4 (Asiático) | 8 (London GMT) |
| `InpSessionMinute` | Minutos inicio sesión | 0 / 15 | 0 |
| `InpRangeCandles` | Velas M5 para construir el rango | 4–5 | 3 |

### Gestión de Riesgo
| Parámetro | Descripción | XAUUSD Default | EURUSD Default |
|---|---|---|---|
| `InpTP_Pips` | Take Profit en pips | 100–270 | 20 |
| `InpSL_Pips` | Stop Loss en pips | 35–70 | 15 |
| `InpBE_Pips` | Activar breakeven a X pips | 50–220 | 10 |
| `InpRiskUSD` | Riesgo fijo en USD por trade | $25–50 | $5 |

### Filtros
| Parámetro | Descripción |
|---|---|
| `InpTradeDirection` | DIR_BOTH / DIR_BUY_ONLY / DIR_SELL_ONLY |
| `InpAllowMonday/Tuesday/.../Friday` | Días de semana habilitados |
| `InpOnlyOnePerDay` | Un trade por día (true = bloquea re-entradas) |
| `InpMagicNumber` | Identificador único del EA |

---

## Arquitectura del EA (State Machine)

```
ResetDay()          ← Nuevo día: cancela pendientes, resetea variables
    ↓
FASE 1:
  now < RangeEndTime   →  Espera pasivamente
  now >= RangeEndTime  →  BuildRange() → PlacePendingOrders()
    ↓
FASE 2: ManageTrade()
  ├── Posición activa     → CancelAllPendingOrders() + ApplyBreakeven()
  ├── Posición cerrada    → g_TradeDone = true (si OnlyOnePerDay=true)
  └── Sin órdenes/posición → g_TradeDone = true
```

**Variables globales clave:**
- `g_RangeBuilt`, `g_OrdersPlaced`, `g_TradeDone`, `g_BEApplied`, `g_OppCancelled`
- `g_TicketBuy`, `g_TicketSell`, `g_RangeHigh`, `g_RangeLow`
- `g_RangeStartTime`, `g_RangeEndTime`, `g_PipSize`

**Cálculo pip universal:** `g_PipSize = _Point * 10.0`  
**Cálculo lotes:** `tickValue * (g_PipSize / tickSize)` → funciona para cualquier símbolo

---

## Versiones del EA

### v1.0 — Base ORB
- Lógica ORB fundamental, todos los parámetros configurables
- Arquitectura: flags booleanos + tickets, no máquina de estados enum

### v1.1 — Direction Filter
- **Único cambio**: parámetro `InpTradeDirection` (DIR_BOTH/BUY_ONLY/SELL_ONLY)
- `PlacePendingOrders()`: cada bloque BUY/SELL envuelto en condición
- Todo lo demás idéntico a v1.0

### v2b — Optimizado (set NY validado)
- SessionHour=4, SessionMinute=15 (sesión asiática/overlap)
- TP=270, SL=35, BE=220, RangeCandles=4
- Días: Lunes, Jueves, Viernes
- Agrega `InpOrdenExpiraVelas`: cancelación automática de pendientes
- **Set NY validado:** PF=1.379, DD=4.64% (Lunes + Viernes únicamente)

### v3 ORCA — Con Filtro ORCA
- **EA1 LON** (Overlap London-NY): H=16:15, C=3, TP=120, SL=60, BE=30, ORCA Peso=0.5, Umbral=0.1
- **EA2 NY**: H=17:00, C=5, TP=100, SL=50, BE=80, ORCA Peso=0.7, Umbral=0.15
- ORCA mejora PF_OOS en 61% de pares comparables
- Parámetros ORCA más robustos: Peso=0.4–0.5, Umbral=0.1–0.15

### v3 PSRP — Con Filtro PSRP (Position in Session Range Prior)
- **Lógica PSRP:** calcula posición del precio en el rango de la sesión previa
  - Tercio alto → sesgo comprador → solo BUY STOP
  - Tercio bajo → sesgo vendedor → solo SELL STOP
  - Zona media → ambas órdenes
- **LB=46 velas M5** cubre ~4h = sesión asiática completa
- Candidato: H=10:30 srv (London Media), C=4, TP=90, SL=50, BE=10
- Días: Miércoles + Viernes
- **Ventaja vs ORCA**: 1,007 configs con PF≥1.20 vs apenas 10 de ORCA
- Degradación IS→OOS: -5.6% PSRP vs -14.3% ORCA

### EURUSD v1.0
- Arquitectura 100% idéntica a XAUUSD v1.1
- Sesión London Open: 08:00 GMT
- TP=20 pips, SL=15 pips → RR=1.33:1
- BE=10 pips, RiskUSD=$5
- Comisión $10/lote, pip=$0.10/0.01 lot
- Magic: `20250404`

---

## Resultados de Backtests

### XAUUSD — Backtest Principal (v2b, 2022–2026)

| Métrica | Valor |
|---|---|
| Período | 2022.01.01 – 2026.04.02 |
| Timeframe | M5 |
| Depósito inicial | $5,000 |
| Total Net Profit | $4,407.06 |
| Profit Factor | 1.50 |
| Recovery Factor | 5.95 |
| Sharpe Ratio | 3.60 |
| Equity DD Máximo | **10.55%** ($741.09) |
| Total Trades | 422 |
| Win Rate | **17.3%** |
| Avg Win | $180.14 |
| Avg Loss | -$24.63 |
| RR Implícito | ~7.3:1 |
| Max consecutive losses | **26** |

### IS/OOS — Set NY Validado (Lun+Vie, v1.1)

| Período | PF | DD | WR |
|---|---|---|---|
| IS (2022–2023) | 1.24 | 5.24–5.81% | ~60% |
| OOS (2024) | **1.34** ↑ | 6.34–6.97% | ~62% |

> Mejora IS→OOS confirma borde real. El DD en OOS supera el límite de 5% de FundingPips.

### Análisis por Día de la Semana (v2b, todos los días)

| Día | PF | WR | Trades | Net | Decisión |
|---|---|---|---|---|---|
| **Lunes** | **1.69** | 18% | — | +$1,774 | ✅ MANTENER |
| **Viernes** | **1.31** | 14.3% | — | +$847 | ✅ MANTENER |
| **Jueves** | 1.06 | 12% | 133 | +$182 | ❌ ELIMINAR |
| Martes | 4.91 | 35% | 20 | — | ⚠️ Muestra pequeña |
| Miércoles | 12.86 | 62.5% | 8 | — | ⚠️ Muestra muy pequeña |

**Anomalía Martes:** BT=0.77 vs FT=1.52 en el mismo día. Divergencia atribuida al rally del oro 2025, no al edge estructural. **No confiar en Martes.**

### Análisis por Dirección

- **BUY**: consistentemente superior en ambos períodos IS y OOS
- **SELL**: degradación OOS especialmente en Lunes → **Lunes SELL** es el segmento tóxico
- Viernes SELL: robusto en ambos períodos (IS=+$182, OOS=+$203)

---

## Análisis de Drawdown y Soluciones

### Problema Central
- DD objetivo FundingPips: ≤5%, DD actual: 8.95–10.55%
- Modelo de alta RR (7:1) + bajo WR (17%) → rachas perdedoras largas
- Max racha perdedora: **26 trades consecutivos**
- 32 rachas de 5+ pérdidas consecutivas

### Soluciones Validadas (con datos reales)

| Solución | DD Resultante | Net Profit | ¿Pasa 5%? |
|---|---|---|---|
| Baseline | 8.95% | $4,728 | ❌ |
| Eliminar Jueves | 6.04% | $4,546 | ❌ |
| Sin Jue + Reducir 50% tras 3 pérdidas | 4.64% | $3,490 | ✅ |
| Equity Curve MA(10) | 4.79% | $3,561 | ✅ |
| **ÓPTIMA: Sin Jue + F0.90 + 40%/4 pérdidas** | **4.87%** | **$3,459** | **✅** |

### Implementación Recomendada (Módulo Adaptive Risk)
```mql5
InpAllowThursday       = false   // elimina 133 trades con PF=1.06
InpGlobalFactor        = 0.90    // 10% menos riesgo base
InpLossStreakThreshold = 4       // activar tras 4 pérdidas
InpStreakReduction     = 0.40    // reducir 40% adicional
```

---

## Decisiones Clave del Proyecto

### Decisión 1: No usar filtro SPMS para mejorar edge
- El filtro no mejora el borde estadístico base
- El DD no proviene de pocas pérdidas grandes sino de perder consistentemente 7/10 trades
- **Conclusión:** Resolver filtro de días primero, luego evaluar filtros adicionales

### Decisión 2: Filtro de días como primera prioridad
- Jueves tiene PF=1.06 con 133 trades → el mayor impacto negativo
- Lunes+Viernes es el par validado más robusto
- **Regla:** Nunca activar días sin validación estadística mínima de 50+ trades

### Decisión 3: SL mínimo 35 pips en XAUUSD
- Spread + slippage en sesión asiática puede consumir 5–10 pips
- SL=20 pips destruye el RR efectivo
- **Regla:** SL mínimo 35 pips para XAUUSD en cualquier sesión

### Decisión 4: Breakeven en v1.0 — No recomendado
- Sistema con WR=27% necesita el RR completo para sobrevivir
- BE puede eliminar trades que "primero retroceden antes de llegar a TP"
- **Veredicto:** En sistemas de breakout puro, el BE puede ser destructivo. Solo implementar con RR ≥ 1.5:1 validado

### Decisión 5: PSRP > ORCA como filtro contextual
- PSRP: 1,007 configs PF≥1.20 vs ORCA: 10 configs
- Degradación IS→OOS: PSRP -5.6% vs ORCA -14.3%
- PSRP tiene lógica macroestructural genuina (posición en rango de Asia)
- **Siguiente paso:** Backtest diagnóstico H=0:45, C=5, todos los días, SL≥35

### Decisión 6: Sesión Overlap London-NY (16:15) > NY puro (17:00)
- El grid de optimización descubrió esto orgánicamente
- PF_OOS medio en H=16:15 superior al H=17
- Zona de alta liquidez: London no cerró, NY abre → institucionales activos

### Decisión 7: EURUSD — Preservar arquitectura fuente
- Usar arquitectura idéntica al v1.1 de XAUUSD
- Solo cambiar defaults de parámetros (sesión, TP, SL, BE, riesgo)
- **Principio:** No reescribir lógica probada para un activo diferente

---

## Framework de Backtesting

### Períodos IS/OOS/Walk-Forward
| Período | Rango | Propósito |
|---|---|---|
| In-Sample (IS) | 2018–2021 (XAUUSD) / 2020–2022 (EURUSD) | Optimización |
| Out-of-Sample (OOS) | 2022–2023 / 2023–2024 | Validación |
| Walk-Forward | 2024–presente | Monitoreo continuo |

### Métricas Mínimas de Viabilidad
- PF ≥ 1.20 IS
- Degradación OOS < 30%
- DD < 4.5% (FundingPips) / < 8% (objetivo general)
- Trades > 300 en IS

### Parámetros a Optimizar
```
InpSessionHour:   múltiples sesiones a probar
InpRangeCandles:  2, 3, 4, 5, 6
InpTP_Pips:       según activo
InpSL_Pips:       mínimo 35 para XAUUSD
InpBE_Pips:       0, 10, 30, 50% del TP
Días de semana:   análisis cruzado Día × Dirección
```

### Análisis Requerido por Backtest
1. **PF por día** → identificar días negativos
2. **PF por dirección** (BUY vs SELL) → detectar sesgo estructural
3. **Cruce Día × Dirección** → encontrar segmentos tóxicos (ej. "Lunes SELL")
4. **Análisis de rachas** → cuantificar max consecutive losses

---

## Estado Actual y Próximos Pasos

### Estado por Variante

**XAUUSD — Set NY Validado (v1.1):**
- Set validado: Lun+Vie, PF IS=1.24 → OOS=1.34
- DD OOS: 6.34–6.97% → requiere módulo Adaptive Risk para bajar a <5%
- Pending: integrar módulo ORB_AdaptiveRisk_Module.mqh + re-validar IS+OOS

**XAUUSD — v3 PSRP London (candidato):**
- Candidato: H=10:30 srv, C=4, TP=90, SL=50, Mie+Vie
- Pending: backtest OOS (2025.04.01–2026.03.31) con `InpRiskUSD=25`
- Pending: determinar días óptimos con backtest diagnóstico todos los días activos

**EURUSD — v1.0:**
- Código generado, arquitectura basada en v1.1 XAUUSD
- Pending: backtest IS 2020–2022 y OOS 2023–2024
- Optimizar: sesión (London 08:00 vs NY 13:00), candles, TP/SL/BE
- Filtrar por días y dirección post-backtest

### Orden de Prioridades
1. Correr backtest IS+OOS para XAUUSD con módulo Adaptive Risk (validar DD <5%)
2. Backtest diagnóstico PSRP candidato H=10:30, todos los días, `InpRiskUSD=25`
3. Backtest EURUSD v1.0 en London Open (2020–2024)
4. Si EURUSD pasa criterios: forward test 30 días en demo FundedNext

---

## Compliance Prop Firms

### FundingPips (XAUUSD)
- Max daily DD: 5%
- Max total DD: 10%
- Min trade duration: 2 min
- **DD target EA:** ≤4.5% con buffer

### FundedNext (EURUSD)
- Max daily DD: 5%
- Max total DD: 10%
- Min trade duration: 2 min
- **DD target EA:** ≤4.5% con buffer

---

## Archivos del Proyecto

| Archivo | Descripción |
|---|---|
| `Source/Experts/ORB_BreakoutEA_v1.1.mq5` | Base XAUUSD con direction filter |
| `Source/Experts/ORB_BreakoutEA_v2b_XAUUSD.mq5` | Set asiático con cancelación por velas |
| `Source/Experts/ORB_BreakoutEA_v3_ORCA_LON_XAUUSD.mq5` | Con filtro ORCA, Overlap London-NY |
| `Source/Experts/ORB_BreakoutEA_v3_ORCA_NY_XAUUSD.mq5` | Con filtro ORCA, NY Open |
| `Source/Experts/ORB_BreakoutEA_v3_PSRP_LON_XAUUSD.mq5` | Con filtro PSRP, London Media |
| `Source/Experts/ORB_BreakoutEA_v1.0_EURUSD.mq5` | Adaptación EURUSD, London Open |
| `Source/Include/ORB_AdaptiveRisk_Module.mqh` | Módulo de position sizing adaptativo |

---

## Referencias

- Chat 079: Generación estrategia EURUSD + adaptación v1.0
- Chat 084: Análisis DD + módulo Adaptive Risk
- Chat 085: EA original v2b XAUUSD (arquitectura base)
- Chat 093: ORB V1 análisis + evolución v1.1 direction filter
- Chat 104: Análisis ORCA vs PSRP + candidatos finales

*Última actualización: 2026-04-12*

## Desarrollo Relacionados

[[093 - ORB V1 XAUUSD]]
[[085 - ORBSPS  V2 XAUUSD]]
[[104 - Análisis de optimización ORB con filtro ORCA]]
[[Backtest - ORB XAUUSD]]
[[084 - Reducir DD en estrategia ORB sin perder edge]]
[[orb]]