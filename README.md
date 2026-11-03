# Sellada

Facturación verificable para autónomos y pymes: registros con cadena de huellas SHA-256, numeración correlativa, anulación sin borrado y verificación de integridad.

> **Aviso.** Sellada es un proyecto educativo de portafolio. No está certificado por la Agencia Tributaria, no envía datos a la AEAT y **no debe usarse con facturas reales**. Las reglas se toman de la documentación técnica pública de la AEAT y se marcan con su versión en los ADR.

## Estado

En desarrollo. Plan de 10 semanas en sprints de 2 semanas.

| Fase | Estado |
|---|---|
| Descubrimiento | Hecho |
| Requisitos ([docs/requirements](docs/requirements)) | En revisión |
| Diseño ([docs/adr](docs/adr)) | En curso |
| Implementación | Pendiente |

## Stack previsto

- Backend: Java 21, Spring Boot 3, PostgreSQL 16, Flyway
- Frontend: Angular, Angular Material
- Infraestructura: Docker Compose, GitHub Actions

Decisiones detalladas en [ADR-001](docs/adr/ADR-001-stack.md).

## Estructura

```
backend/        API y dominio (Spring Boot)
frontend/       Interfaz web (Angular)
infra/          Docker Compose y scripts
docs/
  requirements/ Hoja de requisitos
  adr/          Decisiones de arquitectura
  design/       Diseño y prototipos
  test-plans/   Casos de prueba de la cadena de huellas
```

## Licencia

MIT. Ver [LICENSE](LICENSE).
