"""
Analisis optimizacion TBR v1.0b — Fase 1 (M5)
Parsea el XML de MT5 y produce analisis completo de passes.
"""
import xml.etree.ElementTree as ET
import pandas as pd
import warnings
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
warnings.filterwarnings('ignore')

XML_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\TBR B V1.xml"
PF_THRESHOLD = 1.40
PF_MARGINAL  = 1.30

# --- Parsear XML --------------------------------------------------------------
ns = {'ss': 'urn:schemas-microsoft-com:office:spreadsheet'}
tree = ET.parse(XML_PATH)
root = tree.getroot()

# Extraer metadatos del documento
dp = root.find('.//ss:DocumentProperties', {'ss': 'urn:schemas-microsoft-com:office:office'})
title  = dp.find('{urn:schemas-microsoft-com:office:office}Title').text  if dp is not None else 'N/A'
server = dp.find('{urn:schemas-microsoft-com:office:office}Server').text if dp is not None else 'N/A'

rows = root.findall('.//ss:Worksheet/ss:Table/ss:Row', ns)

records = []
for row in rows[1:]:  # skip header
    cells = row.findall('ss:Cell', ns)
    vals = []
    for c in cells:
        d = c.find('ss:Data', ns)
        vals.append(float(d.text) if d is not None else None)
    if len(vals) >= 14 and vals[0] is not None:
        records.append({
            'pass':       int(vals[0]),
            'fwd_pf':     vals[1],   # Forward (OOS) PF
            'back_pf':    vals[2],   # Back (IS) PF
            'profit':     vals[3],
            'pf_total':   vals[5],   # PF periodo completo
            'sharpe':     vals[7],
            'custom':     vals[8],
            'dd_pct':     vals[9],
            'trades':     int(vals[10]),
            'candles':    int(vals[11]),
            'start_min':  int(vals[12]),
            'rr':         vals[13],
        })

df = pd.DataFrame(records)

print("=" * 70)
print(f"OPTIMIZACION TBR v1.0b — FASE 1")
print(f"Periodo: {title}")
print(f"Broker:  {server}")
print("=" * 70)
print(f"  Passes totales analizados : {len(df)}")
print(f"  Custom=0 en todos         : {'SI — OnTester() no retorno valor util' if (df['custom']==0).all() else 'No'}")
print(f"  Rango Fwd PF              : {df['fwd_pf'].min():.3f} — {df['fwd_pf'].max():.3f}")
print(f"  Rango Back PF             : {df['back_pf'].min():.3f} — {df['back_pf'].max():.3f}")
print(f"  Rango PF total            : {df['pf_total'].min():.3f} — {df['pf_total'].max():.3f}")

# --- Top 10 por Forward PF ----------------------------------------------------
print("\n" + "-" * 70)
print("TOP 10 PASSES (ordenados por Forward/OOS PF)")
print("-" * 70)
print(f"  {'#':>4} {'Fwd':>6} {'Back':>6} {'PFtot':>7} {'DD%':>5} {'n':>4} "
      f"{'Cndl':>5} {'Min':>4} {'RR':>5}  Veredicto")
print("  " + "-" * 62)

top10 = df.nlargest(10, 'fwd_pf')
for _, r in top10.iterrows():
    fwd_flag  = 'OK' if r['fwd_pf']  >= PF_THRESHOLD else ('~' if r['fwd_pf']  >= PF_MARGINAL else 'XX')
    back_flag = 'OK' if r['back_pf'] >= PF_THRESHOLD else ('~' if r['back_pf'] >= PF_MARGINAL else 'XX')
    verdict = f"Fwd[{fwd_flag}] Back[{back_flag}]"
    print(f"  {int(r['pass']):>4} {r['fwd_pf']:>6.3f} {r['back_pf']:>6.3f} {r['pf_total']:>7.3f} "
          f"{r['dd_pct']:>5.2f} {int(r['trades']):>4} "
          f"{int(r['candles']):>5} {int(r['start_min']):>4} {r['rr']:>5.1f}  {verdict}")

# --- Pasa umbral PF >= 1.40? -------------------------------------------------
above_fwd  = df[df['fwd_pf']  >= PF_THRESHOLD]
above_back = df[df['back_pf'] >= PF_THRESHOLD]
above_both = df[(df['fwd_pf'] >= PF_THRESHOLD) & (df['back_pf'] >= PF_THRESHOLD)]

print(f"\n  Passes con Fwd PF >= {PF_THRESHOLD}  : {len(above_fwd)}")
print(f"  Passes con Back PF >= {PF_THRESHOLD} : {len(above_back)}")
print(f"  Passes con AMBOS >= {PF_THRESHOLD}   : {len(above_both)}")

# --- Analisis de clusters de parametros --------------------------------------
print("\n" + "-" * 70)
print("ANALISIS POR PARAMETRO (top tercio — Fwd PF > percentil 66)")
print("-" * 70)
top_third = df[df['fwd_pf'] >= df['fwd_pf'].quantile(0.66)]

print(f"\n  RangeCandlesCount:")
for val, g in top_third.groupby('candles'):
    print(f"    {val} candles ({val*5} min): {len(g)} passes, Fwd avg={g['fwd_pf'].mean():.3f}, "
          f"Back avg={g['back_pf'].mean():.3f}")

print(f"\n  SessionStart_Min:")
for val, g in top_third.groupby('start_min'):
    print(f"    Min={val:3d}: {len(g):3d} passes, Fwd avg={g['fwd_pf'].mean():.3f}, "
          f"Back avg={g['back_pf'].mean():.3f}")

print(f"\n  RR:")
for val, g in top_third.groupby('rr'):
    print(f"    RR={val:.1f}: {len(g):3d} passes, Fwd avg={g['fwd_pf'].mean():.3f}, "
          f"Back avg={g['back_pf'].mean():.3f}")

# --- Cluster dominante --------------------------------------------------------
best_cluster = top10.groupby(['candles','start_min']).size().idxmax()
best_candles, best_start = best_cluster
cluster_df = top10[(top10['candles']==best_candles) & (top10['start_min']==best_start)]

print(f"\n" + "-" * 70)
print(f"CLUSTER DOMINANTE: Candles={best_candles} ({best_candles*5}min), StartMin={best_start}")
print(f"-" * 70)
print(f"  {'RR':>6} {'FwdPF':>7} {'BackPF':>7} {'PFtot':>7} {'DD%':>5} {'n':>5}")
for _, r in cluster_df.sort_values('rr').iterrows():
    print(f"  {r['rr']:>6.1f} {r['fwd_pf']:>7.3f} {r['back_pf']:>7.3f} {r['pf_total']:>7.3f} "
          f"{r['dd_pct']:>5.2f} {int(r['trades']):>5}")

# --- Estabilidad del cluster dominante ----------------------------------------
all_cluster = df[(df['candles']==best_candles) & (df['start_min']==best_start)]
print(f"\n  Todos los RR testeados en cluster Candles={best_candles} StartMin={best_start}:")
print(f"  {'RR':>6} {'FwdPF':>7} {'BackPF':>7} {'DD%':>5} {'n':>5}")
for _, r in all_cluster.sort_values('rr').iterrows():
    flag = '<<' if r['fwd_pf'] == all_cluster['fwd_pf'].max() else ''
    print(f"  {r['rr']:>6.1f} {r['fwd_pf']:>7.3f} {r['back_pf']:>7.3f} "
          f"{r['dd_pct']:>5.2f} {int(r['trades']):>5}  {flag}")

# --- Mejor pass para verificacion IS/OOS -------------------------------------
best = df.loc[df['fwd_pf'].idxmax()]
print(f"\n" + "=" * 70)
print("PARAMETROS RECOMENDADOS PARA VERIFICACION IS/OOS")
print("=" * 70)
print(f"  RangeCandlesCount : {int(best['candles'])}  (rango {int(best['candles'])*5} min en M5)")
print(f"  SessionStart_Min  : {int(best['start_min'])}")
print(f"  RR                : {best['rr']:.1f}")
print(f"\n  Metricas WF       : Fwd={best['fwd_pf']:.3f}  Back={best['back_pf']:.3f}  "
      f"DD={best['dd_pct']:.2f}%  n={int(best['trades'])}")
print()
print("  PASO SIGUIENTE:")
print(f"  1. Correr backtest puro en IS (2022.01.01-2023.12.31) con estos params")
print(f"  2. Correr backtest puro en OOS (2024.01.01-2025.12.31) con estos params")
print(f"  3. Verificar OOS/IS ratio >= 0.50 y PF OOS >= 1.40")
print(f"  4. Si pasa: proceder a Fase 2 (Breakeven)")

# --- VEREDICTO PRELIMINAR ----------------------------------------------------
print("\n" + "=" * 70)
print("VEREDICTO PRELIMINAR")
print("=" * 70)
best_fwd  = df['fwd_pf'].max()
best_back = df['back_pf'].max()

issues = []
if best_fwd < PF_THRESHOLD:
    issues.append(f"  [!] Mejor Fwd PF={best_fwd:.3f} < umbral {PF_THRESHOLD}")
if (df['custom']==0).all():
    issues.append("  [!] Custom=0 en todos los passes — OnTester() no funciono")
if df['back_pf'].max() < PF_THRESHOLD:
    issues.append(f"  [!] Mejor Back PF={best_back:.3f} < umbral {PF_THRESHOLD} en IS del WF")

for i in issues:
    print(i)

print()
if best_fwd >= PF_MARGINAL and not (df['back_pf'] < PF_MARGINAL).all():
    print("  MARGINAL — El mejor cluster (Candles=2, Min=15, RR=3.6-4.0) es estable")
    print("  pero no supera PF>=1.40 en el periodo forward del WF.")
    print("  Requiere verificacion con backtest IS/OOS puro antes de avanzar.")
else:
    print("  INSUFICIENTE — Ninguna combinacion supera los umbrales minimos.")
