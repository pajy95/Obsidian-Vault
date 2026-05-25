"""
Candidatos de filtro de rango para TBR — sin sacrificar operaciones
Enfoque: filtros RELATIVOS y DINÁMICOS, no cortes absolutos
"""
import pandas as pd, numpy as np, warnings, re
warnings.filterwarnings('ignore')

T10_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 10 Test.xlsx"
VPP = 20.0

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
    df['date'] = pd.to_datetime(df['open_time'].str[:10])
    df['year'] = df['date'].dt.year
    df['dow_name'] = df['date'].dt.day_name()
    df['win'] = (df['exit_type']=='TP').astype(int)
    df['profit'] = df.apply(lambda r:
        r['vol']*r['sl_dist']*VPP*3 if r['exit_type']=='TP'
        else (-r['vol']*r['sl_dist']*VPP if r['exit_type']=='SL' else 0), axis=1)
    return df

def pf(df):
    gp = df[df['profit']>0]['profit'].sum()
    gl = abs(df[df['profit']<0]['profit'].sum())
    return gp/gl if gl>0 else 999

def stats_row(df, label):
    if len(df) < 20: return
    p = pf(df)
    wr = df['win'].mean()*100
    net = df['profit'].sum()
    return {'label':label,'n':len(df),'pf':p,'wr':wr,'net':net}

def print_row(s, base_n=623):
    if not s: return
    pct = s['n']/base_n*100
    flag = 'OK' if s['pf']>=1.40 else ('~' if s['pf']>=1.30 else 'XX')
    print(f"  [{flag}] {s['label']:40s} n={s['n']:4d} ({pct:5.1f}%)  PF={s['pf']:.3f}  WR={s['wr']:.1f}%  Net=${s['net']:+.0f}")

t10 = parse_trades(T10_PATH, 97)
BASE = len(t10)

# ── Construir features de filtro ─────────────────────────────────────────

# F1: OR_Factor = sl_dist / price × 100  (% del precio)
t10['or_pct'] = t10['sl_dist'] / t10['price'] * 100

# F2: Rolling ATR proxy — desviación estándar de sl_dist en ventana 20 trades
#     Simula ATR sin datos OHLC — sl_dist es el rango real de la vela de sesión
t10['sl_rolling_median'] = t10['sl_dist'].rolling(20, min_periods=5).median()
t10['sl_rolling_std']    = t10['sl_dist'].rolling(20, min_periods=5).std()
t10['sl_zscore']         = (t10['sl_dist'] - t10['sl_rolling_median']) / (t10['sl_rolling_std'] + 1e-6)

# F3: Ratio vs percentile rolling (percentile 50 de los últimos 30 trades)
t10['sl_roll_p50'] = t10['sl_dist'].rolling(30, min_periods=10).quantile(0.50)
t10['sl_roll_p75'] = t10['sl_dist'].rolling(30, min_periods=10).quantile(0.75)
t10['sl_vs_p50']   = t10['sl_dist'] / (t10['sl_roll_p50'] + 1e-6)

# F4: Spread/Range ratio proxy — sin datos de spread, usamos sl_dist mínima aceptable
#     TP = sl_dist × 3. Spread estimado ~2-3 pts en NDX100.
#     Si spread > X% del TP → skip. Usamos sl_dist como proxy: sl_dist < umbral
SPREAD_EST = 2.5   # pts estimados de spread NDX100
RR_VAL = 3.0
t10['spread_pct_tp'] = SPREAD_EST / (t10['sl_dist'] * RR_VAL) * 100

# F5: Rango normalizado por precio en escala logarítmica
t10['log_or'] = np.log(t10['sl_dist'] / t10['price'] * 10000)  # log(bps)

# ── Filtros base para comparar ───────────────────────────────────────────
print("="*75)
print("BASELINE")
print("="*75)
print_row(stats_row(t10, 'Sin filtro (baseline)'), BASE)

print()
print("="*75)
print("CANDIDATO 1 — OR_Pct: rango como % del precio (dinámico por precio)")
print("  Ventaja: se ajusta automáticamente al nivel de precios (NDX 14K vs 21K)")
print("  Desventaja: no captura cambios de volatilidad del mercado")
print("="*75)

# Distribución
print(f"\n  Distribución OR_Pct:")
for pct_val in [0.04, 0.06, 0.08, 0.10, 0.12, 0.15]:
    grp = t10[t10['or_pct'] <= pct_val]
    s = stats_row(grp, f'OR_Pct <= {pct_val:.2f}%')
    print_row(s, BASE)

print(f"\n  Corte superior (excluir rangos grandes):")
for pct_val in [0.08, 0.10, 0.12, 0.15]:
    grp = t10[t10['or_pct'] <= pct_val]
    s = stats_row(grp, f'OR_Pct <= {pct_val:.2f}% (excluye gigantes)')
    print_row(s, BASE)

print()
print("="*75)
print("CANDIDATO 2 — Z-Score rolling: rango vs su propia historia reciente (20 trades)")
print("  Ventaja: captura 'rango pequeño PARA LAS CONDICIONES ACTUALES'")
print("  No sacrifica trades en períodos de alta volatilidad")
print("  Desventaja: requiere warm-up de 20 trades")
print("="*75)

for z in [-0.5, -0.3, 0.0, 0.3, 0.5, 1.0]:
    grp = t10[t10['sl_zscore'] <= z]
    s = stats_row(grp, f'Z-score <= {z:+.1f}')
    print_row(s, BASE)

print()
print("="*75)
print("CANDIDATO 3 — Percentil rolling (30 trades): rango vs su mediana reciente")
print("  Ventaja: 50% de los trades siempre pasan (no corta frecuencia a la mitad)")
print("  Al usar percentil 75: 75% pasan siempre — pérdida mínima de trades")
print("  Desventaja: siempre filtra el mismo porcentaje, sin importar condiciones")
print("="*75)

for threshold in [0.6, 0.8, 1.0, 1.2, 1.5]:
    grp = t10[t10['sl_vs_p50'] <= threshold]
    label = f'sl_dist <= {threshold:.1f}x mediana_rolling(30)'
    s = stats_row(grp, label)
    print_row(s, BASE)

print()
print("="*75)
print("CANDIDATO 4 — Spread/TP ratio: solo operar cuando el spread 'importa poco'")
print("  Concepto: si spread estimado > X% del TP esperado → skip")
print("  Con RR=3, TP=3×SL_dist. Spread fijo ~2.5pts.")
print("  Si SL_dist pequeño → TP pequeño → spread pesa más → peor edge neto")
print("  PARADOJA: los rangos pequeños tienen mejor WR pero el spread pesa más!")
print("="*75)

print(f"\n  Spread estimado: {SPREAD_EST} pts | RR={RR_VAL}")
for max_spread_pct in [10, 8, 6, 5, 4]:
    grp = t10[t10['spread_pct_tp'] <= max_spread_pct]
    # spread_pct_tp = 2.5 / (sl_dist*3) * 100 <= X → sl_dist >= 2.5/(X/100*3)
    min_sl = SPREAD_EST / (max_spread_pct/100 * RR_VAL)
    s = stats_row(grp, f'Spread <= {max_spread_pct}% del TP (SL_dist>={min_sl:.1f}pts)')
    print_row(s, BASE)

print()
print("="*75)
print("CANDIDATO 5 — Ningún filtro de rango, sino filtro de DÍA solamente")
print("  Concepto: el día es el verdadero driver, no el tamaño del rango")
print("  Miércoles tiene WR=35.2% vs Lunes 26.6% — diferencia estructural")
print("  Ventaja: simple, sin parámetro extra, sin overfitting en sl_dist")
print("="*75)

combos_dias = [
    ('Solo Miercoles',           t10[t10['dow_name']=='Wednesday']),
    ('Mie + Vie',                t10[t10['dow_name'].isin(['Wednesday','Friday'])]),
    ('Sin Lunes',                t10[t10['dow_name'].isin(['Wednesday','Friday'])]),
]
for label, grp in combos_dias:
    s = stats_row(grp, label)
    print_row(s, BASE)

print()
print("="*75)
print("CANDIDATO 6 — OR_Pct con banda (no corte duro, sino rango aceptable)")
print("  Concepto: excluir tanto rangos MUY pequeños (spread pesa) como MUY grandes")
print("  Zona óptima: OR_Pct entre 0.03% y 0.12%")
print("  No es un filtro direccional — es control de calidad bidireccional")
print("="*75)

for lo, hi in [(0.02, 0.10), (0.02, 0.12), (0.03, 0.10), (0.03, 0.12), (0.03, 0.15)]:
    grp = t10[(t10['or_pct']>=lo) & (t10['or_pct']<=hi)]
    s = stats_row(grp, f'OR_Pct entre {lo:.2f}% y {hi:.2f}%')
    print_row(s, BASE)

print()
print("="*75)
print("RESUMEN COMPARATIVO — frecuencia vs PF")
print("="*75)
print(f"\n  {'Filtro':45s} {'n':>5} {'%trades':>8} {'PF':>7} {'WR':>7}")
print("  " + "-"*70)

candidatos = [
    ('Sin filtro (baseline)',         t10),
    ('Solo Miercoles',                t10[t10['dow_name']=='Wednesday']),
    ('Mie + Vie',                     t10[t10['dow_name'].isin(['Wednesday','Friday'])]),
    ('OR_Pct <= 0.10%',              t10[t10['or_pct']<=0.10]),
    ('OR_Pct <= 0.12%',              t10[t10['or_pct']<=0.12]),
    ('OR_Pct 0.03-0.12%',            t10[(t10['or_pct']>=0.03)&(t10['or_pct']<=0.12)]),
    ('Z-score <= 0.0 (rolling 20)',   t10[t10['sl_zscore']<=0.0]),
    ('Z-score <= 0.5 (rolling 20)',   t10[t10['sl_zscore']<=0.5]),
    ('Percentil <= 1.0x mediana',     t10[t10['sl_vs_p50']<=1.0]),
    ('Percentil <= 1.2x mediana',     t10[t10['sl_vs_p50']<=1.2]),
    ('Mie + OR_Pct <= 0.12%',        t10[(t10['dow_name']=='Wednesday')&(t10['or_pct']<=0.12)]),
]
for label, grp in candidatos:
    if len(grp) < 20: continue
    p = pf(grp)
    wr = grp['win'].mean()*100
    n = len(grp)
    pct = n/BASE*100
    flag = 'OK' if p>=1.40 else (' ~' if p>=1.30 else 'XX')
    print(f"  [{flag}] {label:45s} {n:5d} {pct:8.1f}% {p:7.3f} {wr:7.1f}%")

print()
print("="*75)
print("ANÁLISIS DE IMPACTO EN IS/OOS por candidato")
print("="*75)

top_candidatos = [
    ('Sin filtro',        t10),
    ('Solo Mie',          t10[t10['dow_name']=='Wednesday']),
    ('Mie+Vie',           t10[t10['dow_name'].isin(['Wednesday','Friday'])]),
    ('OR_Pct<=0.10%',    t10[t10['or_pct']<=0.10]),
    ('OR_Pct 0.03-0.12', t10[(t10['or_pct']>=0.03)&(t10['or_pct']<=0.12)]),
    ('Z<=0.0',            t10[t10['sl_zscore']<=0.0]),
    ('Percentil<=1.2x',   t10[t10['sl_vs_p50']<=1.2]),
]
IS  = (2022, 2023)
OOS = (2024, 2025)

print(f"\n  {'Filtro':25s} {'IS PF':>7} {'IS n':>6} {'OOS PF':>8} {'OOS n':>7} {'OOS/IS':>8}")
print("  " + "-"*65)
for label, grp in top_candidatos:
    g_is  = grp[grp['year'].between(*IS)]
    g_oos = grp[grp['year'].between(*OOS)]
    if len(g_is)<10 or len(g_oos)<10: continue
    pf_is  = pf(g_is)
    pf_oos = pf(g_oos)
    ratio  = pf_oos/pf_is*100
    flag = 'OK' if pf_oos>=1.40 else (' ~' if pf_oos>=1.30 else 'XX')
    print(f"  [{flag}] {label:25s} {pf_is:7.3f} {len(g_is):6d} {pf_oos:8.3f} {len(g_oos):7d} {ratio:8.1f}%")
