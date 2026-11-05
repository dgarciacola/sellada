-- V2: registro encadenado, auditoría e inmutabilidad.

CREATE TABLE invoice_record (
    id                uuid         NOT NULL DEFAULT gen_random_uuid(),
    company_id        uuid         NOT NULL,
    invoice_id        uuid         NOT NULL,
    sequence          bigint       NOT NULL,
    record_type       varchar(10)  NOT NULL,
    canonical_string  text         NOT NULL,
    hash              varchar(64)  NOT NULL,
    previous_hash     varchar(64)  NOT NULL,
    generated_at      timestamptz  NOT NULL,
    CONSTRAINT pk_invoice_record PRIMARY KEY (id),
    CONSTRAINT fk_invoice_record_company FOREIGN KEY (company_id) REFERENCES company (id),
    CONSTRAINT fk_invoice_record_invoice FOREIGN KEY (invoice_id, company_id)
        REFERENCES invoice (id, company_id),
    CONSTRAINT uq_invoice_record_sequence UNIQUE (company_id, sequence),
    CONSTRAINT uq_invoice_record_previous_hash UNIQUE (company_id, previous_hash),
    CONSTRAINT uq_invoice_record_hash UNIQUE (company_id, hash),
    CONSTRAINT ck_invoice_record_type CHECK (record_type IN ('ALTA', 'ANULACION')),
    CONSTRAINT ck_invoice_record_sequence CHECK (sequence >= 1),
    CONSTRAINT ck_invoice_record_hash CHECK (hash ~ '^[0-9A-F]{64}$'),
    CONSTRAINT ck_invoice_record_previous_hash
        CHECK (previous_hash = '' OR previous_hash ~ '^[0-9A-F]{64}$'),
    CONSTRAINT ck_invoice_record_first CHECK ((sequence = 1) = (previous_hash = ''))
);

CREATE UNIQUE INDEX uq_invoice_record_one_alta
    ON invoice_record (invoice_id) WHERE record_type = 'ALTA';
CREATE UNIQUE INDEX uq_invoice_record_one_cancellation
    ON invoice_record (invoice_id) WHERE record_type = 'ANULACION';

CREATE TABLE audit_log (
    id           bigint       GENERATED ALWAYS AS IDENTITY,
    company_id   uuid         NOT NULL,
    user_id      uuid,
    action       varchar(50)  NOT NULL,
    entity_type  varchar(50),
    entity_id    uuid,
    result       varchar(10)  NOT NULL,
    detail       jsonb,
    created_at   timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_audit_log PRIMARY KEY (id),
    CONSTRAINT fk_audit_log_company FOREIGN KEY (company_id) REFERENCES company (id),
    CONSTRAINT fk_audit_log_user FOREIGN KEY (user_id, company_id)
        REFERENCES app_user (id, company_id),
    CONSTRAINT ck_audit_log_result CHECK (result IN ('SUCCESS', 'FAILURE'))
);

CREATE INDEX ix_audit_log_company_created ON audit_log (company_id, created_at);

CREATE FUNCTION forbid_modification() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Table % is append-only: % is not allowed', TG_TABLE_NAME, TG_OP
        USING ERRCODE = 'integrity_constraint_violation';
END;
$$;

CREATE TRIGGER trg_invoice_record_immutable
    BEFORE UPDATE OR DELETE ON invoice_record
    FOR EACH ROW EXECUTE FUNCTION forbid_modification();

CREATE TRIGGER trg_invoice_record_no_truncate
    BEFORE TRUNCATE ON invoice_record
    FOR EACH STATEMENT EXECUTE FUNCTION forbid_modification();

CREATE TRIGGER trg_audit_log_immutable
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION forbid_modification();

CREATE TRIGGER trg_audit_log_no_truncate
    BEFORE TRUNCATE ON audit_log
    FOR EACH STATEMENT EXECUTE FUNCTION forbid_modification();


-- ============================================================
-- Bloque 3: inmutabilidad de facturas emitidas y sus líneas
-- ============================================================
CREATE FUNCTION forbid_issued_invoice_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status = 'ISSUED' THEN
        RAISE EXCEPTION 'Invoice % is issued: % is not allowed', OLD.id, TG_OP
            USING ERRCODE = 'integrity_constraint_violation';
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoice_immutable
    BEFORE UPDATE OR DELETE ON invoice
    FOR EACH ROW EXECUTE FUNCTION forbid_issued_invoice_change();

CREATE FUNCTION forbid_issued_invoice_line_change() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_status varchar(10);
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        SELECT status INTO v_status FROM invoice WHERE id = OLD.invoice_id FOR SHARE;
        IF v_status = 'ISSUED' THEN
            RAISE EXCEPTION 'Invoice % is issued: its lines cannot be changed', OLD.invoice_id
                USING ERRCODE = 'integrity_constraint_violation';
        END IF;
    END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        SELECT status INTO v_status FROM invoice WHERE id = NEW.invoice_id FOR SHARE;
        IF v_status = 'ISSUED' THEN
            RAISE EXCEPTION 'Invoice % is issued: its lines cannot be changed', NEW.invoice_id
                USING ERRCODE = 'integrity_constraint_violation';
        END IF;
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoice_line_immutable
    BEFORE INSERT OR UPDATE OR DELETE ON invoice_line
    FOR EACH ROW EXECUTE FUNCTION forbid_issued_invoice_line_change();
