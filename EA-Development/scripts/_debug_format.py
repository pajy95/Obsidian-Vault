import pandas as pd
import warnings; warnings.filterwarnings('ignore')

for tag, path in [
    ('P2_IS', r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\is_tbr_xauusd_p2_2022-2024.xlsx'),
    ('P1_IS', r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\IS_TBR_XAUUSD_P1_2022-2024.xlsx'),
    ('P2_OOS', r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\OOS_TBR_XAU_P2_2025.xlsx'),
    ('P1_OOS', r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\OOS_TBR_XAUUSD_P1_2025.xlsx'),
    ('P2_WFA', r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\WFA_TBR_XAU_P2_2026.xlsx'),
    ('P1_WFA', r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\WFA_TBR_XAUUSD_P1_2026.xlsx'),
]:
    df = pd.read_excel(path, header=None)
    rows = df[df[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]

    in_rows  = rows[rows[4].astype(str).str.strip().str.lower() == 'in']
    out_rows = rows[rows[4].astype(str).str.strip().str.lower() == 'out']

    tp_n = sl_n = to_n = 0
    net = 0.0
    if len(out_rows) > 0:
        out2 = out_rows.copy()
        out2['pnl'] = pd.to_numeric(out2[10], errors='coerce')
        comments = out2[12].astype(str).str.strip().str.lower()
        tp_n  = comments.str.startswith('tp').sum()
        sl_n  = comments.str.startswith('sl').sum()
        to_n  = (~(comments.str.startswith('tp') | comments.str.startswith('sl'))).sum()
        net   = out2['pnl'].sum()

    print("=== " + tag + " ===")
    print("  Total filas fecha: " + str(len(rows)))
    print("  col[4]=in  (entries DEAL): " + str(len(in_rows)))
    print("  col[4]=out (exits   DEAL): " + str(len(out_rows)))
    print("  TP=" + str(tp_n) + "  SL=" + str(sl_n) + "  TO=" + str(to_n))
    print("  Net P&L (col[10]): $" + str(round(net, 2)))

    # Ultima fila con datos (resumen MT5)
    for i, r in df.tail(5).iterrows():
        vals = [str(v) for v in r if str(v) != 'nan']
        if vals:
            print("  fila " + str(i) + ": " + str(vals))
    print()
