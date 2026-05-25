"""Inspect NR backtest file structure to find entry rows."""
import pandas as pd

NR_FILE = r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\NR Backtest NAS100 M5.xlsx"

df = pd.read_excel(NR_FILE, header=None)
print(f"Shape: {df.shape}")

# Find rows where col[12] == 'NR ULTRA' (entry comment)
entries = df[df[12].astype(str).str.strip() == 'NR ULTRA']
print(f"\nRows with 'NR ULTRA' in col[12]: {len(entries)}")
print("\nFirst 10 entry rows (all columns):")
print(entries.head(10).to_string())

# Also look at surrounding rows to understand format
idx = entries.index[0]
print(f"\nRows {idx-2} to {idx+3}:")
print(df.iloc[max(0,idx-2):idx+4].to_string())
