# 111 — TBR XAUUSD IS/OOS P1 P2 — Análisis y Parámetros Producción
**Fecha:** 2026-05-11  
**EA:** TBR_v1.0b.mq5  
**Instrumento:** XAUUSD  
**Sesión:** Análisis IS/OOS/WFA P1 (#7129) y P2 (#2603), régimen 2026, sets de producción

---

## Resumen de la sesión

### Punto de partida
P2 (Pass #2603: Candles=8, Min=25, RR=2.8) había sido identificado como candidato alternativo en la sesión previa. Se solicitó análisis formal IS/OOS/WFA con hipótesis de régimen atípico 2026.

### Hallazgo crítico — Parser DEAL vs ORDER

El primer análisis de P2 arrojó resultados catastró ficos (IS Net=-$2,377, PF=0.264). Causa: el parser heredado de NAS100 usaba `col[6]=='0'` para filtrar exits — formato ORDER. Los reportes MT5 de XAUUSD usan formato DEAL donde:
- `col[4]='in'` → entrada
- `col[4]='out'` → salida  
- `col[10]` → P&L real efectivo

Resultado corregido: IS Net=+$678, PF=1.283.

**Insight derivado — timeout trades como motor de rentabilidad:**
- Los cierres de sesión (timeout) tienen P&L real positivo porque el breakout direcciona correctamente aunque no alcance el TP
- IS timeout net: +$1,718 / OOS timeout net: +$998
- PF(TP+SL) puro: ~0.49 — el edge NO está en el TP

### Veredictos finales

| Pass | IS PF | OOS PF | Criterios | WFA 2026 | Veredicto |
|------|-------|--------|-----------|----------|-----------|
| P1 #7129 | 1.214 | 1.606 | 5/5 | 0.849 (falla) | **VIABLE IS/OOS** |
| P2 #2603 | 1.283 | 1.374 | 4/5 | 0.843 (falla) | **MARGINAL — descartado** |

### Análisis de régimen 2026

Ambos passes muestran el mismo patrón en 2026:
- LONG roto: P1 PF=0.374, P2 PF=0.605
- SHORT funciona: P1 PF=1.438, P2 PF=1.134

Hipótesis: incertidumbre macro/política 2026 genera reversiones en breakouts alcistas del oro. El WFA 2026 de P1 (promedio trimestral 0.744) está dentro del rango histórico (mínimo 0.684 en 2024 Q2). El de P2 no (mínimo histórico 0.835).

Acción: esperar Q3 2026 para confirmar si es régimen transitorio.

### Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `Sets-Produccion/NAS100/TBR_v1.0b_NAS100_P63_LMX.set` | Set MT5 NAS100 producción |
| `Sets-Produccion/XAUUSD/TBR_v1.0b_XAUUSD_P1.set` | Set MT5 XAUUSD P1 |
| `Sets-Produccion/XAUUSD/TBR_v1.0b_XAUUSD_P1.md` | Documentación completa P1 |
| `scripts/tbr_xau_p2_analisis.py` | Script análisis IS/OOS/WFA con parser DEAL correcto |
| `01-Strategies/TBR/TBR.md` | Reescrito completo — refleja estado actual |
| `Decisions/XAUUSD/TBR_XAUUSD_P1_IS_OOS_Analysis.md` | Decisión formal P1 |
| `Decisions/XAUUSD/TBR_XAUUSD_P2_Analysis.md` | Decisión formal P2 |
| `WalkForward/XAUUSD/WFA_XAUUSD_P1_2026.md` | WFA P1 2026 |

### Estado del portfolio TBR al cierre de sesión

| Instrumento | Pass | Estado | Acción |
|------------|------|--------|--------|
| NAS100 | P63 L/M/X | EN DEMO (WFA 6/6) | Monitorear |
| XAUUSD | P1 #7129 | VIABLE IS/OOS, WFA falla | Esperar Q3 2026 |
| XAUUSD | P2 #2603 | MARGINAL — descartado | — |

---

## Parámetros de producción definidos

### NAS100 — P63 L/M/X

| Parámetro | Valor |
|-----------|-------|
| TradeDirection | 1 (DIR_BUY) |
| RangeCandlesCount | 2 |
| SessionStart_Hour | 14 UTC |
| SessionStart_Min | 15 |
| RR | 4.0 |
| Días activos | Lun + Mar + Mié |
| MagicNumber | 202501 |

### XAUUSD — P1 #7129

| Parámetro | Valor |
|-----------|-------|
| TradeDirection | 0 (DIR_BOTH) |
| RangeCandlesCount | 3 |
| SessionStart_Hour | 14 UTC |
| SessionStart_Min | 45 |
| RR | 3.6 |
| UseBreakeven | false |
| Días activos | Lun–Vie |
| MagicNumber | 202502 |
