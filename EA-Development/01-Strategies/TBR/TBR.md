---
type: strategy
status: demo
pair: NAS100 | XAUUSD
timeframe: M5
style: breakout-orb
risk_per_trade: USD-based (fijo)
created: 2026-05-11
updated: 2026-05-11
tags:
  - strategy
---
[[Estrategias]]
# Time Boxed Range (TBR) — Estrategia Marco
> Última actualización: 2026-05-11

## Concepto

Time Boxed Range es el **marco de investigación unificado** para estrategias de tipo Opening Range Breakout (ORB). El EA forma un rango con las primeras N velas M5 de la sesión y coloca órdenes stop en los extremos. La primera en activarse abre el trade; la otra se cancela. Cierre por SL, TP, o fin de sesión.

**Hipótesis central:** el precio tiende a romper el rango establecido en una ventana de tiempo predefinida y continuar en esa dirección con suficiente momentum para generar un edge positivo ajustado por costos.

**Diferencia clave vs BreakoutNY:** TBR es **bidireccional** (Long + Short) y parametrizable por instrumento mediante sets. BreakoutNY es long-only con lógica hardcodeada.

---

## Estado actual del portfolio TBR

| Instrumento | Pass | Veredicto IS/OOS | WFA 2026 | Estado |
|-------------|------|-----------------|----------|--------|
| **NAS100** | P63 L/M/X | **VIABLE (5/5)** | **VIABLE (6/6)** | **EN DEMO** |
| **XAUUSD** | P1 #7129 | **VIABLE (5/5)** | Falla (régimen hostil) | Validación WFA |
| XAUUSD | P2 #2603 | MARGINAL (4/5) | Falla | Descartado |

---

## INSTRUMENTO 1 — NAS100 (EN DEMO)

### P63 Lun+Mar+Mié — Pass #63

| Parámetro | Valor |
|-----------|-------|
| TradeDirection | DIR_BUY (long-only) |
| EntryMode | MODE_BREAKOUT |
| RangeCandlesCount | 2 |
| SessionStart_Hour | 14 UTC |
| SessionStart_Min | 15 |
| RR | 4.0 |
| Días activos | Lun + Mar + Mié |
| MagicNumber | 202501 |

### Resultados Pipeline NAS100

| Período | n | PF | WR | Net | MaxDD |
|---------|---|----|----|-----|-------|
| IS 2022-2024 | 425 | 1.252 | 23.1% | +$847 | $331 |
| OOS 2025 | 145 | 1.498 | 26.2% | +$524 | $128 |
| **WFA 2026** | **52** | **1.422** | **25.0%** | **+$163** | **$83** |

**WFA 6/6 criterios superados. VIABLE.**

### Variant LXV (pendiente WF definitivo)

Días: Lun + Mié + Vie. IS PF=1.427, OOS PF=1.408, WF 2026 PF=0.874 (hostil — mismo régimen que BNY). Pendiente más datos WFA 2026.

---

## INSTRUMENTO 2 — XAUUSD (EN VALIDACIÓN)

### P1 #7129 — Pass #7129

| Parámetro | Valor |
|-----------|-------|
| TradeDirection | DIR_BOTH (Long + Short) |
| EntryMode | MODE_BREAKOUT |
| RangeCandlesCount | 3 |
| SessionStart_Hour | 14 UTC |
| SessionStart_Min | 45 |
| RR | 3.6 |
| Días activos | Lun–Vie (todos) |
| MagicNumber | 202502 |

### Resultados Pipeline XAU P1

| Período | n | PF real | WR(TP+SL) | Net | MaxDD |
|---------|---|---------|-----------|-----|-------|
| IS 2022-2024 | 770 | 1.214 | 11.9% | +$831 | 8.15% |
| OOS 2025 | 254 | **1.606** | 14.7% | +$780 | 1.80% |
| WFA 2026 | 91 | 0.849 | 5.5% | -$136 | 8.73% |

**IS/OOS 5/5 criterios. VIABLE.**
WFA 2026 falla por régimen hostil (LONG roto, SHORT funciona). Esperar Q3 2026.

### Nota técnica — Motor de rentabilidad XAU

El PF(TP+SL) puro de TBR XAU es ~0.49 — el edge **no está en alcanzar el TP** sino en los cierres de sesión (timeout trades). Los timeout trades tienen P&L real positivo porque el breakout direcciona correctamente aunque no llegue al TP.

- IS timeout net: +$1,718 sobre net total +$831
- OOS timeout net: +$998 sobre net total +$780

---

## EA — Versiones

**Archivo activo:** `Code/TBR_v1.0b.mq5`

| Versión | Bug / Cambio |
|---------|-------------|
| v1 | Inicial |
| v1.1 | RiskPct → RiskAmountUSD fijo; CloseAfterHours |
| v1.2 | BUG FIX MODE_CONFIRM post-SessionEnd |
| v1.3 | BUG FIX lot calculado con rango bruto (riesgo 3.5x) |
| v1.4 | BUG FIX VPP = $0.20 en lugar de $20 |
| **v1.0b** | **Refactor completo — versión bidireccional (Long+Short), parámetros nuevos (TradeDirection, EntryMode), XAUUSD compatible** |

---

## Historial de tests completo

| Test | Instrumento | EA | PF IS | PF OOS | Veredicto |
|------|------------|-----|-------|--------|-----------|
| T1–T3 | NAS100 | v1 | ~0.99 | — | NO VIABLE |
| T4 | NAS100 | v1.1 | 1.06 | — | NO VIABLE |
| T5 | NAS100 | v1.1 | 1.07 | — | NO VIABLE (bug sesión) |
| T6–T8 | NAS100 | v1.2 | ~1.17 | — | NO VIABLE (bug sizing) |
| T9 | NAS100 | v1.3 | 1.27 | — | NO VIABLE (bug VPP) |
| T10 | NAS100 | v1.4 | 1.405 | 1.285 | MARGINAL |
| P63 L/M/X | NAS100 | v1.0b | 1.252 | 1.498 | **VIABLE — EN DEMO** |
| LXV variant | NAS100 | v1.0b | 1.427 | 1.408 | WF pendiente |
| P1 #7129 | XAUUSD | v1.0b | 1.214 | 1.606 | **VIABLE IS/OOS** |
| P2 #2603 | XAUUSD | v1.0b | 1.283 | 1.374 | MARGINAL |

---

## Pipeline de validación

```
IS → OOS → WFA → Monte Carlo → DEMO → Live
```

### Criterios mínimos de viabilidad

| Métrica | Mínimo |
|---------|--------|
| PF OOS (real) | ≥ 1.40 |
| Max DD OOS | ≤ 10% |
| Trades OOS | ≥ 30 |
| OOS/IS ratio | ≥ 50% |
| Net OOS | > 0 |

---

## Estructura de carpetas

```
TBR/
├── TBR.md                              ← este archivo
├── Analysis/
│   └── TBR_Hypothesis.md
├── Analisis-MonteCarlo/
│   ├── NAS100/                         ← PNG Monte Carlo + Robustez
│   └── XAUUSD/                         ← pendiente
├── Backtests/
│   ├── NAS100/                         ← T1–T10, P63, WFA 2026
│   └── XAUUSD/                         ← IS/OOS/WFA P1 y P2
├── Chat-History/                       ← sesiones de desarrollo
├── Code/
│   ├── TBR_v1.0b.mq5                  ← EA activo (bidireccional)
│   └── TBR_v1.mq5                     ← versión anterior
├── Decisions/
│   ├── NAS100/                         ← análisis T5, T8, T10, P63
│   └── XAUUSD/                         ← análisis P1, P2
├── Optimizacion/
│   ├── NAS100/                         ← XML walk-forward
│   └── XAUUSD/                         ← XML walk-forward (2744 passes)
├── Sets-Produccion/
│   ├── NAS100/
│   │   ├── TBR_v1.0b_NAS100_P63_LMX.set
│   │   └── NAS100_MonTueWed_P63_v1.md
│   └── XAUUSD/
│       ├── TBR_v1.0b_XAUUSD_P1.set
│       └── TBR_v1.0b_XAUUSD_P1.md
├── Trade-Journal/
└── WalkForward/
    ├── NAS100/
    └── XAUUSD/
```

---

## Referencias

- [[Sets-Produccion/NAS100/TBR_v1.0b_NAS100_P63_LMX]] — set activo NAS100
- [[Sets-Produccion/XAUUSD/TBR_v1.0b_XAUUSD_P1]] — set validado XAUUSD
- [[Decisions/NAS100/TBR_NAS100_v1b_Optimization_Analysis]] — análisis P63
- [[Decisions/XAUUSD/TBR_XAUUSD_P1_IS_OOS_Analysis]] — análisis XAU P1
- [[WalkForward/NAS100/WFA_NAS100_2026_P63_LMX]] — WFA NAS100
- [[WalkForward/XAUUSD/WFA_XAUUSD_P1_2026]] — WFA XAU P1
- `07-Knowledge/Workflow/quant-trader-blueprint.md` — estándares de validación
