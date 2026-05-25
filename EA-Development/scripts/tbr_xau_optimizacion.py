"""
Analisis de Optimizacion — TBR v1.0b XAUUSD M5
Parametros optimizados: RangeCandlesCount, SessionStart_Min, RR, UseBreakeven, BE_TriggerRR
Periodo IS: 2022-2025 (Walk-Forward interno del MT5)
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import xml.etree.ElementTree as ET
import pandas as pd, numpy as np, warnings
warnings.filterwarnings('ignore')

XML = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\TBR V1B OP XAU M5 .xml"
ns_ss = 'urn:schemas-microsoft-com:office:spreadsheet'

tree = ET.parse(XML); root = tree.getroot()
rows = root.findall(f'.//{{{ns_ss}}}Worksheet/{{{ns_ss}}}Table/{{{ns_ss}}}Row')

headers = []
for cell in rows[0].findall(f'{{{ns_ss}}}Cell'):
    d = cell.find(f'{{{ns_ss}}}Data')
    headers.append(d.text if d is not None else '')

records = []
for row in rows[1:]:
    cells = row.findall(f'{{{ns_ss}}}Cell')
    vals = [c.find(f'{{{ns_ss}}}Data') for c in cells]
    vals = [v.text if v is not None else None for v in vals]
    if len(vals) < len(headers) or vals[0] is None: continue
    rec = {}
    for i, h in enumerate(headers):
        try: rec[h] = float(vals[i])
        except: rec[h] = vals[i]
    records.append(rec)

df = pd.DataFrame(records)
for col in ['Forward Result','Back Result','Profit Factor','Equity DD %',
            'Trades','RangeCandlesCount','SessionStart_Min','RR',
            'UseBreakeven','BE_TriggerRR','Pass','Profit']:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

print("=" * 70)
print("OPTIMIZACION TBR v1.0b — XAUUSD M5 (IS 2022-2025)")
print("=" * 70)
print(f"\nTotal passes: {len(df)}")
print(f"Columnas: {list(df.columns)}")

# ── Estadisticas generales ────────────────────────────────────────────────────
fwd = df['Forward Result'].dropna()
back = df['Back Result'].dropna()
print(f"\n{'Metrica':<25} {'Min':>8} {'P25':>8} {'P50':>8} {'P75':>8} {'Max':>8}")
print("-" * 65)
for col, label in [('Forward Result','FwdPF (OOS WF)'),('Back Result','BackPF (IS WF)'),
                   ('Equity DD %','Equity DD%'),('Trades','Trades')]:
    s = df[col].dropna()
    print(f"  {label:<23} {s.min():>8.3f} {s.quantile(.25):>8.3f} "
          f"{s.median():>8.3f} {s.quantile(.75):>8.3f} {s.max():>8.3f}")

# ── Distribucion de viabilidad ────────────────────────────────────────────────
total = len(df)
print(f"\n{'Umbral FwdPF':<20} {'Passes':>8} {'%':>8}")
print("-" * 40)
for thr in [1.0, 1.1, 1.2, 1.3, 1.4, 1.5]:
    n = (df['Forward Result'] >= thr).sum()
    print(f"  >= {thr:.1f}              {n:>8}  {n/total*100:>7.1f}%")

# ── TOP 20 passes por FwdPF ───────────────────────────────────────────────────
print(f"\n{'='*70}")
print("TOP 20 PASSES POR FwdPF (OOS Walk-Forward)")
print(f"{'='*70}")
print(f"  {'#':>4} {'Pass':>6} {'FwdPF':>7} {'BackPF':>7} {'Trades':>7} "
      f"{'DD%':>6} {'Cand':>5} {'Min':>5} {'RR':>5} {'BE':>4} {'BETrg':>6}")
print("  " + "-"*68)

top20 = df.nlargest(20, 'Forward Result')
for rank, (_, r) in enumerate(top20.iterrows(), 1):
    be_str = 'ON' if r.get('UseBreakeven', 0) == 1 else 'OFF'
    flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.10 else 'xx')
    print(f"  [{flag}] #{rank:<2} {int(r['Pass']):>5} {r['Forward Result']:>7.3f} "
          f"{r['Back Result']:>7.3f} {r['Trades']:>7.0f} {r['Equity DD %']:>5.2f}% "
          f"{r['RangeCandlesCount']:>5.0f} {r['SessionStart_Min']:>5.0f} {r['RR']:>5.1f} "
          f"{be_str:>4} {r['BE_TriggerRR']:>6.2f}")

# ── Analisis por parametro ────────────────────────────────────────────────────
print(f"\n{'='*70}")
print("PAISAJE POR PARAMETRO — Media de FwdPF agrupada")
print(f"{'='*70}")

# RangeCandlesCount
print(f"\n  A) RangeCandlesCount:")
grp = df.groupby('RangeCandlesCount')['Forward Result'].agg(['mean','max','count'])
for val, row in grp.iterrows():
    flag = 'OK' if row['mean'] >= 1.20 else ('~' if row['mean'] >= 1.0 else 'xx')
    print(f"  [{flag}] Candles={val:.0f}  media={row['mean']:.3f}  max={row['max']:.3f}  n={row['count']:.0f}")

# SessionStart_Min
print(f"\n  B) SessionStart_Min:")
grp2 = df.groupby('SessionStart_Min')['Forward Result'].agg(['mean','max','count'])
for val, row in grp2.iterrows():
    flag = 'OK' if row['mean'] >= 1.20 else ('~' if row['mean'] >= 1.0 else 'xx')
    print(f"  [{flag}] Min={val:.0f}    media={row['mean']:.3f}  max={row['max']:.3f}  n={row['count']:.0f}")

# RR
print(f"\n  C) RR:")
grp3 = df.groupby('RR')['Forward Result'].agg(['mean','max','count'])
for val, row in grp3.iterrows():
    flag = 'OK' if row['mean'] >= 1.20 else ('~' if row['mean'] >= 1.0 else 'xx')
    print(f"  [{flag}] RR={val:.1f}     media={row['mean']:.3f}  max={row['max']:.3f}  n={row['count']:.0f}")

# UseBreakeven
print(f"\n  D) UseBreakeven:")
grp4 = df.groupby('UseBreakeven')['Forward Result'].agg(['mean','max','count'])
for val, row in grp4.iterrows():
    be_str = 'ON' if val == 1 else 'OFF'
    flag = 'OK' if row['mean'] >= 1.20 else ('~' if row['mean'] >= 1.0 else 'xx')
    print(f"  [{flag}] BE={be_str}    media={row['mean']:.3f}  max={row['max']:.3f}  n={row['count']:.0f}")

# BE_TriggerRR
print(f"\n  E) BE_TriggerRR (solo passes con UseBreakeven=ON):")
df_be_on = df[df['UseBreakeven'] == 1]
if len(df_be_on) > 0:
    grp5 = df_be_on.groupby('BE_TriggerRR')['Forward Result'].agg(['mean','max','count'])
    for val, row in grp5.iterrows():
        flag = 'OK' if row['mean'] >= 1.20 else ('~' if row['mean'] >= 1.0 else 'xx')
        print(f"  [{flag}] BETrg={val:.2f}  media={row['mean']:.3f}  max={row['max']:.3f}  n={row['count']:.0f}")
else:
    print("  (no hay passes con BE=ON)")

# ── Identificar pass optimo (top candidate) ────────────────────────────────────
print(f"\n{'='*70}")
print("CANDIDATOS P1 / PASS OPTIMO")
print(f"{'='*70}")

# Criterios de filtro: FwdPF >= 1.30, DD <= 15%, Trades >= 30
viable = df[(df['Forward Result'] >= 1.30) &
            (df['Equity DD %'] <= 15.0) &
            (df['Trades'] >= 30)].copy()
print(f"\n  Passes con FwdPF>=1.30, DD<=15%, Trades>=30: {len(viable)}")

if len(viable) > 0:
    # Score: FwdPF ponderado y DD penalizado
    viable['score'] = viable['Forward Result'] / (1 + viable['Equity DD %'] / 100)
    top_candidates = viable.nlargest(10, 'score')

    print(f"\n  Top 10 candidatos (score = FwdPF / (1 + DD%)):")
    print(f"  {'#':>3} {'Pass':>6} {'FwdPF':>7} {'BackPF':>7} {'Trades':>7} "
          f"{'DD%':>6} {'Cand':>5} {'Min':>5} {'RR':>5} {'BE':>4} {'BETrg':>6} {'Score':>7}")
    print("  " + "-"*75)
    for rank, (_, r) in enumerate(top_candidates.iterrows(), 1):
        be_str = 'ON' if r.get('UseBreakeven', 0) == 1 else 'OFF'
        marker = " <-- P1" if rank == 1 else ""
        print(f"  #{rank:<2} {int(r['Pass']):>6} {r['Forward Result']:>7.3f} "
              f"{r['Back Result']:>7.3f} {r['Trades']:>7.0f} {r['Equity DD %']:>5.2f}% "
              f"{r['RangeCandlesCount']:>5.0f} {r['SessionStart_Min']:>5.0f} {r['RR']:>5.1f} "
              f"{be_str:>4} {r['BE_TriggerRR']:>6.2f} {r['score']:>7.3f}{marker}")

    # P1 — el mejor
    p1 = top_candidates.iloc[0]
    print(f"\n{'─'*70}")
    print(f"  PASS P1 (candidato principal):")
    print(f"  {'RangeCandlesCount':<20} = {p1['RangeCandlesCount']:.0f}")
    print(f"  {'SessionStart_Min':<20} = {p1['SessionStart_Min']:.0f}")
    print(f"  {'RR':<20} = {p1['RR']:.1f}")
    print(f"  {'UseBreakeven':<20} = {'ON' if p1['UseBreakeven']==1 else 'OFF'}")
    print(f"  {'BE_TriggerRR':<20} = {p1['BE_TriggerRR']:.2f}")
    print(f"  {'FwdPF (OOS WF)':<20} = {p1['Forward Result']:.3f}")
    print(f"  {'BackPF (IS WF)':<20} = {p1['Back Result']:.3f}")
    print(f"  {'Equity DD%':<20} = {p1['Equity DD %']:.2f}%")
    print(f"  {'Trades':<20} = {p1['Trades']:.0f}")

    # ── Plateau del P1 ────────────────────────────────────────────────────────
    print(f"\n{'='*70}")
    print("ANALISIS DE PLATEAU ALREDEDOR DE P1")
    print(f"{'='*70}")

    p1_cand = int(p1['RangeCandlesCount'])
    p1_min  = int(p1['SessionStart_Min'])
    p1_rr   = float(p1['RR'])
    p1_be   = int(p1['UseBreakeven']) if pd.notna(p1['UseBreakeven']) else 0
    p1_betr = float(p1['BE_TriggerRR']) if pd.notna(p1['BE_TriggerRR']) else 0.0

    # Detectar si UseBreakeven varia o no
    be_varia = df['UseBreakeven'].nunique(dropna=False) > 1 and df['UseBreakeven'].notna().any()
    be_varia_msg = "" if not be_varia else f", BE={'ON' if p1_be==1 else 'OFF'}"

    # A) Variar RR (Candles y Min fijos en P1, BE ignorado si no varia)
    print(f"\n  A) Variar RR (Cand={p1_cand}, Min={p1_min}{be_varia_msg}):")
    sub_a = df[(df['RangeCandlesCount'] == p1_cand) & (df['SessionStart_Min'] == p1_min)]
    # Agrupar por RR tomando el mejor FwdPF de cada valor (elimina ruido de BETrg cuando BE=OFF)
    grp_a = sub_a.groupby('RR')['Forward Result'].max().reset_index()
    if len(grp_a) > 0:
        print(f"  {'RR':>5} {'FwdPF_max':>10} {'Trades_med':>11}")
        trades_rr = sub_a.groupby('RR')['Trades'].median()
        for _, r in grp_a.sort_values('RR').iterrows():
            marker = " <- P1" if abs(r['RR'] - p1_rr) < 0.01 else ""
            flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.10 else 'xx')
            print(f"  [{flag}] {r['RR']:>5.1f} {r['Forward Result']:>10.3f} "
                  f"{trades_rr.get(r['RR'], 0):>11.0f}{marker}")

    # B) Variar SessionStart_Min (Candles y RR fijos en P1)
    print(f"\n  B) Variar SessionStart_Min (Cand={p1_cand}, RR={p1_rr:.1f}{be_varia_msg}):")
    sub_b = df[(df['RangeCandlesCount'] == p1_cand) & (abs(df['RR'] - p1_rr) < 0.01)]
    grp_b = sub_b.groupby('SessionStart_Min')['Forward Result'].max().reset_index()
    if len(grp_b) > 0:
        print(f"  {'Min':>5} {'FwdPF_max':>10}")
        for _, r in grp_b.sort_values('SessionStart_Min').iterrows():
            marker = " <- P1" if r['SessionStart_Min'] == p1_min else ""
            flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.10 else 'xx')
            print(f"  [{flag}] {r['SessionStart_Min']:>5.0f} {r['Forward Result']:>10.3f}{marker}")

    # C) Variar RangeCandlesCount (Min y RR fijos en P1)
    print(f"\n  C) Variar RangeCandlesCount (Min={p1_min}, RR={p1_rr:.1f}{be_varia_msg}):")
    sub_c = df[(df['SessionStart_Min'] == p1_min) & (abs(df['RR'] - p1_rr) < 0.01)]
    grp_c = sub_c.groupby('RangeCandlesCount')['Forward Result'].max().reset_index()
    if len(grp_c) > 0:
        print(f"  {'Cand':>5} {'FwdPF_max':>10}")
        for _, r in grp_c.sort_values('RangeCandlesCount').iterrows():
            marker = " <- P1" if r['RangeCandlesCount'] == p1_cand else ""
            flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.10 else 'xx')
            print(f"  [{flag}] {r['RangeCandlesCount']:>5.0f} {r['Forward Result']:>10.3f}{marker}")

    # D) Variar BE_TriggerRR (BE siempre OFF en este run — muestra que BETrg no afecta)
    print(f"\n  D) Variar BE_TriggerRR (Cand={p1_cand}, Min={p1_min}, RR={p1_rr:.1f}):")
    sub_d = df[(df['RangeCandlesCount'] == p1_cand) &
               (df['SessionStart_Min']  == p1_min) &
               (abs(df['RR'] - p1_rr)   < 0.01)]
    if len(sub_d) > 0:
        print(f"  {'BETrg':>6} {'FwdPF':>7} {'BackPF':>7} {'Trades':>7}  (BE siempre OFF)")
        for _, r in sub_d.sort_values('BE_TriggerRR').iterrows():
            betr = r['BE_TriggerRR'] if pd.notna(r['BE_TriggerRR']) else 0.0
            marker = " <- P1" if abs(betr - p1_betr) < 0.01 else ""
            flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.10 else 'xx')
            print(f"  [{flag}] {betr:>6.2f} {r['Forward Result']:>7.3f} "
                  f"{r['Back Result']:>7.3f} {r['Trades']:>7.0f}{marker}")

else:
    print(f"\n  ADVERTENCIA: Ningun pass supera los filtros minimos.")
    print(f"  Relajando criterios — FwdPF >= 1.20, DD <= 20%, Trades >= 20:")
    viable2 = df[(df['Forward Result'] >= 1.20) &
                 (df['Equity DD %'] <= 20.0) &
                 (df['Trades'] >= 20)].copy()
    print(f"  Passes viables con criterios relajados: {len(viable2)}")
    if len(viable2) > 0:
        top5 = viable2.nlargest(5, 'Forward Result')
        for _, r in top5.iterrows():
            be_str = 'ON' if r.get('UseBreakeven', 0) == 1 else 'OFF'
            print(f"  Pass={int(r['Pass'])} FwdPF={r['Forward Result']:.3f} BackPF={r['Back Result']:.3f} "
                  f"Cand={r['RangeCandlesCount']:.0f} Min={r['SessionStart_Min']:.0f} RR={r['RR']:.1f} "
                  f"BE={be_str} BETrg={r['BE_TriggerRR']:.2f}")

# ── Veredicto ─────────────────────────────────────────────────────────────────
print(f"\n{'='*70}")
print("VEREDICTO OPTIMIZACION XAU — PASO SIGUIENTE")
print(f"{'='*70}")

pct_1_0 = (df['Forward Result'] >= 1.00).mean() * 100
pct_1_2 = (df['Forward Result'] >= 1.20).mean() * 100
pct_1_3 = (df['Forward Result'] >= 1.30).mean() * 100
best_fwd = df['Forward Result'].max()
best_row = df.loc[df['Forward Result'].idxmax()]

print(f"\n  Landscape general:")
print(f"    Passes con FwdPF >= 1.00: {pct_1_0:.1f}%")
print(f"    Passes con FwdPF >= 1.20: {pct_1_2:.1f}%")
print(f"    Passes con FwdPF >= 1.30: {pct_1_3:.1f}%")
print(f"    Mejor FwdPF absoluto:     {best_fwd:.3f}")

if best_fwd >= 1.40:
    print(f"\n  [AVANZAR] Landscape muestra passes viables (FwdPF max={best_fwd:.3f})")
    print(f"  Siguiente paso: backtest IS (2022-2024) + OOS (2025) con P1")
elif best_fwd >= 1.20:
    print(f"\n  [MARGINAL] Landscape debil pero con edge potencial (FwdPF max={best_fwd:.3f})")
    print(f"  Siguiente paso: backtest IS+OOS para confirmar — no asumir viabilidad")
else:
    print(f"\n  [NO VIABLE] FwdPF maximo={best_fwd:.3f} — TBR no muestra edge en XAUUSD")
    print(f"  No proceder a backtest IS/OOS")
