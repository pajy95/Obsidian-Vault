# Análisis de Monte Carlo y Robustez — BreakoutNY Portfolio

[[Strategy - BreakoutNY]]

**Última actualización:** 2026-04-29
**Estrategia:** BreakoutNY (Breakout sesión New York)
**Activos analizados:** NAS100 + DJI30 + XAUUSD Set E (SP500 descartado)
**Broker/Cuenta:** FundingPips Corp — cuenta $5K operativa (balance: $4.879)
**Período OOS analizado:** 2025-01-01 → 2026-04-28 (16 meses, datos reales)
**Script:** `scripts/portfolio_montecarlo.py`

---

## 1. Metodología

### 1.1 Walk-Forward Framework

| Período | Rango | Propósito |
|---------|-------|-----------|
| **In-Sample (IS)** | 2021–2024 | Optimización y selección de parámetros |
| **Out-of-Sample (OOS)** | 2025–2026 | Validación de generalización |
| **Walk-Forward (WF)** | En curso | Observación en cuenta real |

### 1.2 Criterios de selección de sets

| Métrica | IS mínimo | OOS mínimo |
|---------|-----------|------------|
| Profit Factor | ≥ 1.40 | ≥ 1.40 |
| Equity DD% | ≤ 8% | ≤ 8% |
| Trades | ≥ 30 | ≥ 10 |
| Retención OOS | — | ≥ 75% |

### 1.3 Monte Carlo — Bootstrap Resampling

- **Método:** Bootstrap con reemplazo sobre trades reales OOS
- **Simulaciones:** 10.000 por escenario
- **Semilla fija:** `random.seed(42)`
- **Límite de ruin:** MLL 10% estático (FundingPips) o DLL 5%
- **Escenarios de degradación:** Base (0%), Conservador (-20% expectancy), Pesimista (-40%)
- **Horizonte:** 24 meses máximo por simulación

### 1.4 Análisis de Robustez

1. **Edge Decay (H1 vs H2 OOS):** Compara PF primera mitad vs segunda mitad del período OOS. Detecta si el edge se está normalizando o acelerando.
2. **Rachas perdedoras máximas:** Peor secuencia real de pérdidas consecutivas. Referencia para calibrar aguante psicológico y risk manager.
3. **Contribución por activo:** % de trades y % de profit por activo. Identifica dependencias de concentración.

---

## 2. Datos del Portfolio OOS (base del análisis)

### Trades individuales extraídos de xlsx MT5

| Activo | Trades | Net $ | WR | Avg Win | Avg Loss | Expectancy |
|--------|--------|-------|----|---------|----------|------------|
| NAS100 | 86 | $465.40 | 48.8% | ~$25 | ~$-13 | $5.41 |
| DJI30 | 35 | $93.02 | 28.6% | ~$30 | ~$-13 | $2.66 |
| XAUUSD | 27 | $255.47 | 63.0% | ~$18 | ~$-10 | $9.46 |
| **Portfolio** | **148** | **$813.89** | **46.6%** | **$24.46** | **$-13.24** | **$4.34** |

**Profit Factor combinado:** 1.931 | **Trades/mes:** 9.2

---

## 3. Resultados Monte Carlo

### 3.1 Cuenta operativa $5K (balance $4.879)

| Métrica | Valor |
|---------|-------|
| Probabilidad bust (MLL 10% / DLL 5%) | **0.0%** |
| Max DD p95 | 4.24% |
| Max DD p99 | 5.42% |
| Balance esperado en 24 meses (p10) | $5.682 |
| Balance esperado en 24 meses (p50) | $6.099 |
| Balance esperado en 24 meses (p90) | $6.514 |

La cuenta operativa está correctamente dimensionada. El risk manager ($13–$16/trade) mantiene el DD esperado lejos del DLL del 5%.

### 3.2 Challenge FundingPips $25K (escala x5)

| Escenario | P(Fase 1) | P(F1+F2 = Master) | Tiempo F1 | Tiempo hasta Master | Bust |
|-----------|-----------|-------------------|-----------|---------------------|------|
| **Base** (OOS histórico) | 99.8% | 97.3% | 8.1 meses | **12.7 meses** | 0.0% |
| **Conservador** (-20% expectancy) | 99.2% | 92.0% | 10.0 meses | **15.3 meses** | 0.0% |
| **Pesimista** (-40% expectancy) | 96.9% | 68.4% | 13.0 meses | **18.4 meses** | 0.0% |

**Escenario más realista:** Conservador — dado el Edge Decay observado (NAS100 -52%, XAUUSD -61% en H2 OOS), el PF efectivo en los próximos meses estará más cerca de 1.3–1.5 que de 1.93. **Estimación honesta: ~92% de probabilidad, ~15 meses.**

**Max DD esperado en challenge:**
- p95: 3.12–3.77% (bien dentro del DLL 5%)
- p99: 3.93–4.92%

---

## 4. Análisis de Robustez

### 4.1 Edge Decay — H1 vs H2 OOS

| Activo | PF H1 OOS | PF H2 OOS | Decay | Interpretación |
|--------|-----------|-----------|-------|----------------|
| NAS100 | 2.581 | 1.228 | **-52.4%** | ⚠️ Normalización pronunciada en H2 (sep 2025 – abr 2026) |
| XAUUSD | 6.047 | 2.338 | **-61.3%** | ⚠️ PF extremo en H1, normalización esperada pero acelerada |
| DJI30 | 1.336 | 1.738 | **+30.1%** | ✅ Edge mejorando en período más reciente |

**Implicación:** El H2 del OOS (período más reciente) es el más relevante para el challenge. Los escenarios conservador y pesimista del Monte Carlo capturan mejor la realidad actual que el escenario base.

### 4.2 Rachas perdedoras máximas (OOS)

| Activo | Racha máx. | Pérdida total | Impacto en $5K |
|--------|-----------|---------------|----------------|
| NAS100 | 6 consecutivos | -$78.68 | -1.61% |
| DJI30 | 3 consecutivos | -$51.98 | -1.07% |
| XAUUSD | 2 consecutivos | -$22.27 | -0.46% |

El risk manager activa half-size tras 4 losers consecutivos (NAS100 podría dispararlo). El halt diario al 3% cubre el peor día posible.

### 4.3 Concentración del portfolio

| Activo | % Trades | % Profit | Rol |
|--------|----------|----------|-----|
| NAS100 | 58% | 57% | Motor principal |
| XAUUSD | 18% | 31% | Calidad (alta expectancy/trade) |
| DJI30 | 24% | 11% | Diversificación |

**Riesgo de concentración:** El portfolio depende significativamente de NAS100. Si ese activo entra en drawdown prolongado, el portfolio lo resiente directamente.

---

## 5. Impacto de activos adicionales en el challenge

Simulación (escenario conservador -20%) del efecto de agregar GER40 u otro activo con edge similar a NAS100:

| Portfolio | Trades/mes | P(Master) | Tiempo hasta Master |
|-----------|-----------|-----------|---------------------|
| Base (NAS+DJI+XAU) | 9.2/mes | 91.5% | 15.2 meses |
| + 1 activo (4/mes) | 13.2/mes | 99.4% | **11.2 meses** |
| + 1 activo (7/mes) | 16.2/mes | ~100% | **9.3 meses** |
| + 2 activos (7/mes c/u) | 23.2/mes | ~100% | **~7 meses** |

**Conclusión:** Agregar 2 activos con 4–7 trades/mes cada uno recorta el tiempo del challenge de 15 a ~7–9 meses. El objetivo declarado: ≥ 2 activos adicionales con PF IS ≥ 1.5.

---

## 6. Advertencias críticas

1. **Muestra estadística limitada:** DJI30 (35 trades) y XAUUSD (27 trades) son insuficientes para intervalos de confianza robustos. El Monte Carlo los trata como distribuciones estables cuando no lo son.

2. **Escalado 5x no es lineal:** De $13–$16/trade a $65–$80/trade en el challenge. El slippage en NAS100 tiende a aumentar con el tamaño de posición.

3. **Bootstrap sobre distribución estática:** El Monte Carlo asume que la distribución histórica de trades se mantiene. Si el edge se degrada más allá del -40% (escenario pesimista), las probabilidades son menores a las reportadas.

4. **DLL FundingPips es estático (5% del balance inicial $25K = $1.250).** El DD diario real en trades escalados puede alcanzar ese límite con menos trades de lo esperado.

5. **Tiempo mínimo de operación:** FundingPips puede requerir un número mínimo de días de trading. El tiempo estimado asume operación continua al ritmo histórico.

---

## 7. Scripts

| Script | Descripción |
|--------|-------------|
| `scripts/portfolio_montecarlo.py` | Monte Carlo portfolio completo — 10.000 sim, 3 escenarios, robustez |
| `scripts/sp500_analysis.py` | Comparativa IS/OOS SP500 (todas las versiones) |
| `scripts/compare_is_oos.py` | IS vs OOS XAUUSD sets |
| `scripts/analyze_backtest.py` | Métricas individuales desde CSV MT5 |

```bash
# Regenerar análisis completo
py scripts/portfolio_montecarlo.py
```

---

## 8. Conclusiones

El portfolio NAS100 + DJI30 + XAUUSD Set E tiene **edge real y riesgo de bust prácticamente nulo** en el challenge $25K. La estimación honesta para pasar ambas fases es:

- **Probabilidad: ~92%** (escenario conservador)
- **Tiempo: ~15 meses** (escenario conservador)
- **Reducción con 2 activos adicionales: ~7–9 meses**

La prioridad inmediata es validar GER40 y un segundo candidato TBD para recortar ese tiempo sin sacrificar la robustez del portfolio.

---

## 9. Pendientes

- [ ] GER40: backtesting IS/OOS (2026-04-30) → actualizar simulación con datos reales
- [ ] Segundo activo candidato: identificar y backtest tras GER40
- [ ] WF en curso: cuando se acumulen 30+ trades reales por activo en el challenge, actualizar Monte Carlo
- [ ] Correlación inter-activos: construir matriz cuando haya datos WF suficientes
- [ ] Set G XAUUSD: forward demo paralelo 3 meses para evaluar MaxSL=16.5
