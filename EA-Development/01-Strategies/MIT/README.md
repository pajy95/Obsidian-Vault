# MIT — Macro Intelligence Trader

**Versión:** 0.1 (diseño)
**Fecha de inicio:** 2026-05-26
**Estado:** Fase 0 — Diseño y construcción

---

## Concepto

MIT es una estrategia de trading impulsada por inteligencia artificial que opera alrededor de **eventos macroeconómicos de alto impacto**. A diferencia de estrategias basadas en reglas fijas (como TBR), Claude actúa como el cerebro de decisión: lee el dato publicado, evalúa la sorpresa vs. expectativas, analiza el contexto de precio, y decide si operar, en qué dirección y con qué parámetros.

**Lo que ningún EA de reglas puede hacer — y MIT sí:**
- Leer y razonar sobre comunicados de bancos centrales en lenguaje natural
- Interpretar la magnitud y contexto de una sorpresa macroeconómica
- Distinguir entre un beat técnico y un beat genuino con implicaciones de mercado
- Adaptar su lógica a régimen sin ser reprogramado

---

## Posición en el portfolio

| Estrategia | Tipo | Horario | Relación con MIT |
|-----------|------|---------|-----------------|
| TBR | ORB momentum | Session open | Complementaria — distintos triggers |
| BreakoutNY | Ruptura NY | 14:30 srv | Complementaria — distintos triggers |
| CTR Reclaim | Liquidity sweep reversal | Intraday | Complementaria |
| RBR | Mean reversion rango | Intraday | Complementaria |
| **MIT** | **Macro event post-spike** | **Eventos específicos** | **Ortogonal a todas** |

MIT es **ortogonal** al resto del portfolio: opera en momentos que ninguna otra estrategia cubre.

---

## Instrumentos objetivo

| Instrumento | Eventos clave | Sesión |
|------------|--------------|--------|
| NAS100 | NFP, CPI, Fed, ISM, GDP | NY |
| SPX500 | NFP, CPI, Fed, ISM, GDP | NY |
| GBPJPY | BCE, BoJ, BoE, CPI EUR/GBP/JP | Londres/Tokyo |
| USDJPY | Fed, NFP, BoJ, CPI US/JP | NY/Tokyo |

---

## Estructura del repositorio

```
MIT/
├── README.md                        ← este archivo
├── docs/
│   ├── 01-estrategia.md             ← concepto, lógica, edge
│   ├── 02-arquitectura.md           ← stack técnico completo
│   ├── 03-pipeline-validacion.md    ← las 4 fases de validación
│   ├── 04-fase1-historical-replay.md← metodología Fase 1
│   ├── 05-fase2-shadow-mode.md      ← metodología Fase 2
│   ├── 06-prompt-engineering.md     ← diseño del prompt de Claude
│   ├── 07-risk-management.md        ← reglas de riesgo y circuit breakers
│   └── 08-roadmap.md                ← hoja de ruta y milestones
├── src/
│   ├── fase1_simulation.py          ← simulación histórica (Fase 1)
│   ├── ai_brain.py                  ← servidor FastAPI (cerebro MIT)
│   ├── data_bridge.mq5              ← EA puente MT5 ↔ Python
│   └── telegram_notifier.py        ← notificaciones
├── data/
│   ├── calendar/                    ← CSVs calendario Forex Factory
│   └── ohlcv/                       ← exports M5 desde MT5
└── results/
    ├── fase1/                       ← logs simulación histórica
    └── fase2/                       ← logs shadow mode
```

---

## Documentación

→ [Estrategia y Edge](docs/01-estrategia.md)
→ [Arquitectura Técnica](docs/02-arquitectura.md)
→ [Pipeline de Validación](docs/03-pipeline-validacion.md)
→ [Fase 1 — Historical Replay](docs/04-fase1-historical-replay.md)
→ [Fase 2 — Shadow Mode](docs/05-fase2-shadow-mode.md)
→ [Prompt Engineering](docs/06-prompt-engineering.md)
→ [Risk Management](docs/07-risk-management.md)
→ [Roadmap](docs/08-roadmap.md)
