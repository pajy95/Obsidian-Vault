# Chat-History — BreakoutNY

[[Strategy - BreakoutNY]]


Registro cronológico de sesiones de desarrollo de la estrategia BreakoutNY. Cada archivo documenta las decisiones tomadas, hallazgos técnicos, código producido y conclusiones de esa sesión de trabajo.

---

## Archivos

### 062 - Optimizacion en Estrategia Breakout NY.md
Primera sesión de optimización formal. Se establecen las bases del proceso IS/OOS, el concepto de meseta de parámetros y la decisión de desactivar shorts en NAS100 por degradar el performance histórico.

### 080 - Breakout NY XAUUSD FP viable.md
Análisis de viabilidad de XAUUSD en FundingPips. Se estudia la distribución de rangos pre-NY, se identifican los percentiles P25/P75 para calibrar MinSL/MaxSL, y se documenta el uso de OrderCalcProfit para VPP en CFDs (en lugar de SymbolInfoDouble, que es inestable en el backtester).

### 087 - BreakoutNY v80 XAU.md
Refinamiento del set XAUUSD v80. Análisis detallado por día de semana — se confirma que jueves es el único día robusto en todos los regímenes. Se descarta viernes definitivamente (WR=0% en 2022 bajista).

### 088 - BreakoutNY SP500 FPviable.md
Primer análisis de SP500. Se identifica el bug crítico de BE_BufferPct=0 que generaba un WR ficticio del 99%. Se calibran parámetros iniciales para SP500 en FundingPips.

### 094 - Breakout NY US30 FP viable.md
Validación de US30/DJI30 para FundingPips. Se documenta el TickValue=5.0 USD/tick para DJI30 y se confirma la viabilidad del activo con IS PF=1.609 y OOS PF=2.017.

### 098 - BreakoutNY NAS100 FP viable.md
Validación definitiva de NAS100 para FundingPips. Se confirma el set MonTueFri con FilterShorts=true como configuración de producción.

### 106 - BreakoutNY EURUSD FP (en desarollo).md
Inicio del desarrollo de BreakoutNY para EURUSD. Calibración de parámetros: pipSize=0.0001, SpreadMax=3.0 pips, MinSL 8–12 pips. Estado: en desarrollo.

### 107 - Desarrollo de EA para EURUSD (continuacion part 2).md
Continuación del desarrollo EURUSD. Segunda parte del trabajo de calibración y ajuste de parámetros para este activo.

### 108 - Breakout NY XAU viable.md
Revisión adicional de XAUUSD. Se analiza EntryMaxCandle y se decide dejarlo en 0 (sin límite) porque limitar la ventana de entrada corta trades rentables — el 90% de breakouts ocurren antes de las 15:05 UTC pero los tardíos también son válidos.

### 109 - BreakoutNY XAUUSD v9 Set E produccion.md
Documentación del set E de XAUUSD v9 en producción. BE_BufferPct=70, FilterThursday=true, MinSL=4.5, MaxSL=13.0. Primer set llevado a cuenta FundingPips real.

### 110 - Optimizacion, verificacion y analisis de robustes Breakout NY.md
Sesión completa de optimización y validación del portfolio. Cubre:
- XAUUSD v2: nuevo set con 333 pasadas, selección ThuOnly, PF OOS=2.536
- SP500 v2: diagnóstico de fallo v1, rediseño con ATR filter y solo longs, PF OOS=1.374 (demo)
- Análisis combinado Monte Carlo + Robustez para XAUUSD, NAS100 y DJI30
- Organización completa de carpetas del proyecto
- Creación de Sets-Produccion, WalkForward y Analisis-MonteCarlo

Enlaces Relacionados

[[062 - Optimizacion en Estrategia Breakout NY]]
[[080 - Breakout NY XAUUSD FP viable]]
[[087 - BreakoutNY v80 XAU]]
[[088 - BreakoutNY SP500 FPviable]]
[[094 - Breakout NY  US30 FP viable]]
[[098 - BreakoutNY NAS100 FP viable]]
[[106 - BreakoutNY EURUSD FP (en desarollo)]]
[[107 - Desarrollo de EA para EURUSD (continuacion part 2)]]
[[108 - Breakout NY XAU viable]]
[[109 - BreakoutNY XAUUSD v9 Set E produccion]]
[[110 - Optimizacion, verificacion y analisis de robustes Breakout NY]]
