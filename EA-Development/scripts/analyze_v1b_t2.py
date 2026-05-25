"""
Analisis TBR v1.0b Second Test — MODE_BREAKOUT vs T10 baseline
"""
import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

T2_PATH  = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\nas100 TBR v1.0b Second Test.xlsx"
T10_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 10 Test.xlsx"
VPP = 20.0
RR  = 3.0

def sf(v):
    try: f = float(v); return f if f != 0 else None
    except: return None

def detect_mode_and_parse(path):
    """Detecta si es CONFIRM o BREAKOUT y parsea en consecuencia."""
    df_raw = pd.read_excel(path, header=None)
    # Detectar modo en el header
    mode = 'BREAKOUT'
    for i in range(50):
        row_str = ' '.join(str(v) for v in df_raw.iloc[i])
        if 'EntryMode=0' in row_str:
            mode = 'CONFIRM'; break
        if 'EntryMode=1' in row_str:
            mode = 'BREAKOUT'; break

    entries, exits = [], []
    for _, row in df_raw.iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        typ = str(row[3]).strip().lower()
        vol4 = str(row[4]).strip()
        try: vol = float(vol4.split('/')[0].strip())
        except: continue

        if typ in ['buy', 'buy stop']:
            sl = sf(row[7]); tp = sf(row[8])
            p  = sf(row[6])
            if sl and tp and tp > sl:
                if p:  # BREAKOUT: precio de entrada disponible
                    sl_dist = p - sl
                else:  # CONFIRM: derivar de TP-SL
                    sl_dist = (tp - sl) / (RR + 1.0)
                    p = sl + sl_dist
                if sl_dist > 0:
                    entries.append({'open_time':t,'vol':vol,'price':p,'sl':sl,'tp':tp,'sl_dist':sl_dist})

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
    df['date']     = pd.to_datetime(df['open_time'].str[:10])
    df['year']     = df['date'].dt.year
    df['dow_name'] = df['date'].dt.day_name()
    df['win']      = (df['exit_type'] == 'TP').astype(int)
    df['profit']   = df.apply(lambda r:
        r['vol']*r['sl_dist']*VPP*RR if r['exit_type']=='TP'
        else (-r['vol']*r['sl_dist']*VPP if r['exit_type']=='SL' else 0), axis=1)
    return df, mode

def pf(df):
    gp = df[df['profit']>0]['profit'].sum()
    gl = abs(df[df['profit']<0]['profit'].sum())
    return gp/gl if gl>0 else 999

def stats(df):
    if len(df) < 5: return None
    tp = df['win'].sum()
    sl = (df['exit_type']=='SL').sum()
    to = len(df) - tp - sl
    return {'n':len(df),'pf':pf(df),'wr':df['win'].mean()*100,
            'net':df['profit'].sum(),'tp':tp,'sl':sl,'to':to}

def pr(s, label=''):
    if not s: return
    flag = 'OK' if s['pf']>=1.40 else ('~' if s['pf']>=1.30 else 'XX')
    print(f"  [{flag}] {label:20s} n={s['n']:4d}  PF={s['pf']:.3f}  WR={s['wr']:.1f}%  "
          f"Net=${s['net']:+.0f}  TP={s['tp']} SL={s['sl']} TO={s['to']}")

# ── Parsear ambos
t2,  mode2  = detect_mode_and_parse(T2_PATH)
t10, mode10 = detect_mode_and_parse(T10_PATH)

print("="*70)
print(f"TBR v1.0b Second Test [{mode2}]  vs  T10 [{mode10}]")
print("="*70)
print(f"  Periodo detectado v1.0b: {t2['year'].min()}-{t2['year'].max()}")
print(f"  Periodo detectado T10  : {t10['year'].min()}-{t10['year'].max()}\n")

IS  = (2022, 2023)
OOS = (2024, 2025)

print("GLOBAL:")
pr(stats(t2),  'v1.0b 2nd test')
pr(stats(t10), 'T10 baseline  ')

print("\nIS (2022-2023):")
pr(stats(t2[t2['year'].between(*IS)]),   'v1.0b')
pr(stats(t10[t10['year'].between(*IS)]), 'T10  ')

print("\nOOS (2024-2025):")
s_v_oo = stats(t2[t2['year'].between(*OOS)])
s_t_oo = stats(t10[t10['year'].between(*OOS)])
pr(s_v_oo, 'v1.0b')
pr(s_t_oo, 'T10  ')

print("\nPOR ANO:")
print(f"  {'Ano':6s} | {'v1.0b n':>7} {'PF':>7} {'WR':>7} | {'T10 n':>6} {'PF':>7} {'WR':>7}")
print("  " + "-"*58)
for yr in sorted(set(t2['year'].unique()) | set(t10['year'].unique())):
    gv = t2[t2['year']==yr]
    gt = t10[t10['year']==yr]
    pf_v = f"{pf(gv):.3f}" if len(gv)>=5 else "  n/a "
    wr_v = f"{gv['win'].mean()*100:.1f}%" if len(gv)>=5 else "  n/a "
    pf_t = f"{pf(gt):.3f}" if len(gt)>=5 else "  n/a "
    wr_t = f"{gt['win'].mean()*100:.1f}%" if len(gt)>=5 else "  n/a "
    print(f"  {yr}  | {len(gv):>7d} {pf_v:>7} {wr_v:>7} | {len(gt):>6d} {pf_t:>7} {wr_t:>7}")

print("\nPOR DIA:")
print(f"  {'Dia':12s} | {'v1.0b n':>7} {'PF':>7} {'WR':>7} | {'T10 n':>6} {'PF':>7} {'WR':>7}")
print("  " + "-"*58)
for day in ['Monday','Wednesday','Friday']:
    gv = t2[t2['dow_name']==day]
    gt = t10[t10['dow_name']==day]
    pf_v = f"{pf(gv):.3f}" if len(gv)>=5 else "  n/a "
    wr_v = f"{gv['win'].mean()*100:.1f}%" if len(gv)>=5 else "  n/a "
    pf_t = f"{pf(gt):.3f}" if len(gt)>=5 else "  n/a "
    wr_t = f"{gt['win'].mean()*100:.1f}%" if len(gt)>=5 else "  n/a "
    print(f"  {day:12s} | {len(gv):>7d} {pf_v:>7} {wr_v:>7} | {len(gt):>6d} {pf_t:>7} {wr_t:>7}")

print("\nTIPOS DE SALIDA:")
for label, df in [('v1.0b', t2), ('T10', t10)]:
    total = len(df)
    tp = df['win'].sum()
    sl = (df['exit_type']=='SL').sum()
    to = total - tp - sl
    print(f"  {label}: total={total}  TP={tp}({tp/total*100:.0f}%)  "
          f"SL={sl}({sl/total*100:.0f}%)  TO={to}({to/total*100:.0f}%)")

print("\nSL_DIST distribucion (pts):")
for label, df in [('v1.0b', t2), ('T10', t10)]:
    print(f"  {label}: min={df['sl_dist'].min():.1f}  "
          f"p25={df['sl_dist'].quantile(.25):.1f}  "
          f"med={df['sl_dist'].median():.1f}  "
          f"p75={df['sl_dist'].quantile(.75):.1f}  "
          f"max={df['sl_dist'].max():.1f}")

print("\n" + "="*70)
print("VEREDICTO")
print("="*70)
sv = stats(t2); st = stats(t10)
if sv and st and s_v_oo and s_t_oo:
    delta_pf     = sv['pf']     - st['pf']
    delta_oos_pf = s_v_oo['pf'] - s_t_oo['pf']
    delta_n      = sv['n']      - st['n']
    print(f"\n  PF global : v1.0b={sv['pf']:.3f}  T10={st['pf']:.3f}  delta={delta_pf:+.3f}")
    print(f"  OOS PF    : v1.0b={s_v_oo['pf']:.3f}  T10={s_t_oo['pf']:.3f}  delta={delta_oos_pf:+.3f}")
    print(f"  Trades    : v1.0b={sv['n']}  T10={st['n']}  delta={delta_n:+d}")
    print()
    if sv['pf'] >= 1.40 and s_v_oo['pf'] >= 1.40:
        print("  [OK] v1.0b supera umbral PF>=1.40 global Y OOS — listo para optimizacion")
    elif sv['pf'] >= 1.30:
        print("  [~] v1.0b marginal — proceder con optimizacion para subir OOS PF")
    else:
        print("  [XX] v1.0b por debajo de T10 — revisar configuracion del test")
    if abs(delta_n) > 30:
        print(f"  [!] Diferencia de {delta_n:+d} trades — verificar mismos parametros de dias/sesion")
