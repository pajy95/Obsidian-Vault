# Sets-Produccion — CTR Pro

[[Strategy - CTR Pro]]

Parámetros de producción validados para cada activo de CTR Pro. Última actualización: **2026-04-30**.

```
Sets-Produccion/
├── XAUUSD/   → XAUUSD_M5_v1.md        ← pendiente IS/OOS formal
└── NDX100/   → NDX100_M10_v3.8.md     ← WFA completado, v3.8 en construcción
```

---

## Estado del portfolio — 2026-04-30

| Activo | Set | Timeframe | Risk/trade | Status | Validación |
|--------|-----|-----------|-----------|--------|------------|
| XAUUSD | v1 L+M+X | M5 | $50 (referencia) | ⚠️ Producción sin IS/OOS | Fase 3 pendiente |
| NDX100 | v3.8 WFA | M10 | $100 | 🔬 En construcción | WFA completado |

**⚠️ Riesgo activo:** XAUUSD M5 opera en producción sin IS/OOS formal documentado. Fase 3 cierra este riesgo.

**Parámetros comunes:** MagicNumber único por activo | 1 trade/día máximo | No re-entries

---

## XAUUSD M5 — v1 (parámetros del .set original)

- **EA:** CTR_Pro_EA.mq5
- **MagicNumber:** 27012026
- **RiskAmountUSD:** $50 (referencia — ajustar según cuenta)
- **Status:** ⚠️ EN PRODUCCIÓN — sin IS/OOS formal

| Parámetro | Valor |
|-----------|-------|
| Timeframe | M5 |
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

**⚠️ Hold time:** Hold típico < 8 min. Verificar regla 2 min mínimo de FundingPips en producción.

---

## NDX100 M10 — v3.8 (WFA) — en construcción

- **EA:** CTR_Reclaim_v3_8.mq5 (pendiente finalizar)
- **MagicNumber:** 3800
- **RiskAmountUSD:** $100

| Parámetro | v3.7 | v3.8 WFA | Cambio |
|-----------|------|----------|--------|
| NY_Hour | 8 | 8 | — |
| NY_Minute | 40 | **30** | -10 min |
| TP_ticks | 690 | **925** | +34% |
| SL_ticks | 110 | 110 | — |
| EnableBreakeven | true | **false** | desactivado |
| MagicNumber | 3700 | **3800** | — |

**Degradación OOS v3.7:** -30.2% — aceptable (threshold WFA diseñado para este valor)

**Referencia WFA:** `Decisions/Decision - CTR v3.8 params.md`

---

## Pendiente — Fase 3

- [ ] IS formal XAUUSD M5 (2018-2021) con parámetros del .set original
- [ ] OOS XAUUSD M5 (2022-2023)
- [ ] Crear `Sets-Produccion/XAUUSD/XAUUSD_M5_v1.md` con parámetros validados
- [ ] Finalizar CTR_Reclaim_v3_8.mq5 (4 cambios WFA pendientes)
- [ ] Crear `Sets-Produccion/NDX100/NDX100_M10_v3.8.md`
