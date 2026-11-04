# Hash specification (AEAT v0.1.2)

Source: AEAT, "Detalle de las especificaciones técnicas para generación de la huella o hash de los registros de facturación", version 0.1.2, dated 27/08/2024. It is published in the technical information section of the AEAT page on SIF and VERI*FACTU. The PDF belongs to the AEAT and is not stored in this repository.

Verified on 2026-11-04 against the PDF provided by the author. The three official vectors were recomputed with SHA-256 and match (see `docs/test-plans/hash-chain.md`).

Sellada is an educational project. It is not certified and does not send records to the AEAT.

## Algorithm and output

- Algorithm: SHA-256. At the date of the document it is the only permitted algorithm.
- Input: the canonical string encoded as UTF-8 bytes.
- Output: hexadecimal, uppercase, 64 characters.
- The result is stored in the `Huella` field of the record itself, also for the first record of the chain.

## Canonical string

1. Take the fields listed below, in that exact order.
2. Write each one as `FieldName=value`. Field names are the constants used in the AEAT XML record design.
3. Join all pairs with `&`. No separator at the start or the end.
4. Values carry the same information as the XML field, with spaces removed at the start and at the end.
5. A field that is absent or empty is written as `FieldName=` with nothing after the equals sign.
6. Numeric fields: the AEAT treats one or two decimals as equivalent, so `123.1` and `123.10` are both valid.

### Registro de alta (8 fields)

| # | Field | XML location |
|---|---|---|
| 1 | IDEmisorFactura | RegistroAlta/IDFactura/IDEmisorFactura |
| 2 | NumSerieFactura | RegistroAlta/IDFactura/NumSerieFactura |
| 3 | FechaExpedicionFactura | RegistroAlta/IDFactura/FechaExpedicionFactura |
| 4 | TipoFactura | RegistroAlta/TipoFactura |
| 5 | CuotaTotal | RegistroAlta/CuotaTotal |
| 6 | ImporteTotal | RegistroAlta/ImporteTotal |
| 7 | Huella | RegistroAlta/Encadenamiento/RegistroAnterior/Huella |
| 8 | FechaHoraHusoGenRegistro | RegistroAlta/FechaHoraHusoGenRegistro |

Field 7 is the fingerprint of the previous record. For the first record it is empty (`Huella=`).

### Registro de anulación (5 fields)

| # | Field | XML location |
|---|---|---|
| 1 | IDEmisorFacturaAnulada | RegistroAnulacion/IDFactura/IDEmisorFacturaAnulada |
| 2 | NumSerieFacturaAnulada | RegistroAnulacion/IDFactura/NumSerieFacturaAnulada |
| 3 | FechaExpedicionFacturaAnulada | RegistroAnulacion/IDFactura/FechaExpedicionFacturaAnulada |
| 4 | Huella | RegistroAnulacion/Encadenamiento/RegistroAnterior/Huella |
| 5 | FechaHoraHusoGenRegistro | RegistroAnulacion/FechaHoraHusoGenRegistro |

### Registro de evento (9 fields)

Out of scope for Sellada v1. The document defines it with the fields NIF, ID, IdSistemaInformatico, Version, NumeroInstalacion, NIF (ObligadoEmision), TipoEvento, HuellaEvento and FechaHoraHusoGenEvento.

## Formats seen in the official examples

| Field | Example |
|---|---|
| FechaExpedicionFactura | `01-01-2024` (day-month-year) |
| FechaHoraHusoGenRegistro | `2024-01-01T19:20:30+01:00` (ISO 8601 with offset) |
| CuotaTotal, ImporteTotal | `12.35`, `123.45` (dot as decimal separator, no thousands separator) |
| NumSerieFactura | `12345678/G33` |
| TipoFactura | `F1` |

## Sellada decisions (not part of the AEAT document)

- Amounts are always serialized with exactly two decimals, so there is one canonical form.
- The generation timestamp uses ISO 8601 with offset and seconds precision, as in the examples.
- There is one chain per company (issuer). The AEAT document refers to the first record "of that SIF".
- The chained fingerprint of the first record is the empty string, never null.
- The canonical string is stored with each record, and verification recomputes from stored data.

## Still to confirm

- Date and amount formats against the XML schemas (section "Esquemas" of the AEAT technical page). The examples show the formats, the prose of this document does not define them.
- How a rectificativa is represented. This document defines hash inputs only for alta, anulación and evento records. The record designs (section "Diseños de registro") must be checked.
- Electronic signature and QR specifications, which are separate documents (needed for RF-08).
