"""
Analisis IS/OOS — P63 (5dias), P63 (L/M/X), P49 (5dias) vs T10
Split: IS=2022-2024 / OOS=2025  (metodologia BNY)
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

BASE = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests"
VPP = 20.0
IS_YEARS  = (2022, 2024)
OOS_YEARS = (2025, 2025)

CONFIGS = {
    'P63 5dias': {'is': f"{BASE}\\IS TBR NAS100 V1B.xlsx",
                  'oos': f"{BASE}\\OOS TBR NAS100 V1B.xlsx",             'rr': 4.0},
    'P63 L/M/X': {'is': f"{BASE}\\IS tbr nas100 v1b pass63 no JV.xlsx",
                  'oos': f"{BASE}\\OOS tbr nas100 v1b pass63 no JV.xlsx", 'rr': 4.0},
    'P49 5dias': {'is': f"{BASE}\\IS TBR NAS100 V1B PASS49.xlsx",
                  'oos': f"{BASE}\\OOS TBR NAS100 V1B PASS49.xlsx",       'rr': 3.6},
    'T10 L/X/V': {'file': f"{BASE}\\NAS100 TBR M5 10 Test.xlsx",          'rr': 3.0},
}

def sf(v):
    try: f = float(v); return f if f != 0 else None
    except: return None

def parse(path, rr):
    df_raw = pd.read_excel(path, header=None)
    entries, exits = [], []
    for _, row in df_raw.iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t): continue
        typ = str(row[3]).strip().lower()
        try: vol = float(str(row[4]).strip().split('/')[0].strip())
        except: continue
        if typ in ['buy', 'buy stop']:
            p = sf(row[6]); sl = sf(row[7]); tp = sf(row[8])
            if p and sl and tp and p > sl:
                entries.append({'open_time': t, 'vol': vol, 'price': p,
                                'sl': sl, 'tp': tp, 'sl_dist': p - sl})
        elif typ == 'sell':
            comment = str(row[len(row)-1]).strip().lower()
            et = 'TP' if 'tp' in comment else ('SL' if 'sl' in comment else
                 ('Timeout' if comment in ['nan',''] else 'Other'))
            exits.append({'exit_type': et, 'close_price': sf(row[6]), 'close_time': t})
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
        r['vol']*r['sl_dist']*VPP*rr if r['exit_type']=='TP'
        else (-r['vol']*r['sl_dist']*VPP if r['exit_type']=='SL' else 0), axis=1)
    return df

def pf(df):
    gp = df[df['profit']>0]['profit'].sum()
    gl = abs(df[df['profit']<0]['profit'].sum())
    return gp/gl if gl>0 else 999.0

def stats(df):
    if df is None or len(df)<5: return None
    tp = int(df['win'].sum()); sl = int((df['exit_type']=='SL').sum())
    cum = df['profit'].cumsum()
    return {'n': len(df), 'pf': pf(df), 'wr': df['win'].mean()*100,
            'net': df['profit'].sum(), 'tp': tp, 'sl': sl, 'to': len(df)-tp-sl,
            'max_dd': abs((cum-cum.cummax()).min())}

def pr(s, label=''):
    if not s: print(f"  {'n/a':24s}  n/a"); return
    flag = 'OK' if s['pf']>=1.40 else ('~' if s['pf']>=1.30 else 'XX')
    print(f"  [{flag}] {label:22s}  n={s['n']:4d}  PF={s['pf']:.3f}  WR={s['wr']:.1f}%  "
          f"Net=${s['net']:+.0f}  MaxDD=${s['max_dd']:.0f}  "
          f"TP={s['tp']} SL={s['sl']} TO={s['to']}")

# ── Cargar
data = {}
for name, cfg in CONFIGS.items():
    rr = cfg['rr']
    if 'file' in cfg:  # T10 — un solo archivo, filtrar por año
        all_df = parse(cfg['file'], rr)
        data[name] = {
            'is':  all_df[all_df['year'].between(*IS_YEARS)],
            'oos': all_df[all_df['year'].between(*OOS_YEARS)],
        }
    else:
        data[name] = {'is': parse(cfg['is'], rr), 'oos': parse(cfg['oos'], rr)}

s = {name: {'is': stats(data[name]['is']), 'oos': stats(data[name]['oos'])}
     for name in data}

# ── Header
print("="*70)
print("TBR v1.0b — COMPARACION IS/OOS  (IS=2022-2024 / OOS=2025)")
print("="*70)
print(f"\n  {'Config':22s}  IS n   OOS n")
print("  "+"-"*40)
for name in data:
    ni = data[name]['is'].shape[0]; no = data[name]['oos'].shape[0]
    print(f"  {name:22s}  {ni:5d}  {no:5d}")

# ── IS
print("\n\nIS (2022-2024):")
for name in data: pr(s[name]['is'], name)

# ── OOS
print("\nOOS (2025):")
for name in data: pr(s[name]['oos'], name)

# ── Ratio
print("\nRATIO OOS/IS (min 0.50):")
for name in data:
    si=s[name]['is']; so=s[name]['oos']
    if si and so:
        r = so['pf']/si['pf']
        flag = 'OK' if r>=0.50 else 'XX'
        print(f"  [{flag}] {name:22s}  {so['pf']:.3f}/{si['pf']:.3f} = {r:.3f}")

# ── Por año — solo P63 L/M/X (el candidato principal)
print("\nPOR ANO — P63 L/M/X (RR=4.0, sin Jue/Vie):")
key = 'P63 L/M/X'
all_df = pd.concat([data[key]['is'], data[key]['oos']]).reset_index(drop=True)
print(f"  {'Ano':6} | {'n':>4} {'PF':>7} {'WR':>7} {'Net':>9}  Periodo")
print("  "+"-"*47)
for yr in sorted(all_df['year'].unique()):
    g = all_df[all_df['year']==yr]
    periodo = 'OOS' if yr>=OOS_YEARS[0] else 'IS '
    pf_v = f"{pf(g):.3f}" if len(g)>=5 else "  n/a"
    wr_v = f"{g['win'].mean()*100:.1f}%" if len(g)>=5 else "  n/a"
    print(f"  {yr}  | {len(g):>4} {pf_v:>7} {wr_v:>7} ${g['profit'].sum():>+8.0f}  {periodo}")

# ── Por dia OOS
print("\nPOR DIA OOS 2025:")
print(f"  {'Dia':10} | {'P63-5d':>8} {'P63-LMX':>8} {'P49-5d':>8} {'T10':>8}")
print("  "+"-"*50)
for day in ['Monday','Tuesday','Wednesday','Thursday','Friday']:
    vals = []
    for name in data:
        g = data[name]['oos']
        gd = g[g['dow_name']==day]
        vals.append(f"{pf(gd):.3f}" if len(gd)>=5 else "  n/a")
    print(f"  {day[:3]:10} | {vals[0]:>8} {vals[1]:>8} {vals[2]:>8} {vals[3]:>8}")

# ── Veredicto formal
print("\n"+"="*70)
print("VEREDICTO FORMAL")
print("="*70)
for name in data:
    si=s[name]['is']; so=s[name]['oos']
    print(f"\n  [{name}]")
    if not si or not so: print("  Datos insuficientes"); continue
    checks = [
        (so['pf']>=1.40,        "OOS PF >= 1.40",       f"{so['pf']:.3f}"),
        (si['pf']>=1.40,        "IS  PF >= 1.40",        f"{si['pf']:.3f}"),
        (so['pf']/si['pf']>=0.50,"OOS/IS ratio >= 0.50", f"{so['pf']/si['pf']:.3f}"),
        (so['n']>=30,           "OOS trades >= 30",      f"{so['n']}"),
        (so['wr']>=25.0,        "OOS WR >= 25%",         f"{so['wr']:.1f}%"),
    ]
    ok = sum(1 for c,_,_ in checks if c)
    for cond, lbl, val in checks:
        print(f"  [{'OK' if cond else 'XX'}] {lbl:30s}  {val}")
    verdict = "VIABLE" if ok==5 else ("MARGINAL" if ok>=3 else "NO VIABLE")
    print(f"  => {verdict} ({ok}/5)")

# ── Resumen final
print("\n"+"="*70)
print("RESUMEN COMPARATIVO OOS 2025")
print("="*70)
names = list(data.keys())
header = f"  {'Metrica':28s}" + "".join(f" {n[:8]:>9}" for n in names)
print(header)
print("  "+"-"*70)
metricas = [("PF",'pf','{:.3f}'), ("WR %",'wr','{:.1f}'),
            ("Net $",'net','{:+.0f}'), ("MaxDD $",'max_dd','{:.0f}'),
            ("n trades",'n','{:d}'), ("TP",'tp','{:d}'), ("SL",'sl','{:d}')]
for lbl, key, fmt in metricas:
    row = f"  {lbl:28s}"
    for name in names:
        so = s[name]['oos']
        v = fmt.format(int(so[key]) if fmt=='{:d}' else so[key]) if so else 'n/a'
        row += f" {v:>9}"
    print(row)
