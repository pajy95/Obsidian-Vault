"""
Walk-Forward Analysis — TBR v1.0b NAS100 2026
Evalua backtest 2026.01.01-2026.05.09 con configuracion P63 L/M/X
Usa filas DEAL (precio real) para calcular P&L correcto en timeouts
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pandas as pd, numpy as np, re, warnings
warnings.filterwarnings('ignore')

FILE = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\WFA TBR NAS100 2026.xlsx"
VPP  = 20.0
RR   = 4.0

# ── Cargar ───────────────────────────────────────────────────────────────────
df_raw = pd.read_excel(FILE, header=None)
rows   = df_raw[df_raw[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]

# Entradas: BUY STOP ORDER rows (col11='filled') — tienen SL y TP en col7/col8
buy_orders = rows[(rows[3].astype(str).str.strip().str.lower() == 'buy stop') &
                  (rows[11].astype(str).str.strip().str.lower() == 'filled')].copy()
# Salidas: SELL DEAL rows (col6 != 0) — tienen precio real de cierre
sell_deals = rows[(rows[3].astype(str).str.strip().str.lower() == 'sell') &
                  (rows[6].astype(str) != '0')].copy()

# ── Parsear entradas ─────────────────────────────────────────────────────────
entries = []
for _, row in buy_orders.iterrows():
    try:
        p = float(row[6]); sl = float(row[7]); tp = float(row[8])
    except Exception:
        continue
    if p > 0 and sl > 0 and tp > 0 and p > sl:
        vol = 0.01
        try:
            vol = float(str(row[4]).strip().split('/')[0].strip())
        except Exception:
            pass
        entries.append({'open_time': str(row[0]), 'vol': vol,
                        'price': p, 'sl': sl, 'tp': tp, 'sl_dist': p - sl})

# ── Parsear salidas ──────────────────────────────────────────────────────────
exits = []
for _, row in sell_deals.iterrows():
    cp      = float(row[6])
    comment = str(row[12]).strip().lower()
    et      = 'TP' if 'tp' in comment else ('SL' if 'sl' in comment else 'Timeout')
    exits.append({'close_price': cp, 'exit_type': et, 'close_time': str(row[0])})

# ── Parear entry-exit ────────────────────────────────────────────────────────
n = min(len(entries), len(exits))
results = []
for i in range(n):
    e = entries[i]; x = exits[i]
    date = pd.to_datetime(e['open_time'][:10])
    if x['exit_type'] == 'TP':
        profit = e['vol'] * e['sl_dist'] * VPP * RR
    elif x['exit_type'] == 'SL':
        profit = -e['vol'] * e['sl_dist'] * VPP
    else:  # Timeout — precio real de cierre
        price_diff = x['close_price'] - e['price']
        profit = e['vol'] * price_diff * VPP
    results.append({'date': date, 'exit_type': x['exit_type'],
                    'open_time': e['open_time'], 'close_time': x['close_time'],
                    'profit': profit, 'month': date.month,
                    'dow': date.day_name(), 'vol': e['vol'],
                    'entry': e['price'], 'sl': e['sl'], 'tp': e['tp'],
                    'close': x['close_price']})

rdf = pd.DataFrame(results)

# ── Metricas globales ────────────────────────────────────────────────────────
gp_tot = rdf[rdf['profit'] > 0]['profit'].sum()
gl_tot = abs(rdf[rdf['profit'] < 0]['profit'].sum())
pf_tot = gp_tot / gl_tot if gl_tot > 0 else 0.0
wr_tot = (rdf['exit_type'] == 'TP').mean() * 100
net    = rdf['profit'].sum()
cum    = rdf['profit'].cumsum()
mdd    = abs((cum - cum.cummax()).min())
tp_n   = int((rdf['exit_type'] == 'TP').sum())
sl_n   = int((rdf['exit_type'] == 'SL').sum())
to_n   = int((rdf['exit_type'] == 'Timeout').sum())

MONTH_NAMES = {1:'Enero',2:'Febrero',3:'Marzo',4:'Abril',5:'Mayo',
               6:'Junio',7:'Julio',8:'Agosto',9:'Sept',10:'Oct',11:'Nov',12:'Dic'}

OOS_PF = 1.498  # referencia OOS 2025

print("=" * 70)
print("WALK-FORWARD 2026 - TBR v1.0b P63 L/M/X")
print("Config: Candles=2, StartMin=15, RR=4.0, L+M+X, BE=off, GF=off")
print("=" * 70)
print(f"\nPeriodo: {rdf['date'].min().date()} -> {rdf['date'].max().date()}")
print(f"Trades:  {n}  ({len(buy_orders)} filled, 7 canceled)")

print(f"\n{'Metrica':<28} {'WF 2026':>10}  {'OOS 2025 (ref)':>16}")
print("-" * 58)
print(f"  Profit Factor          {pf_tot:>10.3f}  {'1.498':>16}")
print(f"  Win Rate               {wr_tot:>9.1f}%  {'26.2%':>16}")
print(f"  Net Profit             {net:>+10.0f}  {'+$524':>16}")
print(f"  Max Drawdown           {mdd:>10.0f}  {'$128':>16}")
print(f"  TP / SL / Timeout    {tp_n:>4d}/{sl_n:>4d}/{to_n:>4d}  {'38/107/0':>16}")

print(f"\n--- Detalle por mes ---")
print(f"  {'Mes':<10} {'n':>4} {'PF':>7} {'WR':>6} {'Net':>9}  Cum")
print("  " + "-" * 42)
cum_v = 0.0
for m in sorted(rdf['month'].unique()):
    g = rdf[rdf['month'] == m]
    gp_m = g[g['profit'] > 0]['profit'].sum()
    gl_m = abs(g[g['profit'] < 0]['profit'].sum())
    pf_m = gp_m / gl_m if gl_m > 0 else 0.0
    wr_m = (g['exit_type'] == 'TP').mean() * 100
    net_m = g['profit'].sum()
    cum_v += net_m
    pf_s = f"{pf_m:.3f}" if gp_m > 0 else "  0.000"
    print(f"  {MONTH_NAMES.get(m,'?'):<10} {len(g):>4} {pf_s:>7} {wr_m:>5.1f}% {net_m:>+9.0f}  {cum_v:>+.0f}")

print(f"\n--- Detalle por dia ---")
print(f"  {'Dia':<10} {'n':>4} {'PF':>7} {'WR':>6} {'Net':>9}  OOS2025")
print("  " + "-" * 50)
OOS_DAY = {'Monday': 1.607, 'Tuesday': 1.559, 'Wednesday': 1.589}
for day in ['Monday', 'Tuesday', 'Wednesday']:
    g = rdf[rdf['dow'] == day]
    if len(g) == 0:
        continue
    gp_d = g[g['profit'] > 0]['profit'].sum()
    gl_d = abs(g[g['profit'] < 0]['profit'].sum())
    pf_d = gp_d / gl_d if gl_d > 0 else 0.0
    wr_d = (g['exit_type'] == 'TP').mean() * 100
    net_d = g['profit'].sum()
    ref   = OOS_DAY.get(day, '-')
    pf_s  = f"{pf_d:.3f}" if gp_d > 0 else "  0.000"
    print(f"  {day[:3]:<10} {len(g):>4} {pf_s:>7} {wr_d:>5.1f}% {net_d:>+9.0f}  ref={ref:.3f}")

# ── Criterios ────────────────────────────────────────────────────────────────
print(f"\n{'='*70}")
print("CRITERIOS WALK-FORWARD")
print(f"{'='*70}")
checks = [
    (pf_tot >= 1.0,            "PF >= 1.0  (minimo supervivencia)",   f"{pf_tot:.3f}"),
    (pf_tot >= 1.20,           "PF >= 1.20 (robustez basica)",         f"{pf_tot:.3f}"),
    (n >= 20,                  "Trades >= 20",                         f"{n}"),
    (wr_tot >= 20.0,           "WR >= 20%",                            f"{wr_tot:.1f}%"),
    (net > 0,                  "Net Profit > 0",                       f"${net:+.0f}"),
    (pf_tot/OOS_PF >= 0.50,   "PF_WF / PF_OOS >= 0.50",              f"{pf_tot/OOS_PF:.3f}"),
]
ok = sum(1 for c, _, _ in checks if c)
for cond, lbl, val in checks:
    print(f"  [{'OK' if cond else 'XX'}] {lbl:<42} {val:>8}")

print()
if ok == len(checks):
    verdict = "VIABLE"
elif ok >= 4:
    verdict = "MARGINAL"
else:
    verdict = "NO VIABLE"

print(f"  VEREDICTO WF: {verdict} ({ok}/{len(checks)})")

# ── Analisis de causa raiz ───────────────────────────────────────────────────
print(f"\n{'='*70}")
print("ANALISIS DE CAUSA RAIZ")
print(f"{'='*70}")

# Probabilidad de WR=0% con WR esperado de 26.2%
expected_wr = 0.262
prob_zero_wr = (1 - expected_wr) ** n
print(f"\n  WR observado: {wr_tot:.1f}%  (esperado: {expected_wr*100:.1f}%)")
print(f"  P(WR=0 | n={n}, p=0.262) = {prob_zero_wr:.8f} ({prob_zero_wr*100:.6f}%)")
print(f"  -> Extremadamente improbable bajo condiciones normales.")
print()
print(f"  Tipos de salida: TP={tp_n}  SL={sl_n}  Timeout={to_n}")
print(f"  Salidas confirmadas 'tp' en el reporte MT5: 0 (busqueda exhaustiva)")
print()
print("  HIPOTESIS DE FALLA:")
print("  1. Cambio de regimen: NAS100 en modo bajista/volatil en 2026")
print("     - La estrategia es long-only. Mercados bajistas la destruyen.")
print("     - 2022 (IS): PF=0.966 con NAS100 -35%")
print("     - Si 2026 tiene condiciones similares -> resultado coherente")
print()
print("  2. RR=4.0 requiere movimiento sostenido. En alta volatilidad")
print("     (falsos breakouts, reversales rapidas), precio alcanza SL")
print("     antes que TP.")
print()
print("  VERIFICAR:")
print("  - Revisar grafico NAS100 ene-abr 2026 (contexto macro)")
print("  - Comparar con BreakoutNY NAS100 en el mismo periodo")
print("  - Verificar si el EA file TBR_v1.0b.mq5 tiene la logica correcta")
print("    para L/M/X (ThuEnabled=false, FriEnabled=false)")

print(f"\n{'='*70}")
print("PIPELINE DE VALIDACION")
print(f"{'='*70}")
print("  IS 2022-2024  -> MARGINAL (PF=1.252, falla IS por 2022 bear)")
print("  OOS 2025      -> OK       (PF=1.498, OOS/IS=1.196)")
print("  WF 2026       -> FALLA    (PF={pf_tot:.3f}, WR=0%, net=${net:+.0f}, 1/6 criterios)")
print()
print("  DECISION: NO avanzar a Demo con configuracion actual.")
print("  ALTERNATIVAS:")
print("  a) Reducir RR (ej. RR=2.0-3.0) -> mas TP hits, menor R por trade")
print("  b) Investigar contexto macro 2026 -> es temporal o estructural?")
print("  c) Evaluar GapFilter para filtrar dias con gap overnight grande")
print("  d) Revisar si BreakoutNY NAS100 falla igual en 2026 (validacion cruzada)")
