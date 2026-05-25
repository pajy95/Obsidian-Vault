# -*- coding: utf-8 -*-
"""
Robustez + Monte Carlo + Visualizaciones — XAU P2 BE sin Lunes
TradeDirection=0 (BOTH) | SessionStart=14:45 | SessionEnd=17:00
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

BASE        = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD")
OUT_IMG     = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Analisis-MonteCarlo")
EQUITY_INIT = 5000
N_ITER      = 5000
NP_SEED     = 42
# SessionStart=14:45, SessionEnd=17:00 -> 135 min teorico
# Usamos max real de los datos como baseline
MAX_HOLD_TEORICO = 135

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
    dirs     = entries[3].astype(str).str.lower().str.strip().values
    pnls     = pd.to_numeric(exits[10], errors='coerce').values
    trades   = pd.DataFrame({
        'dt_in':    dt_in,
        'dt_out':   dt_out,
        'dir':      dirs,
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
print("Cargando datos XAU P2 BE sin Lunes...")
FILES = {
    'IS':  'is_tbr_xauusd_p2_2022-2024_be_noL.xlsx',
    'OOS': 'OOS_TBR_XAU_P2_2025_be_NOL.xlsx',
    'WFA': 'WFA_TBR_XAU_be_noL_2026.xlsx',
}
data = {}
for period, fname in FILES.items():
    try:
        t = parse_deals(BASE / fname)
        data[period] = t
        max_h = t['hold_min'].max() if not t.empty else 0
        print(f"  [OK] {period}: {len(t)} trades | max hold={max_h:.0f} min")
    except Exception as e:
        print(f"  [X] {period}: {e}")
        data[period] = pd.DataFrame()

# Baseline MAX_HOLD desde datos IS
t_is = data.get('IS', pd.DataFrame())
MAX_HOLD = int(t_is['hold_min'].max()) if not t_is.empty else MAX_HOLD_TEORICO
print(f"\n  MAX_HOLD real (IS): {MAX_HOLD} min | Teorico: {MAX_HOLD_TEORICO} min")

THRESHOLDS = [(0, 60, '<1h'), (60, 120, '1-2h'), (120, 9999, '>2h')]

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
print(f"  Baseline MAX_HOLD={MAX_HOLD} min (14:45->17:00 teorico=135)")
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
print("  ESTUDIO 3 -- LONG vs SHORT (BOTH strategy)")
print("="*65)
for period in ['IS', 'OOS', 'WFA']:
    t = data.get(period, pd.DataFrame())
    if t.empty: continue
    print(f"\n  {period} | n={len(t)}")
    for d in ['buy', 'sell']:
        sub = t[t['dir'] == d]
        m   = metrics(sub)
        if not m: continue
        lbl  = "LONG " if d == 'buy' else "SHORT"
        pf_f = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        print(f"    {lbl}: n={m['n']:>3} | PF={m['PF']:.3f}{pf_f} | "
              f"WR={m['WR']}% | Net=${m['Net']:+.0f}")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  ESTUDIO 4 -- CONCENTRACION BUCKET DOMINANTE (>2h sesion)")
print("="*65)
for period in ['IS', 'OOS', 'WFA']:
    t = data.get(period, pd.DataFrame())
    if t.empty: continue
    sub = t[t['hold_min'] >= 120]
    if sub.empty:
        print(f"  {period}: sin trades >2h")
        continue
    total_net_bucket = sub['pnl'].sum()
    top3_net = sub.nlargest(3, 'pnl')['pnl'].sum()
    pct_top3 = top3_net/total_net_bucket*100 if total_net_bucket else 0
    flag   = "[OK]" if pct_top3 < 30 else ("[~]" if pct_top3 < 50 else "[X]")
    n_flag = "  [!] n<30" if len(sub) < 30 else ""
    print(f"  {period}: n={len(sub):>3} | Net=${total_net_bucket:+.0f} | "
          f"Top3=${top3_net:+.0f} ({pct_top3:.0f}%){flag}{n_flag}")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  ESTUDIO 5 -- CONSISTENCIA ANO A ANO")
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

    fig = plt.figure(figsize=(18, 12))
    fig.suptitle('XAU P2 BE sin Lunes (BOTH) -- Robustez + Monte Carlo (OOS+WFA)',
                 fontsize=13, fontweight='bold')
    gs = gridspec.GridSpec(3, 3, figure=fig, hspace=0.50, wspace=0.35)

    colors_map = {'IS': '#2196F3', 'OOS': '#4CAF50', 'WFA': '#FF9800'}

    # Equity curves
    ax1 = fig.add_subplot(gs[0, :2])
    for period, t in data.items():
        if t.empty: continue
        t_s = t.sort_values('dt_in')
        cum = t_s['pnl'].cumsum()
        pf_v = metrics(t)['PF']
        ax1.plot(range(len(cum)), cum.values,
                 label=f'{period} (n={len(t)}, PF={pf_v:.3f})',
                 color=colors_map[period], linewidth=1.8)
    ax1.axhline(0, color='black', linewidth=0.8, linestyle='--', alpha=0.5)
    ax1.set_title('Equity Curves IS / OOS / WFA')
    ax1.set_xlabel('Trade #')
    ax1.set_ylabel('P&L acumulado ($)')
    ax1.legend(fontsize=9)
    ax1.grid(alpha=0.3)

    # Long vs Short OOS
    ax2 = fig.add_subplot(gs[0, 2])
    t_oos = data.get('OOS', pd.DataFrame())
    if not t_oos.empty:
        dirs_lbls, dirs_nets, dirs_ns = [], [], []
        for period_k, t_k in [('IS', data.get('IS', pd.DataFrame())),
                               ('OOS', t_oos),
                               ('WFA', data.get('WFA', pd.DataFrame()))]:
            for d, lbl in [('buy', 'LONG'), ('sell', 'SHORT')]:
                sub = t_k[t_k['dir'] == d]
                if sub.empty: continue
                m = metrics(sub)
                dirs_lbls.append(f'{period_k}\n{lbl}')
                dirs_nets.append(m['Net'])
                dirs_ns.append(m['n'])
        bar_col = ['#42A5F5' if 'LONG' in l else '#EF5350' for l in dirs_lbls]
        neg_col = ['#1565C0' if n >= 0 else '#B71C1C' for n in dirs_nets]
        final_col = [('#42A5F5' if 'LONG' in l else '#EF5350') if v >= 0
                     else ('#1565C0' if 'LONG' in l else '#B71C1C')
                     for l, v in zip(dirs_lbls, dirs_nets)]
        bars = ax2.bar(dirs_lbls, dirs_nets, color=final_col, alpha=0.85, edgecolor='white')
        for bar, n_b in zip(bars, dirs_ns):
            h = bar.get_height()
            ax2.text(bar.get_x() + bar.get_width()/2,
                     h + (8 if h >= 0 else -20),
                     f'n={n_b}', ha='center', va='bottom', fontsize=7)
        ax2.axhline(0, color='black', linewidth=0.8)
        ax2.set_title('Long vs Short por Periodo')
        ax2.set_ylabel('P&L neto ($)')
        ax2.tick_params(axis='x', labelsize=7)
        ax2.grid(axis='y', alpha=0.3)

    # Hold time OOS
    ax3 = fig.add_subplot(gs[1, 0])
    if not t_oos.empty:
        lbls, nets, ns = [], [], []
        for lo, hi, lbl in THRESHOLDS:
            sub = t_oos[(t_oos['hold_min'] >= lo) & (t_oos['hold_min'] < hi)]
            lbls.append(lbl)
            nets.append(sub['pnl'].sum() if not sub.empty else 0)
            ns.append(len(sub))
        bar_col2 = ['#EF5350' if v < 0 else '#66BB6A' for v in nets]
        bars2 = ax3.bar(lbls, nets, color=bar_col2, alpha=0.85, edgecolor='white')
        for bar, n_b in zip(bars2, ns):
            h = bar.get_height()
            ax3.text(bar.get_x() + bar.get_width()/2,
                     h + (5 if h >= 0 else -20),
                     f'n={n_b}', ha='center', va='bottom', fontsize=9)
        ax3.axhline(0, color='black', linewidth=0.8)
        ax3.set_title('OOS: P&L neto por hold time')
        ax3.set_ylabel('P&L ($)')
        ax3.grid(axis='y', alpha=0.3)

    # SessionEnd sensitivity OOS
    ax4 = fig.add_subplot(gs[1, 1])
    t_oos_se = data.get('OOS', pd.DataFrame())
    if not t_oos_se.empty:
        pf_vals, delta_lbls = [], []
        for delta in deltas:
            max_h = MAX_HOLD + delta
            sub   = t_oos_se[t_oos_se['hold_min'] <= max_h]
            m     = metrics(sub)
            pf_vals.append(m['PF'] if m else 0)
            delta_lbls.append(f'SE{delta:+d}')
        colors_se = ['#EF5350' if v < 1.0 else ('#FFA726' if v < 1.40 else '#66BB6A') for v in pf_vals]
        ax4.bar(delta_lbls, pf_vals, color=colors_se, alpha=0.85, edgecolor='white')
        ax4.axhline(1.40, color='green', linestyle='--', linewidth=1.5, label='PF=1.40')
        ax4.axhline(1.00, color='red',   linestyle='--', linewidth=1.5, label='PF=1.00')
        ax4.set_title('OOS: Sensibilidad SessionEnd')
        ax4.set_ylabel('Profit Factor')
        ax4.legend(fontsize=8)
        ax4.grid(axis='y', alpha=0.3)

    # MC DD histogram
    ax5 = fig.add_subplot(gs[1, 2])
    ax5.hist(dd_pct, bins=60, color='#EF5350', alpha=0.8, edgecolor='white', linewidth=0.4)
    ax5.axvline(10, color='darkred', linestyle='--', linewidth=1.8, label='Limite 10%')
    p95_dd = np.percentile(dd_pct, 95)
    ax5.axvline(p95_dd, color='orange', linestyle='--', linewidth=1.8, label=f'p95={p95_dd:.1f}%')
    ax5.set_title(f'MC: Max Drawdown\np95={p95_dd:.1f}% | P(>10%)={(dd_pct>10).mean():.1%}')
    ax5.set_xlabel('Max DD (%)')
    ax5.set_ylabel('Frecuencia')
    ax5.legend(fontsize=8)
    ax5.grid(alpha=0.3)

    # MC equity histogram
    ax6 = fig.add_subplot(gs[2, 0])
    ax6.hist(eq_pct, bins=60, color='#42A5F5', alpha=0.8, edgecolor='white', linewidth=0.4)
    ax6.axvline(0, color='red', linestyle='--', linewidth=1.8, label='Breakeven')
    p5_eq = np.percentile(eq_pct, 5)
    ax6.axvline(p5_eq, color='orange', linestyle='--', linewidth=1.8, label=f'p5={p5_eq:+.1f}%')
    ax6.set_title(f'MC: Equity Final\np5={p5_eq:+.1f}% | P(negativa)={(final_eqs<0).mean():.1%}')
    ax6.set_xlabel('Retorno (%)')
    ax6.set_ylabel('Frecuencia')
    ax6.legend(fontsize=8)
    ax6.grid(alpha=0.3)

    # MC equity paths
    ax7 = fig.add_subplot(gs[2, 1:])
    rng2 = np.random.default_rng(NP_SEED + 1)
    for _ in range(150):
        sample = rng2.choice(pnl_arr, size=n_trades, replace=True)
        cum    = np.cumsum(sample)
        ax7.plot(range(len(cum)+1), np.concatenate([[0], cum]),
                 color='#1565C0', alpha=0.07, linewidth=0.6)
    ax7.axhline(0, color='red', linewidth=1.2, linestyle='--', label='Breakeven')
    ax7.set_title('MC: 150 trayectorias de equity')
    ax7.set_xlabel('Trade #')
    ax7.set_ylabel('P&L ($)')
    ax7.legend(fontsize=8)
    ax7.grid(alpha=0.3)

    img_path = OUT_IMG / 'XAU_P2_BE_NoLunes_robustez_mc.png'
    fig.savefig(img_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"  [OK] Imagen: {img_path}")

# ---------------------------------------------------------------------------
print("\n" + "="*65)
print("  RESUMEN -- VEREDICTO FINAL XAU P2 BE sin Lunes")
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
