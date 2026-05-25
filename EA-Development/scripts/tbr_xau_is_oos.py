"""
Analisis IS/OOS/WFA — TBR v1.0b XAUUSD M5
Soporta P1 (Candles=3, Min=45, RR=3.6) y P2 (Candles=8, Min=25, RR=2.8)
Parser bidireccional (long + short)
Exits en col[12] comment: 'sl PRICE' / 'tp PRICE' / NaN (timeout)
VPP XAUUSD = 100 USD/punto/lot estandar
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pandas as pd, numpy as np, warnings
warnings.filterwarnings('ignore')

# ── Configuracion de pase ─────────────────────────────────────────────────────
PASS = "P1"   # cambiar a "P2" para analizar el pase alternativo

PASSES = {
    "P1": dict(
        rr=3.6, candles=3, hour=14, minute=45,
        be=False, pass_num=7129,
        label="P1 | Candles=3, Min=45, RR=3.6, BE=OFF",
        files={
            "IS  2022-2024": r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\IS_TBR_XAUUSD_P1_2022-2024.xlsx",
            "OOS 2025":      r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\OOS_TBR_XAUUSD_P1_2025.xlsx",
            "WFA 2026":      r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\WFA_TBR_XAUUSD_P1_2026.xlsx",
        }
    ),
    "P2": dict(
        rr=2.8, candles=8, hour=14, minute=25,
        be=False, pass_num=2603,
        label="P2 | Candles=8, Min=25, RR=2.8, BE=OFF",
        files={
            "IS  2022-2024": r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\IS_TBR_XAUUSD_P2_2022-2024.xlsx",
            "OOS 2025":      r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\OOS_TBR_XAUUSD_P2_2025.xlsx",
            "WFA 2026":      r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD\WFA_TBR_XAUUSD_P2_2026.xlsx",
        }
    ),
}

cfg     = PASSES[PASS]
RR      = cfg["rr"]
VPP     = 100.0   # XAUUSD: $1 por punto por 0.01 lot -> 100 por lot estandar
ACCOUNT = 5_000.0
FILES   = cfg["files"]

# ── Parser XAU ────────────────────────────────────────────────────────────────
def parse_xau(path, rr=RR, vpp=VPP):
    df = pd.read_excel(path, header=None)
    rows = df[df[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]

    long_ent = rows[(rows[3].astype(str).str.strip().str.lower() == 'buy stop') &
                    (rows[11].astype(str).str.strip().str.lower() == 'filled')]

    short_ent = rows[(rows[3].astype(str).str.strip().str.lower() == 'sell stop') &
                     (rows[11].astype(str).str.strip().str.lower() == 'filled')]

    long_exit = rows[(rows[3].astype(str).str.strip().str.lower() == 'sell') &
                     (rows[11].astype(str).str.strip().str.lower() == 'filled') &
                     (rows[6].astype(str).str.strip() == '0')]

    short_exit = rows[(rows[3].astype(str).str.strip().str.lower() == 'buy') &
                      (rows[11].astype(str).str.strip().str.lower() == 'filled') &
                      (rows[6].astype(str).str.strip() == '0')]

    all_trades = []

    for ent_df, exit_df, direction in [
        (long_ent,  long_exit,  'LONG'),
        (short_ent, short_exit, 'SHORT'),
    ]:
        entries, exits = [], []

        for _, r in ent_df.iterrows():
            try:
                price = float(r[6]); sl = float(r[7]); tp = float(r[8])
                vol   = float(str(r[4]).split('/')[0].strip())
            except:
                continue
            if direction == 'LONG':
                sl_dist = price - sl
            else:
                sl_dist = sl - price
            if sl_dist <= 0 or vol <= 0:
                continue
            dt_str = str(r[0])
            fecha  = dt_str[:10]
            hora   = dt_str[11:16] if len(dt_str) > 10 else ''
            entries.append({'price': price, 'sl': sl, 'tp': tp,
                            'vol': vol, 'sl_dist': sl_dist,
                            'fecha': fecha, 'hora': hora})

        for _, r in exit_df.iterrows():
            raw_comment = str(r[12]).strip().lower() if pd.notna(r[12]) else ''
            if raw_comment.startswith('tp'):
                exit_type = 'TP'
            elif raw_comment.startswith('sl'):
                exit_type = 'SL'
            else:
                exit_type = 'Timeout'
            dt_str = str(r[0])
            exits.append({'exit_type': exit_type, 'fecha': dt_str[:10],
                          'comment': raw_comment})

        n = min(len(entries), len(exits))
        for i in range(n):
            e = entries[i]; x = exits[i]
            if x['exit_type'] == 'TP':
                pnl = e['vol'] * e['sl_dist'] * vpp * rr
            elif x['exit_type'] == 'SL':
                pnl = -e['vol'] * e['sl_dist'] * vpp
            else:
                pnl = 0.0
            all_trades.append({
                'direction':  direction,
                'exit_type':  x['exit_type'],
                'pnl':        pnl,
                'vol':        e['vol'],
                'sl_dist':    e['sl_dist'],
                'fecha':      e['fecha'],
                'hora':       e['hora'],
            })

    td = pd.DataFrame(all_trades)
    if len(td) > 0:
        td = td.sort_values('fecha').reset_index(drop=True)
    return td

# ── Metricas ──────────────────────────────────────────────────────────────────
def metricas(df, label):
    print(f"\n{'─'*70}")
    print(f"  {label}")
    print(f"{'─'*70}")

    if len(df) == 0:
        print("  SIN DATOS")
        return {}

    tp_df  = df[df['exit_type'] == 'TP']
    sl_df  = df[df['exit_type'] == 'SL']
    to_df  = df[df['exit_type'] == 'Timeout']

    tp_n = len(tp_df); sl_n = len(sl_df); to_n = len(to_df)
    ts_total = tp_n + sl_n
    wr_ts    = tp_n / ts_total if ts_total > 0 else 0

    gross_win  = df[df['pnl'] > 0]['pnl'].sum()
    gross_loss = abs(df[df['pnl'] < 0]['pnl'].sum())
    pf_all     = gross_win / gross_loss if gross_loss > 0 else 99.0
    pf_ts      = (tp_n * RR) / sl_n if sl_n > 0 else 99.0

    net = df['pnl'].sum()

    cum  = df['pnl'].cumsum()
    peak = cum.cummax()
    dd   = peak - cum
    max_dd_usd = dd.max()
    max_dd_pct = max_dd_usd / ACCOUNT * 100

    long_n  = (df['direction'] == 'LONG').sum()
    short_n = (df['direction'] == 'SHORT').sum()

    print(f"  Trades totales:   {len(df)}  (Long={long_n} / Short={short_n})")
    print(f"  TP / SL / TO:     {tp_n} / {sl_n} / {to_n}")
    print(f"  Win Rate (TP+SL): {wr_ts:.1%}  ({tp_n}/{ts_total})")
    print(f"  PF (TP+SL):       {pf_ts:.3f}   {'OK' if pf_ts>=1.4 else ('~' if pf_ts>=1.0 else 'XX')}")
    print(f"  PF (todos c/TO=0):{pf_all:.3f}")
    print(f"  Net Profit:       ${net:+.2f}  (aprox, TO={to_n} trades @ $0)")
    print(f"  Max Drawdown:     ${max_dd_usd:.2f}  ({max_dd_pct:.2f}%)  {'OK' if max_dd_pct<=10 else 'XX'}")

    if 'hora' in df.columns:
        horas = df['hora'].value_counts().head(3)
        print(f"  Hora de entrada:  {', '.join([f'{h} ({c}t)' for h,c in horas.items()])}")

    df2 = df.copy()
    df2['anio'] = df2['fecha'].str[:4]
    print(f"\n  Por año:")
    print(f"  {'Año':<6} {'T':>4} {'TP':>4} {'SL':>4} {'TO':>4} {'WR(TS)':>8} {'PF(TS)':>8} {'Net':>10}")
    for anio, g in df2.groupby('anio'):
        gtp = (g['exit_type']=='TP').sum()
        gsl = (g['exit_type']=='SL').sum()
        gto = (g['exit_type']=='Timeout').sum()
        gts = gtp + gsl
        gwr = gtp/gts if gts>0 else 0
        gpf = (gtp*RR)/gsl if gsl>0 else 99
        gnet= g['pnl'].sum()
        flag = 'OK' if gpf >= 1.4 else ('~' if gpf >= 1.0 else 'XX')
        print(f"  [{flag}] {anio:<4}  {len(g):>4} {gtp:>4} {gsl:>4} {gto:>4} "
              f"{gwr:>7.1%} {gpf:>8.3f} ${gnet:>+9.2f}")

    try:
        df2['dt']  = pd.to_datetime(df2['fecha'], format='%Y.%m.%d', errors='coerce')
        df2['dow'] = df2['dt'].dt.day_name()
        dias = ['Monday','Tuesday','Wednesday','Thursday','Friday']
        print(f"\n  Por día:")
        print(f"  {'Día':<12} {'T':>4} {'TP':>4} {'SL':>4} {'TO':>4} {'WR':>7} {'Net':>10}")
        for dia in dias:
            g = df2[df2['dow']==dia]
            if len(g)==0: continue
            gtp=(g['exit_type']=='TP').sum(); gsl=(g['exit_type']=='SL').sum()
            gto=(g['exit_type']=='Timeout').sum()
            gts=gtp+gsl; gwr=gtp/gts if gts>0 else 0
            gnet=g['pnl'].sum()
            flag='OK' if gnet>0 else 'XX'
            print(f"  [{flag}] {dia:<10}  {len(g):>4} {gtp:>4} {gsl:>4} {gto:>4} "
                  f"{gwr:>6.1%} ${gnet:>+9.2f}")
    except Exception as e:
        print(f"  (error dia semana: {e})")

    print(f"\n  Por dirección:")
    for d in ['LONG','SHORT']:
        g = df[df['direction']==d]
        if len(g)==0: continue
        gtp=(g['exit_type']=='TP').sum(); gsl=(g['exit_type']=='SL').sum()
        gto=(g['exit_type']=='Timeout').sum()
        gts=gtp+gsl; gwr=gtp/gts if gts>0 else 0
        gpf=(gtp*RR)/gsl if gsl>0 else 99
        gnet=g['pnl'].sum()
        flag='OK' if gpf>=1.4 else ('~' if gpf>=1.0 else 'XX')
        print(f"  [{flag}] {d:<6}  T={len(g)} TP={gtp} SL={gsl} TO={gto} "
              f"WR={gwr:.1%} PF={gpf:.3f} Net=${gnet:+.2f}")

    return {'pf_ts': pf_ts, 'pf_all': pf_all, 'wr_ts': wr_ts,
            'net': net, 'max_dd_pct': max_dd_pct,
            'trades': len(df), 'tp': tp_n, 'sl': sl_n, 'to': to_n}

# ── Main ──────────────────────────────────────────────────────────────────────
import os

print("=" * 70)
print(f"IS / OOS / WFA — TBR v1.0b {PASS} | XAUUSD M5")
print(f"Pass #{cfg['pass_num']}: {cfg['label']}")
print(f"VPP XAUUSD = $100/punto/lot  |  Cuenta = ${ACCOUNT:.0f}")
print("=" * 70)

results = {}
for label, path in FILES.items():
    if not os.path.exists(path):
        print(f"\n  [{label}] ARCHIVO NO ENCONTRADO: {path}")
        results[label] = (pd.DataFrame(), {})
        continue
    df = parse_xau(path)
    m  = metricas(df, label)
    results[label] = (df, m)

# ── Criterios minimos de viabilidad ──────────────────────────────────────────
print(f"\n{'='*70}")
print(f"CRITERIOS MINIMOS DE VIABILIDAD — {PASS}")
print(f"{'='*70}")

labels_to_check = ["IS  2022-2024", "OOS 2025"]
is_key  = "IS  2022-2024"
oos_key = "OOS 2025"
wfa_key = "WFA 2026"

is_m  = results.get(is_key,  (None, {}))[1]
oos_m = results.get(oos_key, (None, {}))[1]
wfa_m = results.get(wfa_key, (None, {}))[1]

if is_m and oos_m:
    is_pf    = is_m.get('pf_ts', 0)
    oos_pf   = oos_m.get('pf_ts', 0)
    oos_dd   = oos_m.get('max_dd_pct', 99)
    oos_n    = oos_m.get('trades', 0)
    oos_net  = oos_m.get('net', 0)
    oos_vs_is = (oos_pf / is_pf * 100) if is_pf > 0 else 0

    checks = [
        (oos_pf >= 1.4,     f"PF OOS (TP/SL) >= 1.40",       f"{oos_pf:.3f}"),
        (oos_dd <= 10.0,    f"Max DD OOS <= 10%",             f"{oos_dd:.2f}%"),
        (oos_n  >= 30,      f"Trades OOS >= 30",              f"{oos_n}"),
        (oos_vs_is >= 50,   f"Rendimiento OOS/IS >= 50%",     f"{oos_vs_is:.1f}%"),
        (oos_net > 0,       f"Net OOS > 0 (TO=0 aprox)",      f"${oos_net:+.2f}"),
    ]
    ok = sum(1 for c, _, _ in checks if c)
    for cond, lbl, val in checks:
        sym = 'OK' if cond else 'XX'
        print(f"  [{sym}] {lbl:<38} {val:>10}")

    verdict = "VIABLE" if ok == 5 else ("MARGINAL" if ok >= 4 else "NO VIABLE")
    print(f"\n  IS  PF(TP/SL): {is_pf:.3f}  |  OOS PF(TP/SL): {oos_pf:.3f}")
    print(f"  VEREDICTO IS/OOS: {verdict} ({ok}/5 criterios)")

    if wfa_m:
        wfa_pf  = wfa_m.get('pf_ts', 0)
        wfa_dd  = wfa_m.get('max_dd_pct', 99)
        wfa_n   = wfa_m.get('trades', 0)
        wfa_net = wfa_m.get('net', 0)
        print(f"\n  WFA 2026 (referencial, n={wfa_n}):")
        wfa_ok = 'OK' if wfa_pf >= 1.4 else ('~' if wfa_pf >= 1.0 else 'XX')
        print(f"  [{wfa_ok}] PF WFA: {wfa_pf:.3f}   DD: {wfa_dd:.2f}%   Net: ${wfa_net:+.2f}")
        if wfa_n < 30:
            print(f"       (muestra insuficiente — {wfa_n} trades, esperar mas datos)")

    if verdict == "VIABLE":
        print(f"\n  Siguiente: Monte Carlo")
    elif verdict == "MARGINAL":
        print(f"\n  Revisar breakdown por dia/direccion antes de avanzar")
    else:
        print(f"\n  No avanzar con {PASS}. Evaluar pase alternativo.")
