# ADR-002: Hash chain computation

Status: proposed.

## Context
Each invoice record stores a SHA-256 fingerprint computed over a canonical string of fields, and the fingerprint of the previous record of the same issuer. The exact field set, order and formatting must match the official AEAT specification (fingerprint document v0.1.2, dated 27/08/2024). That document has not been verified yet, see docs/requirements (open question Q1).

## Decision
1. The fingerprint is computed in the backend, in an isolated domain service with no framework dependencies, so it can be unit tested without Spring or a database.
2. The canonical string is built only in that service. No other module concatenates fields.
3. For an initial record (alta) the chained field is the empty string, not null.
4. Output is SHA-256 over the UTF-8 bytes of the canonical string, encoded as 64 uppercase hexadecimal characters.
5. Official test vectors from the AEAT document are the acceptance criterion. Third-party vectors are not used.
6. Until Q1 is closed, the field order and formatting rules are marked as TODO in code and the service refuses to emit records.

## Consequences
- Changing the canonical string later invalidates existing chains, so it must be frozen before S2.
- The verification feature recomputes fingerprints from stored canonical fields, not from stored fingerprints.
- Cancellation records (anulación) use their own canonical string, to be confirmed from the official document.
