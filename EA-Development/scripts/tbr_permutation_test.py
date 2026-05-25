"""
Permutation Test — TBR Pipeline Step 5
H0: wins/losses ocurren al azar (sin edge real)
Metodo: asignar +/- aleatoriamente a valores absolutos de trades (10,000 permutaciones)
Criterios:
  p < 0.05 + z > 1.96  → EDGE SIGNIFICATIVO
  p < 0.01 + z > 2.58  → EDGE SOLIDO
  p >= 0.05             → SIN EVIDENCIA — descartar
Uso: python tbr_permutation_test.py <archivo.xlsx> [<archivo_oos.xlsx>]
"""

import sys
import io
import numpy as np
import pandas as pd
import warnings
warnings.filterwarnings('ignore')

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

N_PERMUTATIONS = 10_000
SEED = 42

# ── Carga y extracción de trades ──────────────────────────────────────────────

def extract_trades(path, label):
    df_raw = pd.read_excel(path, sheet_name=0, header=None)

    # Buscar fila header de la tabla de deals/trades
    header_row = None
    for i in range(len(df_raw)):
        row_str = ' '.join(str(v) for v in df_raw.iloc[i].values).lower()
        if 'profit' in row_str and ('type' in row_str or 'time' in row_str) and ('symbol' in row_str or 'volume' in row_str):
            header_row = i
            break

    if header_row is None:
        raise ValueError(f"No se encontró tabla de trades en {label}")

    df = pd.read_excel(path, sheet_name=0, header=header_row)
    df.columns = [str(c).strip() for c in df.columns]

    profit_col = next((c for c in df.columns if 'profit' in c.lower()), None)
    type_col   = next((c for c in df.columns if 'type' in c.lower()), None)
    dir_col    = next((c for c in df.columns if 'direction' in c.lower() or 'entry' in c.lower()), None)

    if not profit_col:
        raise ValueError(f"No se encontró columna Profit en {label}")

    df[profit_col] = pd.to_numeric(df[profit_col], errors='coerce')

    # Filtrar filas de balance/deposito
    if type_col:
        df = df[~df[type_col].astype(str).str.lower().isin(['balance','deposit','credit','nan',''])]

    # Quedarse solo con cierres (out)
    if dir_col:
        df = df[df[dir_col].astype(str).str.lower().str.contains('out|close', na=False)]

    trades = df[df[profit_col].notna() & (df[profit_col] != 0)][profit_col].values
    trades = trades[~np.isnan(trades)]

    print(f"  [{label}] Trades extraídos: {len(trades)}")
    return trades

# ── Test de permutación ───────────────────────────────────────────────────────

def permutation_test(profits, label, n_perm=N_PERMUTATIONS):
    print(f"\n{'─'*55}")
    print(f"  PERMUTATION TEST — {label}")
    print(f"{'─'*55}")

    n = len(profits)
    obs_net = profits.sum()
    abs_vals = np.abs(profits)

    wins   = profits[profits > 0]
    losses = profits[profits < 0]
    wr     = len(wins) / n * 100
    pf_obs = abs(wins.sum() / losses.sum()) if losses.sum() != 0 else 999

    print(f"  Trades:      {n}")
    print(f"  Net real:    ${obs_net:.2f}")
    print(f"  PF real:     {pf_obs:.3f}")
    print(f"  Win Rate:    {wr:.1f}%")

    # Permutaciones
    rng = np.random.default_rng(SEED)
    perm_nets = np.empty(n_perm)
    for i in range(n_perm):
        signs = rng.choice([-1, 1], size=n)
        perm_nets[i] = (abs_vals * signs).sum()

    # p-value (unilateral: cuántas permutaciones superan el net real)
    p_val = (perm_nets >= obs_net).sum() / n_perm
    # z-score
    mu_perm  = perm_nets.mean()
    std_perm = perm_nets.std()
    z_score  = (obs_net - mu_perm) / std_perm if std_perm > 0 else 0

    print(f"\n  p-value:     {p_val:.4f}")
    print(f"  z-score:     {z_score:.3f}")
    print(f"  Media perm:  ${mu_perm:.2f}")
    print(f"  Std perm:    ${std_perm:.2f}")

    # Veredicto
    if p_val < 0.01 and z_score > 2.58:
        verdict = "EDGE SOLIDO ✅✅"
        detail  = "p<0.01 + z>2.58 — prioridad alta"
    elif p_val < 0.05 and z_score > 1.96:
        verdict = "EDGE SIGNIFICATIVO ✅"
        detail  = "p<0.05 + z>1.96 — continuar pipeline"
    else:
        verdict = "SIN EVIDENCIA ❌"
        detail  = "p>=0.05 — descartar o revisar parametros"

    print(f"\n  VEREDICTO: {verdict}")
    print(f"  {detail}")

    return {"label": label, "n": n, "net": obs_net, "pf": pf_obs, "wr": wr,
            "p_val": p_val, "z_score": z_score, "verdict": verdict}

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Uso: python tbr_permutation_test.py <IS.xlsx> [OOS.xlsx]")
        sys.exit(1)

    results = []

    for i, path in enumerate(sys.argv[1:], 1):
        label = "IS" if i == 1 else "OOS"
        try:
            trades = extract_trades(path, label)
            r = permutation_test(trades, label)
            results.append(r)
        except Exception as e:
            print(f"\nERROR procesando {path}: {e}")

    # Resumen final
    if len(results) == 2:
        print(f"\n{'='*55}")
        print("  RESUMEN FINAL")
        print(f"{'='*55}")
        is_r  = results[0]
        oos_r = results[1]

        degradacion = (is_r['pf'] - oos_r['pf']) / is_r['pf'] * 100
        ambos_pasan = all(
            r['p_val'] < 0.05 and r['z_score'] > 1.96 for r in results
        )

        print(f"  IS  — p={is_r['p_val']:.4f}  z={is_r['z_score']:.3f}  PF={is_r['pf']:.3f}  [{is_r['verdict']}]")
        print(f"  OOS — p={oos_r['p_val']:.4f}  z={oos_r['z_score']:.3f}  PF={oos_r['pf']:.3f}  [{oos_r['verdict']}]")
        print(f"  Degradacion IS->OOS: {degradacion:.1f}%")
        print()
        if ambos_pasan:
            print("  PIPELINE: AVANZA — edge confirmado en IS y OOS")
        else:
            print("  PIPELINE: DETENIDO — edge no confirmado en ambos periodos")

if __name__ == "__main__":
    main()
