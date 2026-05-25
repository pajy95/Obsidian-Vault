import numpy as np
import pandas as pd


def profit_factor(trades: pd.Series) -> float:
    gains = trades[trades > 0].sum()
    losses = abs(trades[trades < 0].sum())
    return round(gains / losses, 3) if losses != 0 else float("inf")


def expectancy_r(trades: pd.Series, avg_risk: float) -> float:
    """Expectancy in R units. avg_risk = average risk per trade in $."""
    if avg_risk == 0:
        return 0.0
    return round((trades.mean() / avg_risk), 3)


def win_rate(trades: pd.Series) -> float:
    return round(len(trades[trades > 0]) / len(trades) * 100, 2)


def max_drawdown(equity_curve: pd.Series) -> float:
    peak = equity_curve.cummax()
    dd = (equity_curve - peak) / peak * 100
    return round(dd.min(), 2)


def sharpe(trades: pd.Series, periods_per_year: int = 252) -> float:
    if trades.std() == 0:
        return 0.0
    return round((trades.mean() / trades.std()) * np.sqrt(periods_per_year), 3)


def max_consecutive_losers(trades: pd.Series) -> int:
    count = max_count = 0
    for t in trades:
        if t < 0:
            count += 1
            max_count = max(max_count, count)
        else:
            count = 0
    return max_count


def monte_carlo(trades: pd.Series, simulations: int = 1000, percentile: int = 95) -> dict:
    """Returns DD percentile distribution via random permutations."""
    results = []
    arr = trades.values
    for _ in range(simulations):
        perm = np.random.permutation(arr)
        equity = np.cumsum(perm)
        peak = np.maximum.accumulate(equity)
        dd = (equity - peak) / (peak + 1e-9) * 100
        results.append(dd.min())
    results = np.array(results)
    return {
        "p50": round(np.percentile(results, 50), 2),
        "p95": round(np.percentile(results, percentile), 2),
        "p99": round(np.percentile(results, 99), 2),
    }


def full_report(trades: pd.Series, avg_risk: float = 1.0) -> dict:
    equity = trades.cumsum()
    return {
        "profit_factor": profit_factor(trades),
        "expectancy_r": expectancy_r(trades, avg_risk),
        "win_rate_pct": win_rate(trades),
        "max_dd_pct": max_drawdown(equity),
        "sharpe": sharpe(trades),
        "max_consec_losers": max_consecutive_losers(trades),
        "total_trades": len(trades),
        "monte_carlo": monte_carlo(trades),
    }
