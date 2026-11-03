# ADR-005: Testing strategy

Status: proposed.

## Context
The project's main claims are integrity and concurrency. Those cannot be proven with mocks or with an in-memory database.

## Decision
1. Unit tests for domain logic: amounts, VAT rules (RN-01, RN-02), state transitions (RN-04), and the hash canonical string (ADR-002). No Spring context.
2. Integration tests with Testcontainers running PostgreSQL 16. Required for numbering under concurrency (50 threads, RNF-03), for triggers (RNF-01) and for the chain verification (RF-06).
3. Official AEAT test vectors (docs/test-plans/hash-chain.md) are mandatory and block merging when they fail.
4. Security tests with Spring Security Test for every endpoint and role (RNF-05). Tenant isolation tested with two issuers.
5. API contract tests from the OpenAPI document.
6. E2E with Playwright for the main flows: issue, cancel, rectify, download PDF, verify chain. Accessibility checked with axe-core (RNF-08).
7. Architecture rules with ArchUnit: the domain package must not depend on web or persistence packages.
8. Coverage: JaCoCo, at least 85 % on the domain package (RNF-07). Coverage on other packages is reported, not enforced.
9. Load tests with k6, nightly, not blocking pull requests (RNF-02).

## Consequences
- Integration tests need Docker in CI. GitHub Actions runners provide it.
- The official vectors must be added before S2 closes. Until then the hash service refuses to emit records (ADR-002).
