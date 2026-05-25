"""
Análisis forense T8 vs NR — lotaje y SL
Diferencia estructural de formato:
  NR:  col6=entry_price, col7=SL,         col8=TP   (buy stop → precio explícito)
  T8:  col6=0,           col7=SL,         col8=TP   (buy market → precio=0)
       SL_dist(NR) = entry - SL
       SL_dist(T8) = (TP - SL) / (RR+1)  con RR=3.0 → /4
"""
import pandas as pd
import numpy as np
import warnings
import re

warnings.filterwarnings('ignore')

NR_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\NAS100 V1 NR M3.xlsx"
T8_PATH = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 8voTest.xlsx"
VPP     = 20.0    # $20/punto/lote NDX100
RR_T8   = 3.0     # RR configurado en T8


def safe_float(v):
    try:
        f = float(v)
        return f if not np.isnan(f) else None
    except Exception:
        return None


def parse_nr_entries(path):
    """NR: buy stop → col6=price, col7=SL, col8=TP."""
    df_raw = pd.read_excel(path, header=None)
    rows = []
    for _, row in df_raw.iloc[126:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t):
            continue
        typ = str(row[3]).strip().lower()
        if typ not in ['buy', 'buy stop']:
            continue
        vol4 = str(row[4]).strip()
        try:
            vol = float(vol4.split('/')[0].strip())
        except Exception:
            continue
        price = safe_float(row[6])
        sl    = safe_float(row[7])
        tp    = safe_float(row[8])
        if price and sl and tp:
            rows.append({'open_time': t, 'vol': vol, 'price': price, 'sl': sl, 'tp': tp,
                         'sl_dist': price - sl})
    return pd.DataFrame(rows)


def parse_t8_entries(path, rr=3.0):
    """T8: buy market → col6=0, col7=SL, col8=TP. SL_dist=(TP-SL)/(RR+1)."""
    df_raw = pd.read_excel(path, header=None)
    rows = []
    for _, row in df_raw.iloc[97:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t):
            continue
        typ = str(row[3]).strip().lower()
        if typ not in ['buy', 'buy stop']:
            continue
        vol4 = str(row[4]).strip()
        try:
            vol = float(vol4.split('/')[0].strip())
        except Exception:
            continue
        sl = safe_float(row[7])
        tp = safe_float(row[8])
        if sl and tp and tp > sl:
            sl_dist = (tp - sl) / (rr + 1)
            entry   = sl + sl_dist
            rows.append({'open_time': t, 'vol': vol, 'sl': sl, 'tp': tp,
                         'sl_dist': sl_dist, 'entry': entry})
    return pd.DataFrame(rows)


def parse_exits(path, data_start):
    df_raw = pd.read_excel(path, header=None)
    exits = []
    for _, row in df_raw.iloc[data_start:].iterrows():
        t = str(row[0]).strip()
        if not re.match(r'^\d{4}\.\d{2}\.\d{2}', t):
            continue
        typ = str(row[3]).strip().lower()
        if typ != 'sell':
            continue
        comment = str(row[12]).strip().lower() if len(row) > 12 else ''
        if 'tp' in comment:
            et = 'TP'
        elif 'sl' in comment:
            et = 'SL'
        elif comment in ['nan', '']:
            et = 'Timeout'
        else:
            et = 'Other'
        exits.append({'exit_type': et})
    return pd.DataFrame(exits)


# ── Parseo ────────────────────────────────────────────────────────────────
print("=" * 70)
print("ANÁLISIS FORENSE T8 vs NR — LOTAJE Y SL")
print("=" * 70)

nr = parse_nr_entries(NR_PATH)
t8 = parse_t8_entries(T8_PATH, RR_T8)
nr_ex = parse_exits(NR_PATH, 126)
t8_ex = parse_exits(T8_PATH, 97)

print(f"NR entradas: {len(nr)}   T8 entradas: {len(t8)}")

# ── 1. Distribución lotaje ───────────────────────────────────────────────
print()
print("=" * 70)
print("1. DISTRIBUCIÓN DE LOTAJE")
print("=" * 70)

for label, df in [('NR', nr), ('T8', t8)]:
    v = df['vol']
    print(f"\n[{label}]  n={len(v)}  min={v.min():.2f}  median={v.median():.2f}"
          f"  mean={v.mean():.3f}  max={v.max():.2f}")
    vc = v.value_counts().sort_index()
    for lot, cnt in vc.items():
        bar = '#' * int(cnt / len(v) * 50)
        print(f"  {lot:.2f}: {cnt:4d} ({cnt/len(v)*100:5.1f}%)  {bar}")

# ── 2. SL_dist ─────────────────────────────────────────────────────────
print()
print("=" * 70)
print("2. DISTANCIA SL (puntos)")
print("   NR: entry - SL  |  T8: (TP - SL) / 4  [RR=3]")
print("=" * 70)

for label, df in [('NR', nr), ('T8', t8)]:
    s = df['sl_dist']
    print(f"\n[{label}]  min={s.min():.1f}  p25={s.quantile(.25):.1f}"
          f"  median={s.median():.1f}  p75={s.quantile(.75):.1f}  max={s.max():.1f}")

# ── 3. Riesgo real ───────────────────────────────────────────────────────
print()
print("=" * 70)
print("3. RIESGO REAL USD  (lot × SL_dist × $20)")
print("=" * 70)

for label, df in [('NR', nr), ('T8', t8)]:
    r = df['vol'] * df['sl_dist'] * VPP
    print(f"\n[{label}]  min=${r.min():.2f}  p25=${r.quantile(.25):.2f}"
          f"  median=${r.median():.2f}  p75=${r.quantile(.75):.2f}  max=${r.max():.2f}"
          f"  mean=${r.mean():.2f}")

# ── 4. SL implicita ─────────────────────────────────────────────────────
print()
print("=" * 70)
print("4. SL IMPLÍCITA desde lotaje (si riesgo fuera $12.50 fijo)")
print("   SL_impl = 12.50 / lot / 20")
print("=" * 70)

t8['sl_impl'] = 12.5 / t8['vol'] / VPP
print(f"\n[T8] SL real  — median={t8['sl_dist'].median():.1f}  mean={t8['sl_dist'].mean():.1f} pts")
print(f"     SL impli — median={t8['sl_impl'].median():.1f}  mean={t8['sl_impl'].mean():.1f} pts")
ratio = t8['sl_dist'] / t8['sl_impl']
print(f"     Ratio    — median={ratio.median():.2f}x  (SL real / SL implícita)")
print(f"     => Si ratio~1.0: sizing correcto. Si ratio>>1: SL demasiado ancho.")

nr['sl_impl'] = 12.5 / nr['vol'] / VPP
ratio_nr = nr['sl_dist'] / nr['sl_impl']
print(f"\n[NR] SL real  — median={nr['sl_dist'].median():.1f}  mean={nr['sl_dist'].mean():.1f} pts")
print(f"     SL impli — median={nr['sl_impl'].median():.1f}  mean={nr['sl_impl'].mean():.1f} pts")
print(f"     Ratio    — median={ratio_nr.median():.2f}x")

# ── 5. Floor check T8 ───────────────────────────────────────────────────
print()
print("=" * 70)
print("5. VERIFICACIÓN SIZING T8: lot == floor(12.5 / SL_dist / 20, 2dp)?")
print("=" * 70)

t8['floor_lot'] = (12.5 / (t8['sl_dist'] * VPP)).apply(lambda x: np.floor(x * 100) / 100)
t8['match']     = np.isclose(t8['vol'], t8['floor_lot'], atol=0.005)
n_match = t8['match'].sum()
print(f"  Matches exactos: {n_match} / {len(t8)}  ({n_match/len(t8)*100:.1f}%)")
print(f"\n  Distribución floor_lot vs vol observado:")
comp = t8[['sl_dist', 'vol', 'floor_lot', 'match']].copy()
comp['diff'] = comp['vol'] - comp['floor_lot']
vc_diff = comp['diff'].round(2).value_counts().sort_index()
for diff, cnt in vc_diff.items():
    print(f"  diff={diff:+.2f}: {cnt:4d} trades")

# ── 6. Muestra detallada ─────────────────────────────────────────────────
print()
print("=" * 70)
print("6. PRIMEROS 20 TRADES T8 — SIZING DETALLADO")
print("=" * 70)

t8['risk_real'] = t8['vol'] * t8['sl_dist'] * VPP
cols = ['open_time', 'sl', 'tp', 'sl_dist', 'vol', 'floor_lot', 'risk_real']
print(t8[cols].head(20).to_string(index=False, float_format=lambda x: f'{x:.2f}'))

# ── 7. Exit types ────────────────────────────────────────────────────────
print()
print("=" * 70)
print("7. TIPOS DE SALIDA")
print("=" * 70)

for label, df_ex in [('NR', nr_ex), ('T8', t8_ex)]:
    tot = len(df_ex)
    vc = df_ex['exit_type'].value_counts()
    print(f"\n[{label}]  total={tot}")
    for et, cnt in vc.items():
        print(f"  {et:8s}: {cnt:4d}  ({cnt/tot*100:.1f}%)")

# ── 8. Conclusión ────────────────────────────────────────────────────────
print()
print("=" * 70)
print("8. DIAGNÓSTICO SIZING")
print("=" * 70)

nr_sl_med = nr['sl_dist'].median()
t8_sl_med = t8['sl_dist'].median()
nr_lot_med = nr['vol'].median()
t8_lot_med = t8['vol'].median()

print(f"\nNR: SL mediana={nr_sl_med:.1f} pts  |  lot mediana={nr_lot_med:.2f}")
print(f"T8: SL mediana={t8_sl_med:.1f} pts  |  lot mediana={t8_lot_med:.2f}")
print(f"\nEsperado T8 lot (floor(12.5/{t8_sl_med:.1f}/20)): {np.floor(12.5/(t8_sl_med*VPP)*100)/100:.2f}")
print(f"Esperado NR lot (floor(12.5/{nr_sl_med:.1f}/20)):  {np.floor(12.5/(nr_sl_med*VPP)*100)/100:.2f}")

ratio_sl = t8_sl_med / nr_sl_med
print(f"\nRatio SL T8/NR: {ratio_sl:.2f}x  => T8 tiene SL {ratio_sl:.1f}x más ancho que NR")
print(f"Consecuencia: T8 usa {t8_lot_med/nr_lot_med:.2f}x más lotes → mayor riesgo/trade")
