# Chat 113 — TBR: DJI30 Pipeline Completo · EURUSD Exploratorio · Repositorio
**Fecha:** 2026-05-25
**Sesiones:** 1 (continuación de contexto comprimido del Chat 112)

---

## Resumen ejecutivo

Sesión de análisis de DJI30 (pipeline completo 12/12, decisión EN CUENTA) y evaluación exploratoria de EURUSD. Se completó la organización del repositorio creando todas las carpetas faltantes por instrumento. Se identificó y corrigió un error conceptual sobre el split Bck/Fwd del optimizador MT5.

---

## Corrección conceptual clave — Bck/Fwd en MT5

**Error diagnosticado:** En sesiones anteriores se asumió que Forward Result y Back Result eran dos mitades iguales del mismo período de optimización.

**Corrección:** Cuando MT5 corre una optimización con Forward Period activado:
- **Back Result = IS** (período de optimización configurado por el usuario)
- **Forward Result = OOS** (forward period configurado por el usuario)
- El **título del XML** muestra el rango COMBINADO (IS + OOS)

Esto aplica a todos los XMLs de optimización del portafolio TBR.

---

## EURUSD Exploratorio — Re-evaluación correcta

**Archivo:** `TBR_v1.1_EURUSD_M5_2025_London-NY_Hr11-15_EXPLORATORIO.xml`
- Renombrado desde versión anterior para reflejar sesión cubierta
- Período real: **2025.01.01-2025.12.31** — solo 1 año
- Bck = IS (primera mitad 2025, ~6 meses)
- Fwd = OOS (segunda mitad 2025)

**Hallazgos:**

| Métrica | Valor |
|---------|-------|
| Passes totales | 24,192 |
| Mediana Bck(IS) | 0.92–0.97 en todas las horas (< 1.0) |
| PF>=1.20 | 177 (0.73%) |
| Passes Bck>=1.05 AND Fwd>=1.10 | 44 |

**Cluster identificado:** BUY Hr=14:10-14:20srv, Range=2-3, RR=3.5-4.5, BE=0.60-0.80
- Mejor pass: P269914 PF=1.258, Bck=1.06, Fwd=1.26, DD=3.55%

**Conclusión:** IS de solo 6 meses — edge marginal. Necesita optimización IS=2022-2024 (full IS) para pipeline formal.

**Parámetros para próxima optimización:**
```
Periodo IS:     2022.01.01 – 2024.12.31
Forward period: 2025.01.01 – 2025.12.31
Horas:          SessionStart_Hour = 7 a 16 (optimizar)
Minutos:        SessionStart_Min = 0-55
Range:          2-8
RR:             1.5-4.5
Dir:            0, 1, 2
MaxHold:        2h, 3h, 4h
BE_Trigger:     0.20, 0.40, 0.60, 0.80
SessionEnd:     18 srv
Total passes:   ~17,640
```

---

## DJI30 — Pipeline COMPLETO (12/12) → EN CUENTA

### Configuración P11944
- **Dir:** BUY | **Hr:** 14:25 srv (12:25 UTC) | **Range:** 1 | **RR:** 4.5 | **BE:** 0.20 | **Hold:** 2h
- **Magic Number:** 202512
- **SessionStart_Hour:** 14 (confirmado por usuario)

### Heatmap (4,838 passes, IS=Bck 2022-2024, OOS=Fwd 2025)

| Cluster | Característica |
|---------|---------------|
| BUY Hr=14:20-14:25srv | Dominante — top 15 passes aquí |
| Range=1-2 | Rango de 1-2 velas = entrada precisa |
| RR=3.5-4.5 BE=0.20 | BE bajo = no interferir con edge |
| Bck(IS) top passes | 1.41-1.48 — excelente IS |

### Resultados pipeline

| Fase | n | PF | WR | DD | Estado |
|------|---|----|----|-----|--------|
| IS 2022-2024 | 904* | **1.556** | 53.8% | 5.87% | ✅ |
| OOS 2025 | 227 | **2.419** | 61.2% | 1.81% | ✅ |
| WFA 2026 | 83 | **1.340** | 45.8% | 4.75% | ✅ |

*IS incluye datos de 2021 (backtest arrancó desde 2021-01)

### Score 12/12

| Criterio | Resultado |
|----------|-----------|
| IS PF >= 1.10 | PF=1.556 ✅ |
| OOS PF >= 1.10 | PF=2.419 ✅ |
| OOS DD <= 10% | DD=1.81% ✅ |
| OOS n >= 100 | n=227 ✅ |
| Perm IS p < 0.05 | p=0.0000 SOLIDO ✅ |
| Perm OOS p < 0.05 | p=0.0000 SOLIDO ✅ |
| Stress IS PF >= 1.0 | PF=1.339 ✅ |
| Stress OOS PF >= 1.0 | PF=2.082 ✅ |
| MC IS P(profit) > 90% | 100% ✅ |
| MC OOS P(profit) > 90% | 100% ✅ |
| MC IS P(ruina) < 2% | 0.00% ✅ |
| MC OOS P(ruina) < 2% | 0.00% ✅ |

### WFA mensual 2026 (alerta)

| Mes | PF | WR | Net |
|-----|----|----|-----|
| Ene 2026 | 2.632 | 61.1% | +$132 |
| Feb 2026 | 3.445 | 60.0% | +$227 |
| Mar 2026 | 0.734 | 35.0% | -$38 |
| Abr 2026 | 0.319 | 40.0% | -$93 |
| May 2026 | 0.000 | 0.0% | -$56 |

Mar-May en drawdown — mismo patrón que otros instrumentos en 2026. Circuit breaker: parar si DD>5%/mes o WR<30% en 2 meses consecutivos.

### Set file
`Sets-Produccion/DJI30/TBR_v1.1_DJI30_P11944.set` | **Magic: 202512**

---

## Repositorio — Carpetas creadas

Todas las carpetas faltantes por instrumento creadas en esta sesión:

| Carpeta | Instrumentos nuevos |
|---------|-------------------|
| `Backtests/` | DJI30 |
| `Optimizacion/*/Sets/` | DJI30, EURUSD |
| `WalkForward/` | DJI30, EURUSD, GBPJPY, USDJPY, GBPUSD, SPX500, AUDJPY |
| `Sets-Produccion/` | DJI30, EURUSD, GBPJPY, USDJPY |

---

## Estado portfolio TBR al 2026-05-25

| Instrumento | Pass | Magic | Estado | Fase |
|-------------|------|-------|--------|------|
| **NAS100** | P63 LMX | 202501 | ✅ LIVE | 1 |
| **SPX500** | P187 noJV | 202505 | ✅ LIVE | 1 |
| **DJI30** | P11944 | 202512 | ✅ EN CUENTA | 2 |
| **GBPUSD** | P958 nL | 202506 | ⏳ Demo condicional (bal≥$4,900) | 2 |
| **XAUUSD** | P1 #7129 | 202502 | ⏳ Q3 2026 | 3 |
| **GBPJPY** | P110836 | 202510 | ⏳ Demo | 2 |
| **USDJPY** | P5458 | 202508 | ⏳ Demo | 2 |
| USDJPY | P7389 | 202507 | ⏳ En espera Q3 2026 (WFA neg) | — |
| GBPJPY | P121378 | 202509 | ⏳ Archivado (corr=0.89) | — |
| — | RBR | 202511 | ⏳ EA pendiente codificación | — |

---

## Próximos pasos

1. **EURUSD** — correr optimización IS=2022-2024 completa (Hr=7-16srv)
2. **GBPUSD Londres** — optimización Hr=7-13srv pendiente
3. **Set file DJI30** — crear `TBR_v1.1_DJI30_P11944.set` para producción
4. **Circuit breaker DJI30** — monitorear WFA: parar si DD>5%/mes

---

## Archivos generados esta sesión

| Archivo | Tipo |
|---------|------|
| `C:/Users/JOSE YANEZ/tbr_dji30_heatmap.py` | Heatmap DJI30 |
| `C:/Users/JOSE YANEZ/tbr_dji30_pipeline.py` | Pipeline completo DJI30 |
| `C:/Users/JOSE YANEZ/tbr_eurusd_heatmap.py` | Heatmap EURUSD exploratorio |
| `Analisis-MonteCarlo/DJI30/DJI30_Heatmap_Min_Range.png` | Gráfica heatmap |
| `Analisis-MonteCarlo/DJI30/DJI30_Heatmap_RR_BE.png` | Gráfica heatmap |
| `Analisis-MonteCarlo/DJI30/DJI30_P11944_Pipeline.png` | Gráfica pipeline |
| `Analisis-MonteCarlo/EURUSD/EURUSD_Heatmap_Hr_Min.png` | Gráfica heatmap |
| `Analisis-MonteCarlo/EURUSD/EURUSD_Heatmap_RR_Range.png` | Gráfica heatmap |
| `Backtests/DJI30/IS_TBR_DJI30_M5_P11944_2022-2024.xlsx` | Backtest IS |
| `Backtests/DJI30/OOS_TBR_DJI30_M5_P11944_2025.xlsx` | Backtest OOS |
| `WalkForward/DJI30/WFA_TBR_DJI30_M5_P11944_2026.xlsx` | WFA |
| `Sets-Produccion/CONTROL_MagicNumbers.md` | Actualizado: 202511 RBR, 202512 DJI30 |
| `Optimizacion/EURUSD/TBR_v1.1_EURUSD_M5_2025_London-NY_Hr11-15_EXPLORATORIO.xml` | Renombrado |
