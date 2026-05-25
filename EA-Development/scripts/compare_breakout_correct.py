"""
Comparación BREAKOUT correcta: filtrar solo DEALS de entrada (col[4]='in').
El error anterior mezclaba rows de órdenes (buy stop/sell stop) con deals.

Estructura Orders section:  col[3]='buy stop'/'sell stop', col[4]='0.01/0.01'
Estructura Deals  section:  col[3]='buy'/'sell',           col[4]='in'/'out'
"""

import pandas as pd
import numpy as np
from pathlib import Path
from collections import Counter

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests")

FILES = {
    "NR_CONF":  BASE / "NR Backtest NAS100 M5.xlsx",
    "NR_RUPT":  BASE / "NR Backtest NAS100 M5 rupt.xlsx",
    "TBR_CONF": BASE / "tbR Backtest NAS100 M5 conf.xlsx",
    "TBR_RUPT": BASE / "tbR Backtest NAS100 M5 rupt.xlsx",
}

def load_entries_correct(path, label):
    df = pd.read_excel(path, header=None)
    # Filtrar: deals de entrada (col[4]='in') con comentario del EA
    if "NR_" in label:
        mask_comment = df[12].astype(str).str.strip() == 'NR ULTRA'
    else:
        mask_comment = df[12].astype(str).str.contains('TBR', na=False)

    mask_in = df[4].astype(str).str.strip().str.lower() == 'in'
    mask = mask_comment & mask_in
    e = df[mask].copy()

    e['_dt']       = pd.to_datetime(e[0], errors='coerce')
    e['_date']     = e['_dt'].dt.date
    e['_second']   = e['_dt'].dt.second
    e['_minute']   = e['_dt'].dt.minute
    e['_hhmm']     = e['_dt'].dt.strftime('%H:%M:%S')
    e['_dir']      = e[3].astype(str).str.lower().str.strip()
    e['_entry_px'] = pd.to_numeric(e[6], errors='coerce')
    return e

data = {}
for label, path in FILES.items():
    e = load_entries_correct(path, label)
    data[label] = e
    sec00 = (e['_second'] == 0).mean()
    m3_ok = (e['_minute'] % 3 == 0).mean()
    print(f"{label:<10} | n={len(e):4d} | sec=:00: {sec00:.0%} | min%3=0: {m3_ok:.0%} | "
          f"dirs: {e['_dir'].unique().tolist()}")

def compare_pair(la, lb):
    a = data[la].sort_values('_dt').groupby('_date').first()
    b = data[lb].sort_values('_dt').groupby('_date').first()
    common = a.index.intersection(b.index)

    print(f"\n{'='*60}")
    print(f"  {la}  vs  {lb}  ({len(common)} días comunes)")
    print(f"{'='*60}")

    if len(common) == 0:
        print("Sin días comunes.")
        return

    ac = a.loc[common]
    bc = b.loc[common]

    same_dir = (ac['_dir'].values == bc['_dir'].values)
    print(f"Dirección igual:  {same_dir.sum()} / {len(common)} = {same_dir.mean():.1%}")

    def to_sec(df):
        return df['_minute'] * 60 + df['_second']

    diff = (to_sec(bc).values - to_sec(ac).values).astype(float)
    print(f"Diff tiempo (seg): mean={np.mean(diff):.1f}  median={np.median(diff):.1f}  "
          f"min={int(np.min(diff))}  max={int(np.max(diff))}")

    # Diff en minutos
    diff_min = [int(x) // 60 for x in diff]
    cnt = Counter(diff_min)
    print(f"Distribución diff en minutos:")
    for k, v in sorted(cnt.items(), key=lambda x: -x[1])[:8]:
        print(f"  {k:+4d} min: {v:4d} ({v/len(common):.1%})")

    # Precio entry
    px_diff = bc['_entry_px'].values - ac['_entry_px'].values
    print(f"Diff precio entrada (B-A): mean={np.mean(px_diff):+.2f} median={np.median(px_diff):+.2f}")

    # Primeros 15 días
    print(f"\n{'Fecha':<12} {la:>10} dir   {lb:>10} dir   Dseg  Match  PxDiff")
    print("-" * 70)
    for day in sorted(common)[:15]:
        ar = a.loc[day]
        br = b.loc[day]
        ds = int(to_sec(b.loc[[day]]).values[0] - to_sec(a.loc[[day]]).values[0])
        m  = 'Y' if ar['_dir'] == br['_dir'] else 'N'
        pd_ = br['_entry_px'] - ar['_entry_px']
        print(f"{str(day):<12} {ar['_hhmm']:>10} {ar['_dir'][:4]:<4}  "
              f"{br['_hhmm']:>10} {br['_dir'][:4]:<4}  {ds:>+4}s  {m:^5}  {pd_:+.2f}")

compare_pair("NR_CONF",  "TBR_CONF")
compare_pair("NR_RUPT",  "TBR_RUPT")
