# -*- coding: utf-8 -*-
"""
Analisis optimizacion NAS100 TBR v1.0b — 20160 passes
Parametros: TradeDirection, EntryMode, RangeCandlesCount,
            SessionStart_Min, SessionEnd_Hour, RR, BE_TriggerRR
"""

import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import xml.etree.ElementTree as ET
import pandas as pd
import numpy as np

NS   = 'urn:schemas-microsoft-com:office:spreadsheet'
PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\op TBR NAS.xml100 M5.xml"

# -----------------------------------------------------------------------
def parse_spreadsheetml(path):
    tree  = ET.parse(path)
    root  = tree.getroot()
    ws    = root.find(f'{{{NS}}}Worksheet')
    table = ws.find(f'{{{NS}}}Table')
    rows  = table.findall(f'{{{NS}}}Row')
    data  = []
    for row in rows:
        cells    = row.findall(f'{{{NS}}}Cell')
        row_data = [c.find(f'{{{NS}}}Data').text
                    if c.find(f'{{{NS}}}Data') is not None else None
                    for c in cells]
        data.append(row_data)
    headers = data[0]
    records = []
    for row in data[1:]:
        while len(row) < len(headers):
            row.append(None)
        records.append(dict(zip(headers, row)))
    return pd.DataFrame(records)

print("Cargando XML (21 MB)...")
df = parse_spreadsheetml(PATH)

NUM_COLS = ['Forward Result','Back Result','Profit','Profit Factor','Sharpe Ratio',
            'Equity DD %','Trades','Recovery Factor','Custom',
            'TradeDirection','EntryMode','RangeCandlesCount',
            'SessionStart_Min','SessionEnd_Hour','RR','BE_TriggerRR']
for col in NUM_COLS:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

DIR_MAP  = {0:'LONG', 1:'SHORT', 2:'BOTH'}
MODE_MAP = {0:'CONFIRM', 1:'BREAKOUT'}
df['Dir']  = df['TradeDirection'].map(DIR_MAP)
df['Mode'] = df['EntryMode'].map(MODE_MAP)

print(f"\nTotal passes: {len(df)}")
print(f"TradeDirection: {df['Dir'].value_counts().to_dict()}")
print(f"EntryMode:      {df['Mode'].value_counts().to_dict()}")
print(f"SessionEnd_Hour valores: {sorted(df['SessionEnd_Hour'].dropna().unique().astype(int))}")
print(f"SessionStart_Min valores: {sorted(df['SessionStart_Min'].dropna().unique().astype(int))}")
print(f"RangeCandlesCount valores: {sorted(df['RangeCandlesCount'].dropna().unique().astype(int))}")
print(f"RR valores: {sorted(df['RR'].dropna().unique())}")
print(f"BE_TriggerRR valores: {sorted(df['BE_TriggerRR'].dropna().unique())}")
print(f"Trades rango: {df['Trades'].min():.0f} - {df['Trades'].max():.0f}")

# -----------------------------------------------------------------------
# Filtro minimo de trades
MIN_TRADES = 40
df_f = df[df['Trades'] >= MIN_TRADES].copy()
print(f"\nPasses con Trades >= {MIN_TRADES}: {len(df_f)}")

# -----------------------------------------------------------------------
print("\n" + "="*65)
print("  IMPACTO DE SessionEnd_Hour SOBRE FORWARD RESULT")
print("="*65)
for mode in ['LONG','BOTH']:
    sub = df_f[df_f['Dir'] == mode]
    if sub.empty: continue
    print(f"\n--- Dir={mode} ---")
    summary = sub.groupby('SessionEnd_Hour')['Forward Result'].agg(
        count='count', mean='mean', median='median',
        q75=lambda x: x.quantile(0.75)
    ).round(4)
    print(summary.to_string())

# -----------------------------------------------------------------------
print("\n" + "="*65)
print("  IMPACTO DE BE_TriggerRR SOBRE FORWARD RESULT")
print("="*65)
for mode in ['CONFIRM','BREAKOUT']:
    sub = df_f[df_f['Mode'] == mode]
    if sub.empty: continue
    print(f"\n--- Mode={mode} ---")
    summary = sub.groupby('BE_TriggerRR')['Forward Result'].agg(
        count='count', mean='mean', median='median',
        q75=lambda x: x.quantile(0.75)
    ).round(4)
    print(summary.to_string())

# -----------------------------------------------------------------------
print("\n" + "="*65)
print("  TOP 20 PASSES — LONG BREAKOUT (Forward Result)")
print("="*65)
top_lb = df_f[(df_f['Dir']=='LONG') & (df_f['Mode']=='BREAKOUT')].sort_values('Forward Result', ascending=False)
cols_show = ['Pass','Forward Result','Back Result','Profit Factor','Equity DD %',
             'Trades','RangeCandlesCount','SessionStart_Min','SessionEnd_Hour','RR','BE_TriggerRR']
print(top_lb[cols_show].head(20).to_string(index=False))

print("\n" + "="*65)
print("  TOP 20 PASSES — LONG CONFIRM (Forward Result)")
print("="*65)
top_lc = df_f[(df_f['Dir']=='LONG') & (df_f['Mode']=='CONFIRM')].sort_values('Forward Result', ascending=False)
print(top_lc[cols_show].head(20).to_string(index=False))

if len(df_f[df_f['Dir']=='BOTH']) > 0:
    print("\n" + "="*65)
    print("  TOP 20 PASSES — BOTH BREAKOUT (Forward Result)")
    print("="*65)
    top_bb = df_f[(df_f['Dir']=='BOTH') & (df_f['Mode']=='BREAKOUT')].sort_values('Forward Result', ascending=False)
    print(top_bb[cols_show].head(20).to_string(index=False))

# -----------------------------------------------------------------------
# Meseta del top pass LONG BREAKOUT
print("\n" + "="*65)
print("  MESETA — TOP PASS LONG BREAKOUT")
print("="*65)
if not top_lb.empty:
    top = top_lb.iloc[0]
    print(f"Top pass: #{int(top['Pass'])} | Dir={top['Dir']} Mode={top['Mode']}")
    print(f"  Candles={int(top['RangeCandlesCount'])} Min={int(top['SessionStart_Min'])} "
          f"EndH={int(top['SessionEnd_Hour'])} RR={top['RR']} BE={top['BE_TriggerRR']}")
    print(f"  Forward={top['Forward Result']:.4f} Back={top['Back Result']:.4f} "
          f"PF={top['Profit Factor']:.4f} DD={top['Equity DD %']:.2f}% Trades={int(top['Trades'])}")

    # Meseta RR (mismo Candles, Min, EndH, BE)
    neighbors_rr = df_f[
        (df_f['Dir']=='LONG') & (df_f['Mode']=='BREAKOUT') &
        (df_f['RangeCandlesCount'] == top['RangeCandlesCount']) &
        (df_f['SessionStart_Min']  == top['SessionStart_Min']) &
        (df_f['SessionEnd_Hour']   == top['SessionEnd_Hour']) &
        (df_f['BE_TriggerRR']      == top['BE_TriggerRR'])
    ].sort_values('RR')
    print(f"\n  Meseta RR (Candles={int(top['RangeCandlesCount'])} Min={int(top['SessionStart_Min'])} "
          f"EndH={int(top['SessionEnd_Hour'])} BE={top['BE_TriggerRR']}):")
    print(neighbors_rr[['RR','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

    # Meseta SessionEnd (mismo todo excepto SessionEnd)
    neighbors_end = df_f[
        (df_f['Dir']=='LONG') & (df_f['Mode']=='BREAKOUT') &
        (df_f['RangeCandlesCount'] == top['RangeCandlesCount']) &
        (df_f['SessionStart_Min']  == top['SessionStart_Min']) &
        (df_f['RR']                == top['RR']) &
        (df_f['BE_TriggerRR']      == top['BE_TriggerRR'])
    ].sort_values('SessionEnd_Hour')
    print(f"\n  Meseta SessionEnd_Hour (Candles={int(top['RangeCandlesCount'])} Min={int(top['SessionStart_Min'])} "
          f"RR={top['RR']} BE={top['BE_TriggerRR']}):")
    print(neighbors_end[['SessionEnd_Hour','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

# -----------------------------------------------------------------------
# Resumen comparativo por Mode y Dir
print("\n" + "="*65)
print("  RESUMEN POR DIRECCION Y MODO")
print("="*65)
print(f"\n{'Dir':<6} {'Mode':<10} {'n_pass':>7} {'Fwd_mean':>9} {'Fwd_p75':>9} {'Fwd_max':>9}")
print(f"{'-'*55}")
for dir_ in ['LONG','BOTH','SHORT']:
    for mode in ['BREAKOUT','CONFIRM']:
        sub = df_f[(df_f['Dir']==dir_) & (df_f['Mode']==mode)]
        if sub.empty: continue
        fwd = sub['Forward Result']
        print(f"{dir_:<6} {mode:<10} {len(sub):>7} {fwd.mean():>9.4f} {fwd.quantile(0.75):>9.4f} {fwd.max():>9.4f}")
