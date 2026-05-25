---
type: walkforward-index
strategy: TBR
updated: 2026-05-11
---
[[TBR]]
# Walk-Forward — TBR

Seguimiento walk-forward continuo de cada instrumento del portfolio TBR. Se actualiza cuando hay datos suficientes para un nuevo período (mínimo 30 trades).

---

## Regla de monitoreo

Si un instrumento acumula PF < 0.80 en dos períodos consecutivos → pausar y re-analizar antes de continuar.

---

## Estado actual

| Instrumento | Config | Período WFA | PF | Estado |
|------------|--------|------------|-----|--------|
| NAS100 | P63 L/M/X | 2026-01-05 / 2026-05-06 | 1.422 | **VIABLE (6/6)** |
| XAUUSD | P1 #7129 | 2026-01-01 / 2026-05-11 | 0.849 | **FALLA — régimen hostil** |

---

## Archivos

```
WalkForward/
├── NAS100/
│   └── WFA_NAS100_2026_P63_LMX.md     ← VIABLE 6/6
└── XAUUSD/
    └── WFA_XAUUSD_P1_2026.md           ← FALLA régimen hostil — esperar Q3 2026
```

---

## Próximos pasos

| Instrumento | Acción | Fecha |
|------------|--------|-------|
| NAS100 P63 | Actualizar WFA con datos Q2-Q3 2026 | Julio 2026 |
| XAUUSD P1 | Re-evaluar tras Q3 2026 (mín. 30 trades adicionales) | Octubre 2026 |
