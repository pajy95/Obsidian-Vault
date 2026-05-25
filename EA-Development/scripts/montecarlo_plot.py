
import openpyxl, random, numpy as np, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

base = 'c:/Users/JOSSE/Documents/Obsidian Vault/EA-Development/01-Strategies/BreakoutNY/Optmizacion/'
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

def monte_carlo_full(profits, n_sim=1000, deposit=5000):
    random.seed(42)
    all_equity_curves = []; final_profits = []; max_dds = []
    for _ in range(n_sim):
        sample = random.choices(profits, k=len(profits))
        equity = deposit; peak = deposit; max_dd = 0; curve = [deposit]
        for p in sample:
            equity += p
            if equity > peak: peak = equity
            dd = (peak-equity)/peak*100
            if dd > max_dd: max_dd = dd
            curve.append(equity)
        all_equity_curves.append(curve)
        final_profits.append(equity-deposit)
        max_dds.append(max_dd)
    return all_equity_curves, final_profits, max_dds

def equity_curve_real(trades, deposit=5000):
    curve = [deposit]
    equity = deposit
    for t in trades:
        equity += t['net']
        curve.append(equity)
    return curve

# Cargar datos
nas_is  = extract_trades('BK NAS100.xlsx')
nas_oos = extract_trades('FR NAS100.xlsx')
dji_is  = extract_trades('bk dji30.xlsx')
dji_oos = extract_trades('fr dji30.xlsx')

datasets = {
    'NAS100': {'is': nas_is, 'oos': nas_oos, 'color': '#00d4ff'},
    'DJI30':  {'is': dji_is, 'oos': dji_oos, 'color': '#00ff88'},
}

# ===================== FIGURA 1: MONTE CARLO =====================
fig = plt.figure(figsize=(22, 16), facecolor='#0d1117')
fig.suptitle('Monte Carlo Analysis — BreakoutNY Portfolio (NAS100 + DJI30)',
             fontsize=18, fontweight='bold', color='white', y=0.98)

gs = gridspec.GridSpec(3, 4, figure=fig, hspace=0.50, wspace=0.35)

period_labels = {'is': 'In-Sample 2021-2024', 'oos': 'Out-of-Sample 2025'}
mc_results = {}

for a_idx, (asset, data) in enumerate(datasets.items()):
    color = data['color']
    mc_results[asset] = {}

    for p_idx, (p_key, p_label) in enumerate(period_labels.items()):
        trades  = data[p_key]
        profits = [t['net'] for t in trades]
        deposit = 5000

        curves, final_p, max_dds = monte_carlo_full(profits, n_sim=500, deposit=deposit)
        mc_results[asset][p_key] = {'curves': curves, 'final': final_p, 'dds': max_dds}

        # --- Equity Curves ---
        col_base = a_idx * 2
        ax = fig.add_subplot(gs[p_idx, col_base])
        ax.set_facecolor('#161b22')
        for curve in curves[:120]:
            ax.plot(curve, color=color, alpha=0.04, linewidth=0.5)
        max_len = max(len(c) for c in curves)
        padded  = [c + [c[-1]]*(max_len-len(c)) for c in curves]
        arr     = np.array(padded)
        p5      = np.percentile(arr, 5,  axis=0)
        p50     = np.percentile(arr, 50, axis=0)
        p95     = np.percentile(arr, 95, axis=0)
        ax.fill_between(range(max_len), p5, p95, alpha=0.12, color=color)
        ax.plot(p5,  '--', color='#ff4444', linewidth=1.3, label='P5')
        ax.plot(p50, '-',  color=color,    linewidth=2.2, label='Mediana')
        ax.plot(p95, '--', color='#44ff44', linewidth=1.3, label='P95')
        real_curve = equity_curve_real(trades, deposit)
        ax.plot(real_curve, color='white', linewidth=1.8, linestyle=':', label='Real')
        ax.axhline(deposit, color='#444', linewidth=0.8, linestyle='--')
        ax.set_title(f'{asset} — {p_label}', color='white', fontsize=9, fontweight='bold')
        ax.set_xlabel('Trades', color='#888', fontsize=7)
        ax.set_ylabel('Equity USD', color='#888', fontsize=7)
        ax.tick_params(colors='#666', labelsize=7)
        for spine in ax.spines.values(): spine.set_color('#333')
        if p_idx == 0 and a_idx == 0:
            ax.legend(fontsize=6, loc='upper left', facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

        # --- DD Distribution ---
        ax2 = fig.add_subplot(gs[p_idx, col_base+1])
        ax2.set_facecolor('#161b22')
        ax2.hist(max_dds, bins=35, color=color, alpha=0.75, edgecolor='none')
        p95_dd = np.percentile(max_dds, 95)
        p99_dd = np.percentile(max_dds, 99)
        ax2.axvline(p95_dd, color='#ff8800', linewidth=1.8, linestyle='--', label=f'P95: {p95_dd:.1f}%')
        ax2.axvline(p99_dd, color='#ff4444', linewidth=1.8, linestyle='--', label=f'P99: {p99_dd:.1f}%')
        ax2.axvline(10,     color='#ff0000', linewidth=2.2, linestyle='-',  label='Limite FP: 10%')
        ax2.set_title(f'DD Distribution — {asset} {p_key.upper()}', color='white', fontsize=9, fontweight='bold')
        ax2.set_xlabel('Max Drawdown %', color='#888', fontsize=7)
        ax2.set_ylabel('Frecuencia', color='#888', fontsize=7)
        ax2.tick_params(colors='#666', labelsize=7)
        for spine in ax2.spines.values(): spine.set_color('#333')
        ax2.legend(fontsize=6, facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

# --- Fila 3: Profit Distribution comparada IS vs OOS ---
for a_idx, (asset, data) in enumerate(datasets.items()):
    color = data['color']
    ax3   = fig.add_subplot(gs[2, a_idx*2:(a_idx*2)+2])
    ax3.set_facecolor('#161b22')

    f_is  = mc_results[asset]['is']['final']
    f_oos = mc_results[asset]['oos']['final']

    ax3.hist(f_is,  bins=50, color='#555', alpha=0.6, label='IS (2021-2024)', edgecolor='none')
    ax3.hist(f_oos, bins=50, color=color,  alpha=0.8, label='OOS (2025)',     edgecolor='none')
    ax3.axvline(0, color='white', linewidth=1.5, linestyle='--', alpha=0.7)
    p5_o  = np.percentile(f_oos, 5)
    p50_o = np.percentile(f_oos, 50)
    p95_o = np.percentile(f_oos, 95)
    ax3.axvline(p5_o,  color='#ff4444', linewidth=1.5, linestyle='--', label=f'P5: ${p5_o:.0f}')
    ax3.axvline(p50_o, color=color,     linewidth=2.2, linestyle='-',  label=f'Mediana: ${p50_o:.0f}')
    ax3.axvline(p95_o, color='#44ff44', linewidth=1.5, linestyle='--', label=f'P95: ${p95_o:.0f}')
    ax3.set_title(f'{asset} — Distribucion Profit Final (500 simulaciones)', color='white', fontsize=11, fontweight='bold')
    ax3.set_xlabel('Profit Final USD', color='#888', fontsize=9)
    ax3.set_ylabel('Frecuencia', color='#888', fontsize=9)
    ax3.tick_params(colors='#666', labelsize=8)
    for spine in ax3.spines.values(): spine.set_color('#333')
    ax3.legend(fontsize=8, facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

path1 = output_dir + 'MonteCarlo_NAS100_DJI30.png'
plt.savefig(path1, dpi=150, bbox_inches='tight', facecolor='#0d1117')
plt.close()
print(f'Fig1 OK: {path1}')

# ===================== FIGURA 2: ROBUSTEZ =====================
fig2, axes = plt.subplots(2, 3, figsize=(20, 12), facecolor='#0d1117')
fig2.suptitle('Robustness Analysis — BreakoutNY Portfolio (NAS100 + DJI30)',
              fontsize=16, fontweight='bold', color='white', y=0.98)

for a_idx, (asset, data) in enumerate(datasets.items()):
    color = data['color']
    profits_is  = [t['net'] for t in data['is']]
    profits_oos = [t['net'] for t in data['oos']]
    deposit = 5000

    # --- R-Multiple Distribution ---
    ax = axes[a_idx][0]
    ax.set_facecolor('#161b22')
    avg_loss_is = abs(sum(p for p in profits_is if p < 0) / max(1, sum(1 for p in profits_is if p < 0)))
    r_multiples = [p / avg_loss_is for p in profits_is]
    r_oos       = [p / avg_loss_is for p in profits_oos]
    ax.hist(r_multiples, bins=30, color='#555', alpha=0.7, label='IS', edgecolor='none')
    ax.hist(r_oos,       bins=20, color=color,  alpha=0.8, label='OOS', edgecolor='none')
    ax.axvline(0,  color='white', linewidth=1.2, linestyle='--')
    ax.axvline(np.mean(r_multiples), color='#888', linewidth=1.5, linestyle=':', label=f'E[R] IS={np.mean(r_multiples):.2f}R')
    ax.axvline(np.mean(r_oos),       color=color,  linewidth=1.5, linestyle=':', label=f'E[R] OOS={np.mean(r_oos):.2f}R')
    ax.set_title(f'{asset} — R-Multiple Distribution', color='white', fontsize=10, fontweight='bold')
    ax.set_xlabel('R-Multiple', color='#888', fontsize=8)
    ax.set_ylabel('Frecuencia', color='#888', fontsize=8)
    ax.tick_params(colors='#666', labelsize=7)
    for spine in ax.spines.values(): spine.set_color('#333')
    ax.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')

    # --- Equity Curve IS + OOS continua ---
    ax2 = axes[a_idx][1]
    ax2.set_facecolor('#161b22')
    real_is  = equity_curve_real(data['is'],  deposit)
    real_oos = equity_curve_real(data['oos'], real_is[-1])
    x_is  = list(range(len(real_is)))
    x_oos = list(range(len(real_is)-1, len(real_is)-1+len(real_oos)))
    ax2.plot(x_is,  real_is,  color=color,     linewidth=2.0, label='IS 2021-2024')
    ax2.plot(x_oos, real_oos, color='#ffffff',  linewidth=2.0, label='OOS 2025', linestyle='--')
    ax2.axvline(len(real_is)-1, color='#ffaa00', linewidth=1.5, linestyle=':', label='Separacion IS/OOS')
    ax2.axhline(deposit, color='#444', linewidth=0.8, linestyle='--')
    ax2.fill_between(x_is,  deposit, real_is,  alpha=0.15, color=color)
    ax2.fill_between(x_oos, deposit, real_oos, alpha=0.15, color='white')
    ax2.set_title(f'{asset} — Equity Curve IS + OOS', color='white', fontsize=10, fontweight='bold')
    ax2.set_xlabel('Trades', color='#888', fontsize=8)
    ax2.set_ylabel('Equity USD', color='#888', fontsize=8)
    ax2.tick_params(colors='#666', labelsize=7)
    for spine in ax2.spines.values(): spine.set_color('#333')
    ax2.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')

    # --- Rolling PF (ventana 20 trades) ---
    ax3 = axes[a_idx][2]
    ax3.set_facecolor('#161b22')
    all_profits = profits_is + profits_oos
    window = 20
    rolling_pf = []
    for i in range(window, len(all_profits)+1):
        w = all_profits[i-window:i]
        wins  = sum(p for p in w if p > 0)
        losses = abs(sum(p for p in w if p < 0))
        rolling_pf.append(wins/losses if losses > 0 else 2.0)
    x_roll = list(range(window, len(all_profits)+1))
    sep = len(profits_is)
    ax3.plot(x_roll, rolling_pf, color=color, linewidth=1.5, alpha=0.9)
    ax3.axhline(1.0, color='#ff4444', linewidth=1.5, linestyle='--', label='PF=1.0 (break-even)')
    ax3.axhline(1.5, color='#ffaa00', linewidth=1.0, linestyle=':', label='PF=1.5 (objetivo)')
    ax3.axvline(sep, color='#ffaa00', linewidth=1.5, linestyle=':', label='OOS inicio')
    ax3.fill_between(x_roll, 1.0, rolling_pf,
                     where=[pf >= 1.0 for pf in rolling_pf], color=color, alpha=0.15)
    ax3.fill_between(x_roll, 1.0, rolling_pf,
                     where=[pf < 1.0 for pf in rolling_pf], color='#ff4444', alpha=0.25)
    ax3.set_title(f'{asset} — Rolling PF (ventana {window} trades)', color='white', fontsize=10, fontweight='bold')
    ax3.set_xlabel('Trade #', color='#888', fontsize=8)
    ax3.set_ylabel('Profit Factor', color='#888', fontsize=8)
    ax3.tick_params(colors='#666', labelsize=7)
    for spine in ax3.spines.values(): spine.set_color('#333')
    ax3.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')
    ax3.set_ylim(0, 5)

path2 = output_dir + 'Robustez_NAS100_DJI30.png'
plt.savefig(path2, dpi=150, bbox_inches='tight', facecolor='#0d1117')
plt.close()
print(f'Fig2 OK: {path2}')
