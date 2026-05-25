---
type: code-index
strategy: TBR
updated: 2026-05-11
---

# TBR — Versiones del EA

[[TBR]]

## Versión activa

**`TBR_v1.0b.mq5`** — Refactor completo bidireccional (Long + Short)

### Parámetros clave

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `TradeDirection` | ENUM | DIR_BOTH=0, DIR_BUY=1, DIR_SELL=2 |
| `EntryMode` | ENUM | MODE_CONFIRM=0, MODE_BREAKOUT=1 |
| `RangeCandlesCount` | int | Velas M5 para formar el rango |
| `SessionStart_Hour` | int | Hora UTC de inicio de sesión |
| `SessionStart_Min` | int | Minuto de inicio |
| `SessionEnd_Hour` | int | Hora UTC de cierre (EA aplica + ServerOffsetHours internamente) |
| `SessionEnd_Min` | int | Minuto de cierre |
| `ServerOffsetHours` | int | Offset broker (FundingPips = 2) |
| `RR` | double | Risk-Reward ratio |
| `RiskAmountUSD` | double | Riesgo fijo por trade en USD |
| `SL_AtRangeExtreme` | bool | SL en extremo opuesto del rango |
| `UseBreakeven` | bool | Breakeven automático |
| `MagicNumber` | int | ID único de instancia |

### Nota técnica — SessionEnd

```mql5
// El EA calcula el cierre en hora servidor:
int totalMin = (SessionEnd_Hour + ServerOffsetHours) * 60 + SessionEnd_Min;
// Con SessionEnd_Hour=18, ServerOffsetHours=2 → 20:00 server (FundingPips UTC+2)
```

---

## Historial de versiones

| Versión | Cambio |
|---------|--------|
| v1.0 | Inicial — long-only, RiskPct |
| v1.1 | RiskPct → RiskAmountUSD fijo; CloseAfterHours |
| v1.2 | BUG FIX: MODE_CONFIRM post-SessionEnd |
| v1.3 | BUG FIX: lot calculado con rango bruto (riesgo 3.5×) |
| v1.4 | BUG FIX: VPP = $0.20 en lugar de $20 |
| **v1.0b** | **Refactor completo — bidireccional (DIR_BOTH/BUY/SELL), MODE_BREAKOUT/CONFIRM, compatible XAUUSD** |

---

## Sets de producción activos

- `Sets-Produccion/NAS100/TBR_v1.0b_NAS100_P63_LMX.set` — MagicNumber 202501
- `Sets-Produccion/XAUUSD/TBR_v1.0b_XAUUSD_P1.set` — MagicNumber 202502
