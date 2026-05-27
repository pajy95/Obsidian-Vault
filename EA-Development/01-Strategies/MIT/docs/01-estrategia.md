# MIT — Estrategia y Edge

## Concepto central

MIT opera **después** de la publicación de un dato macroeconómico de alto impacto. No predice el dato — entra cuando el mercado ya reaccionó y hay dirección clara.

```
Publicación del dato
       ↓
Spike inicial de volatilidad (10-30 seg)
       ↓
MIT evalúa: sorpresa + contexto + precio
       ↓
Entrada post-spike en la primera vela M5 de confirmación
       ↓
Cierre por SL, TP, o timeout de sesión
```

---

## Por qué post-spike y no pre-evento

Operar antes del anuncio (straddle) implica pagar spread en ambas direcciones y sufrir el spike en contra. MIT **espera la reacción** para confirmar dirección antes de entrar. Cede los primeros pips del movimiento a cambio de mayor certeza.

---

## El edge de MIT

### 1. Asimetría de sorpresa
Un dato que supera ampliamente las expectativas genera un movimiento direccional sostenido con mayor probabilidad que un dato en línea. Claude cuantifica esta asimetría y filtra eventos donde la sorpresa no es suficiente para justificar el trade.

### 2. Contexto macroeconómico acumulado
Claude evalúa el dato en contexto: ¿Es el tercer mes consecutivo de beats de NFP? ¿Está el mercado ya descontando subidas de tasas? Un dato aislado se interpreta diferente que el mismo dato dentro de una tendencia macro.

### 3. Lectura de comunicados en lenguaje natural
En decisiones de bancos centrales, el dato (tasa sin cambio) puede ser menos importante que el comunicado (lenguaje hawkish/dovish). Claude lee el texto completo y extrae el sesgo real — algo que ningún EA de reglas puede hacer.

### 4. Filtro de ruido
No todos los beats son iguales. Claude puede rechazar un trade si:
- El beat es pequeño relativo al rango histórico del indicador
- Hay eventos contrarios más relevantes ese día
- La vela post-spike muestra rechazo del movimiento (pin bar)
- El instrumento ya se movió significativamente antes del evento

---

## Eventos objetivo por prioridad

### Tier 1 — Máximo impacto (siempre evaluar)
| Evento | Divisa | Instrumento principal |
|--------|--------|----------------------|
| Non-Farm Payrolls | USD | NAS100, SPX500, USDJPY |
| CPI m/m y a/a | USD | NAS100, SPX500, USDJPY |
| Decisión tasa Fed + comunicado | USD | Todos |
| Decisión tasa BCE + conferencia | EUR | GBPJPY |
| Decisión tasa BoJ | JPY | USDJPY, GBPJPY |

### Tier 2 — Alto impacto (evaluar si Tier 1 no está en conflicto)
| Evento | Divisa | Instrumento principal |
|--------|--------|----------------------|
| ISM Manufacturing/Services | USD | NAS100, SPX500 |
| GDP trimestral | USD | NAS100, SPX500 |
| Retail Sales | USD | NAS100, SPX500 |
| CPI UK | GBP | GBPJPY |
| Decisión tasa BoE | GBP | GBPJPY |

### Tier 3 — Impacto moderado (solo si sorpresa es muy grande)
- PPI, Jobless Claims, Durable Goods, Trade Balance

---

## Lógica de entrada

```
1. Evento publicado (hora exacta del calendario)
2. Esperar cierre de la primera vela M5 post-anuncio
3. Claude evalúa: datos + contexto + estructura de vela
4. Si APPROVE:
   - Entrar en apertura de la segunda vela M5
   - SL: debajo/encima del extremo del spike
   - TP: definido por Claude según magnitud de sorpresa
5. Si REJECT: no operar, loggear razón
```

---

## Lógica de salida

| Condición | Acción |
|-----------|--------|
| TP alcanzado | Cierre completo |
| SL alcanzado | Cierre completo |
| Timeout 2 horas | Cierre a mercado |
| Claude detecta reversión | Cierre anticipado (Fase 3+) |

---

## Diferencias clave vs. TBR

| Aspecto | TBR | MIT |
|---------|-----|-----|
| Trigger | Hora fija de sesión | Evento macroeconómico |
| Frecuencia | 1 trade/día/instrumento | 0-3 trades/semana |
| Lógica | Reglas fijas (ORB) | IA (razonamiento) |
| Validación | Strategy Tester MT5 | Historical replay + shadow mode |
| Adaptabilidad | Estática hasta re-optimización | Dinámica por naturaleza |
| Explicabilidad | Ninguna | Completa (Claude justifica cada trade) |

---

## Correlación esperada con TBR

MIT y TBR pueden operar el mismo día en el mismo instrumento, pero los triggers son distintos. La correlación esperada es **baja** porque:
- TBR opera al inicio de sesión (hora fija)
- MIT opera en momentos específicos de news (impredecibles por fecha pero predecibles por calendario)
- Los movimientos que captura cada uno son diferentes

En periodos sin eventos de Tier 1, MIT no opera — TBR sigue operando normalmente.
