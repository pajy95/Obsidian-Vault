import pandas as pd
import numpy as np

path = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests'

files = {
    'Test1 (14:50 NY, cierre 23:00)': 'NAS100 TBR M5 FistTest.xlsx',
    'Test2 (14:50 NY, cierre 23:00)': 'NAS100 TBR M5 SecondTest.xlsx',
    'Test3 (14:30 NY, cierre 17:00)': 'NAS100 TBR M5 ThirtdTest.xlsx',
}

def extract_trades(filepath):
    df = pd.read_excel(filepath, sheet_name='Sheet1', header=None)
    data = df.iloc[65:].copy()
    data.columns = range(13)
    trades_raw = data[pd.to_numeric(data[1], errors='coerce').notna()].copy()
    trades_raw.columns = ['time','deal','symbol','type','direction','volume','price','order','commission','swap','profit','balance','comment']

    trades_in  = trades_raw[trades_raw['direction'] == 'in'].copy()
    trades_out = trades_raw[trades_raw['direction'] == 'out'].copy()

    for t in [trades_in, trades_out]:
        t['time']    = pd.to_datetime(t['time'],   errors='coerce')
        t['profit']  = pd.to_numeric(t['profit'],  errors='coerce')
        t['volume']  = pd.to_numeric(t['volume'],  errors='coerce')
        t['price']   = pd.to_numeric(t['price'],   errors='coerce')
        t['balance'] = pd.to_numeric(t['balance'], errors='coerce')

    return trades_in.reset_index(drop=True), trades_out.reset_index(drop=True)


def analyze(name, trades_in, trades_out):
    sep = '=' * 65
    print('\n' + sep)
    print('  ' + name)
    print(sep)

    n = min(len(trades_in), len(trades_out))
    m = pd.DataFrame({
        'open_time':   trades_in['time'].values[:n],
        'close_time':  trades_out['time'].values[:n],
        'type':        trades_in['type'].values[:n],
        'volume':      trades_in['volume'].values[:n],
        'open_price':  trades_in['price'].values[:n],
        'close_price': trades_out['price'].values[:n],
        'profit':      trades_out['profit'].values[:n],
        'balance':     trades_out['balance'].values[:n],
        'comment':     trades_out['comment'].astype(str).values[:n],
    })

    m['duration_min'] = (m['close_time'] - m['open_time']).dt.total_seconds() / 60

    m['exit_type'] = 'unknown'
    m.loc[m['comment'].str.contains('tp', case=False, na=False), 'exit_type'] = 'TP'
    m.loc[m['comment'].str.contains('sl', case=False, na=False), 'exit_type'] = 'SL'
    m.loc[m['comment'].str.contains('session|SessionEnd', case=False, na=False), 'exit_type'] = 'SessionEnd'

    total    = len(m)
    winners  = m[m['profit'] > 0]
    losers   = m[m['profit'] < 0]
    win_rate = len(winners) / total * 100

    gp = winners['profit'].sum()
    gl = abs(losers['profit'].sum())
    np_ = m['profit'].sum()
    pf  = gp / gl if gl > 0 else 9999

    avg_win  = winners['profit'].mean() if len(winners) > 0 else 0
    avg_loss = losers['profit'].mean()  if len(losers)  > 0 else 0
    rr_real  = abs(avg_win / avg_loss)  if avg_loss != 0 else 0

    tp_dur  = m[m['exit_type'] == 'TP']['duration_min']
    sl_dur  = m[m['exit_type'] == 'SL']['duration_min']
    all_dur = m['duration_min']

    cumbal      = m['balance']
    peak        = cumbal.cummax()
    max_dd_usd  = (cumbal - peak).min()
    max_dd_pct  = abs(max_dd_usd) / 5000 * 100

    print('  Periodo      : %s -> %s' % (m['open_time'].min().date(), m['open_time'].max().date()))
    print('  Trades       : %d' % total)
    print('  Win Rate     : %.1f%%  (TP=%d / SL=%d)' % (win_rate, len(winners), len(losers)))
    print('  Profit Neto  : $%.2f' % np_)
    print('  Gross Win    : $%.2f' % gp)
    print('  Gross Loss   : $%.2f' % gl)
    print('  Profit Factor: %.4f  <- UMBRAL MINIMO: 1.40' % pf)
    print('  Avg Win      : $%.2f' % avg_win)
    print('  Avg Loss     : $%.2f' % avg_loss)
    print('  RR Real      : %.2fx  (configurado: 2.0x)' % rr_real)
    print('  Max DD $     : $%.2f' % max_dd_usd)
    print('  Max DD %%     : %.2f%%  <- UMBRAL MAXIMO: 10%%' % max_dd_pct)

    print('')
    print('  DURACION DE POSICION (minutos):')
    print('    Todos   : med=%.0f  mean=%.0f  max=%.0f  p90=%.0f' % (
        all_dur.median(), all_dur.mean(), all_dur.max(), all_dur.quantile(0.9)))
    if len(tp_dur) > 0:
        print('    TP exits: med=%.0f  mean=%.0f  max=%.0f  p90=%.0f' % (
            tp_dur.median(), tp_dur.mean(), tp_dur.max(), tp_dur.quantile(0.9)))
    if len(sl_dur) > 0:
        print('    SL exits: med=%.0f  mean=%.0f  max=%.0f  p90=%.0f' % (
            sl_dur.median(), sl_dur.mean(), sl_dur.max(), sl_dur.quantile(0.9)))

    print('')
    print('  SALIDAS POR TIPO:')
    for etype, cnt in m['exit_type'].value_counts().items():
        pct = cnt / total * 100
        avg_p = m[m['exit_type'] == etype]['profit'].mean()
        print('    %-12s: %d  (%.0f%%)  avg_profit=$%.2f' % (etype, cnt, pct, avg_p))

    print('')
    print('  POR ANO:')
    m['year'] = m['open_time'].dt.year
    for yr, g in m.groupby('year'):
        g_w = g[g['profit'] > 0]
        g_l = g[g['profit'] < 0]
        gp_yr = g_w['profit'].sum()
        gl_yr = abs(g_l['profit'].sum())
        pf_yr = gp_yr / gl_yr if gl_yr > 0 else 9999
        print('    %d: trades=%d  net=$%+.0f  PF=%.2f  WR=%.0f%%' % (
            yr, len(g), g['profit'].sum(), pf_yr, len(g_w)/len(g)*100))

    # Trades con retencion overnight (>4h = ya problematico para prop firm intraday)
    print('')
    print('  ANALISIS DE RETENCION (problema reportado):')
    cutoffs = [(60, '> 1h'), (240, '> 4h'), (480, '> 8h'), (1020, '> 17h'), (1440, '> 24h')]
    for mins, label in cutoffs:
        subset = m[m['duration_min'] > mins]
        if len(subset) > 0:
            print('    %s : %d trades (%.1f%%)  avg_profit=$%.2f  tipos=%s' % (
                label, len(subset), len(subset)/total*100,
                subset['profit'].mean(),
                subset['exit_type'].value_counts().to_dict()))

    # Riesgo por trade vs balance (problema de riesgo)
    print('')
    print('  ANALISIS DE RIESGO:')
    print('    RiskPct configurado: 0.5%% del balance')
    print('    Balance inicial: $5,000')
    print('    Riesgo esperado por trade: ~$25')
    print('    Avg Loss real          : $%.2f' % abs(avg_loss))
    print('    Max loss en un trade   : $%.2f' % abs(m['profit'].min()))
    print('    Loss > $50 (2x riesgo) : %d trades (%.1f%%)' % (
        len(m[m['profit'] < -50]), len(m[m['profit'] < -50])/total*100))
    print('    Loss > $100 (4x riesgo): %d trades (%.1f%%)' % (
        len(m[m['profit'] < -100]), len(m[m['profit'] < -100])/total*100))

    return m


for name, fname in files.items():
    t_in, t_out = extract_trades(path + '\\' + fname)
    analyze(name, t_in, t_out)
