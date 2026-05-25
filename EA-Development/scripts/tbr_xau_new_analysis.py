# -*- coding: utf-8 -*-
"""
Analisis IS/OOS/WFA -- TBR XAUUSD nuevas configuraciones.
Parser DEAL: col[4]='in'/'out', P&L en col[10].
4 configs: P1(vieja) | P2 sin BE | P2 BE | P2 BE sin Lunes
"""

import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd
import numpy as np
from pathlib import Path

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD")

CONFIGS = {
    "P1 (anterior)": {
        "IS":  "IS_TBR_XAUUSD_P1_2022-2024.xlsx",
        "OOS": "OOS_TBR_XAUUSD_P1_2025.xlsx",
        "WFA": "WFA_TBR_XAUUSD_P1_2026.xlsx",
    },
    "P2 sin BE": {
        "IS":  "is_tbr_xauusd_p2_2022-2024.xlsx",
        "OOS": "OOS_TBR_XAU_P2_2025.xlsx",
        "WFA": "WFA_TBR_XAU_P2_2026.xlsx",
    },
    "P2 BE (con Lunes)": {
        "IS":  "is_tbr_xauusd_p2_2022-2024_be.xlsx",
        "OOS": "OOS_TBR_XAU_P2_2025_be.xlsx",
        "WFA": "WFA_TBR_XAU_be_2026.xlsx",
    },
    "P2 BE sin Lunes": {
        "IS":  "is_tbr_xauusd_p2_2022-2024_be_noL.xlsx",
        "OOS": "OOS_TBR_XAU_P2_2025_be_NOL.xlsx",
        "WFA": "WFA_TBR_XAU_be_noL_2026.xlsx",
    },
}

# -----------------------------------------------------------------------
def parse_deals(path):
    """Parser DEAL MT5: col[4]='in'/'out', P&L en col[10].
    Emparejamiento secuencial: cada 'in' va seguido de su 'out'."""
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
    comms  = exits[12].astype(str).str.lower().values

    trades = pd.DataFrame({
        'dt_in':   dt_in,
        'dt_out':  dt_out,
        'dir':     dirs,
        'pnl':     pnls,
        'comment': comms,
        'dow':     pd.DatetimeIndex(dt_in).day_name(),
        'year':    pd.DatetimeIndex(dt_in).year,
        'month':   pd.DatetimeIndex(dt_in).to_period('M'),
    })
    trades = trades.dropna(subset=['pnl'])
    return trades

# -----------------------------------------------------------------------
def metrics(trades):
    if trades.empty:
        return {}
    n      = len(trades)
    wins   = trades[trades['pnl'] > 0]
    losses = trades[trades['pnl'] < 0]
    gross_w = wins['pnl'].sum()
    gross_l = losses['pnl'].abs().sum()
    pf      = gross_w / gross_l if gross_l > 0 else np.inf
    wr      = len(wins) / n * 100
    net     = trades['pnl'].sum()
    # DD
    cum     = trades['pnl'].cumsum()
    dd      = (cum - cum.cummax()).min()
    dd_pct  = abs(dd) / 5000 * 100  # equity inicial 5000 USD
    return {
        'n': n, 'PF': round(pf,3), 'WR': round(wr,1),
        'Net': round(net,2), 'MaxDD': round(abs(dd),2), 'DD%': round(dd_pct,2)
    }

def fmt(m):
    if not m:
        return "--"
    pf_flag = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.20 else "[X]")
    dd_flag = "[OK]" if m['DD%'] <= 10 else "[X]"
    return (f"n={m['n']} | PF={m['PF']}{pf_flag} | WR={m['WR']}% | "
            f"Net=${m['Net']:+.0f} | DD={m['DD%']}%{dd_flag}")

# -----------------------------------------------------------------------
print("=" * 70)
print("  TBR XAUUSD -- ANALISIS IS / OOS / WFA")
print("=" * 70)

all_trades = {}
for cfg, files in CONFIGS.items():
    print(f"\n{'-'*70}")
    print(f"  {cfg}")
    print(f"{'-'*70}")
    cfg_trades = {}
    for period, fname in files.items():
        fpath = BASE / fname
        try:
            trades = parse_deals(fpath)
            m = metrics(trades)
            print(f"  {period}: {fmt(m)}")
            cfg_trades[period] = trades
        except Exception as e:
            print(f"  {period}: ERROR -- {e}")
            cfg_trades[period] = pd.DataFrame()
    all_trades[cfg] = cfg_trades

# -----------------------------------------------------------------------
# Desglose por dia de la semana
print("\n\n" + "=" * 70)
print("  DESGLOSE POR DIA -- IS (2022-2024)")
print("=" * 70)
DAYS = ['Monday','Tuesday','Wednesday','Thursday','Friday']

for cfg, files in all_trades.items():
    trades = files.get('IS', pd.DataFrame())
    if trades.empty:
        continue
    print(f"\n{cfg}:")
    print(f"  {'Dia':<12} {'n':>4} {'PF':>6} {'WR%':>6} {'Net':>8}")
    print(f"  {'-'*38}")
    for day in DAYS:
        sub = trades[trades['dow'] == day]
        if sub.empty:
            continue
        m = metrics(sub)
        pf_f = "[OK]" if m['PF']>=1.30 else ("[~]" if m['PF']>=1.0 else "[X]")
        print(f"  {day:<12} {m['n']:>4} {m['PF']:>5.3f}{pf_f} {m['WR']:>5.1f}% ${m['Net']:>+7.0f}")

print(f"\n  OOS (2025):")
for cfg, files in all_trades.items():
    trades = files.get('OOS', pd.DataFrame())
    if trades.empty:
        continue
    print(f"\n{cfg}:")
    print(f"  {'Dia':<12} {'n':>4} {'PF':>6} {'WR%':>6} {'Net':>8}")
    print(f"  {'-'*38}")
    for day in DAYS:
        sub = trades[trades['dow'] == day]
        if sub.empty:
            continue
        m = metrics(sub)
        pf_f = "[OK]" if m['PF']>=1.30 else ("[~]" if m['PF']>=1.0 else "[X]")
        print(f"  {day:<12} {m['n']:>4} {m['PF']:>5.3f}{pf_f} {m['WR']:>5.1f}% ${m['Net']:>+7.0f}")

# -----------------------------------------------------------------------
# Desglose por anio
print("\n\n" + "=" * 70)
print("  DESGLOSE POR ANIO")
print("=" * 70)

for cfg, files in all_trades.items():
    all_t = []
    for p, t in files.items():
        if not t.empty:
            t = t.copy()
            t['period'] = p
            all_t.append(t)
    if not all_t:
        continue
    combined = pd.concat(all_t)
    print(f"\n{cfg}:")
    print(f"  {'Anio':<6} {'Period':<5} {'n':>4} {'PF':>6} {'WR%':>6} {'Net':>8} {'DD%':>6}")
    print(f"  {'-'*50}")
    for year in sorted(combined['year'].dropna().unique()):
        sub = combined[combined['year'] == year]
        m = metrics(sub)
        period_label = sub['period'].iloc[0][:3]
        pf_f = "[OK]" if m['PF']>=1.40 else ("[~]" if m['PF']>=1.0 else "[X]")
        print(f"  {int(year):<6} {period_label:<5} {m['n']:>4} {m['PF']:>5.3f}{pf_f} "
              f"{m['WR']:>5.1f}% ${m['Net']:>+7.0f} {m['DD%']:>5.1f}%")

# -----------------------------------------------------------------------
# Resumen comparativo
print("\n\n" + "=" * 70)
print("  RESUMEN COMPARATIVO -- PIPELINE COMPLETO")
print("=" * 70)
print(f"\n{'Config':<22} {'IS PF':>7} {'OOS PF':>7} {'WFA PF':>7} {'OOS Net':>9} {'WFA Net':>9} {'OOS DD%':>8}")
print(f"{'--'*37}")

VIABILITY = {'PF_OOS': 1.40, 'PF_WFA': 1.0, 'DD': 10.0}

for cfg, files in all_trades.items():
    is_m  = metrics(files.get('IS',  pd.DataFrame()))
    oos_m = metrics(files.get('OOS', pd.DataFrame()))
    wfa_m = metrics(files.get('WFA', pd.DataFrame()))

    is_pf  = f"{is_m.get('PF','--'):.3f}"  if is_m  else "--"
    oos_pf = f"{oos_m.get('PF','--'):.3f}" if oos_m else "--"
    wfa_pf = f"{wfa_m.get('PF','--'):.3f}" if wfa_m else "--"

    oos_net = f"${oos_m.get('Net',0):+.0f}" if oos_m else "--"
    wfa_net = f"${wfa_m.get('Net',0):+.0f}" if wfa_m else "--"
    oos_dd  = f"{oos_m.get('DD%',0):.1f}%"  if oos_m else "--"

    # Veredicto
    if oos_m and wfa_m:
        viable = (oos_m.get('PF',0) >= 1.40 and
                  oos_m.get('DD%',99) <= 10 and
                  wfa_m.get('PF',0) >= 1.0)
        verdict = "VIABLE [OK]" if viable else ("MARGINAL [~]" if oos_m.get('PF',0) >= 1.20 else "NO VIABLE [X]")
    else:
        verdict = "--"

    print(f"{cfg:<22} {is_pf:>7} {oos_pf:>7} {wfa_pf:>7} {oos_net:>9} {wfa_net:>9} {oos_dd:>8}  {verdict}")
