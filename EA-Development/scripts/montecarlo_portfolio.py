import openpyxl, random, numpy as np, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

bk_base    = 'c:/Users/JOSSE/Documents/Obsidian Vault/EA-Development/01-Strategies/BreakoutNY/Backtests/'
output_dir = 'c:/Users/JOSSE/Documents/Obsidian Vault/EA-Development/01-Strategies/BreakoutNY/Analisis-MonteCarlo/'

def extract_trades(filepath):
    wb = openpyxl.load_workbook(filepath)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    idx = None
    for i, row in enumerate(rows):
        if row[0] == 'Time' and row[1] == 'Deal' and row[2] == 'Symbol':
            idx = i; break
    if idx is None: return []
    deals = []
    for row in rows[idx+1:]:
        if row[0] is None or row[1] is None: break
        if isinstance(row[1],(int,float)) and row[3] in ('buy','sell') and row[4] in ('in','out','in/out'):
            deals.append({'type':row[3],'direction':row[4],
                          'commission':row[8],'swap':row[9],'profit':row[10],'time':row[0]})
    trades = []; entry = None
    for d in deals:
        if d['direction']=='in': entry=d
        elif d['direction']=='out' and entry is not None:
            net=(d['profit'] or 0)+(entry['commission'] or 0)+(d['commission'] or 0)+(entry['swap'] or 0)+(d['swap'] or 0)
            trades.append({'direction':entry['type'],'net':net,'time':entry['time']})
            entry=None
    return trades

def monte_carlo(profits, n_sim=1000, deposit=5000):
    random.seed(42)
    curves=[]; finals=[]; dds=[]
    for _ in range(n_sim):
        s = random.choices(profits, k=len(profits))
        eq=deposit; pk=deposit; md=0; c=[deposit]
        for p in s:
            eq+=p
            if eq>pk: pk=eq
            dd=(pk-eq)/pk*100
            if dd>md: md=dd
            c.append(eq)
        curves.append(c); finals.append(eq-deposit); dds.append(md)
    return curves, finals, dds

def equity_real(trades, deposit=5000):
    c=[deposit]; eq=deposit
    for t in trades: eq+=t['net']; c.append(eq)
    return c

def stats(trades, deposit=5000):
    eq=deposit; pk=deposit; md=0
    wins=[t for t in trades if t['net']>0]
    loss=[t for t in trades if t['net']<0]
    for t in trades:
        eq+=t['net']
        if eq>pk: pk=eq
        dd=(pk-eq)/pk*100
        if dd>md: md=dd
    pf=sum(t['net'] for t in wins)/abs(sum(t['net'] for t in loss)) if loss else 999
    wr=len(wins)/len(trades)*100 if trades else 0
    return {'profit':eq-deposit,'pf':pf,'dd':md,'trades':len(trades),'wr':wr}

# Cargar los tres activos validados
datasets = {
    'XAUUSD': {
        'is_file':  bk_base+'XAUUSD/IS_XAUUSD_ThuOnly_v2.xlsx',
        'oos_file': bk_base+'XAUUSD/OOS_XAUUSD_ThuOnly_v2.xlsx',
        'color': '#ffd700', 'label_is': 'Thu Only | BE=100 | MinSL=5 | MaxSL=19',
    },
    'NAS100': {
        'is_file':  bk_base+'NAS100/IS_NAS100_MonTueFri_v1.xlsx',
        'oos_file': bk_base+'NAS100/OOS_NAS100_MonTueFri_v1.xlsx',
        'color': '#00d4ff', 'label_is': 'Mon+Tue+Fri | BE=82 | MinSL=35 | MaxSL=120',
    },
    'DJI30': {
        'is_file':  bk_base+'DJI30/IS_DJI30_TueThuFri_v1.xlsx',
        'oos_file': bk_base+'DJI30/OOS_DJI30_TueThuFri_v1.xlsx',
        'color': '#00ff88', 'label_is': 'Tue+Thu+Fri | BE=82 | MinSL=35 | MaxSL=120',
    },
}

deposit = 5000

for name, d in datasets.items():
    d['is_trades']  = extract_trades(d['is_file'])
    d['oos_trades'] = extract_trades(d['oos_file'])
    d['profits_is']  = [t['net'] for t in d['is_trades']]
    d['profits_oos'] = [t['net'] for t in d['oos_trades']]
    d['s_is']  = stats(d['is_trades'])
    d['s_oos'] = stats(d['oos_trades'])
    d['mc_is']  = monte_carlo(d['profits_is'],  1000, deposit)
    d['mc_oos'] = monte_carlo(d['profits_oos'], 1000, deposit)
    print(f"{name}: IS PF={d['s_is']['pf']:.3f} DD={d['s_is']['dd']:.2f}% T={d['s_is']['trades']} | OOS PF={d['s_oos']['pf']:.3f} DD={d['s_oos']['dd']:.2f}% T={d['s_oos']['trades']} | Ret={d['s_oos']['pf']/d['s_is']['pf']*100:.1f}%")

# ===================== FIGURA 1: MONTE CARLO POR ACTIVO =====================
fig = plt.figure(figsize=(24, 20), facecolor='#0d1117')
fig.suptitle('Monte Carlo Analysis — BreakoutNY Portfolio Activo\nXAUUSD v2 + NAS100 v1 + DJI30 v1  |  1000 simulaciones',
             fontsize=17, fontweight='bold', color='white', y=0.99)

gs = gridspec.GridSpec(4, 3, figure=fig, hspace=0.55, wspace=0.32)

for a_idx, (name, d) in enumerate(datasets.items()):
    color = d['color']
    for p_idx, (period, profits, trades, s, mc) in enumerate([
        ('IS 2021-2024', d['profits_is'],  d['is_trades'],  d['s_is'],  d['mc_is']),
        ('OOS 2025',     d['profits_oos'], d['oos_trades'], d['s_oos'], d['mc_oos']),
    ]):
        curves, finals, dds = mc
        ax = fig.add_subplot(gs[p_idx, a_idx])
        ax.set_facecolor('#161b22')
        for curve in curves[:120]:
            ax.plot(curve, color=color, alpha=0.04, linewidth=0.5)
        max_len = max(len(c) for c in curves)
        arr = np.array([c+[c[-1]]*(max_len-len(c)) for c in curves])
        p5=np.percentile(arr,5,axis=0); p50=np.percentile(arr,50,axis=0); p95=np.percentile(arr,95,axis=0)
        ax.fill_between(range(max_len), p5, p95, alpha=0.12, color=color)
        ax.plot(p5,  '--', color='#ff4444', linewidth=1.2, label='P5')
        ax.plot(p50, '-',  color=color,     linewidth=2.0, label='Mediana')
        ax.plot(p95, '--', color='#44ff44', linewidth=1.2, label='P95')
        ax.plot(equity_real(trades, deposit), color='white', linewidth=1.8, linestyle=':', label='Real')
        ax.axhline(deposit, color='#444', linewidth=0.8, linestyle='--')
        ax.set_title(f'{name} — {period}\nPF={s["pf"]:.3f} | DD={s["dd"]:.2f}% | {s["trades"]} trades',
                     color='white', fontsize=8.5, fontweight='bold')
        ax.set_xlabel('Trades', color='#888', fontsize=7)
        ax.set_ylabel('Equity USD', color='#888', fontsize=7)
        ax.tick_params(colors='#666', labelsize=6)
        for sp in ax.spines.values(): sp.set_color('#333')
        if p_idx==0 and a_idx==0:
            ax.legend(fontsize=6, loc='upper left', facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

    # DD Distribution row (fila 2)
    for p_idx, (period, mc) in enumerate([('IS', d['mc_is']), ('OOS', d['mc_oos'])]):
        _, _, dds = mc
        ax2 = fig.add_subplot(gs[p_idx+2, a_idx])
        ax2.set_facecolor('#161b22')
        ax2.hist(dds, bins=40, color=color, alpha=0.75, edgecolor='none')
        p95_dd=np.percentile(dds,95); p99_dd=np.percentile(dds,99)
        ruin=sum(1 for x in dds if x>=10)/len(dds)*100
        ax2.axvline(p95_dd, color='#ff8800', linewidth=1.6, linestyle='--', label=f'P95: {p95_dd:.1f}%')
        ax2.axvline(p99_dd, color='#ff4444', linewidth=1.6, linestyle='--', label=f'P99: {p99_dd:.1f}%')
        ax2.axvline(10,     color='#ff0000', linewidth=2.0, linestyle='-',  label='Limite FP: 10%')
        ax2.set_title(f'{name} DD Dist — {period} | P(ruin): {ruin:.1f}%',
                      color='white', fontsize=8.5, fontweight='bold')
        ax2.set_xlabel('Max DD %', color='#888', fontsize=7)
        ax2.set_ylabel('Frecuencia', color='#888', fontsize=7)
        ax2.tick_params(colors='#666', labelsize=6)
        for sp in ax2.spines.values(): sp.set_color('#333')
        ax2.legend(fontsize=6, facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

plt.savefig(output_dir+'MonteCarlo_Portfolio_XAU_NAS_DJI.png', dpi=150, bbox_inches='tight', facecolor='#0d1117')
plt.close()
print('Fig1 OK: MonteCarlo_Portfolio_XAU_NAS_DJI.png')

# ===================== FIGURA 2: PORTFOLIO COMBINADO =====================
fig2 = plt.figure(figsize=(24, 16), facecolor='#0d1117')
fig2.suptitle('Portfolio Combinado — BreakoutNY (XAUUSD + NAS100 + DJI30)\nEquity acumulada y distribucion de profit final IS vs OOS',
              fontsize=16, fontweight='bold', color='white', y=0.99)
gs2 = gridspec.GridSpec(2, 3, figure=fig2, hspace=0.50, wspace=0.35)

# Profit distribution IS vs OOS por activo
for a_idx, (name, d) in enumerate(datasets.items()):
    color = d['color']
    ax = fig2.add_subplot(gs2[0, a_idx])
    ax.set_facecolor('#161b22')
    f_is  = d['mc_is'][1]; f_oos = d['mc_oos'][1]
    ax.hist(f_is,  bins=55, color='#555', alpha=0.6, label='IS 2021-2024', edgecolor='none')
    ax.hist(f_oos, bins=55, color=color,  alpha=0.8, label='OOS 2025',     edgecolor='none')
    ax.axvline(0, color='white', linewidth=1.3, linestyle='--', alpha=0.7)
    p5_o=np.percentile(f_oos,5); p50_o=np.percentile(f_oos,50); p95_o=np.percentile(f_oos,95)
    ax.axvline(p5_o,  color='#ff4444', linewidth=1.4, linestyle='--', label=f'P5: ${p5_o:.0f}')
    ax.axvline(p50_o, color=color,     linewidth=2.0, linestyle='-',  label=f'Med: ${p50_o:.0f}')
    ax.axvline(p95_o, color='#44ff44', linewidth=1.4, linestyle='--', label=f'P95: ${p95_o:.0f}')
    pct_neg=sum(1 for f in f_oos if f<0)/len(f_oos)*100
    ax.set_title(f'{name} — Profit Final | P(perdida): {pct_neg:.1f}%',
                 color='white', fontsize=10, fontweight='bold')
    ax.set_xlabel('Profit Final USD', color='#888', fontsize=8)
    ax.set_ylabel('Frecuencia', color='#888', fontsize=8)
    ax.tick_params(colors='#666', labelsize=7)
    for sp in ax.spines.values(): sp.set_color('#333')
    ax.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)

# Portfolio equity combinada IS (suma de los 3 activos, alineada por índice)
ax_port = fig2.add_subplot(gs2[1, :2])
ax_port.set_facecolor('#161b22')

# IS combinado — sumar net por trade usando lista unificada (no sincronizada en tiempo, suma de curvas)
for name, d in datasets.items():
    real_is  = equity_real(d['is_trades'],  deposit)
    real_oos = equity_real(d['oos_trades'], real_is[-1])
    x_is  = list(range(len(real_is)))
    x_oos = list(range(len(real_is)-1, len(real_is)-1+len(real_oos)))
    ax_port.plot(x_is,  real_is,  color=d['color'], linewidth=1.8, label=f'{name} IS', alpha=0.9)
    ax_port.plot(x_oos, real_oos, color=d['color'], linewidth=1.8, linestyle='--', alpha=0.7)
    ax_port.axvline(len(real_is)-1, color=d['color'], linewidth=0.8, linestyle=':', alpha=0.4)

ax_port.axhline(deposit, color='#444', linewidth=0.8, linestyle='--')
ax_port.axvline(0, color='#ffaa00', linewidth=1.0, linestyle='-', alpha=0.0)
ax_port.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white', framealpha=0.8)
ax_port.set_title('Equity Curves IS (solido) + OOS (discontinuo) — Los 3 activos',
                   color='white', fontsize=11, fontweight='bold')
ax_port.set_xlabel('Trades', color='#888', fontsize=8)
ax_port.set_ylabel('Equity USD', color='#888', fontsize=8)
ax_port.tick_params(colors='#666', labelsize=7)
for sp in ax_port.spines.values(): sp.set_color('#333')

# Tabla resumen portfolio
ax_tbl = fig2.add_subplot(gs2[1, 2])
ax_tbl.set_facecolor('#161b22')
ax_tbl.axis('off')
rows_data = [['Activo','PF IS','DD IS','PF OOS','DD OOS','Ret%','P(Ruin)']]
for name, d in datasets.items():
    ruin_oos = sum(1 for x in d['mc_oos'][2] if x>=10)/1000*100
    ret = d['s_oos']['pf']/d['s_is']['pf']*100
    rows_data.append([
        name,
        f'{d["s_is"]["pf"]:.3f}', f'{d["s_is"]["dd"]:.2f}%',
        f'{d["s_oos"]["pf"]:.3f}', f'{d["s_oos"]["dd"]:.2f}%',
        f'{ret:.1f}%', f'{ruin_oos:.1f}%'
    ])
colors_row = ['#ffd700','#00d4ff','#00ff88']
tbl = ax_tbl.table(cellText=rows_data[1:], colLabels=rows_data[0],
                   cellLoc='center', loc='center', bbox=[0,0,1,1])
tbl.auto_set_font_size(False); tbl.set_fontsize(8)
for (r,c), cell in tbl.get_celld().items():
    if r==0:
        cell.set_facecolor('#1a1a2e')
        cell.set_text_props(color='white', fontweight='bold')
    else:
        cell.set_facecolor('#161b22')
        cell.set_text_props(color=colors_row[r-1])
    cell.set_edgecolor('#333')
ax_tbl.set_title('Resumen Portfolio', color='white', fontsize=10, fontweight='bold')

plt.savefig(output_dir+'Portfolio_Combinado_XAU_NAS_DJI.png', dpi=150, bbox_inches='tight', facecolor='#0d1117')
plt.close()
print('Fig2 OK: Portfolio_Combinado_XAU_NAS_DJI.png')

# ===================== FIGURA 3: ROBUSTEZ =====================
fig3 = plt.figure(figsize=(24, 14), facecolor='#0d1117')
fig3.suptitle('Robustness Analysis — BreakoutNY Portfolio (XAUUSD v2 + NAS100 + DJI30)',
              fontsize=16, fontweight='bold', color='white', y=0.99)
gs3 = gridspec.GridSpec(2, 3, figure=fig3, hspace=0.50, wspace=0.35)

for a_idx, (name, d) in enumerate(datasets.items()):
    color = d['color']
    profits_is  = d['profits_is']
    profits_oos = d['profits_oos']

    # R-Multiple
    ax = fig3.add_subplot(gs3[0, a_idx])
    ax.set_facecolor('#161b22')
    avg_l = abs(sum(p for p in profits_is if p<0)/max(1,sum(1 for p in profits_is if p<0)))
    r_is  = [p/avg_l for p in profits_is]
    r_oos = [p/avg_l for p in profits_oos]
    ax.hist(r_is,  bins=25, color='#555', alpha=0.7, label='IS',  edgecolor='none')
    ax.hist(r_oos, bins=20, color=color,  alpha=0.8, label='OOS', edgecolor='none')
    ax.axvline(0, color='white', linewidth=1.2, linestyle='--')
    ax.axvline(np.mean(r_is),  color='#888', linewidth=1.4, linestyle=':', label=f'E[R] IS={np.mean(r_is):.2f}R')
    ax.axvline(np.mean(r_oos), color=color,  linewidth=1.4, linestyle=':', label=f'E[R] OOS={np.mean(r_oos):.2f}R')
    ax.set_title(f'{name} — R-Multiple Distribution', color='white', fontsize=10, fontweight='bold')
    ax.set_xlabel('R-Multiple', color='#888', fontsize=8)
    ax.set_ylabel('Frecuencia', color='#888', fontsize=8)
    ax.tick_params(colors='#666', labelsize=7)
    for sp in ax.spines.values(): sp.set_color('#333')
    ax.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')

    # Rolling PF
    ax2 = fig3.add_subplot(gs3[1, a_idx])
    ax2.set_facecolor('#161b22')
    all_p = profits_is + profits_oos
    window = 15 if name=='XAUUSD' else 20
    rpf = []
    for i in range(window, len(all_p)+1):
        w=all_p[i-window:i]
        wn=sum(p for p in w if p>0); ln=abs(sum(p for p in w if p<0))
        rpf.append(wn/ln if ln>0 else 2.0)
    xr=list(range(window, len(all_p)+1)); sep=len(profits_is)
    ax2.plot(xr, rpf, color=color, linewidth=1.5, alpha=0.9)
    ax2.axhline(1.0, color='#ff4444', linewidth=1.5, linestyle='--', label='PF=1.0')
    ax2.axhline(1.5, color='#ffaa00', linewidth=1.0, linestyle=':', label='PF=1.5 obj')
    ax2.axvline(sep, color='#ffaa00', linewidth=1.5, linestyle=':', label='OOS inicio')
    ax2.fill_between(xr, 1.0, rpf, where=[p>=1.0 for p in rpf], color=color, alpha=0.15)
    ax2.fill_between(xr, 1.0, rpf, where=[p<1.0  for p in rpf], color='#ff4444', alpha=0.30)
    ax2.set_title(f'{name} — Rolling PF (ventana {window})', color='white', fontsize=10, fontweight='bold')
    ax2.set_xlabel('Trade #', color='#888', fontsize=8)
    ax2.set_ylabel('Profit Factor', color='#888', fontsize=8)
    ax2.tick_params(colors='#666', labelsize=7)
    for sp in ax2.spines.values(): sp.set_color('#333')
    ax2.legend(fontsize=7, facecolor='#1a1a2e', labelcolor='white')
    ax2.set_ylim(0, 6)

plt.savefig(output_dir+'Robustez_Portfolio_XAU_NAS_DJI.png', dpi=150, bbox_inches='tight', facecolor='#0d1117')
plt.close()
print('Fig3 OK: Robustez_Portfolio_XAU_NAS_DJI.png')
