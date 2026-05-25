# -*- coding: utf-8 -*-
"""
Robustez + Monte Carlo + Visualizaciones — P58421 LONG NAS100
SessionEnd=19h, SessionStart=14:10 => MAX_HOLD=290 min
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from pathlib import Path

BASE        = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion")
OUT_IMG     = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Analisis-MonteCarlo")
EQUITY_INIT = 5000
N_ITER      = 5000
NP_SEED     = 42
MAX_HOLD    = 290  # min: SessionStart 14:10 -> SessionEnd 19:00

def parse_deals(path):
    df       = pd.read_excel(path, header=None)
    mask_in  = df[4].astype(str).str.strip().str.lower() == 'in'
    mask_out = df[4].astype(str).str.strip().str.lower() == 'out'
    entries  = df[mask_in].copy().reset_index(drop=True)
    exits    = df[mask_out].copy().reset_index(drop=True)
    n        = min(len(entries), len(exits))
    entries  = entries.iloc[:n]
    exits    = exits.iloc[:n]
    dt_in    = pd.to_datetime(entries[0].values, errors='coerce')
    dt_out   = pd.to_datetime(exits[0].values,   errors='coerce')
    pnls     = pd.to_numeric(exits[10], errors='coerce').values
    trades   = pd.DataFrame({
        'dt_in':    dt_in,
        'dt_out':   dt_out,
        'pnl':      pnls,
        'dow':      pd.DatetimeIndex(dt_in).day_name(),
        'year':     pd.DatetimeIndex(dt_in).year,
        'hold_min': (pd.DatetimeIndex(dt_out) - pd.DatetimeIndex(dt_in)).total_seconds() / 60,
    })
    trades = trades.dropna(subset=['pnl'])
    trades = trades[trades['hold_min'] <= 1440]
    return trades

def metrics(t):
    if t.empty: return {}
    w   = t[t['pnl'] > 0]
    l   = t[t['pnl'] < 0]
    pf  = w['pnl'].sum() / abs(l['pnl'].sum()) if len(l) > 0 else np.inf
    cum = t['pnl'].cumsum()
    dd  = abs((cum - cum.cummax()).min())
    return {
        'n':   len(t),
        'PF':  round(pf, 3),
        'WR':  round(len(w)/len(t)*100, 1),
        'Net': round(t['pnl'].sum(), 2),
        'DD%': round(dd/EQUITY_INIT*100, 2),
    }

# ---------------------------------------------------------------------------
print("Cargando datos P58421 LONG NAS100...")
FILES = {
    'IS':  'is_nas_58421.xlsx_.xlsx',
    'OOS': 'oos_nas_58421.xlsx_.xlsx',
    'WFA': 'WFA_NAS_58421.xlsx',
}
data = {}
for period, fname in FILES.items():
    try:
        t = parse_deals(BASE / fname)
        data[period] = t
        print(f"  [OK] {period}: {len(t)} trades")
    except Exception as e:
        print(f"  [X] {period}: {e}")
        data[period] = pd.DataFrame()

THRESHOLDS = [(0, 60, '<1h'), (60, 150, '1-2.5h'), (150, 9999, '>2.5h')]

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  ESTUDIO 1 -- HOLD TIME DISTRIBUTION")
print("="*65)
for period in ['IS', 'OOS', 'WFA']:
    t = data.get(period, pd.DataFrame())
    if t.empty: continue
    total_net = t['pnl'].sum()
    print(f"\n  {period} | n={len(t)} | Net=${total_net:+.0f}")
    print(f"  {'Bucket':<12} {'n':>4} {'PF':>7} {'Net':>9} {'%Net':>7}")
    print(f"  {'-'*44}")
    for lo, hi, lbl in THRESHOLDS:
        sub  = t[(t['hold_min'] >= lo) & (t['hold_min'] < hi)]
        m    = metrics(sub)
        if not m: continue
        pct  = sub['pnl'].sum()/total_net*100 if total_net else 0
        pf_s = f"{m['PF']:.3f}" if m['PF'] != np.inf else "  inf"
        pf_f = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        n_flag = " [!n<30]" if len(sub) < 30 else ""
        print(f"  {lbl:<12} {m['n']:>4} {pf_s:>5}{pf_f} ${m['Net']:>+8.0f} {pct:>+6.0f}%{n_flag}")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  ESTUDIO 2 -- SENSIBILIDAD SessionEnd")
print(f"  Baseline: MAX_HOLD={MAX_HOLD} min (14:10->19:00)")
print("="*65)
deltas = [-30, -15, 0, +15, +30]
for period in ['IS', 'OOS', 'WFA']:
    t = data.get(period, pd.DataFrame())
    if t.empty: continue
    print(f"\n  {period}:")
    print(f"  {'SE delta':<12} {'n':>4} {'PF':>7} {'WR%':>6} {'Net':>9} {'DD%':>6}")
    print(f"  {'-'*50}")
    for delta in deltas:
        max_h = MAX_HOLD + delta
        sub   = t[t['hold_min'] <= max_h]
        m     = metrics(sub)
        if not m: continue
        pf_f  = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        mark  = " <-- baseline" if delta == 0 else ""
        print(f"  SE{delta:+d}min{'':<5} {m['n']:>4} {m['PF']:>5.3f}{pf_f} "
              f"{m['WR']:>5.1f}% ${m['Net']:>+8.0f} {m['DD%']:>5.1f}%{mark}")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  ESTUDIO 3 -- CONCENTRACION BUCKET DOMINANTE (>2.5h)")
print("="*65)
for period in ['IS', 'OOS', 'WFA']:
    t = data.get(period, pd.DataFrame())
    if t.empty: continue
    sub = t[t['hold_min'] >= 150]
    if sub.empty:
        print(f"  {period}: sin trades >2.5h")
        continue
    total_net_bucket = sub['pnl'].sum()
    top3_net = sub.nlargest(3, 'pnl')['pnl'].sum()
    pct_top3 = top3_net/total_net_bucket*100 if total_net_bucket else 0
    flag   = "[OK]" if pct_top3 < 30 else ("[~]" if pct_top3 < 50 else "[X]")
    n_flag = "  [!] ALERTA: n<30" if len(sub) < 30 else ""
    print(f"  {period}: n={len(sub):>3} | Net=${total_net_bucket:+.0f} | "
          f"Top3=${top3_net:+.0f} ({pct_top3:.0f}%){flag}{n_flag}")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  ESTUDIO 4 -- CONSISTENCIA ANO A ANO")
print("="*65)
all_list = []
for period, t in data.items():
    if not t.empty:
        tc = t.copy()
        tc['period'] = period
        all_list.append(tc)
if all_list:
    combined = pd.concat(all_list)
    print(f"\n  {'Ano':<6} {'Per':<4} {'n':>4} {'PF':>7} {'WR%':>6} {'Net':>9} {'DD%':>6}")
    print(f"  {'-'*50}")
    for year in sorted(combined['year'].dropna().unique()):
        sub  = combined[combined['year'] == year]
        m    = metrics(sub)
        per  = sub['period'].iloc[0][:3]
        pf_f = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        print(f"  {int(year):<6} {per:<4} {m['n']:>4} {m['PF']:>5.3f}{pf_f} "
              f"{m['WR']:>5.1f}% ${m['Net']:>+8.0f} {m['DD%']:>5.1f}%")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  MONTE CARLO -- OOS + WFA combinados")
print(f"  {N_ITER} iteraciones | Equity inicial=${EQUITY_INIT}")
print("="*65)

oos_t = data.get('OOS', pd.DataFrame())
wfa_t = data.get('WFA', pd.DataFrame())
mc_df = pd.concat([t for t in [oos_t, wfa_t] if not t.empty])

viable_mc = None
max_dds = final_eqs = dd_pct = eq_pct = pnl_arr = None

if not mc_df.empty:
    pnl_arr  = mc_df['pnl'].values
    n_trades = len(pnl_arr)
    print(f"\n  Base: n={n_trades} | Net=${pnl_arr.sum():+.0f} | "
          f"Mean=${pnl_arr.mean():+.2f} | Std=${pnl_arr.std():.2f}")

    rng       = np.random.default_rng(NP_SEED)
    max_dds   = []
    final_eqs = []

    for _ in range(N_ITER):
        sample  = rng.choice(pnl_arr, size=n_trades, replace=True)
        cum     = np.cumsum(sample)
        run_max = np.maximum.accumulate(cum)
        max_dds.append((run_max - cum).max())
        final_eqs.append(cum[-1])

    max_dds   = np.array(max_dds)
    final_eqs = np.array(final_eqs)
    dd_pct    = max_dds / EQUITY_INIT * 100
    eq_pct    = final_eqs / EQUITY_INIT * 100

    print(f"\n  -- Drawdown --")
    for p in [5, 25, 50, 75, 90, 95, 99]:
        v    = np.percentile(dd_pct, p)
        flag = "[OK]" if v <= 10 else "[X]"
        print(f"  DD p{p:>2}: {v:>6.2f}% {flag}")

    print(f"\n  P(DD >  5%): {(dd_pct >  5).mean():.1%}")
    print(f"  P(DD > 10%): {(dd_pct > 10).mean():.1%}")
    print(f"  P(DD > 15%): {(dd_pct > 15).mean():.1%}")

    print(f"\n  -- Equity final --")
    for p in [5, 25, 50, 75, 95]:
        v = np.percentile(eq_pct, p)
        print(f"  Eq p{p:>2}: {v:>+7.2f}%")
    print(f"\n  P(equity negativa): {(final_eqs < 0).mean():.1%}")

    viable_mc = (np.percentile(dd_pct, 95) <= 15) and ((dd_pct > 10).mean() <= 0.20)
    print(f"\n  VEREDICTO MC: {'[MC OK]' if viable_mc else '[MC FAIL]'}")

    # -----------------------------------------------------------------------
    print("\n  Generando imagenes...")
    OUT_IMG.mkdir(parents=True, exist_ok=True)

    fig = plt.figure(figsize=(18, 11))
    fig.suptitle('P58421 LONG NAS100 -- Robustez + Monte Carlo (OOS+WFA)',
                 fontsize=13, fontweight='bold')
    gs = gridspec.GridSpec(2, 3, figure=fig, hspace=0.45, wspace=0.35)

    # Equity curves
    ax1 = fig.add_subplot(gs[0, :2])
    colors_map = {'IS': '#2196F3', 'OOS': '#4CAF50', 'WFA': '#FF9800'}
    for period, t in data.items():
        if t.empty: continue
        t_s = t.sort_values('dt_in')
        cum = t_s['pnl'].cumsum()
        pf_v = metrics(t)['PF']
        ax1.plot(range(len(cum)), cum.values,
                 label=f'{period} (n={len(t)}, PF={pf_v:.3f})',
                 color=colors_map[period], linewidth=1.8)
    ax1.axhline(0, color='black', linewidth=0.8, linestyle='--', alpha=0.5)
    ax1.set_title('Equity Curves acumuladas IS / OOS / WFA')
    ax1.set_xlabel('Trade #')
    ax1.set_ylabel('P&L acumulado ($)')
    ax1.legend(fontsize=9)
    ax1.grid(alpha=0.3)

    # Hold time OOS
    ax2 = fig.add_subplot(gs[0, 2])
    t_oos = data.get('OOS', pd.DataFrame())
    if not t_oos.empty:
        lbls, nets, ns = [], [], []
        for lo, hi, lbl in THRESHOLDS:
            sub = t_oos[(t_oos['hold_min'] >= lo) & (t_oos['hold_min'] < hi)]
            lbls.append(lbl)
            nets.append(sub['pnl'].sum() if not sub.empty else 0)
            ns.append(len(sub))
        bar_col = ['#EF5350' if v < 0 else '#66BB6A' for v in nets]
        bars = ax2.bar(lbls, nets, color=bar_col, alpha=0.85, edgecolor='white', linewidth=0.8)
        for bar, n_b in zip(bars, ns):
            h = bar.get_height()
            ax2.text(bar.get_x() + bar.get_width()/2,
                     h + (25 if h >= 0 else -55),
                     f'n={n_b}', ha='center', va='bottom', fontsize=9)
        ax2.axhline(0, color='black', linewidth=0.8)
        ax2.set_title('OOS: P&L neto por hold time')
        ax2.set_ylabel('P&L ($)')
        ax2.grid(axis='y', alpha=0.3)

    # MC DD histogram
    ax3 = fig.add_subplot(gs[1, 0])
    ax3.hist(dd_pct, bins=60, color='#EF5350', alpha=0.8, edgecolor='white', linewidth=0.4)
    ax3.axvline(10, color='darkred', linestyle='--', linewidth=1.8, label='Limite 10%')
    p95_dd = np.percentile(dd_pct, 95)
    ax3.axvline(p95_dd, color='orange', linestyle='--', linewidth=1.8, label=f'p95={p95_dd:.1f}%')
    ax3.set_title(f'MC: Max Drawdown Distribution\np95={p95_dd:.1f}% | P(>10%)={(dd_pct>10).mean():.1%}')
    ax3.set_xlabel('Max DD (%)')
    ax3.set_ylabel('Frecuencia')
    ax3.legend(fontsize=8)
    ax3.grid(alpha=0.3)

    # MC equity histogram
    ax4 = fig.add_subplot(gs[1, 1])
    ax4.hist(eq_pct, bins=60, color='#42A5F5', alpha=0.8, edgecolor='white', linewidth=0.4)
    ax4.axvline(0, color='red', linestyle='--', linewidth=1.8, label='Breakeven')
    p5_eq = np.percentile(eq_pct, 5)
    ax4.axvline(p5_eq, color='orange', linestyle='--', linewidth=1.8, label=f'p5={p5_eq:+.1f}%')
    ax4.set_title(f'MC: Equity Final Distribution\np5={p5_eq:+.1f}% | P(negativa)={(final_eqs<0).mean():.1%}')
    ax4.set_xlabel('Retorno (%)')
    ax4.set_ylabel('Frecuencia')
    ax4.legend(fontsize=8)
    ax4.grid(alpha=0.3)

    # MC equity paths
    ax5 = fig.add_subplot(gs[1, 2])
    rng2 = np.random.default_rng(NP_SEED + 1)
    for _ in range(150):
        sample = rng2.choice(pnl_arr, size=n_trades, replace=True)
        cum    = np.cumsum(sample)
        ax5.plot(range(len(cum)+1), np.concatenate([[0], cum]),
                 color='#1565C0', alpha=0.07, linewidth=0.6)
    ax5.axhline(0, color='red', linewidth=1.2, linestyle='--', label='Breakeven')
    ax5.set_title('MC: 150 trayectorias de equity')
    ax5.set_xlabel('Trade #')
    ax5.set_ylabel('P&L ($)')
    ax5.legend(fontsize=8)
    ax5.grid(alpha=0.3)

    img_path = OUT_IMG / 'NAS100_P58421_LONG_robustez_mc.png'
    fig.savefig(img_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"  [OK] Imagen: {img_path}")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  RESUMEN -- VEREDICTO FINAL P58421 LONG NAS100")
print("="*65)
is_m  = metrics(data.get('IS',  pd.DataFrame()))
oos_m = metrics(data.get('OOS', pd.DataFrame()))
wfa_m = metrics(data.get('WFA', pd.DataFrame()))

print(f"\n  IS:  PF={is_m.get('PF','--')} | DD={is_m.get('DD%','--')}% | n={is_m.get('n','--')}")
print(f"  OOS: PF={oos_m.get('PF','--')} | DD={oos_m.get('DD%','--')}% | n={oos_m.get('n','--')}")
print(f"  WFA: PF={wfa_m.get('PF','--')} | DD={wfa_m.get('DD%','--')}% | n={wfa_m.get('n','--')}")
if viable_mc is not None:
    print(f"  MC:  {'[MC OK]' if viable_mc else '[MC FAIL]'}")
print()
