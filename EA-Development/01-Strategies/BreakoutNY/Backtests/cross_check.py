import pandas as pd
import warnings
warnings.filterwarnings('ignore')

# --- Cuenta real (forward test) ---
path_real = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Trade-Journal\Report Abril_MAYO.xlsx'
df_raw = pd.read_excel(path_real, sheet_name='Sheet1', header=None)
cols = ['open_time','position','symbol','type','volume','open_price','sl','tp',
        'close_time','close_price','commission','swap','profit','x']
data_rows = []
for i in range(7, len(df_raw)):
    row = df_raw.iloc[i]
    if 'rdenes' in str(row[0]) or 'Saldo' in str(row[0]):
        break
    data_rows.append(row.values)
real = pd.DataFrame(data_rows, columns=cols).drop(columns=['x'])
real = real[real['open_time'].notna()].copy()
real['open_time'] = pd.to_datetime(real['open_time'])
real['profit']    = pd.to_numeric(real['profit'])
real['net']       = real['profit'] + pd.to_numeric(real['commission']) + pd.to_numeric(real['swap'])

# --- Backtest NAS100 ---
def load_bt_trades(path):
    df_raw = pd.read_excel(path, sheet_name=0, header=None)
    deals_row = next(i for i, row in df_raw.iterrows() if str(row[0]) == 'Deals')
    df = pd.read_excel(path, sheet_name=0, header=deals_row+1)
    df.columns = ['Time','Deal','Symbol','Type','Direction','Volume','Price','Order',
                  'Commission','Swap','Profit','Balance','Comment']
    df = df[df['Symbol'].astype(str).str.len() > 1].copy()
    df['Time']    = pd.to_datetime(df['Time'], errors='coerce')
    df['Profit']  = pd.to_numeric(df['Profit'], errors='coerce').fillna(0)
    df['Comment'] = df['Comment'].astype(str)
    rows = df.reset_index(drop=True)
    trades = []
    for i, row in rows.iterrows():
        if row['Direction'] == 'in' and 'BreakoutNY' in row['Comment']:
            for j in range(i+1, len(rows)):
                nxt = rows.iloc[j]
                if nxt['Direction'] == 'out' and nxt['Symbol'] == row['Symbol']:
                    trades.append({
                        'open_time': row['Time'],
                        'close_time': nxt['Time'],
                        'symbol': row['Symbol'],
                        'type': 'buy' if 'BUY' in row['Comment'] else 'sell',
                        'profit': nxt['Profit'],
                        'exit': nxt['Comment'],
                    })
                    break
    return pd.DataFrame(trades)

bt_nas = load_bt_trades(
    r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Backtests\NAS100\WF_NAS100_MonTueFri_v1_2026-01-01_2026-05-08.xlsx'
)
bt_dji = load_bt_trades(
    r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Backtests\DJI30\WF_DJI30_TueThuFri_v1_2026-01-01_2026-05-08.xlsx'
)
bt_nas['open_time'] = pd.to_datetime(bt_nas['open_time'])
bt_dji['open_time'] = pd.to_datetime(bt_dji['open_time'])

# Filtrar periodo abr-may en backtests
bt_nas_am = bt_nas[bt_nas['open_time'] >= '2026-04-01'].copy()
bt_dji_am = bt_dji[bt_dji['open_time'] >= '2026-04-01'].copy()

# --- COMPARACION TRADE A TRADE ---
print('=' * 70)
print('  CRUCE: CUENTA REAL vs BACKTEST | Abr-May 2026')
print('=' * 70)

for sym, bt_sub in [('NDX100', bt_nas_am), ('DJI30', bt_dji_am)]:
    real_sub = real[real['symbol'] == sym].copy()
    print(f'\n[{sym}]  Real={len(real_sub)} trades  |  Backtest={len(bt_sub)} trades')
    print(f'  {"Fecha":12s}  {"Dir":5s}  {"REAL PnL":>10s}  {"BT PnL":>10s}  {"Diff":>8s}  Nota')
    print(f'  {"-"*65}')

    # Trades del real que tienen match en BT (misma fecha)
    matched_real = set()
    matched_bt   = set()
    rows_out = []

    for ri, r in real_sub.iterrows():
        rdate = r['open_time'].date()
        match = bt_sub[bt_sub['open_time'].dt.date == rdate]
        if len(match) > 0:
            m = match.iloc[0]
            diff = r['profit'] - m['profit']
            dir_match = '=' if r['type'] == m['type'] else '!DIR'
            rows_out.append((str(rdate), r['type'], r['profit'], m['profit'], diff, dir_match))
            matched_bt.add(match.index[0])
        else:
            rows_out.append((str(rdate), r['type'], r['profit'], None, None, 'SIN MATCH BT'))
        matched_real.add(ri)

    # Trades del BT sin match en real
    for bi, b in bt_sub.iterrows():
        if bi not in matched_bt:
            rows_out.append((str(b['open_time'].date()), b['type'], None, b['profit'], None, 'SOLO EN BT'))

    rows_out.sort(key=lambda x: x[0])
    for row in rows_out:
        date, direction, rp, bp, diff, nota = row
        rp_s  = f'${rp:+.2f}' if rp is not None else '       ---'
        bp_s  = f'${bp:+.2f}' if bp is not None else '       ---'
        diff_s = f'${diff:+.2f}' if diff is not None else '    ---'
        print(f'  {date:12s}  {direction:5s}  {rp_s:>10s}  {bp_s:>10s}  {diff_s:>8s}  {nota}')

    # Resumen
    real_pnl = real_sub['profit'].sum()
    bt_pnl   = bt_sub['profit'].sum()
    print(f'\n  TOTAL REAL=${real_pnl:.2f}  |  TOTAL BT=${bt_pnl:.2f}  |  Diff=${real_pnl-bt_pnl:.2f}')

# XAUUSD
print('\n[XAUUSD]')
real_xau = real[real['symbol'] == 'XAUUSD']
print(f'  Real: {len(real_xau)} trades  |  BT: 0 trades (TF_Enable filtro)')
for _, r in real_xau.iterrows():
    print(f'  {str(r["open_time"].date()):12s}  {r["type"]:5s}  REAL=${r["profit"]:+.2f}  BT=---  (filtrado por TF)')

# SPX500
print('\n[SPX500]')
real_spx = real[real['symbol'] == 'SPX500']
print(f'  Real: {len(real_spx)} trades  |  BT: no hay backtest SPX500 Ene-May 2026')
for _, r in real_spx.iterrows():
    print(f'  {str(r["open_time"].date()):12s}  {r["type"]:5s}  REAL=${r["profit"]:+.2f}  BT=---')

print('\n' + '=' * 70)
print('  RESUMEN GLOBAL')
print('=' * 70)
print(f'  Cuenta real total (todos activos): ${real["profit"].sum():.2f} en {len(real)} trades')
bt_all_am = pd.concat([bt_nas_am, bt_dji_am])
print(f'  Backtest periodo equivalente:      ${bt_all_am["profit"].sum():.2f} en {len(bt_all_am)} trades')
