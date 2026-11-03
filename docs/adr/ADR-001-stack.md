# ADR-001: Stack tecnológico de Sellada

Estado: propuesto.

## Decisión
- Backend: Java 21 LTS, Spring Boot 3.x (Web, Data JPA, Security, Validation, Actuator).
- Base de datos: PostgreSQL 16 con migraciones Flyway.
- Frontend: Angular (versión estable vigente al iniciar S1, fijada en el README), Angular Material, formularios reactivos.
- API: OpenAPI 3 con springdoc; cliente Angular generado desde el contrato.
- Documentos: OpenPDF (LGPL) para PDF; ZXing para QR.
- Pruebas: JUnit 5, AssertJ, Testcontainers (PostgreSQL real), Spring Security Test, ArchUnit; Vitest o Jest; Playwright; k6.
- Infraestructura: Docker Compose (api, web, db); GitHub Actions.

## Alternativas descartadas
- H2 en pruebas: no reproduce bloqueos ni triggers de PostgreSQL.
- iText: licencia AGPL, no compatible con un repositorio público sin revisión.
- NgRx: exceso de ceremonia para v1.

## Consecuencias
- Docker necesario en local para pruebas de integración.
- La versión de Angular se fija al inicio de S1.
- Las licencias de dependencias se documentan en el README.
