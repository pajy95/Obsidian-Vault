import pandas as pd
import warnings
warnings.filterwarnings('ignore')

path = r'C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\BreakoutNY\Backtests\nas 100 bk ny .2026.xlsx'
df_raw = pd.read_excel(path, sheet_name=0, header=None)
print(f'Total rows: {len(df_raw)}')
for i, row in df_raw.iterrows():
    if i < 60:
        continue
    vals = [str(v)[:25] for v in row.values if str(v) != 'nan']
    if vals:
        print(f'row {i:3d}: {vals}')
