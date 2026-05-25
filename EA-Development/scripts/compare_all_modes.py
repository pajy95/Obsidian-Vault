"""
Comparación de modos: NR vs TBR — CONFIRM y BREAKOUT
Verifica que ambos EAs se comporten igual en cada modo.
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

def load_entries(path, label):
    df = pd.read_excel(path, header=None)
    # NR: comment = 'NR ULTRA' | TBR: comment contains 'TBR'
    if "NR_" in label:
        mask = df[12].astype(str).str.strip() == 'NR ULTRA'
    else:
        mask = df[12].astype(str).str.contains('TBR', na=False)
    e = df[mask].copy()
    e['_dt']     = pd.to_datetime(e[0], errors='coerce')
    e['_date']   = e['_dt'].dt.date
    e['_hour']   = e['_dt'].dt.hour
    e['_minute'] = e['_dt'].dt.minute
    e['_second'] = e['_dt'].dt.second
    e['_hhmm']   = e['_dt'].dt.strftime('%H:%M:%S')
    e['_dir']    = e[3].astype(str).str.lower().str.strip()
    return e

data = {}
for label, path in FILES.items():
    data[label] = load_entries(path, label)
    e = data[label]
    sec00  = (e['_second'] == 0).mean()
    m3_ok  = (e['_minute'] % 3 == 0).mean()
    print(f"{label:<10} | n={len(e):4d} | sec=:00: {sec00:.0%} | min%3=0: {m3_ok:.0%}")

# -----------------------------------------------------------------------
def compare_pair(label_a, label_b):
    a = data[label_a]
    b = data[label_b]

    a_day = a.sort_values('_dt').groupby('_date').first()
    b_day = b.sort_values('_dt').groupby('_date').first()
    common = a_day.index.intersection(b_day.index)

    print(f"\n{'='*60}")
    print(f"  {label_a}  vs  {label_b}")
    print(f"{'='*60}")
    print(f"Días {label_a}: {len(a_day)}  |  {label_b}: {len(b_day)}  |  Comunes: {len(common)}")

    if len(common) == 0:
        print("  Sin días comunes — verificar rango de fechas.")
        return

    ac = a_day.loc[common]
    bc = b_day.loc[common]

    # Dirección
    same_dir = (ac['_dir'].values == bc['_dir'].values)
    print(f"Dirección igual:  {same_dir.sum()} / {len(common)} = {same_dir.mean():.1%}")

    # Tiempo (en segundos totales para BREAKOUT, en minutos para CONFIRM)
    def to_sec(df):
        return df['_hour'] * 3600 + df['_minute'] * 60 + df['_second']

    diff_sec = (to_sec(bc).values - to_sec(ac).values).astype(float)
    print(f"Diff tiempo (seg): mean={np.mean(diff_sec):.1f}  median={np.median(diff_sec):.1f}  "
          f"std={np.std(diff_sec):.1f}  min={int(np.min(diff_sec))}  max={int(np.max(diff_sec))}")

    # Distribución de diffs en minutos
    diff_min = [int(x) // 60 for x in diff_sec]
    cnt = Counter(diff_min)
    total = len(diff_min)
    print(f"Distribución diff en minutos (top 10):")
    for k, v in sorted(cnt.items(), key=lambda x: -x[1])[:10]:
        bar = '#' * (v // max(1, total // 50))
        print(f"  {k:+4d} min: {v:4d} ({v/total:.1%})  {bar}")

    # Mismatches de dirección
    mismatch = [common[i] for i, ok in enumerate(same_dir) if not ok]
    print(f"Mismatches de dirección: {len(mismatch)}")
    for day in mismatch[:8]:
        ar = a_day.loc[day]
        br = b_day.loc[day]
        print(f"  {day}  {label_a}={ar['_dir'][:4]} {ar['_hhmm']}  "
              f"{label_b}={br['_dir'][:4]} {br['_hhmm']}")

    # Primeros 15 días
    print(f"\nPrimeros 15 días comunes:")
    print(f"  {'Fecha':<12} {label_a:>10} {'dir':^4}   {label_b:>10} {'dir':^4}  {'Dseg':>6}  {'Match':^5}")
    print(f"  {'-'*60}")
    for day in sorted(common)[:15]:
        ar = a_day.loc[day]
        br = b_day.loc[day]
        ds = int(to_sec(b_day.loc[[day]]).values[0] - to_sec(a_day.loc[[day]]).values[0])
        m  = 'Y' if ar['_dir'] == br['_dir'] else 'N'
        print(f"  {str(day):<12} {ar['_hhmm']:>10} {ar['_dir'][:4]:^4}   "
              f"{br['_hhmm']:>10} {br['_dir'][:4]:^4}  {ds:>+6}s  {m:^5}")

# -----------------------------------------------------------------------
print("\n" + "="*60)
print("  ANÁLISIS DE SEGUNDOS POR MODO")
print("="*60)
for label, e in data.items():
    sec_dist = e['_second'].value_counts().sort_index()
    unique_sec = len(sec_dist)
    print(f"\n{label} — distribución de segundos ({unique_sec} valores únicos):")
    if unique_sec <= 5:
        print(f"  {sec_dist.to_dict()}")
    else:
        print(f"  Primeros 10: {dict(list(sec_dist.items())[:10])}")
        print(f"  Últimos  5:  {dict(list(sec_dist.items())[-5:])}")

# -----------------------------------------------------------------------
compare_pair("NR_CONF",  "TBR_CONF")
compare_pair("NR_RUPT",  "TBR_RUPT")
