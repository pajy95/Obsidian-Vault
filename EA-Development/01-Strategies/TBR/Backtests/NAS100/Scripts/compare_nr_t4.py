import pandas as pd
import numpy as np

path_nr = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\NAS100 V1 NR M3.xlsx'
path_t4 = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 FourtTest.xlsx'


def load_deals(filepath, start_row):
    df = pd.read_excel(filepath, sheet_name='Sheet1', header=None)
    data = df.iloc[start_row:].copy()
    data.columns = range(13)
    deals = data[pd.to_numeric(data[1], errors='coerce').notna()].copy()
    deals.columns = ['time','deal','symbol','type','direction','volume','price','order',
                     'commission','swap','profit','balance','comment']
    deals['time']    = pd.to_datetime(deals['time'],   errors='coerce')
    deals['profit']  = pd.to_numeric(deals['profit'],  errors='coerce')
    deals['volume']  = pd.to_numeric(deals['volume'],  errors='coerce')
    deals['price']   = pd.to_numeric(deals['price'],   errors='coerce')
    deals['balance'] = pd.to_numeric(deals['balance'], errors='coerce')
    return deals


def build_trades(deals):
    t_in  = deals[deals['direction'] == 'in'].reset_index(drop=True)
    t_out = deals[deals['direction'] == 'out'].reset_index(drop=True)
    n = min(len(t_in), len(t_out))
    m = pd.DataFrame({
        'open_time':   t_in['time'].values[:n],
        'close_time':  t_out['time'].values[:n],
        'type':        t_in['type'].values[:n],
        'volume':      t_in['volume'].values[:n],
        'open_price':  t_in['price'].values[:n],
        'close_price': t_out['price'].values[:n],
        'profit':      t_out['profit'].values[:n],
        'balance':     t_out['balance'].values[:n],
        'comment':     t_out['comment'].astype(str).values[:n],
    })
    m['duration_min'] = (m['close_time'] - m['open_time']).dt.total_seconds() / 60
    m['exit_type'] = 'Timeout'
    m.loc[m['comment'].str.contains('tp', case=False, na=False), 'exit_type'] = 'TP'
    m.loc[m['comment'].str.contains('sl', case=False, na=False), 'exit_type'] = 'SL'
    return m


def stats(m, name, initial=5000, risk_conf=None, rr_config='?'):
    sep = '=' * 68
    print()
    print(sep)
    print('  ' + name)
    print(sep)

    total   = len(m)
    winners = m[m['profit'] > 0]
    losers  = m[m['profit'] < 0]
    timeouts= m[m['exit_type'] == 'Timeout']
    wr      = len(winners) / total * 100
    gp      = winners['profit'].sum()
    gl      = abs(losers['profit'].sum())
    net     = m['profit'].sum()
    pf      = gp / gl if gl > 0 else 9999
    avg_w   = winners['profit'].mean() if len(winners) > 0 else 0
    avg_l   = losers['profit'].mean()  if len(losers)  > 0 else 0
    rr_real = abs(avg_w / avg_l)       if avg_l != 0    else 0
    max_loss_trade = m['profit'].min()
    max_win_trade  = m['profit'].max()

    cumbal     = m['balance']
    peak       = cumbal.cummax()
    max_dd_usd = (cumbal - peak).min()
    max_dd_pct = abs(max_dd_usd) / initial * 100

    all_dur = m['duration_min']
    tp_dur  = m[m['exit_type'] == 'TP']['duration_min']
    sl_dur  = m[m['exit_type'] == 'SL']['duration_min']
    to_dur  = timeouts['duration_min']

    print('PERIODO  : %s  a  %s' % (m['open_time'].min().date(), m['open_time'].max().date()))
    print()
    print('RESULTADOS:')
    print('  Trades          : %d' % total)
    print('  Win Rate        : %.1f%%  (TP=%d / SL=%d / Timeout=%d)' % (
        wr, len(winners), len(losers), len(timeouts)))
    print('  Profit Neto     : $%.2f' % net)
    print('  Gross Win       : $%.2f' % gp)
    print('  Gross Loss      : $%.2f' % gl)
    print('  Profit Factor   : %.4f   <- UMBRAL 1.40' % pf)
    print('  Avg Win         : $%.2f' % avg_w)
    print('  Avg Loss        : $%.2f' % avg_l)
    print('  RR Real         : %.2fx  (configurado: %s)' % (rr_real, rr_config))
    print('  Max Win 1 trade : $%.2f' % max_win_trade)
    print('  Max Loss 1 trade: $%.2f' % max_loss_trade)
    print('  Max DD $        : $%.2f' % max_dd_usd)
    print('  Max DD %%        : %.2f%%  <- UMBRAL 10%%' % max_dd_pct)
    if risk_conf:
        print()
        print('  [RIESGO] Configurado/trade : $%.2f' % risk_conf)
        print('  [RIESGO] Avg Loss real     : $%.2f  (%.1fx conf)' % (
            abs(avg_l), abs(avg_l) / risk_conf))
        print('  [RIESGO] Max Loss real     : $%.2f  (%.1fx conf)' % (
            abs(max_loss_trade), abs(max_loss_trade) / risk_conf))

    print()
    print('DURACION (minutos):')
    print('  Todos   : min=%.0f  med=%.0f  mean=%.0f  max=%.0f  p90=%.0f  p95=%.0f' % (
        all_dur.min(), all_dur.median(), all_dur.mean(), all_dur.max(),
        all_dur.quantile(0.9), all_dur.quantile(0.95)))
    if len(tp_dur) > 0:
        print('  TP exits: min=%.0f  med=%.0f  mean=%.0f  max=%.0f' % (
            tp_dur.min(), tp_dur.median(), tp_dur.mean(), tp_dur.max()))
    if len(sl_dur) > 0:
        print('  SL exits: min=%.0f  med=%.0f  mean=%.0f  max=%.0f' % (
            sl_dur.min(), sl_dur.median(), sl_dur.mean(), sl_dur.max()))
    if len(to_dur) > 0:
        print('  Timeout : min=%.0f  med=%.0f  mean=%.0f  max=%.0f  avg_profit=$%.2f' % (
            to_dur.min(), to_dur.median(), to_dur.mean(), to_dur.max(),
            timeouts['profit'].mean()))

    print()
    print('DISTRIBUCION DURACION:')
    buckets = [(0,5,'0-5min'), (5,15,'5-15min'), (15,30,'15-30min'),
               (30,60,'30-60min'), (60,120,'1-2h'), (120,240,'2-4h'), (240,9999,'>=4h')]
    for lo, hi, label in buckets:
        sub = m[(m['duration_min'] >= lo) & (m['duration_min'] < hi)]
        if len(sub) > 0:
            ptp = len(sub[sub['exit_type'] == 'TP']) / len(sub) * 100
            psl = len(sub[sub['exit_type'] == 'SL']) / len(sub) * 100
            pto = len(sub[sub['exit_type'] == 'Timeout']) / len(sub) * 100
            print('  %-10s: %3d (%3.0f%%)  avg=$%+7.1f  TP=%3.0f%% SL=%3.0f%% TO=%3.0f%%' % (
                label, len(sub), len(sub)/total*100, sub['profit'].mean(), ptp, psl, pto))

    print()
    print('SALIDAS:')
    for et, cnt in m['exit_type'].value_counts().items():
        ap = m[m['exit_type'] == et]['profit'].mean()
        dm = m[m['exit_type'] == et]['duration_min'].median()
        print('  %-10s: %3d (%3.0f%%)  avg=$%+8.2f  dur_med=%4.0fmin' % (
            et, cnt, cnt/total*100, ap, dm))

    print()
    print('POR ANO:')
    m2 = m.copy()
    m2['year'] = m2['open_time'].dt.year
    for yr, g in m2.groupby('year'):
        gw  = g[g['profit'] > 0]
        gl_ = g[g['profit'] < 0]
        pf_yr = gw['profit'].sum() / abs(gl_['profit'].sum()) if len(gl_) > 0 else 9999
        print('  %d: n=%3d  net=$%+7.0f  PF=%.2f  WR=%2.0f%%  avg_dur=%3.0fmin  max_loss=$%6.0f' % (
            yr, len(g), g['profit'].sum(), pf_yr, len(gw)/len(g)*100,
            g['duration_min'].mean(), abs(g['profit'].min())))

    print()
    print('VOLUMEN (lotaje):')
    print('  min=%.2f  med=%.2f  mean=%.2f  max=%.2f' % (
        m['volume'].min(), m['volume'].median(), m['volume'].mean(), m['volume'].max()))
    big_loss = m[(m['volume'] > 0.10) & (m['profit'] < 0)]
    print('  Perdidas con lote > 0.10: %d  avg=$%.2f  max=$%.2f' % (
        len(big_loss),
        big_loss['profit'].mean() if len(big_loss) > 0 else 0,
        big_loss['profit'].min()  if len(big_loss) > 0 else 0))

    return m


nr = build_trades(load_deals(path_nr, 1113))
t4 = build_trades(load_deals(path_t4, 1285))

stats(nr, 'NR M3  |  New Rate Ultra  |  RiskPercent=0.25%  |  RR=3.0x  |  Confirm  |  M3',
      5000, 12.5, '3.0x')
stats(t4, 'TBR M3  |  TBR_v1 v1.1    |  RiskAmountUSD=$50  |  RR=2.0x  |  Breakout |  M3',
      5000, 50.0, '2.0x')

# ── TABLA COMPARATIVA FINAL ──────────────────────────────────────────
print()
print('=' * 68)
print('  COMPARATIVA DIRECTA')
print('=' * 68)

def quick(m, initial=5000):
    w = m[m['profit']>0]; l = m[m['profit']<0]; to=m[m['exit_type']=='Timeout']
    gp=w['profit'].sum(); gl=abs(l['profit'].sum())
    pf=gp/gl if gl>0 else 9999
    cumbal=m['balance']; pk=cumbal.cummax()
    dd=abs((cumbal-pk).min())/initial*100
    return {
        'n':        len(m),
        'wr':       len(w)/len(m)*100,
        'pf':       pf,
        'net':      m['profit'].sum(),
        'avg_w':    w['profit'].mean() if len(w)>0 else 0,
        'avg_l':    l['profit'].mean() if len(l)>0 else 0,
        'rr_real':  abs(w['profit'].mean()/l['profit'].mean()) if len(l)>0 and len(w)>0 else 0,
        'dd':       dd,
        'max_loss': m['profit'].min(),
        'dur_med':  m['duration_min'].median(),
        'dur_p90':  m['duration_min'].quantile(0.9),
        'dur_max':  m['duration_min'].max(),
        'n_tp':     len(w),
        'n_sl':     len(l),
        'n_to':     len(to),
        'to_avg':   to['profit'].mean() if len(to)>0 else 0,
    }

qn = quick(nr)
qt = quick(t4)

rows = [
    ('EA',                  'New Rate Ultra',       'TBR_v1 v1.1'),
    ('Temporalidad',        'M3',                   'M3'),
    ('Período',             '2022-2026',            '2022-2026'),
    ('Entrada',             'Confirmacion',         'Breakout STOP'),
    ('RR configurado',      '3.0x',                 '2.0x'),
    ('Risk/trade config',   '$12.50 (0.25%)',       '$50 (fijo USD)'),
    ('Dias activos',        'Lun Mie Vie',          'Lun Mie Vie Mar Sab'),
    ('---',                 '---',                  '---'),
    ('Trades',              str(qn['n']),           str(qt['n'])),
    ('Win Rate',            '%.1f%%'%qn['wr'],      '%.1f%%'%qt['wr']),
    ('Profit Factor',       '%.4f'%qn['pf'],        '%.4f'%qt['pf']),
    ('Profit Neto',         '$%.0f'%qn['net'],      '$%.0f'%qt['net']),
    ('Avg Win',             '$%.2f'%qn['avg_w'],    '$%.2f'%qt['avg_w']),
    ('Avg Loss',            '$%.2f'%qn['avg_l'],    '$%.2f'%qt['avg_l']),
    ('Avg Loss vs conf',    '%.1fx'%(abs(qn['avg_l'])/12.5), '%.1fx'%(abs(qt['avg_l'])/50)),
    ('RR Real',             '%.2fx'%qn['rr_real'],  '%.2fx'%qt['rr_real']),
    ('Max Loss 1 trade',    '$%.2f'%qn['max_loss'], '$%.2f'%qt['max_loss']),
    ('Max DD %',            '%.2f%%'%qn['dd'],      '%.2f%%'%qt['dd']),
    ('---',                 '---',                  '---'),
    ('Dur mediana',         '%.0fmin'%qn['dur_med'],'%.0fmin'%qt['dur_med']),
    ('Dur p90',             '%.0fmin'%qn['dur_p90'],'%.0fmin'%qt['dur_p90']),
    ('Dur max',             '%.0fmin'%qn['dur_max'],'%.0fmin'%qt['dur_max']),
    ('---',                 '---',                  '---'),
    ('TP exits',            '%d (%.0f%%)'%(qn['n_tp'],qn['n_tp']/qn['n']*100), '%d (%.0f%%)'%(qt['n_tp'],qt['n_tp']/qt['n']*100)),
    ('SL exits',            '%d (%.0f%%)'%(qn['n_sl'],qn['n_sl']/qn['n']*100), '%d (%.0f%%)'%(qt['n_sl'],qt['n_sl']/qt['n']*100)),
    ('Timeout exits',       '%d (%.0f%%)'%(qn['n_to'],qn['n_to']/qn['n']*100), '%d (%.0f%%)'%(qt['n_to'],qt['n_to']/qt['n']*100)),
    ('Timeout avg profit',  '$%.2f'%qn['to_avg'],  '$%.2f'%qt['to_avg']),
]

print('  %-22s  %-22s  %-22s' % ('METRICA', 'NR M3', 'TBR M3 v1.1'))
print('  ' + '-'*66)
for r in rows:
    if r[0] == '---':
        print('  ' + '-'*66)
    else:
        print('  %-22s  %-22s  %-22s' % r)
