# Decision Log — Plan $10K FundingPips

## 2026-04-29 · FASE 0 iniciada

- Producto: 2-Step Standard $25K
- Targets: 8% Fase 1 ($2.000) / 5% Fase 2 ($1.250)
- DLL: 5% ($1.250) | MLL: 10% static ($2.500)
- Apalancamiento: Forex 1:100 / Índices y Oro 1:20
- Ciclo payout: Semanal Martes 60%
- Trading de noticias: permitido (no como estrategia primaria)
- Holding fin de semana: permitido
- EAs: permitidos
- Pendiente: fee, fecha de inicio, screenshot dashboard, datos Master Rules
- Referencia: `FundingPips_2026_summary.md`

## 2026-05-20 · FASE 0 cerrada — Reglas Master confirmadas

### Reglas Master verificadas (2-Step Standard $25K)
- **DLL:** Static (no trailing). Floor fijo desde balance inicial.
- **1-Minute Rule:** Existe en Master. Trades < 1 min no cuentan para payout. No aplica en evaluación.
- **Single trade profit cap:** 3% en cuentas < $50K ($750 máx en $25K). No aplica en evaluación.
- **Max loss por trade:** 3% (< $50K). Violación = cierre inmediato.
- **News window:** ±5 min de evento HIGH → profits no cuentan para payout.
- **Consistency rule:** Solo ciclo On Demand (35%). Weekly/Biweekly/Monthly → sin restricción.
- **IP consistency:** Monitoreo de región. Cambio de país requiere verificación.

### Payout — decisión pendiente
- Ciclo actual en documento: Weekly 60%
- **Recomendado:** Monthly 100% — sin consistency rule, máximo capital en cuenta para crecer buffer y acelerar Hot Seat.
- Hot Seat: 16 payouts + 40% profit acumulado → 100% split + capital hasta $2M

### Ajustes risk_manager.mqh pendientes (antes de activar Master)
1. 1-Minute Rule: bloquear cierre < 60s de apertura
2. 3% profit cap por trade: cerrar si profit flotante > $750 (en $25K)
3. Filtro news ±5 min: desactivar entradas en ventana HIGH

### Admin pendiente (requiere datos del usuario)
- Fee + código de descuento
- Fecha de inicio de cuenta
- Screenshot dashboard → `07-Knowledge/10K$/screenshots/`

---

## 2026-04-29 · FASE 2 — Re-auditoría BreakoutNY Portfolio (NAS100 + DJI30 + XAUUSD)

### NAS100 — VIABLE ✅
- PF: 1.794 | Sharpe: 3.60 | Max DD eq: 1.80% | Trades: 86 (5.6/mes)
- Degradación vs OOS 2025 esperada y dentro de rango normal
- EA principal para el challenge $25K

### DJI30 — MARGINAL 🟡
- PF: 1.475 | Sharpe: 5.57 | Max DD eq: 2.09% | Trades: 35 (2.3/mes)
- PF alineado con IS histórico (1.486) — OOS 2025 de 3.04 era outlier
- Mantener en cuenta $5K operativa, no incorporar al challenge hasta más datos 2026

### XAUUSD — VIABLE ✅ (Set E definitivo)
- Problema detectado: backtest inicial usaba parámetros V3 incorrectos → 9 trades
- Sets evaluados: Set E (solo Jue), Set G (solo Jue), Set E + LXJ (Lun+Mie+Jue)
- **Set E elegido** — PF: 3.618 | Sharpe: 23.90 | Max DD eq: 0.85% | Trades: 27
- Razón: edge estructural de Jueves confirmada IS/OOS/WF. Añadir L+X diluye PF -50% sin compensar en riesgo ajustado
- Set G en forward demo paralelo (3 meses) para evaluar MaxSL=16.5
- Referencia: `01-Strategies/BreakoutNY/Analysis/XAUUSD_set_analysis_2026-04-29.md`

### Portfolio combinado
- PF combinado: 1.747 | DD máximo worst-case: 2.75% | Beneficio neto total: $632 sobre $5K
- Frecuencia total: 8.1 trades/mes (NAS100 motor principal)

---

## 2026-04-29 · Decisiones estratégicas portfolio

- **NAS100 shorts:** descartados — sesgo alcista estructural confirmado, operar contra tendencia primaria no compensa
- **GER40:** candidato aprobado para expansión BreakoutNY — backtesting inicia 2026-04-30
- **Balance operativo confirmado:** $4.879 — g_balance_inicial arranca desde este valor en OnInit()

---

## 2026-04-29 · Parámetros de producción confirmados — Cuenta $5K operativa

### Estado de cuenta
- Balance actual: **$4.879** (desde $5.000)
- Causa: operaciones ejecutadas con parámetros incorrectos previo a la auditoría de hoy
- DD realizado: $121 (2.42% del balance original) — dentro del MLL del 10%
- Parámetros ajustados hoy 2026-04-29 a los sets validados IS/OOS

### Parámetros activos por activo

**NAS100** (L+M+V)
- BE_BufferPct=82 | MinSL=35 | MaxSL=120
- FilterMon=true | FilterTue=true | FilterWed=false | FilterThu=false | FilterFri=true
- ATR_FilterEnable=true | ATR_Max=2.0 | ATR_Min=0.5
- RiskAmountUSD=13 | MagicNumber=202401

**DJI30** (M+J+V)
- BE_BufferPct=20 | MinSL=6000 | MaxSL=30000
- FilterMon=false | FilterTue=true | FilterWed=false | FilterThu=true | FilterFri=true
- ATR_FilterEnable=true | ATR_Max=2.0 | ATR_Min=0.3
- RiskAmountUSD=12 | MagicNumber=202402

**XAUUSD Set E** (solo Jueves)
- BE_BufferPct=70 | MinSL=4.5 | MaxSL=13.0 | EntryMaxCandle=0
- FilterMon=false | FilterTue=false | FilterWed=false | FilterThu=true | FilterFri=false
- RiskAmountUSD=16 | ConfirmOnClose=true | MagicNumber=202409

### Parámetros comunes (todos los activos)
- ServerOffsetHours=2 | EntryWindowEnd_Min=15 | ConfirmOnClose=true | EnablePartials=false

---

## 2026-04-29 · SP500 — Evaluación adicional

### SP500 — NO VIABLE ❌
- Versiones analizadas: v1 (L+M+X+V), v2 (L+M+X), v2 Abril (2021-2026)
- OOS v2 Abril: PF=0.889 | Net Profit=-$19.66 | Retención 60.0%
- OOS v2 previo: PF=1.374 | Retención 79.7% — ya era el más bajo del portfolio
- Tendencia retención: 66.9% → 79.7% → 60.0% (negativa)
- Consistente con análisis histórico (chat 088): IS plateau honesto PF=1.24-1.30
- Decisión: SP500 excluido del challenge $25K. Re-evaluar solo con estrategia nueva (ORB/Cascade Gate)
- Referencia: `01-Strategies/BreakoutNY/Analysis/SP500_verdict_2026-04-29.md`

---

## 2026-04-29 · FASE 1 cerrada

- Vault: carpetas Trade-Journal/ y Analysis/ creadas en todas las estrategias
- Git: primer commit (157 archivos) · branches dev/breakout_ny, dev/crt_pro, dev/orb_multi creadas
- Pipeline: 4 scripts centralizados en scripts/ (ingestion, metrics, correlation, dashboard)
- risk_manager.mqh: v1.0 implementado en MQL5/Include/
  - Halt diario al 3% DD (60% del DLL real)
  - Halt total al 6% DD (60% del MLL real)
  - Half-size automático tras 4 losers consecutivos
  - EmergencyClose() con log y halt
- 02-Roadmap/Roadmap.md creado
- Próximo paso: FASE 2 — re-auditoría BreakoutNY

---

## 2026-05-09 · Nueva estrategia — Time Boxed Range (TBR)

### Contexto
CTR Pro fue suspendida (sin edge IS demostrable). El portfolio necesita un segundo edge independiente y escalable. Las estrategias ORB pendientes (ORB London, Cascade Gate, Tres Soldados) están dispersas sin un marco de investigación unificado.

### Decisión
Crear **TBR (Time Boxed Range)** como estrategia marco que unifica toda la investigación ORB bajo un solo EA Universal parametrizable por activo vía `.set`. BreakoutNY se migra a este marco como primera configuración validada.

**Motivación técnica clave:** el EA actual usa unidades absolutas (precio en USD) que no son transferibles entre activos. TBR normaliza todos los filtros en múltiplos de ATR — un solo código compilado funciona en XAUUSD, NAS100, EURUSD o cualquier otro activo.

### Estrategias absorbidas por TBR

| Estrategia anterior | Configuración TBR |
|--------------------|-------------------|
| BreakoutNY (todos los activos) | TBR — NY Open |
| ORB London | TBR — London Open |
| Cascade Gate | TBR — Cascade Gate |
| Tres Soldados | TBR — Tres Soldados |

### Próximas acciones
1. Desarrollar TBR_Universal.mq5 (EA base con ATR normalizado)
2. Iniciar IS NY Open en NAS100 como primera configuración
3. Validar que ATR normalizado reproduce los resultados de BreakoutNY existente

### Repositorio creado
`01-Strategies/TBR/` con estructura completa (Analysis, Backtests, Code, Decisions, etc.)

---

## 2026-04-30 · Decisión estratégica — Prioridad Fase 3 sobre expansión BreakoutNY

### Contexto
Se evaluó si conviene añadir un activo nuevo (GBPUSD) a BreakoutNY antes de validar CTR Pro.

### Análisis
- **BreakoutNY nuevo activo:** requiere IS + OOS + WF completo (semanas de trabajo) para ganar ~4 trades/mes adicionales. Alta correlación con portfolio existente (misma lógica breakout). Edge decay -52% NAS100 / -61% XAUUSD en H2 OOS ya señala fragilidad del sistema.
- **CTR Pro XAUUSD M5:** está en "producción" sin IS/OOS formal documentado para XAUUSD M5. Solo NDX100 tiene validación cuantitativa. Riesgo real: EA corriendo en live sin base estadística completa.

### Decisión
**Fase 3 CTR Pro IS/OOS/WF es prioridad.** Razones:
1. CTR Pro es un sistema de reversión — correlación baja con BreakoutNY (breakout) → diversificación real de edge
2. Validar CTR Pro primero elimina el riesgo de operar un sistema sin respaldo cuantitativo
3. Un activo nuevo en BreakoutNY añade más de lo mismo; CTR Pro añade un segundo edge independiente
4. Búsqueda de activo BreakoutNY adicional **postergada indefinidamente** — se reevalúa solo si CTR Pro no supera IS/OOS

### Próxima acción
Iniciar backtest IS (2018-2021) de CTR Pro XAUUSD M5 con parámetros del `.set` original: SL=840 ticks, TP=1800 ticks, días L+M+X.

---
