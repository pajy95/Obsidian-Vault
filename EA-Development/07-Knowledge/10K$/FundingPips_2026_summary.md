# FundingPips 2026 — Reglas de la Cuenta

## Tabla de Reglas — Evaluación (2-Step Standard $25K)

| Parámetro | Valor |
|-----------|-------|
| Producto exacto | 2-Step Standard |
| Tamaño de cuenta | $25.000 |
| Profit target Fase 1 | 8% = $2.000 |
| Profit target Fase 2 | 5% = $1.250 |
| Daily Loss Limit (DLL) | 5% = $1.250 (static, sobre balance/equity del día anterior — el mayor) |
| Max Loss Limit (MLL) | 10% = $2.500 (static — fijo desde balance inicial, no sube con ganancias) |
| Mínimo días de trading por fase | 10 días |
| Tiempo máximo permitido | Ilimitado |
| Apalancamiento Forex | 1:100 |
| Apalancamiento Índices y Oro | 1:20 |
| EAs permitidos en evaluación | Sí |
| Holding fin de semana | Sí |
| Trading de noticias (evaluación) | Permitido — sin ventana de restricción. Prohibido como estrategia primaria. |
| 1-Minute Rule (evaluación) | No aplica |
| Single trade cap (evaluación) | No aplica |
| Consistency rule (evaluación) | No aplica |

## Reglas adicionales — Master (Funded Account)

| Regla | Detalle |
|-------|---------|
| DLL tipo | **Static** — igual que evaluación. Floor no sube con ganancias. |
| 1-Minute Rule | Profits de trades cerrados < 1 min de apertura **no cuentan para payout**. Parciales en esa ventana afectan el trade completo (flag HFT). |
| Single trade profit cap | Máximo **3% de profit por trade** en cuentas < $50K. ($25K → $750 máx por trade). En cuentas ≥ $50K: 2%. Incluye splits de la misma idea dentro de 10 min. |
| Max loss por trade | **3%** de la cuenta (< $50K) / **2%** (≥ $50K). Violación = cierre inmediato de cuenta. |
| News window | Profits de trades abiertos/cerrados **±5 min** de evento de alto impacto no cuentan para payout. |
| Consistency rule | Solo aplica con ciclo **On Demand**: máximo 35% de los profits del ciclo en un solo día. Weekly/Biweekly/Monthly → sin consistency rule. |
| IP consistency | Región de IP debe mantenerse consistente. Cambio de país genera solicitud de verificación. |
| Hedging entre cuentas | Prohibido |
| Inactividad | Cuenta puede cerrarse tras ~30 días sin actividad |

## Ciclos de payout — Master

| Ciclo | Split | Frecuencia | Consistency | Recomendación |
|-------|-------|-----------|-------------|---------------|
| Weekly | 60% | 7 días | No | Default — menor retorno |
| Bi-Weekly | 80% | 14 días | No | Equilibrio retorno/frecuencia |
| On Demand | 90% | Cuando quieras (mín 2%) | 35% | Riesgoso con EAs — evitar |
| **Monthly** | **100%** | 30 días | No | **Óptimo para crecimiento de capital** |

> Para el objetivo de $10K/mes: Monthly 100% maximiza el capital que permanece en cuenta y acelera el crecimiento del buffer.

## Hot Seat — Camino al escalado máximo

| Parámetro | Valor |
|-----------|-------|
| Requisito | 16 payouts exitosos + 40% profit acumulado en la cuenta funded |
| Beneficio | 100% profit split en todos los ciclos + capital hasta $2M + bonos mensuales $100–$500 |
| Timeline estimado | 7–12 meses de trading continuo sin breach |
| Reset | Un breach resetea el contador de payouts desde cero |
| Capital máximo | $2.000.000 |

> Con Monthly 100%: 16 meses mínimo para alcanzar Hot Seat desde activación de cuenta Master.

## Halt interno del risk_manager.mqh (60% del límite real)

| Límite FundingPips | Halt interno |
|-------------------|--------------|
| DLL 5% diario | Halt al 3% DD diario |
| MLL 10% total | Halt al 6% DD total |

## Pendiente de decisión (tuya)

- [ ] Fee pagado y código de descuento (añadir cuando se compre la cuenta)
- [ ] Fecha de inicio de la cuenta (añadir cuando se active)
- [ ] Screenshot del dashboard → `07-Knowledge/10K$/screenshots/`
- [ ] Confirmar ciclo de payout elegido antes de activar Master (recomendado: Monthly 100%)

## Ajustes requeridos en risk_manager.mqh antes de entrar en Master

- [ ] Implementar 1-Minute Rule: bloquear cierre de trade si `TimeCurrent() - open_time < 60s`
- [ ] Implementar 3% trade profit cap: cerrar trade si profit flotante supera $750 (en $25K)
- [ ] Implementar filtro news: desactivar entradas ±5 min de eventos HIGH del calendario
