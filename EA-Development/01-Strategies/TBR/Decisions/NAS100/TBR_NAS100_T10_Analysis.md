# TBR NAS100 — Análisis Test 10 (v1.4 MODE_BREAKOUT M3)
> Fecha: 2026-05-10 | EA: TBR_v1 v1.4 | Veredicto: MARGINAL — edge confirmado, OOS PF bajo umbral

---

## Configuración Test 10

| Parámetro | Valor |
|-----------|-------|
| EA | TBR_v1 v1.4 |
| Temporalidad | M3 |
| EntryMode | MODE_BREAKOUT (1) |
| TradeDirection | BUY only (1) |
| RangeCandlesCount | 1 |
| RR | 3.0 |
| RiskAmountUSD | $12.50 fijo |
| SessionStart | 14:27 UTC |
| SessionEnd | 17:00 UTC |
| Días | Lun/Mié/Vie |
| Período | 2022.01.01 – 2026.05.09 |
| Depósito | $5,000 |
| Calidad ticks | 26% reales |

---

## Resultados globales

| Métrica | NR | T10 | Umbral | Estado |
|---------|-----|-----|--------|--------|
| Profit Factor | 1.4356 | **1.4054** | ≥ 1.40 | ✓ |
| Max DD balance | 4.79% | **3.20%** | ≤ 10% | ✓ |
| Max DD equity | 5.21% | **3.42%** | ≤ 10% | ✓ |
| Total Trades | 474 | **623** | ≥ 30 | ✓ |
| Win Rate | 33.3% | **32.1%** | — | similar |
| Sharpe | 46.2 | **43.3** | > 1.0 | ✓ |
| Net profit | $1,918 | **$1,861** | positivo | ✓ |

**MARGINAL — primer test que supera 1.40 de PF. Bugs de sizing corregidos.**

---

## Desglose IS / OOS

| Período | NR PF | T10 PF | T10 DD | Estado |
|---------|-------|--------|--------|--------|
| IS 2022-2023 | 1.789 | **1.412** | 3.11% | ✓ |
| OOS 2024-2025 | 1.353 | **1.285** | 3.70% | ✗ bajo umbral |
| WF 2026 (parcial) | — | 1.226 | 0.89% | referencia |

### Criterios de robustez

| Criterio | NR | T10 | Umbral | Estado |
|----------|-----|-----|--------|--------|
| OOS/IS ratio | 75.6% | **91.0%** | ≥ 50% | ✓ |
| MaxDD OOS | 5.54% | **3.70%** | ≤ 10% | ✓ |
| OOS PF | 1.353 | **1.285** | ≥ 1.40 | ✗ |

---

## Año a año

| Año | Período | Trades | PF | WR | Net |
|-----|---------|--------|----|----|-----|
| 2022 | IS | 154 | 1.284 | 30% | +$328 |
| 2023 | IS | 152 | 1.551 | 34% | +$593 |
| 2024 | OOS | 154 | 1.325 | 31% | +$353 |
| 2025 | OOS | 154 | 1.246 | 31% | +$278 |
| 2026 | WF | 9 | 1.226 | 33% | +$15 |

**Todos los años positivos** — sin año destructor.

---

## Sizing — verificación (bugs corregidos)

| Métrica | NR | T10 |
|---------|-----|-----|
| Lot mediana | 0.04 | 0.04 |
| SL_dist mediana (pts) | 15.0 | 15.2 |
| Riesgo real mediana | $13.52 | $10.88 |
| Floor check matches | — | **91.9%** |

El sizing está correcto. Riesgo real ~$10.88 vs $12.50 configurado — diferencia por floor() que redondea hacia abajo.

---

## Bugs corregidos en este test (v1.4)

| Bug | Versión fix | Impacto |
|-----|-------------|---------|
| MODE_CONFIRM post-SessionEnd | v1.2 | 72% trades fuera de sesión en T5 |
| Lot calculado con rango bruto, no SL real | v1.3 | Riesgo real 3.5x el configurado |
| VPP = $0.20 en lugar de $20 (divide/100 de más) | **v1.4** | Lot 3-4x demasiado alto → DD 21% |

---

## Análisis matemático del edge

Con WR=31% y RR=3.0:
```
PF_esperado = (0.31 × 3.0) / (0.69 × 1.0) = 0.93 / 0.69 = 1.348
```
El PF real de 1.285-1.412 es consistente con la matemática. Para PF≥1.40 se necesita WR≥32.5% o RR>3.0, o filtrar condiciones negativas.

---

## Por qué T10 tiene más trades que NR (623 vs 474)

- NR período: Dic 2022 – Mar 2026 vs T10: Ene 2022 – May 2026
- NR días: Dom/Lun/Mié/Vie vs T10: Lun/Mié/Vie
- NR: `One_Trade_Per_Day=true` — puede saltarse días sin señal clara
- T10 cubre período más largo con días similares

---

## Próximos pasos

1. **Optimizar RR** — probar RR=2.0 y 2.5 para ver si WR sube y PF mejora en OOS
2. **Filtro de días** — Miércoles IS PF=1.55, Lunes/Viernes más débiles
3. **Optimizar SessionStart** — ¿14:27 es el óptimo o hay meseta?
4. **Calidad ticks** — subir de 26% a 99% para confirmar resultados

---

## Veredicto formal

**MARGINAL** — edge real confirmado por primera vez en TBR.

| Criterio | Estado |
|----------|--------|
| PF global ≥ 1.40 | ✓ (1.405) |
| PF OOS ≥ 1.40 | ✗ (1.285) |
| DD ≤ 10% | ✓ (3.42%) |
| Todos los años positivos | ✓ |
| OOS/IS ratio ≥ 50% | ✓ (91%) |
| Sizing correcto | ✓ (91.9% match) |

No avanza a OOS formal hasta mejorar PF OOS ≥ 1.40.
