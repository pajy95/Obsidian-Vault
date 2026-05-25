---
type: strategy
status: development
pair: US30
timeframe: M1
style: range breakout + candle pattern
platform: MT4 (MQL4)
account: demo
risk_per_trade: $100 fijo
created: 2026-04-12
tags:
---
[[Estrategias]]
# Estrategia: Tres Soldados (US30 Range Breakout)

## Descripción General

EA de **ruptura de rango con confirmación de patrón de velas** para US30 en M1. La premisa es que tras marcar el rango de precio de la sesión pre-market (ventana 1), cualquier vela que toque/atraviese ese rango y sea seguida de 2 velas más en la misma dirección representa un impulso confirmado.

El nombre "Tres Soldados" hace referencia al patrón de 3 velas consecutivas (alcistas o bajistas) que constituyen la señal de entrada.

Desarrollado para **US30 en MT4**, con demo testing activo.

---

## Hipótesis

El rango de precio formado en las primeras horas pre-market (5:00–10:00 AM NY en invierno) representa el contexto de liquidez del día. Cuando el precio rompe ese rango y lo confirma con 3 velas consecutivas, hay suficiente momentum para una continuación. La confirmación de 3 velas filtra rupturas falsas.

---

## Activo y Timeframe

| Campo | Valor |
|---|---|
| Activo | US30 (Dow Jones 30) |
| Timeframe | M1 |
| Plataforma | MetaTrader 4 (MQL4) |
| Sesión principal | New York |

---

## Definición de Rangos Horarios

### Ventana de Rango (Pre-market)
Período donde se marca el máximo y mínimo del día.

| Temporada | Horario NY | Horario UTC |
|---|---|---|
| Invierno (EST, UTC-5) | 5:00 AM – 10:00 AM | 10:00 – 15:00 |
| Verano (EDT, UTC-4) | 4:00 AM – 9:00 AM | 8:00 – 13:00 |

### Ventana de Trading
Período donde el EA busca señales de entrada.

| Temporada | Horario NY | Horario UTC |
|---|---|---|
| Invierno (EST) | 10:30 AM – 12:15 PM | 15:30 – 17:15 |
| Verano (EDT) | 9:30 AM – 11:15 AM | 13:30 – 15:15 |

> **Nota DST:** El parámetro `IsWinterTime` controla el conjunto de horarios activo. Se cambia manualmente al inicio de cada temporada.

---

## Reglas de Entrada

### Condición de ruptura (Vela 1)

La primera vela debe **contener dentro de su cuerpo** el nivel del rango:

```
COMPRA: rangeHigh >= Low[vela1] AND rangeHigh <= High[vela1] AND vela alcista
VENTA:  rangeLow  >= Low[vela1] AND rangeLow  <= High[vela1] AND vela bajista
```

**Crítico:** El rangeHigh/rangeLow debe estar **dentro de la vela**, no solo tocarla desde fuera. Velas que estén completamente por encima/debajo del rango no califican.

### Confirmación (Velas 2 y 3)

Después de detectar Vela 1:
- **Vela 2:** Siguiente vela en la misma dirección (alcista/bajista)
- **Vela 3:** Siguiente vela en la misma dirección

Si alguna vela rompe la dirección → **reset del contador**. Puede intentarse con la siguiente ruptura.

### Entrada

Al cierre de Vela 3 (o apertura de la siguiente barra).

### Filtro de movimiento excesivo

Si el movimiento total de las 3 velas supera **200 pips** → entrada **anulada**.

### Múltiples intentos

El EA permite múltiples intentos en la misma sesión:
- Si una ruptura no completa las 3 velas consecutivas → resetear y buscar nueva ruptura
- Máximo **1 operación ejecutada por día**

---

## Reglas de Salida

### Stop Loss
- **COMPRA:** Mínimo de la Vela 1 (la que rompió el rango)
- **VENTA:** Máximo de la Vela 1 (la que rompió el rango)

### Take Profit
- TP = SL (ratio **1:1**)
- Distancia en pips idéntica al SL

### Breakeven
- Trigger: **80%** del TP alcanzado (configurable: `BEPercent`)
- SL se mueve a entrada + **10%** del movimiento al TP (configurable: `BEProfitPercent`)
- Garantiza ganancia mínima al activarse

---

## Parámetros de Entrada

### Gestión de Riesgo
| Parámetro | Descripción | Default |
|---|---|---|
| `RiskAmount` | Riesgo fijo por operación en USD | 100.0 |
| `MaxPipsMove` | Movimiento máximo permitido en 3 velas | 200 |

### Breakeven
| Parámetro | Descripción | Default |
|---|---|---|
| `BEPercent` | % del TP al que se activa BE | 80.0 |
| `BEProfitPercent` | % del movimiento que se asegura en BE | 10.0 |

### Zona Horaria
| Parámetro | Descripción | Default |
|---|---|---|
| `IsWinterTime` | true = invierno (EST), false = verano (EDT) | true |
| `ServerTimeOffset` | Offset del broker respecto a UTC (ej: 1 para UTC+1) | 1 |

### General
| Parámetro | Descripción | Default |
|---|---|---|
| `MagicNumber` | Identificador del EA | 123456 |
| `EnableAlerts` | Alertas visuales/sonoras | true |
| `UseNewsFilter` | Filtro manual de noticias | true |
| `NewsTime` | Hora de noticia a filtrar (formato "HH:MM" UTC) | "15:00" |
| `Slippage` | Slippage máximo permitido | 3 |

---

## Versiones del EA

### v1.0 — Base inicial (bug de lógica)
- Primeras versiones: backtester y live por separado
- Bug crítico: verificaba cualquier combinación de 3 velas alcistas/bajistas sin exigir que la primera tocara el rango

### v2.0 — Correcciones principales
- Lógica corregida: vela 1 debe romper el rango correctamente
- Riesgo cambiado de 1% a **$100 fijo**
- Versiones: `US30_Range_Breakout_Backtest_v2.mq4` y `US30_Range_Breakout_5Sec_Entry.mq4`

### v3.0 — Contador visual de velas
- Panel en pantalla que muestra el estado de cada vela (Vela 1, Vela 2, Vela 3) en tiempo real
- Logs detallados pre-ejecución

### v4.0 — Horario corregido a 10:30–12:15 NY

### v5.0 — Debug completo
- Auto-detección de zona horaria
- Dibuja líneas azul (rangeHigh) y roja (rangeLow) más gruesas

### v6.0 — Versión Final (producción)
- **DST handling:** parámetro `IsWinterTime` para dos conjuntos de horarios
- **ServerTimeOffset:** ajuste configurable del offset del broker
- Panel completo con hora UTC + hora servidor + horarios NY + rango establecido + estado de trading + datos de cuenta
- Lógica correcta de ruptura: `rangeHigh DENTRO de la vela` (no `high >= rangeHigh`)
- Múltiples intentos de ruptura por sesión

---

## Bugs Históricos y Correcciones

| Bug | Descripción | Fix |
|---|---|---|
| Lógica de 3 velas | Entraba con cualquier 3 velas alcistas sin que la primera tocara el rango | Verificar que rangeHigh/Low esté dentro del rango [low, high] de vela 1 |
| Detección de ruptura amplia | `high >= rangeHigh` permitía velas completamente por encima del rango | Cambiar a `rangeHigh >= low AND rangeHigh <= high` |
| Tracking de ruptura | Después de cancelación, podía entrar con una segunda set de 3 velas donde la primera no tocaba el rango | Sistema de tracking con contador + reset explícito |
| Movimiento excesivo | EA intentaba ejecutar aunque movimiento > 200 pips, causando Error 134 (fondos insuficientes por lote mínimo) | Verificar filtro ANTES de enviar orden |
| Timezone offset | EA en UTC pero broker UTC+1 o +2 → horarios desfasados 1-2 horas en demo | Parámetro `ServerTimeOffset` configurable |
| Horario de trading | Inicialmente 9:30–12:15, incorrecto → era 10:30–12:15 NY en invierno | Separar horarios invierno/verano con `IsWinterTime` |
| Candles no consecutivas | Podía aceptar velas no consecutivas si el breakout fue detectado mucho antes | Verificación de tiempo entre velas (60 segundos entre cada una) |

---

## Arquitectura de la Señal

```
SETUP COMPRA:
─────────────────────────────────────────────────
4:00 AM (invierno) → Inicia establecimiento rango
9:00 AM (invierno) → Rango finalizado
10:30 AM          → Ventana de trading activa

Dentro de ventana:
  Vela X:  rangeHigh ∈ [Low_x, High_x] + alcista → RUPTURA DETECTADA (intento #N)
  Vela X+1: alcista → contador = 1/2
  Vela X+2: alcista → contador = 2/2
  
  → ENTRADA al cierre de Vela X+2
    Entry: Ask
    SL: Low de Vela X
    TP: Entry + (Entry - SL)

  Si alguna vela intermedia es bajista → RESET → busca nueva ruptura

BREAKEVEN (cuando precio alcanza 80% del TP):
  Nuevo SL = Entry + 10% × (TP - Entry)
```

---

## Panel en Pantalla (v6.0)

```
╔═══════════════════════════════════════════════════════════╗
║     US30 RANGE BREAKOUT - VERSIÓN FINAL 6.0              ║
╚═══════════════════════════════════════════════════════════╝

🕐 HORA:
   UTC: 2026.02.21 15:35
   Servidor: 16:35 (UTC+1)

🕐 TEMPORADA: INVIERNO (EST)

⏰ HORARIOS (Nueva York):
   Rango: 5:00 AM - 10:00 AM
   Trading: 10:30 AM - 12:15 PM

📊 RANGO DEL DÍA:
   ✓ ESTABLECIDO
   Máximo: 44,510.5
   Mínimo: 44,295.0
   Tamaño: 215.5 pips

🎯 ESTADO:
   Ventana: ✓ ACTIVA
   Trade hoy: ✗
   Intentos: 2

📍 VELA 1 (rompe rango): COMPRA ✓
📍 VELA 2: ALCISTA ✓
📍 VELA 3: ⏳ Esperando...

💰 CUENTA:
   Balance: $10,000.00
   Equity: $10,000.00
```

---

## Compliance

| Regla | Detalles |
|---|---|
| Solo 1 trade/día | Implementado — flag `tradeExecutedToday` |
| Sin hedging | EA abre solo 1 posición |
| Sin martingala | Lote calculado por distancia SL y `RiskAmount` fijo |
| Filtro de noticias | Manual — parámetro `UseNewsFilter` + `NewsTime` |

---

## Errores Comunes de MT4

| Error | Código | Causa | Solución |
|---|---|---|---|
| Stops inválidos | 130 | SL/TP muy cerca del precio (debajo del stop level del broker) | Verificar stop level mínimo |
| Volumen inválido | 131 | Lote calculado menor al mínimo | Verificar tamaño SL; aumentar RiskAmount |
| Fondos insuficientes | 134 | Movimiento > 200 pips → lote resultante = 0 | Filtro de 200 pips aplicado antes de ejecutar |
| EA detenido uninit 5 | — | EA recompilado mientras corría | Reinstalar EA en el gráfico |

---

## Notas de Implementación

1. **Lectura de velas en M1:** La señal se evalúa al cierre de cada barra (IsNewBar). No se usa tick a tick.
2. **Líneas visuales:** El EA dibuja línea azul horizontal en rangeHigh y línea roja en rangeLow al finalizar el período de rango.
3. **Símbolo:** El nombre del símbolo puede variar según broker (US30, US30Cash, US30.c). Verificar símbolo exacto.
4. **Offset del broker:** Verificar UTC del broker observando la hora del servidor cuando son las 15:00 UTC y calcular diferencia.

---

## Estado Actual

| Fase | Estado |
|---|---|
| Código v6.0 final | ✅ Completado |
| Demo testing | ⏳ En progreso |
| Backtest formal (IS/OOS) | ⏳ Pendiente |
| Validación de resultados | ⏳ Pendiente |

**Estado global (CLAUDE.md):** Development

---

## Archivos del Proyecto

| Archivo | Descripción |
|---|---|
| `Source/Experts/US30_Range_Breakout_FINAL_V1.mq4` | Versión final con BE ajustable y panel completo (v6.0 con DST) |

---

## Referencias

- Chat 083: Desarrollo completo desde cero — lógica de 3 velas, múltiples versiones, corrección de bugs de ruptura, DST handling

*Última actualización: 2026-04-12*

