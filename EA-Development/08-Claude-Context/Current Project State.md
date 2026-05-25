# Current Project State
Última actualización: 2026-05-10

---

## Sesión 2026-04-30 — Decisión estratégica Fase 3

### Completado
- **Decisión documentada:** CTR Pro IS/OOS/WF es prioridad sobre expansión BreakoutNY
- **GER40:** cerrado definitivamente — descartado por historial 18% en FundingPips
- **Nuevo activo BreakoutNY (GBPUSD u otro):** postergado indefinidamente
- **Razón:** CTR Pro añade edge independiente (reversión vs breakout) con correlación baja; un activo nuevo BreakoutNY añade más de lo mismo con alta correlación y semanas de trabajo por ~4 trades/mes
- **Riesgo identificado:** CTR Pro XAUUSD M5 corre en producción sin IS/OOS formal — Fase 3 cierra ese riesgo

### Próxima sesión
Iniciar IS formal CTR Pro XAUUSD M5 (2018-2021): SL=840 ticks, TP=1800 ticks, días L+M+X

---

## Sesión 2026-04-29 — Auditoría completa portfolio + Monte Carlo

### Completado
- **FASE 1 cerrada:** Vault, Git, pipeline Python, risk_manager.mqh v1.0
- **FASE 2 cerrada:** Re-auditoría BreakoutNY OOS 2025-2026 (NAS100 + DJI30 + XAUUSD + SP500)
- **Parámetros de producción cargados** en cuenta operativa $5K (balance actual: $4.879)
- **Monte Carlo + Robustez** sobre portfolio OOS real (10.000 simulaciones)
- **GER40** aprobado como candidato — backtesting inicia 2026-04-30
- **Carpeta GER40 creada:** `01-Strategies/BreakoutNY/Backtests/GER40/`

### Veredictos OOS 2025-2026

| Activo | PF OOS | DD eq | Retención | Veredicto |
|--------|--------|-------|-----------|-----------|
| NAS100 v1 (L+M+V) | 1.794 | 1.80% | — | ✅ VIABLE |
| DJI30 v1 (M+J+V) | 1.475 | 2.09% | — | 🟡 MARGINAL |
| XAUUSD Set E (solo Jue) | 3.618 | 0.85% | 180.7% | ✅ VIABLE |
| SP500 v2 Abril | 0.889 | 1.87% | 60.0% | ❌ NO VIABLE — descartado |

### Parámetros de producción — cuenta $5K

| Activo | Risk | BE | MinSL | MaxSL | Días | Magic |
|--------|------|----|-------|-------|------|-------|
| NAS100 | $13 | 82 | 35 | 120 | L+M+V | 202401 |
| DJI30 | $12 | 20 | 6000 | 30000 | M+J+V | 202402 |
| XAUUSD Set E | $16 | 70 | 4.5 | 13.0 | solo Jue | 202409 |

Comunes: ServerOffsetHours=2 | EntryWindowEnd_Min=15 | ConfirmOnClose=true | EnablePartials=false | ATR_FilterEnable=true

### Monte Carlo — resultados clave (10.000 sim, OOS real)

**Portfolio combinado OOS:** 148 trades | 9.2/mes | Expectancy $4.34 | PF 1.931 | WR 46.6%

**Cuenta $5K operativa:**
- Bust: 0.0% | DD p95: 4.24% | DD p99: 5.42%

**Challenge $25K (escala x5):**

| Escenario | P(Fase 1) | P(F1+F2) | Tiempo hasta Master | Bust |
|-----------|-----------|----------|---------------------|------|
| Base (histórico) | 99.8% | 97.3% | 12.7 meses | 0.0% |
| Conservador (-20%) | 99.2% | 92.0% | 15.3 meses | 0.0% |
| Pesimista (-40%) | 96.9% | 68.4% | 18.4 meses | 0.0% |

**Escenario más realista dado Edge Decay observado:** Conservador → ~92%, ~15 meses.

### Robustez — señales críticas

| Activo | PF H1 OOS | PF H2 OOS | Decay |
|--------|-----------|-----------|-------|
| NAS100 | 2.581 | 1.228 | ⚠️ -52.4% |
| XAUUSD | 6.047 | 2.338 | ⚠️ -61.3% |
| DJI30 | 1.336 | 1.738 | ✅ +30.1% |

El Edge Decay en NAS100 y XAUUSD indica que el PF real actual es más cercano a 1.3–1.5 que al 1.93 total. Las simulaciones conservadoras son las más relevantes.

### Decisiones estratégicas tomadas hoy
- NAS100 shorts: descartados permanentemente
- SP500 BreakoutNY: descartado definitivamente
- GER40: aprobado para backtesting — driver similar a NAS100 (apertura NY, sesgo alcista)
- risk_manager.mqh: g_balance_inicial desde $4.879 (confirmado)

### Scripts disponibles en `scripts/`
| Script | Función |
|--------|---------|
| `portfolio_montecarlo.py` | Monte Carlo + robustez + análisis challenge (NUEVO) |
| `sp500_analysis.py` | Comparativa IS/OOS SP500 todas las versiones |
| `compare_is_oos.py` | IS vs OOS XAUUSD sets |
| `analyze_backtest.py` | Métricas individuales desde CSV MT5 |

---

## Sesión 2026-04-28

### Completado
- **BreakoutNY_Universal_FP.mq5** creado y compilado (0 errores)
  - `ENUM_TRADE_DIRECTION`: Solo Longs / Solo Shorts / Ambas
  - `ENUM_ENTRY_MODEL`: Confirmación al cierre de vela M5 / Ruptura directa
  - Visual histórico completo, prefijo VIS_PFX dinámico por símbolo
  - ATR filter, filtros de día, parciales en TP1 y TP2 opcionales

---

## Sesión 2026-05-10 — TBR NAS100 M3 — Edge confirmado (T10)

### Completado
- **10 tests ejecutados** sobre TBR_v1 NAS100 M3
- **3 bugs críticos identificados y corregidos** en el EA:
  - v1.2: MODE_CONFIRM post-SessionEnd (72% trades fuera de sesión)
  - v1.3: Lot calculado con rango bruto, SL real 2x mayor → riesgo 3.5x
  - v1.4: VPP = $0.20 en lugar de $20 (división /100 de más en OrderCalcProfit)
- **T10 — primer test MARGINAL:** PF=1.405, DD=3.42%, todos los años positivos
- **Comparación NR vs TBR:** NR usa RiskPercent=0.25% compounding; TBR usa RiskAmountUSD fijo. Modos equivalentes: ambos MODE_BREAKOUT (buy stop)
- **Desglose IS/OOS T10:** IS PF=1.412 ✓ | OOS PF=1.285 ✗ | OOS/IS=91% ✓ | DD OOS=3.70% ✓

### Veredicto T10
**MARGINAL** — edge real confirmado. OOS PF=1.285 bajo umbral mínimo 1.40.
Con WR=31% y RR=3.0 el PF matemático máximo es ~1.35 — para llegar a 1.40 se necesita optimizar.

### Próxima acción TBR
Optimizar RR y filtro de días para mejorar OOS PF ≥ 1.40:
1. Probar RR=2.0 y 2.5 (WR puede subir al reducir TP)
2. Aislar Miércoles (IS PF~1.55 vs Lunes/Viernes más débiles)
3. Subir calidad ticks a 99% para confirmar

### Archivos actualizados
- `01-Strategies/TBR/TBR.md` — overview completo con historial de tests
- `01-Strategies/TBR/Decisions/TBR_NAS100_T10_Analysis.md` — veredicto T10
- `01-Strategies/TBR/Code/TBR_v1.mq5` — v1.4 compilada
- `memory/project_tbr_state.md` — estado actualizado

---

## Próximas prioridades

1. **TBR NAS100 — optimización RR/días** para llevar OOS PF a ≥ 1.40
2. **Fase 3 — CTR Pro IS/OOS/WF:** PRIORIDAD ACTIVA — iniciar backtest IS (2018-2021) XAUUSD M5
3. **Fase 0 pendiente:** fee, fecha inicio cuenta, screenshot dashboard, Master Rules
4. ~~GER40 backtesting~~ — descartado definitivamente (historial 18% en FundingPips)
5. ~~Nuevo activo BreakoutNY~~ — postergado indefinidamente (decisión 2026-04-30)

## Estado de fases

| Fase | Estado |
|------|--------|
| 0 — Verificación reglas FundingPips | 🟡 Iniciada (pendiente datos administrativos) |
| 1 — Setup entorno | ✅ Cerrada 2026-04-29 |
| 2 — Auditoría BreakoutNY | ✅ Cerrada 2026-04-29 |
| 3 — Validación CTR Pro | ⬜ Pendiente |
| 4+ — Challenge y escalado | ⬜ Pendiente |

## EAs en desarrollo activo

| EA | Activo | Status | Nota |
|----|--------|--------|------|
| BreakoutNY NAS100 | NAS100 | Production ($5K) | Parámetros v1 activos |
| BreakoutNY DJI30 | DJI30 | Production ($5K) | MARGINAL — monitorear |
| BreakoutNY XAUUSD | XAUUSD | Production ($5K) | Set E — solo Jueves |
| BreakoutNY GER40 | GER40 | ❌ Descartado | Historial 18% en FundingPips |
| BreakoutNY SP500 | SP500 | ❌ Descartado | OOS PF=0.889 |
| BreakoutNY Universal | NAS100/DJI30/XAUUSD | Testing | EA único compilado |
| CTR Pro | XAUUSD | En validación | Fase 3 pendiente |
| CTR Reclaim | XAUUSD | Development | Pendiente |
| ORB | EURUSD / SPX / US30 | Development | Pendiente |
| Donchian v1.1 | EURUSD | Forward testing | Circuit breaker removido |
| Cascade Gate | NAS100/SP500 | Development | Pendiente |
| Tres Soldados | US30 | Development | Pendiente |

## Issues abiertos
- Ninguno
