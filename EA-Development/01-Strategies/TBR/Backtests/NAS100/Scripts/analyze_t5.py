import pandas as pd
import numpy as np

path_nr = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\NAS100 V1 NR M3.xlsx'
path_t4 = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 FourtTest.xlsx'
path_t5 = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NAS100 TBR M5 fiveTest.xlsx'


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


def find_deals_row(filepath):
    df = pd.read_excel(filepath, sheet_name='Sheet1', header=None)
    for i in range(len(df)):
        for col in range(13):
            v = str(df.iloc[i, col]).strip() if pd.notna(df.iloc[i, col]) else ''
            if v == 'in':
                return i
    return None


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
    m['open_hour'] = m['open_time'].dt.hour + m['open_time'].dt.minute / 60
    m['open_dow']  = m['open_time'].dt.dayofweek
    m['year']      = m['open_time'].dt.year
    return m


def full_stats(m, name, initial=5000, risk_conf=50.0):
    sep = '=' * 70
    print()
    print(sep)
    print('  ' + name)
    print(sep)

    total    = len(m)
    winners  = m[m['profit'] > 0]
    losers   = m[m['profit'] < 0]
    timeouts = m[m['exit_type'] == 'Timeout']
    tp_trades= m[m['exit_type'] == 'TP']
    sl_trades= m[m['exit_type'] == 'SL']

    wr      = len(winners) / total * 100
    gp      = winners['profit'].sum()
    gl      = abs(losers['profit'].sum())
    net     = m['profit'].sum()
    pf      = gp / gl if gl > 0 else 9999
    avg_w   = winners['profit'].mean() if len(winners) > 0 else 0
    avg_l   = losers['profit'].mean()  if len(losers)  > 0 else 0
    rr_real = abs(avg_w / avg_l)       if avg_l != 0    else 0
    cumbal  = m['balance']
    peak    = cumbal.cummax()
    max_dd_usd = (cumbal - peak).min()
    max_dd_pct = abs(max_dd_usd) / initial * 100
    all_dur = m['duration_min']

    print('PERIODO   : %s -> %s' % (m['open_time'].min().date(), m['open_time'].max().date()))
    print()
    print('RESULTADOS:')
    print('  Trades          : %d' % total)
    print('  Win Rate        : %.1f%%  (TP=%d  SL=%d  Timeout=%d)' % (
        wr, len(tp_trades), len(sl_trades), len(timeouts)))
    print('  Profit Neto     : $%.2f' % net)
    print('  Gross Win       : $%.2f' % gp)
    print('  Gross Loss      : $%.2f' % gl)
    print('  Profit Factor   : %.4f   <- UMBRAL 1.40' % pf)
    print('  Avg Win         : $%.2f' % avg_w)
    print('  Avg Loss        : $%.2f' % avg_l)
    print('  Avg Loss vs conf: %.1fx  ($%.0f conf)' % (abs(avg_l)/risk_conf, risk_conf))
    print('  RR Real         : %.2fx' % rr_real)
    print('  Max Win 1 trade : $%.2f' % m['profit'].max())
    print('  Max Loss 1 trade: $%.2f  (%.1fx conf)' % (m['profit'].min(), abs(m['profit'].min())/risk_conf))
    print('  Max DD $        : $%.2f' % max_dd_usd)
    print('  Max DD %%        : %.2f%%  <- UMBRAL 10%%' % max_dd_pct)

    print()
    print('DURACION (minutos):')
    print('  Todos   : min=%.0f  med=%.0f  mean=%.0f  max=%.0f  p90=%.0f' % (
        all_dur.min(), all_dur.median(), all_dur.mean(), all_dur.max(), all_dur.quantile(0.9)))
    for tag, sub in [('TP', tp_trades), ('SL', sl_trades), ('Timeout', timeouts)]:
        if len(sub) > 0:
            d = sub['duration_min']
            print('  %-8s: min=%.0f  med=%.0f  mean=%.0f  max=%.0f  avg_profit=$%.2f' % (
                tag, d.min(), d.median(), d.mean(), d.max(), sub['profit'].mean()))

    print()
    print('DISTRIBUCION DURACION:')
    buckets = [(0,5,'0-5min'),(5,15,'5-15min'),(15,30,'15-30min'),
               (30,60,'30-60min'),(60,120,'1-2h'),(120,240,'2-4h'),(240,9999,'>=4h')]
    for lo, hi, label in buckets:
        sub = m[(m['duration_min'] >= lo) & (m['duration_min'] < hi)]
        if len(sub) > 0:
            ptp = len(sub[sub['exit_type']=='TP'])    / len(sub) * 100
            psl = len(sub[sub['exit_type']=='SL'])    / len(sub) * 100
            pto = len(sub[sub['exit_type']=='Timeout'])/ len(sub) * 100
            print('  %-10s: %3d (%3.0f%%)  avg=$%+7.1f  TP=%3.0f%% SL=%3.0f%% TO=%3.0f%%' % (
                label, len(sub), len(sub)/total*100, sub['profit'].mean(), ptp, psl, pto))

    print()
    print('POR ANO:')
    for yr, g in m.groupby('year'):
        gw  = g[g['profit'] > 0]
        gl_ = g[g['profit'] < 0]
        pf_yr = gw['profit'].sum() / abs(gl_['profit'].sum()) if len(gl_) > 0 else 9999
        print('  %d: n=%3d  net=$%+7.0f  PF=%.2f  WR=%2.0f%%  avg_dur=%3.0fmin  max_loss=$%6.0f' % (
            yr, len(g), g['profit'].sum(), pf_yr,
            len(gw)/len(g)*100, g['duration_min'].mean(), abs(g['profit'].min())))

    print()
    print('POR HORA DE ENTRADA (UTC):')
    for h, g in m.groupby(m['open_time'].dt.hour):
        gw  = g[g['profit'] > 0]
        gl_ = g[g['profit'] < 0]
        pf_h = gw['profit'].sum() / abs(gl_['profit'].sum()) if len(gl_) > 0 else 9999
        print('  %02d:xx UTC  n=%3d  net=$%+7.0f  PF=%.2f  WR=%2.0f%%  avg_dur=%3.0fmin' % (
            h, len(g), g['profit'].sum(), pf_h, len(gw)/len(g)*100, g['duration_min'].mean()))

    print()
    print('POR DIA (0=Lun):')
    dias = {0:'Lun',1:'Mar',2:'Mie',3:'Jue',4:'Vie',5:'Sab',6:'Dom'}
    for d, g in m.groupby('open_dow'):
        gw  = g[g['profit'] > 0]
        gl_ = g[g['profit'] < 0]
        pf_d = gw['profit'].sum() / abs(gl_['profit'].sum()) if len(gl_) > 0 else 9999
        print('  %-4s: n=%3d  net=$%+7.0f  PF=%.2f  WR=%2.0f%%' % (
            dias[d], len(g), g['profit'].sum(), pf_d, len(gw)/len(g)*100))

    print()
    print('VOLUMEN:')
    print('  min=%.2f  med=%.2f  mean=%.2f  max=%.2f' % (
        m['volume'].min(), m['volume'].median(), m['volume'].mean(), m['volume'].max()))

    return m


# ── Cargar ───────────────────────────────────────────────────────────
nr = build_trades(load_deals(path_nr, 1113))
t4 = build_trades(load_deals(path_t4, 1285))

row_t5 = find_deals_row(path_t5)
t5 = build_trades(load_deals(path_t5, row_t5))

full_stats(t5, 'TEST 5  |  TBR_v1 v1.1  |  M5  |  MODE_CONFIRM  |  BE=false  |  RR=2.0  |  RiskUSD=$50', 5000, 50.0)

# ── Comparativa T4 vs T5 vs NR ───────────────────────────────────────
print()
print('=' * 70)
print('  COMPARATIVA DIRECTA: NR M3  vs  TBR T4 (Breakout)  vs  TBR T5 (Confirm)')
print('=' * 70)

def quick(m, initial=5000, risk=50):
    w=m[m['profit']>0]; l=m[m['profit']<0]; to=m[m['exit_type']=='Timeout']
    gp=w['profit'].sum(); gl=abs(l['profit'].sum())
    pf=gp/gl if gl>0 else 9999
    dd=abs((m['balance']-m['balance'].cummax()).min())/initial*100
    avg_l=l['profit'].mean() if len(l)>0 else 0
    avg_w=w['profit'].mean() if len(w)>0 else 0
    return {
        'n':len(m), 'wr':len(w)/len(m)*100, 'pf':pf, 'net':m['profit'].sum(),
        'avg_w':avg_w, 'avg_l':avg_l,
        'rr':abs(avg_w/avg_l) if avg_l!=0 else 0,
        'dd':dd, 'max_loss':m['profit'].min(), 'max_win':m['profit'].max(),
        'n_tp':len(w), 'n_sl':len(l), 'n_to':len(to),
        'to_avg':to['profit'].mean() if len(to)>0 else 0,
        'dur_med':m['duration_min'].median(), 'dur_p90':m['duration_min'].quantile(0.9),
        'dur_max':m['duration_min'].max(),
        'avg_l_x':abs(avg_l)/risk,
        'max_loss_x':abs(m['profit'].min())/risk,
    }

qn = quick(nr,  5000, 12.5)
qt = quick(t4,  5000, 50.0)
q5 = quick(t5,  5000, 50.0)

rows = [
    ('EA / Version',        'New Rate Ultra',       'TBR v1.1 T4',         'TBR v1.1 T5'),
    ('Temporalidad',        'M3',                   'M3',                  'M5'),
    ('Entrada',             'Confirm',              'Breakout STOP',       'Confirm'),
    ('RR config',           '3.0x',                 '2.0x',                '2.0x'),
    ('Breakeven',           'OFF',                  'OFF',                 'OFF'),
    ('Risk/trade',          '$12.50 (0.25%)',        '$50 fijo',            '$50 fijo'),
    ('Calidad ticks',       '31%',                  '99%',                 '99%'),
    ('---','---','---','---'),
    ('Trades',              str(qn['n']),            str(qt['n']),          str(q5['n'])),
    ('Win Rate',            '%.1f%%'%qn['wr'],       '%.1f%%'%qt['wr'],     '%.1f%%'%q5['wr']),
    ('Profit Factor',       '%.4f'%qn['pf'],         '%.4f'%qt['pf'],       '%.4f'%q5['pf']),
    ('Profit Neto',         '$%.0f'%qn['net'],        '$%.0f'%qt['net'],      '$%.0f'%q5['net']),
    ('Avg Win',             '$%.2f'%qn['avg_w'],      '$%.2f'%qt['avg_w'],    '$%.2f'%q5['avg_w']),
    ('Avg Loss',            '$%.2f'%qn['avg_l'],      '$%.2f'%qt['avg_l'],    '$%.2f'%q5['avg_l']),
    ('Avg Loss vs conf',    '%.1fx'%qn['avg_l_x'],    '%.1fx'%qt['avg_l_x'],  '%.1fx'%q5['avg_l_x']),
    ('RR Real',             '%.2fx'%qn['rr'],          '%.2fx'%qt['rr'],       '%.2fx'%q5['rr']),
    ('Max Win 1 trade',     '$%.0f'%qn['max_win'],    '$%.0f'%qt['max_win'],  '$%.0f'%q5['max_win']),
    ('Max Loss 1 trade',    '$%.0f'%qn['max_loss'],   '$%.0f'%qt['max_loss'], '$%.0f'%q5['max_loss']),
    ('Max Loss vs conf',    '%.1fx'%qn['max_loss_x'], '%.1fx'%qt['max_loss_x'],'%.1fx'%q5['max_loss_x']),
    ('Max DD %',            '%.2f%%'%qn['dd'],         '%.2f%%'%qt['dd'],      '%.2f%%'%q5['dd']),
    ('---','---','---','---'),
    ('TP exits',            '%d(%.0f%%)'%(qn['n_tp'],qn['n_tp']/qn['n']*100),
                            '%d(%.0f%%)'%(qt['n_tp'],qt['n_tp']/qt['n']*100),
                            '%d(%.0f%%)'%(q5['n_tp'],q5['n_tp']/q5['n']*100)),
    ('SL exits',            '%d(%.0f%%)'%(qn['n_sl'],qn['n_sl']/qn['n']*100),
                            '%d(%.0f%%)'%(qt['n_sl'],qt['n_sl']/qt['n']*100),
                            '%d(%.0f%%)'%(q5['n_sl'],q5['n_sl']/q5['n']*100)),
    ('Timeout exits',       '%d(%.0f%%)'%(qn['n_to'],qn['n_to']/qn['n']*100),
                            '%d(%.0f%%)'%(qt['n_to'],qt['n_to']/qt['n']*100),
                            '%d(%.0f%%)'%(q5['n_to'],q5['n_to']/q5['n']*100)),
    ('Timeout avg profit',  '$%.2f'%qn['to_avg'],     '$%.2f'%qt['to_avg'],   '$%.2f'%q5['to_avg']),
    ('---','---','---','---'),
    ('Dur mediana',         '%.0fmin'%qn['dur_med'],   '%.0fmin'%qt['dur_med'], '%.0fmin'%q5['dur_med']),
    ('Dur p90',             '%.0fmin'%qn['dur_p90'],   '%.0fmin'%qt['dur_p90'], '%.0fmin'%q5['dur_p90']),
    ('Dur max',             '%.0fmin'%qn['dur_max'],   '%.0fmin'%qt['dur_max'], '%.0fmin'%q5['dur_max']),
]

print('  %-22s  %-22s  %-22s  %-22s' % ('METRICA','NR M3','TBR T4 Breakout','TBR T5 Confirm'))
print('  ' + '-'*88)
for r in rows:
    if r[0] == '---':
        print('  ' + '-'*88)
    else:
        print('  %-22s  %-22s  %-22s  %-22s' % r)

# ── Bug check: entradas fuera de sesion ──────────────────────────────
print()
print('=' * 70)
print('  ANOMALIA DETECTADA: entradas fuera de SessionEnd=17:00 UTC')
print('=' * 70)
late = t5[t5['open_time'].dt.hour >= 17]
print('T5 entradas >= 17:00 UTC: %d de %d trades (%.0f%%)' % (
    len(late), len(t5), len(late)/len(t5)*100))
print('  net=$%.2f  PF=%.2f  WR=%.0f%%' % (
    late['profit'].sum(),
    late[late['profit']>0]['profit'].sum() / abs(late[late['profit']<0]['profit'].sum())
    if len(late[late['profit']<0])>0 else 9999,
    len(late[late['profit']>0])/len(late)*100 if len(late)>0 else 0))
print()
print('Detalle primeras entradas tardias:')
print(late[['open_time','close_time','profit','duration_min','exit_type']].head(10).to_string())
print()

# Horas de entrada T5
print('Distribucion por hora de entrada T5:')
for h, g in t5.groupby(t5['open_time'].dt.hour):
    gw=g[g['profit']>0]; gl_=g[g['profit']<0]
    pf_h=gw['profit'].sum()/abs(gl_['profit'].sum()) if len(gl_)>0 else 9999
    flag = ' <-- FUERA DE SESION' if h >= 17 else ''
    print('  %02d:xx UTC  n=%3d  net=$%+6.0f  PF=%.2f  WR=%.0f%%%s' % (
        h, len(g), g['profit'].sum(), pf_h, len(gw)/len(g)*100, flag))
