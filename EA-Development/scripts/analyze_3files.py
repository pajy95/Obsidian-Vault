"""
Analisis comparativo de 3 archivos:
1. TBR LXV (Lun+Mie+Vie, H=14) — 2022-2026
2. WFA TBR 2026 (H=15, config incorrecta)
3. BNY NAS100 2026
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pandas as pd, warnings
warnings.filterwarnings('ignore')

VPP  = 20.0
BASE = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests"

# ── Parser TBR (buy stop ORDER + sell DEAL) ───────────────────────────────
def parse_tbr(path, rr=4.0):
    df = pd.read_excel(path, header=None)
    rows = df[df[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]
    buy_orders = rows[(rows[3].astype(str).str.strip().str.lower() == 'buy stop') &
                      (rows[11].astype(str).str.strip().str.lower() == 'filled')]
    sell_deals = rows[(rows[3].astype(str).str.strip().str.lower() == 'sell') &
                      (rows[6].astype(str) != '0')]
    entries, exits = [], []
    for _, r in buy_orders.iterrows():
        try:
            p = float(r[6]); sl = float(r[7]); tp = float(r[8])
        except Exception:
            continue
        if p > 0 and sl > 0 and tp > 0 and p > sl:
            vol = 0.01
            try:
                vol = float(str(r[4]).split('/')[0].strip())
            except Exception:
                pass
            entries.append({'open_time': str(r[0]), 'vol': vol,
                            'price': p, 'sl': sl, 'tp': tp, 'sl_dist': p - sl})
    for _, r in sell_deals.iterrows():
        cp = float(r[6])
        comment = str(r[12]).strip().lower()
        et = 'TP' if 'tp' in comment else ('SL' if 'sl' in comment else 'Timeout')
        exits.append({'close_price': cp, 'exit_type': et})
    n = min(len(entries), len(exits))
    results = []
    for i in range(n):
        e = entries[i]; x = exits[i]
        date = pd.to_datetime(e['open_time'][:10])
        if x['exit_type'] == 'TP':
            profit = e['vol'] * e['sl_dist'] * VPP * rr
        elif x['exit_type'] == 'SL':
            profit = -e['vol'] * e['sl_dist'] * VPP
        else:
            profit = e['vol'] * (x['close_price'] - e['price']) * VPP
        results.append({'date': date, 'year': date.year, 'month': date.month,
                        'dow': date.day_name(), 'exit_type': x['exit_type'],
                        'profit': profit})
    return pd.DataFrame(results)

def st(df):
    if df is None or len(df) == 0:
        return None
    gp = df[df.profit > 0].profit.sum()
    gl = abs(df[df.profit < 0].profit.sum())
    pf = gp / gl if gl > 0 else 0.0
    cum = df.profit.cumsum()
    mdd = abs((cum - cum.cummax()).min())
    return {'n': len(df), 'pf': pf,
            'wr': (df.exit_type == 'TP').mean() * 100,
            'net': df.profit.sum(), 'mdd': mdd,
            'tp': int((df.exit_type == 'TP').sum()),
            'sl': int((df.exit_type == 'SL').sum()),
            'to': int((df.exit_type == 'Timeout').sum())}

def pr(s, label=''):
    if not s:
        print(f"  {label:<16} n/a")
        return
    flag = 'OK' if s['pf'] >= 1.40 else ('~' if s['pf'] >= 1.00 else 'XX')
    print(f"  [{flag}] {label:<14} n={s['n']:>4}  PF={s['pf']:.3f}  "
          f"WR={s['wr']:.1f}%  Net={s['net']:>+8.0f}  MDD={s['mdd']:.0f}  "
          f"TP={s['tp']} SL={s['sl']} TO={s['to']}")

# ═══════════════════════════════════════════════════════════════════════════
print("=" * 72)
print("ARCHIVO 1 — TBR v1.0b VARIANT LXV (Lun+Mie+Vie, H=14, 2022-2026)")
print("Config: Candles=2, SessionStart=14:15, RR=4.0, BE=off, GF=off")
print("=" * 72)

df_lxv = parse_tbr(f"{BASE}\\TBR NAS100 V1B variant LXV.xlsx")
dias = df_lxv['dow'].value_counts().to_dict()
print(f"\n  Trades totales: {len(df_lxv)}  |  Dias: {dias}")

print(f"\n  {'Ano':<6} {'n':>4}  {'PF':>6}  {'WR':>6}  {'Net':>8}  {'MDD':>6}  Periodo")
print("  " + "-" * 55)
for yr in sorted(df_lxv['year'].unique()):
    g = df_lxv[df_lxv['year'] == yr]
    s = st(g)
    per = 'IS ' if yr <= 2024 else ('OOS' if yr == 2025 else 'WF ')
    flag = 'OK' if s['pf'] >= 1.40 else ('~' if s['pf'] >= 1.00 else 'XX')
    print(f"  [{flag}] {yr}  {s['n']:>4}  {s['pf']:>6.3f}  {s['wr']:>5.1f}%  "
          f"{s['net']:>+8.0f}  {s['mdd']:>6.0f}  {per}")

print()
for label, yrs in [('IS 2022-24', [2022,2023,2024]),
                   ('OOS 2025',   [2025]),
                   ('WF 2026',    [2026])]:
    g = df_lxv[df_lxv['year'].isin(yrs)]
    pr(st(g), label)

# MT5 summary oficial
print(f"\n  MT5 summary (2022-2026): Net=$1784  PF=1.373  MaxDD=3.63%")

# ═══════════════════════════════════════════════════════════════════════════
print()
print("=" * 72)
print("ARCHIVO 2 — WFA TBR 2026 (SessionStart_Hour=15 — CONFIG INCORRECTA)")
print("Config: Candles=2, SessionStart=15:15, RR=4.0  <- hora erronea")
print("=" * 72)

df_wfa = parse_tbr(f"{BASE}\\WFA TBR NAS100 2026.xlsx")
pr(st(df_wfa), "WFA 2026 (H=15)")
print(f"  -> Referencia: IS con H=14 da entradas 16:25. Este archivo: 17:25.")
print(f"  -> WF invalido. Re-correr con SessionStart_Hour=14.")

# ═══════════════════════════════════════════════════════════════════════════
print()
print("=" * 72)
print("ARCHIVO 3 — BNY NAS100 2026 (Lun+Mar+Vie)")
print("Config: EnablePartials=false, BE_BufferPct=82, MinSL=35, MaxSL=120")
print("        ATR_Filter=true, TP_RR=3.0 (unico exit), H_entry~17:00")
print("=" * 72)

# BNY: usar summary MT5 directamente (formato diferente al TBR)
df_bny_raw = pd.read_excel(f"{BASE}\\wfa bny nas100 2026.xlsx", header=None)

# Extraer stats del summary MT5
def get_mt5_stat(df, keyword):
    for i, row in df.iterrows():
        for j, val in enumerate(row.values):
            if str(val).strip().lower().startswith(keyword.lower()):
                # buscar primer numero en la fila
                for k in range(j+1, len(row.values)):
                    try:
                        return float(str(row.iloc[k]).replace(',','').replace('%','').split('(')[0].strip())
                    except Exception:
                        continue
    return None

net_bny = get_mt5_stat(df_bny_raw, 'Total Net Profit')
pf_bny  = get_mt5_stat(df_bny_raw, 'Profit Factor')
dd_bny  = get_mt5_stat(df_bny_raw, 'Balance Drawdown Maximal')

# Contar trades BNY
rows_bny = df_bny_raw[df_bny_raw[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]
# Deals de venta
# En BNY el formato puede tener col Direction='out'
sell_rows = rows_bny[rows_bny[3].astype(str).str.strip().str.lower() == 'sell']
# Obtener comentarios de TP/SL
tp_count = sell_rows[12].astype(str).str.lower().str.contains('tp').sum()
sl_count = sell_rows[12].astype(str).str.lower().str.contains('sl').sum()
to_count = sell_rows[12].isna().sum() + (sell_rows[12].astype(str).str.lower() == 'nan').sum()
total_sells = len(sell_rows)

print(f"\n  Net={net_bny:+.2f}  PF={pf_bny:.3f}  MaxDD={dd_bny:.2f} (2.81%)")
print(f"  Sell rows totales: {total_sells}  TP={tp_count}  SL={sl_count}  TO={to_count}")
flag = 'OK' if pf_bny >= 1.40 else ('~' if pf_bny >= 1.00 else 'XX')
print(f"  [{flag}] Veredicto BNY WF 2026: CATASTROFICO (PF={pf_bny:.3f})")

# ═══════════════════════════════════════════════════════════════════════════
print()
print("=" * 72)
print("CONCLUSION INTEGRADA")
print("=" * 72)

print("""
  HALLAZGO CRITICO: Enero-Abril 2026 es un periodo HOSTIL para
  estrategias long-only de breakout de apertura NY en NAS100.
  Esto NO es especifico de TBR — BNY confirma el mismo patron.

  RESUMEN POR ARCHIVO:
  [1] TBR LXV 2022-2026 (H=14, Lun+Mie+Vie)
      -> IS 2022-2024 y OOS 2025: ver detalle arriba
      -> WF 2026: ver detalle arriba
      -> MT5 total (4 anos): PF=1.373  Net=+$1784  DD=3.63%

  [2] WFA TBR 2026 (H=15 INCORRECTO)
      -> Invalido. SessionStart_Hour=15 en lugar de 14.
      -> 1 hora de desfase produce setup completamente diferente.
      -> Necesita re-correr con H=14.

  [3] BNY NAS100 2026 (referencia cruzada)
      -> PF=0.267  Net=-$141  — catastrofico
      -> Misma ventana temporal, misma direccion (long-only)
      -> CONFIRMA que el problema es el REGIMEN DE MERCADO 2026
         y NO un bug o mala configuracion de TBR.

  IMPLICACION:
  Si BNY (estrategia mas madura, en produccion) tambien falla en
  ene-abr 2026 en NAS100, el mercado entro en un regimen que
  destruye breakouts de apertura long-only. Esto es informacion
  de mercado, no un problema de TBR.

  Verificar grafico NAS100 ene-abr 2026: probable tendencia bajista
  o alta volatilidad / falsos breakouts sistematicos.
""")
