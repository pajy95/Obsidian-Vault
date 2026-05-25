# Code — CTR Pro

[[Strategy - CTR Pro]]

Archivos de código fuente MQL5 (`.mq5`) y compilados (`.ex5`) para CTR Pro. La estrategia opera con una vela clave fija a las 8:45 AM NY, sweep del High/Low y reclaim dentro del rango.

---

## Estructura de archivos

```
Code/
├── CTR_Pro_EA.mq5                  ← ⭐ PRODUCCIÓN XAUUSD M5
├── CTR_Reclaim_v3_7.mq5            ← NDX100 M10, IS+OOS validado
├── CTR_Reclaim_v3_8.mq5            ← NDX100 M10, WFA params (en construcción)
├── CTR_Reclaim_v3_1.mq5            ← NDX100, SL/TP v2.2 corregido (archivado)
├── CTR_Reclaim_v3_0.mq5            ← NDX100, SL×10 — DESCARTADO (archivado)
├── CTR_Reclaim_v2_3_GBPUSD.mq5    ← GBPUSD, solo Martes (archivado)
└── CTR_Reclaim_v2_2.mq5            ← NDX100, PF=1.31, referencia histórica
```

> Los fuentes en producción residen también en `Source/Experts/` (directorio de compilación MT5).

---

## CTR_Pro_EA.mq5 ⭐ ACTIVO

EA de producción para XAUUSD M5. 700 líneas MQL5. Dashboard interactivo + visual signals.

**Lógica de detección (`DetectLiquiditySweep()`):**
- BUY: `low[1] < low[2]` AND `close[1] > low[2]` → mínimo barrido con recuperación
- SELL: `high[1] > high[2]` AND `close[1] < high[2]` → máximo barrido con rechazo

**Visualización por señal:**
- Flecha de entrada (verde BUY / naranja SELL) + label "CTR ENTRY"
- Líneas horizontales: TP (verde), SL (rojo), Entry (punteada)
- `InpMaxDrawings` controla cuántos setups quedan visibles

**Dashboard:**
- Estado sistema (Activo/Inactivo/Pausado) | Spread en tiempo real
- P/L diario acumulado | Contador de operaciones
- Botones: "Cerrar Todo", "Cerrar +$" (solo ganancias), "Pausar/Reanudar"

**Filtros en cascada:** día de semana → sesión horaria → trades diarios → spread → nueva barra → patrón de sweep

**Parámetros clave producción XAUUSD:**

| Parámetro | Valor |
|-----------|-------|
| InpSL_Pips | 30 |
| InpTP_Pips | 60 |
| InpRiskUSD | 50 |
| InpMaxPerDay | 1 |
| InpMaxSpread | 30 pts |
| InpStartHour | 8 |
| InpEndHour | 17 |

**⚠️ Riesgo compliance:** Hold time típico < 8 min — verificar regla 2 min mínimo de FundingPips.

---

## CTR_Reclaim_v3_7.mq5 — IS+OOS Validado

NDX100 M10. WFA 4.806 combinaciones completado. Degradación OOS: -30.2% (aceptable).

- NY_Hour=8 | NY_Minute=40 | TP=690 | EnableBreakeven=true | MN=3700

---

## CTR_Reclaim_v3_8.mq5 — EN CONSTRUCCIÓN

NDX100 M10. Parámetros WFA aplicados. Pendiente finalizar 4 cambios:

| Cambio | v3.7 | v3.8 |
|--------|------|------|
| NY_Minute | 40 | **30** |
| TP_ticks | 690 | **925** |
| EnableBreakeven | true | **false** |
| MagicNumber | 3700 | **3800** |

---

## Versiones archivadas

| Versión | Activo | Motivo de archivo |
|---------|--------|-------------------|
| v2.2 | NDX100 | Bug lotaje 100×, data gap 2023, referencia histórica |
| v2.3 GBPUSD | GBPUSD | Solo Martes, AutoSafeMode — base para futuro |
| v3.0 | NDX100 | SL×10 destruye edge — WR cae a 25.8% < breakeven |
| v3.1 | NDX100 | Re-introduce data gap bug de v2.2 |

---

## Compilación

```
metaeditor64.exe /compile:"ruta\al\archivo.mq5"
```

MetaTrader 5 instalado en: `C:\Program Files\MetaTrader 5\`

---

## Arquitectura común

| Componente | Descripción |
|---|---|
| Vela clave | Una sola vela: 8:45 AM NY (configurable por GMT offset) |
| Niveles de referencia | HIGH y LOW de esa vela específica |
| Señal BUY | Vela siguiente rompe bajo el LOW y cierra sobre el LOW (reclaim) |
| Señal SELL | Vela siguiente rompe sobre el HIGH y cierra bajo el HIGH (reclaim) |
| Re-entries | No — una sola operación por día |
| Hold time | < 8 minutos en condiciones normales (micro-scalp) |
| Sizing | RiskUSD / (SL_distance × ValuePerPoint) |
