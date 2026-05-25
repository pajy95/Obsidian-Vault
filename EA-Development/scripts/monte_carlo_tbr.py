"""
Monte Carlo — TBR v1.1  (Paso 9 pipeline)
Metodologia:
  - Shuffle (permutacion): mismos trades OOS, orden aleatorio  -> riesgo de secuencia
  - Bootstrap (resample):  muestreo con reemplazo             -> riesgo de distribucion
  N = 10,000 iteraciones cada uno

P&L con comision incluida (profit_out + commission_in).
Criterios prop firm FundingPips: Balance inicial $5,000 | Max DD 10% | Daily DD 5%.
"""
import sys, io, pandas as pd, numpy as np, warnings
from datetime import datetime
warnings.filterwarnings('ignore')
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

np.random.seed(42)

OOS_PATH     = r"C:\Users\JOSE YANEZ\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\GBPJPY\OOS_TBR_GBPJPY_M5_P121378.xlsx"
BALANCE_INIT = 5_000.0
MAX_DD_PCT   = 0.10        # 10% -> $500
DAILY_DD_PCT = 0.05        # 5%  -> $250
N_SIM        = 10_000
SEED         = 42

# ─────────────────────────────────────────────────────────────
def load_pnl(path):
    raw = pd.read_excel(path, sheet_name='Sheet1', header=None, dtype=str)
    header_row = None
    for i, row in raw.iterrows():
        s = ' '.join(str(v).lower() for v in row.values if str(v) not in ('nan',''))
        if 'profit' in s and 'direction' in s and 'symbol' in s:
            header_row = i
            break
    cols   = [str(v).strip().lower() for v in raw.iloc[header_row].values]
    df     = raw.iloc[header_row + 1:].copy()
    df.columns = cols
    df     = df.reset_index(drop=True)
    dir_s  = df['direction'].astype(str).str.strip().str.lower()
    in_df  = df[dir_s == 'in'].reset_index(drop=True)
    out_df = df[dir_s == 'out'].reset_index(drop=True)
    n      = min(len(in_df), len(out_df))
    comm   = pd.to_numeric(in_df['commission'].iloc[:n], errors='coerce').fillna(0).values
    prof   = pd.to_numeric(out_df['profit'].iloc[:n],    errors='coerce').values
    pnl    = prof + comm
    return pnl[~np.isnan(pnl)]

# ─────────────────────────────────────────────────────────────
def run_equity_curve(trades, balance_init):
    """Calcula equity curve y estadisticas de un orden de trades."""
    equity  = balance_init
    peak    = balance_init
    max_dd  = 0.0
    ruin    = False
    curve   = [equity]
    for t in trades:
        equity += t
        curve.append(equity)
        if equity > peak:
            peak = equity
        dd = (peak - equity) / peak
        if dd > max_dd:
            max_dd = dd
        if dd >= MAX_DD_PCT:
            ruin = True
            break
    return np.array(curve), max_dd, ruin, equity

# ─────────────────────────────────────────────────────────────
def monte_carlo(trades, mode='shuffle'):
    """
    mode: 'shuffle'    -> permuta el orden (riesgo de secuencia)
          'bootstrap'  -> resample con reemplazo (riesgo de distribucion)
    """
    n           = len(trades)
    final_eq    = np.zeros(N_SIM)
    max_dds     = np.zeros(N_SIM)
    ruins       = np.zeros(N_SIM, dtype=bool)
    rng         = np.random.default_rng(SEED)

    for i in range(N_SIM):
        if mode == 'shuffle':
            seq = rng.permutation(trades)
        else:
            seq = rng.choice(trades, size=n, replace=True)
        _, dd, ruin, feq = run_equity_curve(seq, BALANCE_INIT)
        final_eq[i] = feq
        max_dds[i]  = dd
        ruins[i]    = ruin

    return final_eq, max_dds, ruins

# ─────────────────────────────────────────────────────────────
def report(label, final_eq, max_dds, ruins, n_trades):
    ruin_pct   = ruins.mean() * 100
    p5_eq      = np.percentile(final_eq[~ruins], 5)  if (~ruins).any() else 0
    p50_eq     = np.percentile(final_eq[~ruins], 50) if (~ruins).any() else 0
    p95_eq     = np.percentile(final_eq[~ruins], 95) if (~ruins).any() else 0
    p5_dd      = np.percentile(max_dds, 95)   # percentil 95 de DD = escenario pesimista
    p50_dd     = np.percentile(max_dds, 50)
    p99_dd     = np.percentile(max_dds, 99)
    net_p5     = p5_eq  - BALANCE_INIT
    net_p50    = p50_eq - BALANCE_INIT

    ok_ruin = ruin_pct < 5.0
    ok_dd   = p5_dd    < MAX_DD_PCT * 0.80    # Pct95 DD < 8%
    ok_net  = net_p5   > 0                    # P5 final equity > inicio

    print(f"\n  [{label}]  n={n_trades} trades  N={N_SIM:,} simulaciones")
    print(f"  {'─'*50}")
    print(f"  Ruin (DD>=10%):   {ruin_pct:.1f}%   {'OK' if ok_ruin else 'ALERTA'} (criterio < 5%)")
    print(f"  Max DD P50:       {p50_dd*100:.1f}%")
    print(f"  Max DD P95:       {p5_dd*100:.1f}%   {'OK' if ok_dd else 'ALERTA'} (criterio < 8%)")
    print(f"  Max DD P99:       {p99_dd*100:.1f}%")
    print(f"  Equity final P5:  ${p5_eq:,.0f}  (net ${net_p5:+,.0f})  {'OK' if ok_net else 'ALERTA'}")
    print(f"  Equity final P50: ${p50_eq:,.0f}  (net ${net_p50:+,.0f})")
    print(f"  Equity final P95: ${p95_eq:,.0f}  (net ${p95_eq-BALANCE_INIT:+,.0f})")

    all_ok = ok_ruin and ok_dd and ok_net
    print(f"\n  Veredicto {label}: {'PASS' if all_ok else 'MARGINAL/FAIL'}")
    return all_ok, ruin_pct, p5_dd, net_p5, net_p50

# ─────────────────────────────────────────────────────────────
print("=" * 60)
print("  MONTE CARLO — GBPJPY P121378 — TBR v1.1")
print("=" * 60)
print(f"  Balance inicial:  ${BALANCE_INIT:,.0f}")
print(f"  Max DD regla:     {MAX_DD_PCT*100:.0f}%  (${BALANCE_INIT*MAX_DD_PCT:,.0f})")
print(f"  N simulaciones:   {N_SIM:,}")
print(f"  Seed:             {SEED}")

pnl = load_pnl(OOS_PATH)
n   = len(pnl)
wins   = pnl[pnl > 0]
losses = pnl[pnl < 0]
pf_real = wins.sum() / abs(losses.sum()) if len(losses) else 99
wr_real = len(wins) / n * 100

print(f"\n  OOS trade sample: n={n}  PF={pf_real:.3f}  WR={wr_real:.1f}%")
print(f"  Net real: ${pnl.sum():.2f}  |  Avg win: ${wins.mean():.2f}  Avg loss: ${losses.mean():.2f}")
print(f"  Ratio avg win/loss: {abs(wins.mean()/losses.mean()):.2f}")

# ─── SHUFFLE ───
print("\n" + "=" * 60)
print("  MODO 1 — SHUFFLE (riesgo de secuencia)")
print("=" * 60)
feq_sh, mdd_sh, ruins_sh = monte_carlo(pnl, mode='shuffle')
ok_sh, ruin_sh, p95dd_sh, net5_sh, net50_sh = report(
    "Shuffle", feq_sh, mdd_sh, ruins_sh, n)

# ─── BOOTSTRAP ───
print("\n" + "=" * 60)
print("  MODO 2 — BOOTSTRAP (riesgo de distribucion)")
print("=" * 60)
feq_bs, mdd_bs, ruins_bs = monte_carlo(pnl, mode='bootstrap')
ok_bs, ruin_bs, p95dd_bs, net5_bs, net50_bs = report(
    "Bootstrap", feq_bs, mdd_bs, ruins_bs, n)

# ─── RESUMEN ───
print("\n" + "=" * 60)
print("  RESUMEN FINAL")
print("=" * 60)
print(f"\n  Criterios FundingPips (balance $5,000):")
print(f"    Ruin < 5%         Shuffle={ruin_sh:.1f}%  Bootstrap={ruin_bs:.1f}%")
print(f"    DD P95 < 8%       Shuffle={p95dd_sh*100:.1f}%  Bootstrap={p95dd_bs*100:.1f}%")
print(f"    Net P5 > $0       Shuffle=${net5_sh:+,.0f}  Bootstrap=${net5_bs:+,.0f}")
veredicto = "PASS" if (ok_sh and ok_bs) else ("MARGINAL" if (ok_sh or ok_bs) else "FAIL")
print(f"\n  VEREDICTO MC: {veredicto}")
