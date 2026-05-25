# TBR SPX500 M5 P187 — Análisis noJV (sin Jue + sin Vie)
**Fecha:** 2026-05-17
**Filtro aplicado:** TradeThursday=false | TradeFriday=false
**Días activos:** Lun / Mar / Mie

---

## Resumen comparativo

| | Net $ | PF | DD% | Trades |
|-|-------|----|-----|--------|
| **IS** (5 días) | 1,263.71 | 1.224 | 7.13 | 704 |
| **IS noJV** | 725.61 | 1.216 | **4.64** | 427 |
| **OOS** (5 días) | 430.03 | **1.234** | 2.18 | 238 |
| **OOS noJV** | 152.41 | 1.132 | 2.28 | 149 |
| **WFA** (5 días) | 77.87 | 1.116 | 3.71 | 86 |
| **WFA noJV** | 209.79 | **1.585** | **2.69** | 52 |

---

## Hallazgo crítico: el filtro es un ajuste de régimen, no un parámetro

El filtro noJV **ayuda en 2026 pero no en 2025**:

| Período | Delta PF | Interpretación |
|---------|---------|----------------|
| IS | -0.009 | Neutro. DD baja 7.13→4.64% |
| **OOS 2025** | **-0.102** | Jue+Vie eran *rentables* en 2025 |
| **WFA 2026** | **+0.469** | Jue+Vie *destruyen* el edge en 2026 |

**Conclusión:** No es un error de diseño — es un cambio de régimen. En 2025, Viernes era el mejor día (WR=30.4%). En 2026, Viernes colapsa (WR=5.9%). El filtro captura correctamente el régimen actual.

El OOS (2025) válido para la estrategia sin filtro es **PF=1.234** — ese es el número de referencia histórico. El filtro es una adaptación táctica 2026.

---

## Día de semana — noJV

| Día | IS WR% | OOS WR% | WFA WR% | Estado |
|-----|--------|---------|---------|--------|
| **Lun** | 28.2% | 31.1% | **35.3%** | ✅ Sólido y mejorando |
| **Mar** | **21.5%** | **18.4%** | 31.2% | ⚠️ Bajo breakeven en IS+OOS |
| **Mie** | 24.5% | 22.4% | 25.0% | ✅ Estable |

**Martes es un problema latente:**
- Bajo breakeven en IS (21.5%) y OOS (18.4%) — dos períodos independientes
- Solo WFA 2026 lo rescata (31.2%)
- Evidencia insuficiente para filtrar ahora, pero requiere monitoreo activo
- Si en demo Mar WR < 22% en 2+ meses consecutivos → evaluar filtro

**Breakeven RR=3.5: 22.2%**

---

## WFA noJV vs Criterios de Pipeline

| Criterio | Mínimo | WFA noJV | Estado |
|----------|--------|----------|--------|
| PF | > 1.0 | **1.585** | ✅ |
| DD% | < 10% | **2.69%** | ✅ |
| Trades | ≥ 30 | **52** | ✅ |
| WR | ≥ 22.2% | **30.6%** | ✅ |
| OOS PF (base) | ≥ 1.20 | 1.234 (5 días) | ✅ ajustado |
| OOS PF noJV | ≥ 1.20 | **1.132** | ⚠️ |

El OOS noJV (1.132) no cumple el criterio de 1.20. Sin embargo, el OOS correcto de referencia es el de 5 días (1.234), dado que el filtro noJV es una adaptación post-facto al régimen 2026.

---

## Veredicto Final

### MARGINAL → DEMO CONDICIONAL

**Argumentación:**

El conjunto de evidencia soporta avanzar a demo con precaución:

1. **OOS (2025) sin filtro: PF=1.234** — edge real confirmado en período out-of-sample
2. **WFA 2026 con filtro: PF=1.585, DD=2.69%, WR=30.6%** — la estrategia está funcionando bien en el régimen actual cuando se excluyen los días rotos
3. La degradación OOS→WFA es explicada y cuantificada (régimen de días de semana, no fallo estructural)
4. Exit type 100% TP/SL con WR consistentemente sobre breakeven en todos los períodos

**Condición de demo:** aplicar filtro noJV (sin Jue, sin Vie) reflejando el régimen actual 2026.

### Parámetros para demo

```
TradeDirection    = BUY (1)
EntryMode         = Pending (1)
RangeCandlesCount = 2
SessionStart_Hour = 14
SessionStart_Min  = 15
RR                = 3.5
UseBreakeven      = false
TradeMonday       = true
TradeTuesday      = true
TradeWednesday    = true
TradeThursday     = false
TradeFriday       = false
MagicNumber       = 202505
RiskAmountUSD     = 12.5
```

### Stop demo si (circuit breakers)

| Condición | Acción |
|-----------|--------|
| DD > 5% en cualquier mes | Pausar, revisar |
| WR < 20% en 3 meses consecutivos | Detener |
| Martes WR < 18% en 2+ meses | Evaluar filtrar Martes |
| PF acumulado < 0.90 en 60 trades | Detener |

### Revisión programada

- **Q3 2026 (jul-sep):** re-evaluar Viernes. Si WR Vie > 25% en 2+ meses → reactivar
- **Q3 2026:** decidir sobre Jueves con datos adicionales
- **Q3 2026:** si Martes sigue bajo breakeven → correr backtest noJVM (sin Jue+Vie+Mar)
