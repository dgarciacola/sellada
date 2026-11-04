package com.sellada.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/*
 * Test de arranque del contexto completo de Spring.
 *
 * @Testcontainers: JUnit gestiona el ciclo de vida de los contenedores de esta clase.
 * @SpringBootTest: arranca la aplicación completa, igual que en ./mvnw spring-boot:run.
 * properties: define POSTGRES_PASSWORD para que el placeholder de application.yaml
 *             se resuelva aunque no exportes la contraseña real en esta terminal.
 */
@Testcontainers
@SpringBootTest(properties = "POSTGRES_PASSWORD=test-only")
class BackendApplicationTests {

	/*
	 * static: el contenedor se arranca una sola vez para toda la clase.
	 * @ServiceConnection: Spring Boot usa este contenedor como base de datos,
	 *                     sustituyendo la URL y las credenciales de application.yaml.
	 */
	@Container
	@ServiceConnection
	static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16");

	@Test
	void contextLoads() {
	}

}