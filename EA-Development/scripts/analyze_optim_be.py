"""
Analisis optimizacion Fase 2 — Breakeven
Compara UseBreakeven=false vs true a distintos BE_TriggerRR
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import xml.etree.ElementTree as ET
import pandas as pd
import warnings
warnings.filterwarnings('ignore')

XML_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Optimizacion\TBR B V1 be.xml"

ns_ss = 'urn:schemas-microsoft-com:office:spreadsheet'
ns_o  = 'urn:schemas-microsoft-com:office:office'

tree = ET.parse(XML_PATH)
root = tree.getroot()

dp = root.find(f'.//{{{ns_o}}}Title')
title = dp.text if dp is not None else 'N/A'

rows = root.findall(f'.//{{{ns_ss}}}Worksheet/{{{ns_ss}}}Table/{{{ns_ss}}}Row')

# Leer header para mapear columnas dinamicamente
header_row = rows[0]
headers = []
for cell in header_row.findall(f'{{{ns_ss}}}Cell'):
    d = cell.find(f'{{{ns_ss}}}Data')
    headers.append(d.text if d is not None else '')

print(f"Columnas detectadas: {headers}")
print(f"Periodo: {title}\n")

# Parsear todos los passes
records = []
for row in rows[1:]:
    cells = row.findall(f'{{{ns_ss}}}Cell')
    vals = []
    for c in cells:
        d = c.find(f'{{{ns_ss}}}Data')
        vals.append(d.text if d is not None else None)
    if len(vals) < len(headers) or vals[0] is None:
        continue
    rec = {}
    for i, h in enumerate(headers):
        try: rec[h] = float(vals[i])
        except: rec[h] = vals[i]
    records.append(rec)

df = pd.DataFrame(records)

# Normalizar columna UseBreakeven
if 'UseBreakeven' in df.columns:
    df['be'] = df['UseBreakeven'].apply(lambda x: str(x).strip().lower() in ('1','true') if x is not None else False)
else:
    df['be'] = False

# Asegurar tipos numericos
for col in ['Forward Result','Back Result','Profit Factor','Equity DD %','Trades','BE_TriggerRR','RR']:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

print("="*70)
print("FASE 2 — BREAKEVEN OPTIMIZATION")
print("="*70)
print(f"  Total passes: {len(df)}")
print(f"  Con BE:       {df['be'].sum():.0f}")
print(f"  Sin BE:       {(~df['be']).sum():.0f}")

if 'RR' in df.columns:
    print(f"  RR values:    {sorted(df['RR'].dropna().unique())}")
if 'BE_TriggerRR' in df.columns:
    print(f"  BE_TriggerRR: {sorted(df['BE_TriggerRR'].dropna().unique())}")

# ── Separar con y sin BE
no_be = df[~df['be']]
with_be = df[df['be']]

print("\n" + "-"*70)
print("RESUMEN: SIN BE vs CON BE (todos los passes)")
print("-"*70)
for label, sub in [('Sin BE (baseline)', no_be), ('Con BE', with_be)]:
    if len(sub) == 0: continue
    fwd = sub['Forward Result'] if 'Forward Result' in sub.columns else None
    back = sub['Back Result'] if 'Back Result' in sub.columns else None
    pf   = sub['Profit Factor']
    print(f"\n  [{label}]  n_passes={len(sub)}")
    if fwd is not None:
        print(f"    Fwd PF   : min={fwd.min():.3f}  avg={fwd.mean():.3f}  max={fwd.max():.3f}")
    if back is not None:
        print(f"    Back PF  : min={back.min():.3f}  avg={back.mean():.3f}  max={back.max():.3f}")
    print(f"    PF total : min={pf.min():.3f}  avg={pf.mean():.3f}  max={pf.max():.3f}")
    print(f"    DD %     : avg={sub['Equity DD %'].mean():.2f}%  max={sub['Equity DD %'].max():.2f}%")

# ── Tabla por BE_TriggerRR
if 'BE_TriggerRR' in df.columns and 'Forward Result' in df.columns:
    print("\n" + "-"*70)
    print("DETALLE CON BE — por BE_TriggerRR")
    print("-"*70)
    print(f"  {'BE_TRR':>8} {'RR':>5} {'FwdPF':>7} {'BackPF':>7} {'PFtot':>7} {'DD%':>5} {'n':>5}  Pass")
    print("  " + "-"*58)

    # Agrupar por BE_TriggerRR (y RR si hay variacion)
    group_cols = ['BE_TriggerRR']
    if df['RR'].nunique() > 1:
        group_cols.insert(0, 'RR')

    be_sorted = with_be.sort_values(['BE_TriggerRR'] if 'RR' not in group_cols else ['RR','BE_TriggerRR'])
    for _, r in be_sorted.iterrows():
        rr_v = f"{r['RR']:.1f}" if 'RR' in r and not pd.isna(r['RR']) else " n/a"
        be_v = f"{r['BE_TriggerRR']:.2f}" if not pd.isna(r['BE_TriggerRR']) else " n/a"
        fwd  = f"{r['Forward Result']:.3f}" if not pd.isna(r['Forward Result']) else "  n/a"
        back = f"{r['Back Result']:.3f}"    if not pd.isna(r['Back Result'])    else "  n/a"
        pft  = f"{r['Profit Factor']:.3f}"  if not pd.isna(r['Profit Factor'])  else "  n/a"
        dd   = f"{r['Equity DD %']:.2f}"
        n    = f"{int(r['Trades'])}"        if not pd.isna(r['Trades']) else " n/a"
        ps   = f"{int(r['Pass'])}"
        print(f"  {be_v:>8} {rr_v:>5} {fwd:>7} {back:>7} {pft:>7} {dd:>5} {n:>5}  #{ps}")

# ── Baseline sin BE
print("\n" + "-"*70)
print("BASELINE SIN BE")
print("-"*70)
print(f"  {'RR':>5} {'FwdPF':>7} {'BackPF':>7} {'PFtot':>7} {'DD%':>5} {'n':>5}  Pass")
print("  " + "-"*45)
no_be_s = no_be.sort_values('RR') if 'RR' in no_be.columns else no_be
for _, r in no_be_s.iterrows():
    rr_v = f"{r['RR']:.1f}" if 'RR' in r and not pd.isna(r['RR']) else " n/a"
    fwd  = f"{r['Forward Result']:.3f}" if 'Forward Result' in r and not pd.isna(r['Forward Result']) else "  n/a"
    back = f"{r['Back Result']:.3f}"    if 'Back Result' in r and not pd.isna(r['Back Result'])       else "  n/a"
    pft  = f"{r['Profit Factor']:.3f}"
    dd   = f"{r['Equity DD %']:.2f}"
    n    = f"{int(r['Trades'])}"        if not pd.isna(r['Trades']) else " n/a"
    ps   = f"{int(r['Pass'])}"
    print(f"  {rr_v:>5} {fwd:>7} {back:>7} {pft:>7} {dd:>5} {n:>5}  #{ps}")

# ── Veredicto comparativo
print("\n" + "="*70)
print("VEREDICTO: BREAKEVEN AYUDA?")
print("="*70)

if len(no_be) > 0 and len(with_be) > 0 and 'Forward Result' in df.columns:
    best_no_be  = no_be['Forward Result'].max()
    best_with_be = with_be['Forward Result'].max()
    delta = best_with_be - best_no_be
    flag = 'MEJORA' if delta > 0.02 else ('NEUTRAL' if delta > -0.02 else 'PEOR')
    print(f"\n  Mejor Fwd sin BE : {best_no_be:.3f}")
    print(f"  Mejor Fwd con BE : {best_with_be:.3f}")
    print(f"  Delta            : {delta:+.3f}  -> [{flag}]")

    best_be_row = with_be.loc[with_be['Forward Result'].idxmax()]
    best_nobe_row = no_be.loc[no_be['Forward Result'].idxmax()]

    print(f"\n  Mejor pass sin BE: RR={best_nobe_row.get('RR', 'n/a'):.1f}  "
          f"Fwd={best_nobe_row['Forward Result']:.3f}  Back={best_nobe_row['Back Result']:.3f}  "
          f"DD={best_nobe_row['Equity DD %']:.2f}%")

    if not pd.isna(best_be_row.get('BE_TriggerRR', float('nan'))):
        print(f"  Mejor pass con BE: RR={best_be_row.get('RR', 'n/a'):.1f}  "
              f"BE_TRR={best_be_row['BE_TriggerRR']:.2f}  "
              f"Fwd={best_be_row['Forward Result']:.3f}  Back={best_be_row['Back Result']:.3f}  "
              f"DD={best_be_row['Equity DD %']:.2f}%")

    print()
    if flag == 'PEOR':
        print("  CONCLUSION: El breakeven NO mejora el rendimiento.")
        print("  El mecanismo reduce trades ganadores prematuramente (be-stop).")
        print("  RECOMENDACION: Mantener UseBreakeven=false. Avanzar a Fase 3 (GapFilter).")
    elif flag == 'NEUTRAL':
        print("  CONCLUSION: Breakeven no aporta ventaja significativa.")
        print("  RECOMENDACION: Mantener UseBreakeven=false (menos complejidad).")
    else:
        print("  CONCLUSION: Breakeven mejora el rendimiento.")
        be_trr = best_be_row['BE_TriggerRR']
        print(f"  RECOMENDACION: UseBreakeven=true, BE_TriggerRR={be_trr:.2f}.")
