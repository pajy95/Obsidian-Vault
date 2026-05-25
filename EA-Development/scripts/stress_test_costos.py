import sys, io, pandas as pd, numpy as np, warnings
warnings.filterwarnings('ignore')
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

OOS_PATH = r"C:\Users\JOSE YANEZ\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\GBPJPY\OOS_TBR_GBPJPY_M5_P121378.xlsx"
WFA_PATH = r"C:\Users\JOSE YANEZ\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\GBPJPY\WFA_TBR_GBPJPY_M5_P121378_2026.xlsx"

# GBPJPY: 1 pip = 0.01, contrato 100,000 GBP
# pip_value = 1,000 JPY / USDJPY
USDJPY_AVG        = 152.0
PIP_VALUE_PER_LOT = 1000.0 / USDJPY_AVG   # ~6.58 USD/pip/lot

# Spread real de tick analysis (09:00-11:00 server, 3.5M ticks)
SPREAD_BASE_PIPS   = 1.20
SPREAD_STRESS_PIPS = 1.60
SPREAD_MAX_PIPS    = 25.00

# Escenarios: pips ADICIONALES encima de lo que MT5 ya aplico en backtesting
# Base es lo que MT5 ya tenia (real ticks); nosotros agregamos stress encima
SCENARIOS = [
    # (nombre,                           extra_spread_pips, extra_slip_pips)
    ("Baseline (MT5 ticks reales)",      0.00,  0.00),
    ("Stress spread Pct95 (+0.40p)",     0.40,  0.00),
    ("Stress + slippage 50% (+0.60p)",   0.40,  0.60),
    ("Full stress Pct95 + slip 1pip",    0.40,  1.00),
    ("Extremo spread Max (+23.80p)",    23.80,  0.00),
]

CRITERION_PF = 1.0

# ─────────────────────────────────────────────────────────────
def load_deals(path, label):
    """
    Carga SOLO las filas 'out' del deal list de un xlsx exportado por MT5.
    Parsea la columna direction ANTES de cualquier conversion numerica.
    Retorna DataFrame con columnas: profit, commission, volume (por trade completo).
    """
    try:
        raw = pd.read_excel(path, sheet_name='Sheet1', header=None, dtype=str)
    except Exception as e:
        print(f"ERROR abriendo {label}: {e}")
        return None

    # Buscar header de deals: contiene 'profit' + 'direction' + 'symbol'
    header_row = None
    for i, row in raw.iterrows():
        row_str = ' '.join(str(v).lower() for v in row.values if str(v) not in ('nan',''))
        if 'profit' in row_str and 'direction' in row_str and 'symbol' in row_str:
            header_row = i
            break

    if header_row is None:
        print(f"ERROR: header no encontrado en {label}")
        return None

    cols = [str(v).strip().lower() for v in raw.iloc[header_row].values]
    df   = raw.iloc[header_row + 1:].copy()
    df.columns = cols
    df   = df.reset_index(drop=True)

    # Filtrar direction ANTES de conversion numerica (evita perder la columna)
    dir_col = df['direction'].astype(str).str.strip().str.lower()
    in_df   = df[dir_col == 'in'].copy()
    out_df  = df[dir_col == 'out'].copy()

    # Convertir columnas clave a float (solo en los subsets correctos)
    out_df['_profit']     = pd.to_numeric(out_df['profit'],     errors='coerce')
    out_df['_volume']     = pd.to_numeric(out_df['volume'],     errors='coerce')
    in_df['_commission']  = pd.to_numeric(in_df['commission'],  errors='coerce').fillna(0)

    # Descartar filas sin profit valido
    out_df = out_df.dropna(subset=['_profit', '_volume'])

    # Alinear comisiones: mismo orden, mismo largo
    in_comm = in_df['_commission'].values
    if len(in_comm) != len(out_df):
        print(f"  AVISO: in={len(in_comm)} / out={len(out_df)} — usando commission=0")
        out_df['_commission'] = 0.0
    else:
        out_df = out_df.copy()
        out_df['_commission'] = in_comm

    # P&L real por trade = profit del exit + commission del entry (ya negativa)
    out_df['_pnl_real'] = out_df['_profit'] + out_df['_commission']

    print(f"\n[{label}] Header fila {header_row}")
    print(f"  In deals:  {len(in_df)}")
    print(f"  Out deals: {len(out_df)}")
    print(f"  Volume promedio: {out_df['_volume'].mean():.4f} lots")
    print(f"  Commission total: ${out_df['_commission'].sum():.2f}")

    return out_df[['_profit', '_commission', '_volume', '_pnl_real']].copy()

# ─────────────────────────────────────────────────────────────
def pf_metrics(pnl_series):
    wins   = pnl_series[pnl_series > 0]
    losses = pnl_series[pnl_series < 0]
    if len(losses) == 0 or abs(losses.sum()) < 1e-9:
        return 99.0, len(pnl_series), len(wins), len(losses), pnl_series.sum()
    pf  = wins.sum() / abs(losses.sum())
    return pf, len(pnl_series), len(wins), len(losses), pnl_series.sum()

# ─────────────────────────────────────────────────────────────
def run_stress(df, label):
    n_trades   = len(df)
    vol_avg    = df['_volume'].mean()
    pip_avg    = vol_avg * PIP_VALUE_PER_LOT

    print(f"\n{'='*62}")
    print(f"  STRESS TEST: {label}")
    print(f"{'='*62}")
    print(f"  pip_value: ${PIP_VALUE_PER_LOT:.2f}/pip/lot (USDJPY={USDJPY_AVG})")
    print(f"  Trades: {n_trades} | Vol medio: {vol_avg:.4f} lots | "
          f"Costo/pip: ~${pip_avg:.2f}")
    print()

    results = []
    for name, extra_sp, extra_sl in SCENARIOS:
        extra_pips = extra_sp + extra_sl
        extra_cost = extra_pips * PIP_VALUE_PER_LOT * df['_volume']

        # Aplicar costo adicional sobre P&L real (ya incluye commission)
        adj = df['_pnl_real'] - extra_cost

        pf, n, nw, nl, net = pf_metrics(adj)
        wr = nw / n * 100 if n > 0 else 0
        ok = pf >= CRITERION_PF
        tag = "PASS" if ok else "FAIL"
        results.append((name, extra_pips, pf, wr, net, ok))

        print(f"  [{tag}]  {name}")
        print(f"         Extra: +{extra_pips:.2f} pips "
              f"(spread +{extra_sp:.2f} + slip +{extra_sl:.2f})")
        print(f"         PF={pf:.3f}  WR={wr:.1f}%  Net=${net:.2f}")
        print()

    print(f"  Criterio: PF >= {CRITERION_PF}")
    key_ok = all(r[5] for r in results if r[1] <= 1.40)
    print(f"  Escenarios relevantes (<=1.40 pips extra): {'TODOS PASS' if key_ok else 'FALLA'}")
    return results

# ─────────────────────────────────────────────────────────────
print("=== STRESS TEST DE COSTOS — GBPJPY P121378 ===\n")
print(f"Spread medido (09:00-11:00 server, 3.5M ticks FundingPips):")
print(f"  Base   Pct50 : {SPREAD_BASE_PIPS:.2f} pips  (ya aplicado por MT5 real ticks)")
print(f"  Stress Pct95 : {SPREAD_STRESS_PIPS:.2f} pips  -> extra +{SPREAD_STRESS_PIPS-SPREAD_BASE_PIPS:.2f} pips")
print(f"  Extremo Max  : {SPREAD_MAX_PIPS:.2f} pips  -> extra +{SPREAD_MAX_PIPS-SPREAD_BASE_PIPS:.2f} pips")

oos = load_deals(OOS_PATH, "OOS 2025")
if oos is not None:
    # Mostrar baseline sin/con commission para referencia cruzada
    pf_no_comm, n, nw, nl, net_no_comm = pf_metrics(oos['_profit'])
    pf_real,    _, _, _,  net_real     = pf_metrics(oos['_pnl_real'])
    print(f"\n  Referencia cruzada pipeline:")
    print(f"    PF sin comision (permutation test): {pf_no_comm:.3f}  Net=${net_no_comm:.2f}")
    print(f"    PF con comision (MT5 report real):  {pf_real:.3f}  Net=${net_real:.2f}")
    run_stress(oos, "OOS 2025 (P121378)")

wfa = load_deals(WFA_PATH, "WFA 2026")
if wfa is not None:
    pf_no_comm, n, nw, nl, net_no_comm = pf_metrics(wfa['_profit'])
    pf_real,    _, _, _,  net_real     = pf_metrics(wfa['_pnl_real'])
    print(f"\n  Referencia cruzada pipeline:")
    print(f"    PF sin comision (permutation test): {pf_no_comm:.3f}  Net=${net_no_comm:.2f}")
    print(f"    PF con comision (MT5 report real):  {pf_real:.3f}  Net=${net_real:.2f}")
    run_stress(wfa, "WFA 2026 (P121378)")
