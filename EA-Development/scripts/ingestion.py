import pandas as pd
from pathlib import Path


def load_backtest_csv(filepath: str) -> pd.DataFrame:
    """Load a MetaTrader Strategy Tester CSV export."""
    df = pd.read_csv(filepath, sep="\t", encoding="utf-16", skiprows=0)
    df.columns = df.columns.str.strip()
    df["Time"] = pd.to_datetime(df["Time"], errors="coerce")
    return df


def load_all_backtests(strategies_root: str) -> dict[str, pd.DataFrame]:
    """Load all Backtests CSVs from every strategy folder."""
    root = Path(strategies_root)
    result = {}
    for csv_file in root.glob("*/Backtests/*.csv"):
        strategy = csv_file.parent.parent.name
        result[f"{strategy}/{csv_file.stem}"] = load_backtest_csv(str(csv_file))
    return result
