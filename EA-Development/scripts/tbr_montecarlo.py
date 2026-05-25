"""
Monte Carlo — TBR v1.0b P63 L/M/X NAS100
Fuente: OOS 2025 (145 trades) + WFA 2026 (52 trades)
10,000 iteraciones con bootstrap (resampleo con reemplazo)
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

np.random.seed(42)
N_SIM    = 10_000
VPP      = 20.0
RR       = 4.0
ACCOUNT  = 5_000.0
MAX_DD_LIMIT = 0.10  # 10% prop firm

BASE = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100"

# ── Parser ────────────────────────────────────────────────────────────────
def parse(path, rr=4.0):
    df = pd.read_excel(path, header=None)
    rows = df[df[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]
    buys = rows[(rows[3].astype(str).str.strip().str.lower() == 'buy stop') &
                (rows[11].astype(str).str.strip().str.lower() == 'filled')]
    sells = rows[(rows[3].astype(str).str.strip().str.lower() == 'sell') &
                 (rows[6].astype(str) != '0')]
    entries, exits = [], []
    for _, r in buys.iterrows():
        try:
            p=float(r[6]); sl=float(r[7]); tp=float(r[8])
        except: continue
        if p>0 and sl>0 and tp>0 and p>sl:
            vol=0.01
            try: vol=float(str(r[4]).split('/')[0].strip())
            except: pass
            entries.append({'sl_dist': p-sl, 'vol': vol})
    for _, r in sells.iterrows():
        c = str(r[12]).strip().lower()
        et = 'TP' if 'tp' in c else ('SL' if 'sl' in c else 'Timeout')
        exits.append({'exit_type': et, 'close': float(r[6])})
    n = min(len(entries), len(exits))
    profits = []
    for i in range(n):
        e=entries[i]; x=exits[i]
        if x['exit_type']=='TP': p=e['vol']*e['sl_dist']*VPP*rr
        elif x['exit_type']=='SL': p=-e['vol']*e['sl_dist']*VPP
        else: p=0.0
        profits.append(p)
    return np.array(profits)

oos  = parse(f"{BASE}\\OOS tbr nas100 v1b pass63 no JV.xlsx")
wfa  = parse(f"{BASE}\\WFA TBR NAS100 2026.xlsx")
all_trades = np.concatenate([oos, wfa])

print("=" * 65)
print("MONTE CARLO — TBR v1.0b P63 L/M/X NAS100")
print(f"N simulaciones: {N_SIM:,}  |  Bootstrap con reemplazo")
print("=" * 65)

print(f"\nPool de trades: OOS 2025 ({len(oos)}) + WFA 2026 ({len(wfa)}) = {len(all_trades)} trades")
print(f"  EV por trade:  ${all_trades.mean():+.2f}")
print(f"  Std por trade: ${all_trades.std():.2f}")
print(f"  WR real:       {(all_trades > 0).mean()*100:.1f}%")

# ── Funcion de simulacion ─────────────────────────────────────────────────
def simulate(trades, n_trades, n_sim, account, max_dd_pct):
    net_results = np.zeros(n_sim)
    max_dd_abs  = np.zeros(n_sim)
    ruined      = np.zeros(n_sim, dtype=bool)

    for i in range(n_sim):
        sample = np.random.choice(trades, size=n_trades, replace=True)
        cum    = np.cumsum(sample)
        peak   = np.maximum.accumulate(cum)
        dd     = (peak - cum)  # drawdown absoluto desde peak
        max_dd_abs[i]  = dd.max()
        net_results[i] = cum[-1]
        ruined[i]      = (dd.max() / account) >= max_dd_pct

    return net_results, max_dd_abs, ruined

# ── Escenario 1: OOS completo (145 trades ~ 1 ano) ───────────────────────
print("\n" + "-"*65)
print(f"ESCENARIO 1 — Periodo tipo OOS (n={len(oos)} trades, ~1 ano)")
print("-"*65)
net1, dd1, ruin1 = simulate(all_trades, len(oos), N_SIM, ACCOUNT, MAX_DD_LIMIT)
p5_net = np.percentile(net1, 5);  p50_net = np.percentile(net1, 50)
p95_net = np.percentile(net1, 95)
p5_dd  = np.percentile(dd1, 5);   p50_dd  = np.percentile(dd1, 50)
p95_dd = np.percentile(dd1, 95)
p_ruin = ruin1.mean() * 100
p_prof = (net1 > 0).mean() * 100

print(f"\n  Net Profit (percentiles):")
print(f"    P5  (pesimista): ${p5_net:>+8.0f}")
print(f"    P50 (mediana):   ${p50_net:>+8.0f}")
print(f"    P95 (optimista): ${p95_net:>+8.0f}")
print(f"\n  Max Drawdown (percentiles):")
print(f"    P5:  ${p5_dd:>6.0f}  ({p5_dd/ACCOUNT*100:.1f}%)")
print(f"    P50: ${p50_dd:>6.0f}  ({p50_dd/ACCOUNT*100:.1f}%)")
print(f"    P95: ${p95_dd:>6.0f}  ({p95_dd/ACCOUNT*100:.1f}%)")
print(f"\n  P(Net > 0):        {p_prof:.1f}%")
print(f"  P(DD >= 10%/ruin): {p_ruin:.2f}%")
flag = 'OK' if p_ruin < 5 else ('~' if p_ruin < 15 else 'XX')
print(f"  [{flag}] Riesgo de ruin: {'BAJO' if p_ruin<5 else ('MODERADO' if p_ruin<15 else 'ALTO')}")

# ── Escenario 2: WFA corto (52 trades ~ 4 meses) ─────────────────────────
print("\n" + "-"*65)
print(f"ESCENARIO 2 — Periodo tipo WFA (n={len(wfa)} trades, ~4 meses)")
print("-"*65)
net2, dd2, ruin2 = simulate(all_trades, len(wfa), N_SIM, ACCOUNT, MAX_DD_LIMIT)
p5_net2=np.percentile(net2,5); p50_net2=np.percentile(net2,50); p95_net2=np.percentile(net2,95)
p5_dd2=np.percentile(dd2,5);   p50_dd2=np.percentile(dd2,50);   p95_dd2=np.percentile(dd2,95)
p_ruin2=ruin2.mean()*100; p_prof2=(net2>0).mean()*100

print(f"\n  Net Profit (percentiles):")
print(f"    P5  (pesimista): ${p5_net2:>+8.0f}")
print(f"    P50 (mediana):   ${p50_net2:>+8.0f}")
print(f"    P95 (optimista): ${p95_net2:>+8.0f}")
print(f"\n  Max Drawdown (percentiles):")
print(f"    P5:  ${p5_dd2:>6.0f}  ({p5_dd2/ACCOUNT*100:.1f}%)")
print(f"    P50: ${p50_dd2:>6.0f}  ({p50_dd2/ACCOUNT*100:.1f}%)")
print(f"    P95: ${p95_dd2:>6.0f}  ({p95_dd2/ACCOUNT*100:.1f}%)")
print(f"\n  P(Net > 0):        {p_prof2:.1f}%")
print(f"  P(DD >= 10%/ruin): {p_ruin2:.2f}%")
flag2 = 'OK' if p_ruin2 < 5 else ('~' if p_ruin2 < 15 else 'XX')
print(f"  [{flag2}] Riesgo de ruin: {'BAJO' if p_ruin2<5 else ('MODERADO' if p_ruin2<15 else 'ALTO')}")

# ── Racha de perdidas ─────────────────────────────────────────────────────
print("\n" + "-"*65)
print("ANALISIS DE RACHAS")
print("-"*65)
# Simular rachas maximas de perdidas consecutivas
max_streaks = []
for _ in range(N_SIM):
    sample = np.random.choice(all_trades, size=len(oos), replace=True)
    streak = 0; max_s = 0
    for t in sample:
        if t < 0: streak += 1; max_s = max(max_s, streak)
        else: streak = 0
    max_streaks.append(max_s)
ms = np.array(max_streaks)
print(f"\n  Racha max perdidas consecutivas:")
print(f"    P50 (tipico):   {np.percentile(ms,50):.0f} trades")
print(f"    P95 (extremo):  {np.percentile(ms,95):.0f} trades")
print(f"    P99 (peor caso):{np.percentile(ms,99):.0f} trades")
print(f"\n  Con RiskAmountUSD=12.5 y racha P95={np.percentile(ms,95):.0f}:")
avg_loss = abs(all_trades[all_trades<0].mean()) if (all_trades<0).any() else 12.5
est_racha_loss = np.percentile(ms,95) * avg_loss
print(f"  Perdida estimada en racha P95: ${est_racha_loss:.0f} ({est_racha_loss/ACCOUNT*100:.1f}% cuenta)")

# ── Veredicto ─────────────────────────────────────────────────────────────
print("\n" + "="*65)
print("VEREDICTO MONTE CARLO")
print("="*65)
checks = [
    (p_ruin < 5.0,  f"P(ruin DD>=10%) < 5%",    f"{p_ruin:.2f}%"),
    (p_prof > 75.0, f"P(Net>0) > 75%",           f"{p_prof:.1f}%"),
    (p5_net > -ACCOUNT*0.10, f"P5 Net > -10% cuenta", f"${p5_net:+.0f}"),
    (p95_dd/ACCOUNT < 0.10,  f"P95 MaxDD < 10%",  f"{p95_dd/ACCOUNT*100:.1f}%"),
]
ok = sum(1 for c,_,_ in checks if c)
for cond, lbl, val in checks:
    print(f"  [{'OK' if cond else 'XX'}] {lbl:<35} {val:>10}")
verdict = "VIABLE" if ok==4 else ("MARGINAL" if ok>=3 else "REVISION")
print(f"\n  VEREDICTO: {verdict} ({ok}/4)")
