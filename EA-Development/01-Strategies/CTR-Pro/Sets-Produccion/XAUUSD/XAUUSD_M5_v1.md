# XAUUSD M5 — Set v1 (pendiente validación IS/OOS)

[[Sets-Produccion]]

**Status:** ⚠️ En producción sin IS/OOS formal — Fase 3 pendiente

---

## Parámetros activos (del .set original)

| Parámetro | Valor |
|-----------|-------|
| EA | CTR_Pro_EA.mq5 |
| Timeframe | M5 |
| MagicNumber | 27012026 |
| Key candle | 8:45 AM NY → 13:45 UTC |
| SL_ticks | 840 ($8.40) |
| TP_ticks | 1800 ($18.00) |
| RR | 1:2.14 |
| Breakeven WR mínimo | 31.8% |
| Días activos | Lunes, Martes, Miércoles |
| Ventana entrada | 13:10–16:10 UTC |
| MaxSpreadPoints | 100 |
| EnableBreakeven | false |
| InpMaxPerDay | 1 |
| RiskAmountUSD | $50 (ajustar según cuenta) |

**⚠️ CRÍTICO:** Hold time típico < 8 min. Verificar regla 2 min mínimo de FundingPips en producción.

---

## Validación pendiente

- [ ] IS formal (2018-2021)
- [ ] OOS (2022-2023)
- [ ] WFA
- [ ] Monte Carlo
