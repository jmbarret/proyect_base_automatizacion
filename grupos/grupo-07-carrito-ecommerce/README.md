# Grupo 07 — Carrito de Compras / E-commerce

**Módulo:** Checkout de un e-commerce (tablas `ordenes` + `items_orden`)
**Rama sugerida:** `grupo-07-carrito-ecommerce`

## Integrantes
- Juan Barreto	    juan.m.barretog@gmail.com
- Andrea Escurra    escurracaceres.andy@gmail.com
- Emilio Rojas	    emrojazg@gmail.com
- Armin Avezada     arminavq@fpuna.edu.py
- Felipe Rivas      danirivas64@fpuna.edu.py

## Alcance
Automatización del cierre de compra y ciclo de vida de la orden del sandbox (RF-G7-01..05):
listar, checkout transaccional (cálculo server-side del total), consulta con detalle,
recálculo de cabecera y baja lógica. Cubierto en tres capas:

- **BDD (feature):** `features/carrito-ecommerce.feature` — 18 escenarios `@grupo-7 @api`
  usando el catálogo de steps de la skill `bdd` (RF-G7-01..05, happy/negativo/edge).
  El stub original de alumnos quedó en `features/carrito-ecommerce.stub.feature.bak`.
- **API (Postman/Newman):** `postman/grupo-07-carrito-ecommerce.postman_collection.json`
  — 20 requests con `pm.test`, encadenando `ordenId`.
- **Agente de IA (ejemplo):** `agente-ia/` — agente function-calling que opera los 5 endpoints.

## Supuestos / brechas del diseño (documentadas como comportamiento esperado)
- `monto` y `subtotal` los calcula siempre el servidor; un total del cliente se ignora.
- `PUT /ordenes/{id}` recalcula `producto`/`monto` pero **no** toca `items_orden`: tras un
  recálculo, `GET /ordenes/{id}` muestra el detalle original desincronizado del nuevo monto.
- `DELETE /ordenes/{id}` es soft-delete (`activo=false`); deja `items_orden` huérfanos.

## Cómo ejecutar la regresión
```bash
# Postman/Newman
npm i -g newman
newman run postman/grupo-07-carrito-ecommerce.postman_collection.json \
  --env-var "baseUrl=http://localhost:3001" \
  --env-var "apiKey=TU_API_KEY"

# BDD (skill bdd) — requiere steps S_api.steps.ts y cucumber-js
npx cucumber-js --tags "@grupo-7"

# Agente de IA (demo)
cd agente-ia
BASE_URL=http://localhost:3001 API_KEY=TU_API_KEY node agent.mjs
```

## CI: regresión Postman automática

El workflow [`postman-grupo07-regression.yml`](../../.github/workflows/postman-grupo07-regression.yml)
corre esta colección con Newman en GitHub Actions (push/PR a `main` que toquen la colección, o
manual vía `workflow_dispatch`). Requiere configurar en el repo
(Settings → Secrets and variables → Actions):

- **Variable** `GRUPO07_BASE_URL` — URL del backend desplegado de `aiquaa-sandbox-api`
  (ej. `https://aiquaa-sandbox-api.vercel.app`).
- **Secret** `GRUPO07_API_KEY` — API key para el header `x-api-key`.

El run sube un único artifact **`informe-regresion-grupo07`** con el PDF de resultados
(`report.pdf`), generado con el reporter de
[`skills/postman-newman-skill/reporter/newman_report.py`](../../skills/postman-newman-skill/reporter/newman_report.py)
(reportlab + Pillow) a partir del `--reporter-json-export` de Newman: portada con banner/logos,
estadísticas (peticiones/pruebas/aprobadas/fallidas) y detalle por request (método, URL, status,
tiempo, cada `pm.test` con su resultado y el cuerpo de respuesta). Sin HTML ni XML intermedios en
el artifact — solo el PDF.

> **Nota:** la key de demo del sandbox tiene rate-limit propio (`429 RATE_LIMITED`); el workflow
> usa `--delay-request 800` para evitarlo. Con una key dedicada del equipo (sin ese límite
> compartido) la corrida debería ser estable y más rápida.

## Entregables (checklist ENTREGABLES.md)
- [x] Análisis y alcance (este README + feature)
- [x] BDD — `features/` (18 escenarios: happy path, negativo, edge case)
- [x] API — colección Postman/Newman (`postman/grupo-07-carrito-ecommerce.postman_collection.json`)
- [ ] UI — `tests/e2e/` con Playwright (pendiente: el front del sandbox no expone carrito)
- [ ] Evidencias en `evidence/`
- [ ] CI/CD verde
- [ ] PR a `main` usando la plantilla del repo

## Trazabilidad BDD -> API - Juan Barreto

Colección Postman: `postman/grupo-07-juan-barreto-carrito-e-commerce.postman_collection.json`.

| Escenario BDD | Tipo | Endpoint | Método | Datos de entrada | Validaciones / Assertions |
|---|---|---|---|---|---|
| Completar una compra con productos disponibles | Happy Path | `{{baseUrl}}/api/v1/ordenes` | POST | `usuarioId: 1`; dos ítems: Teclado (`cantidad: 2`, `precioUnitario: 10.50`) y Mouse (`cantidad: 1`, `precioUnitario: 5.25`) | Status **201**; `data.id` existe; `data.estado` es `pendiente`; `data.items` contiene dos elementos; `data.monto` es **26.25**; tiempo de respuesta menor a 3000 ms; guarda `data.id` en `ordenId` |
| No permitir finalizar una compra con el carrito vacío | Negativo | `{{baseUrl}}/api/v1/ordenes` | POST | `usuarioId: 1`; `items: []` | Status **400**; existe la estructura `error`; `error.code` es `VALIDATION_ERROR`; tiempo de respuesta menor a 3000 ms |
| No permitir confirmar una compra con cantidad cero de un producto | Edge Case | `{{baseUrl}}/api/v1/ordenes` | POST | `usuarioId: 1`; Teclado con `cantidad: 0` y `precioUnitario: 10.50` | Status **400**; existe la estructura `error`; `error.code` es `VALIDATION_ERROR`; tiempo de respuesta menor a 3000 ms |

### Variables de colección utilizadas

- `baseUrl`: URL base del sandbox AIQUAA (`https://aiquaa-sandbox-api.vercel.app`).
- `apiKey`: API key enviada mediante el header `x-api-key`; su valor se mantiene vacío en el archivo exportado para no publicar credenciales.
- `ordenId`: identificador guardado automáticamente desde `data.id` después del checkout exitoso.
## Trazabilidad BDD -> API (AIQUAA)

> Flujo de **eliminar producto de carrito** (Happy Path) — colección
> `postman/grupo-07-andrea-escurra-carrito-e-commerce.postman_collection.json` (Andrea).
> El mismo flujo aplica como base para el **caso negativo**: tras la baja,
> la verificación devuelve `404` confirmando que el recurso ya no existe.

> **Nota (Andrea):** Mi trazabilidad cubre el caso de **eliminar producto de carrito**. Para poder eliminar, el flujo incluye como primer paso **agregar** una orden (precondición) y como último paso **consultar** para verificar la baja. Si otro/a compañero/a va a cubrir **solo** el escenario de "agregar producto", ese caso estará documentado aparte para no duplicar ni confundir responsabilidades.

> **Nota (Tarea 3):** La validación de BD (SQL REST) aplica solo a los DELETE (caso feliz y negativo). `1-Crear Orden` es setup sin SQL porque el escenario de creación/checkout lo cubre otro integrante del grupo en la colección oficial; el pre-request de colección solo define el helper `utils`, no valida BD.

| Paso | Acción BDD | Tipo | Endpoint | Método | Datos Entrada | Validaciones / Assertions |
|---|---|---|---|---|---|---|
| 1 | Agregar producto al carrito (precondición) | Setup | `{{baseUrl}}/api/v1/ordenes` | POST | `usuarioId: 3`, `items: [{ producto: "Cable HDMI", cantidad: 1, precioUnitario: 50000 }]` | Status **201**, guarda `eliminarId` |
| 2 | Eliminar el producto del carrito | Happy Path | `{{baseUrl}}/api/v1/ordenes/{{eliminarId}}` | DELETE | `eliminarId` de la orden creada | Status **204** (baja exitosa) |
| 3 | Verificar que el producto ya no existe | Verificación | `{{baseUrl}}/api/v1/ordenes/{{eliminarId}}` | GET | `eliminarId` | Status **404** (orden dada de baja) |

## Variables de Entorno Utilizadas

- `baseUrl` → `https://aiquaa-sandbox-api.vercel.app`
- `apiKey` → `sbx_demo_f581ca21e68a347288c94d71`
- `eliminarId` → se setea automáticamente desde la respuesta del paso 1

## Semana 3 — Checkout con datos SQL dinámicos

La carpeta **Semana 3 - SQL dinamico** de la colección grupal
`postman/grupo-07-carrito-ecommerce.postman_collection.json` agrega dos casos de
`RF-G7-02`. Los 20 requests anteriores y las colecciones individuales se conservan.

| Caso | Escenario BDD existente | Pre-request SQL | Assertions HTTP y SQL posterior |
|---|---|---|---|
| G7-S3 01 Checkout exitoso con SQL | Completar una compra con productos disponibles | Obtiene `usuarios.id` real; confirma cero cabeceras e ítems para el marcador del intento | 201; comprador, estado pendiente, producto, monto 26.25 y subtotales 21/5.25; relee `ordenes` por ID y los dos `items_orden` por `orden_id`, comparando cantidades, precios y subtotales |
| G7-S3 02 Cantidad cero sin inserciones | No permitir confirmar una compra con cantidad cero de un producto | Obtiene comprador real; toma conteos propios; cambia únicamente el campo `g7Cantidad` de 2 a 0 | 400 `VALIDATION_ERROR`; conteos de cabeceras e ítems permanecen en cero |

La mención de productos disponibles conserva el nombre del BDD; no implica verificar stock:
el contrato no incluye catálogo ni existencias. El caso de cantidad cero cubre el mínimo
negativo exigido y el límite inferior de cantidad. El caso previo de carrito vacío permanece
en la regresión original. No se afirma cobertura de rollback por un fallo dentro de la
transacción: este negativo es rechazado por validación de entrada.

### Configuración y variables

Importar la colección grupal y `postman/E_GRUPO_07_SQL.json`. Seleccionar ese environment,
completar `apiKey` localmente y ejecutar solo la carpeta **Semana 3 - SQL dinamico**.

- `baseUrl`: `https://aiquaa-sandbox-api.vercel.app`; el environment prevalece sobre el
  localhost de la colección heredada.
- `apiKey`: header `x-api-key`; el environment exportado queda vacío.
- `g7Cantidad`: default de colección 2, reseteado antes de cada caso; el negativo usa 0.
  Se establece también en el scope local para evitar que un environment lo sobrescriba.
- `g7UsuarioId`: scope local, obtenido en cada pre-request mediante
  `SELECT id FROM usuarios ORDER BY id LIMIT 1`; ningún ID está fijado en el nuevo body.
- `g7Producto1/2`: marcadores UUID por intento, generados automáticamente.
- `g7Antes` y `g7OrdenId`: datos locales de ejecución; no modifican el `ordenId` heredado.

El helper `utils.bodySqlRest(sql, params)` se declara una sola vez en el pre-request de
colección. Las consultas son SELECT parametrizados. Los conteos se limitan al marcador de
cada intento (incluyen también órdenes inactivas), evitando que compras simultáneas de otros
compañeros cambien el resultado. El body sigue siendo JSON legible con variables por campo.

Los helpers que realizan operaciones asíncronas reciben el `pm` del script que los llama:
esto permite que Newman registre los callbacks en el contexto vigente. Un fallo SQL, JSON
inválido o comprador ausente registra una assertion fallida y detiene el checkout mediante
`skipRequest()` y `setNextRequest(null)`.

### Ejecución y evidencia

Con las dependencias del repositorio instaladas, definir `API_KEY` en el entorno del proceso
y ejecutar desde la raíz:

```bash
node grupos/grupo-07-carrito-ecommerce/run-sql-newman.cjs
```

El runner usa Newman, limita la ejecución a los dos casos y guarda un reporte reducido en
`grupos/grupo-07-carrito-ecommerce/evidence/semana-3-newman.json`. Excluye headers, credenciales,
bodies y datos personales. Devuelve código distinto de cero si falla o si no ejecuta ambos
requests de negocio. `BASE_URL` permite cambiar el sandbox explícitamente.

Alternativa Postman/Newman: completar la API key en una copia local del environment y ejecutar:

```bash
npx newman run postman/grupo-07-carrito-ecommerce.postman_collection.json -e postman/E_GRUPO_07_SQL.json --folder "Semana 3 - SQL dinamico" --bail --delay-request 2500
```

No publicar el environment con credenciales ni un reporte JSON estándar sin sanear.
La carpeta consume **12 solicitudes** por corrida (10 SQL y 2 de negocio); el límite del
sandbox es 30/minuto por API key, compartido con otros usuarios. El delay de Newman se aplica
a los requests principales; los `pm.sendRequest` internos también cuentan para el límite.
Dejar al menos un minuto entre corridas repetidas y coordinar el uso de la clave compartida.

Pruebas locales de protección, sin acceso al sandbox ni credenciales reales:

```bash
node --test grupos/grupo-07-carrito-ecommerce/tests/api/sql-prerequest.test.cjs
```

Resultado registrado: **18 assertions, 0 fallos, 12 solicitudes**, con Newman 6.2.2 el
2026-09-07 a las 00:22 UTC (2026-09-06, 21:22 de Asunción). Comprador dinámico 1; orden creada
125, con una cabecera y dos ítems. Negativo: conteos 0/0 antes y después.
Las cuatro protecciones locales también pasaron. Ver `evidence/SEMANA-3.md`.

Cada corrida exitosa crea una orden y dos ítems de prueba, que permanecen en el sandbox;
no hay limpieza destructiva. La evidencia corresponde al subset de Semana 3, no certifica
la regresión completa, BDD ni UI.

### Entrega

Descripción en `PR-SEMANA-3.md`: el PR #54 entrega a la rama compartida
`grupo-07-carrito-ecommerce` y el PR grupal #51 integra hacia `main`.
Los archivos de herramientas locales (`.agents/`, `.codegraph/`,
`skills-lock.json`) quedan fuera de esta entrega.

Fuentes: `docs/TAREA-SQL-REST-DINAMICO.md`,
`docs/requerimientos/_src/grupo-07.mjs` (RF-G7-02),
`features/carrito-ecommerce.feature` del grupo, y contrato público de
[checkout](https://github.com/stevenayal/aiquaa-sandbox-api/blob/main/app/api/v1/ordenes/route.ts)
y [SQL REST](https://github.com/stevenayal/aiquaa-sandbox-api/blob/main/lib/handle-sql-request.ts).

## Tarea 3 — Verificación de BD (SQL REST)

> Tarea asincrónica grupal (semana 03): no creerle a la API solo por el status code — volver a
> **consultar la base de datos** antes y después de cada operación de escritura para confirmar
> que el cambio realmente quedó (o, en un caso negativo, que la BD no cambió).

### Patrón

Cada operación se valida **dos veces** contra la BD vía el endpoint de solo lectura
`POST {{baseUrl}}/api/v1/sql/select` (header `x-api-key`):

```
ANTES   (Pre-request Script)  → leo la BD antes de tocar
↓
LA ACCIÓN  (POST / DELETE)
↓
DESPUÉS (Tests Script)        → vuelvo a la BD y confirmo
```

- Si la operación **debe cambiar** la BD (caso feliz) → después se confirma el cambio.
- Si la operación **debe rechazarse** (caso negativo) → después se confirma que el `COUNT(*)` no cambió.

### Implementación — flujo de Andrea (Eliminar producto de carrito)

Colección: [`postman/grupo-07-andrea-escurra-carrito-e-commerce.postman_collection.json`](../../postman/grupo-07-andrea-escurra-carrito-e-commerce.postman_collection.json)

| # | Request | Método | Status | Validación BD (SQL REST) |
|---|---|---|---|---|
| 1 | `1-Crear Orden` (setup, sin SQL) | POST `/api/v1/ordenes` | 201 | — (setup: guarda `eliminarId`; el POST lo cubre el integrante de checkout) |
| 2 | `2-Dar de Baja` ⭐ caso feliz | DELETE `/api/v1/ordenes/{{eliminarId}}` | 204 | ANTES: `SELECT id, activo FROM ordenes WHERE id = $1` → `activo=true` · DESPUÉS: misma consulta → `activo=false` |
| 3 | `3-Verificar Baja` | GET `/api/v1/ordenes/{{eliminarId}}` | 404 | Verificación vía API (NOT_FOUND) |
| 4 | `4-Orden inexistente (404, BD sin cambios)` ⭐ caso negativo | DELETE `/api/v1/ordenes/999999` | 404 | ANTES: `SELECT COUNT(*) AS total FROM ordenes` · DESPUÉS: mismo COUNT igual (la BD no cambió) |

### Manejo de variables

- **Pre-request de colección** (una sola vez): define el helper `utils.bodySqlRest(sql, params)`
  que arma la llamada a `/api/v1/sql/select`, y el valor por defecto `usuarioId = 3`.
- `{{usuarioId}}` en el body del POST (`1-Crear Orden`) y `{{eliminarId}}` en la URL del DELETE.
- `totalAntes` se guarda con `pm.variables.set(...)` en el pre-request del caso negativo.
- **Pitfall respetado:** los valores que devuelve `/api/v1/sql/select` vienen como **string**;
  se convierten con `Number(...)` / `String(...)` antes de comparar.

### Evidencia

`evidence/semana-03/` → `newman-report-andrea.json`, `newman-junit-andrea.xml` y
`RESUMEN-EJECUCION-andrea.md` (corrida Newman 6.2.1 de Andrea Escurra: 8 requests, 8 assertions,
0 fallos). Cada integrante agrega sus archivos con su prefijo (`*-juan.json`, `*-aramin.xml`,
etc.) al entregar su escenario.
