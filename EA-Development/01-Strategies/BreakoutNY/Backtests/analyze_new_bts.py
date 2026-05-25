import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

files = {
    'NAS100': r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Backtests\nas 100 bk ny .2026.xlsx',
    'DJI30':  r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Backtests\dji30 bk ny.xlsx',
    'XAUUSD': r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Backtests\XAU BK NY 2026.xlsx',
}

def extract_trades(path):
    df_raw = pd.read_excel(path, sheet_name=0, header=None)

    # Inputs
    inputs = {}
    for i, row in df_raw.iterrows():
        v3 = str(row[3]) if pd.notna(row[3]) else ''
        if '=' in v3 and not v3.startswith('<'):
            k, v = v3.split('=', 1)
            inputs[k.strip()] = v.strip()
        if str(row[0]) == 'Results':
            break

    # Summary stats from Results section
    summary = {}
    in_results = False
    for i, row in df_raw.iterrows():
        if str(row[0]) == 'Results':
            in_results = True
        if in_results:
            for col in [0, 3, 6]:
                label = str(row[col]) if pd.notna(row[col]) else ''
                val   = str(row[col+1]) if col+1 < len(row) and pd.notna(row[col+1]) else ''
                if label and val and label != 'nan':
                    summary[label.strip(':')] = val
        if in_results and str(row[0]) == 'Total Trades:':
            break

    # Deals table — entradas "in" con BreakoutNY y profit del deal "out" siguiente
    deals_row = None
    for i, row in df_raw.iterrows():
        if str(row[0]) == 'Deals':
            deals_row = i
            break

    df = pd.read_excel(path, sheet_name=0, header=deals_row+1)
    df.columns = ['Time','Deal','Symbol','Type','Direction','Volume','Price','Order','Commission','Swap','Profit','Balance','Comment']
    df = df[df['Symbol'].astype(str).str.len() > 1].copy()  # eliminar fila de totales
    df['Time']    = pd.to_datetime(df['Time'], errors='coerce')
    df['Profit']  = pd.to_numeric(df['Profit'], errors='coerce').fillna(0)
    df['Balance'] = pd.to_numeric(df['Balance'], errors='coerce')
    df['Direction'] = df['Direction'].astype(str).str.strip()
    df['Comment']   = df['Comment'].astype(str)

    # Construir trades: cada "in" con BreakoutNY + su "out" inmediatamente siguiente
    trades = []
    i = 0
    rows = df.reset_index(drop=True)
    while i < len(rows):
        row = rows.iloc[i]
        if row['Direction'] == 'in' and 'BreakoutNY' in row['Comment']:
            # Buscar el próximo "out" para el mismo symbol
            j = i + 1
            while j < len(rows):
                nxt = rows.iloc[j]
                if nxt['Direction'] == 'out' and nxt['Symbol'] == row['Symbol']:
                    direction = 'buy' if 'BUY' in row['Comment'] else 'sell'
                    trades.append({
                        'open_time':  row['Time'],
                        'close_time': nxt['Time'],
                        'symbol':     row['Symbol'],
                        'direction':  direction,
                        'profit':     nxt['Profit'],
                        'comment_close': nxt['Comment'],
                    })
                    break
                j += 1
        i += 1

    trades_df = pd.DataFrame(trades)
    if len(trades_df) == 0:
        return trades_df, inputs, summary

    trades_df['month'] = trades_df['open_time'].dt.to_period('M')
    trades_df['result'] = trades_df['profit'].apply(lambda x: 'WIN' if x > 0 else 'LOSS')
    trades_df['comment_close'] = trades_df['comment_close'].astype(str).fillna('')
    trades_df['exit_type'] = trades_df['comment_close'].apply(
        lambda x: 'TP' if 'tp' in x.lower() else ('SL' if 'sl' in x.lower() else 'SESSION')
    )
    return trades_df, inputs, summary


def print_analysis(sym, trades, inputs, summary):
    n = len(trades)
    if n == 0:
        print(f'  {sym}: 0 trades')
        return

    wr   = (trades['profit'] > 0).mean()
    gw   = trades.loc[trades['profit'] > 0, 'profit'].sum()
    gl   = abs(trades.loc[trades['profit'] < 0, 'profit'].sum())
    pf   = gw / gl if gl > 0 else float('inf')
    net  = trades['profit'].sum()
    avg_w = trades.loc[trades['profit'] > 0, 'profit'].mean()
    avg_l = trades.loc[trades['profit'] < 0, 'profit'].mean()
    exp  = wr * avg_w + (1 - wr) * avg_l

    buys  = trades[trades['direction'] == 'buy']
    sells = trades[trades['direction'] == 'sell']
    buy_wr  = (buys['profit'] > 0).mean() if len(buys) > 0 else float('nan')
    sell_wr = (sells['profit'] > 0).mean() if len(sells) > 0 else float('nan')

    # Max DD
    cumul  = trades.sort_values('open_time')['profit'].cumsum()
    max_dd = (cumul - cumul.cummax()).min()

    # Racha perdedora max
    max_ls = cur = 0
    for p in trades.sort_values('open_time')['profit']:
        cur = cur + 1 if p < 0 else 0
        max_ls = max(max_ls, cur)

    # Exit types
    tp_count = (trades['exit_type'] == 'TP').sum()
    sl_count = (trades['exit_type'] == 'SL').sum()
    ss_count = (trades['exit_type'] == 'SESSION').sum()

    print(f'{"=" * 62}')
    print(f'  {sym} | Ene-May 2026 | {n} trades | 99% real ticks')
    print(f'{"=" * 62}')
    print(f'  BUY:  {len(buys):2d} trades | WR={buy_wr:.0%}  | PnL=${buys["profit"].sum():.2f}')
    print(f'  SELL: {len(sells):2d} trades | WR={sell_wr:.0%}  | PnL=${sells["profit"].sum():.2f}')
    print(f'  ---')
    print(f'  WR={wr:.0%} | PF={pf:.2f} | Net=${net:.2f}')
    print(f'  AvgWin=${avg_w:.2f} | AvgLoss=${avg_l:.2f} | Exp=${exp:.2f}/trade')
    print(f'  Max DD=${max_dd:.2f} | Max racha loss={max_ls}')
    print(f'  Exits: TP={tp_count} | SL={sl_count} | Session={ss_count}')
    print()
    print(f'  MENSUAL:')
    for m, g in trades.groupby('month'):
        mn  = len(g)
        mwr = (g['profit'] > 0).mean()
        mpnl = g['profit'].sum()
        print(f'    {m}  n={mn:2d}  WR={mwr:.0%}  PnL=${mpnl:+.2f}')
    print()
    print(f'  INPUTS CLAVE:')
    for k in ['BE_BufferPct','MinSL_Points','MaxSL_Points','SessionCloseHour',
              'FilterMonday','FilterTuesday','FilterWednesday','FilterThursday','FilterFriday',
              'ConfirmOnClose','RiskAmountUSD','EnableBuy','EnableSell','TF_Enable']:
        if k in inputs:
            print(f'    {k} = {inputs[k]}')
    print()


all_trades = {}

for sym, path in files.items():
    trades, inputs, summary = extract_trades(path)
    all_trades[sym] = trades
    print_analysis(sym, trades, inputs, summary)


# Comparativa vs referencia OOS 2025
print('=' * 62)
print('  COMPARATIVA: BT Ene-May 2026 vs OOS 2025 (referencia MC)')
print('=' * 62)
ref = {
    'NAS100': {'wr': 0.488, 'pf': 1.720, 'exp': 5.41},
    'DJI30':  {'wr': 0.286, 'pf': 5.469, 'exp': 2.66},
    'XAUUSD': {'wr': 0.630, 'pf': 6.0,   'exp': 9.46},
}
for sym in ['NAS100','DJI30','XAUUSD']:
    t = all_trades[sym]
    o = ref[sym]
    if len(t) == 0:
        print(f'  {sym}: sin trades')
        continue
    wr  = (t['profit'] > 0).mean()
    gw  = t.loc[t['profit'] > 0, 'profit'].sum()
    gl  = abs(t.loc[t['profit'] < 0, 'profit'].sum())
    pf  = gw / gl if gl > 0 else float('inf')
    avg_w = t.loc[t['profit'] > 0, 'profit'].mean()
    avg_l = t.loc[t['profit'] < 0, 'profit'].mean()
    exp = wr * avg_w + (1 - wr) * avg_l
    print(f'  {sym}')
    print(f'    WR:  OOS={o["wr"]:.0%} -> 2026={wr:.0%}')
    print(f'    PF:  OOS={o["pf"]:.2f} -> 2026={pf:.2f}  {"OK" if pf >= 1.4 else "BAJO MINIMO 1.4"}')
    print(f'    Exp: OOS=${o["exp"]:.2f} -> 2026=${exp:.2f}  {"OK" if exp > 0 else "NEGATIVA"}')
    print()
