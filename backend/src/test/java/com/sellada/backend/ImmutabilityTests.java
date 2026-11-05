package com.sellada.backend;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@Testcontainers
@SpringBootTest(properties = "POSTGRES_PASSWORD=test-only")
class ImmutabilityTests {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16");

    @Autowired
    JdbcTemplate jdbc;

    UUID company, series, customer, issued, draft;

    @BeforeEach
    void createFreshData() {
        company = UUID.randomUUID();
        series = UUID.randomUUID();
        customer = UUID.randomUUID();
        issued = UUID.randomUUID();
        draft = UUID.randomUUID();

        jdbc.update("INSERT INTO company (id, tax_id, legal_name, address) VALUES (?, ?, 'Test SL', 'Calle 1')",
                company, "B" + company.toString().substring(0, 8));
        jdbc.update("INSERT INTO customer (id, company_id, tax_id, legal_name, address) VALUES (?, ?, 'C1', 'Cliente', 'Dir')",
                customer, company);
        jdbc.update("INSERT INTO invoice_series (id, company_id, code) VALUES (?, ?, 'A2026')", series, company);

        insertDraft(issued);
        jdbc.update("INSERT INTO invoice_line (id, invoice_id, line_number, description, quantity, unit_price, vat_rate, base_amount, vat_amount) "
                + "VALUES (?, ?, 1, 'Concepto', 2, 50, 21, 100, 21)", UUID.randomUUID(), issued);
        jdbc.update("UPDATE invoice SET status='ISSUED', number=1, invoice_number='A2026-000001', issued_at=now(), "
                + "customer_tax_id='C1', customer_legal_name='Cliente', customer_address='Dir' WHERE id=?", issued);

        insertDraft(draft);
    }

    private void insertDraft(UUID id) {
        jdbc.update("INSERT INTO invoice (id, company_id, series_id, customer_id, issue_date, invoice_type) "
                + "VALUES (?, ?, ?, ?, '2026-11-05', 'F1')", id, company, series, customer);
    }

    private void insertRecord(int sequence, String previousHash, String hash) {
        jdbc.update("INSERT INTO invoice_record (company_id, invoice_id, sequence, record_type, canonical_string, hash, previous_hash, generated_at) "
                + "VALUES (?, ?, ?, 'ALTA', 'x', ?, ?, now())", company, issued, sequence, hash, previousHash);
    }

    @Test
    void draftInvoiceCanBeEditedAndDeleted() {
        assertThatCode(() -> {
            jdbc.update("UPDATE invoice SET issue_date = '2026-11-06' WHERE id = ?", draft);
            jdbc.update("DELETE FROM invoice WHERE id = ?", draft);
        }).doesNotThrowAnyException();
    }

    @Test
    void issuedInvoiceCannotBeUpdatedOrDeleted() {
        assertThatThrownBy(() -> jdbc.update("UPDATE invoice SET issue_date = '2026-12-01' WHERE id = ?", issued))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("DELETE FROM invoice WHERE id = ?", issued))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("UPDATE invoice SET status = 'DRAFT' WHERE id = ?", issued))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void linesOfIssuedInvoiceCannotBeChanged() {
        assertThatThrownBy(() -> jdbc.update("UPDATE invoice_line SET description = 'x' WHERE invoice_id = ?", issued))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("DELETE FROM invoice_line WHERE invoice_id = ?", issued))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("INSERT INTO invoice_line (id, invoice_id, line_number, description, quantity, unit_price, vat_rate, base_amount, vat_amount) "
                + "VALUES (?, ?, 2, 'Otra', 1, 10, 21, 10, 2.10)", UUID.randomUUID(), issued))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void lineCannotBeMovedFromDraftToIssuedInvoice() {
        UUID line = UUID.randomUUID();
        jdbc.update("INSERT INTO invoice_line (id, invoice_id, line_number, description, quantity, unit_price, vat_rate, base_amount, vat_amount) "
                + "VALUES (?, ?, 1, 'Concepto', 1, 10, 21, 10, 2.10)", line, draft);

        assertThatThrownBy(() -> jdbc.update("UPDATE invoice_line SET invoice_id = ?, line_number = 9 WHERE id = ?", issued, line))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void deletingDraftCascadesToItsLines() {
        jdbc.update("INSERT INTO invoice_line (id, invoice_id, line_number, description, quantity, unit_price, vat_rate, base_amount, vat_amount) "
                + "VALUES (?, ?, 1, 'Concepto', 1, 10, 21, 10, 2.10)", UUID.randomUUID(), draft);

        jdbc.update("DELETE FROM invoice WHERE id = ?", draft);

        Integer remaining = jdbc.queryForObject("SELECT count(*) FROM invoice_line WHERE invoice_id = ?", Integer.class, draft);
        assertThat(remaining).isZero();
    }

    @Test
    void invoiceRecordIsAppendOnly() {
        insertRecord(1, "", "A".repeat(64));

        assertThatThrownBy(() -> jdbc.update("UPDATE invoice_record SET canonical_string = 'y' WHERE company_id = ?", company))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("DELETE FROM invoice_record WHERE company_id = ?", company))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.execute("TRUNCATE invoice_record"))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void auditLogIsAppendOnly() {
        jdbc.update("INSERT INTO audit_log (company_id, action, result) VALUES (?, 'TEST', 'SUCCESS')", company);

        assertThatThrownBy(() -> jdbc.update("UPDATE audit_log SET action = 'x' WHERE company_id = ?", company))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("DELETE FROM audit_log WHERE company_id = ?", company))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.execute("TRUNCATE audit_log"))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void chainRejectsForkAndDuplicates() {
        insertRecord(1, "", "A".repeat(64));

        // Bifurcación: otro registro con el mismo previous_hash.
        assertThatThrownBy(() -> insertRecord(2, "", "B".repeat(64)))
                .isInstanceOf(DataIntegrityViolationException.class);
        // Segunda ALTA de la misma factura.
        assertThatThrownBy(() -> insertRecord(2, "A".repeat(64), "C".repeat(64)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}