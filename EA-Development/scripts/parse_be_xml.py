"""
Análisis completo: optimización XAUUSD con BE habilitado.
Pregunta clave: ¿BE mejora el rendimiento? ¿Cuál modo es mejor?
"""

import xml.etree.ElementTree as ET
import pandas as pd
import numpy as np

NS = 'urn:schemas-microsoft-com:office:spreadsheet'

def parse_spreadsheetml(path):
    tree = ET.parse(path)
    root = tree.getroot()
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

# -----------------------------------------------------------------------
df = parse_spreadsheetml(
    r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\XAUUSD\OP TBR XAU M5 BE.xml"
)

# Tipos numéricos
for col in ['Forward Result','Back Result','Profit','Profit Factor',
            'Sharpe Ratio','Equity DD %','Trades','Recovery Factor',
            'EntryMode','RangeCandlesCount','SessionStart_Min','RR','BE_TriggerRR']:
    df[col] = pd.to_numeric(df[col], errors='coerce')

df['EntryMode_name'] = df['EntryMode'].map({0:'CONFIRM', 1:'BREAKOUT'})

print(f"Total passes: {len(df)}")
print(f"EntryMode dist: {df['EntryMode_name'].value_counts().to_dict()}")
print(f"BE_TriggerRR valores: {sorted(df['BE_TriggerRR'].dropna().unique())}")
print(f"Trades range: {df['Trades'].min():.0f} – {df['Trades'].max():.0f}")

# -----------------------------------------------------------------------
# Filtro mínimo: trades >= 50 para evitar over-fitted passes con pocas muestras
df_f = df[df['Trades'] >= 50].copy()
print(f"\nPasses con Trades >= 50: {len(df_f)}")

# -----------------------------------------------------------------------
# PREGUNTA CENTRAL: ¿BE mejora el Forward Result?
print("\n" + "="*60)
print("  IMPACTO DE BE_TriggerRR SOBRE FORWARD RESULT")
print("="*60)

for mode in ['CONFIRM','BREAKOUT']:
    sub = df_f[df_f['EntryMode_name'] == mode]
    if sub.empty:
        continue
    print(f"\n--- {mode} ---")
    be_summary = sub.groupby('BE_TriggerRR')['Forward Result'].agg(
        count='count', mean='mean', median='median', q75=lambda x: x.quantile(0.75)
    ).round(4)
    print(be_summary.to_string())

# -----------------------------------------------------------------------
# TOP passes por modo
print("\n" + "="*60)
print("  TOP 15 PASSES — CONFIRM (ordenado por Forward Result)")
print("="*60)
conf = df_f[df_f['EntryMode_name'] == 'CONFIRM'].sort_values('Forward Result', ascending=False)
print(conf[['Pass','Forward Result','Back Result','Profit Factor',
            'Equity DD %','Trades','RangeCandlesCount',
            'SessionStart_Min','RR','BE_TriggerRR']].head(15).to_string(index=False))

print("\n" + "="*60)
print("  TOP 15 PASSES — BREAKOUT (ordenado por Forward Result)")
print("="*60)
rupt = df_f[df_f['EntryMode_name'] == 'BREAKOUT'].sort_values('Forward Result', ascending=False)
print(rupt[['Pass','Forward Result','Back Result','Profit Factor',
            'Equity DD %','Trades','RangeCandlesCount',
            'SessionStart_Min','RR','BE_TriggerRR']].head(15).to_string(index=False))

# -----------------------------------------------------------------------
# Comparativa BE=OFF vs BE=ON para mismos parámetros estructurales
print("\n" + "="*60)
print("  BE vs NO-BE: mismo grupo de parámetros (RangeCandlesCount + Min + RR)")
print("="*60)

for mode in ['CONFIRM','BREAKOUT']:
    sub = df_f[df_f['EntryMode_name'] == mode].copy()
    if sub.empty:
        continue

    # Agrupar por (RangeCandlesCount, SessionStart_Min, RR)
    # Para cada grupo, comparar FwdResult con distintos BE_TriggerRR
    groups = sub.groupby(['RangeCandlesCount','SessionStart_Min','RR'])

    be_wins  = 0
    be_loses = 0
    no_be_val = []
    be_best_val = []

    for key, grp in groups:
        if len(grp) < 2:
            continue
        # BE_TriggerRR valores en este grupo
        no_be = grp[grp['BE_TriggerRR'] == 0]['Forward Result']
        with_be = grp[grp['BE_TriggerRR'] > 0]['Forward Result']

        if no_be.empty or with_be.empty:
            continue

        base   = no_be.mean()
        best_be = with_be.max()
        no_be_val.append(base)
        be_best_val.append(best_be)

        if best_be > base:
            be_wins += 1
        else:
            be_loses += 1

    total = be_wins + be_loses
    if total > 0:
        print(f"\n{mode}:")
        print(f"  Grupos donde BE mejora FwdResult:   {be_wins}/{total} = {be_wins/total:.1%}")
        print(f"  Grupos donde BE empeora FwdResult:  {be_loses}/{total} = {be_loses/total:.1%}")
        if no_be_val:
            print(f"  FwdResult medio SIN BE:  {np.mean(no_be_val):.4f}")
            print(f"  FwdResult medio CON BE:  {np.mean(be_best_val):.4f}")
            diff = np.mean(be_best_val) - np.mean(no_be_val)
            print(f"  Delta medio:             {diff:+.4f}")

# -----------------------------------------------------------------------
# Meseta del top pass CONFIRM
print("\n" + "="*60)
print("  MESETA — TOP PASS CONFIRM")
print("="*60)
if not conf.empty:
    top = conf.iloc[0]
    print(f"Top pass: #{int(top['Pass'])} | Candles={int(top['RangeCandlesCount'])} "
          f"Min={int(top['SessionStart_Min'])} RR={top['RR']} BE={top['BE_TriggerRR']}")
    print(f"  Forward={top['Forward Result']:.4f} Back={top['Back Result']:.4f} "
          f"PF={top['Profit Factor']:.4f} DD={top['Equity DD %']:.2f}% Trades={int(top['Trades'])}")

    # Vecinos: mismo Candles y Min, RR ±0.6
    neighbors = df_f[
        (df_f['EntryMode_name'] == 'CONFIRM') &
        (df_f['RangeCandlesCount'] == top['RangeCandlesCount']) &
        (df_f['SessionStart_Min'] == top['SessionStart_Min']) &
        (df_f['BE_TriggerRR'] == top['BE_TriggerRR'])
    ].sort_values('RR')
    print(f"\n  Meseta RR (Candles={int(top['RangeCandlesCount'])} Min={int(top['SessionStart_Min'])} BE={top['BE_TriggerRR']}):")
    print(neighbors[['RR','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))

print("\n" + "="*60)
print("  MESETA — TOP PASS BREAKOUT")
print("="*60)
if not rupt.empty:
    top = rupt.iloc[0]
    print(f"Top pass: #{int(top['Pass'])} | Candles={int(top['RangeCandlesCount'])} "
          f"Min={int(top['SessionStart_Min'])} RR={top['RR']} BE={top['BE_TriggerRR']}")
    print(f"  Forward={top['Forward Result']:.4f} Back={top['Back Result']:.4f} "
          f"PF={top['Profit Factor']:.4f} DD={top['Equity DD %']:.2f}% Trades={int(top['Trades'])}")

    neighbors = df_f[
        (df_f['EntryMode_name'] == 'BREAKOUT') &
        (df_f['RangeCandlesCount'] == top['RangeCandlesCount']) &
        (df_f['SessionStart_Min'] == top['SessionStart_Min']) &
        (df_f['BE_TriggerRR'] == top['BE_TriggerRR'])
    ].sort_values('RR')
    print(f"\n  Meseta RR (Candles={int(top['RangeCandlesCount'])} Min={int(top['SessionStart_Min'])} BE={top['BE_TriggerRR']}):")
    print(neighbors[['RR','Forward Result','Back Result','Profit Factor','Equity DD %','Trades']].to_string(index=False))
