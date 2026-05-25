"""
Robustez Parametrica — TBR v1.0b P63 L/M/X NAS100
Analiza el paisaje de PF alrededor de P63 usando el XML de optimizacion Fase 1
Verifica plateau vs pico
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import xml.etree.ElementTree as ET
import pandas as pd, numpy as np, warnings
warnings.filterwarnings('ignore')

XML = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\NAS100\TBR B V1.xml"
ns_ss = 'urn:schemas-microsoft-com:office:spreadsheet'
ns_o  = 'urn:schemas-microsoft-com:office:office'

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
            'Trades','RangeCandlesCount','SessionStart_Min','RR','Pass']:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

# Parametros P63 de referencia
P63_CANDLES = 2
P63_MIN     = 15
P63_RR      = 4.0

print("=" * 65)
print("ROBUSTEZ PARAMETRICA — TBR v1.0b P63 L/M/X NAS100")
print(f"Referencia P63: Candles={P63_CANDLES}, StartMin={P63_MIN}, RR={P63_RR}")
print("=" * 65)
print(f"\nTotal passes en XML: {len(df)}")
print(f"Columnas: {[c for c in df.columns if not c.startswith('unnamed')]}")

# ── Tabla completa alrededor de P63 ──────────────────────────────────────
print("\n" + "-"*65)
print("PAISAJE COMPLETO DE PARAMETROS (Fwd PF = OOS del WF interno)")
print("-"*65)
print(f"  {'Cand':>5} {'Min':>5} {'RR':>5} {'FwdPF':>7} {'BackPF':>7} "
      f"{'Trades':>7} {'DD%':>6}  Ref")
print("  " + "-"*55)

df_s = df.sort_values(['RangeCandlesCount','SessionStart_Min','RR'])
for _, r in df_s.iterrows():
    candles = r.get('RangeCandlesCount', float('nan'))
    min_v   = r.get('SessionStart_Min',  float('nan'))
    rr_v    = r.get('RR',                float('nan'))
    fwd     = r.get('Forward Result',    float('nan'))
    back    = r.get('Back Result',       float('nan'))
    trades  = r.get('Trades',            float('nan'))
    dd      = r.get('Equity DD %',       float('nan'))
    is_p63  = (candles == P63_CANDLES and min_v == P63_MIN and abs(rr_v - P63_RR) < 0.01)
    marker  = " <- P63" if is_p63 else ""
    flag    = 'OK' if fwd >= 1.30 else ('~' if fwd >= 1.10 else 'xx')
    print(f"  [{flag}] {candles:>4.0f} {min_v:>5.0f} {rr_v:>5.1f} "
          f"{fwd:>7.3f} {back:>7.3f} {trades:>7.0f} {dd:>5.2f}%{marker}")

# ── Analisis de plateau por dimension ────────────────────────────────────
print("\n" + "-"*65)
print("ANALISIS DE PLATEAU POR PARAMETRO (fijando los otros 2 en P63)")
print("-"*65)

# Variar RR con Candles=P63_CANDLES, Min=P63_MIN
print(f"\n  A) Variar RR (Candles={P63_CANDLES}, Min={P63_MIN} fijos):")
sub = df[(df['RangeCandlesCount']==P63_CANDLES) & (df['SessionStart_Min']==P63_MIN)]
if len(sub) > 0:
    print(f"  {'RR':>5} {'FwdPF':>7} {'BackPF':>7} {'Trades':>7}")
    for _, r in sub.sort_values('RR').iterrows():
        marker = " <- P63" if abs(r['RR']-P63_RR)<0.01 else ""
        flag = 'OK' if r['Forward Result']>=1.30 else ('~' if r['Forward Result']>=1.10 else 'xx')
        print(f"  [{flag}] {r['RR']:>5.1f} {r['Forward Result']:>7.3f} "
              f"{r['Back Result']:>7.3f} {r['Trades']:>7.0f}{marker}")

# Variar SessionStart_Min con Candles=P63_CANDLES, RR=P63_RR
print(f"\n  B) Variar SessionStart_Min (Candles={P63_CANDLES}, RR={P63_RR} fijos):")
sub2 = df[(df['RangeCandlesCount']==P63_CANDLES) & (abs(df['RR']-P63_RR)<0.01)]
if len(sub2) > 0:
    print(f"  {'Min':>5} {'FwdPF':>7} {'BackPF':>7} {'Trades':>7}")
    for _, r in sub2.sort_values('SessionStart_Min').iterrows():
        marker = " <- P63" if r['SessionStart_Min']==P63_MIN else ""
        flag = 'OK' if r['Forward Result']>=1.30 else ('~' if r['Forward Result']>=1.10 else 'xx')
        print(f"  [{flag}] {r['SessionStart_Min']:>5.0f} {r['Forward Result']:>7.3f} "
              f"{r['Back Result']:>7.3f} {r['Trades']:>7.0f}{marker}")

# Variar RangeCandlesCount con Min=P63_MIN, RR=P63_RR
print(f"\n  C) Variar RangeCandlesCount (Min={P63_MIN}, RR={P63_RR} fijos):")
sub3 = df[(df['SessionStart_Min']==P63_MIN) & (abs(df['RR']-P63_RR)<0.01)]
if len(sub3) > 0:
    print(f"  {'Cand':>5} {'FwdPF':>7} {'BackPF':>7} {'Trades':>7}")
    for _, r in sub3.sort_values('RangeCandlesCount').iterrows():
        marker = " <- P63" if r['RangeCandlesCount']==P63_CANDLES else ""
        flag = 'OK' if r['Forward Result']>=1.30 else ('~' if r['Forward Result']>=1.10 else 'xx')
        print(f"  [{flag}] {r['RangeCandlesCount']:>5.0f} {r['Forward Result']:>7.3f} "
              f"{r['Back Result']:>7.3f} {r['Trades']:>7.0f}{marker}")

# ── Stress test ±20% ──────────────────────────────────────────────────────
print("\n" + "-"*65)
print("STRESS TEST: passes con FwdPF >= 1.20 (zona de viabilidad)")
print("-"*65)
viable = df[df['Forward Result'] >= 1.20]
total  = len(df)
pct    = len(viable)/total*100
print(f"\n  Passes con FwdPF >= 1.20: {len(viable)}/{total} ({pct:.0f}%)")
print(f"  Passes con FwdPF >= 1.30: {(df['Forward Result']>=1.30).sum()}/{total} "
      f"({(df['Forward Result']>=1.30).mean()*100:.0f}%)")
print(f"  Passes con FwdPF >= 1.00: {(df['Forward Result']>=1.00).sum()}/{total} "
      f"({(df['Forward Result']>=1.00).mean()*100:.0f}%)")

fwd_p63_row = df[(df['RangeCandlesCount']==P63_CANDLES) &
                 (df['SessionStart_Min']==P63_MIN) &
                 (abs(df['RR']-P63_RR)<0.01)]
if len(fwd_p63_row) > 0:
    p63_fwd = fwd_p63_row.iloc[0]['Forward Result']
    rank = (df['Forward Result'] > p63_fwd).sum() + 1
    print(f"\n  P63 FwdPF={p63_fwd:.3f} — ranking #{rank} de {total} passes")

# ── Veredicto robustez ────────────────────────────────────────────────────
print("\n" + "="*65)
print("VEREDICTO ROBUSTEZ")
print("="*65)

if len(fwd_p63_row) > 0:
    p63_fwd = fwd_p63_row.iloc[0]['Forward Result']
    p63_back = fwd_p63_row.iloc[0]['Back Result']

    # Verificar plateau: passes vecinos con FwdPF >= P63_FWD * 0.85
    threshold = p63_fwd * 0.85
    neighbors_ok = (df['Forward Result'] >= threshold).sum()

    checks = [
        (pct >= 30,            f">=30% passes con FwdPF>=1.20",        f"{pct:.0f}%"),
        (p63_fwd >= 1.30,      f"P63 FwdPF >= 1.30",                   f"{p63_fwd:.3f}"),
        (p63_back >= 1.00,     f"P63 BackPF >= 1.00 (no overfitting)",  f"{p63_back:.3f}"),
        (neighbors_ok >= 3,    f">=3 passes en ±15% de P63 FwdPF",     f"{neighbors_ok}"),
    ]
    ok = sum(1 for c,_,_ in checks if c)
    for cond, lbl, val in checks:
        print(f"  [{'OK' if cond else 'XX'}] {lbl:<40} {val:>8}")
    verdict = "PLATEAU (robusto)" if ok>=3 else ("MESETA DEBIL" if ok>=2 else "PICO (fragil)")
    print(f"\n  VEREDICTO: {verdict} ({ok}/4)")
