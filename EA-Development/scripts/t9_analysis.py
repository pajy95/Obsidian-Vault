import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

NR_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\NAS100 V1 NR M3.xlsx"
T9_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 9noTest.xlsx"
VPP = 20.0

def parse_entries(path, start_row):
    df_raw = pd.read_excel(path, header=None)
    rows = []
    for _, row in df_raw.iloc[start_row:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t):
            continue
        typ = str(row[3]).strip().lower()
        if typ not in ['buy', 'buy stop']:
            continue
        vol4 = str(row[4]).strip()
        try:
            vol = float(vol4.split('/')[0].strip())
        except:
            continue
        def sf(v):
            try:
                f = float(v)
                return f if f != 0 else None
            except:
                return None
        price = sf(row[6])
        sl    = sf(row[7])
        tp    = sf(row[8])
        if price and sl and tp:
            rows.append({'open_time': t, 'vol': vol, 'price': price,
                         'sl': sl, 'tp': tp, 'sl_dist': price - sl})
    return pd.DataFrame(rows)

def parse_exits(path, start_row):
    df_raw = pd.read_excel(path, header=None)
    exits = []
    for _, row in df_raw.iloc[start_row:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t):
            continue
        if str(row[3]).strip().lower() != 'sell':
            continue
        comment = str(row[len(row)-1]).strip().lower()
        if 'tp' in comment:
            et = 'TP'
        elif 'sl' in comment:
            et = 'SL'
        elif comment in ['nan', '']:
            et = 'Timeout'
        else:
            et = 'Other'
        exits.append({'exit_type': et})
    return pd.DataFrame(exits)

nr = parse_entries(NR_PATH, 126)
t9 = parse_entries(T9_PATH, 97)
nr_ex = parse_exits(NR_PATH, 126)
t9_ex = parse_exits(T9_PATH, 97)

print("=" * 60)
print("RESULTADOS T9 (MODE_BREAKOUT v1.3) vs NR")
print("=" * 60)

print("""
           NR          T9
Trades:    474         623
WR:        33.3%       32.1%
PF:        1.4356      1.2651
Net:       $1,918      $2,941
MaxDD:     5.84%       13.37%
Periodo:   2022-2026   2022-2026
""")

print("=" * 60)
print("LOTAJE")
print("=" * 60)
for label, df in [('NR', nr), ('T9', t9)]:
    v = df['vol']
    print(f"\n[{label}] min={v.min():.2f}  median={v.median():.2f}  mean={v.mean():.3f}  max={v.max():.2f}")
    for lot, cnt in v.value_counts().sort_index().items():
        bar = '#' * int(cnt / len(v) * 40)
        print(f"  {lot:.2f}: {cnt:4d} ({cnt/len(v)*100:5.1f}%)  {bar}")

print()
print("=" * 60)
print("SL_DIST (puntos)")
print("=" * 60)
for label, df in [('NR', nr), ('T9', t9)]:
    s = df['sl_dist']
    print(f"[{label}] min={s.min():.1f}  p25={s.quantile(.25):.1f}  median={s.median():.1f}  p75={s.quantile(.75):.1f}  max={s.max():.1f}")

print()
print("=" * 60)
print("RIESGO REAL USD (lot x SL_dist x $20)")
print("=" * 60)
for label, df in [('NR', nr), ('T9', t9)]:
    r = df['vol'] * df['sl_dist'] * VPP
    print(f"[{label}] min=${r.min():.2f}  median=${r.median():.2f}  mean=${r.mean():.2f}  max=${r.max():.2f}")

print()
print("=" * 60)
print("FLOOR CHECK T9: lot == floor(12.5 / SL_dist / 20)?")
print("=" * 60)
t9['floor_lot'] = (12.5 / (t9['sl_dist'] * VPP)).apply(lambda x: np.floor(x * 100) / 100)
t9['match'] = np.isclose(t9['vol'], t9['floor_lot'], atol=0.005)
n_match = t9['match'].sum()
print(f"Matches: {n_match} / {len(t9)} ({n_match/len(t9)*100:.1f}%)")
diff = (t9['vol'] - t9['floor_lot']).round(2).value_counts().sort_index()
print("Diferencia vol_real - floor_lot:")
for d, cnt in diff.items():
    print(f"  {d:+.2f}: {cnt} trades")

print()
print("=" * 60)
print("TIPOS DE SALIDA")
print("=" * 60)
for label, df_ex in [('NR', nr_ex), ('T9', t9_ex)]:
    tot = len(df_ex)
    vc = df_ex['exit_type'].value_counts()
    print(f"[{label}] total={tot}")
    for et, cnt in vc.items():
        print(f"  {et:8s}: {cnt:4d} ({cnt/tot*100:.1f}%)")

print()
print("=" * 60)
print("TRADES POR AÑO T9")
print("=" * 60)
t9['year'] = pd.to_datetime(t9['open_time'].str[:10]).dt.year
for yr, grp in t9.groupby('year'):
    print(f"  {yr}: {len(grp)} trades")
