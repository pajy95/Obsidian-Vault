"""
Analisis TBR v1.0b — parser corregido para MODE_CONFIRM
En MODE_CONFIRM: entry price = 0 en col[6], SL en col[7], TP en col[8]
SL_dist = (TP - SL) / (RR + 1)  con RR=3 -> SL_dist = (TP-SL)/4
"""
import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

V1B_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\nas100 TBR v1.0b.xlsx"
T10_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 10 Test.xlsx"
VPP = 20.0
RR  = 3.0

def sf(v):
    try: f=float(v); return f if f!=0 else None
    except: return None

def parse_v1b(path, start_row=100):
    """Parser para MODE_CONFIRM: price en col[6]=0, SL=col[7], TP=col[8]"""
    df_raw = pd.read_excel(path, header=None)
    entries, exits = [], []
    for _, row in df_raw.iloc[start_row:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        typ = str(row[3]).strip().lower()
        vol4 = str(row[4]).strip()
        try: vol = float(vol4.split('/')[0].strip())
        except: continue

        if typ == 'buy':
            sl = sf(row[7]); tp = sf(row[8])
            if sl and tp and tp > sl:
                sl_dist = (tp - sl) / (RR + 1.0)  # derivado de tp = entry + RR*sl_dist, sl = entry - sl_dist
                entry   = sl + sl_dist
                entries.append({'open_time':t,'vol':vol,'price':entry,'sl':sl,'tp':tp,'sl_dist':sl_dist})

        elif typ == 'sell':
            comment = str(row[len(row)-1]).strip().lower()
            cp = sf(row[6])
            if 'tp' in comment:   et = 'TP'
            elif 'sl' in comment: et = 'SL'
            elif comment in ['nan','']: et = 'Timeout'
            else: et = 'Other'
            exits.append({'exit_type':et,'close_price':cp,'close_time':t})

    df_e = pd.DataFrame(entries).reset_index(drop=True)
    df_x = pd.DataFrame(exits).reset_index(drop=True)
    n = min(len(df_e), len(df_x))
    df = df_e.iloc[:n].copy()
    df['exit_type']   = df_x.iloc[:n]['exit_type'].values
    df['close_time']  = df_x.iloc[:n]['close_time'].values
    df['close_price'] = df_x.iloc[:n]['close_price'].values
    df['date']     = pd.to_datetime(df['open_time'].str[:10])
    df['year']     = df['date'].dt.year
    df['dow_name'] = df['date'].dt.day_name()
    df['win']      = (df['exit_type']=='TP').astype(int)
    df['profit']   = df.apply(lambda r:
        r['vol']*r['sl_dist']*VPP*RR if r['exit_type']=='TP'
        else (-r['vol']*r['sl_dist']*VPP if r['exit_type']=='SL' else 0), axis=1)
    return df

def parse_t10(path, start_row=97):
    """Parser original para MODE_BREAKOUT (buy stop)"""
    df_raw = pd.read_excel(path, header=None)
    entries, exits = [], []
    for _, row in df_raw.iloc[start_row:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        typ = str(row[3]).strip().lower()
        vol4 = str(row[4]).strip()
        try: vol = float(vol4.split('/')[0].strip())
        except: continue
        if typ in ['buy','buy stop']:
            p=sf(row[6]); sl=sf(row[7]); tp=sf(row[8])
            if p and sl and tp:
                entries.append({'open_time':t,'vol':vol,'price':p,'sl':sl,'tp':tp,'sl_dist':p-sl})
        elif typ == 'sell':
            comment = str(row[len(row)-1]).strip().lower()
            if 'tp' in comment: et='TP'
            elif 'sl' in comment: et='SL'
            elif comment in ['nan','']: et='Timeout'
            else: et='Other'
            exits.append({'exit_type':et})
    df_e = pd.DataFrame(entries).reset_index(drop=True)
    df_x = pd.DataFrame(exits).reset_index(drop=True)
    n = min(len(df_e), len(df_x))
    df = df_e.iloc[:n].copy()
    df['exit_type'] = df_x.iloc[:n]['exit_type'].values
    df['date']     = pd.to_datetime(df['open_time'].str[:10])
    df['year']     = df['date'].dt.year
    df['dow_name'] = df['date'].dt.day_name()
    df['win']      = (df['exit_type']=='TP').astype(int)
    df['profit']   = df.apply(lambda r:
        r['vol']*r['sl_dist']*VPP*RR if r['exit_type']=='TP'
        else (-r['vol']*r['sl_dist']*VPP if r['exit_type']=='SL' else 0), axis=1)
    return df

def pf(df):
    gp = df[df['profit']>0]['profit'].sum()
    gl = abs(df[df['profit']<0]['profit'].sum())
    return gp/gl if gl>0 else 999

def stats(df, label=''):
    if len(df) < 5: return None
    tp = df['win'].sum()
    sl = (df['exit_type']=='SL').sum()
    to = len(df) - tp - sl
    return {'label':label,'n':len(df),'pf':pf(df),'wr':df['win'].mean()*100,
            'net':df['profit'].sum(),'tp':tp,'sl':sl,'timeout':to}

def pr(s, indent='  '):
    if not s: return
    flag = 'OK' if s['pf']>=1.40 else ('~' if s['pf']>=1.30 else 'XX')
    print(f"{indent}[{flag}] n={s['n']:4d}  PF={s['pf']:.3f}  WR={s['wr']:.1f}%"
          f"  Net=${s['net']:+.0f}  TP={s['tp']} SL={s['sl']} TO={s['timeout']}")

v1b = parse_v1b(V1B_PATH)
t10 = parse_t10(T10_PATH)

IS  = (2022, 2023)
OOS = (2024, 2025)

print("="*65)
print("TBR v1.0b  vs  T10 (baseline MODE_BREAKOUT)")
print("="*65)
print(f"\n  NOTA: v1.0b corrio en MODE_CONFIRM (EntryMode=0)")
print(f"  T10 corrio en MODE_BREAKOUT — son modos distintos, comparar con cautela\n")

print("GLOBAL:")
sv = stats(v1b, 'v1.0b (CONFIRM)')
st = stats(t10, 'T10   (BREAKOUT)')
print(f"  v1.0b  ", end=''); pr(sv, '')
print(f"  T10    ", end=''); pr(st, '')

print("\nIS 2022-2023:")
sv_is = stats(v1b[v1b['year'].between(*IS)])
st_is = stats(t10[t10['year'].between(*IS)])
print(f"  v1.0b  ", end=''); pr(sv_is, '')
print(f"  T10    ", end=''); pr(st_is, '')

print("\nOOS 2024-2025:")
sv_oo = stats(v1b[v1b['year'].between(*OOS)])
st_oo = stats(t10[t10['year'].between(*OOS)])
print(f"  v1.0b  ", end=''); pr(sv_oo, '')
print(f"  T10    ", end=''); pr(st_oo, '')

print("\nPOR ANO:")
print(f"  {'Ano':6s} | {'v1b n':>5} {'v1b PF':>7} {'v1b WR':>7} | {'T10 n':>5} {'T10 PF':>7} {'T10 WR':>7}")
print("  " + "-"*55)
all_years = sorted(set(v1b['year'].unique()) | set(t10['year'].unique()))
for yr in all_years:
    gv = v1b[v1b['year']==yr]
    gt = t10[t10['year']==yr]
    pf_v = f"{pf(gv):.3f}" if len(gv)>=5 else "  n/a"
    wr_v = f"{gv['win'].mean()*100:.1f}%" if len(gv)>=5 else "  n/a"
    pf_t = f"{pf(gt):.3f}" if len(gt)>=5 else "  n/a"
    wr_t = f"{gt['win'].mean()*100:.1f}%" if len(gt)>=5 else "  n/a"
    print(f"  {yr}  | {len(gv):>5d} {pf_v:>7} {wr_v:>7} | {len(gt):>5d} {pf_t:>7} {wr_t:>7}")

print("\nTIPOS DE SALIDA:")
for label, df in [('v1.0b', v1b), ('T10', t10)]:
    total = len(df)
    tp = df['win'].sum()
    sl = (df['exit_type']=='SL').sum()
    to = total - tp - sl
    print(f"  {label}: total={total}"
          f"  TP={tp}({tp/total*100:.0f}%)"
          f"  SL={sl}({sl/total*100:.0f}%)"
          f"  Timeout/Other={to}({to/total*100:.0f}%)")

print("\nDISTRIBUCION SL_DIST (pts):")
for label, df in [('v1.0b', v1b), ('T10', t10)]:
    print(f"  {label}: min={df['sl_dist'].min():.1f}  "
          f"p25={df['sl_dist'].quantile(.25):.1f}  "
          f"med={df['sl_dist'].median():.1f}  "
          f"p75={df['sl_dist'].quantile(.75):.1f}  "
          f"max={df['sl_dist'].max():.1f}")

print("\nPOR DIA (v1.0b):")
for day in ['Monday','Wednesday','Friday']:
    g = v1b[v1b['dow_name']==day]
    if len(g)>=5:
        print(f"  {day[:3]}: n={len(g):4d}  PF={pf(g):.3f}  WR={g['win'].mean()*100:.1f}%")

print("\n" + "="*65)
print("VEREDICTO")
print("="*65)
if sv_oo and st_oo:
    delta = sv_oo['pf'] - st_oo['pf']
    print(f"\n  OOS PF:  v1.0b={sv_oo['pf']:.3f}  T10={st_oo['pf']:.3f}  delta={delta:+.3f}")
    print(f"  Trades:  v1.0b={sv['n']}  T10={st['n']}  (v1.0b tiene {sv['n']-st['n']:+d})")
    if sv_oo['pf'] >= 1.40:
        print(f"  SUPERA umbral OOS PF>=1.40")
    else:
        print(f"  NO supera umbral OOS PF>=1.40")
    print()
    print("  IMPORTANTE: v1.0b corrio MODE_CONFIRM, T10 MODE_BREAKOUT.")
    print("  Para comparacion justa, re-correr v1.0b con EntryMode=MODE_BREAKOUT.")
    print("  MODE_CONFIRM tiene mas trades pero diferente dinamica de entrada.")
