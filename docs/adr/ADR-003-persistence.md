# ADR-003: Persistence and data model

Status: proposed.

## Context
Invoice numbering must be gap-free under concurrency (RF-02, RNF-03). Records must be immutable once issued (RNF-01). Money must be exact.

## Decision
1. PostgreSQL 16, schema managed by Flyway versioned migrations. No schema changes outside migrations.
2. Core tables: issuers (tenant), series, customers, invoices, invoice_records (hash chain), audit_log.
3. Money stored as NUMERIC(12,2). Never floating point.
4. Timestamps stored as TIMESTAMPTZ in UTC; the generation timestamp keeps its original offset in a separate text column, because the fingerprint uses the offset.
5. Numbering: the series row is locked with SELECT ... FOR UPDATE inside the issuing transaction (RN-03). The number is assigned only on commit of a valid invoice, so failed issues consume no number (RF-02 CA2).
6. Immutability enforced in the database: BEFORE UPDATE and BEFORE DELETE triggers on invoice_records and audit_log raise an exception. Tests verify both (RNF-01).
7. Tenant isolation: every row of tenant-scoped tables carries issuer_id; repository queries always filter by it.

## Consequences
- Triggers do not stop a database superuser. The threat model in the README states this, and the fase 2 backlog covers external anchoring.
- Pessimistic locking serialises issuing per series. Acceptable at portfolio scale; measured in k6 (RNF-02).
