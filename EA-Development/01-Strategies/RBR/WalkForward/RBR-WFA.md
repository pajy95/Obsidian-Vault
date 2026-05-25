---
title: "RBR — Walk-Forward Analysis"
date: 2026-05-23
tags: [RBR, WFA, walk-forward]
related:
  - "[[RBR]]"
  - "[[RBR-Decision-Log]]"
---

# RBR — Walk-Forward Analysis

> WFA 2026 — ventana rolling: IS 12 meses / OOS 3 meses.
> Ejecutar después de que OOS (2025) pase con veredicto VIABLE.

---

## Metodología

| Campo | Valor |
|---|---|
| Período IS | 12 meses |
| Período OOS | 3 meses |
| Paso | 3 meses (avance de ventana) |
| Métrica de optimización | PF × (1 - DD/100) con penalización < 30 trades |

---

## Resultados por instrumento

### NAS100
*(pendiente)*

### SPX500
*(pendiente)*

### XAUUSD
*(pendiente)*

### GBPUSD
*(pendiente)*

---

## Walk-Forward Efficiency (WFE)

```
WFE = PF_OOS_WFA / PF_IS_WFA

WFE ≥ 0.70 → excelente generalización
WFE 0.50–0.70 → aceptable
WFE < 0.50 → overfitting en IS
```

| Instrumento | PF IS | PF OOS | WFE | Estado |
|---|---|---|---|---|
| NAS100 | — | — | — | ⏳ |
| SPX500 | — | — | — | ⏳ |
| XAUUSD | — | — | — | ⏳ |
| GBPUSD | — | — | — | ⏳ |
