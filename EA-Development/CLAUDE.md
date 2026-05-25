# EA-Development — Jose Yanez

## Quién soy y qué hacemos aquí

Soy Jose, desarrollador cuantitativo MQL5/MT5. Este repositorio es el núcleo de mi operación de trading algorítmico: desarrollo, validación y despliegue de Expert Advisors (EAs) para cuentas de evaluación de prop firms (FundingPips y FundedNext).

Mi metodología se basa en la busqueda de estrategias rentables. Toda estrategia pasa por un pipeline riguroso: IS → OOS → Walk-Forward → Monte Carlo → Demo → Live. No avanzo ninguna estrategia sin veredicto formal.

---

## Build & Compile

- MetaTrader 5: `C:\Program Files\MetaTrader 5\`
- MetaTrader 4: para cuenta FundedNext MT4
- Source files: `Source/Experts/`, `Source/Include/`
- Compilar: `metaeditor64.exe /compile`

---

## Estructura del repositorio

```
EA-Development/
├── _Templates/                  # Plantillas Obsidian (Templater)
├── 01-Strategies/               # Hub principal — una carpeta por estrategia
│   ├── ARE/
│   ├── BreakoutNY/              # EA más maduro, en producción
│   ├── Cascade-Gate/
│   ├── CTR-Pro/
│   ├── CTR-Reclaim/
│   ├── Donchian/
│   ├── ORB/
│   └── Tres-Soldados/
├── 02-Roadmap/                  # Planificación de desarrollo
├── 07-Knowledge/                # Base de conocimiento (filosofía, investigación, workflow)
├── 08-Claude-Context/           # Estado actual del proyecto, briefings
├── 09-Chat-History/             # Historial de conversaciones exportadas
├── scripts/                     # Scripts Python/utilitarios
└── Source/                      # Código fuente MQL5
    ├── Experts/                 # EAs (.mq5)
    └── Include/                 # Módulos reutilizables (.mqh)
```

### Estructura interna de cada estrategia

```
StrategyName/
├── Analysis/                    # Notas de análisis, hipótesis
├── Analisis-MonteCarlo/         # Resultados Monte Carlo por instrumento
├── Backtests/                   # CSVs y reportes por instrumento
├── Chat-History/                # Conversaciones relevantes archivadas
├── Code/                        # Código MQL5 específico de la estrategia
├── Decisions/                   # Decision log (veredictos IS/OOS/WF)
├── Optimizacion/                # Resultados de optimización MT5
├── Sets-Produccion/             # Sets (.set) listos para live/demo
├── Trade-Journal/               # Diario de operaciones
└── WalkForward/                 # Análisis walk-forward
```

> Estrategias maduras (BreakoutNY, CTR-Pro, ARE) tienen todas las carpetas.
> Estrategias en exploración temprana pueden tener solo un subconjunto.

---

## Architecture & Standards MQL5

- Usar `CTrade` class para todas las operaciones de orden (MT5)
- Patrón base: `OnInit()`, `OnDeinit()`, `OnTick()` + `IsNewBar()`
- Todo EA incluye `MagicNumber` como input parameter
- **Sizing: USD fijo** (`RiskAmountUSD`) — nunca porcentaje directo, para compatibilidad con prop firms
- Sin martingala — una posición por señal máximo
- Sin hedging
- Notación húngara: `dLotSize`, `iMagicNumber`, `sComment`
- Siempre verificar retorno de `CopyBuffer()`
- `GetLastError()` después de cada operación de trading
- Manejar brokers de 5 dígitos: `_Point * 10` para pips
- `SessionClose` hardcodeado donde aplique (ej: 17:00 UTC en EURUSD)
- `ConfirmOnClose = true` por defecto en entradas basadas en velas — evita repainting

### Regla crítica — cálculo de profit/VPP

**NUNCA usar `SYMBOL_TRADE_TICK_VALUE`** — hay un bug conocido en el backtester de MT5.
Usar siempre `OrderCalcProfit()` para cualquier cálculo de VPP o profit esperado.

### Magic Numbers asignados (no reutilizar)

| MagicNumber | EA | Instrumento | Estado |
|------------|-----|-------------|--------|
| 202401 | BreakoutNY | NAS100 | Producción |
| 202402 | BreakoutNY | DJI30 | Producción |
| 202409 | BreakoutNY | XAUUSD | Producción |
| 20250404 | ORB | EURUSD | Demo |
| 202501 | TBR v1.0b | NAS100 P63 | Demo |
| 202502 | TBR v1.0b | XAUUSD P2 BE NoLunes | Demo |
| 202503 | TBR v1.0b | NAS100 P58421 LONG | Pendiente demo |

> Registro completo TBR: `01-Strategies/TBR/Sets-Produccion/CONTROL_MagicNumbers.md`

### TradeDirection enum en TBR v1.0b

**CRITICO:** El enum del EA tiene el orden contrario a la intuición:

| Valor | Constante | Comportamiento |
|-------|-----------|---------------|
| `0` | `DIR_BOTH` | Long + Short (bidireccional) |
| `1` | `DIR_BUY` | Solo Long |
| `2` | `DIR_SELL` | Solo Short |

### Nomenclatura de inputs estándar

```mql5
input double RiskAmountUSD      = 50;      // Riesgo por trade en USD
input double RR                 = 2.0;     // Risk-Reward ratio
input bool   BreakevenEnabled   = true;    // Activar breakeven
input int    MagicNumber        = 202401;  // ID único del EA
input bool   ConfirmOnClose     = true;    // Confirmar señal en cierre de vela
```

### Nomenclatura de funciones

```mql5
bool   IsNewBar()          // Detección de nueva vela
double CalcLotSize()       // Cálculo de lote — usa OrderCalcProfit(), nunca TickValue
bool   SessionIsActive()   // Filtro de sesión
void   ManageOpenTrades()  // Gestión de posiciones abiertas
```

- Archivos `.mq5`: EA completo (lógica principal)
- Archivos `.mqh`: módulos reutilizables (risk, session, utils)
- Comentarios: en español, concisos
- Sin magic numbers hardcodeados en el cuerpo — siempre como input

### Regla de adaptación entre instrumentos

Al portar un EA a un nuevo instrumento: **preservar arquitectura interna verbatim**.
Solo modificar defaults de inputs (SL ranges, sesión, símbolo). Nunca refactorizar la lógica core durante una adaptación.

---

## Methodology

- Smart Money Concepts (SMC) + ICT methodology
- Sesión NY como ventana principal de trading
- Sesiones Londres y Asia como ventana secundaria
- Activos primarios: XAUUSD, NAS100, EURUSD, SP500, DJI30
- Timeframes: M5 (primario), M15, H1
- Edge validation obligatorio antes de codificar

### Pipeline de validación (obligatorio, sin saltarse pasos)

```
IS → OOS → Walk-Forward → Robustez → Monte Carlo → Demo → Live
```

- **IS**: 2018–2021
- **OOS**: 2022–2023
- **Walk-Forward**: 2024–presente
- **Robustez**: estudios de sensibilidad paramétrica (ver checklist abajo) — descartar edges frágiles antes de gastar tiempo en MC
- **Monte Carlo**: distribución de drawdowns y equity en 1000+ iteraciones, solo sobre edges robustos

### Criterios mínimos de viabilidad (todos obligatorios)

| Métrica | Mínimo |
|---------|--------|
| Profit Factor OOS | ≥ 1.4 |
| Max Drawdown OOS | ≤ 10% |
| Trades en OOS | ≥ 30 (preferible 100+) |
| Rendimiento OOS vs IS | ≥ 50% |
| Walk-Forward Efficiency | ≥ 0.5 |
| Sharpe Ratio | > 1.0 |
| Concentración de ganancias | Sin dependencia de 1–2 trades |
| Long/Short separados | Ambas direcciones PF ≥ 1.0 en OOS (si la estrategia es bidireccional) |
| Bucket de exit dominante | n ≥ 30 trades en el bucket que genera el edge principal |
| Sensibilidad al cierre de sesión | PF OOS no cae por debajo de 1.0 al mover SessionEnd ±15 min |

### Veredictos formales (usar siempre en `Decisions/`)

- `VIABLE` — cumple todos los criterios, avanza al siguiente paso
- `MARGINAL` — cumple la mayoría, requiere análisis adicional antes de avanzar
- `NO VIABLE` — no avanza, documentar razón específica

### Filosofía de backtesting — "punish the strategy"

- Buscar **mesetas de rendimiento**, no picos — parámetros estables en rango amplio
- Slippage: usar 1.5–2x del estimado real
- Stress test paramétrico: ±20–30% en cada parámetro clave
- Análisis año a año: rentable en mayoría de años individuales
- Escepticismo por defecto ante resultados brillantes — buscar por qué podría ser falso
- Circuit breakers: remover durante backtesting para no distorsionar datos de evaluación pura

### Estudios de robustez obligatorios (etapa "Robustez" del pipeline)

Ejecutar antes de Monte Carlo. Scripts en `scripts/`:

1. **Distribución de hold times** — identificar cómo cierra cada trade (SL / TP / sesión).
   Calcular PF por bucket de duración. Si un solo bucket concentra todo el edge, es una señal de alerta.

2. **Sensibilidad al cierre de sesión (SessionEnd)** — simular umbral ±15 / ±30 min.
   Si PF OOS cae por debajo de 1.0 con -15 min → edge frágil, requiere reoptimización de SessionEnd en MT5.

3. **Long vs Short separados** — calcular PF/WR/Net para cada dirección en IS, OOS y WFA por separado.
   Ambas deben ser PF ≥ 1.0 en OOS. Si una dirección falla en WFA → evaluar filtro direccional.

4. **Concentración interna del bucket dominante** — dentro del bucket de exit que genera el edge,
   verificar que Top 3 trades < 30% del net del bucket. Si n < 30 en ese bucket → muestra insuficiente.

5. **Desglose año a año** — PF positivo en mayoría de años individuales (mínimo 3 de 4).
   Incluir OOS y WFA como años independientes.

---

## SMC/ICT Concepts en uso

- Liquidity sweeps (BSL/SSL)
- Fair Value Gaps (FVG)
- Order Blocks (OB)
- Change of Character (CHoCH)
- Break of Structure (BOS)
- Opening Range Breakout (ORB)
- Donchian Channel breakouts
- Weinstein Stage Analysis (D1 XAUUSD, tier-1)
- Análisis de patrones de velas japonesas
- Price action basado en rango de velas (sesión de apertura)

---

## Estrategias activas

### BreakoutNY — `01-Strategies/BreakoutNY/`
- **Tipo**: Breakout de rango pre-sesión NY
- **Instrumentos**: NAS100, XAUUSD, DJI30, SP500 (todos en M5)
- **Lógica**: Long-only en NAS100/DJI30 (sesgo estructural alcista — shorts desactivados)
- **Sets de producción**: `Sets-Produccion/` por instrumento
- **Estado XAUUSD Set E** (forward-test):
  - `BE_BufferPct=70, MinSL_Points=4.5, MaxSL_Points=13.0`
  - `Thursday-only, ConfirmOnClose=true, RiskAmountUSD=50`
- **Status**: Producción (NAS100, DJI30) / Forward-test (XAUUSD, SP500)

### CTR-Pro — `01-Strategies/CTR-Pro/`
- **Tipo**: Candle Range Theory — Liquidity Sweep Reversal
- **Instrumentos**: NDX100, XAUUSD (M5, sesión NY)
- **Features**: Dashboard interactivo on-chart, visual signal drawing, USD-based sizing
- **Status**: Validación avanzada

### CTR-Reclaim — `01-Strategies/CTR-Reclaim/`
- **Tipo**: Variante de CTR-Pro
- **Concepto**: Entrada en confirmación de reclaim de nivel clave post-sweep (vs entrada directa en sweep)
- **Activo**: XAUUSD
- **Status**: Development

### ARE — `01-Strategies/ARE/`
- **Instrumentos**: EURUSD, GBPUSD, NAS100, XAUUSD
- **Status**: Optimización / análisis

### ORB — `01-Strategies/ORB/`
- **Tipo**: Opening Range Breakout
- **Activo**: EURUSD — cuenta FundedNext demo
- **Base**: Adaptación de BreakoutNY (arquitectura preservada verbatim)
- **London Open**: 08:00 GMT, MagicNumber 20250404
- **Status**: Development

### Donchian — `01-Strategies/Donchian/`
- **Tipo**: Trend-following breakout
- **Activo**: EURUSD — cuenta FundedNext MT4
- **Timeframe**: M15
- **Nota**: Circuit breaker removido para observación cuantitativa limpia
- **Status**: Forward testing

### Cascade-Gate — `01-Strategies/Cascade-Gate/`
- **Tipo**: Breakout / Momentum
- **Activos**: NAS100, SP500
- **Status**: Development

### Tres-Soldados — `01-Strategies/Tres-Soldados/`
- **Tipo**: Patrón de velas / Momentum
- **Activo**: US30
- **Status**: Development

---

## Estrategias basadas en modelos aleatorios (investigación)

- Teoría del paseo aleatorio
- Modelos estocásticos de ejecución
- Estrategias de ineficiencia de mercado
- Estrategias de premium de riesgo

Ver referencias en `07-Knowledge/Investigacion/`

---

## Prop Firm Compliance

### FundingPips
- Max daily drawdown: 5%
- Max total drawdown: 10% (estático)
- Profit split: 80% bi-semanal
- 1-Minute Rule: no abrir en el primer minuto de sesión (solo Master accounts)
- Single trade max: 3% del capital (solo Master accounts)
- No hedging, no martingala

### FundedNext
- Max daily drawdown: 5%
- Max total drawdown: 10%
- No hedging, no martingala

---

## Stack técnico

- **Lenguaje principal**: MQL5 (MT5) + MQL4 (MT4 FundedNext)
- **Análisis / IA**: Python (pandas, numpy, scikit-learn, statsmodels, TensorFlow/PyTorch)
- **Comunicación MT5↔Python**: ZeroMQ, sockets, archivos compartidos (.h5/.onnx)
- **Control de versiones**: Git → GitHub privado (`pajy95/ea-knowledge-base`)
- **Documentación**: Obsidian (este vault), commits automáticos cada 5 min
- **IDE**: VSCode con extensiones MQL5 y Git

---

## Cómo actuar según el tipo de tarea

### Escribir o modificar código MQL5
1. Revisar si existe código base en `Source/Experts/` o `01-Strategies/[EA]/Code/`
2. Aplicar todas las reglas de Architecture & Standards sin excepción
3. Usar `OrderCalcProfit()` — nunca `SYMBOL_TRADE_TICK_VALUE`
4. Verificar que el Magic Number no esté ya asignado
5. Si es adaptación: preservar arquitectura, solo cambiar inputs

### Analizar backtest o CSV de optimización
1. Archivos en `01-Strategies/[EA]/Backtests/` o `Optimizacion/`
2. Aplicar todos los criterios mínimos de viabilidad
3. Buscar mesetas, no picos — identificar pass más robusto, no el de mayor profit
4. Emitir veredicto formal: VIABLE / MARGINAL / NO VIABLE
5. Documentar en `01-Strategies/[EA]/Decisions/`

### Analizar resultados Monte Carlo
1. Archivos en `01-Strategies/[EA]/Analisis-MonteCarlo/`
2. Evaluar distribución de drawdowns y profit en 1000+ iteraciones
3. Reportar percentil 5% como escenario pesimista de referencia

### Crear scripts Python
- Utilitario general → `scripts/`
- Específico de estrategia → `01-Strategies/[EA]/`
- Usar pandas para CSVs de MT5
- MT5 exporta en **UTF-16 con BOM** — manejar encoding explícitamente:
  ```python
  df = pd.read_csv(file, encoding='utf-16', sep='\t')
  ```

### Documentar resultados
- Análisis e hipótesis → `01-Strategies/[EA]/Analysis/`
- Decisiones y veredictos → `01-Strategies/[EA]/Decisions/`
- Resultados de backtest → `01-Strategies/[EA]/Backtests/`

---

## Estado actual del proyecto

@08-Claude-Context/Current Project State.md

## Referencias clave

@01-Strategies/
@07-Knowledge/Workflow/quant-trader-blueprint.md

---

## Tono y estilo de respuesta

- Análisis directo, sin hedging ni disclaimers genéricos
- Datos primero, conclusiones después
- Si algo no cumple criterios: decirlo sin suavizar
- Veredictos formales cuando corresponda
- Honestidad técnica completa — sin eufemismos sobre pérdidas o resultados pobres