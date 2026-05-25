"""
Investigación de dirección opuesta en BREAKOUT mode.
Analiza precios de entrada en días con mismatch NR vs TBR.
Hipótesis: StopLevel_ExtraPoints diferente (NR=2, TBR=10) causa
que TBR no pueda colocar BUY STOP cuando precio ya pasó rangeHigh+2
pero no llegó a rangeHigh+10.
"""

import pandas as pd
import numpy as np
from pathlib import Path

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests")
NR_FILE  = BASE / "NR Backtest NAS100 M5 rupt.xlsx"
TBR_FILE = BASE / "tbR Backtest NAS100 M5 rupt.xlsx"

nr_raw  = pd.read_excel(NR_FILE,  header=None)
tbr_raw = pd.read_excel(TBR_FILE, header=None)

# ---------- extraer entradas ----------
def load_entries(df, is_nr):
    if is_nr:
        mask = df[12].astype(str).str.strip() == 'NR ULTRA'
    else:
        mask = df[12].astype(str).str.contains('TBR', na=False)
    e = df[mask].copy()
    e['_dt']        = pd.to_datetime(e[0], errors='coerce')
    e['_date']      = e['_dt'].dt.date
    e['_hhmm']      = e['_dt'].dt.strftime('%H:%M:%S')
    e['_dir']       = e[3].astype(str).str.lower().str.strip()
    e['_entry_px']  = pd.to_numeric(e[6], errors='coerce')   # precio de entrada (col 6)
    e['_sl']        = pd.to_numeric(e[7], errors='coerce')   # SL
    e['_tp']        = pd.to_numeric(e[8], errors='coerce')   # TP
    e['_comment']   = e[12].astype(str)
    return e.sort_values('_dt').groupby('_date').first()

nr  = load_entries(nr_raw,  is_nr=True)
tbr = load_entries(tbr_raw, is_nr=False)

common  = nr.index.intersection(tbr.index)
nr_c    = nr.loc[common]
tbr_c   = tbr.loc[common]

same_dir    = nr_c['_dir'].values == tbr_c['_dir'].values
mismatch_days = common[~same_dir]

print(f"Total días comunes: {len(common)}")
print(f"Mismatches:         {len(mismatch_days)}")
print(f"Match rate:         {same_dir.mean():.1%}\n")

# ---------- análisis de precios en mismatch ----------
print("=== DÍAS CON DIRECCIÓN OPUESTA — análisis de precios ===\n")
print(f"{'Fecha':<12} {'NR dir':^6} {'NR px':^10} {'TBR dir':^6} {'TBR px':^10} {'PX diff':^10} {'NR SL':^10} {'TBR SL':^10}")
print("-" * 80)

px_diffs = []
for day in sorted(mismatch_days)[:30]:
    nr_r  = nr_c.loc[day]
    tbr_r = tbr_c.loc[day]
    px_diff = tbr_r['_entry_px'] - nr_r['_entry_px']
    px_diffs.append(px_diff)
    print(f"{str(day):<12} {nr_r['_dir'][:4]:^6} {nr_r['_entry_px']:^10.2f} "
          f"{tbr_r['_dir'][:4]:^6} {tbr_r['_entry_px']:^10.2f} "
          f"{px_diff:^+10.2f} {nr_r['_sl']:^10.2f} {tbr_r['_sl']:^10.2f}")

print(f"\nDiff precio (TBR - NR) en mismatches:")
print(f"  Media:    {np.mean(px_diffs):+.2f} pts")
print(f"  Mediana:  {np.median(px_diffs):+.2f} pts")
print(f"  Std:      {np.std(px_diffs):.2f} pts")

# ---------- análisis de precios en días que SÍ coinciden ----------
match_days = common[same_dir]
px_diffs_match = []
for day in sorted(match_days)[:50]:
    nr_r  = nr_c.loc[day]
    tbr_r = tbr_c.loc[day]
    px_diffs_match.append(tbr_r['_entry_px'] - nr_r['_entry_px'])

print(f"\nDiff precio (TBR - NR) en días que SÍ coinciden ({len(match_days)} días):")
print(f"  Media:    {np.mean(px_diffs_match):+.2f} pts")
print(f"  Mediana:  {np.median(px_diffs_match):+.2f} pts")
print(f"  Std:      {np.std(px_diffs_match):.2f} pts")

# ---------- rango de precios: ¿TBR entra más lejos del rango? ----------
print("\n=== RANGO DE PRECIOS DE ENTRADA vs SL ===")
print("(Para BREAKOUT: entry = range_boundary + extra_points)")
print("(SL = opposite boundary + extra_points)")

# Para un BUY: entry = rangeHigh + extra, SL = rangeLow - extra
# rangeHigh = entry - extra, rangeLow = SL + extra
# Distancia entry→SL = rangeHigh - rangeLow + 2*extra = rangeWidth + 2*extra

# Para NR BUY: entry_nr = rangeHigh + 2, SL_nr = rangeLow - 2 (si SL_On_Opposite=true con offset 2)
# Para TBR BUY: entry_tbr = rangeHigh + 10, SL_tbr = rangeLow - 10

# En días de match BUY:
buy_match = [(day, nr_c.loc[day], tbr_c.loc[day])
             for day in match_days if nr_c.loc[day]['_dir'] == 'buy'][:20]

if buy_match:
    print(f"\nDías de match con BUY — diferencia de precios de entrada:")
    for day, nr_r, tbr_r in buy_match[:10]:
        diff = tbr_r['_entry_px'] - nr_r['_entry_px']
        sl_diff = tbr_r['_sl'] - nr_r['_sl']
        print(f"  {day}: NR_buy={nr_r['_entry_px']:.2f} TBR_buy={tbr_r['_entry_px']:.2f} "
              f"entry_diff={diff:+.2f} | NR_sl={nr_r['_sl']:.2f} TBR_sl={tbr_r['_sl']:.2f} sl_diff={sl_diff:+.2f}")

sell_match = [(day, nr_c.loc[day], tbr_c.loc[day])
              for day in match_days if nr_c.loc[day]['_dir'] == 'sell'][:20]

if sell_match:
    print(f"\nDías de match con SELL — diferencia de precios de entrada:")
    for day, nr_r, tbr_r in sell_match[:10]:
        diff = tbr_r['_entry_px'] - nr_r['_entry_px']
        sl_diff = tbr_r['_sl'] - nr_r['_sl']
        print(f"  {day}: NR_sell={nr_r['_entry_px']:.2f} TBR_sell={tbr_r['_entry_px']:.2f} "
              f"entry_diff={diff:+.2f} | NR_sl={nr_r['_sl']:.2f} TBR_sl={tbr_r['_sl']:.2f} sl_diff={sl_diff:+.2f}")

# ---------- Comment analysis ----------
print(f"\nTBR comments en días de mismatch:")
mismatch_comments = tbr_c.loc[mismatch_days]['_comment'].value_counts()
print(mismatch_comments)

print(f"\nTBR comments en días de match:")
match_comments = tbr_c.loc[match_days]['_comment'].value_counts()
print(match_comments)
