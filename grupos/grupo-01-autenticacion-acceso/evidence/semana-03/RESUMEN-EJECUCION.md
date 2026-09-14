# Evidencia de Ejecucion - Grupo 01 (Semana 03)

- **Coleccion:** Grupo 01 - Autenticacion y Acceso (Semana 03)
- **Fecha de ejecucion:** 29/8/2026, 15:48:29
- **Entorno:** E_GRUPO_01_AUTENTICACION.json (aiquaa-sandbox-api)
- **Requests ejecutados (API):** 18
- **Assertions:** 31 (✅ 31 / ❌ 0)
- **Resultado global:** ✅ PASS

## Cobertura por escenario

| # | Escenario | Status esperado | Validacion realizada |
| :--- | :--- | :---: | :--- |
| 1 | SQL - Validar usuario activo (precondicion) | 200 | SELECT usuarios (preparacion BD) |
| 2 | SQL - Sesiones previas del usuario (historial) | 200 | SELECT sesiones (validacion BD) |
| 3 | 01 - Login exitoso (Happy Path) | 200 | POST /api/v1/auth/login + BD login insertado |
| 4 | 02 - Logout exitoso (Happy Path) | 200 | POST /api/v1/auth/logout + BD logout insertado |
| 5 | 03a - Login correo no registrado | 400 | VALIDATION_ERROR + JSON schema |
| 6 | 03b - Login usuario inactivo | 400 | VALIDATION_ERROR + JSON schema |
| 7 | 03c - Recuperacion correo inexistente | 404 | NOT_FOUND + JSON schema |
| 8 | 03d - Login sin API key | 401 | Unauthorized + tiempo respuesta |
| 9 | 04a - Crear sesion (E2E SQL) | 201 | POST /api/v1/sesiones + BD COUNT aumento |
| 10 | 04b - Crear sesion usuario inexistente | 400 | FK rechazada + BD sin cambios (COUNT) |

## Validaciones aplicadas (assertions reales)

- **Status codes:** 200, 201, 400, 401 y 404 verificados con `pm.response.to.have.status(...)`.
- **Esquema JSON:** presencia de `data.{id,email,activo}` en login, `data.{id,usuario_id,tipo_evento,exitoso}` en sesiones, y `error.code` en negativos.
- **Tiempo de respuesta:** `pm.response.responseTime < 3000 ms` en requests de negocio.
- **Tokens/identificadores devueltos:** `authToken` (usuarioId) y `sesionId` capturados dinamicamente con `pm.collectionVariables.set(...)`.
- **Verificacion en BD (patron SQL REST):** `utils.bodySqlRest` consulta `sesiones` antes/despues para confirmar el INSERT y, en el caso negativo, que la base NO cambio (FK violada).

## Manejo de variables

- **Collection variables:** `baseUrl`, `apiKey`, `usuarioId`, `email` (valores por defecto para ejecucion standalone).
- **Environment:** `E_GRUPO_01_AUTENTICACION.json` sobreescribe `baseUrl`/`apiKey` (prevalece sobre collection variables).
- **Variables dinamicas:** `authToken`, `sesionId`, `sesAntesLogin`, `sesAntesLogout`, `sesAntesE2E`, `sesAntesFK` gestionadas durante la corrida.

## Archivos de evidencia

- `newman-report.json` - salida JSON completa de Newman.
- `newman-junit.xml` - reporte JUnit (integrable en CI).
- `RESUMEN-EJECUCION.md` - este resumen.
