# -*- coding: utf-8 -*-
"""
Estudios de alta urgencia — TBR XAUUSD P2 BE sin Lunes
1. Robustez SessionEnd (sensibilidad al cierre de sesion)
2. Long vs Short separados (por periodo y por anio)
3. Concentracion del edge en bucket 150-180m
"""

import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd
import numpy as np
from pathlib import Path

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD")

FILES = {
    "IS":  "is_tbr_xauusd_p2_2022-2024_be_noL.xlsx",
    "OOS": "OOS_TBR_XAU_P2_2025_be_NOL.xlsx",
    "WFA": "WFA_TBR_XAU_be_noL_2026.xlsx",
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
    dirs   = entries[3].astype(str).str.lower().str.strip().values
    pnls   = pd.to_numeric(exits[10], errors='coerce').values
    trades = pd.DataFrame({
        'dt_in': dt_in, 'dt_out': dt_out,
        'dir': dirs, 'pnl': pnls,
        'year': pd.DatetimeIndex(dt_in).year,
    })
    trades = trades.dropna(subset=['pnl', 'dt_in', 'dt_out'])
    trades['hold_min'] = (trades['dt_out'] - trades['dt_in']).dt.total_seconds() / 60
    # Excluir outlier extremo (>24h = datos anomalos)
    trades = trades[trades['hold_min'] <= 1440]
    return trades

def metrics(t):
    if t.empty: return {}
    w = t[t['pnl'] > 0]; l = t[t['pnl'] < 0]
    pf = w['pnl'].sum() / abs(l['pnl'].sum()) if len(l) > 0 else np.inf
    cum = t['pnl'].cumsum()
    dd_pct = abs((cum - cum.cummax()).min()) / 5000 * 100
    return {'n': len(t), 'PF': round(pf,3), 'WR': round(len(w)/len(t)*100,1),
            'Net': round(t['pnl'].sum(),2), 'DD%': round(dd_pct,2)}

data = {k: parse_deals(BASE / v) for k, v in FILES.items()}

# =====================================================================
# ESTUDIO 1 — ROBUSTEZ SessionEnd
# Aproximacion: si SessionEnd fuera X minutos antes/despues,
# los trades del bucket largo (>X min) no existirian o serian diferentes.
# Simulamos excluyendo trades con hold_time > umbral (SessionEnd anticipado).
# =====================================================================
print("=" * 68)
print("  ESTUDIO 1 — ROBUSTEZ DE SessionEnd")
print("=" * 68)

print("\nDistribucion granular de hold times (bucket 150-180m):")
for period, trades in data.items():
    long_trades = trades[(trades['hold_min'] >= 140) & (trades['hold_min'] <= 185)]
    if long_trades.empty:
        continue
    print(f"\n  {period} — trades 140-185 min (n={len(long_trades)}):")
    print(f"  {'Hold (min)':<12} {'n':>4} {'Net':>9} {'PF':>7}")
    print(f"  {'-'*35}")
    bins = list(range(140, 186, 5))
    for i in range(len(bins)-1):
        sub = long_trades[(long_trades['hold_min'] >= bins[i]) & (long_trades['hold_min'] < bins[i+1])]
        if sub.empty: continue
        w = sub[sub['pnl'] > 0]; lo = sub[sub['pnl'] < 0]
        pf = w['pnl'].sum()/abs(lo['pnl'].sum()) if len(lo)>0 else np.inf
        pf_s = f"{pf:.2f}" if pf != np.inf else "inf"
        print(f"  {bins[i]:>3}-{bins[i+1]:<3} min   {len(sub):>4} ${sub['pnl'].sum():>+8.0f} {pf_s:>7}")

# Sensibilidad: ¿que pasa si SessionEnd es X min antes?
# = excluir trades con hold_min > umbral_sesion
print("\n\nSensibilidad: resultados segun umbral maximo de duracion")
print("(simula SessionEnd mas temprano o mas tarde)\n")

thresholds = [60, 90, 120, 135, 150, 165, 180, 999]
threshold_labels = ['60m(1h)', '90m(1.5h)', '120m(2h)', '135m(2.25h)',
                    '150m(2.5h)', '165m(2.75h)', '180m(3h)', 'sin limite']

for period, trades in data.items():
    total_net = trades['pnl'].sum()
    print(f"  {period} (total n={len(trades)}, Net=${total_net:+.0f}):")
    print(f"  {'Umbral':<14} {'n_excl':>7} {'n_keep':>7} {'Net_keep':>10} {'PF_keep':>8} {'% del Net'}")
    print(f"  {'-'*60}")
    for thr, lbl in zip(thresholds, threshold_labels):
        kept = trades[trades['hold_min'] <= thr]
        excl = trades[trades['hold_min'] > thr]
        m = metrics(kept)
        if not m: continue
        pct = kept['pnl'].sum() / total_net * 100 if total_net != 0 else 0
        marker = " <-- actual" if thr == 999 else ""
        print(f"  {lbl:<14} {len(excl):>7} {m['n']:>7} ${m['Net']:>+9.0f} {m['PF']:>8.3f} {pct:>8.1f}%{marker}")
    print()

# =====================================================================
# ESTUDIO 2 — LONG vs SHORT separados
# =====================================================================
print("=" * 68)
print("  ESTUDIO 2 — LONG vs SHORT SEPARADOS")
print("=" * 68)

print(f"\n{'Periodo':<6} {'Dir':<6} {'n':>4} {'PF':>6} {'WR%':>6} {'Net':>9} {'DD%':>6}")
print(f"{'-'*48}")

for period, trades in data.items():
    for direction in ['buy', 'sell']:
        sub = trades[trades['dir'] == direction]
        m = metrics(sub)
        if not m: continue
        dir_label = "LONG" if direction == 'buy' else "SHORT"
        flag = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        print(f"{period:<6} {dir_label:<6} {m['n']:>4} {m['PF']:>5.3f}{flag} {m['WR']:>5.1f}% "
              f"${m['Net']:>+8.0f} {m['DD%']:>5.1f}%")
    print()

# Desglose Long/Short por anio (IS + combinado)
print("\nLong vs Short por anio (IS 2022-2024):")
is_trades = data['IS']
print(f"\n{'Anio':<6} {'Dir':<6} {'n':>4} {'PF':>6} {'WR%':>6} {'Net':>9}")
print(f"{'-'*42}")
for year in sorted(is_trades['year'].dropna().unique()):
    for direction in ['buy', 'sell']:
        sub = is_trades[(is_trades['year'] == year) & (is_trades['dir'] == direction)]
        m = metrics(sub)
        if not m: continue
        dir_label = "LONG" if direction == 'buy' else "SHORT"
        flag = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        print(f"{int(year):<6} {dir_label:<6} {m['n']:>4} {m['PF']:>5.3f}{flag} {m['WR']:>5.1f}% ${m['Net']:>+8.0f}")
    print()

print("\nLong vs Short OOS 2025 + WFA 2026:")
for period in ['OOS', 'WFA']:
    trades = data[period]
    for direction in ['buy', 'sell']:
        sub = trades[trades['dir'] == direction]
        m = metrics(sub)
        if not m: continue
        dir_label = "LONG" if direction == 'buy' else "SHORT"
        flag = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        print(f"{period:<6} {dir_label:<6} {m['n']:>4} {m['PF']:>5.3f}{flag} {m['WR']:>5.1f}% ${m['Net']:>+8.0f}")
    print()

# Long vs Short por bucket de duracion (OOS)
print("\nLong vs Short segun duracion trade (OOS 2025):")
oos = data['OOS']
buckets = [(0,60,'rapido(<1h)'), (60,150,'medio(1-2.5h)'), (150,200,'sesion(>2.5h)')]
print(f"\n{'Bucket':<16} {'Dir':<6} {'n':>4} {'PF':>6} {'Net':>9}")
print(f"{'-'*44}")
for lo, hi, label in buckets:
    for direction in ['buy', 'sell']:
        sub = oos[(oos['hold_min'] >= lo) & (oos['hold_min'] < hi) & (oos['dir'] == direction)]
        m = metrics(sub)
        if not m or m['n'] < 3: continue
        dir_label = "LONG" if direction == 'buy' else "SHORT"
        flag = "[OK]" if m['PF'] >= 1.40 else ("[~]" if m['PF'] >= 1.0 else "[X]")
        print(f"{label:<16} {dir_label:<6} {m['n']:>4} {m['PF']:>5.3f}{flag} ${m['Net']:>+8.0f}")

# =====================================================================
# ESTUDIO 3 — CONCENTRACION DEL EDGE
# =====================================================================
print("\n\n" + "=" * 68)
print("  ESTUDIO 3 — CONCENTRACION DEL EDGE (150-180m)")
print("=" * 68)

for period, trades in data.items():
    total_net = trades['pnl'].sum()
    long_bucket = trades[trades['hold_min'] >= 150]
    rest = trades[trades['hold_min'] < 150]
    m_long = metrics(long_bucket)
    m_rest = metrics(rest)

    print(f"\n{period} — Net total: ${total_net:+.0f} (n={len(trades)})")

    if m_long:
        pct = long_bucket['pnl'].sum() / total_net * 100 if total_net != 0 else 0
        print(f"  Bucket >150m:  n={m_long['n']:>3} | Net=${m_long['Net']:>+8.0f} ({pct:>+.0f}% del total) | PF={m_long['PF']:.3f}")
    if m_rest:
        pct_r = rest['pnl'].sum() / total_net * 100 if total_net != 0 else 0
        print(f"  Bucket <150m:  n={m_rest['n']:>3} | Net=${m_rest['Net']:>+8.0f} ({pct_r:>+.0f}% del total) | PF={m_rest['PF']:.3f}")

    # Concentracion dentro del bucket >150m: top trades
    if not long_bucket.empty:
        sorted_lt = long_bucket.sort_values('pnl', ascending=False)
        top1 = sorted_lt.iloc[0]['pnl']
        top3 = sorted_lt.head(3)['pnl'].sum()
        top5 = sorted_lt.head(5)['pnl'].sum()
        bucket_net = long_bucket['pnl'].sum()
        print(f"  Concentracion interna bucket >150m:")
        print(f"    Top 1 trade: ${top1:>+.0f}  ({top1/bucket_net*100:.0f}% del bucket)")
        print(f"    Top 3 trades: ${top3:>+.0f}  ({top3/bucket_net*100:.0f}% del bucket)")
        print(f"    Top 5 trades: ${top5:>+.0f}  ({top5/bucket_net*100:.0f}% del bucket)")
        print(f"    Distribucion P&L bucket >150m:")
        print(f"      p5={np.percentile(long_bucket['pnl'],5):>+.1f}  p25={np.percentile(long_bucket['pnl'],25):>+.1f}  "
              f"p50={np.percentile(long_bucket['pnl'],50):>+.1f}  p75={np.percentile(long_bucket['pnl'],75):>+.1f}  "
              f"p95={np.percentile(long_bucket['pnl'],95):>+.1f}")

# =====================================================================
# RESUMEN EJECUTIVO
# =====================================================================
print("\n\n" + "=" * 68)
print("  RESUMEN EJECUTIVO — 3 ESTUDIOS")
print("=" * 68)

oos = data['OOS']
wfa = data['WFA']
is_ = data['IS']

# SessionEnd sensitivity
oos_kept_165 = oos[oos['hold_min'] <= 165]
oos_kept_full = oos

# Long/Short OOS
oos_long  = metrics(oos[oos['dir'] == 'buy'])
oos_short = metrics(oos[oos['dir'] == 'sell'])
wfa_long  = metrics(wfa[wfa['dir'] == 'buy'])
wfa_short = metrics(wfa[wfa['dir'] == 'sell'])

# Concentracion OOS
oos_bucket = oos[oos['hold_min'] >= 150]
oos_rest   = oos[oos['hold_min'] < 150]

print(f"""
[1] SESSIONEND — sensibilidad critica
    OOS con SessionEnd 15 min antes (umbral 165m): PF={metrics(oos_kept_165).get('PF','?')} | Net=${oos_kept_165['pnl'].sum():+.0f}
    OOS sin limite de sesion:                      PF={metrics(oos_kept_full).get('PF','?')} | Net=${oos_kept_full['pnl'].sum():+.0f}
    -> Movimiento de SessionEnd afecta directamente al bucket que genera el 100% del edge.
    -> NECESARIO: reoptimizar SessionEnd_Hour en MT5 (test 16:00–18:00 UTC).

[2] LONG vs SHORT
    OOS — LONG:  PF={oos_long.get('PF','?')} | Net=${oos_long.get('Net',0):+.0f}
    OOS — SHORT: PF={oos_short.get('PF','?')} | Net=${oos_short.get('Net',0):+.0f}
    WFA — LONG:  PF={wfa_long.get('PF','?')} | Net=${wfa_long.get('Net',0):+.0f}
    WFA — SHORT: PF={wfa_short.get('PF','?')} | Net=${wfa_short.get('Net',0):+.0f}

[3] CONCENTRACION DEL EDGE
    OOS bucket >150m: Net=${oos_bucket['pnl'].sum():+.0f} ({oos_bucket['pnl'].sum()/oos['pnl'].sum()*100:.0f}% del total OOS)
    OOS bucket <150m: Net=${oos_rest['pnl'].sum():+.0f}  ({oos_rest['pnl'].sum()/oos['pnl'].sum()*100:.0f}% del total OOS)
    -> El edge esta TOTALMENTE concentrado en cierres de sesion.
    -> Trades rapidos (<150m) son sistematicamente perdedores.
""")
