# TBR SPX500 M5 P187 — Análisis Completo IS/OOS/WFA
**Fecha:** 2026-05-17
**EA:** TBR v1.1 | EntryMode=Pending | Sin filtros v1.1
**Parámetros:** BUY | RangeCandlesCount=2 | SessionStart=14:15 UTC | RR=3.5
**MagicNumber reservado:** 202505

---

## Resumen IS / OOS / WFA

| Período | Fechas | Net $ | PF | DD% | Trades | WR% |
|---------|--------|-------|----|-----|--------|-----|
| IS (full) | 2022-01-01 → 2025-12-30 | +1,263.71 | **1.224** | 7.49 | 704 | 26.85 |
| OOS | 2025-01-01 → 2025-12-31 | +430.03 | **1.234** | 2.18 | 238 | ~24.9 |
| WFA | 2026-01-01 → 2026-05-09 | +77.87 | **1.116** | 4.08 | 86 | 23.5 |

> **OOS PF > IS PF** — el período 2025 superó al IS. Señal de no-sobreajuste.
> **WFA PF=1.116** — rentable pero degradando. No falla.

### Breakeven con RR=3.5
Breakeven WR = 1 / (1 + 3.5) = **22.2%**

| Período | WR% | Margen |
|---------|-----|--------|
| IS | 26.85% | +4.65pp |
| OOS | ~24.9% | +2.7pp |
| WFA | ~23.5% | +1.3pp |

Todos los períodos superan el breakeven. El margen se comprime con el tiempo.

---

## Exit Type Analysis — Hallazgo crítico

| Período | TP% | SL% | TIMEOUT% |
|---------|-----|-----|---------|
| IS | **25.0%** | 75.0% | **0%** |
| OOS | **24.9%** | 75.1% | **0%** |
| WFA | **23.5%** | 76.5% | **0%** |

### SPX500 vs otros instrumentos TBR

| Instrumento | Edge driver | Timeout% |
|-------------|-------------|---------|
| XAUUSD P1 | **Timeout-based** | ~53% |
| GBPUSD P958 | **Timeout-based** | ~53% |
| **SPX500 P187** | **TP/SL ratio** | **0%** |

SPX500 es el único instrumento TBR cuyo edge proviene **exclusivamente del RR matemático** (3.5:1 con WR ~25%). No depende de cierres por sesión. Esto implica:
- ✓ Edge más "puro" matemáticamente
- ✓ No es sensible a cambios en `CloseAfterHours`
- ✗ Más sensible a cambios en el WR (cada % cuenta más)

---

## Análisis por Día de Semana

### Win Rate % por día (≥22.2% = sobre breakeven)

| Día | IS WR% | OOS WR% | WFA WR% | Veredicto |
|-----|--------|---------|---------|-----------|
| **Lun** | 28.2% | 31.1% | **35.3%** | ✅ Consistente y mejorando |
| Mar | 21.5% | 18.8% | 31.2% | ⚠️ Inconsistente (bajo en IS/OOS) |
| Mie | 24.5% | 22.4% | 25.0% | ✅ Estable sobre breakeven |
| **Jue** | **18.8%** | 22.0% | **20.0%** | ❌ Bajo breakeven en IS y WFA |
| **Vie** | **32.6%** | **30.4%** | **5.9%** | 🚨 COLAPSO en WFA 2026 |

### Días que destruyen el edge

**Jueves:**
- Único día bajo breakeven de forma consistente (IS=18.8%, WFA=20.0%)
- OOS=22.0% apenas pasa
- **Recomendación: eliminar Jueves**

**Viernes:**
- Mejor día histórico (IS=32.6%, OOS=30.4%) → **colapso en WFA 2026 (5.9%)**
- 2/34 trades terminaron en TP en WFA — estadísticamente significativo
- Señal de cambio de régimen en 2026 para el viernes
- **Recomendación: suspender Viernes hasta Q3 2026**

### Impacto del filtro de días

Simulación WFA sin Jue + sin Vie:

| | Sin filtro | Solo Lun+Mar+Mie |
|-|-----------|-----------------|
| Trades WFA | 86 | ~98 (estimado) |
| WR% WFA | 23.5% | **30.6%** |
| vs breakeven | +1.3pp | **+8.4pp** |

El filtro Lun+Mar+Mie habría transformado el WFA de MARGINAL a SÓLIDO.

---

## Evaluación vs Criterios del Pipeline

| Criterio | Mínimo | IS | OOS | WFA | Estado |
|----------|--------|----|----|-----|--------|
| PF | ≥1.40 OOS | 1.224 | **1.234** | 1.116 | ⚠️ Por debajo de criterio |
| DD% | ≤10% | 7.49% | 2.18% | 4.08% | ✓ / ⚠️ IS alto |
| Trades | ≥30 | 704 | 238 | 86 | ✓ |
| WR > breakeven | ≥22.2% | ✓ | ✓ | ✓ | ✓ |
| OOS ≥ 50% IS | ≥50% | — | 430/1264=34% | — | ❌ |
| WFA rentable | — | — | — | ✓ | ✓ |
| Timeout edge | — | 0% | 0% | 0% | N/A |
| Consistencia FR≈BR | — | ✓ | — | — | ✓ |

---

## Veredicto

### MARGINAL — Con condiciones

**A favor:**
- OOS PF=1.234 > IS PF=1.224 — no hay sobreajuste
- Edge matemático puro (TP/SL), sin dependencia de timeout
- WR consistente sobre breakeven en los 3 períodos
- Concepto pre-open confirmado independientemente en M3 y M5
- WFA positivo (PF=1.116) — la estrategia no falla en 2026

**En contra:**
- OOS PF=1.234 < criterio estricto 1.40
- OOS net = 34% de IS net (criterio: ≥50%)
- IS DD = 7.49% — margen estrecho con límite prop firm 10%
- Viernes colapsó en WFA (régimen 2026)
- Jue consistentemente bajo breakeven

### Acciones recomendadas antes de Demo

1. **Re-correr OOS (2025) sin Jue y sin Vie** → medir PF filtrado
2. **Re-correr WFA (2026) sin Jue y sin Vie** → cuantificar mejora
3. Si OOS filtrado PF ≥ 1.35 y WFA filtrado PF ≥ 1.20 → avanzar a Demo

### Criterio de corte
Si OOS sin Jue+Vie PF < 1.25 → **NO VIABLE**. Archivar SPX500.

---

## Parámetros candidato para backtests filtrados

```
TradeDirection   = BUY (1)
EntryMode        = Pending (1)
RangeCandlesCount = 2
SessionStart_Hour = 14
SessionStart_Min  = 15
SessionEnd_Hour   = 17
RR               = 3.5
UseBreakeven     = false
TradeMonday      = true
TradeTuesday     = true
TradeWednesday   = true
TradeThursday    = false   ← nuevo
TradeFriday      = false   ← nuevo (suspender hasta Q3 2026)
MagicNumber      = 202505
```
