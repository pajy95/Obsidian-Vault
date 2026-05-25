# BreakoutNY XAUUSD — Análisis de Sets 2025-2026

**Fecha:** 2026-04-29
**Período analizado:** 01/01/2025 – 28/04/2026
**EA:** Breakout NY XAU V9 FP
**Depósito referencia:** $5.000 | RiskAmountUSD=$16

---

## Contexto

El backtest inicial de XAUUSD (parámetros V3 heredados) arrojó solo 9 trades en 16 meses — frecuencia insuficiente para validar la edge. La causa raíz fue el uso de parámetros incorrectos (`BE=190, MinSL=5.5, MaxSL=19, EMC=2`) en lugar del Set E validado IS/OOS 2021-2026.

Se corrieron 3 backtests para resolver el problema de frecuencia:

---

## Sets comparados

### Parámetros

| Parámetro | Set E (Jue) | Set G (Jue) | Set E + LXJ |
|-----------|-------------|-------------|-------------|
| BE_BufferPct | 70 | 260 | 70 |
| MinSL_Points | 4.5 | 4.5 | 4.5 |
| MaxSL_Points | 13.0 | 16.5 | 13.0 |
| EntryMaxCandle | 0 | 0 | 0 |
| Lunes | false | false | **true** |
| Miércoles | false | false | **true** |
| Jueves | true | true | true |
| Viernes | false | false | false |

### Resultados

| Métrica | Set E (Jue) | Set G (Jue) | Set E + LXJ | Umbral VIABLE |
|---------|-------------|-------------|-------------|---------------|
| **Profit Factor** | **3.618** | 3.035 | 1.791 | ≥ 1.5 |
| **Net Profit** | $251.17 | $277.74 | **$731.82** | > 0 |
| **Expectancy/trade** | **$9.30** | $8.39 | $4.13 | > 0 |
| **Sharpe** | **23.90** | 22.00 | 11.62 | ≥ 1.0 |
| **Max DD balance** | **0.61%** | 0.59% | 1.57% | ≤ 5% |
| **Max DD equity** | **0.85%** | 0.95% | 2.12% | ≤ 5% |
| **Trades** | 27 | 33 | **177** | — |
| **Trades/mes** | 1.7 | 2.1 | 11.1 | — |
| **Hold promedio** | 1:26:05 | 1:26:39 | 1:19:19 | > 2 min ✅ |

---

## Análisis por set

### Set E — Solo Jueves
El set validado IS/OOS 2021-2026 (chat 110). Jueves es el único día con edge robusta y consistente en todos los regímenes analizados (alcista, bajista, lateral). PF de 3.618 con DD de 0.85% representa la mejor relación calidad/riesgo del portfolio. La baja frecuencia (1.7 trades/mes) es una característica estructural del día — no un defecto del set.

### Set G — Solo Jueves
Candidato identificado en análisis de 3.175 pasadas (chat 108). BE=260 más alto captura más ganancia antes del breakeven, MaxSL=16.5 acepta rangos más amplios → 6 trades extra vs Set E. Sin embargo el PF baja de 3.618 a 3.035 y el DD equity sube de 0.85% a 0.95%. Mayor frecuencia a costa de menor eficiencia por trade.

### Set E + LXJ — Lunes + Miércoles + Jueves
Añadir Lunes y Miércoles resuelve la frecuencia (177 trades, 11.1/mes) pero diluye la edge de forma significativa:
- PF cae de 3.618 → 1.791 (-50%)
- Expectancy cae de $9.30 → $4.13/trade (-56%)
- DD equity sube de 0.85% → 2.12% (+150%)

**Conclusión:** Lunes y Miércoles en XAUUSD generan señales con edge inferior al Jueves. Aportan volumen pero degradan la calidad del portfolio. Viernes ya estaba descartado por dependencia de régimen (PF=0.35 en IS 2022, chat 108).

---

## Set definitivo: **SET E — Solo Jueves**

### Justificación

**1. Edge estructural de Jueves confirmada en múltiples periodos**
IS 2021-2024: PF=2.002 | OOS 2025: PF=2.536 | Re-val 2025-2026: PF=3.618
La edge no solo persiste sino que mejora en el periodo más reciente.

**2. DD mínimo del portfolio**
Max DD equity 0.85% es el más bajo de todos los sets analizados. En el contexto de un challenge FundingPips con DLL del 5%, este set deja el mayor margen de seguridad de los 3 activos del portfolio.

**3. La frecuencia baja no es un problema operativo**
Con NAS100 (5.6 trades/mes) y DJI30 (2.3 trades/mes) como motores de frecuencia, XAUUSD actúa como activo de calidad — cada trade tiene $9.30 de expectancy vs $5.41 de NAS100. Su rol en el portfolio no es volumen sino diversificación de activo (oro vs índices).

**4. Añadir días degrada sin compensar**
El LXJ añade $480 neto extra pero reduce la expectancy por trade a la mitad y duplica el DD. En términos de riesgo ajustado, el Set E puro es superior.

---

## Parámetros de producción — Set E definitivo

```
ServerOffsetHours  = 2
EntryWindowEnd_Min = 15
RiskAmountUSD      = 16        ← cuenta $5K (3 activos)
BE_BufferPct       = 70
MinSL_Points       = 4.5
MaxSL_Points       = 13.0
FilterMonday       = false
FilterTuesday      = false
FilterWednesday    = false
FilterThursday     = true
FilterFriday       = false
ConfirmOnClose     = true
EntryMaxCandle     = 0
MagicNumber        = 202409
```

**Para challenge $25K (solo XAUUSD):** ajustar `RiskAmountUSD = 80` (0.32% de $25.000)

---

## Pendientes

- [ ] Set G: forward demo paralelo en demo durante 3 meses (Jueves) para confirmar si MaxSL=16.5 añade valor real
- [ ] Validar en cuenta real que BE_BufferPct=70 actúa correctamente en trades cortos
- [ ] Correlación XAUUSD vs NAS100/DJI30 en días con trades simultáneos
