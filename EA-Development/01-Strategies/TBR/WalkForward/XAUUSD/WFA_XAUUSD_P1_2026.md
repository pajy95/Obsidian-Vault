---
type: walkforward-result
strategy: TBR
asset: XAUUSD
config: P1 #7129
period: 2026-01-01 / 2026-05-11
status: FALLA — régimen hostil
validated: 2026-05-11
---
[[TBR]]
# Walk-Forward XAUUSD — P1 #7129 — 2026

## Resultado

**FALLA (régimen hostil)** — PF=0.849 | WR=5.5% | Net=-$136 | MaxDD=8.73% | n=91

## Contexto histórico

| Período | PF trimestral (rango) | Promedio |
|---------|----------------------|---------|
| IS 2022-2024 | 0.684 – 1.741 | 1.136 |
| OOS 2025 | 1.351 – 1.891 | 1.606 |
| **WFA 2026** | **~0.744 promedio** | — |

El mínimo histórico IS/OOS fue 0.684 (2024 Q2). El WFA 2026 promedia 0.744 — dentro del rango de variación observada. No es evidencia definitiva de cambio estructural permanente.

## Análisis por dirección

| Dirección | n | PF | WR | Net |
|-----------|---|----|----|-----|
| LONG | ~45 | 0.374 | ~3% | negativo |
| SHORT | ~46 | 1.438 | ~8% | positivo |

**Patrón claro**: LONG roto, SHORT funciona. El problema no es el sistema sino el régimen del instrumento en LONG.

## Hipótesis del régimen hostil

2026 — incertidumbre macro/política global (tarifas, geopolítica) genera reversiones frecuentes en los breakouts alcistas del oro. Los movimientos al alza de XAU tienden a revertir dentro de la sesión. Los movimientos bajistas (shorts) se mantienen con mayor continuidad.

Esto es consistente con:
- Volatilidad intradía elevada
- Lunes siendo el peor día en 2026 (mayor gap overnight / incertidumbre de apertura semanal)
- WFA P2 con patrón idéntico (LONG roto, SHORT funciona)

## Acción definida

**Esperar Q3 2026** para evaluar con datos adicionales:

| Escenario | Acción |
|-----------|--------|
| SHORT mantiene PF > 1.20, LONG sigue roto | Evaluar DIR_SELL temporal con nueva optimización |
| Ambos se recuperan | Activar P1 en demo con DIR_BOTH |
| Ambos permanecen rotos | Esperar y re-evaluar en Q4 2026 |

## Nota sobre comparación P1 vs P2

| Métrica WFA 2026 | P1 | P2 |
|------------------|----|----|
| PF total | 0.849 | 0.843 |
| Dentro de rango histórico | **Sí** | No |
| Trades | 91 | 53 |

P1 permanece como el pass preferido incluso con WFA en falla — tiene más trades y su comportamiento 2026 es estadísticamente menos atípico respecto a su historia.

## Archivo de backtest

`Backtests/XAUUSD/WFA_TBR_XAUUSD_P1_2026.xlsx`
