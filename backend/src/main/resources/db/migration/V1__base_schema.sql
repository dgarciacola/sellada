-- V1: esquema base. Empresas y usuarios.

CREATE TABLE company (
    id          uuid         NOT NULL DEFAULT gen_random_uuid(),
    tax_id      varchar(20)  NOT NULL,
    legal_name  varchar(200) NOT NULL,
    address     text         NOT NULL,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_company PRIMARY KEY (id),
    CONSTRAINT uq_company_tax_id UNIQUE (tax_id)
);

CREATE TABLE app_user (
    id             uuid         NOT NULL DEFAULT gen_random_uuid(),
    company_id     uuid         NOT NULL,
    email          varchar(254) NOT NULL,
    password_hash  varchar(255) NOT NULL,
    role           varchar(20)  NOT NULL,
    enabled        boolean      NOT NULL DEFAULT true,
    created_at     timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_app_user PRIMARY KEY (id),
    CONSTRAINT fk_app_user_company FOREIGN KEY (company_id) REFERENCES company (id),
    CONSTRAINT uq_app_user_id_company UNIQUE (id, company_id),
    CONSTRAINT ck_app_user_role CHECK (role IN ('ADMIN', 'ISSUER', 'AUDITOR'))
);

CREATE UNIQUE INDEX uq_app_user_email ON app_user (lower(email));
CREATE INDEX ix_app_user_company ON app_user (company_id);

CREATE TABLE customer (
    id          uuid         NOT NULL DEFAULT gen_random_uuid(),
    company_id  uuid         NOT NULL,
    tax_id      varchar(20)  NOT NULL,
    legal_name  varchar(200) NOT NULL,
    address     text         NOT NULL,
    active      boolean      NOT NULL DEFAULT true,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT pk_customer PRIMARY KEY (id),
    CONSTRAINT fk_customer_company FOREIGN KEY (company_id) REFERENCES company (id),
    CONSTRAINT uq_customer_id_company UNIQUE (id, company_id),
    CONSTRAINT uq_customer_company_tax_id UNIQUE (company_id, tax_id)
);

CREATE TABLE invoice_series (
    id           uuid        NOT NULL DEFAULT gen_random_uuid(),
    company_id   uuid        NOT NULL,
    code         varchar(10) NOT NULL,
    last_number  bigint      NOT NULL DEFAULT 0,
    created_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_invoice_series PRIMARY KEY (id),
    CONSTRAINT fk_invoice_series_company FOREIGN KEY (company_id) REFERENCES company (id),
    CONSTRAINT uq_invoice_series_id_company UNIQUE (id, company_id),
    CONSTRAINT uq_invoice_series_company_code UNIQUE (company_id, code),
    CONSTRAINT ck_invoice_series_last_number CHECK (last_number >= 0)
);

CREATE TABLE invoice (
    id                    uuid          NOT NULL DEFAULT gen_random_uuid(),
    company_id            uuid          NOT NULL,
    series_id             uuid          NOT NULL,
    customer_id           uuid          NOT NULL,
    status                varchar(10)   NOT NULL DEFAULT 'DRAFT',
    number                bigint,
    invoice_number        varchar(60),
    issue_date            date          NOT NULL,
    invoice_type          varchar(2)    NOT NULL,
    customer_tax_id       varchar(20),
    customer_legal_name   varchar(200),
    customer_address      text,
    rectified_invoice_id  uuid,
    rectification_reason  varchar(500),
    total_base            numeric(14,2) NOT NULL DEFAULT 0,
    total_vat             numeric(14,2) NOT NULL DEFAULT 0,
    total_amount          numeric(14,2) NOT NULL DEFAULT 0,
    created_at            timestamptz   NOT NULL DEFAULT now(),
    issued_at             timestamptz,
    CONSTRAINT pk_invoice PRIMARY KEY (id),
    CONSTRAINT uq_invoice_id_company UNIQUE (id, company_id),
    CONSTRAINT fk_invoice_company FOREIGN KEY (company_id) REFERENCES company (id),
    CONSTRAINT fk_invoice_series FOREIGN KEY (series_id, company_id)
        REFERENCES invoice_series (id, company_id),
    CONSTRAINT fk_invoice_customer FOREIGN KEY (customer_id, company_id)
        REFERENCES customer (id, company_id),
    CONSTRAINT fk_invoice_rectified FOREIGN KEY (rectified_invoice_id, company_id)
        REFERENCES invoice (id, company_id),
    CONSTRAINT uq_invoice_series_number UNIQUE (series_id, number),
    CONSTRAINT uq_invoice_company_invoice_number UNIQUE (company_id, invoice_number),
    CONSTRAINT ck_invoice_status CHECK (status IN ('DRAFT', 'ISSUED')),
    CONSTRAINT ck_invoice_lifecycle CHECK (
        (status = 'DRAFT'
            AND number IS NULL AND invoice_number IS NULL AND issued_at IS NULL)
        OR
        (status = 'ISSUED'
            AND number IS NOT NULL AND invoice_number IS NOT NULL AND issued_at IS NOT NULL
            AND customer_tax_id IS NOT NULL AND customer_legal_name IS NOT NULL
            AND customer_address IS NOT NULL)
    ),
    CONSTRAINT ck_invoice_totals CHECK (total_amount = total_base + total_vat),
    CONSTRAINT ck_invoice_rectification CHECK
        ((rectified_invoice_id IS NULL) = (rectification_reason IS NULL)),
    CONSTRAINT ck_invoice_not_self_rectified CHECK (rectified_invoice_id <> id)
);

CREATE INDEX ix_invoice_company_issue_date ON invoice (company_id, issue_date);
CREATE INDEX ix_invoice_customer ON invoice (customer_id);

CREATE TABLE invoice_line (
    id           uuid          NOT NULL DEFAULT gen_random_uuid(),
    invoice_id   uuid          NOT NULL,
    line_number  integer       NOT NULL,
    description  varchar(500)  NOT NULL,
    quantity     numeric(14,3) NOT NULL,
    unit_price   numeric(14,4) NOT NULL,
    vat_rate     numeric(4,2)  NOT NULL,
    base_amount  numeric(14,2) NOT NULL,
    vat_amount   numeric(14,2) NOT NULL,
    CONSTRAINT pk_invoice_line PRIMARY KEY (id),
    CONSTRAINT fk_invoice_line_invoice FOREIGN KEY (invoice_id)
        REFERENCES invoice (id) ON DELETE CASCADE,
    CONSTRAINT uq_invoice_line_number UNIQUE (invoice_id, line_number),
    CONSTRAINT ck_invoice_line_number CHECK (line_number > 0),
    CONSTRAINT ck_invoice_line_quantity CHECK (quantity <> 0),
    CONSTRAINT ck_invoice_line_unit_price CHECK (unit_price >= 0),
    CONSTRAINT ck_invoice_line_vat_rate CHECK (vat_rate IN (21, 10, 4, 0))
);