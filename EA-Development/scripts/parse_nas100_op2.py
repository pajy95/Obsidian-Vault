# -*- coding: utf-8 -*-
"""
Analisis profundo NAS100 — meseta BOTH BREAKOUT + comparativa LONG vs BOTH
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import xml.etree.ElementTree as ET
import pandas as pd
import numpy as np

NS   = 'urn:schemas-microsoft-com:office:spreadsheet'
PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\op TBR NAS.xml100 M5.xml"

def parse_spreadsheetml(path):
    tree = ET.parse(path)
    root = tree.getroot()
    ws   = root.find(f'{{{NS}}}Worksheet')
    table= ws.find(f'{{{NS}}}Table')
    rows = table.findall(f'{{{NS}}}Row')
    data = []
    for row in rows:
        cells = row.findall(f'{{{NS}}}Cell')
        data.append([c.find(f'{{{NS}}}Data').text if c.find(f'{{{NS}}}Data') is not None else None
                     for c in cells])
    headers = data[0]
    records = []
    for row in data[1:]:
        while len(row) < len(headers): row.append(None)
        records.append(dict(zip(headers, row)))
    return pd.DataFrame(records)

print("Cargando XML...")
df = parse_spreadsheetml(PATH)
NUM = ['Forward Result','Back Result','Profit Factor','Equity DD %','Trades',
       'TradeDirection','EntryMode','RangeCandlesCount','SessionStart_Min',
       'SessionEnd_Hour','RR','BE_TriggerRR','Sharpe Ratio']
for c in NUM:
    if c in df.columns: df[c] = pd.to_numeric(df[c], errors='coerce')
df['Dir']  = df['TradeDirection'].map({0:'LONG',1:'SHORT',2:'BOTH'})
df['Mode'] = df['EntryMode'].map({0:'CONFIRM',1:'BREAKOUT'})
df_f = df[df['Trades'] >= 40].copy()

top_both = df_f[(df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT')].sort_values('Forward Result', ascending=False)
top_long = df_f[(df_f['Dir']=='LONG') & (df_f['Mode']=='BREAKOUT')].sort_values('Forward Result', ascending=False)

# -----------------------------------------------------------------------
print("\n" + "="*65)
print("  MESETA BOTH BREAKOUT — TOP PASS #25390")
print("  Candles=1, Min=25, RR=5.4, BE=0.25")
print("="*65)
top = top_both.iloc[0]
print(f"Top: Forward={top['Forward Result']:.4f} Back={top['Back Result']:.4f} "
      f"PF={top['Profit Factor']:.4f} DD={top['Equity DD %']:.2f}% Trades={int(top['Trades'])}")

# Meseta RR
nb_rr = df_f[
    (df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT') &
    (df_f['RangeCandlesCount']==top['RangeCandlesCount']) &
    (df_f['SessionStart_Min']==top['SessionStart_Min']) &
    (df_f['SessionEnd_Hour']==top['SessionEnd_Hour']) &
    (df_f['BE_TriggerRR']==top['BE_TriggerRR'])
].sort_values('RR')
print(f"\nMeseta RR (Candles=1 Min=25 EndH=19 BE=0.25):")
print(nb_rr[['RR','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# Meseta SessionEnd
nb_end = df_f[
    (df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT') &
    (df_f['RangeCandlesCount']==top['RangeCandlesCount']) &
    (df_f['SessionStart_Min']==top['SessionStart_Min']) &
    (df_f['RR']==top['RR']) &
    (df_f['BE_TriggerRR']==top['BE_TriggerRR'])
].sort_values('SessionEnd_Hour')
print(f"\nMeseta SessionEnd_Hour (Candles=1 Min=25 RR=5.4 BE=0.25):")
print(nb_end[['SessionEnd_Hour','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# Meseta Candles
nb_can = df_f[
    (df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT') &
    (df_f['SessionStart_Min']==top['SessionStart_Min']) &
    (df_f['SessionEnd_Hour']==top['SessionEnd_Hour']) &
    (df_f['RR']==top['RR']) &
    (df_f['BE_TriggerRR']==top['BE_TriggerRR'])
].sort_values('RangeCandlesCount')
print(f"\nMeseta Candles (Min=25 EndH=19 RR=5.4 BE=0.25):")
print(nb_can[['RangeCandlesCount','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# Meseta Min
nb_min = df_f[
    (df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT') &
    (df_f['RangeCandlesCount']==top['RangeCandlesCount']) &
    (df_f['SessionEnd_Hour']==top['SessionEnd_Hour']) &
    (df_f['RR']==top['RR']) &
    (df_f['BE_TriggerRR']==top['BE_TriggerRR'])
].sort_values('SessionStart_Min')
print(f"\nMeseta SessionStart_Min (Candles=1 EndH=19 RR=5.4 BE=0.25):")
print(nb_min[['SessionStart_Min','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# Meseta BE
nb_be = df_f[
    (df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT') &
    (df_f['RangeCandlesCount']==top['RangeCandlesCount']) &
    (df_f['SessionStart_Min']==top['SessionStart_Min']) &
    (df_f['SessionEnd_Hour']==top['SessionEnd_Hour']) &
    (df_f['RR']==top['RR'])
].sort_values('BE_TriggerRR')
print(f"\nMeseta BE_TriggerRR (Candles=1 Min=25 EndH=19 RR=5.4):")
print(nb_be[['BE_TriggerRR','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# -----------------------------------------------------------------------
print("\n" + "="*65)
print("  MESETA LONG BREAKOUT — TOP PASS #58421")
print("  Candles=4, Min=10, EndH=19, RR=5.8, BE=0.5")
print("="*65)
top_l = top_long.iloc[0]

# Meseta Candles LONG
nb_can_l = df_f[
    (df_f['Dir']=='LONG') & (df_f['Mode']=='BREAKOUT') &
    (df_f['SessionStart_Min']==top_l['SessionStart_Min']) &
    (df_f['SessionEnd_Hour']==top_l['SessionEnd_Hour']) &
    (df_f['RR']==top_l['RR']) &
    (df_f['BE_TriggerRR']==top_l['BE_TriggerRR'])
].sort_values('RangeCandlesCount')
print(f"\nMeseta Candles LONG (Min=10 EndH=19 RR=5.8 BE=0.5):")
print(nb_can_l[['RangeCandlesCount','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# Meseta Min LONG
nb_min_l = df_f[
    (df_f['Dir']=='LONG') & (df_f['Mode']=='BREAKOUT') &
    (df_f['RangeCandlesCount']==top_l['RangeCandlesCount']) &
    (df_f['SessionEnd_Hour']==top_l['SessionEnd_Hour']) &
    (df_f['RR']==top_l['RR']) &
    (df_f['BE_TriggerRR']==top_l['BE_TriggerRR'])
].sort_values('SessionStart_Min')
print(f"\nMeseta Min LONG (Candles=4 EndH=19 RR=5.8 BE=0.5):")
print(nb_min_l[['SessionStart_Min','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# -----------------------------------------------------------------------
print("\n" + "="*65)
print("  COMPARATIVA FINAL — CANDIDATOS")
print("="*65)
print(f"\n{'Candidato':<28} {'Fwd':>6} {'Bck':>6} {'PF':>6} {'DD%':>6} {'Trades':>7} {'Params'}")
print(f"{'-'*80}")

candidates = [
    ("BOTH BRKOUT #25390",   top_both.iloc[0]),
    ("LONG BRKOUT #58421",   top_long.iloc[0]),
    ("BOTH BRKOUT #25750",   top_both.iloc[1]),
    ("LONG BRKOUT #58781",   top_long.iloc[1]),
]
for name, row in candidates:
    print(f"{name:<28} {row['Forward Result']:>6.3f} {row['Back Result']:>6.3f} "
          f"{row['Profit Factor']:>6.3f} {row['Equity DD %']:>6.2f} {int(row['Trades']):>7}  "
          f"C={int(row['RangeCandlesCount'])} Min={int(row['SessionStart_Min'])} "
          f"H={int(row['SessionEnd_Hour'])} RR={row['RR']} BE={row['BE_TriggerRR']}")

# -----------------------------------------------------------------------
print("\n" + "="*65)
print("  ROBUSTED DEL ESPACIO BOTH — distribucion general Forward")
print("="*65)
both_br = df_f[(df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT')]['Forward Result']
long_br = df_f[(df_f['Dir']=='LONG') & (df_f['Mode']=='BREAKOUT')]['Forward Result']
print(f"\nBOTH BREAKOUT (n={len(both_br)}):")
for p in [5,25,50,75,90,95]:
    print(f"  p{p:>2}: {np.percentile(both_br,p):.4f}")
print(f"\nLONG BREAKOUT (n={len(long_br)}):")
for p in [5,25,50,75,90,95]:
    print(f"  p{p:>2}: {np.percentile(long_br,p):.4f}")
print(f"\n% passes BOTH con Forward > 1.40: {(both_br > 1.40).mean():.1%}")
print(f"% passes LONG con Forward > 1.40: {(long_br > 1.40).mean():.1%}")
print(f"% passes BOTH con Forward > 1.20: {(both_br > 1.20).mean():.1%}")
print(f"% passes LONG con Forward > 1.20: {(long_br > 1.20).mean():.1%}")
