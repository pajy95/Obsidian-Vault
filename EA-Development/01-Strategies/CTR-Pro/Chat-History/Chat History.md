# Chat-History — CTR Pro

[[Strategy - CTR Pro]]

Registro cronológico de sesiones de desarrollo de la estrategia CTR Pro. Cada archivo documenta las decisiones tomadas, hallazgos técnicos, código producido y conclusiones de esa sesión de trabajo.

---

## Archivos

### 077 - Desarrollo de EA CTR para GBPUSD.md
Desarrollo de la variante GBPUSD del CTR. Ingeniería inversa del EA comercial "Liquid Pours Xtreme MT5". Se documenta AutoSafeMode + H1 range validation para prevenir `INVALID_STOPS`. Resultado: solo Martes, GMT_Offset=3 (FundingPips verano).

### 089 - Ingeniería inversa de una estrategia CTR.md
Sesión fundacional. Se realiza la ingeniería inversa del EA comercial CTR Reclaim v3.0 a partir de video YouTube + imágenes MQL5 + .set files originales. Se descubre la discrepancia video vs realidad: el timeframe real es M10 (no M5), y las unidades son ticks (no pips). Se establece la vela clave única a las 8:45 AM NY.

### 099 - CTR Reclaim EA v30 MQL5.md
Construcción de v3.0 con SL×10. Se confirma experimentalmente que expandir el SL 10× destruye el edge: WR cae de 32.9% a 25.8%, por debajo del breakeven matemático. Se documenta que el edge vive en micro-reversiones < 8 min de hold time. También se corrige el data gap bug (`todayStart` con timezone offset).

### 102 - Expert Advisor automatizado para patrones de rever.md
Construcción del CTR_Pro_EA.mq5 de producción — EA profesional completo de 700 líneas con dashboard interactivo, visual signals, filtros en cascada y sizing USD-based. Primera versión llevada a producción en XAUUSD M5.

### 103 - CTR Reclaim EA estado global y próximos pasos.md
Revisión del estado global del proyecto CTR. Se inicia el proceso WFA para NDX100. Se documenta que la degradación OOS de -30.2% en v3.7 es aceptable según el threshold del WFA diseñado.

### 105 - Crear v38 con parámetros WFA.md
Aplicación de los resultados WFA (4.806 combinaciones) a v3.8. Se documentan los 4 cambios: NY_Minute=30, TP=925, BE=false, MN=3800. v3.8 queda en construcción pendiente de finalizar.

---

## Enlaces Relacionados

[[077 - Desarrollo de EA CTR para GBPUSD]]
[[089 - Ingeniería inversa de una estrategia CTR]]
[[099 - CTR Reclaim EA v30 MQL5]]
[[102 - Expert Advisor automatizado para patrones de rever]]
[[103 - CTR Reclaim EA estado global y próximos pasos]]
[[105 - Crear v38 con parámetros WFA]]
