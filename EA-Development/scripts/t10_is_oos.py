import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

NR_PATH  = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\NAS100 V1 NR M3.xlsx"
T10_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 10 Test.xlsx"
VPP = 20.0
RR  = 3.0

def parse_trades(path, start_row):
    df_raw = pd.read_excel(path, header=None)
    entries, exits = [], []

    for _, row in df_raw.iloc[start_row:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        typ = str(row[3]).strip().lower()
        vol4 = str(row[4]).strip()
        try: vol = float(vol4.split('/')[0].strip())
        except: continue

        def sf(v):
            try: f = float(v); return f if f != 0 else None
            except: return None

        if typ in ['buy', 'buy stop']:
            price = sf(row[6]); sl = sf(row[7]); tp = sf(row[8])
            if price and sl and tp:
                entries.append({'open_time': t, 'vol': vol, 'price': price,
                                'sl': sl, 'tp': tp, 'sl_dist': price - sl})
        elif typ == 'sell':
            comment = str(row[len(row)-1]).strip().lower()
            close_price = sf(row[6])
            if 'tp' in comment:   et = 'TP'
            elif 'sl' in comment: et = 'SL'
            elif comment in ['nan', '']: et = 'Timeout'
            else: et = 'Other'
            exits.append({'close_time': t, 'exit_type': et, 'close_price': close_price, 'vol': vol})

    df_e = pd.DataFrame(entries).reset_index(drop=True)
    df_x = pd.DataFrame(exits).reset_index(drop=True)
    min_len = min(len(df_e), len(df_x))
    df = df_e.iloc[:min_len].copy()
    df['exit_type']   = df_x.iloc[:min_len]['exit_type'].values
    df['close_time']  = df_x.iloc[:min_len]['close_time'].values
    df['close_price'] = df_x.iloc[:min_len]['close_price'].values

    df['profit'] = df.apply(lambda r:
        r['vol'] * r['sl_dist'] * VPP * RR if r['exit_type'] == 'TP'
        else (-r['vol'] * r['sl_dist'] * VPP if r['exit_type'] == 'SL'
        else 0.0), axis=1)

    df['date'] = pd.to_datetime(df['open_time'].str[:10])
    df['year'] = df['date'].dt.year
    return df

def period_stats(df, label):
    if len(df) == 0:
        print(f"  [{label}] Sin trades")
        return
    gross_profit = df[df['profit'] > 0]['profit'].sum()
    gross_loss   = abs(df[df['profit'] < 0]['profit'].sum())
    pf   = gross_profit / gross_loss if gross_loss > 0 else 999
    net  = df['profit'].sum()
    tp   = (df['exit_type'] == 'TP').sum()
    sl   = (df['exit_type'] == 'SL').sum()
    to   = (df['exit_type'] == 'Timeout').sum()
    wr   = tp / len(df) * 100

    # DD simplificado (equity curve)
    equity = 5000 + df['profit'].cumsum()
    running_max = equity.cummax()
    dd_series = (equity - running_max) / running_max * 100
    max_dd = abs(dd_series.min())

    print(f"  [{label}]  n={len(df)}  PF={pf:.4f}  Net=${net:.0f}  WR={wr:.1f}%  MaxDD={max_dd:.2f}%")
    print(f"           TP={tp} ({tp/len(df)*100:.0f}%)  SL={sl} ({sl/len(df)*100:.0f}%)  TO={to}")
    return pf, max_dd, len(df)

# ── Parseo ────────────────────────────────────────────────────────────────
nr  = parse_trades(NR_PATH, 126)
t10 = parse_trades(T10_PATH, 97)

# ── Períodos ──────────────────────────────────────────────────────────────
IS_START,  IS_END  = 2022, 2023
OOS_START, OOS_END = 2024, 2025

nr_is  = nr[nr['year'].between(IS_START, IS_END)]
nr_oos = nr[nr['year'].between(OOS_START, OOS_END)]
t10_is  = t10[t10['year'].between(IS_START, IS_END)]
t10_oos = t10[t10['year'].between(OOS_START, OOS_END)]

print("=" * 65)
print("DESGLOSE IS / OOS — T10 (TBR v1.4) vs NR")
print(f"IS  = {IS_START}-{IS_END}   |   OOS = {OOS_START}-{OOS_END}")
print("=" * 65)

print("\nIN-SAMPLE (2022-2023):")
r_nr_is  = period_stats(nr_is,  'NR ')
r_t10_is = period_stats(t10_is, 'T10')

print("\nOUT-OF-SAMPLE (2024-2025):")
r_nr_oos  = period_stats(nr_oos,  'NR ')
r_t10_oos = period_stats(t10_oos, 'T10')

print("\nWALK-FORWARD 2026 (parcial):")
period_stats(nr[nr['year'] == 2026],  'NR ')
period_stats(t10[t10['year'] == 2026], 'T10')

print("\nTOTAL:")
period_stats(nr,  'NR ')
period_stats(t10, 'T10')

# ── OOS/IS ratio ─────────────────────────────────────────────────────────
print()
print("=" * 65)
print("CRITERIOS DE ROBUSTEZ")
print("=" * 65)
if r_nr_is and r_nr_oos and r_t10_is and r_t10_oos:
    pf_is_t10  = r_t10_is[0]
    pf_oos_t10 = r_t10_oos[0]
    ratio_t10  = pf_oos_t10 / pf_is_t10 * 100

    pf_is_nr   = r_nr_is[0]
    pf_oos_nr  = r_nr_oos[0]
    ratio_nr   = pf_oos_nr / pf_is_nr * 100

    print(f"\n  OOS/IS PF ratio (umbral >= 50%):")
    print(f"  NR : IS={pf_is_nr:.4f}  OOS={pf_oos_nr:.4f}  ratio={ratio_nr:.1f}%")
    print(f"  T10: IS={pf_is_t10:.4f}  OOS={pf_oos_t10:.4f}  ratio={ratio_t10:.1f}%")

    dd_oos_t10 = r_t10_oos[1]
    dd_oos_nr  = r_nr_oos[1]
    print(f"\n  MaxDD OOS (umbral <= 10%):")
    print(f"  NR : {dd_oos_nr:.2f}%")
    print(f"  T10: {dd_oos_t10:.2f}%")

# ── Año a año detallado ───────────────────────────────────────────────────
print()
print("=" * 65)
print("AÑO A AÑO DETALLADO — T10")
print("=" * 65)
for yr in sorted(t10['year'].unique()):
    grp = t10[t10['year'] == yr]
    gp  = grp[grp['profit'] > 0]['profit'].sum()
    gl  = abs(grp[grp['profit'] < 0]['profit'].sum())
    pf  = gp / gl if gl > 0 else 999
    net = grp['profit'].sum()
    wr  = (grp['exit_type'] == 'TP').mean() * 100
    tp  = (grp['exit_type'] == 'TP').sum()
    sl  = (grp['exit_type'] == 'SL').sum()
    tag = 'IS ' if yr <= IS_END else ('OOS' if yr <= OOS_END else 'WF ')
    print(f"  {yr} [{tag}]: n={len(grp):3d}  PF={pf:.3f}  Net=${net:+.0f}  WR={wr:.0f}%  TP={tp} SL={sl}")
