import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

NR_PATH  = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\NAS100 V1 NR M3.xlsx"
T10_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 10 Test.xlsx"
VPP = 20.0

def parse_entries(path, start_row):
    df_raw = pd.read_excel(path, header=None)
    rows = []
    for _, row in df_raw.iloc[start_row:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        typ = str(row[3]).strip().lower()
        if typ not in ['buy', 'buy stop']: continue
        vol4 = str(row[4]).strip()
        try: vol = float(vol4.split('/')[0].strip())
        except: continue
        def sf(v):
            try: f = float(v); return f if f != 0 else None
            except: return None
        price = sf(row[6]); sl = sf(row[7]); tp = sf(row[8])
        if price and sl and tp:
            rows.append({'open_time': t, 'vol': vol, 'price': price,
                         'sl': sl, 'tp': tp, 'sl_dist': price - sl})
    return pd.DataFrame(rows)

def parse_exits(path, start_row):
    df_raw = pd.read_excel(path, header=None)
    exits = []
    for _, row in df_raw.iloc[start_row:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        if str(row[3]).strip().lower() != 'sell': continue
        comment = str(row[len(row)-1]).strip().lower()
        if 'tp' in comment: et = 'TP'
        elif 'sl' in comment: et = 'SL'
        elif comment in ['nan', '']: et = 'Timeout'
        else: et = 'Other'
        exits.append({'exit_type': et})
    return pd.DataFrame(exits)

nr  = parse_entries(NR_PATH, 126)
t10 = parse_entries(T10_PATH, 97)
nr_ex  = parse_exits(NR_PATH, 126)
t10_ex = parse_exits(T10_PATH, 97)

print("=" * 60)
print("T10 (TBR v1.4 MODE_BREAKOUT M3) vs NR")
print("=" * 60)
print("""
           NR          T10
Trades:    474         623
WR:        33.3%       32.1%
PF:        1.4356      1.4054
Net:       $1,918      $1,861
MaxDD bal: 4.79%       3.20%
MaxDD eq:  5.21%       3.42%
Sharpe:    46.2        43.3
""")

print("=" * 60)
print("LOTAJE")
print("=" * 60)
for label, df in [('NR', nr), ('T10', t10)]:
    v = df['vol']
    print(f"\n[{label}] min={v.min():.2f}  median={v.median():.2f}  mean={v.mean():.3f}  max={v.max():.2f}")
    for lot, cnt in v.value_counts().sort_index().items():
        bar = '#' * int(cnt / len(v) * 40)
        print(f"  {lot:.2f}: {cnt:4d} ({cnt/len(v)*100:5.1f}%)  {bar}")

print()
print("=" * 60)
print("SL_DIST (puntos)")
print("=" * 60)
for label, df in [('NR', nr), ('T10', t10)]:
    s = df['sl_dist']
    print(f"[{label}] min={s.min():.1f}  p25={s.quantile(.25):.1f}  median={s.median():.1f}  p75={s.quantile(.75):.1f}  max={s.max():.1f}")

print()
print("=" * 60)
print("RIESGO REAL USD (lot x SL_dist x $20)")
print("=" * 60)
for label, df in [('NR', nr), ('T10', t10)]:
    r = df['vol'] * df['sl_dist'] * VPP
    print(f"[{label}] min=${r.min():.2f}  median=${r.median():.2f}  mean=${r.mean():.2f}  max=${r.max():.2f}")

print()
print("=" * 60)
print("FLOOR CHECK: lot == floor(12.5 / SL_dist / 20)?")
print("=" * 60)
t10['floor_lot'] = (12.5 / (t10['sl_dist'] * VPP)).apply(lambda x: np.floor(x * 100) / 100)
t10['match'] = np.isclose(t10['vol'], t10['floor_lot'], atol=0.005)
n_match = t10['match'].sum()
print(f"Matches: {n_match} / {len(t10)} ({n_match/len(t10)*100:.1f}%)")

print()
print("=" * 60)
print("TIPOS DE SALIDA")
print("=" * 60)
for label, df_ex in [('NR', nr_ex), ('T10', t10_ex)]:
    tot = len(df_ex)
    vc = df_ex['exit_type'].value_counts()
    print(f"[{label}] total={tot}")
    for et, cnt in vc.items():
        print(f"  {et:8s}: {cnt:4d} ({cnt/tot*100:.1f}%)")

print()
print("=" * 60)
print("AÑO A AÑO T10")
print("=" * 60)
t10['year'] = pd.to_datetime(t10['open_time'].str[:10]).dt.year
nr['year']  = pd.to_datetime(nr['open_time'].str[:10]).dt.year

# Para T10: reconstruir profit desde SL_dist y tipo de salida
t10_exits_list = t10_ex.reset_index(drop=True)
t10_entries    = t10.reset_index(drop=True)
min_len = min(len(t10_entries), len(t10_exits_list))
t10_merged = t10_entries.iloc[:min_len].copy()
t10_merged['exit_type'] = t10_exits_list.iloc[:min_len]['exit_type'].values
t10_merged['profit'] = t10_merged.apply(lambda r:
    r['vol'] * r['sl_dist'] * VPP * VPP/VPP *  # TP
    (3.0 if r['exit_type'] == 'TP' else (-1.0 if r['exit_type'] == 'SL' else 0.0)), axis=1)

for yr, grp in t10_merged.groupby('year'):
    tp_cnt  = (grp['exit_type'] == 'TP').sum()
    sl_cnt  = (grp['exit_type'] == 'SL').sum()
    to_cnt  = (grp['exit_type'] == 'Timeout').sum()
    net     = grp['profit'].sum()
    wins    = tp_cnt / len(grp) * 100
    print(f"  {yr}: {len(grp):3d} trades | TP={tp_cnt:3d} SL={sl_cnt:3d} TO={to_cnt} | WR={wins:.0f}% | net~${net:.0f}")
