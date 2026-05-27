# Chat 115 — TBR Reportes-Validacion: Bug Fix Parser + Estados 2026-05-26

## Contexto
Continuación de Chat 114. Script `tbr_reportes_estandar.py` ya creado con 40 gráficos (5 por 8 instrumentos), pero con valores de PF incorrectos por bug en el parser.

## Bug corregido — `parse_trades()`

**Síntomas:** NAS100 IS PF=2.754 (esperado ~1.275), DJI30 IS PF=2.588 (esperado 1.556), GBPJPY IS PF=4.379 (esperado 1.250).

**Causa raíz — dos errores combinados:**
1. `abs(p) < 50000` incluía filas de balance/resumen del reporte MT5 → cambio a `abs(p) < 5000`
2. `col_map.get('Profit', 10)` fallback al índice 10 (columna Balance) → reemplazado por búsqueda robusta: primer key donde `'Profit' in k AND 'Factor' not in k AND 'Gross' not in k`

**Fix aplicado en `parse_trades()`:**
```python
profit_col = None
# al encontrar header:
for k in col_map:
    if 'Profit' in k and 'Factor' not in k and 'Gross' not in k:
        profit_col = k; break
# al leer trades:
p_key  = profit_col if profit_col else 'Profit'
profit = row[col_map[p_key]] if p_key in col_map else None
if abs(p) < 5000 and t:  # era 50000
```

## Resultados verificados post-fix

| Instrumento | IS PF | OOS PF | WFA PF |
|-------------|-------|--------|--------|
| NAS100 P63 | 1.275 | 1.588 | 1.080 |
| SPX500 P187 | 1.216 | 1.132 | 1.585 |
| SPX500 P12538 | 1.708 | 1.601 | 1.279 |
| DJI30 P11944 | 1.556 | 2.419 | 1.340 |
| GBPJPY P110836 | 1.250 | 1.759 | 1.333 |
| USDJPY P5458 | 1.378 | 1.387 | 1.170 |
| GBPUSD P958 | 1.241 | 1.744 | 0.925 |
| XAUUSD P1 | 1.214 | 1.606 | 0.849 |

40 gráficos regenerados en `Reportes-Validacion/{SYMBOL}/`.

## Actualización de estados

**Corrección:** Ningún set TBR está actualmente en cuenta live. Todos son DEMO.

| Cambio | Antes | Después |
|--------|-------|---------|
| NAS100 P63 | LIVE | DEMO |
| SPX500 P187 | LIVE | DEMO |
| DJI30 P11944 | EN CUENTA | DEMO |

Actualizado en `tbr_reportes_estandar.py` y en memoria `strategy_tbr.md`.

## Pendientes

- **GBPUSD Londres** — analizar cuando termine la optimización
- **SPX500 P12538** — activar demo cuando haya cuenta disponible
- **CADJPY / NZDJPY** — siguiente tras GBPUSD-L
