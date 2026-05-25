# Blueprint — Trader Cuantitativo Profesional
> Archivo de referencia para Claude Code. Se carga vía `@07-Knowledge/Workflow/quant-trader-blueprint.md` desde CLAUDE.md.
> Cubre los 6 dominios del sistema cohesivo de skills. Leer completo al inicio de cualquier tarea de desarrollo cuantitativo avanzado.

---

## Mapa del sistema — 6 dominios

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRADER CUANTITATIVO PROFESIONAL              │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│  DOMINIO 1   │  DOMINIO 2   │  DOMINIO 3   │    DOMINIO 4       │
│  MQL5 + Dev  │  ML / Stats  │  Microestruc │    DevOps / Infra  │
├──────────────┴──────────────┴──────────────┴────────────────────┤
│              DOMINIO 5 — Risk & Portfolio                       │
├─────────────────────────────────────────────────────────────────┤
│              DOMINIO 6 — Research & Mejora Continua             │
└─────────────────────────────────────────────────────────────────┘
```

Cada dominio tiene: conceptos clave, instrucciones operativas para Claude Code, y criterios de calidad.

---

## DOMINIO 1 — Programación y Desarrollo MT5

### 1.1 MQL5 Avanzado

**Más allá de abrir/cerrar órdenes:**

```mql5
// Tester multitarea — configurar en OnTesterInit()
double OnTester()
{
   // Retornar métrica custom para optimización genética
   double pf     = TesterStatistics(STAT_PROFIT_FACTOR);
   double dd     = TesterStatistics(STAT_EQUITY_DD_RELATIVE);
   double trades = TesterStatistics(STAT_TRADES);
   if(trades < 30) return 0; // penalizar sample size insuficiente
   return pf * (1.0 - dd/100.0);
}

// Custom symbols — para backtesting con datos propios
long sym = CustomSymbolCreate("MY_SYMBOL", "Custom");
CustomRatesUpdate("MY_SYMBOL", rates_array, rates_count);

// Conexión a socket externo (bridge con Python)
int socket = SocketCreate();
if(SocketConnect(socket, "127.0.0.1", 5555, 3000))
{
   string msg = "GET_SIGNAL";
   uchar data[]; StringToCharArray(msg, data);
   SocketSend(socket, data, ArraySize(data));
}
```

**Exportación de datos de alta calidad:**
```mql5
// Ticks históricos — resolución máxima
MqlTick ticks[];
int count = CopyTicksRange(_Symbol, ticks, COPY_TICKS_ALL,
                           start_ms, end_ms);

// Guardar en CSV para Python
int file = FileOpen("ticks_export.csv", FILE_WRITE|FILE_CSV|FILE_ANSI);
FileWrite(file, "time_ms", "bid", "ask", "last", "volume", "flags");
for(int i=0; i<count; i++)
   FileWrite(file, ticks[i].time_msc, ticks[i].bid, ticks[i].ask,
             ticks[i].last, ticks[i].volume, ticks[i].flags);
FileClose(file);
```

**Reglas de código — nivel avanzado:**
- `OnTester()` custom obligatorio en todo EA que pase por optimización — nunca optimizar solo por Balance
- Usar `ENUM_STATISTICS` para extraer métricas dentro del tester
- Custom symbols para validar con datos de tick propios (evitar interpolación del broker)
- Nube de optimización MT5: solo activar cuando el espacio de parámetros > 10,000 passes
- Manejo de errores de conexión broker: retry con backoff exponencial, máximo 3 intentos

### 1.2 Python ↔ MT5 Bridge

**Arquitectura de comunicación:**

```
MT5 (MQL5)  ←──ZeroMQ──→  Python Bridge  ←──→  ML Model
     │                          │
     │                    (preprocessing,
     │                     feature eng,
     │                     inference)
     │
     └──→ Señal de trading (BUY/SELL/FLAT + SL + TP)
```

**Implementación ZeroMQ en MQL5:**
```mql5
#include <Zmq/Zmq.mqh>

Context context;
Socket publisher(context, ZMQ_PUB);

int OnInit()
{
   publisher.bind("tcp://*:5556");
   return INIT_SUCCEEDED;
}

void OnTick()
{
   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   string msg = StringFormat("%s|%.5f|%.5f|%lld",
                              _Symbol, tick.bid, tick.ask, tick.time_msc);
   ZmqMsg message(msg);
   publisher.send(message);
}
```

**Python side:**
```python
import zmq
import pandas as pd
import numpy as np

context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect("tcp://localhost:5556")
socket.setsockopt_string(zmq.SUBSCRIBE, "")

def receive_tick():
    msg = socket.recv_string()
    symbol, bid, ask, time_ms = msg.split("|")
    return {
        "symbol": symbol,
        "bid": float(bid),
        "ask": float(ask),
        "time_ms": int(time_ms)
    }
```

**Alternativas al ZeroMQ:**
- **Archivos compartidos**: más simple, latencia ~100ms — válido para M5+
- **REST API Flask**: bridge HTTP, fácil de debuggear, latencia ~50ms
- **ONNX directo en MQL5**: para modelos pequeños (no LSTM), cero latencia
  ```mql5
  #include <ONNX/OnnxRuntime.mqh>
  long model = OnnxCreate("model.onnx", ONNX_DEFAULT);
  ```

**Cuándo usar cada alternativa:**
| Método | Latencia | Complejidad | Usar cuando |
|--------|----------|-------------|-------------|
| Archivos CSV | ~100ms | Baja | M5+, backtesting |
| REST API | ~50ms | Media | Prototipos, M1+ |
| ZeroMQ | ~5ms | Alta | Producción, tick data |
| ONNX nativo | <1ms | Media | Modelos simples, M1 |

### 1.3 Optimización de Ejecución

```mql5
// Slippage control — crítico en prop firms
MqlTradeRequest request = {};
request.action    = TRADE_ACTION_DEAL;
request.deviation = 10;  // máximo 10 puntos de slippage aceptado
request.type_filling = ORDER_FILLING_FOK; // Fill or Kill — sin fills parciales

// Verificar spread antes de entrar
double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
if(spread > MaxSpreadPoints * _Point) return; // abortar si spread excesivo

// Tipos de órdenes según contexto
// MARKET: ejecución inmediata, más slippage
// LIMIT:  sin slippage, puede no ejecutarse
// STOP:   breakout confirmation, slippage en dirección del movimiento
```

**Instrucciones para Claude Code — Dominio 1:**
- Al escribir cualquier EA de producción: incluir `OnTester()` custom con penalización por trades < 30
- Al implementar bridge Python↔MT5: preguntar el timeframe antes de elegir método de comunicación
- Al manejar órdenes: siempre incluir `deviation` y `type_filling` explícitos
- Al exportar datos: usar ticks cuando el backtest es < 1 año; OHLCV para períodos más largos

---

## DOMINIO 2 — Machine Learning y Estadística Cuantitativa

### 2.1 Feature Engineering Financiero

**Pipeline obligatorio antes de cualquier modelo:**

```python
import pandas as pd
import numpy as np
from statsmodels.tsa.stattools import adfuller

def check_stationarity(series, name="series"):
    """ADF test — todo feature debe ser estacionario antes de entrar al modelo"""
    result = adfuller(series.dropna())
    pvalue = result[1]
    is_stationary = pvalue < 0.05
    print(f"{name}: p={pvalue:.4f} → {'ESTACIONARIA' if is_stationary else 'NO ESTACIONARIA ⚠️'}")
    return is_stationary

def fractional_differentiation(series, d=0.4, thresh=1e-5):
    """
    López de Prado — Advances in Financial ML, Cap 5.
    Diferenciación fraccional: preserva memoria mientras logra estacionariedad.
    d=0.4 es el mínimo típico para OHLCV de forex/indices.
    """
    w = [1.0]
    for k in range(1, len(series)):
        w.append(-w[-1] * (d - k + 1) / k)
        if abs(w[-1]) < thresh:
            break
    w = np.array(w[::-1])
    result = []
    for i in range(len(w)-1, len(series)):
        result.append(np.dot(w, series[i-len(w)+1:i+1]))
    return pd.Series(result, index=series.index[len(w)-1:])

# Features estándar del stack
def build_features(df):
    """df debe tener columnas: open, high, low, close, volume, time"""

    # Price-based (todos deben ser estacionarios)
    df['returns']      = df['close'].pct_change()
    df['log_returns']  = np.log(df['close']).diff()
    df['hl_range']     = (df['high'] - df['low']) / df['close']
    df['gap']          = (df['open'] - df['close'].shift(1)) / df['close'].shift(1)

    # Volatilidad realizada (ventana rodante)
    df['vol_5']  = df['log_returns'].rolling(5).std()
    df['vol_20'] = df['log_returns'].rolling(20).std()
    df['vol_ratio'] = df['vol_5'] / df['vol_20']  # régimen: >1 = alta vol

    # ATR normalizado
    tr = pd.concat([
        df['high'] - df['low'],
        (df['high'] - df['close'].shift()).abs(),
        (df['low']  - df['close'].shift()).abs()
    ], axis=1).max(axis=1)
    df['atr_14'] = tr.rolling(14).mean()
    df['atr_norm'] = df['atr_14'] / df['close']

    # Momentum
    for p in [5, 10, 20]:
        df[f'mom_{p}'] = df['close'].pct_change(p)

    # Volume features
    df['vol_ma'] = df['volume'].rolling(20).mean()
    df['vol_ratio_vol'] = df['volume'] / df['vol_ma']

    # Diferenciación fraccional del precio (estacionario pero con memoria)
    df['frac_diff_close'] = fractional_differentiation(df['close'], d=0.4)

    # Verificar estacionariedad de features clave
    for col in ['returns', 'log_returns', 'frac_diff_close', 'vol_ratio']:
        check_stationarity(df[col].dropna(), col)

    return df.dropna()
```

**Features prohibidos (look-ahead bias):**
```python
# MAL — usa información futura
df['future_return'] = df['close'].pct_change().shift(-1)

# MAL — normalización con datos futuros
df['normalized'] = (df['close'] - df['close'].mean()) / df['close'].std()

# BIEN — normalización rolling (solo datos pasados)
df['normalized'] = (df['close'] - df['close'].rolling(100).mean()) / df['close'].rolling(100).std()
```

### 2.2 Modelos de Series Temporales

**Selección de modelo según problema:**

| Problema | Modelo recomendado | Por qué |
|----------|--------------------|---------|
| Clasificación dirección (BUY/SELL/FLAT) | XGBoost / LightGBM | Robusto, rápido, interpretable |
| Secuencias temporales largas | LSTM / GRU | Captura dependencias temporales |
| Datos de alta dimensionalidad | Transformer (TFT) | Atención sobre features y tiempo |
| Filtrado de estado (régimen) | Kalman Filter | Estimación en tiempo real, bajo costo |
| Volatilidad | GARCH(1,1) | Estándar industria, rápido |

**LSTM para señales de trading:**
```python
import torch
import torch.nn as nn

class TradingLSTM(nn.Module):
    def __init__(self, input_size, hidden_size=64, num_layers=2, dropout=0.3):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            dropout=dropout,
            batch_first=True
        )
        self.classifier = nn.Sequential(
            nn.Linear(hidden_size, 32),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(32, 3)  # BUY=0, FLAT=1, SELL=2
        )

    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        return self.classifier(lstm_out[:, -1, :])  # último timestep

# Etiquetado — Triple Barrier Method (López de Prado)
def triple_barrier_label(prices, h, pt_sl=[1, 1], min_ret=0.01):
    """
    Etiqueta cada barra con 1 (UP), -1 (DOWN), 0 (TIMEOUT).
    Evita el sesgo de lookahead usando barreras explícitas.
    pt_sl: [profit_take_multiplier, stop_loss_multiplier]
    """
    labels = pd.Series(index=prices.index, dtype=float)
    for i, t in enumerate(prices.index[:-h]):
        window = prices.iloc[i:i+h]
        ret = (window / prices.iloc[i]) - 1
        pt = min_ret * pt_sl[0]
        sl = -min_ret * pt_sl[1]
        if (ret >= pt).any():
            labels[t] = 1
        elif (ret <= sl).any():
            labels[t] = -1
        else:
            labels[t] = 0
    return labels
```

**Kalman Filter para detección de régimen:**
```python
from pykalman import KalmanFilter

def kalman_trend_filter(prices):
    """
    Estima tendencia subyacente eliminando ruido.
    Útil para detectar cambio de régimen sin retraso excesivo.
    """
    kf = KalmanFilter(
        transition_matrices=[1],
        observation_matrices=[1],
        initial_state_mean=prices.iloc[0],
        initial_state_covariance=1,
        observation_covariance=1,
        transition_covariance=0.01  # ajustar: más bajo = más smooth
    )
    state_means, _ = kf.filter(prices.values)
    return pd.Series(state_means.flatten(), index=prices.index)
```

### 2.3 Validación Robusta — Sin Data Leakage

```python
from sklearn.model_selection import TimeSeriesSplit

def walk_forward_validation(model_class, X, y, n_splits=5, min_train_size=0.6):
    """
    Walk-forward cross-validation correcta para series temporales.
    NUNCA usar KFold estándar — mezcla datos futuros con pasados.
    """
    tscv = TimeSeriesSplit(n_splits=n_splits)
    results = []

    for fold, (train_idx, test_idx) in enumerate(tscv.split(X)):
        X_train, X_test = X.iloc[train_idx], X.iloc[test_idx]
        y_train, y_test = y.iloc[train_idx], y.iloc[test_idx]

        # Normalización DENTRO del fold — solo con datos de train
        from sklearn.preprocessing import StandardScaler
        scaler = StandardScaler()
        X_train_sc = scaler.fit_transform(X_train)
        X_test_sc  = scaler.transform(X_test)  # transform solo, no fit

        model = model_class()
        model.fit(X_train_sc, y_train)
        preds = model.predict(X_test_sc)

        # Métricas financieras, no solo accuracy
        from sklearn.metrics import classification_report
        report = classification_report(y_test, preds, output_dict=True)
        results.append({
            "fold": fold,
            "accuracy": report["accuracy"],
            "precision_buy": report.get("1", {}).get("precision", 0),
            "recall_buy": report.get("1", {}).get("recall", 0),
        })
        print(f"Fold {fold}: acc={report['accuracy']:.3f}")

    return pd.DataFrame(results)

# Adversarial Validation — detectar distribution shift entre IS y OOS
def adversarial_validation(X_train, X_test):
    """
    Si un clasificador puede distinguir train de test con AUC > 0.8,
    hay distribution shift — el modelo no generalizará.
    """
    import xgboost as xgb
    from sklearn.metrics import roc_auc_score

    X_train['is_test'] = 0
    X_test['is_test'] = 1
    combined = pd.concat([X_train, X_test]).sample(frac=1)

    clf = xgb.XGBClassifier(n_estimators=100, verbosity=0)
    tscv = TimeSeriesSplit(n_splits=3)
    aucs = []
    for train_idx, val_idx in tscv.split(combined):
        clf.fit(combined.iloc[train_idx].drop('is_test', axis=1),
                combined.iloc[train_idx]['is_test'])
        pred = clf.predict_proba(combined.iloc[val_idx].drop('is_test', axis=1))[:,1]
        aucs.append(roc_auc_score(combined.iloc[val_idx]['is_test'], pred))

    auc = np.mean(aucs)
    print(f"Adversarial AUC: {auc:.3f}")
    if auc > 0.8:
        print("⚠️  DISTRIBUTION SHIFT DETECTADO — modelo no generalizará")
    else:
        print("✓  Distribuciones similares — OK para walk-forward")
    return auc
```

**Métricas financieras obligatorias (además de accuracy):**
```python
def financial_metrics(returns):
    """returns: pd.Series de retornos por trade"""
    sharpe  = returns.mean() / returns.std() * np.sqrt(252)
    sortino = returns.mean() / returns[returns < 0].std() * np.sqrt(252)
    calmar  = returns.sum() / abs(returns.cumsum().cummin().min())
    max_dd  = (returns.cumsum() - returns.cumsum().cummax()).min()

    print(f"Sharpe:  {sharpe:.3f}  (mínimo: 1.0)")
    print(f"Sortino: {sortino:.3f}  (mínimo: 1.5)")
    print(f"Calmar:  {calmar:.3f}  (mínimo: 0.5)")
    print(f"Max DD:  {max_dd:.2%}  (máximo: -10%)")
    return {"sharpe": sharpe, "sortino": sortino, "calmar": calmar, "max_dd": max_dd}
```

**Instrucciones para Claude Code — Dominio 2:**
- Todo feature nuevo: verificar estacionariedad con ADF antes de incluirlo
- Normalización siempre dentro del fold de validación — nunca global
- Etiquetado: usar Triple Barrier Method, no retornos forward simples
- Al implementar walk-forward: `TimeSeriesSplit`, nunca `KFold`
- Antes de deployment: correr adversarial validation entre IS y OOS
- Incluir siempre Sharpe, Sortino, Calmar además de accuracy

---

## DOMINIO 3 — Microestructura de Mercado y Alpha

### 3.1 Costos de Transacción Reales

```python
def true_cost_per_trade(symbol_info, direction="buy", volume=0.01):
    """
    Costo real de un trade incluyendo todos los componentes.
    Usar antes de declarar cualquier estrategia como viable.
    """
    spread_points = symbol_info['spread']
    commission    = symbol_info['commission_per_lot'] * volume
    swap_daily    = symbol_info['swap_long' if direction=="buy" else 'swap_short']

    # Slippage estimado (conservador)
    slippage_points = spread_points * 0.5  # 50% del spread como slippage

    total_points = spread_points + slippage_points
    total_usd    = commission + abs(swap_daily)

    print(f"Spread:     {spread_points} pts")
    print(f"Slippage:   {slippage_points:.1f} pts (estimado)")
    print(f"Commission: ${commission:.2f}")
    print(f"Swap/día:   ${swap_daily:.2f}")
    print(f"Break-even mínimo: {total_points} pts + ${total_usd:.2f}")
    return total_points, total_usd
```

**Horarios de liquidez — cuándo evitar entrar:**

| Instrumento | Alta liquidez | Baja liquidez (evitar) |
|-------------|--------------|------------------------|
| XAUUSD | 08:00–12:00 NY, 13:30–16:00 NY | 22:00–02:00 UTC |
| NAS100 | 09:30–11:30 NY, 14:00–16:00 NY | Pre-market, primeros 5 min |
| EURUSD | 07:00–09:00 London, 13:30–15:00 NY | Asian session |
| DJI30 | 09:30–11:00 NY | Overnight |

**Rollover CFD — impacto real:**
```python
def rollover_impact(swap_points_per_day, hold_days, lot_size, tick_value):
    """
    Para posiciones overnight en CFDs.
    XAUUSD: swap típico -$3 a -$8 por lote estándar por día en longs.
    """
    cost = swap_points_per_day * hold_days * lot_size * tick_value
    print(f"Costo rollover {hold_days} días: ${cost:.2f}")
    return cost

# Regla: si el rollover > 10% del TP esperado, reconsiderar estrategia overnight
```

### 3.2 Detección de Régimen de Mercado

```python
def detect_market_regime(prices, vol_window=20, trend_window=50):
    """
    Clasificación en 4 regímenes: trend_up, trend_down, range_high_vol, range_low_vol.
    Usar para activar/desactivar estrategias según régimen.
    """
    returns  = prices.pct_change()
    vol      = returns.rolling(vol_window).std()
    vol_med  = vol.rolling(200).median()
    trend    = prices.rolling(trend_window).mean()

    regimes = []
    for i in range(len(prices)):
        is_high_vol = vol.iloc[i] > vol_med.iloc[i] * 1.5
        is_uptrend  = prices.iloc[i] > trend.iloc[i]

        if is_uptrend and not is_high_vol:
            regimes.append("trend_up")
        elif not is_uptrend and not is_high_vol:
            regimes.append("trend_down")
        elif is_high_vol:
            regimes.append("high_vol_chop")
        else:
            regimes.append("low_vol_range")

    return pd.Series(regimes, index=prices.index)

# Kolmogorov-Smirnov para detectar cambio estructural
from scipy.stats import ks_2samp

def detect_structural_break(returns_is, returns_oos, alpha=0.05):
    """
    Si KS p-value < alpha: las distribuciones son distintas.
    Indica cambio de régimen — el modelo IS puede no funcionar en OOS.
    """
    stat, pvalue = ks_2samp(returns_is, returns_oos)
    changed = pvalue < alpha
    print(f"KS stat={stat:.4f}, p={pvalue:.4f}")
    print(f"Régimen: {'CAMBIO DETECTADO ⚠️' if changed else 'ESTABLE ✓'}")
    return changed
```

### 3.3 Filtro de Eventos Macroeconómicos

```python
# Eventos de alto impacto que invalidan señales técnicas
HIGH_IMPACT_EVENTS = [
    "NFP",           # Non-Farm Payrolls — primer viernes del mes
    "FOMC",          # Fed rate decision
    "CPI",           # Consumer Price Index
    "GDP",           # Gross Domestic Product
    "ECB_RATE",      # European Central Bank
    "BOE_RATE",      # Bank of England
    "JOBLESS",       # Initial Jobless Claims
]

def is_news_window(dt, calendar_df, buffer_minutes=30):
    """
    Retorna True si dt está dentro de la ventana de buffer de un evento de alto impacto.
    calendar_df: DataFrame con columnas [datetime, event, impact]
    """
    high_impact = calendar_df[calendar_df['impact'] == 'HIGH']
    for _, event in high_impact.iterrows():
        delta = abs((dt - event['datetime']).total_seconds() / 60)
        if delta <= buffer_minutes:
            return True, event['event']
    return False, None

# Regla operativa: pausar EAs 30 min antes y 15 min después de eventos HIGH
```

**Instrucciones para Claude Code — Dominio 3:**
- Antes de declarar viabilidad: calcular `true_cost_per_trade` y verificar que el edge supera los costos
- Al construir filtros de sesión: respetar horarios de liquidez por instrumento
- Para estrategias overnight: incluir cálculo de rollover en el P&L esperado
- Al comparar IS vs OOS: correr `detect_structural_break` — si hay cambio de régimen, el modelo necesita reentrenamiento
- Toda estrategia debe tener filtro de noticias configurable (activar/desactivar por input)

---

## DOMINIO 4 — Infraestructura y DevOps

### 4.1 Backtesting con Datos de Tick

```python
def load_mt5_ticks(filepath):
    """
    MT5 exporta ticks en UTF-16 con BOM, separado por tabs.
    Columnas: Time, Bid, Ask, Last, Volume, Flags
    """
    df = pd.read_csv(
        filepath,
        encoding='utf-16',
        sep='\t',
        parse_dates=['Time'],
        dayfirst=False
    )
    df.columns = [c.strip() for c in df.columns]
    df['spread_points'] = ((df['Ask'] - df['Bid']) / df['Ask'] * 10000).round(1)
    df['mid'] = (df['Bid'] + df['Ask']) / 2
    return df

def simulate_fill(signal_time, ticks_df, direction, sl_points, tp_points):
    """
    Simula fill realista usando tick data.
    Fill en Ask para LONG, en Bid para SHORT.
    Modela slippage como función del spread en el momento del fill.
    """
    window = ticks_df[ticks_df['Time'] >= signal_time].head(5)
    if window.empty:
        return None

    first_tick = window.iloc[0]
    spread = first_tick['spread_points']

    if direction == "BUY":
        entry = first_tick['Ask']
        slippage = spread * 0.3  # 30% del spread como slippage
        entry += slippage * first_tick['Ask'] / 10000
        sl = entry - sl_points * first_tick['Ask'] / 10000
        tp = entry + tp_points * first_tick['Ask'] / 10000
    else:
        entry = first_tick['Bid']
        slippage = spread * 0.3
        entry -= slippage * first_tick['Bid'] / 10000
        sl = entry + sl_points * first_tick['Bid'] / 10000
        tp = entry - tp_points * first_tick['Bid'] / 10000

    return {"entry": entry, "sl": sl, "tp": tp, "slippage_pts": slippage}
```

### 4.2 Sistema de Monitoreo y Kill-Switch

```python
import logging
from datetime import datetime, timedelta

class EAMonitor:
    """
    Monitor de salud para EAs en producción.
    Detecta: model drift, anomalías de broker, secuencias de pérdidas.
    """
    def __init__(self, ea_name, max_consecutive_losses=5,
                 max_daily_dd=0.03, alert_webhook=None):
        self.ea_name = ea_name
        self.max_losses = max_consecutive_losses
        self.max_daily_dd = max_daily_dd
        self.webhook = alert_webhook
        self.trades = []
        self.logger = self._setup_logger()

    def _setup_logger(self):
        logging.basicConfig(
            filename=f"logs/{self.ea_name}_{datetime.now().date()}.log",
            level=logging.INFO,
            format='%(asctime)s | %(levelname)s | %(message)s'
        )
        return logging.getLogger(self.ea_name)

    def register_trade(self, pnl, balance):
        self.trades.append({"pnl": pnl, "balance": balance, "time": datetime.now()})
        self.logger.info(f"Trade: PnL={pnl:.2f}, Balance={balance:.2f}")
        self._check_kill_conditions(balance)

    def _check_kill_conditions(self, current_balance):
        if len(self.trades) < 2:
            return

        # Pérdidas consecutivas
        recent = [t['pnl'] for t in self.trades[-self.max_losses:]]
        if all(p < 0 for p in recent) and len(recent) == self.max_losses:
            self._trigger_kill("CONSECUTIVE_LOSSES")
            return

        # Daily drawdown
        today_trades = [t for t in self.trades
                       if t['time'].date() == datetime.now().date()]
        if today_trades:
            day_start = today_trades[0]['balance'] - today_trades[0]['pnl']
            daily_dd = (current_balance - day_start) / day_start
            if daily_dd < -self.max_daily_dd:
                self._trigger_kill(f"DAILY_DD_{daily_dd:.1%}")

    def _trigger_kill(self, reason):
        msg = f"🚨 KILL SWITCH ACTIVADO | EA: {self.ea_name} | Razón: {reason}"
        self.logger.critical(msg)
        print(msg)
        # Enviar señal al EA via archivo compartido
        with open(f"kill_switch_{self.ea_name}.txt", "w") as f:
            f.write(f"{reason}|{datetime.now().isoformat()}")
        # Opcional: webhook (Telegram, Slack)
        if self.webhook:
            import requests
            requests.post(self.webhook, json={"text": msg})

# En MQL5 — verificar kill switch en OnTick()
# if(FileIsExist("kill_switch_BreakoutNY.txt")) { ExpertRemove(); }
```

### 4.3 Control de Versiones y Entornos

```python
# requirements.txt — entorno replicable
"""
pandas==2.1.0
numpy==1.24.0
scikit-learn==1.3.0
xgboost==1.7.6
lightgbm==4.0.0
torch==2.0.1
statsmodels==0.14.0
pykalman==0.9.5
pyzmq==25.1.0
scipy==1.11.0
"""

# .gitignore para el repo
"""
*.set          # Sets de producción — no versionar con credenciales
*.log          # Logs de trading
kill_switch_*  # Archivos de kill switch
__pycache__/
.env           # Variables de entorno (API keys, etc.)
"""
```

**Git workflow para EAs:**
```bash
# Rama por estrategia
git checkout -b feature/BreakoutNY-XAUUSD-SetF

# Commit con contexto de backtest
git commit -m "BreakoutNY XAUUSD: Set F - PF=1.82 OOS, DD=4.1%, VIABLE"

# Tag en producción
git tag -a v1.0-BreakoutNY-NAS100 -m "Producción FundingPips - validado IS/OOS/WF"
```

**Instrucciones para Claude Code — Dominio 4:**
- Todo script de backtest: usar `load_mt5_ticks()` para datos de tick, no OHLCV interpolado
- Al crear scripts de monitoreo: incluir kill-switch por archivo compartido (compatible con MQL5)
- Commits: siempre incluir métricas clave del backtest en el mensaje
- Variables de entorno: nunca hardcodear IPs, tokens o credenciales — usar `.env`

---

## DOMINIO 5 — Risk & Portfolio

### 5.1 Sizing Dinámico

```python
def kelly_criterion(win_rate, avg_win, avg_loss):
    """
    Kelly completo: f* = (p*b - q) / b
    p = win_rate, q = 1-p, b = avg_win/avg_loss
    IMPORTANTE: usar Half-Kelly en práctica (f*/2) — Kelly completo es demasiado agresivo
    """
    b = avg_win / abs(avg_loss)
    q = 1 - win_rate
    kelly_full = (win_rate * b - q) / b
    kelly_half = kelly_full / 2

    print(f"Kelly completo: {kelly_full:.1%} del capital")
    print(f"Half-Kelly (recomendado): {kelly_half:.1%} del capital")

    # Límite prop firm: máximo 3% por trade
    safe_f = min(kelly_half, 0.03)
    print(f"Aplicado con límite prop firm: {safe_f:.1%}")
    return safe_f

def atr_based_position_size(account_balance, risk_usd, atr_value,
                             atr_multiplier=1.5, tick_value=1.0):
    """
    SL basado en ATR — adapta el riesgo a la volatilidad actual.
    SL = ATR * multiplier
    Lote = RiskUSD / (SL_points * tick_value)
    """
    sl_points = atr_value * atr_multiplier
    lot_size  = risk_usd / (sl_points * tick_value)
    lot_size  = round(lot_size, 2)

    print(f"ATR: {atr_value:.5f}")
    print(f"SL:  {sl_points:.5f} ({sl_points/atr_value:.1f}x ATR)")
    print(f"Lot: {lot_size:.2f} (riesgo: ${risk_usd})")
    return lot_size, sl_points
```

### 5.2 Correlación entre Estrategias

```python
def portfolio_correlation_check(strategies_returns):
    """
    strategies_returns: dict {name: pd.Series of daily returns}
    Alerta si correlación > 0.7 entre dos estrategias — reducen diversificación
    """
    df = pd.DataFrame(strategies_returns)
    corr = df.corr()

    print("\nMatriz de correlación:")
    print(corr.round(3))

    # Alertas
    for i in range(len(corr.columns)):
        for j in range(i+1, len(corr.columns)):
            c = corr.iloc[i,j]
            if abs(c) > 0.7:
                print(f"⚠️  Alta correlación: {corr.columns[i]} ↔ {corr.columns[j]}: {c:.3f}")

    return corr

def portfolio_drawdown(strategies_returns, weights=None):
    """Drawdown del portfolio combinado vs individual"""
    df = pd.DataFrame(strategies_returns)
    if weights is None:
        weights = {col: 1/len(df.columns) for col in df.columns}

    portfolio = sum(df[k] * v for k, v in weights.items())
    cumulative = (1 + portfolio).cumprod()
    dd = (cumulative / cumulative.cummax() - 1)

    print(f"Max DD portfolio: {dd.min():.2%}")
    print(f"Max DD individual:")
    for col in df.columns:
        cum = (1 + df[col]).cumprod()
        ind_dd = (cum / cum.cummax() - 1).min()
        print(f"  {col}: {ind_dd:.2%}")
    return dd
```

### 5.3 Plan de Drawdown

```
NIVEL 1 — DD < 3% (Normal)
  → Operación estándar, sin cambios

NIVEL 2 — DD 3%–5% (Alerta)
  → Reducir RiskAmountUSD al 50%
  → Revisar Trade Journal — ¿hay patrón en las pérdidas?
  → No abrir nuevas estrategias en este período

NIVEL 3 — DD 5%–7% (Crítico)
  → Reducir RiskAmountUSD al 25%
  → Solo operar la estrategia con mejor Sharpe histórico
  → Revisar si hay cambio de régimen (KS test)

NIVEL 4 — DD > 7% (Emergencia)
  → Pausar todos los EAs
  → Análisis completo antes de reactivar
  → Verificar: ¿bug en el EA? ¿cambio de régimen? ¿datos corruptos?
```

**Instrucciones para Claude Code — Dominio 5:**
- Al calcular lot size: siempre usar `atr_based_position_size` — nunca lot fijo sin ATR
- Antes de agregar una nueva estrategia al portfolio: correr `portfolio_correlation_check`
- El plan de drawdown es operativo — implementarlo como lógica en el monitor, no solo documentación

---

## DOMINIO 6 — Research y Mejora Continua

### 6.1 Papers y Conceptos Clave

**López de Prado — Advances in Financial Machine Learning:**
- Cap 2: Financial Data Structures (tick bars > time bars para ML)
- Cap 4: Labeling (Triple Barrier Method — ver Dominio 2)
- Cap 5: Fractional Differentiation (ver Dominio 2)
- Cap 7: Cross-Validation in Finance (Purged KFold)
- Cap 8: Feature Importance (MDI, MDA, SFI)
- Cap 10: Bet Sizing (Kelly aplicado a ML)

**Purged KFold (evitar contaminación temporal):**
```python
from mlfinlab.cross_validation import PurgedKFold

# Purge: elimina observaciones en train que solapan con test en tiempo
# Embargo: añade buffer temporal adicional entre train y test
cv = PurgedKFold(n_splits=5, t1=events['t1'], pct_embargo=0.01)
```

**Tick Bars vs Time Bars:**
```python
def build_tick_bars(ticks_df, bar_size=1000):
    """
    Agrupa N ticks en una barra — independiente del tiempo.
    Ventaja: distribución de retornos más normal (menos leptocúrtica).
    Mejor para ML que velas de tiempo fijo.
    """
    bars = []
    for i in range(0, len(ticks_df), bar_size):
        chunk = ticks_df.iloc[i:i+bar_size]
        bars.append({
            'open':   chunk['mid'].iloc[0],
            'high':   chunk['mid'].max(),
            'low':    chunk['mid'].min(),
            'close':  chunk['mid'].iloc[-1],
            'volume': chunk['Volume'].sum(),
            'ticks':  len(chunk),
            'time':   chunk['Time'].iloc[-1]
        })
    return pd.DataFrame(bars)
```

### 6.2 Diario Algorítmico — Estructura

Cada entrada en `Trade-Journal/` debe contener:

```markdown
## [Fecha] — [Estrategia] — [Instrumento]

### Setup observado
- Condición de entrada: [descripción exacta]
- Régimen de mercado: [trend_up / trend_down / high_vol_chop / low_vol_range]
- Spread al momento de entrada: [X puntos]
- Evento macro activo: [sí/no — cuál]

### Resultado
- PnL: [+/- USD]
- SL activado / TP alcanzado / Expiración
- Slippage real vs estimado: [X puntos]

### Observación (sin conclusiones precipitadas)
- [Lo que ocurrió factualmente]
- Pendiente de investigación: [sí/no]

### Hipótesis para backtest
- [Si aplica — qué probar en el próximo ciclo IS]
```

### 6.3 Escepticismo Sistemático

**Checklist antes de declarar VIABLE cualquier resultado:**

```
□ ¿El PF se mantiene si aumento slippage 2x?
□ ¿El resultado depende de 1–3 trades excepcionales?
□ ¿Funciona en años individuales o solo en el período completo?
□ ¿Los parámetros son estables en ±20% o son un pico?
□ ¿Pasó adversarial validation (AUC < 0.8)?
□ ¿El KS test entre IS y OOS no detectó cambio de régimen?
□ ¿Sample size > 30 trades en OOS? (preferible > 100)
□ ¿El edge supera los costos reales (spread + comisión + swap)?
□ ¿El modelo fue entrenado con datos del futuro en algún paso?
□ ¿La normalización fue siempre rolling, nunca global?
```

**Instrucciones para Claude Code — Dominio 6:**
- Al revisar cualquier backtest: ejecutar el checklist completo arriba
- Al implementar ML: usar tick bars si hay datos de tick disponibles
- Al documentar trades: seguir la estructura del diario — observaciones, no conclusiones
- Al citar investigación: referenciar capítulo específico de López de Prado cuando aplique

---

## Índice de referencia rápida

| Necesito... | Ir a... |
|-------------|---------|
| Escribir bridge Python↔MT5 | Dominio 1.2 |
| Optimizar EA con métrica custom | Dominio 1.1 → `OnTester()` |
| Construir features para ML | Dominio 2.1 |
| Validar modelo sin data leakage | Dominio 2.3 |
| Detectar cambio de régimen | Dominio 3.2 |
| Calcular costo real de un trade | Dominio 3.1 |
| Simular fill con tick data | Dominio 4.1 |
| Implementar kill-switch | Dominio 4.2 |
| Calcular lot size con Kelly/ATR | Dominio 5.1 |
| Verificar correlación de portfolio | Dominio 5.2 |
| Aplicar Triple Barrier labeling | Dominio 2.2 |
| Implementar fractional diff | Dominio 2.1 |
| Usar Purged KFold | Dominio 6.1 |
| Construir tick bars | Dominio 6.1 |
| Correr checklist de escepticismo | Dominio 6.3 |
