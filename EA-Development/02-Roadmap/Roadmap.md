# Roadmap — Meta $10K NET/mes · FundingPips

## Estado actual — 2026-05-20
- Fase 0: ✅ cerrada 2026-05-20 — reglas Master confirmadas, payout Monthly 100% recomendado, ajustes risk_manager pendientes para Master
- Fase 1: ✅ cerrada 2026-04-29
- Fase 2: ✅ cerrada 2026-04-29 — NAS100 VIABLE, DJI30 MARGINAL, XAUUSD VIABLE (Set E Jue)
- Fase 3: ❌ CTR Pro suspendida (sin edge IS con muestra suficiente) — Fase absorbida por Fase 8
- Fase 4: 🟡 TBR NAS100+SPX500 live desde 2026-05-11. Balance $4,844 / Floor $4,500 / Buffer $344
- Fase 8: 🟡 TBR en progreso — NAS100+SPX500 live, GBPUSD condicional (espera balance ≥ $4,900), XAUUSD espera Q3 2026

## Mapa de fases

| # | Fase | Duración estimada | Estado |
|---|------|-------------------|--------|
| 0 | Verificación de reglas FundingPips | 1 día | ✅ Cerrada 2026-05-20 |
| 1 | Setup entorno (Vault, Git, Pipeline, risk_manager) | 1 día | ✅ Cerrada 2026-04-29 |
| 2 | Auditoría BreakoutNY (re-validación OOS) | 3 días | ✅ Cerrada 2026-04-29 |
| 3 | Validación CRT Pro (IS/OOS/WF) | 5-7 días | ❌ Suspendida — sin edge IS |
| 4 | Forward demo EAs activos (90 días paralelo) | Continuo | 🟡 TBR NAS100 en demo desde 2026-05-11 |
| 5 | Challenge Fase 1: +8% ($25K → $27K) | 2-4 semanas | ⬜ Pendiente |
| 6 | Challenge Fase 2: +5% | 2-4 semanas | ⬜ Pendiente |
| 7 | Primer ciclo Master + payout | 14 días | ⬜ Pendiente |
| 8 | TBR: EA Universal ORB — NAS100+XAUUSD+GBPUSD | 4-6 semanas | 🟡 Sets definidos, NAS100 en demo, otros en espera Q3 2026 |
| 9 | 2do y 3er payout bi-weekly | 1 mes | ⬜ Pendiente |
| 10 | Apertura cuenta evaluación #2 | 1 día | ⬜ Pendiente |
| 11 | Escalado 4 cuentas Master + matriz multi-EA | 2-3 meses | ⬜ Pendiente |
| 12 | Hot Seat o Monthly 100% → $10K NET/mes | M9-M12 | ⬜ Pendiente |

## KPIs objetivo

| Mes | Cuentas Master | Capital agregado | NET objetivo/mes |
|-----|---------------|-----------------|-----------------|
| M4 | 1 + 1 eval | $25K | $1.500 - $2.500 |
| M5 | 2 + 1 eval | $50K | $3.000 - $5.000 |
| M6 | 3-4 | $75K-$125K | $5.000 - $8.000 |
| M7 | 4 | $125K-$200K | $7.000 - $10.000 |

## EAs en portfolio

| EA | Activo | Status | Veredicto |
|----|--------|--------|-----------|
| BreakoutNY NAS100 | NAS100 | Producción | ✅ VIABLE — PF 1.794, DD 1.80% OOS |
| BreakoutNY DJI30 | DJI30 | Producción ($5K) | 🟡 MARGINAL — PF 1.475, monitorear |
| BreakoutNY XAUUSD | XAUUSD | Producción ($5K) | ✅ VIABLE — Set E Jue, PF 3.618 |
| BreakoutNY SP500 | SP500 | ❌ Descartado | NO VIABLE — OOS PF=0.889 |
| CTR Pro | XAUUSD | ❌ Suspendida | Sin edge IS con muestra suficiente |
| CTR Reclaim | NDX100 | Development | v3.8 pendiente backtest |
| Donchian | EURUSD | Forward testing | Pendiente veredicto |
| **TBR v1.1 — NAS100 P63** | NAS100 | 🟢 Demo (desde 2026-05-11) | ✅ VIABLE IS/OOS/WFA — DD max 6.22% IS / 2.54% WFA — Magic 202501 |
| **TBR v1.1 — XAUUSD P1** | XAUUSD | ⏳ Esperar Q3 2026 | ⚠️ IS/OOS ok — WFA 2026 FALLA (PF=0.840, DD=9.38%) — Magic 202502 |
| **TBR v1.1 — GBPUSD P958 nL** | GBPUSD | ⏳ Demo condicional | ⚠️ IS/OOS ok — WFA 2026 FALLA (PF=0.823, DD=3.60%) — Magic 202504 |
| TBR — London Open | EURUSD, GBPUSD | 🔬 Investigación | Pendiente |
| TBR — Cascade Gate | NAS100, SP500 | 🔬 Investigación | Pendiente |
| TBR — Tres Soldados | US30 | 🔬 Investigación | Pendiente |

## TBR — Sets de producción definidos (2026-05-17)

| Instrumento | Pass | EA | MagicNumber | Set file | DD Max histórico |
|-------------|------|----|-------------|----------|-----------------|
| NAS100 | P63 Lun+Mar+Mié | TBR_v1.1 | 202501 | ✅ Sets-Produccion/NAS100/ | IS=6.22% / OOS=2.77% / WFA=2.54% |
| XAUUSD | P1 todos los días | TBR_v1.1 | 202502 | ✅ Sets-Produccion/XAUUSD/ | IS=8.44% / OOS=1.93% / WFA=9.38% ⚠️ |
| GBPUSD | P958 sin Lunes | TBR_v1.1 | 202504 | ❌ Pendiente crear archivo | IS=5.35% / OOS=3.48% / WFA=3.60% |

**Parámetros críticos compartidos:** `UseBreakeven=false` (edge timeout-based en XAU y GBP), `RiskAmountUSD=12.5`, `ServerOffsetHours=2`

## TBR — Análisis portfolio para fondeo (2026-05-17)

**Veredicto: NO correr los 3 sets juntos en fondeo en este momento.**

Razones:
- XAUUSD WFA 2026 DD = 9.38% → margen de 0.62% sobre el límite FundingPips (10%). Riesgo de eliminación en régimen adverso continuo.
- GBPUSD WFA 2026 PF = 0.823 → en pérdida en lo que va de 2026.
- Trades simultáneos en ventana NYSE pueden generar DD aditivo en días de eventos macro.

**Ruta de incorporación gradual:**
1. **Ahora:** Solo NAS100 P63 — cuando complete demo sin violar criterios de parada (DD>6%/mes o WR<32% en 3 meses).
2. **Q3 2026 (jul–sep):** Revisar XAUUSD P1. Si PF recupera >1.4 en período reciente → agregar.
3. **Q3 2026:** Revisar GBPUSD P958. Si WR >40% y PF >1.2 en 3 meses → agregar.
4. **Sizing portfolio completo:** Reducir a 0.5% por instrumento para que 3 SLs simultáneos no superen 2% DD diario.

## TBR — Versionado del EA (aclaración 2026-05-17)

| Versión | Fecha | Cambio clave |
|---------|-------|--------------|
| v1.1 original | 2026-05-09 | Fix RiskPct → RiskAmountUSD + CloseAfterHours |
| v1.2 | 2026-05-09 | Bug fix MODE_CONFIRM post-SessionEnd |
| v1.3 | 2026-05-10 | Bug fix lot con SL_dist real |
| v1.4 | 2026-05-10 | Bug fix VPP ($20 no $0.20) |
| v1.0b | 2026-05-10 | Ideas 4 (BE_TriggerRR) + 5 (GapFilter) — versión estable |
| **v1.1 actual** | **2026-05-14** | **Ideas 6+7+8 (RangeFilter, ATRFilter, EntryWindow) — filtros opcionales desactivados por defecto** |

**Base para producción: TBR_v1.1.mq5** (incluye todos los fixes + filtros desactivados = comportamiento idéntico a v1.0b)
