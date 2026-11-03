# ADR-004: Authentication and authorization

Status: proposed.

## Context
Users belong to one issuer (tenant) and have one role among issuer admin, issuer user and auditor (RF-12, RF-13, RF-14).

## Decision
1. Email and password login. Passwords hashed with Argon2id (preferred) or bcrypt, never stored or logged in clear (RNF-04).
2. Stateless JWT access tokens, short-lived (15 minutes), signed with a key from environment configuration. Refresh tokens are out of scope for v1.
3. JWT claims: user id, issuer id, role. Authorization uses Spring Security method rules per role (RNF-05).
4. Tenant check: the issuer id from the token is compared with the issuer id of every resource before use. Mismatch returns 404, not 403, so resource existence is not leaked.
5. Auditor role is read-only at the API level and cannot call issue, cancel or rectify endpoints (RF-14).
6. Login attempts are rate limited per email address (basic brute-force protection).

## Consequences
- No session storage, so no server-side logout in v1. Tokens expire on their own.
- Signing key rotation is manual in v1.
