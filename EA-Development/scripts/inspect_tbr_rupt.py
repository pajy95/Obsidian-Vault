"""
Inspecciona la estructura raw del TBR BREAKOUT backtest.
Buscamos: ¿col[0] es tiempo de orden o tiempo de fill?
¿Hay secciones de Orders vs Deals?
"""
import pandas as pd
from pathlib import Path

BASE = Path(r"C:\Users\JOSSE\Documents\Obsidian Vault\EA-Development\01-Strategies\TBR\Backtests")
TBR_RUPT = BASE / "tbR Backtest NAS100 M5 rupt.xlsx"
NR_RUPT  = BASE / "NR Backtest NAS100 M5 rupt.xlsx"

df_tbr = pd.read_excel(TBR_RUPT, header=None)
df_nr  = pd.read_excel(NR_RUPT,  header=None)

# --- Buscar secciones del reporte ---
for label, df in [("TBR", df_tbr), ("NR", df_nr)]:
    print(f"\n{'='*60}\n{label} — secciones del reporte")
    section_rows = df[df[0].astype(str).str.lower().str.contains(
        'orden|deal|operacion|trad|posic|order|result|config|symbol|expert',
        na=False)]
    print(section_rows[[0]].head(20).to_string())

# --- Mostrar filas alrededor de un día de mismatch (2022-01-07) ---
print("\n\n=== TBR RUPT — filas para 2022-01-07 ===")
mask_07 = df_tbr[0].astype(str).str.contains('2022.01.07', na=False)
rows_07 = df_tbr[mask_07]
print(rows_07.to_string())

print("\n\n=== NR RUPT — filas para 2022-01-07 ===")
mask_07_nr = df_nr[0].astype(str).str.contains('2022.01.07', na=False)
rows_07_nr = df_nr[mask_07_nr]
print(rows_07_nr.to_string())

# --- Analizar col[9] vs col[0] en entradas TBR ---
tbr_entries = df_tbr[df_tbr[12].astype(str).str.contains('TBR', na=False)].copy()
tbr_entries['t0'] = pd.to_datetime(tbr_entries[0], errors='coerce')
tbr_entries['t9'] = pd.to_datetime(tbr_entries[9], errors='coerce')
tbr_entries['diff_sec'] = (tbr_entries['t9'] - tbr_entries['t0']).dt.total_seconds()

print("\n\n=== TBR: diferencia entre col[0] y col[9] ===")
print(f"Filas con col[0] != col[9]: {(tbr_entries['diff_sec'] != 0).sum()} / {len(tbr_entries)}")
print(f"Distribución diff (seg):")
print(tbr_entries['diff_sec'].value_counts().sort_index().head(20))

# Mostrar primeras 10 con diff != 0
diff_rows = tbr_entries[tbr_entries['diff_sec'] != 0].head(10)
if len(diff_rows) > 0:
    print("\nFilas con diff != 0:")
    print(diff_rows[[0, 3, 6, 9, 12, 'diff_sec']].to_string())
