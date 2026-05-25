---
type: magic-number-registry
strategy: TBR
updated: 2026-05-23
---

# Control de Magic Numbers — TBR v1.1

Registro central de Magic Numbers para todos los sets activos del EA TBR.
**Regla:** un Magic Number no puede reutilizarse. Asignar secuencialmente. Nunca modificar un número ya en producción.

---

## Mapa de TradeDirection en el EA

> **CRITICO:** El enum del EA difiere de la convención intuida. Usar siempre estos valores:

| Valor | Constante EA | Comportamiento |
|-------|-------------|---------------|
| `0`   | `DIR_BOTH`  | Long + Short (bidireccional) |
| `1`   | `DIR_BUY`   | Solo Long |
| `2`   | `DIR_SELL`  | Solo Short |

---

## Registry completo

| MagicNumber | Instrumento | Pass / Config | Dir | RR | Range | Sesion (srv) | Estado | Set File |
|------------|-------------|--------------|-----|----|-------|--------------|--------|----------|
| **202501** | NAS100 | P63 LMX | 1 BUY | 4.0 | 2 | 14:15 | ✅ Desplegando (live) | `NAS100/TBR_v1.1_NAS100_P63_LMX.set` |
| **202502** | XAUUSD | P1 #7129 | 0 BOTH | 3.6 | 3 | 14:45 | ⏳ Esperar Q3 2026 | `XAUUSD/TBR_v1.1_XAUUSD_P1.set` |
| **202503** | NAS100 | P58421 LONG | 1 BUY | 5.8 | 4 | — | ⏳ Pendiente demo | `NAS100/TBR_v1.0b_NAS100_P58421_LONG.set` |
| **202504** | — | reservado | — | — | — | — | — | — |
| **202505** | SPX500 | P187 noJV | 1 BUY | 3.5 | 2 | 14:15 | ✅ Desplegando (live) | `SPX500/TBR_v1.1_SPX500_P187_noJV.set` |
| **202506** | GBPUSD | P958 nL | 1 BUY | 4.5 | 3 | 14:30 | ⏳ Demo condicional (balance ≥$4,900) | `GBPUSD/TBR_v1.1_GBPUSD_P958_nL.set` |
| **202507** | USDJPY | P7389 | 0 BOTH | 3.0 | 6 | 03:50 | ⏳ En espera — WFA negativo (0.970), re-evaluar Q3 2026 | `Optimizacion/USDJPY/Sets/TBR_USDJPY_P7389.set` |
| **202508** | USDJPY | P5458 | 1 BUY | 2.5 | 6 | 02:35 | ⏳ Demo — VIABLE 10/10 (activar) | `Optimizacion/USDJPY/Sets/TBR_USDJPY_P5458.set` |
| **202509** | GBPJPY | P121378 | 1 BUY | 3.0 | 6 | 09:00 | ⏳ Pendiente demo | `Optimizacion/GBPJPY/Sets/TBR_GBPJPY_P121378.set` |
| **202510** | GBPJPY | P110836 | 1 BUY | 2.5 | 6 | 08:55 | ⏳ Pendiente demo | `Optimizacion/GBPJPY/Sets/TBR_GBPJPY_P110836.set` |

**Próximo disponible: 202511**

---

## Notas operativas por instrumento

### NAS100
- 202501 activo en live. 202503 pendiente — NO activar los dos simultáneamente sin análisis de correlación.

### SPX500
- 202505 activo en live junto con NAS100 (corr=+0.478, monitorear).

### XAUUSD
- 202502 en espera: WFA 2026 negativo. Reactivar Q3 2026 si régimen cambia.

### GBPUSD
- 202506 demo condicional: activar cuando balance FundingPips ≥ $4,900.

### USDJPY
- **202508 (P5458):** VIABLE 10/10 — activar en demo. BUY, RR=2.5, 02:35srv. WFA=1.170, degradación IS→OOS casi cero.
- **202507 (P7389):** MARGINAL 9/10 — WFA negativo (0.970). En espera. Re-evaluar Q3 2026 o backtest BUY-only con sus parámetros.

### GBPJPY
- **202509 (P121378):** primera meseta 09:00. PF OOS=1.744, WFA=0.918 (negativo 2026).
- **202510 (P110836):** segunda meseta 08:55. PF OOS=1.759, WFA=1.333 (positivo 2026).
- Ambas mantenidas para variar portafolios. Timing casi idéntico (5 min) — correlación probablemente alta.
- P110836 es el pass superior en WFA y DD — usar como primario.

---

## Números usados por otros EAs (NO reutilizar)

| MagicNumber | EA | Instrumento | Estado |
|------------|-----|-------------|--------|
| 202401 | BreakoutNY | NAS100 | Producción |
| 202402 | BreakoutNY | DJI30 | Producción |
| 202409 | BreakoutNY | XAUUSD | Producción |
| 20250404 | ORB | EURUSD | Demo |

---

## Reglas de asignación

1. Nuevo candidato TBR → siguiente número disponible (actualmente 202511)
2. Nunca reciclar un MN de un set descartado → marcarlo como INACTIVO en este registro
3. Antes de activar en demo: verificar que el MN no esté corriendo en otra terminal MT5
4. Documentar fecha de activación en la columna Estado
