import pandas as pd
import numpy as np

path = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Trade-Journal\Report Abril_MAYO.xlsx'
df_raw = pd.read_excel(path, sheet_name='Sheet1', header=None)

cols = ['open_time','position','symbol','type','volume','open_price','sl','tp','close_time','close_price','commission','swap','profit','x']
data_rows = []
for i in range(7, len(df_raw)):
    row = df_raw.iloc[i]
    if 'rdenes' in str(row[0]) or 'Saldo' in str(row[0]) or 'Resultados' in str(row[0]):
        break
    data_rows.append(row.values)

trades = pd.DataFrame(data_rows, columns=cols).drop(columns=['x'])
trades = trades[trades['open_time'].notna()].copy()
trades['open_time'] = pd.to_datetime(trades['open_time'])
trades['close_time'] = pd.to_datetime(trades['close_time'])
trades['profit'] = pd.to_numeric(trades['profit'])
trades['commission'] = pd.to_numeric(trades['commission'])
trades['swap'] = pd.to_numeric(trades['swap'])
trades['net_profit'] = trades['profit'] + trades['commission'] + trades['swap']
trades['result'] = trades['profit'].apply(lambda x: 'WIN' if x > 0 else 'LOSS')
trades['duration_min'] = (trades['close_time'] - trades['open_time']).dt.total_seconds() / 60

print('=' * 60)
print('ANALISIS BREAKOUT NY --- ABRIL/MAYO 2026')
print('=' * 60)

# RESUMEN GLOBAL
total = len(trades)
wins = (trades['profit'] > 0).sum()
losses = (trades['profit'] <= 0).sum()
total_profit = trades['net_profit'].sum()
avg_win = trades.loc[trades['profit'] > 0, 'profit'].mean()
avg_loss = trades.loc[trades['profit'] <= 0, 'profit'].mean()
win_rate = wins / total
gross_wins = trades.loc[trades['profit'] > 0, 'profit'].sum()
gross_losses = abs(trades.loc[trades['profit'] <= 0, 'profit'].sum())
pf = gross_wins / gross_losses if gross_losses > 0 else float('inf')
rr_real = avg_win / abs(avg_loss) if avg_loss != 0 else float('inf')

print()
print('[RESUMEN GLOBAL]')
print(f'Periodo        : {trades["open_time"].min().date()} -> {trades["open_time"].max().date()}')
print(f'Total trades   : {total}')
print(f'Wins / Losses  : {wins} / {losses}')
print(f'Win Rate       : {win_rate:.1%}')
print(f'Net P&L total  : ${total_profit:.2f}')
print(f'Avg Win        : ${avg_win:.2f}')
print(f'Avg Loss       : ${avg_loss:.2f}')
print(f'RR real (W/L)  : {rr_real:.2f}')
print(f'Profit Factor  : {pf:.2f}')
print(f'Avg duracion   : {trades["duration_min"].mean():.0f} min')

# POR INSTRUMENTO
print()
print('[POR INSTRUMENTO]')
for sym, g in trades.groupby('symbol'):
    t = len(g)
    w = (g['profit'] > 0).sum()
    wr = w / t
    gl = abs(g.loc[g['profit'] <= 0, 'profit'].sum())
    gw = g.loc[g['profit'] > 0, 'profit'].sum()
    sym_pf = gw / gl if gl > 0 else float('inf')
    sym_pnl = g['net_profit'].sum()
    print(f'  {sym:8s}  trades={t}  WR={wr:.0%}  PF={sym_pf:.2f}  PnL=${sym_pnl:.2f}')

# POR DIRECCION
print()
print('[DIRECCION]')
for d, g in trades.groupby('type'):
    t = len(g)
    w = (g['profit'] > 0).sum()
    wr = w / t
    pnl = g['net_profit'].sum()
    print(f'  {d:5s}  trades={t}  WR={wr:.0%}  PnL=${pnl:.2f}')

# EQUITY CURVE
print()
print('[EQUITY CURVE]')
trades_sorted = trades.sort_values('open_time').copy()
trades_sorted['cumulative'] = trades_sorted['net_profit'].cumsum()
for _, r in trades_sorted.iterrows():
    print(f'  {str(r["open_time"].date()):12s}  {r["symbol"]:8s}  {r["type"]:5s}  ${r["profit"]:+7.2f}  cumul=${r["cumulative"]:+7.2f}')

# RACHAS
print()
print('[RACHAS]')
results = trades_sorted['result'].tolist()
max_win_streak = max_loss_streak = cur_win = cur_loss = 0
for r in results:
    if r == 'WIN':
        cur_win += 1; cur_loss = 0
    else:
        cur_loss += 1; cur_win = 0
    max_win_streak = max(max_win_streak, cur_win)
    max_loss_streak = max(max_loss_streak, cur_loss)
print(f'  Max racha ganadora : {max_win_streak}')
print(f'  Max racha perdedora: {max_loss_streak}')

# DRAWDOWN
print()
print('[DRAWDOWN]')
cumul = trades_sorted['net_profit'].cumsum()
running_max = cumul.cummax()
dd = cumul - running_max
max_dd = dd.min()
print(f'  Max Drawdown: ${max_dd:.2f}')

# TRADES INDIVIDUALES
print()
print('[DETALLE TRADES]')
print(f'  {"Fecha":12s}  {"Sym":8s}  {"Dir":5s}  {"PnL":>8s}  {"Dur":>6s}  {"Resultado"}')
for _, r in trades_sorted.iterrows():
    print(f'  {str(r["open_time"].date()):12s}  {r["symbol"]:8s}  {r["type"]:5s}  ${r["profit"]:+7.2f}  {r["duration_min"]:5.0f}m  {r["result"]}')
