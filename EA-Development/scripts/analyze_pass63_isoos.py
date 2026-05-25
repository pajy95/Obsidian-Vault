"""
Analisis IS/OOS — Pass #63 (Candles=2, StartMin=15, RR=4.0)
Compara rendimiento IS (2022-2023) vs OOS (2024-2025) vs T10 baseline
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

IS_PATH  = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\IS TBR NAS100 V1B.xlsx"
OOS_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\OOS TBR NAS100 V1B.xlsx"
T10_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 10 Test.xlsx"
VPP = 20.0
RR  = 4.0   # pass #63

def sf(v):
    try: f = float(v); return f if f != 0 else None
    except: return None

def parse_breakout(path):
    df_raw = pd.read_excel(path, header=None)
    entries, exits = [], []
    for _, row in df_raw.iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        typ = str(row[3]).strip().lower()
        vol4 = str(row[4]).strip()
        try: vol = float(vol4.split('/')[0].strip())
        except: continue

        if typ in ['buy', 'buy stop']:
            p = sf(row[6]); sl = sf(row[7]); tp = sf(row[8])
            if p and sl and tp and p > sl:
                entries.append({'open_time': t, 'vol': vol, 'price': p,
                                'sl': sl, 'tp': tp, 'sl_dist': p - sl})
        elif typ == 'sell':
            comment = str(row[len(row)-1]).strip().lower()
            cp = sf(row[6])
            if 'tp' in comment:               et = 'TP'
            elif 'sl' in comment:             et = 'SL'
            elif comment in ['nan', '']:      et = 'Timeout'
            else:                             et = 'Other'
            exits.append({'exit_type': et, 'close_price': cp, 'close_time': t})

    df_e = pd.DataFrame(entries).reset_index(drop=True)
    df_x = pd.DataFrame(exits).reset_index(drop=True)
    n = min(len(df_e), len(df_x))
    df = df_e.iloc[:n].copy()
    df['exit_type']  = df_x.iloc[:n]['exit_type'].values
    df['close_time'] = df_x.iloc[:n]['close_time'].values
    df['date']       = pd.to_datetime(df['open_time'].str[:10])
    df['year']       = df['date'].dt.year
    df['dow_name']   = df['date'].dt.day_name()
    df['win']        = (df['exit_type'] == 'TP').astype(int)
    df['profit']     = df.apply(lambda r:
        r['vol'] * r['sl_dist'] * VPP * RR if r['exit_type'] == 'TP'
        else (-r['vol'] * r['sl_dist'] * VPP if r['exit_type'] == 'SL' else 0), axis=1)
    return df

def pf(df):
    gp = df[df['profit'] > 0]['profit'].sum()
    gl = abs(df[df['profit'] < 0]['profit'].sum())
    return gp / gl if gl > 0 else 999.0

def stats(df):
    if len(df) < 5: return None
    tp = int(df['win'].sum())
    sl = int((df['exit_type'] == 'SL').sum())
    to = len(df) - tp - sl
    return {'n': len(df), 'pf': pf(df), 'wr': df['win'].mean() * 100,
            'net': df['profit'].sum(), 'tp': tp, 'sl': sl, 'to': to,
            'dd_approx': abs(df['profit'].cumsum().cummin().min())}

def pr(s, label='', flag_threshold=1.40):
    if not s: print(f"  {label}: n/a"); return
    flag = 'OK' if s['pf'] >= flag_threshold else ('~' if s['pf'] >= 1.30 else 'XX')
    print(f"  [{flag}] {label:22s} n={s['n']:4d}  PF={s['pf']:.3f}  WR={s['wr']:.1f}%  "
          f"Net=${s['net']:+.0f}  TP={s['tp']} SL={s['sl']} TO={s['to']}")

# ── Parsear
is_df  = parse_breakout(IS_PATH)
oos_df = parse_breakout(OOS_PATH)

# T10 solo en sus periodos equivalentes para comparacion
t10_df = parse_breakout(T10_PATH)
t10_is  = t10_df[t10_df['year'].between(2022, 2023)]
t10_oos = t10_df[t10_df['year'].between(2024, 2025)]

s_is  = stats(is_df)
s_oos = stats(oos_df)
s_t10_is  = stats(t10_is)
s_t10_oos = stats(t10_oos)

print("=" * 70)
print("PASS #63 — Candles=2, SessionStart_Min=15, RR=4.0")
print("=" * 70)
print(f"  IS  periodo: {is_df['year'].min()}-{is_df['year'].max()}  ({len(is_df)} trades)")
print(f"  OOS periodo: {oos_df['year'].min()}-{oos_df['year'].max()}  ({len(oos_df)} trades)\n")

print("IS (2022-2023):")
pr(s_is,      'Pass #63')
pr(s_t10_is,  'T10 baseline ')

print("\nOOS (2024-2025):")
pr(s_oos,     'Pass #63')
pr(s_t10_oos, 'T10 baseline ')

# ── Ratio OOS/IS
print("\nRATIO OOS/IS (criterio >= 0.50):")
if s_is and s_oos:
    ratio_pf = s_oos['pf'] / s_is['pf']
    ratio_wr = (s_oos['wr'] / s_is['wr']) if s_is['wr'] > 0 else 0
    flag_ratio = 'OK' if ratio_pf >= 0.50 else 'XX'
    print(f"  [{flag_ratio}] PF ratio  : OOS/IS = {s_oos['pf']:.3f}/{s_is['pf']:.3f} = {ratio_pf:.3f}  (min 0.50)")
    print(f"       WR ratio  : OOS/IS = {s_oos['wr']:.1f}%/{s_is['wr']:.1f}% = {ratio_wr:.3f}")

# ── Por ano
print("\nPOR ANO:")
print(f"  {'Ano':6s} | {'n':>4} {'PF':>7} {'WR':>7} {'Net':>9}")
print("  " + "-" * 40)
all_df = pd.concat([is_df, oos_df]).reset_index(drop=True)
all_df['profit'] = all_df.apply(lambda r:
    r['vol'] * r['sl_dist'] * VPP * RR if r['exit_type'] == 'TP'
    else (-r['vol'] * r['sl_dist'] * VPP if r['exit_type'] == 'SL' else 0), axis=1)

for yr in sorted(all_df['year'].unique()):
    g = all_df[all_df['year'] == yr]
    label = '  IS  ' if yr <= 2023 else '  OOS '
    pf_v = f"{pf(g):.3f}" if len(g) >= 5 else "  n/a "
    wr_v = f"{g['win'].mean()*100:.1f}%" if len(g) >= 5 else "  n/a "
    net_v = f"${g['profit'].sum():+.0f}"
    print(f"{label}{yr}  | {len(g):>4} {pf_v:>7} {wr_v:>7} {net_v:>9}")

# ── Por dia (OOS solamente — lo que importa)
print("\nPOR DIA (OOS 2024-2025):")
for day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']:
    g = oos_df[oos_df['dow_name'] == day]
    if len(g) >= 5:
        print(f"  {day[:3]}: n={len(g):4d}  PF={pf(g):.3f}  WR={g['win'].mean()*100:.1f}%  "
              f"Net=${g['profit'].sum():+.0f}")

# ── Tipos de salida
print("\nTIPOS DE SALIDA:")
for label, df in [('IS  Pass#63', is_df), ('OOS Pass#63', oos_df)]:
    total = len(df)
    tp = int(df['win'].sum())
    sl = int((df['exit_type'] == 'SL').sum())
    to = total - tp - sl
    print(f"  {label}: total={total}  TP={tp}({tp/total*100:.0f}%)  "
          f"SL={sl}({sl/total*100:.0f}%)  TO={to}({to/total*100:.0f}%)")

# ── SL_dist
print("\nSL_DIST distribucion (pts):")
for label, df in [('IS', is_df), ('OOS', oos_df)]:
    print(f"  {label}: min={df['sl_dist'].min():.1f}  "
          f"p25={df['sl_dist'].quantile(.25):.1f}  "
          f"med={df['sl_dist'].median():.1f}  "
          f"p75={df['sl_dist'].quantile(.75):.1f}  "
          f"max={df['sl_dist'].max():.1f}")

# ── VEREDICTO FORMAL
print("\n" + "=" * 70)
print("VEREDICTO FORMAL")
print("=" * 70)

criterios = []
ok_count = 0

def chk(cond, label, detail=''):
    flag = 'OK' if cond else 'XX'
    if cond: pass
    criterios.append((flag, label, detail))

if s_oos and s_is:
    chk(s_oos['pf'] >= 1.40,   f"OOS PF >= 1.40",           f"actual={s_oos['pf']:.3f}")
    chk(s_is['pf']  >= 1.40,   f"IS  PF >= 1.40",           f"actual={s_is['pf']:.3f}")
    ratio = s_oos['pf'] / s_is['pf']
    chk(ratio >= 0.50,          f"OOS/IS ratio >= 0.50",     f"actual={ratio:.3f}")
    chk(s_oos['n']  >= 30,      f"OOS trades >= 30",         f"actual={s_oos['n']}")
    chk(s_oos['wr'] >= 25.0,   f"OOS WR >= 25%",            f"actual={s_oos['wr']:.1f}%")

print()
ok = sum(1 for f,_,_ in criterios if f == 'OK')
for flag, label, detail in criterios:
    print(f"  [{flag}] {label:30s}  {detail}")

print()
if ok == len(criterios):
    print("  VIABLE — Todos los criterios superados. Avanzar a Fase 2 (Breakeven).")
elif ok >= 3:
    print("  MARGINAL — Mayoria de criterios cumplidos. Analizar debilidades antes de Fase 2.")
else:
    print("  NO VIABLE — No supera criterios minimos.")

if s_oos and s_t10_oos:
    delta = s_oos['pf'] - s_t10_oos['pf']
    print(f"\n  vs T10 baseline OOS: Pass#63={s_oos['pf']:.3f}  T10={s_t10_oos['pf']:.3f}  "
          f"delta={delta:+.3f} {'(MEJORA)' if delta > 0 else '(PEOR)'}")
