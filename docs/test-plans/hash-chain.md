# Test plan: hash chain

Status: ready. Vectors taken from the AEAT document v0.1.2 (27/08/2024) and recomputed with SHA-256 on 2026-11-04. All three match.

## Official vectors

### H-01: first alta record, empty previous fingerprint

Input fields:
- IDEmisorFactura: 89890001K
- NumSerieFactura: 12345678/G33
- FechaExpedicionFactura: 01-01-2024
- TipoFactura: F1
- CuotaTotal: 12.35
- ImporteTotal: 123.45
- Huella: (empty)
- FechaHoraHusoGenRegistro: 2024-01-01T19:20:30+01:00

Canonical string:
```
IDEmisorFactura=89890001K&NumSerieFactura=12345678/G33&FechaExpedicionFactura=01-01-2024&TipoFactura=F1&CuotaTotal=12.35&ImporteTotal=123.45&Huella=&FechaHoraHusoGenRegistro=2024-01-01T19:20:30+01:00
```

Expected fingerprint:
```
3C464DAF61ACB827C65FDA19F352A4E3BDC2C640E9E9FC4CC058073F38F12F60
```

### H-02: alta record chained to H-01

Input fields: as H-01 with NumSerieFactura 12345679/G34, Huella equal to the H-01 result and FechaHoraHusoGenRegistro 2024-01-01T19:20:35+01:00.

Canonical string:
```
IDEmisorFactura=89890001K&NumSerieFactura=12345679/G34&FechaExpedicionFactura=01-01-2024&TipoFactura=F1&CuotaTotal=12.35&ImporteTotal=123.45&Huella=3C464DAF61ACB827C65FDA19F352A4E3BDC2C640E9E9FC4CC058073F38F12F60&FechaHoraHusoGenRegistro=2024-01-01T19:20:35+01:00
```

Expected fingerprint:
```
F7B94CFD8924EDFF273501B01EE5153E4CE8F259766F88CF6ACB8935802A2B97
```

### H-03: cancellation record chained to H-02

Input fields:
- IDEmisorFacturaAnulada: 89890001K
- NumSerieFacturaAnulada: 12345679/G34
- FechaExpedicionFacturaAnulada: 01-01-2024
- Huella: the H-02 result
- FechaHoraHusoGenRegistro: 2024-01-01T19:20:40+01:00

Canonical string:
```
IDEmisorFacturaAnulada=89890001K&NumSerieFacturaAnulada=12345679/G34&FechaExpedicionFacturaAnulada=01-01-2024&Huella=F7B94CFD8924EDFF273501B01EE5153E4CE8F259766F88CF6ACB8935802A2B97&FechaHoraHusoGenRegistro=2024-01-01T19:20:40+01:00
```

Expected fingerprint:
```
177547C0D57AC74748561D054A9CEC14B4C4EA23D1BEFD6F2E69E3A388F90C68
```

## Cases

| ID | Case | Expected |
|---|---|---|
| H-01 | First alta record, empty previous fingerprint | Official vector above |
| H-02 | Alta record chained to H-01 | Official vector above |
| H-03 | Cancellation record chained to H-02 | Official vector above |
| H-04 | Amount 123.1 stored as a number | Serialized as 123.10 in the canonical string |
| H-05 | Generation timestamp with offset | ISO 8601 with offset, as in the official examples |
| H-06 | Modify one stored field of record N | Verification fails starting at N |
| H-07 | Delete a record from the middle of the chain | Verification detects the gap |
| H-08 | Leading and trailing spaces in a field | Trimmed before concatenation |
| H-09 | Empty or absent field | Written as the field name followed by an equals sign, nothing after it |
| H-10 | Output format | 64 characters, hexadecimal, uppercase |
