# Code — BreakoutNY

[[Strategy - BreakoutNY]]

Archivos de código fuente MQL5 (`.mq5`) y compilados (`.ex5`) para cada activo del portfolio BreakoutNY. Todos los EAs comparten la misma arquitectura base: rango de 3 velas M5 en apertura NY, breakout por cierre, sizing USD-based, sin martingala.

---

## Estructura de archivos

```
Code/
├── BreakoutNY_Universal_FP.mq5      ← ⭐ EA UNIVERSAL (NAS100/DJI30/SP500/XAUUSD)
├── BreakoutNY_Universal_FP.ex5      ← compilado Universal (2026-04-28)
├── Breakout NY XAU V9 FP.mq5        ← fuente XAUUSD (legacy)
├── BreakoutNY_NAS100_FP.mq5         ← fuente NAS100 (legacy)
├── BreakoutNY_NAS100_FP.ex5         ← compilado NAS100 (legacy)
├── BreakoutNY_v1_DJI30_FP.mq5      ← fuente DJI30 (legacy)
├── BreakoutNY_v1_DJI30_FP.ex5      ← compilado DJI30 (legacy)
├── BreakoutNY_v1_SP500_FP.mq5      ← fuente SP500 (legacy)
└── BreakoutNY_v1_SP500_FP.ex5      ← compilado SP500 (legacy)
```

---

## Archivos

### BreakoutNY_Universal_FP.mq5 ⭐ ACTIVO
EA universal compilado el 2026-04-28. Reemplaza los 4 EAs individuales — un solo archivo para todos los activos, configurado mediante inputs.

**Features:**
- `TradeDirection`: Solo Longs / Solo Shorts / Ambas
- `EntryModel`: Confirmación al cierre de vela M5 / Ruptura directa (primer tick)
- Visual histórico completo — punto de entrada coincide con modelo activo
- Prefijo VIS_PFX dinámico por símbolo (sin colisión entre instancias simultáneas)
- ATR filter, filtros de día reagrupados, parciales en TP1 y TP2

**Defaults por activo:**

| Activo | MinSL | MaxSL | SessionClose UTC | BE% | Días filtrados |
|--------|-------|-------|-----------------|-----|----------------|
| NAS100 | 25 | 50 | 17:00 | 20 | Lun, Mié |
| DJI30 | 8200 | 20000 | 17:00 | 50 | Mié |
| SP500 | 400 | 1550 | 21:00 | 130 | Mié |
| XAUUSD | 550 | 1500 | 17:00 | 100 | Mar, Vie |

- **MagicNumber recomendado:** NAS100=202401 · DJI30=202402 · SP500=202403 · XAUUSD=202409
- **Status:** 🔬 Testing — en validación, los EAs legacy siguen en producción

---

### Breakout NY XAU V9 FP.mq5
Código fuente del EA para XAUUSD en FundingPips. Versión 9 — incluye lógica de BE_BufferPct, filtros de día de semana, ConfirmOnClose, y sizing USD-based vía OrderCalcProfit.

- **Activo:** XAUUSD
- **MagicNumber:** 202401
- **Set activo:** ThuOnly v2 — ver `Sets-Produccion/XAUUSD_ThuOnly_v2.md`
- **Compilado:** no disponible en esta carpeta — compilar desde MetaEditor

### BreakoutNY_NAS100_FP.mq5
Código fuente del EA para NAS100 en FundingPips. Incluye parámetro FilterShorts para desactivar posiciones cortas (obligatorio en producción).

- **Activo:** NAS100
- **Set activo:** MonTueFri v1 — ver `Sets-Produccion/NAS100_MonTueFri_v1.md`
- **⚠️ Crítico:** FilterShorts=true obligatorio en producción

### BreakoutNY_NAS100_FP.ex5
Compilado listo para instalar en MetaTrader 5. Corresponde al fuente `BreakoutNY_NAS100_FP.mq5`.

### BreakoutNY_v1_DJI30_FP.mq5
Código fuente del EA para DJI30/US30 en FundingPips. Versión 1 — arquitectura base compartida con NAS100, parámetros específicos para DJI30 (TickValue=5.0 USD/tick).

- **Activo:** DJI30 (símbolo puede ser US30, DJ30H o DJI30 según broker)
- **MagicNumber:** 202402
- **Set activo:** TueThuFri v1 — ver `Sets-Produccion/DJI30_TueThuFri_v1.md`

### BreakoutNY_v1_DJI30_FP.ex5
Compilado listo para instalar en MetaTrader 5. Corresponde al fuente `BreakoutNY_v1_DJI30_FP.mq5`.

### BreakoutNY_v1_SP500_FP.mq5
Código fuente del EA para SP500 en FundingPips. Versión 1 — incluye ATR filter (ATR_FilterEnable, ATR_Period, ATR_MaxMultiplier, ATR_MinMultiplier, ATR_BaselineDays) para descartar días de volatilidad extrema.

- **Activo:** SP500 (símbolo puede ser SPX500, SP500 o US500 según broker)
- **MagicNumber:** 202403
- **Set activo:** MonTueWed v2 — ver `Sets-Produccion/SP500_MonTueWed_v2.md`
- **Estado:** 🔬 Demo — no operar en cuenta prop hasta julio 2026

### BreakoutNY_v1_SP500_FP.ex5
Compilado listo para instalar en MetaTrader 5. Corresponde al fuente `BreakoutNY_v1_SP500_FP.mq5`.

---

## Compilación

Para recompilar cualquier fuente:

```
metaeditor64.exe /compile:"ruta\al\archivo.mq5"
```

MetaTrader 5 instalado en: `C:\Program Files\MetaTrader 5\`

---

## Arquitectura común

| Componente | Descripción |
|---|---|
| Rango de referencia | High/Low de 3 velas M5: 14:35, 14:40, 14:45 UTC |
| Señal de entrada | Cierre por encima del High (BUY) o por debajo del Low (SELL) |
| Ventana de entrada | 14:50 UTC → 15:15 UTC — una operación por día máximo |
| Filtro de rango | SL debe estar dentro de [MinSL_Points, MaxSL_Points] |
| ConfirmOnClose | Siempre true — breakout confirmado solo en cierre de vela M5 |
| Break-even | BE_BufferPct — SL se mueve a entrada cuando precio recorre X% hacia TP |
| Cierre forzado | SessionCloseHour — cierre automático de posición abierta al final de sesión |
| Sizing | RiskAmountUSD / (slDistance × valuePerPoint) — calculado con OrderCalcProfit |
