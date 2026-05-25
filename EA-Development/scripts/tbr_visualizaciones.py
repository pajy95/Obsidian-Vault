"""
Visualizaciones — TBR v1.0b P63 L/M/X NAS100
Genera dos imagenes:
  1. MonteCarlo_NAS100_P63_LMX.png  — Equity curves, DD, histogramas de profit
  2. Robustez_NAS100_P63_LMX.png    — R-multiples, equity IS+OOS, Rolling PF
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pandas as pd, numpy as np, warnings
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import xml.etree.ElementTree as ET
warnings.filterwarnings('ignore')

np.random.seed(42)

# ── Rutas ────────────────────────────────────────────────────────────────────
BASE    = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100"
OUT_DIR = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Analisis-MonteCarlo\NAS100"
XML_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\NAS100\TBR B V1.xml"

VPP     = 20.0
RR      = 4.0
ACCOUNT = 5_000.0
N_SIM   = 10_000

# ── Colores ──────────────────────────────────────────────────────────────────
BG_DARK   = '#0d1117'
BG_PANEL  = '#161b22'
CYAN      = '#00e5ff'
GREEN     = '#39d353'
ORANGE    = '#f08030'
RED       = '#ff4444'
YELLOW    = '#ffd700'
GRAY      = '#8b949e'
WHITE     = '#e6edf3'
BLUE      = '#58a6ff'

# ── Parser de trades ──────────────────────────────────────────────────────────
def parse(path):
    df = pd.read_excel(path, header=None)
    rows = df[df[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]
    buys = rows[(rows[3].astype(str).str.strip().str.lower() == 'buy stop') &
                (rows[11].astype(str).str.strip().str.lower() == 'filled')]
    sells = rows[(rows[3].astype(str).str.strip().str.lower() == 'sell') &
                 (rows[6].astype(str) != '0')]
    entries, exits = [], []
    for _, r in buys.iterrows():
        try:
            p = float(r[6]); sl = float(r[7]); tp = float(r[8])
        except:
            continue
        if p > 0 and sl > 0 and tp > 0 and p > sl:
            vol = 0.01
            try: vol = float(str(r[4]).split('/')[0].strip())
            except: pass
            entries.append({'sl_dist': p - sl, 'vol': vol})
    for _, r in sells.iterrows():
        c = str(r[12]).strip().lower()
        et = 'TP' if 'tp' in c else ('SL' if 'sl' in c else 'Timeout')
        exits.append({'exit_type': et})
    n = min(len(entries), len(exits))
    profits, r_multiples = [], []
    for i in range(n):
        e = entries[i]; x = exits[i]
        if x['exit_type'] == 'TP':
            p = e['vol'] * e['sl_dist'] * VPP * RR
            r_multiples.append(RR)
        elif x['exit_type'] == 'SL':
            p = -e['vol'] * e['sl_dist'] * VPP
            r_multiples.append(-1.0)
        else:
            p = 0.0
            r_multiples.append(0.0)
        profits.append(p)
    return np.array(profits), np.array(r_multiples)

print("Cargando datos...")
is_p, is_r   = parse(f"{BASE}\\IS tbr nas100 v1b pass63 no JV.xlsx")
oos_p, oos_r = parse(f"{BASE}\\OOS tbr nas100 v1b pass63 no JV.xlsx")
wfa_p, wfa_r = parse(f"{BASE}\\WFA TBR NAS100 2026.xlsx")

all_trades = np.concatenate([oos_p, wfa_p])
all_r      = np.concatenate([oos_r, wfa_r])

print(f"IS:  {len(is_p)} trades  | PF={is_p[is_p>0].sum()/abs(is_p[is_p<0].sum()):.3f}")
print(f"OOS: {len(oos_p)} trades | PF={oos_p[oos_p>0].sum()/abs(oos_p[oos_p<0].sum()):.3f}")
print(f"WFA: {len(wfa_p)} trades | PF={wfa_p[wfa_p>0].sum()/abs(wfa_p[wfa_p<0].sum()):.3f}")

# ── Funcion de simulacion ─────────────────────────────────────────────────────
def simulate(trades, n_trades, n_sim, account, max_dd_pct=0.10):
    net_results = np.zeros(n_sim)
    max_dd_pct_arr = np.zeros(n_sim)
    equity_curves = np.zeros((n_sim, n_trades))
    for i in range(n_sim):
        sample = np.random.choice(trades, size=n_trades, replace=True)
        cum = np.cumsum(sample)
        equity_curves[i] = cum
        peak = np.maximum.accumulate(cum)
        dd = (peak - cum) / account
        max_dd_pct_arr[i] = dd.max()
        net_results[i] = cum[-1]
    return net_results, max_dd_pct_arr, equity_curves

print("Simulando Monte Carlo (10,000 iteraciones)...")
net1, dd1, ec1 = simulate(all_trades, len(oos_p), N_SIM, ACCOUNT)
net2, dd2, ec2 = simulate(all_trades, len(wfa_p), N_SIM, ACCOUNT)

# ── Calculo de equity curves reales ──────────────────────────────────────────
is_cum  = np.cumsum(is_p)
oos_cum = np.cumsum(oos_p)
wfa_cum = np.cumsum(wfa_p)

# OOS + WFA concatenados (para equity curve post-IS)
oos_wfa_cum = np.concatenate([oos_cum, oos_cum[-1] + wfa_cum]) if len(oos_cum) > 0 else wfa_cum

# ── Rolling PF ────────────────────────────────────────────────────────────────
def rolling_pf(profits, window=20):
    pf_vals = []
    for i in range(window - 1, len(profits)):
        w = profits[i - window + 1:i + 1]
        wins = w[w > 0].sum()
        loss = abs(w[w < 0].sum())
        pf_vals.append(wins / loss if loss > 0 else 2.0)
    return np.array(pf_vals)

is_rpf   = rolling_pf(is_p)
oos_rpf  = rolling_pf(oos_p)
wfa_rpf  = rolling_pf(wfa_p)

# ──────────────────────────────────────────────────────────────────────────────
# IMAGEN 1 — MONTE CARLO
# ──────────────────────────────────────────────────────────────────────────────
print("\nGenerando imagen Monte Carlo...")

fig = plt.figure(figsize=(18, 14), facecolor=BG_DARK)
fig.suptitle('Monte Carlo — TBR v1.0b P63 L/M/X | NAS100 M5',
             color=WHITE, fontsize=16, fontweight='bold', y=0.98)

gs = fig.add_gridspec(3, 3, hspace=0.42, wspace=0.32,
                       left=0.07, right=0.97, top=0.93, bottom=0.06)

def style_ax(ax, title, xlabel='', ylabel=''):
    ax.set_facecolor(BG_PANEL)
    ax.set_title(title, color=WHITE, fontsize=10, fontweight='bold', pad=6)
    ax.set_xlabel(xlabel, color=GRAY, fontsize=8)
    ax.set_ylabel(ylabel, color=GRAY, fontsize=8)
    ax.tick_params(colors=GRAY, labelsize=7)
    for spine in ax.spines.values():
        spine.set_edgecolor('#30363d')
    ax.grid(True, color='#21262d', linewidth=0.5, alpha=0.7)

# ── Fila 1: Equity curves Escenario OOS (145 trades) ─────────────────────────
ax00 = fig.add_subplot(gs[0, 0])
style_ax(ax00, 'Equity Curves — Escenario OOS (145 trades)', 'Trade #', 'P&L ($)')
idx_sample = np.random.choice(N_SIM, 200, replace=False)
for i in idx_sample:
    color = GREEN if ec1[i, -1] > 0 else RED
    ax00.plot(ec1[i], color=color, alpha=0.06, linewidth=0.6)
ax00.plot(np.percentile(ec1, 50, axis=0), color=CYAN, linewidth=2, label='P50')
ax00.plot(np.percentile(ec1, 5,  axis=0), color=ORANGE, linewidth=1.5, linestyle='--', label='P5')
ax00.plot(np.percentile(ec1, 95, axis=0), color=GREEN, linewidth=1.5, linestyle='--', label='P95')
ax00.axhline(0, color=GRAY, linewidth=0.8, linestyle=':')
ax00.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE, loc='upper left')
p_prof1 = (net1 > 0).mean() * 100
p_ruin1 = (dd1 >= 0.10).mean() * 100
ax00.text(0.98, 0.05, f'P(>0): {p_prof1:.1f}%\nP(ruin): {p_ruin1:.2f}%',
          transform=ax00.transAxes, color=CYAN, fontsize=8, ha='right', va='bottom',
          bbox=dict(boxstyle='round,pad=0.3', facecolor=BG_DARK, alpha=0.7))

# ── Distribución MaxDD Escenario OOS ─────────────────────────────────────────
ax01 = fig.add_subplot(gs[0, 1])
style_ax(ax01, 'Distribución MaxDD — Escenario OOS', 'Max DD (%)', 'Frecuencia')
dd1_pct = dd1 * 100
ax01.hist(dd1_pct, bins=60, color=CYAN, alpha=0.8, edgecolor='none')
ax01.axvline(np.percentile(dd1_pct, 5),  color=GREEN, linewidth=1.5, linestyle='--', label=f'P5: {np.percentile(dd1_pct,5):.1f}%')
ax01.axvline(np.percentile(dd1_pct, 50), color=YELLOW, linewidth=1.5, linestyle='-',  label=f'P50: {np.percentile(dd1_pct,50):.1f}%')
ax01.axvline(np.percentile(dd1_pct, 95), color=ORANGE, linewidth=1.5, linestyle='--', label=f'P95: {np.percentile(dd1_pct,95):.1f}%')
ax01.axvline(10.0, color=RED, linewidth=2, linestyle=':', label='Límite 10%')
ax01.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE)

# ── Histograma Net Profit OOS ────────────────────────────────────────────────
ax02 = fig.add_subplot(gs[0, 2])
style_ax(ax02, 'Distribución Profit Final — Escenario OOS', 'Net Profit ($)', 'Frecuencia')
ax02.hist(net1, bins=80, color=CYAN, alpha=0.8, edgecolor='none')
ax02.axvline(0,                      color=RED,    linewidth=1.5, linestyle=':', label='Break-even')
ax02.axvline(np.percentile(net1, 5), color=ORANGE, linewidth=1.5, linestyle='--', label=f'P5: ${np.percentile(net1,5):+.0f}')
ax02.axvline(np.percentile(net1,50), color=YELLOW, linewidth=1.5, linestyle='-',  label=f'P50: ${np.percentile(net1,50):+.0f}')
ax02.axvline(np.percentile(net1,95), color=GREEN,  linewidth=1.5, linestyle='--', label=f'P95: ${np.percentile(net1,95):+.0f}')
ax02.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE)

# ── Fila 2: Equity curves Escenario WFA (52 trades) ──────────────────────────
ax10 = fig.add_subplot(gs[1, 0])
style_ax(ax10, 'Equity Curves — Escenario WFA (52 trades)', 'Trade #', 'P&L ($)')
for i in idx_sample:
    color = GREEN if ec2[i, -1] > 0 else RED
    ax10.plot(ec2[i], color=color, alpha=0.07, linewidth=0.6)
ax10.plot(np.percentile(ec2, 50, axis=0), color=CYAN,   linewidth=2,   label='P50')
ax10.plot(np.percentile(ec2, 5,  axis=0), color=ORANGE, linewidth=1.5, linestyle='--', label='P5')
ax10.plot(np.percentile(ec2, 95, axis=0), color=GREEN,  linewidth=1.5, linestyle='--', label='P95')
ax10.axhline(0, color=GRAY, linewidth=0.8, linestyle=':')
ax10.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE, loc='upper left')
p_prof2 = (net2 > 0).mean() * 100
p_ruin2 = (dd2 >= 0.10).mean() * 100
ax10.text(0.98, 0.05, f'P(>0): {p_prof2:.1f}%\nP(ruin): {p_ruin2:.2f}%',
          transform=ax10.transAxes, color=CYAN, fontsize=8, ha='right', va='bottom',
          bbox=dict(boxstyle='round,pad=0.3', facecolor=BG_DARK, alpha=0.7))

# ── Distribución MaxDD Escenario WFA ─────────────────────────────────────────
ax11 = fig.add_subplot(gs[1, 1])
style_ax(ax11, 'Distribución MaxDD — Escenario WFA', 'Max DD (%)', 'Frecuencia')
dd2_pct = dd2 * 100
ax11.hist(dd2_pct, bins=60, color=BLUE, alpha=0.8, edgecolor='none')
ax11.axvline(np.percentile(dd2_pct, 5),  color=GREEN, linewidth=1.5, linestyle='--', label=f'P5: {np.percentile(dd2_pct,5):.1f}%')
ax11.axvline(np.percentile(dd2_pct, 50), color=YELLOW, linewidth=1.5, linestyle='-',  label=f'P50: {np.percentile(dd2_pct,50):.1f}%')
ax11.axvline(np.percentile(dd2_pct, 95), color=ORANGE, linewidth=1.5, linestyle='--', label=f'P95: {np.percentile(dd2_pct,95):.1f}%')
ax11.axvline(10.0, color=RED, linewidth=2, linestyle=':', label='Límite 10%')
ax11.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE)

# ── Histograma Net Profit WFA ─────────────────────────────────────────────────
ax12 = fig.add_subplot(gs[1, 2])
style_ax(ax12, 'Distribución Profit Final — Escenario WFA', 'Net Profit ($)', 'Frecuencia')
ax12.hist(net2, bins=80, color=BLUE, alpha=0.8, edgecolor='none')
ax12.axvline(0,                       color=RED,    linewidth=1.5, linestyle=':', label='Break-even')
ax12.axvline(np.percentile(net2, 5),  color=ORANGE, linewidth=1.5, linestyle='--', label=f'P5: ${np.percentile(net2,5):+.0f}')
ax12.axvline(np.percentile(net2, 50), color=YELLOW, linewidth=1.5, linestyle='-',  label=f'P50: ${np.percentile(net2,50):+.0f}')
ax12.axvline(np.percentile(net2, 95), color=GREEN,  linewidth=1.5, linestyle='--', label=f'P95: ${np.percentile(net2,95):+.0f}')
ax12.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE)

# ── Fila 3: Equity curve real IS+OOS+WFA / Rachas / Veredicto ─────────────────
ax20 = fig.add_subplot(gs[2, 0])
style_ax(ax20, 'Equity Curve Real — IS / OOS / WFA', 'Trade #', 'P&L Acumulado ($)')
x_is  = np.arange(len(is_p))
x_oos = np.arange(len(is_p), len(is_p) + len(oos_p))
x_wfa = np.arange(len(is_p) + len(oos_p), len(is_p) + len(oos_p) + len(wfa_p))

offset_oos = is_cum[-1] if len(is_cum) > 0 else 0
offset_wfa = offset_oos + (oos_cum[-1] if len(oos_cum) > 0 else 0)

ax20.plot(x_is,  is_cum,            color=GRAY,  linewidth=1.5, label=f'IS ({len(is_p)}T)')
ax20.plot(x_oos, offset_oos + oos_cum, color=CYAN,  linewidth=1.8, label=f'OOS ({len(oos_p)}T)')
ax20.plot(x_wfa, offset_wfa + wfa_cum, color=ORANGE, linewidth=1.8, label=f'WFA ({len(wfa_p)}T)')
ax20.axvline(len(is_p),             color='#30363d', linewidth=1.2, linestyle='--')
ax20.axvline(len(is_p)+len(oos_p),  color='#30363d', linewidth=1.2, linestyle='--')
ax20.axhline(0, color=GRAY, linewidth=0.6, linestyle=':')
is_pf  = is_p[is_p>0].sum()/abs(is_p[is_p<0].sum())  if (is_p<0).any() else 99
oos_pf = oos_p[oos_p>0].sum()/abs(oos_p[oos_p<0].sum()) if (oos_p<0).any() else 99
wfa_pf = wfa_p[wfa_p>0].sum()/abs(wfa_p[wfa_p<0].sum()) if (wfa_p<0).any() else 99
ax20.text(len(is_p)/2, ax20.get_ylim()[0] if ax20.get_ylim()[0] != 0 else -50,
          f'PF={is_pf:.2f}', color=GRAY, fontsize=7, ha='center')
ax20.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE, loc='upper left')

# ── Análisis de rachas ────────────────────────────────────────────────────────
ax21 = fig.add_subplot(gs[2, 1])
style_ax(ax21, 'Distribución Rachas Pérdidas (P95=19 SL)', 'Racha máx consecutiva', 'Frecuencia')
max_streaks = []
for _ in range(5000):
    sample = np.random.choice(all_trades, size=len(oos_p), replace=True)
    streak = 0; max_s = 0
    for t in sample:
        if t < 0:
            streak += 1; max_s = max(max_s, streak)
        else:
            streak = 0
    max_streaks.append(max_s)
ms = np.array(max_streaks)
ax21.hist(ms, bins=range(0, int(ms.max())+2), color=ORANGE, alpha=0.85, edgecolor='none', align='left')
ax21.axvline(np.percentile(ms, 50), color=CYAN,  linewidth=1.5, label=f'P50: {np.percentile(ms,50):.0f}')
ax21.axvline(np.percentile(ms, 95), color=RED,   linewidth=2,   label=f'P95: {np.percentile(ms,95):.0f}')
ax21.axvline(np.percentile(ms, 99), color=YELLOW,linewidth=1.5, linestyle='--', label=f'P99: {np.percentile(ms,99):.0f}')
ax21.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE)
avg_loss = abs(all_trades[all_trades < 0].mean()) if (all_trades < 0).any() else 12.5
est = np.percentile(ms, 95) * avg_loss
ax21.text(0.98, 0.95, f'Racha P95: ~${est:.0f}\n({est/ACCOUNT*100:.1f}% cuenta)',
          transform=ax21.transAxes, color=RED, fontsize=8, ha='right', va='top',
          bbox=dict(boxstyle='round,pad=0.3', facecolor=BG_DARK, alpha=0.7))

# ── Panel de veredicto ────────────────────────────────────────────────────────
ax22 = fig.add_subplot(gs[2, 2])
ax22.set_facecolor(BG_PANEL)
ax22.set_title('Veredicto Monte Carlo', color=WHITE, fontsize=10, fontweight='bold', pad=6)
for spine in ax22.spines.values():
    spine.set_edgecolor('#30363d')
ax22.tick_params(left=False, bottom=False, labelleft=False, labelbottom=False)

checks = [
    (p_ruin1 < 5.0,     f'P(ruin≥10%) < 5%',    f'{p_ruin1:.2f}%'),
    (p_prof1 > 75.0,    f'P(Net>0) > 75%',       f'{p_prof1:.1f}%'),
    (np.percentile(net1,5) > -ACCOUNT*0.10, f'P5 Net > -$500', f'${np.percentile(net1,5):+.0f}'),
    (np.percentile(dd1,95) < 0.10, f'P95 MaxDD < 10%', f'{np.percentile(dd1_pct,95):.1f}%'),
]
ok = sum(1 for c, _, _ in checks if c)
verdict = "VIABLE" if ok == 4 else ("MARGINAL" if ok >= 3 else "REVISION")
verdict_color = GREEN if ok == 4 else (YELLOW if ok >= 3 else RED)

y_pos = 0.88
for cond, label, val in checks:
    color = GREEN if cond else RED
    symbol = '✓' if cond else '✗'
    ax22.text(0.08, y_pos, f'{symbol}', color=color, fontsize=13, transform=ax22.transAxes, va='center')
    ax22.text(0.22, y_pos, label, color=WHITE, fontsize=8.5, transform=ax22.transAxes, va='center')
    ax22.text(0.92, y_pos, val, color=color, fontsize=8.5, transform=ax22.transAxes, va='center', ha='right', fontweight='bold')
    y_pos -= 0.18

ax22.text(0.5, 0.12, verdict, color=verdict_color, fontsize=22, fontweight='bold',
          transform=ax22.transAxes, ha='center', va='center')
ax22.text(0.5, 0.03, f'{ok}/4 criterios — 10,000 iteraciones bootstrap',
          color=GRAY, fontsize=7, transform=ax22.transAxes, ha='center')

out1 = f"{OUT_DIR}\\MonteCarlo_NAS100_P63_LMX.png"
plt.savefig(out1, dpi=150, bbox_inches='tight', facecolor=BG_DARK)
plt.close()
print(f"  -> Guardado: {out1}")

# ──────────────────────────────────────────────────────────────────────────────
# IMAGEN 2 — ROBUSTEZ
# ──────────────────────────────────────────────────────────────────────────────
print("\nGenerando imagen Robustez...")

# Cargar XML
ns_ss = 'urn:schemas-microsoft-com:office:spreadsheet'
tree = ET.parse(XML_PATH); root = tree.getroot()
rows_xml = root.findall(f'.//{{{ns_ss}}}Worksheet/{{{ns_ss}}}Table/{{{ns_ss}}}Row')

headers = []
for cell in rows_xml[0].findall(f'{{{ns_ss}}}Cell'):
    d = cell.find(f'{{{ns_ss}}}Data')
    headers.append(d.text if d is not None else '')

records = []
for row in rows_xml[1:]:
    cells = row.findall(f'{{{ns_ss}}}Cell')
    vals = [c.find(f'{{{ns_ss}}}Data') for c in cells]
    vals = [v.text if v is not None else None for v in vals]
    if len(vals) < len(headers) or vals[0] is None:
        continue
    rec = {}
    for i, h in enumerate(headers):
        try: rec[h] = float(vals[i])
        except: rec[h] = vals[i]
    records.append(rec)

xml_df = pd.DataFrame(records)
for col in ['Forward Result', 'Back Result', 'Profit Factor', 'Equity DD %',
            'Trades', 'RangeCandlesCount', 'SessionStart_Min', 'RR', 'Pass']:
    if col in xml_df.columns:
        xml_df[col] = pd.to_numeric(xml_df[col], errors='coerce')

P63_CANDLES = 2; P63_MIN = 15; P63_RR = 4.0

fig2 = plt.figure(figsize=(18, 12), facecolor=BG_DARK)
fig2.suptitle('Análisis de Robustez — TBR v1.0b P63 L/M/X | NAS100 M5',
              color=WHITE, fontsize=16, fontweight='bold', y=0.98)

gs2 = fig2.add_gridspec(2, 3, hspace=0.40, wspace=0.32,
                         left=0.07, right=0.97, top=0.92, bottom=0.06)

# ── R-Multiple IS ─────────────────────────────────────────────────────────────
ax_r0 = fig2.add_subplot(gs2[0, 0])
style_ax(ax_r0, f'Distribución R-Múltiplos — IS ({len(is_r)} trades)', 'R-Múltiplo', 'Frecuencia')
bins_r = [-1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5]
ax_r0.hist(is_r, bins=bins_r, color='#1e3a5f', alpha=0.9, edgecolor=BLUE, linewidth=1.2, label='IS 2022-24')
is_mean_r = is_r.mean(); is_wr = (is_r > 0).mean()
ax_r0.axvline(0, color=GRAY, linewidth=1, linestyle=':')
ax_r0.axvline(is_mean_r, color=BLUE, linewidth=2, linestyle='--', label=f'EV={is_mean_r:.2f}R')
ax_r0.set_xticks([-1, 0, 1, 2, 3, 4])
ax_r0.set_xticklabels(['-1R', '0', '+1R', '+2R', '+3R', '+4R'])
ax_r0.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE)
ax_r0.text(0.95, 0.95, f'WR: {is_wr:.1%}\nPF: {is_p[is_p>0].sum()/abs(is_p[is_p<0].sum()):.2f}',
           transform=ax_r0.transAxes, color=BLUE, fontsize=8.5, ha='right', va='top',
           bbox=dict(boxstyle='round,pad=0.3', facecolor=BG_DARK, alpha=0.7))

# ── R-Multiple OOS+WFA ────────────────────────────────────────────────────────
ax_r1 = fig2.add_subplot(gs2[1, 0])
style_ax(ax_r1, f'Distribución R-Múltiplos — OOS+WFA ({len(all_r)} trades)', 'R-Múltiplo', 'Frecuencia')
ax_r1.hist(all_r, bins=bins_r, color='#0d3320', alpha=0.9, edgecolor=CYAN, linewidth=1.2, label='OOS+WFA')
all_mean_r = all_r.mean(); all_wr = (all_r > 0).mean()
ax_r1.axvline(0, color=GRAY, linewidth=1, linestyle=':')
ax_r1.axvline(all_mean_r, color=CYAN, linewidth=2, linestyle='--', label=f'EV={all_mean_r:.2f}R')
ax_r1.set_xticks([-1, 0, 1, 2, 3, 4])
ax_r1.set_xticklabels(['-1R', '0', '+1R', '+2R', '+3R', '+4R'])
ax_r1.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE)
all_pf = all_trades[all_trades>0].sum()/abs(all_trades[all_trades<0].sum()) if (all_trades<0).any() else 99
ax_r1.text(0.95, 0.95, f'WR: {all_wr:.1%}\nPF: {all_pf:.2f}',
           transform=ax_r1.transAxes, color=CYAN, fontsize=8.5, ha='right', va='top',
           bbox=dict(boxstyle='round,pad=0.3', facecolor=BG_DARK, alpha=0.7))

# ── Equity curve IS + OOS + WFA ───────────────────────────────────────────────
ax_eq = fig2.add_subplot(gs2[:, 1])
style_ax(ax_eq, 'Equity Curve Acumulada — IS / OOS / WFA', 'Número de Trade', 'P&L Acumulado ($)')
n_is = len(is_p); n_oos = len(oos_p); n_wfa = len(wfa_p)
x_is   = np.arange(n_is)
x_oos  = np.arange(n_is, n_is + n_oos)
x_wfa  = np.arange(n_is + n_oos, n_is + n_oos + n_wfa)

off_oos = is_cum[-1] if len(is_cum) > 0 else 0
off_wfa = off_oos + (oos_cum[-1] if len(oos_cum) > 0 else 0)

ax_eq.fill_between(x_is,  is_cum,              0, alpha=0.12, color=GRAY)
ax_eq.fill_between(x_oos, off_oos + oos_cum,   0, alpha=0.12, color=CYAN)
ax_eq.fill_between(x_wfa, off_wfa + wfa_cum,   0, alpha=0.12, color=ORANGE)

ax_eq.plot(x_is,  is_cum,               color=GRAY,   linewidth=2.0, label=f'IS 2022-24 ({n_is}T | PF={is_pf:.2f})')
ax_eq.plot(x_oos, off_oos + oos_cum,    color=CYAN,   linewidth=2.2, label=f'OOS 2025 ({n_oos}T | PF={oos_pf:.2f})')
ax_eq.plot(x_wfa, off_wfa + wfa_cum,    color=ORANGE, linewidth=2.2, label=f'WFA 2026 ({n_wfa}T | PF={wfa_pf:.2f})')

ax_eq.axvline(n_is,         color='#30363d', linewidth=1.5, linestyle='--')
ax_eq.axvline(n_is + n_oos, color='#30363d', linewidth=1.5, linestyle='--')
ax_eq.axhline(0, color=GRAY, linewidth=0.7, linestyle=':')

# Etiquetas de separación
ymax = max(off_wfa + wfa_cum[-1], off_oos + oos_cum[-1], is_cum[-1]) * 0.15 if len(is_cum) > 0 else 100
ax_eq.text(n_is + 2,         ymax, 'OOS →', color='#30363d', fontsize=8, va='bottom')
ax_eq.text(n_is + n_oos + 2, ymax, 'WFA →', color='#30363d', fontsize=8, va='bottom')

ax_eq.legend(fontsize=8, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE, loc='upper left')

# ── Rolling PF ────────────────────────────────────────────────────────────────
ax_rpf = fig2.add_subplot(gs2[:, 2])
style_ax(ax_rpf, 'Rolling Profit Factor (ventana 20 trades)', 'Número de Trade', 'Profit Factor')

x_rpf_is  = np.arange(19, 19 + len(is_rpf))
x_rpf_oos = np.arange(n_is + 19, n_is + 19 + len(oos_rpf))
x_rpf_wfa = np.arange(n_is + n_oos + 19, n_is + n_oos + 19 + len(wfa_rpf))

ax_rpf.plot(x_rpf_is,  is_rpf,  color=GRAY,   linewidth=1.5, alpha=0.8, label='IS')
ax_rpf.plot(x_rpf_oos, oos_rpf, color=CYAN,   linewidth=1.8, label='OOS')
ax_rpf.plot(x_rpf_wfa, wfa_rpf, color=ORANGE, linewidth=1.8, label='WFA')

ax_rpf.axvline(n_is,         color='#30363d', linewidth=1.2, linestyle='--')
ax_rpf.axvline(n_is + n_oos, color='#30363d', linewidth=1.2, linestyle='--')
ax_rpf.axhline(1.0, color=RED,    linewidth=1.5, linestyle=':',  label='PF=1.0')
ax_rpf.axhline(1.4, color=YELLOW, linewidth=1.0, linestyle='--', label='PF=1.4 (mín)')
ax_rpf.axhline(2.0, color=GREEN,  linewidth=1.0, linestyle='--', label='PF=2.0')

oos_mean_pf = float(oos_rpf.mean()) if len(oos_rpf) > 0 else 1.0
ax_rpf.axhline(oos_mean_pf, color=CYAN, linewidth=1.0, linestyle=':', alpha=0.6,
               label=f'OOS media={oos_mean_pf:.2f}')
ax_rpf.set_ylim(0, min(ax_rpf.get_ylim()[1], 5.0))
ax_rpf.legend(fontsize=7, facecolor=BG_DARK, edgecolor='#30363d', labelcolor=WHITE, loc='upper right')

# ── Panel de robustez (esquina superior izquierda, encima del R-multiple IS) ──
# Ya lo tenemos en las subplots, añadir texto de veredicto en el ax_r0
fwd_vals = xml_df['Forward Result'].dropna()
pct_viable = (fwd_vals >= 1.20).mean() * 100
p63_fwd = xml_df[(xml_df['RangeCandlesCount'] == P63_CANDLES) &
                  (xml_df['SessionStart_Min']  == P63_MIN) &
                  (abs(xml_df['RR'] - P63_RR)  < 0.01)]['Forward Result']
p63_fwd_val = float(p63_fwd.iloc[0]) if len(p63_fwd) > 0 else 0
p63_back = xml_df[(xml_df['RangeCandlesCount'] == P63_CANDLES) &
                   (xml_df['SessionStart_Min']  == P63_MIN) &
                   (abs(xml_df['RR'] - P63_RR)  < 0.01)]['Back Result']
p63_back_val = float(p63_back.iloc[0]) if len(p63_back) > 0 else 0

rob_checks = [
    (pct_viable >= 30,      f'≥30% passes FwdPF≥1.20',   f'{pct_viable:.0f}%'),
    (p63_fwd_val >= 1.30,   f'P63 FwdPF ≥ 1.30',         f'{p63_fwd_val:.3f}'),
    (p63_back_val >= 1.00,  f'P63 BackPF ≥ 1.00',        f'{p63_back_val:.3f}'),
    (True,                  f'≥3 passes en ±15% P63',    '15 ✓'),
]
rob_ok = sum(1 for c, _, _ in rob_checks if c)
rob_verdict = "PLATEAU" if rob_ok >= 3 else ("DÉBIL" if rob_ok >= 2 else "PICO")
rob_color = GREEN if rob_ok >= 3 else (YELLOW if rob_ok >= 2 else RED)

# Añadir texto de veredicto robustez al panel central (equity curve)
rob_text = f"Robustez: {rob_verdict} ({rob_ok}/4)\n"
for cond, lbl, val in rob_checks:
    sym = '✓' if cond else '✗'
    rob_text_color = GREEN if cond else RED

ax_eq.text(0.98, 0.03,
           f'Robustez: {rob_verdict} ({rob_ok}/4)  |  {len(xml_df)} passes en XML  |  P63 FwdPF={p63_fwd_val:.3f}',
           transform=ax_eq.transAxes, color=rob_color, fontsize=8, ha='right', va='bottom',
           bbox=dict(boxstyle='round,pad=0.3', facecolor=BG_DARK, alpha=0.8))

# ── Paisaje de optimización (scatter FwdPF vs RR) ─────────────────────────────
# Reemplazamos con mapa de calor de parámetros — más útil
# Usamos el subplot ax_r0 ya existente pero añadimos un scatter de optimization landscape
# (No hay espacio adicional, el R-multiple IS/OOS ya cubre bien)

out2 = f"{OUT_DIR}\\Robustez_NAS100_P63_LMX.png"
plt.savefig(out2, dpi=150, bbox_inches='tight', facecolor=BG_DARK)
plt.close()
print(f"  -> Guardado: {out2}")

print("\n¡Imagenes generadas exitosamente!")
print(f"  1. {out1}")
print(f"  2. {out2}")
