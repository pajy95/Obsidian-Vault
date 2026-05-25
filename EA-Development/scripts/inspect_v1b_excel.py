"""Inspeccionar estructura del Excel v1.0b para adaptar el parser"""
import pandas as pd
df = pd.read_excel(
    r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests\nas100 TBR v1.0b.xlsx",
    header=None
)
print(f"Filas: {len(df)}")
# Buscar las primeras filas que contengan una fecha 2022/2023
import re
found = 0
for i, row in df.iterrows():
    t = str(row[0]).strip()
    if re.match(r'^\d{4}\.\d{2}\.\d{2}', t):
        vals = [str(v)[:18] for v in row]
        print(f"Row {i:4d}: {' | '.join(vals)}")
        found += 1
        if found >= 30:
            break
