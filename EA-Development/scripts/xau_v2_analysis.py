import openpyxl

base = 'c:/Users/JOSSE/Documents/Obsidian Vault/EA-Development/01-Strategies/BreakoutNY/Optmizacion/'

def extract_trades(filename):
    wb = openpyxl.load_workbook(base + filename)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    deals_header_idx = None
    for i, row in enumerate(rows):
        if row[0] == 'Time' and row[1] == 'Deal' and row[2] == 'Symbol':
            deals_header_idx = i; break
    if deals_header_idx is None: return []
    deals = []
    for row in rows[deals_header_idx+1:]:
        if row[0] is None or row[1] is None: break
        if isinstance(row[1],(int,float)) and row[3] in ('buy','sell') and row[4] in ('in','out','in/out'):
            deals.append({'time':row[0],'type':row[3],'direction':row[4],
                          'commission':row[8],'swap':row[9],'profit':row[10],'comment':row[12]})
    trades = []; entry = None
    for d in deals:
        if d['direction']=='in': entry=d
        elif d['direction']=='out' and entry is not None:
            net=(d['profit'] or 0)+(entry['commission'] or 0)+(d['commission'] or 0)+(entry['swap'] or 0)+(d['swap'] or 0)
            trades.append({'time':entry['time'],'direction':entry['type'],'net':net,'comment':d['comment'] or ''})
            entry=None
    return trades

def stats(trades, deposit=5000):
    equity = deposit; peak = deposit; max_dd = 0
    wins   = [t for t in trades if t['net'] > 0]
    losses = [t for t in trades if t['net'] < 0]
    for t in trades:
        equity += t['net']
        if equity > peak: peak = equity
        dd = (peak - equity) / peak * 100
        if dd > max_dd: max_dd = dd
    profit = equity - deposit
    pf  = sum(t['net'] for t in wins) / abs(sum(t['net'] for t in losses)) if losses else 999
    wr  = len(wins) / len(trades) * 100 if trades else 0
    avg_w = sum(t['net'] for t in wins)   / len(wins)   if wins   else 0
    avg_l = sum(t['net'] for t in losses) / len(losses) if losses else 0
    rr  = abs(avg_w / avg_l) if avg_l else 0
    return {'profit': profit, 'pf': pf, 'dd': max_dd, 'trades': len(trades),
            'wr': wr, 'avg_w': avg_w, 'avg_l': avg_l, 'rr': rr}

def pf_sub(tlist):
    w = sum(t['net'] for t in tlist if t['net'] > 0)
    l = abs(sum(t['net'] for t in tlist if t['net'] < 0))
    return w / l if l > 0 else 999

is_trades  = extract_trades('BK XAU v2.xlsx')
oos_trades = extract_trades('fr xau v2.xlsx')

s_is  = stats(is_trades,  deposit=5000)
s_oos = stats(oos_trades, deposit=5000)

is_l  = [t for t in is_trades  if t['direction'] == 'buy']
is_s  = [t for t in is_trades  if t['direction'] == 'sell']
oos_l = [t for t in oos_trades if t['direction'] == 'buy']
oos_s = [t for t in oos_trades if t['direction'] == 'sell']

print('=== IS 2021-2024 (BE=100, Thu Only) ===')
print(f'  Profit Neto:   ${s_is["profit"]:.2f}')
print(f'  Profit Factor: {s_is["pf"]:.3f}')
print(f'  Max DD:        {s_is["dd"]:.2f}%')
print(f'  Trades:        {s_is["trades"]} | WR: {s_is["wr"]:.1f}%')
print(f'  Avg Win:       ${s_is["avg_w"]:.2f} | Avg Loss: ${s_is["avg_l"]:.2f} | RR: {s_is["rr"]:.2f}')
print(f'  Longs:         {len(is_l)} trades | PF Longs: {pf_sub(is_l):.3f}')
print(f'  Shorts:        {len(is_s)} trades | PF Shorts: {pf_sub(is_s):.3f}')
print()
print('=== OOS 2025 (BE=100, Thu Only) ===')
print(f'  Profit Neto:   ${s_oos["profit"]:.2f}')
print(f'  Profit Factor: {s_oos["pf"]:.3f}')
print(f'  Max DD:        {s_oos["dd"]:.2f}%')
print(f'  Trades:        {s_oos["trades"]} | WR: {s_oos["wr"]:.1f}%')
print(f'  Avg Win:       ${s_oos["avg_w"]:.2f} | Avg Loss: ${s_oos["avg_l"]:.2f} | RR: {s_oos["rr"]:.2f}')
print(f'  Longs:         {len(oos_l)} trades | PF Longs: {pf_sub(oos_l):.3f}')
print(f'  Shorts:        {len(oos_s)} trades | PF Shorts: {pf_sub(oos_s):.3f}')
print()
print(f'  Retencion OOS: {s_oos["pf"] / s_is["pf"] * 100:.1f}%')
print()

# Alerta parametros
print('=== ALERTA DE PARAMETROS ===')
print('  BE_BufferPct usado en BK/FR: 100')
print('  BE_BufferPct recomendado Pass 98: 190')
print('  -> El backtest NO corresponde exactamente al Pass 98 analizado')
print('  -> MinSL=5.0, MaxSL=19.0, Thu Only, EMC=0 SI coinciden')
