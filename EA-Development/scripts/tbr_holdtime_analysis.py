# -*- coding: utf-8 -*-
"""
Analisis de hold times TBR XAUUSD P2 BE sin Lunes.
Pregunta: cuantos trades cierran por MaxHoldHours=4?
Que pasa si el timer fuera 2h, 3h, 5h, 6h?
"""

import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd
import numpy as np
from pathlib import Path

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD")

FILES = {
    "IS  (2022-2024)": "is_tbr_xauusd_p2_2022-2024_be_noL.xlsx",
    "OOS (2025)     ": "OOS_TBR_XAU_P2_2025_be_NOL.xlsx",
    "WFA (2026)     ": "WFA_TBR_XAU_be_noL_2026.xlsx",
}

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
    pnls   = pd.to_numeric(exits[10], errors='coerce').values
    comms  = exits[12].astype(str).str.strip().str.lower().values

    trades = pd.DataFrame({
        'dt_in':   dt_in,
        'dt_out':  dt_out,
        'pnl':     pnls,
        'comment': comms,
    })
    trades = trades.dropna(subset=['pnl', 'dt_in', 'dt_out'])
    trades['hold_min'] = (trades['dt_out'] - trades['dt_in']).dt.total_seconds() / 60
    trades['hold_h']   = trades['hold_min'] / 60
    return trades

# -----------------------------------------------------------------------
print("=" * 65)
print("  ANALISIS DE HOLD TIME -- TBR XAUUSD P2 BE SIN LUNES")
print("=" * 65)

all_trades = {}
for label, fname in FILES.items():
    trades = parse_deals(BASE / fname)
    all_trades[label] = trades

    print(f"\n{label}  (n={len(trades)})")
    print(f"  Hold time medio:   {trades['hold_min'].mean():.0f} min  ({trades['hold_min'].mean()/60:.2f}h)")
    print(f"  Hold time mediana: {trades['hold_min'].median():.0f} min  ({trades['hold_min'].median()/60:.2f}h)")
    print(f"  Hold time max:     {trades['hold_min'].max():.0f} min  ({trades['hold_min'].max()/60:.2f}h)")
    print(f"  Hold time min:     {trades['hold_min'].min():.0f} min")

    # Distribucion por buckets
    buckets = [0, 30, 60, 90, 120, 150, 180, 210, 240, 300, 9999]
    labels  = ['<30m','30-60m','60-90m','90-120m','120-150m','150-180m','180-210m','210-240m','240-300m','>300m']
    trades['bucket'] = pd.cut(trades['hold_min'], bins=buckets, labels=labels, right=False)
    dist = trades.groupby('bucket', observed=True).agg(
        n=('pnl','count'),
        net=('pnl','sum'),
        pf=('pnl', lambda x: x[x>0].sum() / abs(x[x<0].sum()) if (x<0).any() else np.inf)
    )
    print(f"\n  Distribucion por duracion:")
    print(f"  {'Rango':<12} {'n':>4} {'%':>6} {'Net':>9} {'PF':>6}")
    print(f"  {'-'*42}")
    for bucket, row in dist.iterrows():
        if row['n'] == 0:
            continue
        pf_str = f"{row['pf']:.3f}" if row['pf'] != np.inf else "inf"
        print(f"  {str(bucket):<12} {int(row['n']):>4} {row['n']/len(trades)*100:>5.1f}%"
              f" ${row['net']:>+8.0f} {pf_str:>6}")

    # Identificar timeouts (cerca de 240 min = 4h, tolerancia 5 min)
    timeouts = trades[(trades['hold_min'] >= 235) & (trades['hold_min'] <= 245)]
    non_timeout = trades[~trades.index.isin(timeouts.index)]
    print(f"\n  Trades ~4h (timeout estimado): {len(timeouts)} ({len(timeouts)/len(trades)*100:.1f}%)")
    if len(timeouts) > 0:
        tw = timeouts[timeouts['pnl'] > 0]
        tl = timeouts[timeouts['pnl'] < 0]
        pf_t = tw['pnl'].sum() / abs(tl['pnl'].sum()) if len(tl) > 0 else np.inf
        print(f"    Net timeouts: ${timeouts['pnl'].sum():+.0f}  |  PF: {pf_t:.3f}  |  WR: {len(tw)/len(timeouts)*100:.1f}%")
    if len(non_timeout) > 0:
        ntw = non_timeout[non_timeout['pnl'] > 0]
        ntl = non_timeout[non_timeout['pnl'] < 0]
        pf_nt = ntw['pnl'].sum() / abs(ntl['pnl'].sum()) if len(ntl) > 0 else np.inf
        print(f"  Trades SL/TP (no timeout):     {len(non_timeout)} ({len(non_timeout)/len(trades)*100:.1f}%)")
        print(f"    Net SL/TP:  ${non_timeout['pnl'].sum():+.0f}  |  PF: {pf_nt:.3f}  |  WR: {len(ntw)/len(non_timeout)*100:.1f}%")

# -----------------------------------------------------------------------
# Simulacion: si cambiaramos MaxHoldHours, que trades se ven afectados?
print("\n\n" + "=" * 65)
print("  SIMULACION DE SENSIBILIDAD -- MaxHoldHours")
print("=" * 65)
print("  (Trades que cierran ANTES del timer -> no afectados)")
print("  (Trades que cierran POR el timer -> afectados por el cambio)")
print()

# Combinar OOS + WFA para el analisis de sensibilidad
oos = all_trades["OOS (2025)     "]
wfa = all_trades["WFA (2026)     "]
combined = pd.concat([oos, wfa], ignore_index=True)

print(f"  Base OOS+WFA combinados: {len(combined)} trades")
print()

timers_h = [1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0]
print(f"  {'Timer':>6} {'n_afect':>8} {'%afect':>8} {'n_elim':>8} {'Net_base':>10} {'comentario'}")
print(f"  {'-'*65}")

base_net = combined['pnl'].sum()

for timer_h in timers_h:
    # Trades que hubieran cerrado por el timer (hold >= timer)
    # -> en realidad si el timer es mas corto, algunos trades que antes
    #    se mantuvieron (y salieron por SL/TP despues) ahora se cortarian
    # Con los datos disponibles solo podemos ver:
    # - trades que cerraron ANTES del timer: no afectados
    # - trades que cerraron EN o DESPUES del timer actual: potencialmente afectados
    affected = combined[combined['hold_h'] >= timer_h]
    not_affected = combined[combined['hold_h'] < timer_h]

    marker = " <-- ACTUAL" if timer_h == 4.0 else ""
    print(f"  {timer_h:>5.1f}h {len(affected):>8} {len(affected)/len(combined)*100:>7.1f}% "
          f"{'-':>8} ${not_affected['pnl'].sum():>+9.0f}{marker}")

print()
print("  Nota: 'n_afect' = trades con duracion >= timer (cerraron por timeout")
print("        o hubieran sido cortados antes con un timer menor).")
print("        'Net_base' = net de trades que cerraron antes del umbral.")

# -----------------------------------------------------------------------
# Analisis por tipo de comentario (SL / TP / timeout)
print("\n\n" + "=" * 65)
print("  TIPOS DE CIERRE POR COMENTARIO")
print("=" * 65)

for label, trades in all_trades.items():
    print(f"\n{label}:")
    comm_groups = trades.groupby(trades['comment'].str[:10]).agg(
        n=('pnl','count'),
        net=('pnl','sum'),
        wr=('pnl', lambda x: (x>0).mean()*100)
    ).sort_values('n', ascending=False)
    print(f"  {'Comentario':<18} {'n':>4} {'Net':>9} {'WR%':>6}")
    print(f"  {'-'*42}")
    for comm, row in comm_groups.head(15).iterrows():
        print(f"  {str(comm):<18} {int(row['n']):>4} ${row['net']:>+8.0f} {row['wr']:>5.1f}%")
