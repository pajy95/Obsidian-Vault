"""
Investigación de mejoras TBR — análisis profundo T10
Busca patrones en: día, hora, tamaño rango, RR óptimo, secuencias
"""
import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

T10_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 10 Test.xlsx"
NR_PATH  = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\NAS100 V1 NR M3.xlsx"
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
            try: f=float(v); return f if f!=0 else None
            except: return None
        if typ in ['buy','buy stop']:
            p=sf(row[6]); sl=sf(row[7]); tp=sf(row[8])
            if p and sl and tp:
                entries.append({'open_time':t,'vol':vol,'price':p,'sl':sl,'tp':tp,'sl_dist':p-sl})
        elif typ == 'sell':
            comment = str(row[len(row)-1]).strip().lower()
            cp = sf(row[6])
            if 'tp' in comment: et='TP'
            elif 'sl' in comment: et='SL'
            elif comment in ['nan','']: et='Timeout'
            else: et='Other'
            exits.append({'exit_type':et,'close_price':cp,'close_time':t})
    df_e = pd.DataFrame(entries).reset_index(drop=True)
    df_x = pd.DataFrame(exits).reset_index(drop=True)
    n = min(len(df_e), len(df_x))
    df = df_e.iloc[:n].copy()
    df['exit_type']  = df_x.iloc[:n]['exit_type'].values
    df['close_time'] = df_x.iloc[:n]['close_time'].values
    df['close_price']= df_x.iloc[:n]['close_price'].values
    df['date'] = pd.to_datetime(df['open_time'].str[:10])
    df['year'] = df['date'].dt.year
    df['month']= df['date'].dt.month
    df['dow']  = df['date'].dt.dayofweek   # 0=Lun, 2=Mie, 4=Vie
    df['dow_name'] = df['date'].dt.day_name()
    df['hour'] = df['open_time'].str[11:13].astype(int)
    df['min']  = df['open_time'].str[14:16].astype(int)
    df['entry_min'] = df['hour']*60 + df['min']  # minutos desde medianoche
    df['win']  = (df['exit_type']=='TP').astype(int)
    # Profit con RR real
    df['profit_rr3'] = df.apply(lambda r:
        r['vol']*r['sl_dist']*VPP*3 if r['exit_type']=='TP'
        else (-r['vol']*r['sl_dist']*VPP if r['exit_type']=='SL' else 0), axis=1)
    return df

def pf(df, col='profit_rr3'):
    gp = df[df[col]>0][col].sum()
    gl = abs(df[df[col]<0][col].sum())
    return gp/gl if gl>0 else 999

def stats(df, label='', col='profit_rr3'):
    if len(df)==0: return None
    p = pf(df, col)
    wr = df['win'].mean()*100
    net = df[col].sum()
    n = len(df)
    tp = df['win'].sum()
    sl = (df['exit_type']=='SL').sum()
    return {'label':label,'n':n,'pf':p,'wr':wr,'net':net,'tp':tp,'sl':sl}

def print_stats(s):
    if s: print(f"  {s['label']:25s}: n={s['n']:4d}  PF={s['pf']:.3f}  WR={s['wr']:.1f}%  Net=${s['net']:+.0f}  TP={s['tp']} SL={s['sl']}")

t10 = parse_trades(T10_PATH, 97)
nr  = parse_trades(NR_PATH, 126)

# ── 1. DÍA DE LA SEMANA ──────────────────────────────────────────────────
print("="*65)
print("1. POR DÍA DE SEMANA")
print("="*65)
for day in ['Monday','Wednesday','Friday']:
    grp = t10[t10['dow_name']==day]
    s = stats(grp, day)
    print_stats(s)

# ── 2. HORA DE ENTRADA ───────────────────────────────────────────────────
print()
print("="*65)
print("2. POR HORA DE ENTRADA (UTC servidor = UTC+2, sesión 16:27-19:00 srv)")
print("="*65)
for h in sorted(t10['hour'].unique()):
    grp = t10[t10['hour']==h]
    s = stats(grp, f"hora {h:02d}:xx")
    print_stats(s)

# ── 3. VENTANA DE ENTRADA (primeros N minutos de sesión) ─────────────────
print()
print("="*65)
print("3. VENTANA DE ENTRADA (minutos desde SessionStart=16:27 srv)")
print("   ¿Entradas tempranas vs tardías?")
print("="*65)
session_start_min = 16*60 + 27
t10['mins_after_open'] = t10['entry_min'] - session_start_min
buckets = [(0,5,'0-5 min'),(5,15,'5-15 min'),(15,30,'15-30 min'),
           (30,60,'30-60 min'),(60,120,'1-2h'),(120,999,'2h+')]
for lo,hi,label in buckets:
    grp = t10[(t10['mins_after_open']>=lo)&(t10['mins_after_open']<hi)]
    s = stats(grp, label)
    print_stats(s)

# ── 4. TAMAÑO DEL RANGO (SL_dist como proxy) ────────────────────────────
print()
print("="*65)
print("4. TAMAÑO DE RANGO (SL_dist en quintiles)")
print("   Rango pequeño vs grande — ¿cuál tiene mejor edge?")
print("="*65)
t10['sl_quintile'] = pd.qcut(t10['sl_dist'], 5, labels=['Q1 (peq)','Q2','Q3','Q4','Q5 (gde)'])
for q in ['Q1 (peq)','Q2','Q3','Q4','Q5 (gde)']:
    grp = t10[t10['sl_quintile']==q]
    rng = f"{grp['sl_dist'].min():.1f}-{grp['sl_dist'].max():.1f}pts"
    s = stats(grp, f"{q} [{rng}]")
    print_stats(s)

# ── 5. RR ÓPTIMO SIMULADO ────────────────────────────────────────────────
print()
print("="*65)
print("5. SIMULACIÓN RR ÓPTIMO")
print("   Usando precios reales — ¿cuántos TP se habrían alcanzado con RR menor?")
print("="*65)

# Para trades que hicieron SL: con RR menor habrían hecho TP si el precio
# llegó al TP reducido antes del SL. Aproximación: usamos sl_dist y precio
# No tenemos el precio intra-trade, pero podemos analizar la distribución teórica.
# Mejor: analizar WR real por quintil de sl_dist y estimar PF por RR.

# Análisis matemático puro: dado WR observado, ¿qué RR maximiza PF?
# PF(rr) = (WR * rr) / ((1-WR) * 1)
wr_global = t10['win'].mean()

print(f"\n  WR global observado: {wr_global*100:.1f}%")
print(f"  PF = (WR x RR) / (1-WR)\n")
for rr_test in [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]:
    pf_teorico = (wr_global * rr_test) / ((1-wr_global) * 1)
    # Pero WR cambia con RR — si RR baja, más trades llegarán al TP
    # Estimación: con SL fijo y TP más cercano, WR_ajustado depende de
    # la distribución de MAE/MFE que no tenemos directamente.
    # Usamos WR puro como lower bound.
    print(f"  RR={rr_test:.1f}: PF_min={pf_teorico:.3f}  (asume WR={wr_global*100:.1f}% constante)")

# WR necesario para PF=1.40 con cada RR
print(f"\n  WR necesario para PF=1.40:")
for rr_test in [1.0, 1.5, 2.0, 2.5, 3.0, 3.5]:
    wr_needed = 1.40 / (1.40 + rr_test)
    print(f"  RR={rr_test:.1f}: WR necesario = {wr_needed*100:.1f}%  (actual={wr_global*100:.1f}%)")

# ── 6. ANÁLISIS POR DÍA + AÑO ────────────────────────────────────────────
print()
print("="*65)
print("6. MATRIZ DÍA x AÑO")
print("="*65)
pivot = t10.groupby(['year','dow_name']).apply(
    lambda g: pd.Series({
        'n': len(g),
        'PF': pf(g),
        'WR': g['win'].mean()*100
    })
).reset_index()
for yr in sorted(t10['year'].unique()):
    row = pivot[pivot['year']==yr]
    parts = []
    for day in ['Monday','Wednesday','Friday']:
        r = row[row['dow_name']==day]
        if len(r):
            parts.append(f"{day[:3]}:PF={r['PF'].values[0]:.2f}/WR={r['WR'].values[0]:.0f}%")
    print(f"  {yr}: {' | '.join(parts)}")

# ── 7. FILTRO COMBINADO: Día + Rango ─────────────────────────────────────
print()
print("="*65)
print("7. FILTRO COMBINADO: Solo Miércoles")
print("="*65)
wed = t10[t10['dow_name']=='Wednesday']
print_stats(stats(wed, 'Solo Miercoles (global)'))
for yr, grp in wed.groupby('year'):
    s = stats(grp, f'  Miercoles {yr}')
    print_stats(s)

# ── 8. FILTRO: Rango pequeño (Q1+Q2 sl_dist <= p40) ─────────────────────
print()
print("="*65)
print("8. FILTRO RANGO — solo rangos 'tight' (SL_dist <= percentil 40)")
print("="*65)
p40 = t10['sl_dist'].quantile(0.40)
p60 = t10['sl_dist'].quantile(0.60)
tight = t10[t10['sl_dist'] <= p40]
mid   = t10[(t10['sl_dist'] > p40) & (t10['sl_dist'] <= p60)]
wide  = t10[t10['sl_dist'] > p60]
print(f"  Tight (<=p40, <={p40:.1f}pts):", end=''); print_stats(stats(tight, ''))
print(f"  Mid   (p40-p60, {p40:.1f}-{p60:.1f}pts):", end=''); print_stats(stats(mid, ''))
print(f"  Wide  (>p60, >={p60:.1f}pts):", end=''); print_stats(stats(wide, ''))

# ── 9. OR_FACTOR — rango relativo al precio ──────────────────────────────
print()
print("="*65)
print("9. OR_FACTOR = SL_dist / price (rango normalizado por precio)")
print("   Proxy del tamaño del rango en % del precio")
print("="*65)
t10['or_factor'] = t10['sl_dist'] / t10['price'] * 100
t10['or_q'] = pd.qcut(t10['or_factor'], 4, labels=['Q1 tight','Q2','Q3','Q4 wide'])
for q in ['Q1 tight','Q2','Q3','Q4 wide']:
    grp = t10[t10['or_q']==q]
    rng = f"{grp['or_factor'].min():.3f}-{grp['or_factor'].max():.3f}%"
    s = stats(grp, f"{q} [{rng}]")
    print_stats(s)

# ── 10. ANÁLISIS SECUENCIAL ───────────────────────────────────────────────
print()
print("="*65)
print("10. ANÁLISIS SECUENCIAL — tras pérdida, ¿mejora el siguiente?")
print("="*65)
t10_s = t10.copy().reset_index(drop=True)
t10_s['prev_win'] = t10_s['win'].shift(1)
after_win  = t10_s[t10_s['prev_win']==1]
after_loss = t10_s[t10_s['prev_win']==0]
print_stats(stats(after_win,  'Tras ganancia'))
print_stats(stats(after_loss, 'Tras perdida '))

# ── 11. MEJOR COMBINACIÓN DETECTADA ──────────────────────────────────────
print()
print("="*65)
print("11. RESUMEN — FILTROS QUE MEJORAN EL EDGE")
print("="*65)

combos = [
    ('Solo Miercoles',                    t10[t10['dow_name']=='Wednesday']),
    ('Tight range (<=p40)',               t10[t10['sl_dist']<=p40]),
    ('Mie + Tight range',                 t10[(t10['dow_name']=='Wednesday')&(t10['sl_dist']<=p40)]),
    ('Hora <17h srv (early entry)',       t10[t10['hour']<17]),
    ('Mie + hora <17h',                   t10[(t10['dow_name']=='Wednesday')&(t10['hour']<17)]),
    ('Q1+Q2 OR_factor (tight %)',         t10[t10['or_factor']<=t10['or_factor'].quantile(0.5)]),
]
for label, grp in combos:
    s = stats(grp, label)
    if s and s['n'] >= 30:
        print_stats(s)
