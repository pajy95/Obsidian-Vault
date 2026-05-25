import pandas as pd


def equity_curves(trades_dict: dict[str, pd.Series]) -> pd.DataFrame:
    """Build aligned daily equity curves from multiple strategy trade series."""
    curves = {}
    for name, trades in trades_dict.items():
        curves[name] = trades.cumsum()
    return pd.DataFrame(curves).fillna(method="ffill").fillna(0)


def correlation_matrix(trades_dict: dict[str, pd.Series]) -> pd.DataFrame:
    df = equity_curves(trades_dict)
    return df.corr(method="pearson").round(3)


def flag_high_correlation(corr_matrix: pd.DataFrame, threshold: float = 0.60) -> list[tuple]:
    """Return pairs with |r| >= threshold."""
    flagged = []
    cols = corr_matrix.columns
    for i in range(len(cols)):
        for j in range(i + 1, len(cols)):
            r = corr_matrix.iloc[i, j]
            if abs(r) >= threshold:
                flagged.append((cols[i], cols[j], round(r, 3)))
    return flagged
