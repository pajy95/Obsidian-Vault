"""
Analisis IS/OOS/WFA — TBR v1.0b P1 y P2 | XAUUSD M5
Parser correcto: usa DEAL rows (col[4]='in'/'out') y P&L real en col[10]
Incluye analisis de regimen trimestral para evaluar si 2026 es atipico
"""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import pandas as pd, numpy as np, os, warnings
warnings.filterwarnings('ignore')

ACCOUNT = 5_000.0

BASE = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\XAUUSD"

PASSES = {
    "P1": dict(
        rr=3.6, candles=3, minute=45, be=False, pass_num=7129,
        files={
            "IS  2022-2024": f"{BASE}\\IS_TBR_XAUUSD_P1_2022-2024.xlsx",
            "OOS 2025":      f"{BASE}\\OOS_TBR_XAUUSD_P1_2025.xlsx",
            "WFA 2026":      f"{BASE}\\WFA_TBR_XAUUSD_P1_2026.xlsx",
        }
    ),
    "P2": dict(
        rr=2.8, candles=8, minute=25, be=False, pass_num=2603,
        files={
            "IS  2022-2024": f"{BASE}\\is_tbr_xauusd_p2_2022-2024.xlsx",
            "OOS 2025":      f"{BASE}\\OOS_TBR_XAU_P2_2025.xlsx",
            "WFA 2026":      f"{BASE}\\WFA_TBR_XAU_P2_2026.xlsx",
        }
    ),
}

# ── Parser DEAL format ────────────────────────────────────────────────────────
def parse_deal(path):
    """
    Parser para reportes MT5 en formato DEAL:
      col[0]:  datetime
      col[3]:  buy / sell
      col[4]:  in / out
      col[5]:  volume
      col[6]:  precio (entrada o salida)
      col[8]:  comision
      col[10]: profit real del deal
      col[11]: balance
      col[12]: comentario (TBR BUY/SELL STOP, sl X, tp X, o vacio=timeout)
    """
    if not os.path.exists(path):
        print("  ARCHIVO NO ENCONTRADO: " + path)
        return pd.DataFrame()

    df = pd.read_excel(path, header=None)
    rows = df[df[0].astype(str).str.match(r'^\d{4}\.\d{2}\.\d{2}')]

    # Entradas: col[4]='in'
    entries = rows[rows[4].astype(str).str.strip().str.lower() == 'in'].copy()
    # Salidas: col[4]='out'
    exits   = rows[rows[4].astype(str).str.strip().str.lower() == 'out'].copy()

    if len(entries) == 0 or len(exits) == 0:
        return pd.DataFrame()

    trades = []
    for (_, e), (_, x) in zip(entries.iterrows(), exits.iterrows()):
        # Direccion por tipo de entry deal
        entry_type = str(e[3]).strip().lower()
        direction  = 'LONG' if entry_type == 'buy' else 'SHORT'

        # Comentario del exit para clasificar tipo
        comment = str(x[12]).strip().lower() if pd.notna(x[12]) else ''
        if comment.startswith('tp'):
            exit_type = 'TP'
        elif comment.startswith('sl'):
            exit_type = 'SL'
        else:
            exit_type = 'Timeout'

        pnl = float(x[10]) if pd.notna(x[10]) else 0.0

        dt_str   = str(e[0])
        fecha    = dt_str[:10]
        hora     = dt_str[11:16] if len(dt_str) > 10 else ''
        vol      = float(str(e[5]).split('/')[0].strip()) if pd.notna(e[5]) else 0.01

        # Precios
        entry_price = float(e[6]) if pd.notna(e[6]) else 0.0
        exit_price  = float(x[6]) if pd.notna(x[6]) else 0.0

        trades.append({
            'direction':   direction,
            'exit_type':   exit_type,
            'pnl':         pnl,
            'vol':         vol,
            'entry_price': entry_price,
            'exit_price':  exit_price,
            'fecha':       fecha,
            'hora':        hora,
        })

    td = pd.DataFrame(trades)
    if len(td) > 0:
        td = td.sort_values('fecha').reset_index(drop=True)
    return td

# ── Metricas completas ────────────────────────────────────────────────────────
def metricas(df, label, rr=3.6, verbose=True):
    if verbose:
        print("\n" + "─"*70)
        print("  " + label)
        print("─"*70)

    if len(df) == 0:
        if verbose: print("  SIN DATOS")
        return {}

    tp_n  = (df['exit_type'] == 'TP').sum()
    sl_n  = (df['exit_type'] == 'SL').sum()
    to_n  = (df['exit_type'] == 'Timeout').sum()
    ts    = tp_n + sl_n
    wr_ts = tp_n / ts if ts > 0 else 0

    # PF real (basado en P&L efectivo de cada trade)
    gross_win  = df[df['pnl'] > 0]['pnl'].sum()
    gross_loss = abs(df[df['pnl'] < 0]['pnl'].sum())
    pf_real    = gross_win / gross_loss if gross_loss > 0 else 99.0

    # PF teorico TP/SL (sin timeouts)
    pf_ts = (tp_n * rr) / sl_n if sl_n > 0 else 99.0

    net     = df['pnl'].sum()
    cum     = df['pnl'].cumsum()
    dd      = cum.cummax() - cum
    mdd_usd = dd.max()
    mdd_pct = mdd_usd / ACCOUNT * 100

    long_n  = (df['direction'] == 'LONG').sum()
    short_n = (df['direction'] == 'SHORT').sum()

    if verbose:
        print("  Trades:       " + str(len(df)) + "  (L=" + str(long_n) + " / S=" + str(short_n) + ")")
        print("  TP/SL/TO:     " + str(tp_n) + " / " + str(sl_n) + " / " + str(to_n))
        print("  WR (TP+SL):   " + "{:.1%}".format(wr_ts) + "  (" + str(tp_n) + "/" + str(ts) + ")")
        pf_flag = "OK" if pf_real >= 1.4 else ("~" if pf_real >= 1.0 else "XX")
        print("  PF real:      " + "{:.3f}".format(pf_real) + "   [" + pf_flag + "]  (gross win/loss incluye timeouts)")
        print("  PF(TP+SL):    " + "{:.3f}".format(pf_ts) + "   (solo TP y SL, referencial)")
        print("  Net Profit:   $" + "{:+.2f}".format(net))
        dd_flag = "OK" if mdd_pct <= 10 else "XX"
        print("  Max DD:       $" + "{:.2f}".format(mdd_usd) + "  (" + "{:.2f}".format(mdd_pct) + "%)  [" + dd_flag + "]")

        # TO breakdown
        if to_n > 0:
            to_df  = df[df['exit_type'] == 'Timeout']
            to_pos = (to_df['pnl'] > 0).sum()
            to_neg = (to_df['pnl'] < 0).sum()
            to_net = to_df['pnl'].sum()
            print("  Timeouts:     " + str(to_n) + " trades  (" + str(to_pos) + " pos / " + str(to_neg) + " neg)  Net=$" + "{:+.2f}".format(to_net))

        # Por año
        df2 = df.copy(); df2['anio'] = df2['fecha'].str[:4]
        print("\n  Por año:")
        print("  " + "{:<6}".format("Año") + "{:>4}".format("T") + "{:>4}".format("TP") +
              "{:>4}".format("SL") + "{:>4}".format("TO") + "{:>8}".format("WR(TS)") +
              "{:>8}".format("PF_real") + "{:>10}".format("Net"))
        for anio, g in df2.groupby('anio'):
            gtp=(g['exit_type']=='TP').sum(); gsl=(g['exit_type']=='SL').sum()
            gto=(g['exit_type']=='Timeout').sum(); gts=gtp+gsl
            gwr=gtp/gts if gts>0 else 0
            gw=g[g['pnl']>0]['pnl'].sum(); gl=abs(g[g['pnl']<0]['pnl'].sum())
            gpf=gw/gl if gl>0 else 99
            gnet=g['pnl'].sum()
            flag='OK' if gpf>=1.4 else ('~' if gpf>=1.0 else 'XX')
            print("  [" + flag + "] " + "{:<4}".format(str(anio)) +
                  "{:>5}".format(len(g)) + "{:>4}".format(gtp) + "{:>4}".format(gsl) +
                  "{:>4}".format(gto) + "{:>7.1%}".format(gwr) +
                  "{:>8.3f}".format(gpf) + "  $" + "{:>+9.2f}".format(gnet))

        # Por dia
        try:
            df2['dt']  = pd.to_datetime(df2['fecha'], format='%Y.%m.%d', errors='coerce')
            df2['dow'] = df2['dt'].dt.day_name()
            print("\n  Por día:")
            print("  " + "{:<12}".format("Día") + "{:>4}".format("T") + "{:>4}".format("TP") +
                  "{:>4}".format("SL") + "{:>4}".format("TO") + "{:>7}".format("WR") + "{:>10}".format("Net"))
            for dia in ['Monday','Tuesday','Wednesday','Thursday','Friday']:
                g = df2[df2['dow']==dia]
                if len(g)==0: continue
                gtp=(g['exit_type']=='TP').sum(); gsl=(g['exit_type']=='SL').sum()
                gto=(g['exit_type']=='Timeout').sum(); gts=gtp+gsl
                gwr=gtp/gts if gts>0 else 0; gnet=g['pnl'].sum()
                flag='OK' if gnet>0 else 'XX'
                print("  [" + flag + "] " + "{:<10}".format(dia) +
                      "{:>5}".format(len(g)) + "{:>4}".format(gtp) + "{:>4}".format(gsl) +
                      "{:>4}".format(gto) + "{:>6.1%}".format(gwr) + "  $" + "{:>+9.2f}".format(gnet))
        except: pass

        # Por direccion
        print("\n  Por dirección:")
        for d in ['LONG','SHORT']:
            g = df[df['direction']==d]
            if len(g)==0: continue
            gtp=(g['exit_type']=='TP').sum(); gsl=(g['exit_type']=='SL').sum()
            gto=(g['exit_type']=='Timeout').sum(); gts=gtp+gsl
            gwr=gtp/gts if gts>0 else 0
            gw=g[g['pnl']>0]['pnl'].sum(); gl=abs(g[g['pnl']<0]['pnl'].sum())
            gpf=gw/gl if gl>0 else 99
            gnet=g['pnl'].sum()
            flag='OK' if gpf>=1.4 else ('~' if gpf>=1.0 else 'XX')
            print("  [" + flag + "] " + d + "  T=" + str(len(g)) +
                  " TP=" + str(gtp) + " SL=" + str(gsl) + " TO=" + str(gto) +
                  " WR=" + "{:.1%}".format(gwr) + " PF=" + "{:.3f}".format(gpf) +
                  " Net=$" + "{:+.2f}".format(gnet))

    # Calculo de PF para criterios
    return {'pf_real': pf_real, 'pf_ts': pf_ts, 'wr_ts': wr_ts,
            'net': net, 'mdd_pct': mdd_pct, 'mdd_usd': mdd_usd,
            'trades': len(df), 'tp': tp_n, 'sl': sl_n, 'to': to_n}

# ── Analisis trimestral ───────────────────────────────────────────────────────
def quarterly(df, label):
    if len(df) == 0:
        return pd.DataFrame()
    df2 = df.copy()
    df2['dt'] = pd.to_datetime(df2['fecha'], format='%Y.%m.%d', errors='coerce')
    df2['q']  = df2['dt'].dt.to_period('Q')
    rows = []
    for q, g in df2.groupby('q'):
        if len(g) < 5: continue
        gtp=(g['exit_type']=='TP').sum(); gsl=(g['exit_type']=='SL').sum()
        gto=(g['exit_type']=='Timeout').sum(); gts=gtp+gsl
        gwr=gtp/gts if gts>0 else 0
        gw=g[g['pnl']>0]['pnl'].sum(); gl=abs(g[g['pnl']<0]['pnl'].sum())
        gpf=gw/gl if gl>0 else 99
        gnet=g['pnl'].sum()
        rows.append({'Q': str(q), 'T': len(g), 'TP': gtp, 'SL': gsl, 'TO': gto,
                     'WR': gwr, 'PF': gpf, 'Net': gnet, 'periodo': label,
                     'hostile': gpf < 1.0})
    return pd.DataFrame(rows)

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

all_results = {}

for pass_id, cfg in PASSES.items():
    print("=" * 70)
    print("TBR v1.0b " + pass_id + " | XAUUSD M5 | Candles=" + str(cfg['candles']) +
          " Min=" + str(cfg['minute']) + " RR=" + str(cfg['rr']) + " BE=OFF")
    print("Pass #" + str(cfg['pass_num']) + "  |  VPP=$100/pt/lot  |  Cuenta=$" + str(int(ACCOUNT)))
    print("=" * 70)

    res = {}
    for label, path in cfg['files'].items():
        df = parse_deal(path)
        m  = metricas(df, label + " — " + pass_id, rr=cfg['rr'])
        res[label] = (df, m)
    all_results[pass_id] = (res, cfg)

# ── Veredictos IS/OOS ─────────────────────────────────────────────────────────
for pass_id, (res, cfg) in all_results.items():
    print("\n" + "=" * 70)
    print("VEREDICTO IS/OOS — " + pass_id)
    print("=" * 70)

    is_m  = res.get("IS  2022-2024", (None, {}))[1]
    oos_m = res.get("OOS 2025",      (None, {}))[1]
    wfa_m = res.get("WFA 2026",      (None, {}))[1]

    if not is_m or not oos_m:
        print("  Datos insuficientes")
        continue

    is_pf   = is_m.get('pf_real', 0)
    oos_pf  = oos_m.get('pf_real', 0)
    oos_dd  = oos_m.get('mdd_pct', 99)
    oos_n   = oos_m.get('trades', 0)
    oos_net = oos_m.get('net', 0)
    ratio   = (oos_pf / is_pf * 100) if is_pf > 0 else 0

    checks = [
        (oos_pf >= 1.4,  "PF OOS (real) >= 1.40",        "{:.3f}".format(oos_pf)),
        (oos_dd <= 10.0, "Max DD OOS <= 10%",             "{:.2f}%".format(oos_dd)),
        (oos_n  >= 30,   "Trades OOS >= 30",              str(oos_n)),
        (ratio  >= 50,   "Rendimiento OOS/IS >= 50%",     "{:.1f}%".format(ratio)),
        (oos_net > 0,    "Net OOS > 0",                   "$" + "{:+.2f}".format(oos_net)),
    ]
    ok = sum(1 for c, _, _ in checks if c)
    for cond, lbl, val in checks:
        sym = 'OK' if cond else 'XX'
        print("  [" + sym + "] " + "{:<38}".format(lbl) + "{:>10}".format(val))

    verdict = "VIABLE" if ok==5 else ("MARGINAL" if ok>=4 else "NO VIABLE")
    print("\n  IS  PF={:.3f}  |  OOS PF={:.3f}  |  Ratio={:.1f}%".format(is_pf, oos_pf, ratio))
    print("  VEREDICTO " + pass_id + " IS/OOS: " + verdict + " (" + str(ok) + "/5)")

    if wfa_m:
        wfa_pf  = wfa_m.get('pf_real', 0)
        wfa_dd  = wfa_m.get('mdd_pct', 99)
        wfa_n   = wfa_m.get('trades', 0)
        wfa_net = wfa_m.get('net', 0)
        wfa_ok  = 'OK' if wfa_pf>=1.4 else ('~' if wfa_pf>=1.0 else 'XX')
        print("\n  WFA 2026 (n=" + str(wfa_n) + "): PF=" + "{:.3f}".format(wfa_pf) +
              "  DD=" + "{:.2f}%".format(wfa_dd) + "  Net=$" + "{:+.2f}".format(wfa_net) +
              "  [" + wfa_ok + "]")

# ── Analisis de regimen trimestral ────────────────────────────────────────────
print("\n" + "=" * 70)
print("ANALISIS DE REGIMEN TRIMESTRAL")
print("Objetivo: comparar sub-periodos IS/OOS con WFA 2026")
print("PF calculado con P&L real (incluye timeout trades)")
print("=" * 70)

all_q = {}
for pass_id, (res, cfg) in all_results.items():
    print("\n  --- " + pass_id + " ---")
    print("  " + "{:<10}".format("Trim") + "{:>4}".format("T") + "{:>4}".format("TP") +
          "{:>4}".format("SL") + "{:>4}".format("TO") + "{:>7}".format("WR") +
          "{:>8}".format("PF_real") + "{:>9}".format("Net") + "  Status")
    q_frames = []
    for label in ["IS  2022-2024", "OOS 2025", "WFA 2026"]:
        df_item = res.get(label, (pd.DataFrame(), {}))[0]
        q_df = quarterly(df_item, label)
        if len(q_df) > 0:
            q_frames.append(q_df)
    if not q_frames:
        continue
    combined = pd.concat(q_frames, ignore_index=True)
    all_q[pass_id] = combined
    for _, r in combined.iterrows():
        is_wfa = r['periodo'] == 'WFA 2026'
        flag   = 'XX' if r['PF'] < 1.0 else ('OK' if r['PF'] >= 1.4 else '~')
        marker = '' if not r['hostile'] else (' <- WFA 2026' if is_wfa else ' <- HOSTIL IS/OOS')
        print("  [" + flag + "] " + "{:<10}".format(r['Q']) +
              "{:>4}".format(int(r['T'])) + "{:>4}".format(int(r['TP'])) +
              "{:>4}".format(int(r['SL'])) + "{:>4}".format(int(r['TO'])) +
              "{:>6.1%}".format(r['WR']) + "{:>8.3f}".format(r['PF']) +
              "  $" + "{:>+7.2f}".format(r['Net']) + marker)

# ── Diagnostico de regimen 2026 ───────────────────────────────────────────────
print("\n" + "=" * 70)
print("DIAGNOSTICO DE REGIMEN 2026")
print("=" * 70)

for pass_id, q_df in all_q.items():
    wfa_rows    = q_df[q_df['periodo'] == 'WFA 2026']
    is_oos_rows = q_df[q_df['periodo'] != 'WFA 2026']
    hostiles    = is_oos_rows[is_oos_rows['hostile']]

    wfa_pf_avg    = wfa_rows['PF'].mean() if len(wfa_rows) > 0 else 0
    wfa_net_sum   = wfa_rows['Net'].sum()
    is_oos_pf_min = is_oos_rows['PF'].min() if len(is_oos_rows) > 0 else 0
    is_oos_pf_avg = is_oos_rows['PF'].mean() if len(is_oos_rows) > 0 else 0

    pct_hostil = len(hostiles) / len(is_oos_rows) * 100 if len(is_oos_rows) > 0 else 0

    print("\n  " + pass_id + ":")
    print("  PF promedio IS/OOS (trimestral): {:.3f}".format(is_oos_pf_avg))
    print("  PF minimo   IS/OOS (trimestral): {:.3f}".format(is_oos_pf_min))
    print("  PF promedio WFA 2026:            {:.3f}".format(wfa_pf_avg))
    print("  Net WFA 2026 (trim total):       ${:+.2f}".format(wfa_net_sum))
    print("  Trimestres hostiles IS/OOS:      {}/{} ({:.0f}%)".format(
          len(hostiles), len(is_oos_rows), pct_hostil))

    if len(wfa_rows) > 0:
        if wfa_pf_avg < is_oos_pf_min:
            print("  CONCLUSION: 2026 es MAS hostil que cualquier trimestre previo")
            print("  PF 2026 < PF_min IS/OOS -> posible regimen atipico (macro/politico)")
        else:
            worst_hist = is_oos_rows.nsmallest(3, 'PF')[['Q','PF','Net']].to_dict('records')
            print("  CONCLUSION: 2026 es comparable a trimestres previos")
            print("  Peores trimestres hist: " +
                  ", ".join([r['Q'] + " PF=" + "{:.3f}".format(r['PF']) for r in worst_hist]))

# ── Resumen ejecutivo P1 vs P2 ────────────────────────────────────────────────
print("\n" + "=" * 70)
print("RESUMEN EJECUTIVO — P1 vs P2 (PF real, con timeouts)")
print("=" * 70)
print("  " + "{:<28}".format("Metrica") + "{:>10}".format("P1") + "{:>10}".format("P2"))
print("  " + "-"*48)

for label_key in ["IS  2022-2024", "OOS 2025", "WFA 2026"]:
    m1 = all_results["P1"][0].get(label_key, (None, {}))[1]
    m2 = all_results["P2"][0].get(label_key, (None, {}))[1]
    short = label_key.strip()
    pf1 = m1.get('pf_real', 0) if m1 else 0
    pf2 = m2.get('pf_real', 0) if m2 else 0
    dd1 = m1.get('mdd_pct', 0) if m1 else 0
    dd2 = m2.get('mdd_pct', 0) if m2 else 0
    n1  = m1.get('trades', 0) if m1 else 0
    n2  = m2.get('trades', 0) if m2 else 0
    net1= m1.get('net', 0) if m1 else 0
    net2= m2.get('net', 0) if m2 else 0
    print("  PF_real " + "{:<20}".format(short) + "{:>10.3f}".format(pf1) + "{:>10.3f}".format(pf2))
    print("  DD%     " + "{:<20}".format(short) + "{:>9.2f}%".format(dd1) + "{:>9.2f}%".format(dd2))
    print("  T       " + "{:<20}".format(short) + "{:>10}".format(n1) + "{:>10}".format(n2))
    print("  Net     " + "{:<20}".format(short) + "  ${:>+7.2f}".format(net1) + "  ${:>+7.2f}".format(net2))
    print()
