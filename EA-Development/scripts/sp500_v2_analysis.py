import openpyxl, random, numpy as np, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from collections import defaultdict

base       = 'c:/Users/JOSSE/Documents/Obsidian Vault/EA-Development/01-Strategies/BreakoutNY/Optmizacion/'
output_dir = 'c:/Users/JOSSE/Documents/Obsidian Vault/EA-Development/01-Strategies/BreakoutNY/Analisis-MonteCarlo/'

def extract_trades(filename):
    wb = openpyxl.load_workbook(base + filename)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    deals_header_idx = None
    for i, row in enumerate(rows):
        if row[0] == 'Time' and row[1] == 'Deal' and row[2] == 'Symbol':
            deals_header_idx = i; break
    if deals_header_idx is None: return []
    deals = []
    for row in rows[deals_header_idx+1:]:
        if row[0] is None or row[1] is None: break
        if isinstance(row[1],(int,float)) and row[3] in ('buy','sell') and row[4] in ('in','out','in/out'):
            deals.append({'time':row[0],'type':row[3],'direction':row[4],
                          'commission':row[8],'swap':row[9],'profit':row[10],'comment':row[12]})
    trades = []; entry = None
    for d in deals:
        if d['direction']=='in': entry=d
        elif d['direction']=='out' and entry is not None:
            net=(d['profit'] or 0)+(entry['commission'] or 0)+(d['commission'] or 0)+(entry['swap'] or 0)+(d['swap'] or 0)
            trades.append({'time':entry['time'],'direction':entry['type'],'net':net,'comment':d['comment'] or ''})
            entry=None
    return trades

def stats(trades, deposit=5000):
    equity = deposit; peak = deposit; max_dd = 0
    wins   = [t for t in trades if t['net'] > 0]
    losses = [t for t in trades if t['net'] < 0]
    for t in trades:
        equity += t['net']
        if equity > peak: peak = equity
        dd = (peak - equity) / peak * 100
        if dd > max_dd: max_dd = dd
    pf  = sum(t['net'] for t in wins) / abs(sum(t['net'] for t in losses)) if losses else 999
    wr  = len(wins) / len(trades) * 100 if trades else 0
    avg_w = sum(t['net'] for t in wins)   / len(wins)   if wins   else 0
    avg_l = sum(t['net'] for t in losses) / len(losses) if losses else 0
    return {'profit': equity-deposit, 'pf': pf, 'dd': max_dd, 'trades': len(trades),
            'wr': wr, 'avg_w': avg_w, 'avg_l': avg_l, 'rr': abs(avg_w/avg_l) if avg_l else 0}

def pf_sub(tlist):
    w = sum(t['net'] for t in tlist if t['net'] > 0)
    l = abs(sum(t['net'] for t in tlist if t['net'] < 0))
    return w / l if l > 0 else 999

def monte_carlo_full(profits, n_sim=1000, deposit=5000):
    random.seed(42)
    all_curves = []; final_p = []; max_dds = []
    for _ in range(n_sim):
        sample = random.choices(profits, k=len(profits))
        equity = deposit; peak = deposit; max_dd = 0; curve = [deposit]
        for p in sample:
            equity += p
            if equity > peak: peak = equity
            dd = (peak - equity) / peak * 100
            if dd > max_dd: max_dd = dd
            curve.append(equity)
        all_curves.append(curve); final_p.append(equity-deposit); max_dds.append(max_dd)
    return all_curves, final_p, max_dds

def equity_curve_real(trades, deposit=5000):
    curve = [deposit]; equity = deposit
    for t in trades:
        equity += t['net']; curve.append(equity)
    return curve

is_trades  = extract_trades('bk ny sp500 v2.xlsx')
oos_trades = extract_trades('fr bk sp500 v2.xlsx')
s_is  = stats(is_trades)
s_oos = stats(oos_trades)

profits_is  = [t['net'] for t in is_trades]
profits_oos = [t['net'] for t in oos_trades]
deposit = 5000
COLOR = '#00d4ff'

# --- Stats detalladas ---
is_l  = [t for t in is_trades  if t['direction']=='buy']
is_s  = [t for t in is_trades  if t['direction']=='sell']
oos_l = [t for t in oos_trades if t['direction']=='buy']
oos_s = [t for t in oos_trades if t['direction']=='sell']

by_year = defaultdict(list)
for t in is_trades:
    yr = t['time'].year if hasattr(t['time'],'year') else int(str(t['time'])[:4])
    by_year[yr].append(t)

print('=== SP500 v2 — IS 2021-2024 ===')
print(f'  Profit Neto:   ${s_is["profit"]:.2f}')
print(f'  Profit Factor: {s_is["pf"]:.3f}')
print(f'  Max DD:        {s_is["dd"]:.2f}%')
print(f'  Trades:        {s_is["trades"]} | WR: {s_is["wr"]:.1f}%')
print(f'  Avg Win:       ${s_is["avg_w"]:.2f} | Avg Loss: ${s_is["avg_l"]:.2f} | RR: {s_is["rr"]:.2f}')
print(f'  Longs:         {len(is_l)} trades | PF={pf_sub(is_l):.3f}')
print(f'  Shorts:        {len(is_s)} trades | PF={pf_sub(is_s):.3f}')
print('  Por año:')
for yr in sorted(by_year):
    yt = by_year[yr]
    yl = [t for t in yt if t['direction']=='buy']
    ys = [t for t in yt if t['direction']=='sell']
    print(f'    {yr}: {len(yt):3d} trades | Profit=${sum(t["net"] for t in yt):7.2f} | L:{len(yl)} PF={pf_sub(yl):.2f} | S:{len(ys)} PF={pf_sub(ys):.2f}')

print()
print('=== SP500 v2 — OOS 2025 ===')
print(f'  Profit Neto:   ${s_oos["profit"]:.2f}')
print(f'  Profit Factor: {s_oos["pf"]:.3f}')
print(f'  Max DD:        {s_oos["dd"]:.2f}%')
print(f'  Trades:        {s_oos["trades"]} | WR: {s_oos["wr"]:.1f}%')
print(f'  Avg Win:       ${s_oos["avg_w"]:.2f} | Avg Loss: ${s_oos["avg_l"]:.2f} | RR: {s_oos["rr"]:.2f}')
print(f'  Longs:         {len(oos_l)} trades | PF={pf_sub(oos_l):.3f}')
print(f'  Shorts:        {len(oos_s)} trades | PF={pf_sub(oos_s):.3f}')
print(f'  Retención OOS: {s_oos["pf"]/s_is["pf"]*100:.1f}%')

# Monte Carlo
mc_is  = monte_carlo_full(profits_is,  1000, deposit)
mc_oos = monte_carlo_full(profits_oos, 1000, deposit)
ruin_is  = sum(1 for d in mc_is[2]  if d >= 10) / 1000 * 100
ruin_oos = sum(1 for d in mc_oos[2] if d >= 10) / 1000 * 100
print(f'\n  P(Ruin DD>=10%) IS:  {ruin_is:.1f}%')
print(f'  P(Ruin DD>=10%) OOS: {ruin_oos:.1f}%')

# ===================== FIGURA 1: MONTE CARLO =====================
fig = plt.figure(figsize=(22, 16), facecolor='#0d1117')
fig.suptitle('Monte Carlo Analysis — SP500 BreakoutNY v2\nMon+Tue+Wed | BE=70 | MinSL=1000 | MaxSL=2000 | Only Longs',
             fontsize=16, fontweight='bold', color='white', y=0.98)

gs = gridspec.GridSpec(3, 2, figure=fig, hspace=0.55, wspace=0.35)

period_data = [('IS 2021–2024', profits_is, is_trades, s_is, mc_is),
               ('OOS 2025',     profits_oos, oos_trades, s_oos, mc_oos)]

for p_idx, (p_label, profits, trades, s, mc) in enumerate(period_data):
    curves, final_p, max_dds = mc

    ax = fig.add_subplot(gs[p_idx, 0])
    ax.set_facecolor('#161b22')
    for curve in curves[:150]:
        ax.plot(curve, color=COLOR, alpha=0.04, linewidth=0.5)
    max_len = max(len(c) for c in curves)
    padded  = [c + [c[-1]]*(max_len-len(c)) for c in curves]
    arr     = np.array(padded)
    p5  = np.percentile(arr, 5,  axis=0)
    p50 = np.percentile(arr, 50, axis=0)
    p95 = np.percentile(arr, 95, axis=0)
    ax.fill_between(range(max_len), p5, p95, alpha=0.12, color=COLOR)
    ax.plot(p5,  '--', color='#ff4444', linewidth=1.3, label='P5')
    ax.plot(p50, '-',  color=COLOR,     linewidth=2.2, label='Mediana')
    ax.plot(p95, '--', color='#44ff44', linewidth=1.3, label='P95')
    real_curve = equity_curve_real(trades, deposit)
    ax.plot(real_curve, color='white', linewidth=2.0, linestyle=':', label='Real')
    ax.axhline(deposit, color='#444', linewidth=0.8, linestyle='--')
    ax.set_title(f'SP500 — {p_label} | PF={s["pf"]:.3f} | DD={s["dd"]:.2f}% | {s["trades"]} trades',
                 color='white', fontsize=9, fontweight='bold')
    ax.set_xlabel('Trades', color='#888', fontsize=7)
    ax.set_ylabel('Equity USD', color='#888', fontsize=7)
    ax.tick_params(colors='#666', labelsize=7)
    for spine in ax.spines.values(): spine.set_color('#333')
    ax.legend(fontsize=6, loc='upper left', facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

    ax2 = fig.add_subplot(gs[p_idx, 1])
    ax2.set_facecolor('#161b22')
    ax2.hist(max_dds, bins=40, color=COLOR, alpha=0.75, edgecolor='none')
    p95_dd = np.percentile(max_dds, 95)
    p99_dd = np.percentile(max_dds, 99)
    ruin = sum(1 for d in max_dds if d >= 10) / len(max_dds) * 100
    ax2.axvline(p95_dd, color='#ff8800', linewidth=1.8, linestyle='--', label=f'P95: {p95_dd:.1f}%')
    ax2.axvline(p99_dd, color='#ff4444', linewidth=1.8, linestyle='--', label=f'P99: {p99_dd:.1f}%')
    ax2.axvline(10,     color='#ff0000', linewidth=2.2, linestyle='-',  label='Limite FP: 10%')
    ax2.set_title(f'DD Distribution — {p_label} | P(DD≥10%): {ruin:.1f}%',
                  color='white', fontsize=9, fontweight='bold')
    ax2.set_xlabel('Max Drawdown %', color='#888', fontsize=7)
    ax2.set_ylabel('Frecuencia', color='#888', fontsize=7)
    ax2.tick_params(colors='#666', labelsize=7)
    for spine in ax2.spines.values(): spine.set_color('#333')
    ax2.legend(fontsize=6, facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

# Profit Distribution IS vs OOS
ax3 = fig.add_subplot(gs[2, :])
ax3.set_facecolor('#161b22')
f_is  = mc_is[1]; f_oos = mc_oos[1]
ax3.hist(f_is,  bins=60, color='#555', alpha=0.6, label='IS 2021–2024', edgecolor='none')
ax3.hist(f_oos, bins=60, color=COLOR,  alpha=0.8, label='OOS 2025',     edgecolor='none')
ax3.axvline(0, color='white', linewidth=1.5, linestyle='--', alpha=0.7)
p5_o  = np.percentile(f_oos, 5)
p50_o = np.percentile(f_oos, 50)
p95_o = np.percentile(f_oos, 95)
ax3.axvline(p5_o,  color='#ff4444', linewidth=1.5, linestyle='--', label=f'P5 OOS: ${p5_o:.0f}')
ax3.axvline(p50_o, color=COLOR,     linewidth=2.2, linestyle='-',  label=f'Mediana OOS: ${p50_o:.0f}')
ax3.axvline(p95_o, color='#44ff44', linewidth=1.5, linestyle='--', label=f'P95 OOS: ${p95_o:.0f}')
pct_neg = sum(1 for f in f_oos if f < 0) / len(f_oos) * 100
ax3.set_title(f'SP500 — Distribucion Profit Final (1000 sim) | P(perdida OOS): {pct_neg:.1f}%',
              color='white', fontsize=11, fontweight='bold')
ax3.set_xlabel('Profit Final USD', color='#888', fontsize=9)
ax3.set_ylabel('Frecuencia', color='#888', fontsize=9)
ax3.tick_params(colors='#666', labelsize=8)
for spine in ax3.spines.values(): spine.set_color('#333')
ax3.legend(fontsize=8, facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

path1 = output_dir + 'MonteCarlo_SP500_v2.png'
plt.savefig(path1, dpi=150, bbox_inches='tight', facecolor='#0d1117')
plt.close()
print(f'\nFig1 OK: {path1}')

# ===================== FIGURA 2: ROBUSTEZ =====================
fig2 = plt.figure(figsize=(22, 12), facecolor='#0d1117')
fig2.suptitle('Robustness Analysis — SP500 BreakoutNY v2\nMon+Tue+Wed | BE=70 | MinSL=1000 | MaxSL=2000',
              fontsize=16, fontweight='bold', color='white', y=0.98)
gs2 = gridspec.GridSpec(2, 3, figure=fig2, hspace=0.50, wspace=0.35)

# R-Multiple
ax = fig2.add_subplot(gs2[0, 0])
ax.set_facecolor('#161b22')
avg_loss = abs(sum(p for p in profits_is if p < 0) / max(1, sum(1 for p in profits_is if p < 0)))
r_is  = [p / avg_loss for p in profits_is]
r_oos = [p / avg_loss for p in profits_oos]
ax.hist(r_is,  bins=25, color='#555', alpha=0.7, label='IS',  edgecolor='none')
ax.hist(r_oos, bins=20, color=COLOR,  alpha=0.8, label='OOS', edgecolor='none')
ax.axvline(0, color='white', linewidth=1.2, linestyle='--')
ax.axvline(np.mean(r_is),  color='#888', linewidth=1.5, linestyle=':', label=f'E[R] IS={np.mean(r_is):.2f}R')
ax.axvline(np.mean(r_oos), color=COLOR,  linewidth=1.5, linestyle=':', label=f'E[R] OOS={np.mean(r_oos):.2f}R')
ax.set_title('R-Multiple Distribution IS vs OOS', color='white', fontsize=10, fontweight='bold')
ax.set_xlabel('R-Multiple', color='#888', fontsize=8)
ax.set_ylabel('Frecuencia', color='#888', fontsize=8)
ax.tick_params(colors='#666', labelsize=7)
for spine in ax.spines.values(): spine.set_color('#333')
ax.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')

# Equity IS + OOS continua
ax2 = fig2.add_subplot(gs2[0, 1])
ax2.set_facecolor('#161b22')
real_is  = equity_curve_real(is_trades,  deposit)
real_oos = equity_curve_real(oos_trades, real_is[-1])
x_is  = list(range(len(real_is)))
x_oos = list(range(len(real_is)-1, len(real_is)-1+len(real_oos)))
ax2.plot(x_is,  real_is,  color=COLOR,    linewidth=2.2, label='IS 2021–2024')
ax2.plot(x_oos, real_oos, color='#ffffff', linewidth=2.2, label='OOS 2025', linestyle='--')
ax2.axvline(len(real_is)-1, color='#ffaa00', linewidth=1.5, linestyle=':', label='Separacion IS/OOS')
ax2.axhline(deposit, color='#444', linewidth=0.8, linestyle='--')
ax2.fill_between(x_is,  deposit, real_is,  alpha=0.15, color=COLOR)
ax2.fill_between(x_oos, deposit, real_oos, alpha=0.15, color='white')
ax2.set_title('Equity Curve IS + OOS continua', color='white', fontsize=10, fontweight='bold')
ax2.set_xlabel('Trades', color='#888', fontsize=8)
ax2.set_ylabel('Equity USD', color='#888', fontsize=8)
ax2.tick_params(colors='#666', labelsize=7)
for spine in ax2.spines.values(): spine.set_color('#333')
ax2.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')

# Rolling PF
ax3 = fig2.add_subplot(gs2[0, 2])
ax3.set_facecolor('#161b22')
all_profits = profits_is + profits_oos
window = 20
rolling_pf = []
for i in range(window, len(all_profits)+1):
    w = all_profits[i-window:i]
    wins_s = sum(p for p in w if p > 0)
    loss_s = abs(sum(p for p in w if p < 0))
    rolling_pf.append(wins_s/loss_s if loss_s > 0 else 2.0)
x_roll = list(range(window, len(all_profits)+1))
sep = len(profits_is)
ax3.plot(x_roll, rolling_pf, color=COLOR, linewidth=1.5, alpha=0.9)
ax3.axhline(1.0, color='#ff4444', linewidth=1.5, linestyle='--', label='PF=1.0 (break-even)')
ax3.axhline(1.5, color='#ffaa00', linewidth=1.0, linestyle=':', label='PF=1.5 (objetivo)')
ax3.axvline(sep, color='#ffaa00', linewidth=1.5, linestyle=':', label='OOS inicio')
ax3.fill_between(x_roll, 1.0, rolling_pf,
                 where=[pf >= 1.0 for pf in rolling_pf], color=COLOR, alpha=0.15)
ax3.fill_between(x_roll, 1.0, rolling_pf,
                 where=[pf < 1.0 for pf in rolling_pf], color='#ff4444', alpha=0.30)
ax3.set_title(f'Rolling PF (ventana {window} trades)', color='white', fontsize=10, fontweight='bold')
ax3.set_xlabel('Trade #', color='#888', fontsize=8)
ax3.set_ylabel('Profit Factor', color='#888', fontsize=8)
ax3.tick_params(colors='#666', labelsize=7)
for spine in ax3.spines.values(): spine.set_color('#333')
ax3.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')
ax3.set_ylim(0, 6)

# Longs vs Shorts IS
ax4 = fig2.add_subplot(gs2[1, 0])
ax4.set_facecolor('#161b22')
ax4.hist([t['net'] for t in is_l], bins=20, color='#44aaff', alpha=0.75,
         label=f'Longs IS (PF={pf_sub(is_l):.2f})', edgecolor='none')
ax4.hist([t['net'] for t in is_s], bins=20, color='#ff7744', alpha=0.75,
         label=f'Shorts IS (PF={pf_sub(is_s):.2f})', edgecolor='none')
ax4.axvline(0, color='white', linewidth=1.2, linestyle='--')
ax4.set_title('P&L Longs vs Shorts — IS', color='white', fontsize=10, fontweight='bold')
ax4.set_xlabel('P&L por Trade (USD)', color='#888', fontsize=8)
ax4.set_ylabel('Frecuencia', color='#888', fontsize=8)
ax4.tick_params(colors='#666', labelsize=7)
for spine in ax4.spines.values(): spine.set_color('#333')
ax4.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')

# Longs vs Shorts OOS
ax5 = fig2.add_subplot(gs2[1, 1])
ax5.set_facecolor('#161b22')
ax5.hist([t['net'] for t in oos_l], bins=15, color='#44aaff', alpha=0.75,
         label=f'Longs OOS (PF={pf_sub(oos_l):.2f})', edgecolor='none')
ax5.hist([t['net'] for t in oos_s], bins=15, color='#ff7744', alpha=0.75,
         label=f'Shorts OOS (PF={pf_sub(oos_s):.2f})', edgecolor='none')
ax5.axvline(0, color='white', linewidth=1.2, linestyle='--')
ax5.set_title('P&L Longs vs Shorts — OOS', color='white', fontsize=10, fontweight='bold')
ax5.set_xlabel('P&L por Trade (USD)', color='#888', fontsize=8)
ax5.set_ylabel('Frecuencia', color='#888', fontsize=8)
ax5.tick_params(colors='#666', labelsize=7)
for spine in ax5.spines.values(): spine.set_color('#333')
ax5.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')

# Tabla resumen
ax6 = fig2.add_subplot(gs2[1, 2])
ax6.set_facecolor('#161b22')
ax6.axis('off')
ret = s_oos['pf'] / s_is['pf'] * 100
table_data = [
    ['Metrica',         'IS 2021-2024',          'OOS 2025'],
    ['Profit Factor',   f'{s_is["pf"]:.3f}',      f'{s_oos["pf"]:.3f}'],
    ['Max DD',          f'{s_is["dd"]:.2f}%',     f'{s_oos["dd"]:.2f}%'],
    ['Trades',          f'{s_is["trades"]}',       f'{s_oos["trades"]}'],
    ['Win Rate',        f'{s_is["wr"]:.1f}%',      f'{s_oos["wr"]:.1f}%'],
    ['Avg Win',         f'${s_is["avg_w"]:.2f}',   f'${s_oos["avg_w"]:.2f}'],
    ['Avg Loss',        f'${s_is["avg_l"]:.2f}',   f'${s_oos["avg_l"]:.2f}'],
    ['RR Promedio',     f'{s_is["rr"]:.2f}:1',     f'{s_oos["rr"]:.2f}:1'],
    ['PF Longs',        f'{pf_sub(is_l):.3f}',     f'{pf_sub(oos_l):.3f}'],
    ['PF Shorts',       f'{pf_sub(is_s):.3f}',     f'{pf_sub(oos_s):.3f}'],
    ['Retencion OOS',   '—',                        f'{ret:.1f}%'],
    ['P(Ruin DD>=10%)', f'{ruin_is:.1f}%',         f'{ruin_oos:.1f}%'],
]
tbl = ax6.table(cellText=table_data[1:], colLabels=table_data[0],
                cellLoc='center', loc='center', bbox=[0, 0, 1, 1])
tbl.auto_set_font_size(False); tbl.set_fontsize(8)
for (r, c), cell in tbl.get_celld().items():
    cell.set_facecolor('#1a1a2e' if r == 0 else '#161b22')
    cell.set_text_props(color='white' if r > 0 else COLOR)
    cell.set_edgecolor('#333')
ax6.set_title('Resumen Estadistico', color='white', fontsize=10, fontweight='bold')

path2 = output_dir + 'Robustez_SP500_v2.png'
plt.savefig(path2, dpi=150, bbox_inches='tight', facecolor='#0d1117')
plt.close()
print(f'Fig2 OK: {path2}')
