import streamlit as st
import pandas as pd
from pathlib import Path

from ingestion import load_all_backtests
from metrics import full_report
from correlation import correlation_matrix, flag_high_correlation

STRATEGIES_ROOT = str(Path(__file__).parent.parent / "01-Strategies")

st.set_page_config(page_title="EA Dashboard", layout="wide")
st.title("EA Performance Dashboard")

data = load_all_backtests(STRATEGIES_ROOT)

if not data:
    st.warning("No se encontraron CSVs en las carpetas Backtests/. Exporta primero desde Strategy Tester.")
    st.stop()

selected = st.sidebar.multiselect("Estrategias", list(data.keys()), default=list(data.keys()))

st.header("Métricas por estrategia")
for name in selected:
    df = data[name]
    if "Profit" not in df.columns:
        st.error(f"{name}: columna 'Profit' no encontrada en el CSV.")
        continue
    trades = df["Profit"]
    report = full_report(trades)
    with st.expander(name):
        col1, col2, col3 = st.columns(3)
        col1.metric("Profit Factor", report["profit_factor"])
        col1.metric("Win Rate", f"{report['win_rate_pct']}%")
        col2.metric("Expectancy R", report["expectancy_r"])
        col2.metric("Sharpe", report["sharpe"])
        col3.metric("Max DD", f"{report['max_dd_pct']}%")
        col3.metric("Max Consec. Losers", report["max_consec_losers"])
        st.write("**Monte Carlo (p95 DD):**", report["monte_carlo"]["p95"], "%")

st.header("Correlación entre estrategias")
if len(selected) >= 2:
    trades_dict = {n: data[n]["Profit"] for n in selected if "Profit" in data[n].columns}
    corr = correlation_matrix(trades_dict)
    st.dataframe(corr.style.background_gradient(cmap="RdYlGn_r", vmin=-1, vmax=1))
    flagged = flag_high_correlation(corr)
    if flagged:
        st.warning("Pares con correlación alta (|r| ≥ 0.60):")
        for a, b, r in flagged:
            st.write(f"- **{a}** ↔ **{b}**: r = {r}")
else:
    st.info("Selecciona al menos 2 estrategias para ver correlación.")
