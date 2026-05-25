# -*- coding: utf-8 -*-
"""
Busqueda de BOTH BREAKOUT robusto para NAS100.
Criterio: pass con meseta amplia en SessionStart_Min (al menos 3 valores vecinos > 1.40)
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
df_f = df[(df['Trades'] >= 40) & (df['Dir']=='BOTH') & (df['Mode']=='BREAKOUT')].copy()
print(f"BOTH BREAKOUT passes: {len(df_f)}")

# -----------------------------------------------------------------------
# Estrategia: para cada combinacion (Candles, EndH, RR, BE),
# contar cuantos valores de Min tienen Forward > 1.40
# Un pass es "robusto en Min" si al menos 3 valores de Min son > 1.40
# -----------------------------------------------------------------------
print("\nBuscando combinaciones con meseta amplia en SessionStart_Min...")

group_cols = ['RangeCandlesCount','SessionEnd_Hour','RR','BE_TriggerRR']
results = []

for key, grp in df_f.groupby(group_cols):
    candles, endh, rr, be = key
    # Cuantos Min distintos tienen Forward > 1.40
    good_mins = grp[grp['Forward Result'] > 1.40]['SessionStart_Min'].nunique()
    total_mins = grp['SessionStart_Min'].nunique()
    mean_fwd   = grp['Forward Result'].mean()
    max_fwd    = grp['Forward Result'].max()
    median_fwd = grp['Forward Result'].median()
    best_row   = grp.loc[grp['Forward Result'].idxmax()]

    results.append({
        'Candles': int(candles), 'EndH': int(endh),
        'RR': rr, 'BE': be,
        'good_mins': good_mins, 'total_mins': total_mins,
        'mean_fwd': round(mean_fwd,4), 'max_fwd': round(max_fwd,4),
        'median_fwd': round(median_fwd,4),
        'best_pass': int(best_row['Pass']),
        'best_min': int(best_row['SessionStart_Min']),
        'best_fwd': round(best_row['Forward Result'],4),
        'best_dd': round(best_row['Equity DD %'],2),
        'best_trades': int(best_row['Trades']),
    })

res = pd.DataFrame(results).sort_values(['good_mins','mean_fwd'], ascending=False)

print(f"\n{'C':>2} {'H':>3} {'RR':>4} {'BE':>5} {'MinOK':>6} {'nMin':>5} "
      f"{'MeanFwd':>8} {'MaxFwd':>8} {'BestPass':>9} {'BestMin':>8} {'DD':>6}")
print("-"*80)
for _, row in res.head(30).iterrows():
    print(f"{int(row['Candles']):>2} {int(row['EndH']):>3} {row['RR']:>4.1f} {row['BE']:>5.2f} "
          f"{int(row['good_mins']):>6} {int(row['total_mins']):>5} "
          f"{row['mean_fwd']:>8.4f} {row['max_fwd']:>8.4f} "
          f"{int(row['best_pass']):>9} {int(row['best_min']):>8} {row['best_dd']:>6.2f}")

# -----------------------------------------------------------------------
# Tomar el candidato mas robusto y analizar su meseta completa
best_combo = res.iloc[0]
print(f"\n{'='*65}")
print(f"  CANDIDATO ROBUSTO: Candles={int(best_combo['Candles'])} EndH={int(best_combo['EndH'])} "
      f"RR={best_combo['RR']} BE={best_combo['BE']}")
print(f"{'='*65}")

sub = df_f[
    (df_f['RangeCandlesCount'] == best_combo['Candles']) &
    (df_f['SessionEnd_Hour']   == best_combo['EndH']) &
    (df_f['RR']                == best_combo['RR']) &
    (df_f['BE_TriggerRR']      == best_combo['BE'])
].sort_values('SessionStart_Min')

print(f"\nMeseta SessionStart_Min:")
print(sub[['SessionStart_Min','Forward Result','Back Result','Profit Factor',
           'Equity DD %','Trades']].to_string(index=False))

# Analizar los top 3 candidatos robustos
print(f"\n{'='*65}")
print(f"  ANALISIS TOP 3 CANDIDATOS ROBUSTOS")
print(f"{'='*65}")

for i, (_, combo) in enumerate(res.head(3).iterrows()):
    sub_c = df_f[
        (df_f['RangeCandlesCount'] == combo['Candles']) &
        (df_f['SessionEnd_Hour']   == combo['EndH']) &
        (df_f['RR']                == combo['RR']) &
        (df_f['BE_TriggerRR']      == combo['BE'])
    ].sort_values('SessionStart_Min')

    print(f"\n[{i+1}] C={int(combo['Candles'])} EndH={int(combo['EndH'])} "
          f"RR={combo['RR']} BE={combo['BE']} | "
          f"MinOK={int(combo['good_mins'])}/{int(combo['total_mins'])} | "
          f"MeanFwd={combo['mean_fwd']:.4f}")
    print(f"  {'Min':>4} {'Fwd':>6} {'Bck':>6} {'PF':>6} {'DD%':>6} {'N':>4}")
    for _, r in sub_c.iterrows():
        flag = " <--" if r['Forward Result'] == sub_c['Forward Result'].max() else ""
        print(f"  {int(r['SessionStart_Min']):>4} {r['Forward Result']:>6.4f} "
              f"{r['Back Result']:>6.4f} {r['Profit Factor']:>6.4f} "
              f"{r['Equity DD %']:>6.2f} {int(r['Trades']):>4}{flag}")

# -----------------------------------------------------------------------
# Meseta SessionEnd del mejor candidato robusto (dentro del top 3)
print(f"\n{'='*65}")
print(f"  MESETA SessionEnd del candidato #1")
print(f"{'='*65}")

c1 = res.iloc[0]
best_min_val = df_f[
    (df_f['RangeCandlesCount'] == c1['Candles']) &
    (df_f['SessionEnd_Hour']   == c1['EndH']) &
    (df_f['RR']                == c1['RR']) &
    (df_f['BE_TriggerRR']      == c1['BE'])
]['Forward Result'].idxmax()
best_min_row = df_f.loc[best_min_val]

nb_end = df_f[
    (df_f['RangeCandlesCount'] == c1['Candles']) &
    (df_f['SessionStart_Min']  == best_min_row['SessionStart_Min']) &
    (df_f['RR']                == c1['RR']) &
    (df_f['BE_TriggerRR']      == c1['BE'])
].sort_values('SessionEnd_Hour')
print(f"(Min={int(best_min_row['SessionStart_Min'])} fijo)")
print(nb_end[['SessionEnd_Hour','Forward Result','Back Result',
              'Profit Factor','Equity DD %','Trades']].to_string(index=False))

# Meseta RR
nb_rr2 = df_f[
    (df_f['RangeCandlesCount'] == c1['Candles']) &
    (df_f['SessionStart_Min']  == best_min_row['SessionStart_Min']) &
    (df_f['SessionEnd_Hour']   == c1['EndH']) &
    (df_f['BE_TriggerRR']      == c1['BE'])
].sort_values('RR')
print(f"\nMeseta RR:")
print(nb_rr2[['RR','Forward Result','Back Result',
              'Profit Factor','Equity DD %','Trades']].to_string(index=False))

# Meseta BE
nb_be2 = df_f[
    (df_f['RangeCandlesCount'] == c1['Candles']) &
    (df_f['SessionStart_Min']  == best_min_row['SessionStart_Min']) &
    (df_f['SessionEnd_Hour']   == c1['EndH']) &
    (df_f['RR']                == c1['RR'])
].sort_values('BE_TriggerRR')
print(f"\nMeseta BE:")
print(nb_be2[['BE_TriggerRR','Forward Result','Back Result',
              'Profit Factor','Equity DD %','Trades']].to_string(index=False))

# -----------------------------------------------------------------------
print(f"\n{'='*65}")
print(f"  VEREDICTO — CANDIDATO BOTH ROBUSTO")
print(f"{'='*65}")
top_pass = df_f[
    (df_f['RangeCandlesCount'] == c1['Candles']) &
    (df_f['SessionEnd_Hour']   == c1['EndH']) &
    (df_f['RR']                == c1['RR']) &
    (df_f['BE_TriggerRR']      == c1['BE'])
].sort_values('Forward Result', ascending=False).iloc[0]

print(f"\nPass #{int(top_pass['Pass'])}")
print(f"  RangeCandlesCount = {int(top_pass['RangeCandlesCount'])}")
print(f"  SessionStart_Min  = {int(top_pass['SessionStart_Min'])}")
print(f"  SessionEnd_Hour   = {int(top_pass['SessionEnd_Hour'])}")
print(f"  RR                = {top_pass['RR']}")
print(f"  BE_TriggerRR      = {top_pass['BE_TriggerRR']}")
print(f"  Forward Result    = {top_pass['Forward Result']:.4f}")
print(f"  Back Result       = {top_pass['Back Result']:.4f}")
print(f"  Profit Factor     = {top_pass['Profit Factor']:.4f}")
print(f"  Equity DD%        = {top_pass['Equity DD %']:.2f}%")
print(f"  Trades            = {int(top_pass['Trades'])}")
