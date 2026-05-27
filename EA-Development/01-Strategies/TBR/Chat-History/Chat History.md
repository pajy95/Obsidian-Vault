# Chat-History — TBR

[[TBR]]

Registro cronológico de sesiones de desarrollo de la estrategia TBR. Cada archivo documenta las decisiones tomadas, hallazgos técnicos, código producido y conclusiones de esa sesión de trabajo.

---

## Archivos

### 111 - TBR XAU IS-OOS P1 P2 analisis y parametros produccion.md
Análisis IS/OOS/WFA de XAUUSD con dos passes: P1 (#7129, VIABLE 5/5) y P2 (#2603, MARGINAL 4/5). Se descubre y corrige el parser DEAL de MT5 (col[4]='in'/'out', P&L en col[10]). Se identifica que los timeout trades son el motor de rentabilidad del sistema XAU. Análisis de régimen 2026: LONG roto, SHORT funciona — esperar Q3 2026. Se crean los sets de producción NAS100 y XAUUSD en Sets-Produccion/. Se actualiza el vault TBR completo con estructura de carpetas de estrategia madura.

### 112 - TBR Expansion Portfolio USDJPY-GBPJPY-XAUUSD_Asian-AUDJPY-EURUSD 2026-05-23_24.md
Pipeline completo de expansión del portfolio TBR. USDJPY P5458 VIABLE (10/10), P7389 MARGINAL (9/10). GBPJPY P110836 VIABLE (11/11), P121378 archivado (corr=0.89). XAUUSD Asian DESCARTADO (IS PF<1.10). AUDJPY DESCARTADO (0 passes PF≥1.10). EURUSD exploratoria iniciada (archivo 2025-only).

### 113 - TBR DJI30 Pipeline EURUSD Exploratorio 2026-05-25.md
Pipeline DJI30 completo (12/12, VIABLE, EN CUENTA Magic 202512). Set file DJI30 creado. Corrección conceptual: Bck=IS / Fwd=OOS en MT5. EURUSD exploratorio descartado (IS=2025 solo, 1 año insuficiente). Renombre y reorganización de archivos EURUSD. Script `tbr_eurusd_is2022_heatmap.py` creado para nueva optimización IS=2022-2024.

### 114 - TBR SPX500 P12538 EURUSD Descartado Reportes-Validacion 2026-05-25.md
SPX500 P12538 noJV VIABLE 13/13 (IS=1.708, OOS=1.601, WFA=1.279). EURUSD definitivamente descartado (P269914 falló 7/12 criterios). Creación de `tbr_reportes_estandar.py`: script maestro que genera 5 gráficos estandarizados (Analisis, PermTest, Robustez, MonteCarlo, Pipeline) para los 8 instrumentos activos del portfolio TBR. Bug detectado en parser: PF inflados por inclusión de filas de balance MT5.

### 115 - TBR Reportes-Validacion Estandarizados Bug Fix Estados 2026-05-26.md
Corrección del bug en `parse_trades()`: `abs(p) < 50000 → 5000` + detección robusta de columna Profit (excluye 'Factor'/'Gross'). 40 gráficos regenerados con PF correctos. Actualización de estados: NAS100 LIVE→DEMO, SPX500 LIVE→DEMO, DJI30 EN CUENTA→DEMO (ningún set actualmente en cuenta live).
Verificación IS=2022-2024 EURUSD (comparación Pass P41200 entre archivos). EURUSD P269914 DESCARTADO (7/12, Perm OOS p=0.27, MC P(profit)=72.6%). SPX500 nueva optimización Hr=14 exclusivo analizada — P12538 VIABLE 13/13 (IS=1.708, OOS=1.601, WFA=1.279, noJV filter). Set file Magic 202513 creado. Correlación P12538 vs P187 = 0.661 (moderada). Registro MN actualizado. Carpeta `Analisis-MonteCarlo` renombrada a `Reportes-Validacion` — 15 scripts Python actualizados.

---

## Enlaces Relacionados

[[111 - TBR XAU IS-OOS P1 P2 analisis y parametros produccion]]
[[112 - TBR Expansion Portfolio USDJPY-GBPJPY-XAUUSD_Asian-AUDJPY-EURUSD 2026-05-23_24]]
[[113 - TBR DJI30 Pipeline EURUSD Exploratorio 2026-05-25]]
[[114 - TBR SPX500 P12538 EURUSD Descartado Reportes-Validacion 2026-05-25]]
