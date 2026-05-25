# Análisis Monte Carlo y Robustez — CTR Pro

[[Strategy - CTR Pro]]

Análisis probabilístico de robustez y riesgo de ruina para CTR Pro. Pendiente de ejecutar tras completar IS/OOS XAUUSD M5 en Fase 3.

```
Analisis-MonteCarlo/
├── Analisis-MonteCarlo.md    ← este índice
├── XAUUSD/                   ← pendiente Fase 3
└── NDX100/                   ← pendiente
```

---

## Estado

| Activo | Monte Carlo | Robustez | P(Ruin) | Estado |
|--------|-------------|----------|---------|--------|
| XAUUSD M5 | ⏳ Pendiente | ⏳ Pendiente | — | Requiere IS/OOS previo |
| NDX100 M10 | ⏳ Pendiente | ⏳ Pendiente | — | Requiere OOS documentado |

---

## Metodología (pendiente ejecutar)

- **Bootstrap resampling:** 10.000 simulaciones, seed=42
- **Ruin:** DD acumulado ≥ 10% (MLL FundingPips) o DLL 5%
- **Escenarios:** Base (0%) | Conservador (-20% expectancy) | Pesimista (-40%)
- **Horizonte:** 24 meses máximo por simulación
- **Script:** `scripts/portfolio_montecarlo.py` (adaptar para CTR Pro)

---

## Criterios mínimos para aprobar Monte Carlo

| Métrica | Mínimo |
|---------|--------|
| P(Ruin DD≥10%) | < 1% |
| DD p95 | < 4% |
| P(Fase 1 + Fase 2) | ≥ 85% |

---

## Pendiente

- [ ] IS/OOS XAUUSD M5 completo (Fase 3)
- [ ] Ejecutar `portfolio_montecarlo.py` con trades reales CTR Pro
- [ ] Análisis de correlación CTR Pro vs BreakoutNY (diversificación de edge)
