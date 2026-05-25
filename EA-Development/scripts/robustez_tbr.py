"""
Robustez parametrica — TBR v1.1
Estudios obligatorios (CLAUDE.md pipeline Paso 8):
  1. Distribucion de hold times / exit types (SL vs TP vs sesion)
  2. PF por bucket de exit type
  3. Long vs Short separados (IS, OOS, WFA)
  4. Concentracion interna top-3 trades
  5. Desglose año a año

Metodologia: P&L real = profit_out + commission_in (con comision).
"""
import sys, io, pandas as pd, numpy as np, warnings
from datetime import datetime
warnings.filterwarnings('ignore')
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE = r"C:\Users\JOSE YANEZ\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\GBPJPY"
FILES = {
    "IS 2022-2024": f"{BASE}\\IS_TBR_GBPJPY_M5_P121378.xlsx",
    "OOS 2025":     f"{BASE}\\OOS_TBR_GBPJPY_M5_P121378.xlsx",
    "WFA 2026":     f"{BASE}\\WFA_TBR_GBPJPY_M5_P121378_2026.xlsx",
}

# ─────────────────────────────────────────────────────────────
def load_paired_deals(path, label):
    """
    Carga pares (in, out) del deal list MT5.
    Retorna DataFrame con una fila por trade completo.
    """
    raw = pd.read_excel(path, sheet_name='Sheet1', header=None, dtype=str)

    # Buscar header de deals
    header_row = None
    for i, row in raw.iterrows():
        s = ' '.join(str(v).lower() for v in row.values if str(v) not in ('nan',''))
        if 'profit' in s and 'direction' in s and 'symbol' in s:
            header_row = i
            break
    if header_row is None:
        print(f"ERROR: header no encontrado en {label}")
        return None

    cols = [str(v).strip().lower() for v in raw.iloc[header_row].values]
    df   = raw.iloc[header_row + 1:].copy()
    df.columns = cols
    df   = df.reset_index(drop=True)

    dir_s = df['direction'].astype(str).str.strip().str.lower()
    in_df  = df[dir_s == 'in'].copy().reset_index(drop=True)
    out_df = df[dir_s == 'out'].copy().reset_index(drop=True)

    if len(in_df) != len(out_df):
        print(f"AVISO {label}: in={len(in_df)} out={len(out_df)} — desbalanceado")

    n = min(len(in_df), len(out_df))
    in_df  = in_df.iloc[:n].copy()
    out_df = out_df.iloc[:n].copy()

    # Parsear tiempos
    def parse_time(s):
        for fmt in ('%Y.%m.%d %H:%M:%S', '%Y.%m.%d %H:%M'):
            try:
                return datetime.strptime(str(s).strip(), fmt)
            except:
                pass
        return pd.NaT

    trades = pd.DataFrame()
    trades['time_in']    = in_df['time'].apply(parse_time)
    trades['time_out']   = out_df['time'].apply(parse_time)
    trades['direction']  = in_df['type'].astype(str).str.strip().str.lower()  # buy=long, sell=short
    trades['volume']     = pd.to_numeric(in_df['volume'], errors='coerce')
    trades['price_in']   = pd.to_numeric(in_df['price'], errors='coerce')
    trades['price_out']  = pd.to_numeric(out_df['price'], errors='coerce')
    trades['commission'] = pd.to_numeric(in_df['commission'], errors='coerce').fillna(0)
    trades['profit_out'] = pd.to_numeric(out_df['profit'], errors='coerce')
    trades['pnl']        = trades['profit_out'] + trades['commission']
    trades['comment_out'] = out_df['comment'].astype(str).str.strip().str.lower()

    # Hold time en minutos
    trades['hold_min'] = (
        trades['time_out'] - trades['time_in']
    ).dt.total_seconds() / 60.0

    # Tipo de exit: 'sl', 'tp', 'session' (cierre por tiempo)
    def classify_exit(row):
        c = str(row['comment_out'])
        if 'sl' in c:
            return 'SL'
        if 'tp' in c:
            return 'TP'
        # Sin comment o 'nan' → cierre por sesion (SessionEnd)
        if c in ('nan', '', 'none'):
            return 'Session'
        return 'Other'

    trades['exit_type'] = trades.apply(classify_exit, axis=1)

    # Año del trade
    trades['year'] = trades['time_in'].apply(lambda t: t.year if pd.notnull(t) else None)

    trades = trades.dropna(subset=['pnl', 'volume'])
    return trades

# ─────────────────────────────────────────────────────────────
def pf(pnl):
    w = pnl[pnl > 0].sum()
    l = abs(pnl[pnl < 0].sum())
    return round(w/l, 3) if l > 1e-9 else 99.0

def metrics(pnl, label=""):
    wins   = pnl[pnl > 0]
    losses = pnl[pnl < 0]
    n = len(pnl)
    pf_val = pf(pnl)
    wr = len(wins)/n*100 if n > 0 else 0
    net = pnl.sum()
    return pf_val, wr, net, n

def fmt(pf_val, wr, net, n):
    ok = "OK" if pf_val >= 1.0 else "!!"
    return f"[{ok}] PF={pf_val:.3f}  WR={wr:.0f}%  Net=${net:.0f}  n={n}"

# ─────────────────────────────────────────────────────────────
# Cargar todos los periodos
all_data = {}
for label, path in FILES.items():
    print(f"Cargando {label}...")
    df = load_paired_deals(path, label)
    if df is not None:
        all_data[label] = df
        print(f"  {len(df)} trades | "
              f"Long={len(df[df['direction']=='buy'])} "
              f"Short={len(df[df['direction']=='sell'])}")

print()

# ═══════════════════════════════════════════════════════════════
# ESTUDIO 1 — Distribución exit types y hold times
# ═══════════════════════════════════════════════════════════════
print("=" * 62)
print("ESTUDIO 1 — EXIT TYPES y HOLD TIMES")
print("=" * 62)

for label, df in all_data.items():
    print(f"\n  [{label}] n={len(df)} trades")
    for etype in ['SL', 'TP', 'Session', 'Other']:
        sub = df[df['exit_type'] == etype]
        if len(sub) == 0:
            continue
        p, w, net, n = metrics(sub['pnl'], etype)
        pct = n/len(df)*100
        avg_hold = sub['hold_min'].mean()
        print(f"    {etype:<8}: n={n:>3} ({pct:.0f}%)  "
              f"hold={avg_hold:.0f}min  {fmt(p, w, net, n)}")

    print(f"    Hold times  — "
          f"min={df['hold_min'].min():.0f}  "
          f"med={df['hold_min'].median():.0f}  "
          f"max={df['hold_min'].max():.0f}  (minutos)")

# ═══════════════════════════════════════════════════════════════
# ESTUDIO 2 — PF por bucket de hold time
# ═══════════════════════════════════════════════════════════════
print()
print("=" * 62)
print("ESTUDIO 2 — PF POR BUCKET DE DURACION")
print("=" * 62)

OOS = all_data.get("OOS 2025")
if OOS is not None:
    # Definir buckets en minutos (sesion ~120 min max)
    buckets = [(0, 30), (30, 60), (60, 90), (90, 999)]
    print(f"\n  OOS 2025 — n={len(OOS)}")
    for lo, hi in buckets:
        sub = OOS[(OOS['hold_min'] >= lo) & (OOS['hold_min'] < hi)]
        if len(sub) < 3:
            continue
        p, w, net, n = metrics(sub['pnl'])
        top3 = sub.nlargest(3, 'pnl')['pnl'].sum()
        top3_pct = top3 / net * 100 if net > 0 else 0
        label_b = f"{lo}-{hi if hi < 999 else 'max'}min"
        print(f"    {label_b:<14}: {fmt(p, w, net, n)}  top3={top3_pct:.0f}%net")

# ═══════════════════════════════════════════════════════════════
# ESTUDIO 3 — Long vs Short separados
# ═══════════════════════════════════════════════════════════════
print()
print("=" * 62)
print("ESTUDIO 3 — LONG vs SHORT SEPARADOS")
print("=" * 62)
print(f"  Criterio: PF >= 1.0 en OOS para AMBAS direcciones\n")

for label, df in all_data.items():
    longs  = df[df['direction'] == 'buy']
    shorts = df[df['direction'] == 'sell']
    pl, wl, netl, nl = metrics(longs['pnl'])
    ps, ws, nets, ns = metrics(shorts['pnl'])
    print(f"  [{label}]")
    print(f"    LONG  {fmt(pl, wl, netl, nl)}")
    print(f"    SHORT {fmt(ps, ws, nets, ns)}")

# ═══════════════════════════════════════════════════════════════
# ESTUDIO 4 — Concentracion interna (top-3 trades)
# ═══════════════════════════════════════════════════════════════
print()
print("=" * 62)
print("ESTUDIO 4 — CONCENTRACION (top-3 trades < 30% del net)")
print("=" * 62)

for label, df in all_data.items():
    net_total = df['pnl'].sum()
    top3      = df.nlargest(3, 'pnl')['pnl']
    top3_sum  = top3.sum()
    top3_pct  = top3_sum / net_total * 100 if net_total > 0 else 999
    ok_tag    = "OK" if top3_pct < 30 else "ALERTA"
    print(f"\n  [{label}]  Net=${net_total:.0f}  Top-3 sum=${top3_sum:.0f}  "
          f"Top-3/Net={top3_pct:.0f}%  [{ok_tag}]")
    for i, (idx, val) in enumerate(top3.items()):
        row = df.loc[idx]
        print(f"    #{i+1}: ${val:.2f}  {row['time_in'].strftime('%Y-%m-%d')}  "
              f"{row['direction'].upper():<5}  exit={row['exit_type']}")

# ═══════════════════════════════════════════════════════════════
# ESTUDIO 5 — Desglose año a año
# ═══════════════════════════════════════════════════════════════
print()
print("=" * 62)
print("ESTUDIO 5 — DESGLOSE AÑO A AÑO")
print("=" * 62)
print(f"  Criterio: PF > 1.0 en mayoria de años (min 3 de 4)\n")

# Combinar todos los periodos para vista completa
combined = pd.concat(all_data.values(), ignore_index=True)
combined = combined.dropna(subset=['year'])
combined['year'] = combined['year'].astype(int)

years_ok = 0
years_total = 0
for yr in sorted(combined['year'].unique()):
    sub = combined[combined['year'] == yr]
    p, w, net, n = metrics(sub['pnl'])
    ok = p >= 1.0
    if ok:
        years_ok += 1
    years_total += 1
    tag = "OK" if ok else "!!"
    print(f"  {yr}: {fmt(p, w, net, n)}")

print(f"\n  Años positivos: {years_ok}/{years_total}  "
      f"({'CUMPLE' if years_ok >= max(3, years_total-1) else 'NO CUMPLE'})")

# ═══════════════════════════════════════════════════════════════
# RESUMEN
# ═══════════════════════════════════════════════════════════════
print()
print("=" * 62)
print("RESUMEN ROBUSTEZ — GBPJPY P121378")
print("=" * 62)
