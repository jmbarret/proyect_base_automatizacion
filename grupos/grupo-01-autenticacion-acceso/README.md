# Grupo 01 — Autenticación y Acceso

**Módulo:** Login / Logout / Recuperación de contraseña
**Rama:** `grupo-01-autenticacion-acceso`

## Integrantes

- Gloria Figueredo ---> gloriaoliva487@gmail.com
- David Cristaldo  ---> davidcrislo89@gmail.com
- Oscar Benítez    ---> oscardocito@gmail.com
- Mariel Aquino    ---> maquino1986@gmail.com
- Mariset Lorente  ---> marisetlorentecastillo@gmail.com

## Análisis y Alcance

### Objetivo del flujo automatizado

Validar el flujo de autenticación y acceso al laboratorio AIQUAA, contemplando
el inicio de sesión, control de acceso a recursos protegidos, recuperación de
contraseña y cierre de sesión, incluyendo escenarios exitosos, negativos y
casos límite.

### Supuestos

- El ambiente de pruebas de AIQUAA se encuentra disponible.
- Existen usuarios y datos de prueba previamente configurados.
- El servicio de autenticación se encuentra operativo durante las pruebas.
- Se utilizan únicamente datos del entorno de pruebas.
- La cohorte "demo" dispone de una sesión seeded cuando el escenario lo requiere.
- Los recursos protegidos del laboratorio requieren una sesión autenticada.
- El servicio de recuperación de contraseña y envío de notificaciones se
  encuentra disponible cuando el escenario lo requiere.

### Riesgos

- Indisponibilidad temporal del ambiente o del servicio de autenticación.
- Credenciales o usuarios de prueba vencidos, bloqueados o deshabilitados.
- Bloqueo temporal de usuarios debido a múltiples intentos fallidos.
- Cambios en las rutas, campos, mensajes o comportamiento de la interfaz.
- Fallas o demoras en servicios externos utilizados para la recuperación
  de contraseña.
- Configuración incorrecta o indisponibilidad de la sesión seeded.
- Diferencias entre los mensajes esperados y los implementados en la interfaz.

### Cobertura incluida

- Login con credenciales válidas.
- Login con credenciales inválidas.
- Validación de campos obligatorios.
- Casos límite relacionados con los datos de autenticación.
- Redirección al login de usuarios no autenticados que intentan acceder
  a recursos protegidos.
- Acceso al recurso protegido después de una autenticación exitosa.
- Recuperación de contraseña con datos registrados.
- Cierre de sesión seguro.

### Cobertura excluida

- Registro y onboarding de nuevos usuarios.
- Autenticación multifactor (MFA/2FA).
- Inicio de sesión mediante proveedores externos.
- Gestión de roles y permisos.
- Funcionalidades de negocio posteriores a la autenticación asignadas
  a otros módulos.
- Pruebas de rendimiento, carga y seguridad.
- Validación detallada del contenido o formato de los correos de recuperación.
- Uso, expiración y cambio efectivo de contraseña mediante el enlace de
  recuperación.

## Entregables

Checklist según [ENTREGABLES.md](../../ENTREGABLES.md):

#- [ ] Análisis y alcance
#- [ ] BDD — `features/` (mínimo 3 escenarios: happy path, negativo, edge case)
- [x] API — colección Postman/Newman (si aplica al módulo)
- [ ] UI — `tests/e2e/` con Playwright
- [x] Evidencias en `evidence/semana-03/` (Newman)
- [ ] CI/CD verde
- [ ] PR a `main` usando la plantilla del repo


## Trazabilidad BDD -> API (AIQUAA)

| Escenario BDD | Tipo | Endpoint AIQUAA / Postman | Método | Datos Entrada | Validaciones / Assertions |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Login exitoso con credenciales válidas** | Happy Path | `{{baseUrl}}/api/v1/labs/admin/seed/{{candidateId}}` | `POST` | `documento`, `password` | Status 200, confirma estado activo y genera `sessionId`. |
| **Solicitud de recuperación con correo no registrado** | Caso Negativo | `{{baseUrl}}/api/v1/auth/forgot-password` | `POST` | `email` no registrado | Status 404, valida mensaje `"Correo no encontrado"`. |
| **Cierre de sesión con token expirado** | Edge Case | `{{baseUrl}}/api/v1/auth/logout` | `POST` | Header `Authorization` expirado | Status 401, valida mensaje de sesión expirada. |
<!-- Aporte: Gloria Figueredo -->
| **Login con campos obligatorios vacíos** | Edge Case | `{{baseUrl}}/api/v1/auth/login` | `POST` | `email` vacío | Status 400, `VALIDATION_ERROR`, mensaje `"Invalid request."`, detalle del campo `email` y tiempo < 3000 ms. |
<!-- Aporte: Mariset C. Lorente -->
| **Login rechazado con credenciales inválidas** | Caso Negativo | `POST Supabase /auth/v1/token?grant_type=password` | `POST` | `email` válido + `password` incorrecta | Status 400, `error_code: invalid_credentials`, respuesta JSON y tiempo < 3000 ms. |
| **Login con correo válido ingresado con espacios** | Caso Negativo | `POST Supabase /auth/v1/token?grant_type=password` | `POST` | `email` válido con espacios + `password` válida | Status 400, `error_code: invalid_credentials`, respuesta JSON y tiempo < 3000 ms. |
<!-- Aporte: Oscar Benítez -->
| **Redirección al login al intentar acceder a un laboratorio protegido** | Caso Negativo | `{{supabaseUrl}}/auth/v1/user` | `GET` | Header `apikey`, sin token de sesión | Status 401, respuesta JSON con información del error y tiempo < 3000 ms. La API valida el rechazo; la redirección se valida en UI. |
| **Login exitoso con credenciales válidas** | Happy Path | `{{supabaseUrl}}/auth/v1/token?grant_type=password` | `POST` | `testEmail` + `testPassword` | Status 200, usuario esperado, token Bearer y captura dinámica de `accessToken`. |
| **Acceso al recurso solicitado después de iniciar sesión** | Happy Path | `{{supabaseUrl}}/auth/v1/user` | `GET` | `apikey` + `Bearer {{accessToken}}` | Status 200, identificador y correo del usuario autenticado. El acceso al laboratorio específico se valida en UI. |
| **Login rechazado con credenciales inválidas** | Caso Negativo | `{{supabaseUrl}}/auth/v1/token?grant_type=password` | `POST` | `testEmail` + `invalidPassword` | Status 400, `error_code: invalid_credentials`, respuesta JSON y tiempo < 3000 ms. |

## Variables de Entorno Utilizadas

* **`baseUrl`**: URL base del servidor de AIQUAA.
* **`candidateId`**: Identificador asignado para la ejecución del grupo.
* **`sessionId`**: Token capturado dinámicamente para autenticación.
<!-- Variables utilizadas por los escenarios de Mariset C. Lorente -->
* **supabaseAnonKey**: Clave utilizada para consumir el servicio de autenticación de Supabase. Su valor no se almacena en el repositorio.
* **testEmail**: Correo válido utilizado durante las pruebas.
* **testPassword**: Contraseña válida utilizada durante las pruebas. Su valor no se almacena en el repositorio.
* **invalidPassword**: Contraseña inválida utilizada para validar el rechazo de credenciales.
<!-- Variables utilizadas por los escenarios de Oscar Benítez -->
* **`supabaseUrl`**: URL del servicio de autenticación utilizado por AIQUAA.
* **`accessToken`**: Token capturado dinámicamente después del login exitoso; no debe completarse manualmente.

## Ejecución de la colección de Oscar Benítez

1. Importar `postman/Grupo 01 - Autenticacion y Acceso Oscar Benitez.postman_collection.json` en Postman.
2. Completar localmente `supabaseAnonKey`, `testEmail` y `testPassword` con datos de prueba válidos. No guardar ni exportar esos valores al repositorio.
3. Ejecutar la colección completa en el orden definido, porque el request 02 genera el `accessToken` utilizado por el request 03.

La colección utiliza el servicio Supabase de autenticación consumido por AIQUAA. Las rutas `/api/v1/labs/*` de la plantilla académica no están publicadas actualmente bajo `https://aiquaa.com`; al 29 de agosto de 2026 responden con una página HTML 404. Por ese motivo, la colección separa las verificaciones API de sesión de las redirecciones y accesos específicos que deben validarse mediante pruebas UI.

---

## Semana 03 — API con Postman/Newman + validación SQL

Entregables de la semana 03 para el módulo Autenticación y Acceso.

- **Colección actualizada:** [`postman/C_GRUPO_01_AUTENTICACION_ACCESO.json`](../../postman/C_GRUPO_01_AUTENTICACION_ACCESO.json)
- **Entorno:** [`postman/E_GRUPO_01_AUTENTICACION.json`](../../postman/E_GRUPO_01_AUTENTICACION.json)
- **Evidencia:** [`grupos/grupo-01-autenticacion-acceso/evidence/semana-03/`](evidence/semana-03/)

### Qué se agregó

1. **Consultas SQL (preparación/validación de datos):** mediante el patrón SQL REST dinámico,
   se consulta `qa_training` vía `POST /api/v1/sql/select` (helper `utils.bodySqlRest`) para
   preparar y verificar los datos de autenticación y acceso **antes y después** de cada
   operación (pre-request y post-response).
2. **Assertions reales:** status `200` / `201` / `400` / `401` / `404`, validación de
   **esquema JSON** (`data.*` y `error.code`), **tiempo de respuesta** `< 3000 ms` y
   **captura de tokens/identificadores** devueltos (`authToken` = `usuarioId`, `sesionId`).
3. **Manejo de variables y evidencia:** variables de colección + archivo de entorno + variables
   dinámicas de corrida, y reportes generados con **Newman** en `evidence/semana-03/`.

### Requisitos

- Node.js (v18+) y Newman (se ejecuta vía `npx`, no requiere instalación previa):
  ```bash
  npx newman --version
  ```

### Ejecución

```bash
# Desde la raíz del repositorio
npx -y newman run postman/C_GRUPO_01_AUTENTICACION_ACCESO.json \
  -e postman/E_GRUPO_01_AUTENTICACION.json \
  -r cli,json,junit \
  --reporter-json-export grupos/grupo-01-autenticacion-acceso/evidence/semana-03/newman-report.json \
  --reporter-junit-export grupos/grupo-01-autenticacion-acceso/evidence/semana-03/newman-junit.xml
```

### Resultado de la ejecución base (Semana 03)

- **Requests:** 18 · **Assertions:** 31 · **Fallidas:** 0 → ✅ **PASS**
- Detalle completo en [`evidence/semana-03/RESUMEN-EJECUCION.md`](evidence/semana-03/RESUMEN-EJECUCION.md).
- Archivos de evidencia: `newman-report.json`, `newman-junit.xml`, `RESUMEN-EJECUCION.md`.
- Estas métricas corresponden a la ejecución anterior al aporte de Oscar Benítez. La colección ampliada contiene 12 escenarios y genera 24 requests efectivos; se deben regenerar los reportes antes de cerrar el PR.

### Cobertura de escenarios

| # | Escenario | Status | Validación |
| :--- | :--- | :---: | :--- |
| 1 | SQL — usuario activo (precondición) | 200 | `SELECT usuarios` (preparación BD) |
| 2 | SQL — sesiones previas (historial) | 200 | `SELECT sesiones` (validación BD) |
| 3 | Login exitoso (Happy Path) | 200 | POST `/auth/login` + BD login insertado |
| 4 | Logout exitoso (Happy Path) | 200 | POST `/auth/logout` + BD logout insertado |
| 5 | Login correo no registrado | 400 | `VALIDATION_ERROR` + esquema |
| 6 | Login usuario inactivo | 400 | `VALIDATION_ERROR` + esquema |
| 7 | Recuperación correo inexistente | 404 | `NOT_FOUND` + esquema |
| 8 | Login sin API key | 401 | Unauthorized + tiempo |
| 9 | Crear sesión (E2E SQL) | 201 | POST `/sesiones` + BD `COUNT` aumenta |
| 10 | Crear sesión usuario inexistente | 400 | FK rechazada + BD sin cambios (`COUNT`) |
| 11 | Recuperación exitosa con correo registrado — **Oscar Benítez** | 200 | Usuario dinámico por SQL + POST `/auth/forgot-password` + BD `COUNT` aumenta exactamente en 1 |
| 12 | Login con email obligatorio vacío — **Oscar Benítez** | 400 | `VALIDATION_ERROR` + BD sin cambios (`COUNT`) |

### Aporte de Mariel Aquino — Semana 03

- Colección Postman con tres escenarios de autenticación: login exitoso, recuperación con correo no registrado y cierre de sesión con token expirado.
- Trazabilidad de los escenarios BDD hacia sus endpoints, métodos, datos de entrada y assertions esperadas.
- Manejo de las variables `baseUrl`, `candidateId` y `sessionId` para la ejecución de la colección.
- El aporte fue subido anticipadamente en el PR de Semana 02 mediante el commit `1f33f88`, aunque corresponde a los entregables API de Semana 03.
- Colección: [`postman/grupo-01-autenticacion.postman_collection.json`](../../postman/grupo-01-autenticacion.postman_collection.json).
- Constancia de entrega: [`evidence/semana-03/ENTREGA-MARIEL.md`](evidence/semana-03/ENTREGA-MARIEL.md).

### Aporte de Oscar Benítez — Semana 03

- Automatización de recuperación exitosa con un correo registrado obtenido dinámicamente desde `usuarios`.
- Automatización del rechazo de login sin el campo obligatorio `email`.
- Validación SQL posterior sobre `sesiones`: el caso exitoso inserta exactamente una fila y el caso negativo no modifica la tabla.
- Los escenarios están en `05 - Aporte Oscar Benitez - BDD pendientes` dentro de la colección consolidada.

### Notas

- El API bajo prueba es `aiquaa-sandbox-api` (Vercel) y requiere `x-api-key` (incluida en el
  entorno). Respeta el **rate limit de 30 req/min**: no ejecutar la colección en paralelo ni en
  bucle, ya que los `pm.sendRequest` de validación también consumen cuota.
- Las rutas `/api/v1/labs/*` de la plantilla académica no están publicadas; esta colección apunta
  al endpoint real de autenticación/acceso del sandbox.
  
 ### Aporte de David Cristaldo — Semana 03

- **CP 01 - Solicitar recuperación con correo registrado:** usuario activo obtenido 
  dinámicamente por SQL (aleatorio), POST `/auth/forgot-password`, validación en 
  `qa_training.sesiones` de que el evento `password_reset_solicitado` quedó persistido.

- **CP 02 - Confirmar restablecimiento de contraseña (nuevo):** POST `/auth/reset-password`, 
  encadenado al usuario capturado por CP 01 (mismo usuario que pidió el reset es el que lo 
  completa), validación en `qa_training.sesiones` de que el evento `password_reset_completado` 
  quedó persistido. Incluye fallback a usuario aleatorio si se corre de forma independiente.

**Resultado de la ejecución (Newman):**

- **Requests:** 6 (incluye 4 llamadas auxiliares a `/sql/select` para pre/post-request)
- **Test-scripts:** 2 · **Prerequest-scripts:** 2 · **Assertions:** 6
- **Fallidas:** 0 → ✅ **PASS**
- **Duración total:** 2.4s
- Evidencia: [`evidence/semana-03/newman-report-david.json`](evidence/semana-03/newman-report-david.json) 
  y [`evidence/semana-03/newman-junit-david.xml`](evidence/semana-03/newman-junit-david.xml)
  ### Aporte de Gloria Figueredo — Semana 03

- **CP 01 - Login con campos obligatorios vacíos:** consulta SQL previa sobre `qa_training.sesiones`, ejecución del POST `/auth/login` con `email` vacío y validación de respuesta HTTP 400. La consulta SQL posterior verifica que el intento de login inválido no genere un nuevo registro en la base de datos.
- **CP 02 - Login exitoso con usuario dinámico:** obtención dinámica de un usuario activo desde `qa_training.usuarios`, utilizando el `email` e `id` obtenidos desde la base de datos para ejecutar el POST `/auth/login`. Posteriormente se valida en `qa_training.sesiones` que el login haya quedado registrado.
- Se utilizaron variables de colección para almacenar y reutilizar los datos obtenidos dinámicamente desde la base de datos.
- Se incorporaron validaciones de API y base de datos mediante SQL REST `/api/v1/sql/select`.

**Resultado de la ejecución (Newman):**

- **Requests:** 6
- **Test-scripts:** 2 · **Prerequest-scripts:** 2 · **Assertions:** 16
- **Fallidas:** 0 → ✅ **PASS**
- **Duración total:** 2s
- Evidencia: [`evidence/semana-03/newman-report-gloria.json`](evidence/semana-03/newman-report-gloria.json) y [`evidence/semana-03/newman-junit-gloria.xml`](evidence/semana-03/newman-junit-gloria.xml)
