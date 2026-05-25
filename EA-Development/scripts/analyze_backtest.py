import pandas as pd
import numpy as np
import sys

path = r"c:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Backtests\NAS100\Backtest NAS100 01_01_2025 - 28_04_2026.csv"

df = pd.read_csv(path, encoding="utf-8")

# Solo trades ejecutados
trades = df[df["ExitType"].notna() & ~df["ExitType"].str.startswith("filtered")].copy()
trades["OpenTime"] = pd.to_datetime(trades["OpenTime"])
trades["CloseTime"] = pd.to_datetime(trades["CloseTime"])
# Tickets parciales tienen OpenTime=1970 — usar CloseTime como referencia
bad_mask = trades["OpenTime"].dt.year < 2000
trades.loc[bad_mask, "OpenTime"] = trades.loc[bad_mask, "CloseTime"]
trades = trades.dropna(subset=["PnL_USD"])
pnl = trades["PnL_USD"]

print(f"Total trades ejecutados: {len(trades)}")
print(f"Periodo: {trades['OpenTime'].min().date()} a {trades['OpenTime'].max().date()}")

# --- Métricas base ---
wins = pnl[pnl > 0]
losses = pnl[pnl < 0]
wr = len(wins) / len(pnl) * 100
pf = wins.sum() / abs(losses.sum()) if losses.sum() != 0 else float("inf")
avg_risk = trades["RiskReal_USD"].mean()
expectancy_r = pnl.mean() / avg_risk if avg_risk > 0 else 0
max_consec = cur = 0
for v in pnl:
    cur = cur + 1 if v < 0 else 0
    max_consec = max(max_consec, cur)

equity = pnl.cumsum()
peak = equity.cummax()
dd_series = (equity - peak) / (peak.abs() + 1e-9) * 100
max_dd = dd_series.min()

daily = trades.groupby(trades["OpenTime"].dt.date)["PnL_USD"].sum()
sharpe = (daily.mean() / daily.std() * np.sqrt(252)) if daily.std() > 0 else 0

months = (trades["OpenTime"].max() - trades["OpenTime"].min()).days / 30.44
freq_month = len(trades) / months if months > 0 else 0

print("\n--- MÉTRICAS ---")
print(f"Win Rate:              {wr:.2f}%")
print(f"Profit Factor:         {pf:.3f}")
print(f"Expectancy (USD):      {pnl.mean():.2f}")
print(f"Expectancy (R):        {expectancy_r:.3f}R")
print(f"Avg Risk/trade:        {avg_risk:.2f} USD")
print(f"Sharpe anualizado:     {sharpe:.3f}")
print(f"Max DD:                {max_dd:.2f}%")
print(f"Max consec losers:     {max_consec}")
print(f"Trades/mes:            {freq_month:.1f}")
print(f"Beneficio neto:        {pnl.sum():.2f} USD")

# --- Edge Decay H1 vs H2 ---
mid = trades["OpenTime"].min() + (trades["OpenTime"].max() - trades["OpenTime"].min()) / 2
mask_h1 = trades["OpenTime"] < mid
h1 = pnl[mask_h1]
h2 = pnl[~mask_h1]
pf_h1 = h1[h1 > 0].sum() / abs(h1[h1 < 0].sum()) if h1[h1 < 0].sum() != 0 else float("inf")
pf_h2 = h2[h2 > 0].sum() / abs(h2[h2 < 0].sum()) if h2[h2 < 0].sum() != 0 else float("inf")
decay = (pf_h1 - pf_h2) / pf_h1 * 100 if pf_h1 > 0 else 0

print("\n--- EDGE DECAY ---")
print(f"PF H1 ({trades['OpenTime'].min().date()} - {mid.date()}): {pf_h1:.3f}")
print(f"PF H2 ({mid.date()} - {trades['OpenTime'].max().date()}): {pf_h2:.3f}")
print(f"Edge decay: {decay:.1f}%")

# --- Monte Carlo p95 DD ---
np.random.seed(42)
arr = pnl.values
results = []
for _ in range(1000):
    perm = np.random.permutation(arr)
    eq = np.cumsum(perm)
    pk = np.maximum.accumulate(eq)
    dd = (eq - pk) / (np.abs(pk) + 1e-9) * 100
    results.append(dd.min())

mc_p50 = np.percentile(results, 50)
mc_p95 = np.percentile(results, 95)
mc_p99 = np.percentile(results, 99)

print("\n--- MONTE CARLO (1000 permutaciones) ---")
print(f"DD p50: {mc_p50:.2f}%")
print(f"DD p95: {mc_p95:.2f}%")
print(f"DD p99: {mc_p99:.2f}%")

# --- Veredicto ---
print("\n--- VEREDICTO ---")
checks = {
    "PF >= 1.5": pf >= 1.5,
    "Expectancy R >= 0.30": expectancy_r >= 0.30,
    "Edge decay <= 25%": decay <= 25,
    "MC p95 DD <= 6%": abs(mc_p95) <= 6,
    "Max consec losers <= 6": max_consec <= 6,
    "Trades/mes 8-25": 8 <= freq_month <= 25,
}
for k, v in checks.items():
    print(f"  {'OK' if v else 'FAIL'} — {k}")

viable = all(checks.values())
print(f"\nVEREDICTO FINAL: {'VIABLE' if viable else 'MARGINAL/NO VIABLE'}")
