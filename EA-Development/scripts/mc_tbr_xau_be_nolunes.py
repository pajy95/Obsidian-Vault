# -*- coding: utf-8 -*-
"""
Monte Carlo -- TBR XAUUSD P2 BE sin Lunes
Analiza distribucion de riesgo sobre OOS+WFA combinados.
N=5000 iteraciones. Equity inicial: $5000.
"""

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd
import numpy as np
from pathlib import Path

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD")
EQUITY_INIT = 5000
N_SIM = 5000
np.random.seed(42)

# -----------------------------------------------------------------------
def parse_deals(path):
    df = pd.read_excel(path, header=None)
    mask_in  = df[4].astype(str).str.strip().str.lower() == 'in'
    mask_out = df[4].astype(str).str.strip().str.lower() == 'out'
    entries = df[mask_in].copy().reset_index(drop=True)
    exits   = df[mask_out].copy().reset_index(drop=True)
    n = min(len(entries), len(exits))
    entries = entries.iloc[:n]
    exits   = exits.iloc[:n]
    dt_in = pd.to_datetime(entries[0].values, errors='coerce')
    pnls  = pd.to_numeric(exits[10], errors='coerce').values
    trades = pd.DataFrame({'dt_in': dt_in, 'pnl': pnls})
    return trades.dropna(subset=['pnl'])

oos = parse_deals(BASE / "OOS_TBR_XAU_P2_2025_be_NOL.xlsx")
wfa = parse_deals(BASE / "WFA_TBR_XAU_be_noL_2026.xlsx")

# Combinar OOS + WFA como base historica
combined = pd.concat([oos, wfa], ignore_index=True)
pnl_arr = combined['pnl'].values
n_trades = len(pnl_arr)

print("=" * 65)
print("  MONTE CARLO -- TBR XAUUSD P2 BE SIN LUNES")
print("=" * 65)
print(f"\nBase: OOS 2025 (n={len(oos)}) + WFA 2026 (n={len(wfa)}) = {n_trades} trades")
print(f"Iteraciones: {N_SIM:,} | Equity inicial: ${EQUITY_INIT:,}")

# Estadisticas del conjunto de trades
wins   = pnl_arr[pnl_arr > 0]
losses = pnl_arr[pnl_arr < 0]
print(f"\n-- Estadisticas del trade set --")
print(f"  WR:       {len(wins)/n_trades:.1%}")
print(f"  Avg Win:  ${wins.mean():.2f}")
print(f"  Avg Loss: ${losses.mean():.2f}")
print(f"  RR real:  {wins.mean()/abs(losses.mean()):.2f}")
print(f"  PF:       {wins.sum()/abs(losses.sum()):.3f}")
print(f"  Net real: ${pnl_arr.sum():+.2f}")

# -----------------------------------------------------------------------
# Monte Carlo: resampling con reemplazo
final_equities = []
max_dds        = []
max_dd_pcts    = []
ruin_count     = 0
neg_count      = 0

for _ in range(N_SIM):
    shuffled = np.random.choice(pnl_arr, size=n_trades, replace=True)
    cum      = EQUITY_INIT + np.cumsum(shuffled)
    eq_curve = np.concatenate([[EQUITY_INIT], cum])

    # Drawdown absoluto maximo
    running_max = np.maximum.accumulate(eq_curve)
    dd_abs = (eq_curve - running_max)
    max_dd_abs = dd_abs.min()

    # Drawdown porcentual maximo
    dd_pct = (eq_curve - running_max) / running_max * 100
    max_dd_pct = dd_pct.min()

    final_eq = eq_curve[-1]
    final_equities.append(final_eq)
    max_dds.append(abs(max_dd_abs))
    max_dd_pcts.append(abs(max_dd_pct))

    if final_eq < EQUITY_INIT * 0.70:
        ruin_count += 1
    if final_eq < EQUITY_INIT:
        neg_count += 1

final_equities = np.array(final_equities)
max_dds        = np.array(max_dds)
max_dd_pcts    = np.array(max_dd_pcts)

# -----------------------------------------------------------------------
print("\n" + "=" * 65)
print("  RESULTADOS MONTE CARLO")
print("=" * 65)

print(f"\n-- Equity final (sobre ${EQUITY_INIT:,}) --")
print(f"  Percentil  5%:  ${np.percentile(final_equities, 5):>8,.0f}  ({(np.percentile(final_equities,5)/EQUITY_INIT-1)*100:>+.1f}%)")
print(f"  Percentil 25%:  ${np.percentile(final_equities,25):>8,.0f}  ({(np.percentile(final_equities,25)/EQUITY_INIT-1)*100:>+.1f}%)")
print(f"  Mediana    50%: ${np.percentile(final_equities,50):>8,.0f}  ({(np.percentile(final_equities,50)/EQUITY_INIT-1)*100:>+.1f}%)")
print(f"  Percentil 75%:  ${np.percentile(final_equities,75):>8,.0f}  ({(np.percentile(final_equities,75)/EQUITY_INIT-1)*100:>+.1f}%)")
print(f"  Percentil 95%:  ${np.percentile(final_equities,95):>8,.0f}  ({(np.percentile(final_equities,95)/EQUITY_INIT-1)*100:>+.1f}%)")
print(f"  Media:          ${final_equities.mean():>8,.0f}  ({(final_equities.mean()/EQUITY_INIT-1)*100:>+.1f}%)")

print(f"\n-- Max Drawdown absoluto --")
print(f"  Peor caso (p95):  ${np.percentile(max_dds, 95):>7,.0f}  ({np.percentile(max_dd_pcts,95):>5.1f}%)")
print(f"  Mediana   (p50):  ${np.percentile(max_dds, 50):>7,.0f}  ({np.percentile(max_dd_pcts,50):>5.1f}%)")
print(f"  Mejor caso (p5):  ${np.percentile(max_dds,  5):>7,.0f}  ({np.percentile(max_dd_pcts, 5):>5.1f}%)")

print(f"\n-- Riesgo de ruina --")
print(f"  P(equity < $5000, perdida neta):  {neg_count/N_SIM:.1%}  ({neg_count:,} / {N_SIM:,} sims)")
print(f"  P(DD > 30%, ruina prop firm):     {ruin_count/N_SIM:.1%}  ({ruin_count:,} / {N_SIM:,} sims)")

# Umbral prop firm: DD > 10%
dd10_count = (max_dd_pcts > 10).sum()
print(f"  P(DD > 10%, limite prop firm):    {dd10_count/N_SIM:.1%}  ({dd10_count:,} / {N_SIM:,} sims)")

# -----------------------------------------------------------------------
# Analisis adicional: consecutivas perdedoras esperadas
print(f"\n-- Rachas perdedoras esperadas --")
loss_rate = len(losses) / n_trades
expected_max_consec = np.log(N_SIM) / np.log(1 / loss_rate)
print(f"  Loss rate:              {loss_rate:.1%}")
print(f"  Racha perdedora media:  {1/(1-loss_rate + 0.0001):.1f} trades")
print(f"  Racha esperada en {N_SIM:,} sims: ~{expected_max_consec:.0f} perdidas consecutivas")

# MC de rachas perdedoras
max_consec_losses = []
for _ in range(1000):
    shuffled = np.random.choice(pnl_arr, size=n_trades, replace=True)
    max_streak = 0
    streak = 0
    for p in shuffled:
        if p < 0:
            streak += 1
            max_streak = max(max_streak, streak)
        else:
            streak = 0
    max_consec_losses.append(max_streak)

mcl = np.array(max_consec_losses)
print(f"  Racha perdedora p50:    {np.percentile(mcl,50):.0f} consecutivas")
print(f"  Racha perdedora p95:    {np.percentile(mcl,95):.0f} consecutivas")
print(f"  Racha perdedora p99:    {np.percentile(mcl,99):.0f} consecutivas")

# -----------------------------------------------------------------------
# Veredicto Monte Carlo
print("\n" + "=" * 65)
print("  VEREDICTO MONTE CARLO")
print("=" * 65)

dd_p95 = np.percentile(max_dd_pcts, 95)
eq_p5  = (np.percentile(final_equities, 5) / EQUITY_INIT - 1) * 100
dd10_prob = dd10_count / N_SIM * 100

ok_dd   = dd_p95 <= 15
ok_eq   = eq_p5  >= -10
ok_prop = dd10_prob <= 20

verdict = "VIABLE [MC OK]" if (ok_dd and ok_eq and ok_prop) else "MARGINAL [MC ~]"

print(f"\n  DD p95 <= 15%:       {dd_p95:.1f}%  -> {'PASS' if ok_dd else 'FAIL'}")
print(f"  Equity p5 >= -10%:   {eq_p5:.1f}%  -> {'PASS' if ok_eq else 'FAIL'}")
print(f"  P(DD>10%) <= 20%:    {dd10_prob:.1f}%  -> {'PASS' if ok_prop else 'FAIL'}")
print(f"\n  Veredicto: {verdict}")
print(f"\n  Escenario pesimista (p5): equity ${np.percentile(final_equities,5):,.0f} | DD {np.percentile(max_dd_pcts,95):.1f}%")
print(f"  Escenario base    (p50): equity ${np.percentile(final_equities,50):,.0f} | DD {np.percentile(max_dd_pcts,50):.1f}%")
