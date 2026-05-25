---
type: decision
strategy: TBR
asset: XAUUSD
pass: P2
pass_num: 2603
veredicto: MARGINAL
validated: 2026-05-11
pipeline: IS/OOS completado — WFA falla — DESCARTADO
---
[[TBR]]
# Decisión IS/OOS — XAUUSD P2 #2603

## Veredicto: MARGINAL (4/5) — DESCARTADO

## Parámetros del pass

| Parámetro | Valor |
|-----------|-------|
| RangeCandlesCount | 8 |
| SessionStart_Min | 25 |
| RR | 2.8 |
| TradeDirection | DIR_BOTH (Long + Short) |
| Días activos | Lun–Vie (todos) |

## Por qué fue analizado

P2 fue identificado como alternativa a P1 por:

1. **Robustez de meseta**: Min=25 tiene vecinos viables (Min=20 PF=1.209, Min=30 PF=1.296 en IS). P1 (Min=45) es más un pico local sin vecinos fuertes.
2. **PF IS aceptable**: 1.283 (vs 1.214 de P1) — ligeramente superior en IS.
3. **Diferentes parámetros**: Candles=8 vs 3, Min=25 vs 45 — sesiones operativas distintas (14:25 vs 14:45 UTC). Baja correlación esperada.

## Resultados

| Período | n | PF real | WR (TP+SL) | Net | MaxDD |
|---------|---|---------|------------|-----|-------|
| **IS 2022-2024** | **473** | **1.283** | 10.6% | **+$678** | — |
| **OOS 2025** | **91** | **1.374** | 17.6% | **+$249** | — |
| WFA 2026 | 53 | 0.843 | 5.7% | -$68 | — |

## Criterios de viabilidad

| Criterio | Umbral | OOS 2025 | Estado |
|----------|--------|----------|--------|
| PF OOS ≥ 1.40 | ≥ 1.40 | 1.374 | ❌ (falla por 0.03) |
| Max DD OOS ≤ 10% | ≤ 10% | — | ✅ |
| Trades OOS ≥ 30 | ≥ 30 | 91 | ✅ |
| OOS/IS ratio ≥ 50% | ≥ 50% | 106.8% | ✅ |
| Net OOS > 0 | > 0 | +$249 | ✅ |

**Falla un criterio**: PF OOS = 1.374 < 1.40. Veredicto MARGINAL.

## Análisis de régimen — Por qué se descarta

El WFA 2026 de P2 es más preocupante que el de P1:

| Métrica | P1 | P2 |
|---------|----|----|
| WFA 2026 PF | 0.849 | 0.843 |
| WFA 2026 trimestral mínimo histórico (IS/OOS) | 0.684 | 0.835 |
| WFA 2026 promedio trimestral | 0.744 | ~0.75 |
| Dentro de rango histórico | Sí (0.744 > 0.684) | **No** (0.75 < 0.835) |

Para P2, el rendimiento de 2026 **es peor que cualquier trimestre histórico** en IS/OOS. Esto sugiere mayor sensibilidad al cambio de régimen que P1.

**Patrón 2026 — Dirección rota (similar a P1):**

| Dirección | WFA 2026 PF |
|-----------|------------|
| LONG | 0.605 — roto |
| SHORT | 1.134 — funciona |

## Decisión final

- **DESCARTADO** como candidato de producción.
- Motivos: (1) PF OOS falla por 0.03, (2) WFA 2026 fuera de rango histórico, (3) P1 es superior en todos los criterios donde ambos compiten.
- No reanalizar a menos que P1 sea definitivamente descartado por cambio estructural confirmado post-Q3 2026.

## Lección del análisis

**Error crítico del parser (DEAL vs ORDER format):** El primer análisis de P2 arrojó IS Net=-$2,377 (catastrófico). La causa fue usar el parser heredado de NAS100 que filtraba con `col[6]=='0'` (formato ORDER). En XAUUSD, los backtests MT5 usan filas DEAL donde col[4]='in'/'out' y col[10] contiene el P&L real. El resultado correcto es IS Net=+$678.

Ver `scripts/tbr_xau_p2_analisis.py` (función `parse_deal`) para la implementación correcta.

## Archivos de referencia

- `Backtests/XAUUSD/is_tbr_xauusd_p2_2022-2024.xlsx`
- `Backtests/XAUUSD/OOS_TBR_XAU_P2_2025.xlsx`
- `Backtests/XAUUSD/WFA_TBR_XAU_P2_2026.xlsx`
- `Optimizacion/XAUUSD/TBR_V1B_OP_XAUUSD_M5.xml` — pass #2603
- `scripts/tbr_xau_p2_analisis.py`
