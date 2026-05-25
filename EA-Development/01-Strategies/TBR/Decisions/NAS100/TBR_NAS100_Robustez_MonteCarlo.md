---
type: decision-log
strategy: TBR
asset: NAS100
config: P63 L/M/X
fecha: 2026-05-11
veredicto: PIPELINE COMPLETO — EN DEMO
---

# Robustez y Monte Carlo — NAS100 P63 L/M/X

## Robustez Paramétrica

### Plateau de RR (Candles=2, Min=15 fijos)

| RR | FwdPF | Estado |
|---|---|---|
| 2.8 | 1.240 | ~ |
| 3.2 | 1.230 | ~ |
| 3.6 | 1.310 | OK |
| 3.8 | 1.310 | OK |
| **4.0** | **1.350** | **OK ← P63** |

Plateau confirmado en RR=3.6-4.0. Tres valores consecutivos con FwdPF≥1.31.

### SessionStart_Min — PICO, no plateau

| Min | FwdPF |
|---|---|
| 0 | 1.010 |
| **15** | **1.350 ← P63** |
| 25 | 1.030 |
| 35 | 1.000 |

Min=15 es un pico aislado. Sin vecinos con FwdPF competitivo. **Riesgo de sobreajuste en este parámetro.** Mitigado por OOS/WFA que confirman el edge en datos no vistos.

### Ranking global

- P63 es el **pass #1 de 152** (FwdPF más alto)
- Solo el 5% de passes alcanza FwdPF≥1.20
- Concentración de rendimiento en Min=15 + Candles=2

### Veredicto robustez — PLATEAU 3/4

| Criterio | Estado |
|---|---|
| ≥30% passes con FwdPF≥1.20 | 5% ❌ |
| P63 FwdPF ≥ 1.30 | 1.350 ✅ |
| P63 BackPF ≥ 1.00 | 1.240 ✅ |
| ≥3 passes en ±15% de P63 | 15 passes ✅ |

## Monte Carlo (10,000 iteraciones)

| Métrica | Resultado |
|---|---|
| P(ruin DD≥10%) | **0.05%** |
| P(Net>0) en 1 año | **97.3%** |
| P5 Net (pesimista) | **+$73** |
| P95 MaxDD | **5.6%** |
| Racha SL P95 | 19 trades (-$192 / 3.8% cuenta) |

**Veredicto MC: VIABLE (4/4)**

## Conclusión integrada

La estrategia pasa Monte Carlo con excelencia (P ruin = 0.05%) pero muestra señales de pico en SessionStart_Min. Esto se contrarresta con:

1. OOS 2025 PF=1.498 — **mejor que el período de optimización** (FwdPF=1.350). Si fuera overfitting, OOS sería peor.
2. WFA 2026 PF=1.422 — el edge persiste en datos completamente fuera del proceso de optimización.
3. El plateau de RR (3.6-4.0) confirma que no es un pico de parámetro único.

**PIPELINE COMPLETO:**
IS → OOS → WFA → Monte Carlo → Robustez → **DEMO** ✅
