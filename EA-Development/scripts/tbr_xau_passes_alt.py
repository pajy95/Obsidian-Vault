"""
Analisis de passes alternativos — TBR XAUUSD
Busca passes fuera del pico Min=45 con edge robusto y DD bajo
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import xml.etree.ElementTree as ET
import pandas as pd, numpy as np, warnings
warnings.filterwarnings('ignore')

XML = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\XAUUSD\TBR_V1B_OP_XAUUSD_M5.xml"
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
for col in ['Forward Result','Back Result','Equity DD %','Trades',
            'RangeCandlesCount','SessionStart_Min','RR','Pass']:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

df['score'] = df['Forward Result'] / (1 + df['Equity DD %'] / 100)

# ── Top passes excluyendo Min=45 ──────────────────────────────────────────────
print("=" * 70)
print("PASSES ALTERNATIVOS — Min != 45 (excluye el pico)")
print("=" * 70)

alt = df[
    (df['SessionStart_Min'] != 45) &
    (df['Forward Result'] >= 1.20) &
    (df['Equity DD %'] <= 10.0) &
    (df['Trades'] >= 30)
].copy().nlargest(15, 'score')

print(f"\n  Top 15 con Min!=45, FwdPF>=1.20, DD<=10%: {len(alt)} encontrados")
print(f"  {'#':>3} {'Pass':>6} {'FwdPF':>7} {'BackPF':>7} {'T':>5} {'DD%':>6} "
      f"{'Cand':>5} {'Min':>5} {'RR':>5} {'Score':>7}")
print("  " + "-"*65)
for rank, (_, r) in enumerate(alt.iterrows(), 1):
    marker = " <- CANDIDATO" if rank == 1 else ""
    print(f"  #{rank:<2} {int(r['Pass']):>6} {r['Forward Result']:>7.3f} {r['Back Result']:>7.3f} "
          f"{r['Trades']:>5.0f} {r['Equity DD %']:>5.2f}% {r['RangeCandlesCount']:>5.0f} "
          f"{r['SessionStart_Min']:>5.0f} {r['RR']:>5.1f} {r['score']:>7.3f}{marker}")

# ── Mejor pass por cada Min ───────────────────────────────────────────────────
print(f"\n{'='*70}")
print("MEJOR PASS POR CADA SessionStart_Min")
print(f"{'='*70}")
print(f"  {'Min':>5} {'FwdPF_max':>10} {'DD%':>7} {'Cand':>5} {'RR':>5} {'Pass':>7}")
print("  " + "-"*50)
for min_val in sorted(df['SessionStart_Min'].dropna().unique()):
    sub = df[df['SessionStart_Min'] == min_val]
    best = sub.loc[sub['score'].idxmax()]
    flag = 'OK' if best['Forward Result'] >= 1.30 else ('~' if best['Forward Result'] >= 1.20 else 'xx')
    marker = " <- P1 (pico)" if min_val == 45 else ""
    print(f"  [{flag}] {min_val:>4.0f} {best['Forward Result']:>10.3f} "
          f"{best['Equity DD %']:>6.2f}% {best['RangeCandlesCount']:>5.0f} "
          f"{best['RR']:>5.1f} {int(best['Pass']):>7}{marker}")

# ── Cluster alternativo con plateau potencial ─────────────────────────────────
print(f"\n{'='*70}")
print("CLUSTER ALTERNATIVO — Min en zona 20-30 (meseta potencial)")
print(f"{'='*70}")
for cand in [2, 3, 5, 8]:
    sub = df[
        (df['RangeCandlesCount'] == cand) &
        (df['SessionStart_Min'].isin([20, 25, 30])) &
        (df['Forward Result'] >= 1.20)
    ]
    if len(sub) == 0:
        continue
    print(f"\n  Candles={cand}:")
    print(f"  {'Min':>5} {'RR':>5} {'FwdPF':>7} {'BackPF':>7} {'DD%':>6} {'T':>5}")
    for _, r in sub.sort_values(['SessionStart_Min', 'RR']).iterrows():
        flag = 'OK' if r['Forward Result'] >= 1.30 else '~'
        print(f"  [{flag}] {r['SessionStart_Min']:>5.0f} {r['RR']:>5.1f} "
              f"{r['Forward Result']:>7.3f} {r['Back Result']:>7.3f} "
              f"{r['Equity DD %']:>5.2f}% {r['Trades']:>5.0f}")

# ── Analisis de plateau para el mejor alternativo ─────────────────────────────
if len(alt) > 0:
    p2 = alt.iloc[0]
    p2_cand = int(p2['RangeCandlesCount'])
    p2_min  = int(p2['SessionStart_Min'])
    p2_rr   = float(p2['RR'])

    print(f"\n{'='*70}")
    print(f"PLATEAU DEL MEJOR ALTERNATIVO (Cand={p2_cand}, Min={p2_min}, RR={p2_rr})")
    print(f"{'='*70}")

    # Variar RR
    print(f"\n  A) Variar RR (Cand={p2_cand}, Min={p2_min}):")
    sub_a = df[(df['RangeCandlesCount'] == p2_cand) & (df['SessionStart_Min'] == p2_min)]
    grp_a = sub_a.groupby('RR')['Forward Result'].max().reset_index()
    for _, r in grp_a.sort_values('RR').iterrows():
        marker = " <- P2" if abs(r['RR'] - p2_rr) < 0.01 else ""
        flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.20 else 'xx')
        print(f"  [{flag}] RR={r['RR']:>4.1f}  FwdPF={r['Forward Result']:.3f}{marker}")

    # Variar Min
    print(f"\n  B) Variar SessionStart_Min (Cand={p2_cand}, RR={p2_rr}):")
    sub_b = df[(df['RangeCandlesCount'] == p2_cand) & (abs(df['RR'] - p2_rr) < 0.01)]
    grp_b = sub_b.groupby('SessionStart_Min')['Forward Result'].max().reset_index()
    for _, r in grp_b.sort_values('SessionStart_Min').iterrows():
        marker = " <- P2" if r['SessionStart_Min'] == p2_min else ""
        flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.20 else 'xx')
        print(f"  [{flag}] Min={r['SessionStart_Min']:>4.0f}  FwdPF={r['Forward Result']:.3f}{marker}")

    # Variar Candles
    print(f"\n  C) Variar RangeCandlesCount (Min={p2_min}, RR={p2_rr}):")
    sub_c = df[(df['SessionStart_Min'] == p2_min) & (abs(df['RR'] - p2_rr) < 0.01)]
    grp_c = sub_c.groupby('RangeCandlesCount')['Forward Result'].max().reset_index()
    for _, r in grp_c.sort_values('RangeCandlesCount').iterrows():
        marker = " <- P2" if r['RangeCandlesCount'] == p2_cand else ""
        flag = 'OK' if r['Forward Result'] >= 1.30 else ('~' if r['Forward Result'] >= 1.20 else 'xx')
        print(f"  [{flag}] Cand={r['RangeCandlesCount']:>3.0f}  FwdPF={r['Forward Result']:.3f}{marker}")

    print(f"\n{'='*70}")
    print(f"RESUMEN — P2 CANDIDATO ALTERNATIVO")
    print(f"{'='*70}")
    print(f"  RangeCandlesCount : {p2_cand}")
    print(f"  SessionStart_Min  : {p2_min}")
    print(f"  RR                : {p2_rr}")
    print(f"  FwdPF             : {p2['Forward Result']:.3f}")
    print(f"  BackPF            : {p2['Back Result']:.3f}")
    print(f"  Equity DD%        : {p2['Equity DD %']:.2f}%")
    print(f"  Trades            : {p2['Trades']:.0f}")
    print(f"  Pass #            : {int(p2['Pass'])}")
    print(f"\n  Para evaluar: correr IS+OOS con estos parametros")
    print(f"  Si plateau confirma robustez en Min -> candidato serio")
