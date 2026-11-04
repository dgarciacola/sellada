# ADR-002: Hash chain computation

Status: proposed.

## Context
Each invoice record stores a SHA-256 fingerprint computed over a canonical string of fields, and the fingerprint of the previous record of the same issuer. The field set, order and formatting follow the official AEAT specification (fingerprint document v0.1.2, dated 27/08/2024).

That document was verified on 2026-11-04 against the PDF provided by the author. Open question Q1 is closed for the fingerprint. The rules are written down in `docs/design/hash-specification.md`.

## Decision
1. The fingerprint is computed in the backend, in an isolated domain service with no framework dependencies, so it can be unit tested without Spring or a database.
2. The canonical string is built only in that service. No other module concatenates fields.
3. For an initial record (alta) the chained field is the empty string, not null.
4. Output is SHA-256 over the UTF-8 bytes of the canonical string, encoded as 64 uppercase hexadecimal characters.
5. Field order and formatting are those of `docs/design/hash-specification.md`: 8 fields for alta records and 5 fields for cancellation records (anulación).
6. Amounts are always serialized with two decimals. The AEAT accepts one or two decimals, Sellada uses a single canonical form.
7. Official test vectors from the AEAT document are the acceptance criterion (cases H-01 to H-03 in `docs/test-plans/hash-chain.md`). Third-party vectors are not used.
8. There is one chain per company (issuer), not one per series.

## Consequences
- Changing the canonical string later invalidates existing chains, so it must stay frozen from S2.
- The verification feature recomputes fingerprints from stored canonical fields, not from stored fingerprints.
- Cancellation records use their own canonical string, with the fields confirmed in the official document.
- Date and amount formats must still be checked against the AEAT XML schemas before S2.
