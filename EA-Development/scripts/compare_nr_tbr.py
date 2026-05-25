"""
Comparison: NR Entry_Mode=1 vs TBR MODE_CONFIRM
NAS100 M3 — same period, equivalent parameters.
Goal: determine if confirm-on-close behavior is identical.

Column map (both files):
  col[0]  = datetime (open time)
  col[3]  = direction: 'buy' / 'sell'
  col[12] = comment: 'NR ULTRA' (NR entries) | 'TBR BUY/SELL v1.0b' (TBR entries)
"""

import pandas as pd
import numpy as np
from pathlib import Path
from collections import Counter

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests")
NR_FILE  = BASE / "NR Backtest NAS100 M5.xlsx"
TBR_FILE = BASE / "tbR Backtest NAS100 M5.xlsx"

nr_raw  = pd.read_excel(NR_FILE,  header=None)
tbr_raw = pd.read_excel(TBR_FILE, header=None)

# ---------- extract entries ----------
nr_e  = nr_raw[nr_raw[12].astype(str).str.strip() == 'NR ULTRA'].copy()
tbr_e = tbr_raw[tbr_raw[12].astype(str).str.contains('TBR', na=False)].copy()

print(f"NR  entries: {len(nr_e)}")
print(f"TBR entries: {len(tbr_e)}")

# ---------- parse ----------
for df in [nr_e, tbr_e]:
    df['_dt']     = pd.to_datetime(df[0], errors='coerce')
    df['_date']   = df['_dt'].dt.date
    df['_hour']   = df['_dt'].dt.hour
    df['_minute'] = df['_dt'].dt.minute
    df['_second'] = df['_dt'].dt.second
    df['_hhmm']   = df['_dt'].dt.strftime('%H:%M')
    df['_dir']    = df[3].astype(str).str.lower().str.strip()

print(f"\nNR  directions:  {nr_e['_dir'].unique()}")
print(f"TBR directions:  {tbr_e['_dir'].unique()}")
print(f"\nTBR comment types:\n{tbr_e[12].value_counts()}")

# ---------- seconds / M3 open checks ----------
print(f"\n=== NR seconds distribution ===")
print(nr_e['_second'].value_counts().sort_index())
pct_nr_sec00 = (nr_e['_second'] == 0).mean()
pct_nr_m3    = (nr_e['_minute'] % 3 == 0).mean()
print(f"NR  at :00 sec:  {pct_nr_sec00:.1%}  |  at M3 open (min%3=0): {pct_nr_m3:.1%}")

print(f"\n=== TBR seconds distribution ===")
print(tbr_e['_second'].value_counts().sort_index())
pct_tbr_sec00 = (tbr_e['_second'] == 0).mean()
pct_tbr_m3    = (tbr_e['_minute'] % 3 == 0).mean()
print(f"TBR at :00 sec:  {pct_tbr_sec00:.1%}  |  at M3 open (min%3=0): {pct_tbr_m3:.1%}")

# ---------- per-day — take FIRST trade only ----------
nr_by_day  = nr_e.sort_values('_dt').groupby('_date').first()
tbr_by_day = tbr_e.sort_values('_dt').groupby('_date').first()

common  = nr_by_day.index.intersection(tbr_by_day.index)
only_nr = nr_by_day.index.difference(tbr_by_day.index)
only_tb = tbr_by_day.index.difference(nr_by_day.index)

print(f"\n=== Day coverage ===")
print(f"NR  trading days: {len(nr_by_day)}")
print(f"TBR trading days: {len(tbr_by_day)}")
print(f"Common days:      {len(common)}")
print(f"Only in NR:       {len(only_nr)}")
print(f"Only in TBR:      {len(only_tb)}")

if len(common) == 0:
    print("\nNo common days — check datetime parsing or date ranges.")
    print("NR  date range:", nr_by_day.index.min(), "→", nr_by_day.index.max())
    print("TBR date range:", tbr_by_day.index.min(), "→", tbr_by_day.index.max())
else:
    nr_c  = nr_by_day.loc[common]
    tbr_c = tbr_by_day.loc[common]

    same_dir = (nr_c['_dir'].values == tbr_c['_dir'].values)
    print(f"\nDirection match (common days): {same_dir.sum()} / {len(common)} = {same_dir.mean():.1%}")

    def to_min(df):
        return df['_hour'] * 60 + df['_minute']

    diff = (to_min(tbr_c).values - to_min(nr_c).values).astype(float)

    print(f"\nTime diff TBR - NR (minutes):")
    print(f"  Mean:   {np.mean(diff):.1f}")
    print(f"  Median: {np.median(diff):.1f}")
    print(f"  Std:    {np.std(diff):.1f}")
    print(f"  Min:    {int(np.min(diff))}")
    print(f"  Max:    {int(np.max(diff))}")

    cnt = Counter(int(x) for x in diff)
    print(f"\nDistribution of diff (minutes):")
    for k in sorted(cnt.keys()):
        bar = '#' * (cnt[k] // 5)
        print(f"  {k:+4d} min: {cnt[k]:4d}  {bar}")

    # Minutes distribution for TBR entries (on common days)
    tbr_min_vals = tbr_c['_minute'].values
    print(f"\nTBR entry minute distribution (common days, sorted):")
    cnt_min = Counter(int(m) for m in tbr_min_vals)
    for m in sorted(cnt_min.keys()):
        print(f"  :{m:02d}  {cnt_min[m]} trades")

    # First 20 days detail
    print(f"\n{'Date':<12} {'NR':^6} {'NR dir':^6} {'TBR':^6} {'TBR dir':^6} {'Diff':^5} {'Match':^5}")
    print("-" * 55)
    for day in sorted(common)[:20]:
        nr_r  = nr_by_day.loc[day]
        tbr_r = tbr_by_day.loc[day]
        d     = to_min(tbr_by_day.loc[[day]]).values[0] - to_min(nr_by_day.loc[[day]]).values[0]
        m     = 'Y' if nr_r['_dir'] == tbr_r['_dir'] else 'N'
        print(f"{str(day):<12} {nr_r['_hhmm']:^6} {nr_r['_dir'][:4]:^6} {tbr_r['_hhmm']:^6} {tbr_r['_dir'][:4]:^6} {int(d):^+5} {m:^5}")

    # Days with direction mismatch
    mismatch = [common[i] for i, ok in enumerate(same_dir) if not ok]
    print(f"\n=== Direction mismatches ({len(mismatch)} days) ===")
    for day in mismatch[:15]:
        nr_r  = nr_by_day.loc[day]
        tbr_r = tbr_by_day.loc[day]
        print(f"  {day}  NR={nr_r['_dir'][:4]} {nr_r['_hhmm']}  TBR={tbr_r['_dir'][:4]} {tbr_r['_hhmm']}")
