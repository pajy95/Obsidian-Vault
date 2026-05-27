# MIT — Arquitectura Técnica

## Visión general

```
Ubuntu VPS (Contabo)
│
├── MT5 (Wine)
│   └── data_bridge.mq5
│       ├── Envía OHLCV M5 cada cierre de vela → POST /data
│       ├── Envía estado de cuenta + posiciones abiertas
│       └── Polling GET /command cada 3 segundos
│
├── ai_brain.py  (FastAPI · localhost:5000)
│   ├── Buffer OHLCV por instrumento
│   ├── Detector de eventos (lee calendario)
│   ├── Motor de decisión → Claude API
│   ├── Cola de comandos para el EA
│   └── Logger de todas las decisiones
│
├── telegram_notifier.py
│   └── Notificaciones: decisión + razón + resultado
│
└── Claude API (claude-sonnet-4-6)
    └── Recibe contexto → devuelve JSON estructurado
```

---

## Componentes detallados

### 1. data_bridge.mq5 (EA puente)

El EA más simple posible: solo ojos y manos. Sin lógica de trading propia.

**Responsabilidades:**
- `OnInit()` → registrar instrumento en el servidor
- `OnTick()` → detectar cierre de vela M5 → WebRequest POST /data
- `OnTimer()` → cada 3s → GET /command → ejecutar si hay orden pendiente
- `OnTradeTransaction()` → notificar apertura/cierre al servidor

**Datos que envía al servidor (JSON):**
```json
{
  "instrument": "NAS100",
  "timestamp": "2026-09-05T13:30:00Z",
  "candles_m5": [
    {"t": "13:00", "o": 19405, "h": 19420, "l": 19398, "c": 19415, "v": 1250},
    ...
  ],
  "account": {
    "balance": 5000.0,
    "equity": 4985.5,
    "open_positions": []
  }
}
```

**Comandos que recibe del servidor:**
```json
{
  "command": "BUY",
  "instrument": "NAS100",
  "lots": 0.01,
  "sl_points": 500,
  "tp_points": 2000,
  "comment": "MIT_NFP_20260905",
  "magic": 300001
}
```

**Comandos disponibles:** `BUY` · `SELL` · `CLOSE` · `MODIFY_SL` · `NOOP`

---

### 2. ai_brain.py (FastAPI)

Servidor central. Mantiene estado y orquesta las llamadas a Claude.

**Endpoints:**
```
POST /data          ← recibe velas del EA
GET  /command       ← EA consulta si hay orden pendiente
POST /confirm       ← EA confirma ejecución de orden
GET  /status        ← dashboard de estado del sistema
```

**Estado interno:**
```python
state = {
    "NAS100": {
        "candles":    deque(maxlen=50),  # últimas 50 velas M5
        "positions":  [],
        "last_event": None,
        "pending_cmd": None
    },
    ...
}
```

**Flujo en evento:**
1. Detector compara timestamp actual con calendario de eventos
2. Si hay evento en los próximos 60 segundos → activa modo espera
3. Cuando llegan las velas post-evento → construye prompt
4. Llama a Claude API → parsea JSON de respuesta
5. Si `trade: true` → coloca comando en cola
6. EA recoge el comando en próximo polling

---

### 3. Integración Claude API

```python
import anthropic

client = anthropic.Anthropic()

def ask_claude(instrument: str, event: dict, candles: list, account: dict) -> dict:
    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=500,
        system=SYSTEM_PROMPT,
        messages=[{
            "role": "user",
            "content": build_prompt(instrument, event, candles, account)
        }]
    )
    return parse_json_response(response.content[0].text)
```

**Latencia esperada:** 1-3 segundos por llamada — aceptable para M5.

---

### 4. Magic Numbers MIT

| Instrumento | Magic |
|-------------|-------|
| NAS100 | 300001 |
| SPX500 | 300002 |
| USDJPY | 300003 |
| GBPJPY | 300004 |

Rango 300XXX reservado para MIT. No colisiona con TBR (202501-202514) ni RBR (202511).

---

### 5. Gestión de riesgo en el EA (hardcoded)

El EA aplica límites duros **independientemente** de lo que diga Claude:

```mq5
// Límites que el EA nunca viola
#define MAX_POSITIONS_PER_INSTRUMENT  1
#define MAX_DAILY_LOSS_USD            50.0   // ajustar por cuenta
#define MIN_SL_POINTS                 200    // SL mínimo obligatorio
#define MAX_LOTS                      0.05   // tamaño máximo
```

---

### 6. Systemd service (Ubuntu)

```ini
[Unit]
Description=MIT AI Brain
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/mit
ExecStart=/home/ubuntu/mit/venv/bin/uvicorn ai_brain:app --host 127.0.0.1 --port 5000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable mit-brain
sudo systemctl start mit-brain
```

---

## Stack tecnológico

| Componente | Tecnología | Versión mínima |
|-----------|-----------|---------------|
| EA puente | MQL5 | MT5 build 3000+ |
| Servidor IA | Python + FastAPI | Python 3.11 |
| ASGI server | uvicorn | 0.30+ |
| Claude API | anthropic SDK | 0.30+ |
| Notificaciones | python-telegram-bot | 21+ |
| Persistencia logs | SQLite (sqlite3 stdlib) | — |
| SO servidor | Ubuntu 22.04 LTS | — |

---

## Diagrama de flujo completo

```
[Evento NFP 13:30]
      │
      ▼
ai_brain detecta evento en calendario
      │
      ▼ (espera cierre vela M5 post-anuncio)
      │
EA envía velas → POST /data (13:35)
      │
      ▼
ai_brain construye prompt con:
  - Dato actual vs esperado vs anterior
  - Sorpresa en % y en valor absoluto
  - Últimas 12 velas M5 pre-anuncio
  - Vela M5 del spike (la del anuncio)
  - ATR, tendencia H4, posiciones abiertas
      │
      ▼
Claude API → JSON en 1-3 seg
  { trade: true, direction: BUY,
    sl_pips: 25, tp_pips: 100,
    confidence: 82,
    reason: "NFP beat masivo +89K..." }
      │
      ▼
ai_brain → cola de comandos
      │
      ▼ (próximo polling ~3 seg)
EA GET /command → ejecuta BUY
      │
      ▼
EA POST /confirm → trade abierto
      │
      ▼
Telegram: "MIT BUY NAS100 — NFP +89K beat.
           SL: 19380 | TP: 19620 | Conf: 82%"
```
