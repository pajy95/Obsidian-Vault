# Trade Journal — CTR Pro

[[Strategy - CTR Pro]]

Registro de operaciones reales en cuenta operativa. Actualizar semanalmente con reportes MT5.

```
Trade-Journal/
├── Trade-Journal.md     ← este índice
└── [reportes mensuales pending]
```

---

## Estado

| Activo | Cuenta | Inicio WF | Trades registrados |
|--------|--------|-----------|-------------------|
| XAUUSD M5 | FundingPips $5K | — | Pendiente primer reporte |

---

## Formato de reporte mensual

Depositar reportes MT5 (Statement) con el formato:
```
CTRPro_XAUUSD_[YYYY-MM].xlsx
```

## Métricas a registrar por mes

| Métrica | Descripción |
|---------|-------------|
| Trades | Total operaciones ejecutadas |
| Win Rate | % operaciones ganadoras |
| PF mensual | Profit Factor del mes |
| Net P/L | Ganancia/pérdida neta en USD |
| DD máx diario | Mayor drawdown diario registrado |
| Hold time promedio | Tiempo promedio por trade (verificar > 2 min) |

## Regla de parada

Si PF acumulado WF cae por debajo de **1.20** con ≥ 30 trades reales → pausar y re-evaluar parámetros.
