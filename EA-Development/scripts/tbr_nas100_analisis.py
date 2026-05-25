# -*- coding: utf-8 -*-
"""
Analisis IS/OOS/WFA NAS100 — Pass #25720 (BOTH) vs Pass #58421 (LONG)
Pipeline completo: metricas, dia semana, Long/Short, hold times, robustez.
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd
import numpy as np
from pathlib import Path

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion")
EQUITY_INIT = 5000

CONFIGS = {
    "P25720 BOTH (con Lunes)": {
        "IS":  "is_nas_25720.xlsx_.xlsx",
        "OOS": "oos_nas_25720.xlsx_.xlsx",
        "WFA": "WFA_NAS_25720.xlsx",
    },
    "P25720 BOTH (sin Lunes)": {
        "IS":  "is_nas_25720_noM.xlsx_.xlsx",
        "OOS": "oos_nas_25720_NOM.xlsx_.xlsx",
        "WFA": "WFA_NAS_25720_NOM.xlsx",
    },
    "P58421 LONG": {
        "IS":  "is_nas_58421.xlsx_.xlsx",
        "OOS": "oos_nas_58421.xlsx_.xlsx",
        "WFA": "WFA_NAS_58421.xlsx",
    },
}

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
    dt_in  = pd.to_datetime(entries[0].values, errors='coerce')
    dt_out = pd.to_datetime(exits[0].values,   errors='coerce')
    dirs   = entries[3].astype(str).str.lower().str.strip().values
    pnls   = pd.to_numeric(exits[10], errors='coerce').values
    trades = pd.DataFrame({
        'dt_in':    dt_in,
        'dt_out':   dt_out,
        'dir':      dirs,
        'pnl':      pnls,
        'dow':      pd.DatetimeIndex(dt_in).day_name(),
        'year':     pd.DatetimeIndex(dt_in).year,
        'hold_min': (pd.DatetimeIndex(dt_out) - pd.DatetimeIndex(dt_in)).total_seconds() / 60,
    })
    trades = trades.dropna(subset=['pnl'])
    trades = trades[trades['hold_min'] <= 1440]
    return trades

def metrics(t):
    if t.empty: return {}
    w = t[t['pnl'] > 0]; l = t[t['pnl'] < 0]
    pf  = w['pnl'].sum() / abs(l['pnl'].sum()) if len(l) > 0 else np.inf
    cum = t['pnl'].cumsum()
    dd  = abs((cum - cum.cummax()).min())
    dd_pct = dd / EQUITY_INIT * 100
    return {'n': len(t), 'PF': round(pf,3), 'WR': round(len(w)/len(t)*100,1),
            'Net': round(t['pnl'].sum(),2), 'DD%': round(dd_pct,2)}

def fmt(m):
    if not m: return "--"
    pf_f = "[OK]" if m['PF']>=1.40 else ("[~]" if m['PF']>=1.20 else "[X]")
    dd_f = "[OK]" if m['DD%']<=10  else "[X]"
    return (f"n={m['n']} | PF={m['PF']}{pf_f} | WR={m['WR']}% | "
            f"Net=${m['Net']:+.0f} | DD={m['DD%']}%{dd_f}")

# -----------------------------------------------------------------------
print("=" * 70)
print("  TBR NAS100 -- ANALISIS IS / OOS / WFA")
print("=" * 70)

all_trades = {}
for cfg, files in CONFIGS.items():
    print(f"\n{'-'*70}\n  {cfg}\n{'-'*70}")
    cfg_trades = {}
    for period, fname in files.items():
        fpath = BASE / fname
        try:
            t = parse_deals(fpath)
            print(f"  {period}: {fmt(metrics(t))}")
            cfg_trades[period] = t
        except Exception as e:
            print(f"  {period}: ERROR -- {e}")
            cfg_trades[period] = pd.DataFrame()
    all_trades[cfg] = cfg_trades

# -----------------------------------------------------------------------
print("\n\n" + "="*70)
print("  DESGLOSE POR DIA DE LA SEMANA")
print("="*70)
DAYS = ['Monday','Tuesday','Wednesday','Thursday','Friday']

for period_key in ['IS', 'OOS']:
    print(f"\n-- {period_key} --")
    for cfg, files in all_trades.items():
        t = files.get(period_key, pd.DataFrame())
        if t.empty: continue
        print(f"\n  {cfg}:")
        print(f"  {'Dia':<12} {'n':>4} {'PF':>7} {'WR%':>6} {'Net':>9}")
        print(f"  {'-'*40}")
        for day in DAYS:
            sub = t[t['dow'] == day]
            if sub.empty: continue
            m = metrics(sub)
            pf_f = "[OK]" if m['PF']>=1.30 else ("[~]" if m['PF']>=1.0 else "[X]")
            print(f"  {day:<12} {m['n']:>4} {m['PF']:>5.3f}{pf_f} {m['WR']:>5.1f}% ${m['Net']:>+8.0f}")

# -----------------------------------------------------------------------
print("\n\n" + "="*70)
print("  LONG vs SHORT (solo P25720 BOTH)")
print("="*70)
for period in ['IS', 'OOS', 'WFA']:
    t = all_trades.get("P25720 BOTH (con Lunes)", {}).get(period, pd.DataFrame())
    if t.empty: continue
    print(f"\n  {period}:")
    for d in ['buy','sell']:
        sub = t[t['dir']==d]
        m   = metrics(sub)
        if not m: continue
        lbl = "LONG " if d=='buy' else "SHORT"
        pf_f = "[OK]" if m['PF']>=1.40 else ("[~]" if m['PF']>=1.0 else "[X]")
        print(f"    {lbl}: n={m['n']:>3} | PF={m['PF']:.3f}{pf_f} | WR={m['WR']}% | Net=${m['Net']:+.0f}")

# -----------------------------------------------------------------------
print("\n\n" + "="*70)
print("  DESGLOSE POR ANO")
print("="*70)
for cfg, files in all_trades.items():
    all_t = []
    for p, t in files.items():
        if not t.empty:
            t = t.copy(); t['period'] = p; all_t.append(t)
    if not all_t: continue
    combined = pd.concat(all_t)
    print(f"\n{cfg}:")
    print(f"  {'Ano':<6} {'Per':<4} {'n':>4} {'PF':>7} {'WR%':>6} {'Net':>9} {'DD%':>6}")
    print(f"  {'-'*48}")
    for year in sorted(combined['year'].dropna().unique()):
        sub = combined[combined['year']==year]
        m   = metrics(sub)
        per = sub['period'].iloc[0][:3]
        pf_f = "[OK]" if m['PF']>=1.40 else ("[~]" if m['PF']>=1.0 else "[X]")
        print(f"  {int(year):<6} {per:<4} {m['n']:>4} {m['PF']:>5.3f}{pf_f} "
              f"{m['WR']:>5.1f}% ${m['Net']:>+8.0f} {m['DD%']:>5.1f}%")

# -----------------------------------------------------------------------
print("\n\n" + "="*70)
print("  ROBUSTEZ SessionEnd -- HOLD TIME DISTRIBUTION")
print("="*70)
THRESHOLDS = [(0,60,'<1h'),(60,150,'1-2.5h'),(150,9999,'>2.5h')]

for cfg in ["P25720 BOTH (con Lunes)", "P58421 LONG"]:
    files = all_trades.get(cfg, {})
    for period in ['IS','OOS','WFA']:
        t = files.get(period, pd.DataFrame())
        if t.empty: continue
        total_net = t['pnl'].sum()
        print(f"\n  {cfg} | {period} | n={len(t)} | Net=${total_net:+.0f}")
        print(f"  {'Bucket':<12} {'n':>4} {'PF':>7} {'Net':>9} {'% Net':>7}")
        print(f"  {'-'*44}")
        for lo, hi, lbl in THRESHOLDS:
            sub = t[(t['hold_min']>=lo)&(t['hold_min']<hi)]
            m   = metrics(sub)
            if not m: continue
            pct = sub['pnl'].sum()/total_net*100 if total_net!=0 else 0
            pf_s = f"{m['PF']:.3f}" if m['PF']!=np.inf else "inf"
            print(f"  {lbl:<12} {m['n']:>4} {pf_s:>7} ${m['Net']:>+8.0f} {pct:>+6.0f}%")

# -----------------------------------------------------------------------
print("\n\n" + "="*70)
print("  RESUMEN COMPARATIVO -- PIPELINE COMPLETO")
print("="*70)
print(f"\n{'Config':<26} {'IS PF':>6} {'OOS PF':>7} {'WFA PF':>7} "
      f"{'OOS Net':>9} {'WFA Net':>9} {'OOS DD':>7}  Veredicto")
print("-"*85)

for cfg, files in all_trades.items():
    is_m  = metrics(files.get('IS',  pd.DataFrame()))
    oos_m = metrics(files.get('OOS', pd.DataFrame()))
    wfa_m = metrics(files.get('WFA', pd.DataFrame()))
    is_pf  = f"{is_m['PF']:.3f}"  if is_m  else "--"
    oos_pf = f"{oos_m['PF']:.3f}" if oos_m else "--"
    wfa_pf = f"{wfa_m['PF']:.3f}" if wfa_m else "--"
    oos_net = f"${oos_m['Net']:+.0f}" if oos_m else "--"
    wfa_net = f"${wfa_m['Net']:+.0f}" if wfa_m else "--"
    oos_dd  = f"{oos_m['DD%']:.1f}%"  if oos_m else "--"
    if oos_m and wfa_m:
        viable = (oos_m['PF']>=1.40 and oos_m['DD%']<=10 and wfa_m['PF']>=1.0)
        verdict = "VIABLE [OK]" if viable else ("MARGINAL [~]" if oos_m['PF']>=1.20 else "NO VIABLE [X]")
    else:
        verdict = "--"
    print(f"{cfg:<26} {is_pf:>6} {oos_pf:>7} {wfa_pf:>7} "
          f"{oos_net:>9} {wfa_net:>9} {oos_dd:>7}  {verdict}")
