# Trazabilidad RF → API → SQL — Grupo 06 (Semana 03)

**Rama:** `grupo-06-notificaciones-alertas`
**Fuente de requerimientos:** *Notificaciones y Alertas — Requerimientos funcionales v1.0* (22/08/2026), derivado del código de `aiquaa-sandbox-api` y del schema `qa_training`.
**Colección:** [`postman/grupo-06-notificaciones-alertas.postman_collection.json`](../../../postman/grupo-06-notificaciones-alertas.postman_collection.json)
**Evidencia:** [`evidence/semana-03/`](../evidence/semana-03/)

> **Última ejecución:** 69 requests · **455 assertions · 0 failed** · exit 0 · 5m 15s.
> De esas, **11 assertions consultan la base de datos** vía `POST /api/v1/sql/select`.

Este documento complementa a [`trazabilidad-bdd-api.md`](trazabilidad-bdd-api.md), que mapea los escenarios BDD del grupo. Acá el eje es el **requerimiento funcional oficial (RF-G6-0x)** y qué agrega la verificación en base de datos.

---

## 1. Por qué SQL: lo que REST no puede demostrar

La colección de la semana 02 solo podía afirmar lo que la API devolvía. Hay reglas del documento que son **indemostrables desde la respuesta HTTP**:

| Regla del requerimiento | Lo que ve REST | Lo que agrega SQL |
|---|---|---|
| RF-G6-06: *"Marca activo = false; la fila permanece en la base, nunca se borra físicamente"* | `204` y la fila desaparece de los listados | La fila **existe** con `activo = false`. Sin esto, un borrado físico pasaría el test igual |
| RF-G6-02: *"no se registra ninguna notificación"* ante destinatario inexistente | `400 VALIDATION_ERROR` | `COUNT(*) = 0`: la base quedó intacta. El `400` no prueba ausencia de escritura |
| RF-G6-03: *"El campo estado no cambia al marcarla como leída"* | El JSON de respuesta dice `enviada` | La **fila persistida** dice `enviada`: el JSON podría armarse en memoria |
| RF-G6-05: *"leido y estado no forman parte del reemplazo"* | El JSON conserva los valores | La fila conserva los valores tras el `UPDATE` real |
| RF-G6-01: *"limitado a 100 registros"* | Devuelve N registros | Compara N contra el **total real**: distingue "el límite se aplica" de "hay pocos datos" |
| **HG06-03** | `GET` da 404 y `PATCH /leer` da 200 | Un único `SELECT` muestra el estado contradictorio `activo=false` + `leido=true` |

### Contrato del endpoint SQL

`POST /api/v1/sql/select` con `{ sql, params }` → `{ data, rowCount }`.

Guardrails verificados contra la API real:

- **Solo `SELECT`.** `UPDATE` y `DELETE` responden `400 VALIDATION_ERROR` — *"Only SELECT statements are allowed on this endpoint."*
- **Whitelist de tablas.** `sql_audit_log` es rechazada; `notificaciones` y `usuarios` están permitidas.
- **Parámetros posicionales** `$1, $2, …` en el arreglo `params`, nunca interpolados en el string SQL.

El helper vive en el **Pre-request Script de la colección**, declarado una sola vez:

```javascript
if (typeof utils === "undefined") {
  utils = {
    sqlSelect: function (sql, params) { /* arma el request a {{baseUrl}}{{sqlPath}} */ },
    filas: function (res) { /* devuelve [] si la consulta fallo o no es JSON */ },
  };
}
```

> `utils` vive en memoria durante la corrida, no es una variable de Postman. La colección **debe ejecutarse completa o por carpetas** (Runner o Newman): un request suelto no pasa por el pre-request y da `ReferenceError`.

---

## 2. Matriz RF → endpoint → carpeta → SQL

| RF | Endpoint | Carpetas que lo cubren | Consulta SQL de respaldo |
|----|----------|------------------------|--------------------------|
| **RF-G6-01** Listar | `GET /notificaciones` | `S1`, `S5`, `S2`, `S4`, `RF-G6-01 @negative` | `COUNT(*)` de filas activas para contrastar contra el límite de 100; `COUNT(*)` por titular inexistente = 0 |
| **RF-G6-02** Crear | `POST /notificaciones` | `S1`, `S6`, `S8`, `S9`, `S4`, `S3`, `S7`, `RF-G6-02 @negative` | `SELECT` de la fila creada (`estado='enviada'`, `leido=false`, `activo=true`); `COUNT` por canal para TRX-009; `COUNT`=2 en el reproceso; `COUNT`=0 tras alta rechazada |
| **RF-G6-03** Marcar leída | `PATCH /notificaciones/{id}/leer` | `S5`, `HG06-03`, `CONTRATO` | `SELECT` que confirma `leido=true` y `estado='enviada'` sin cambios |
| **RF-G6-04** Consultar | `GET /notificaciones/{id}` | `S1`, `HG06-03`, `CONTRATO` | — (el `404` tras la baja se cruza con el `SELECT` de HG06-03) |
| **RF-G6-05** Reemplazar | `PUT /notificaciones/{id}` | `S4`, `S5`, `CONTRATO` | `SELECT` que confirma canal reemplazado y `leido`/`estado` intactos |
| **RF-G6-06** Dar de baja | `DELETE /notificaciones/{id}` | `S2`, `S3`, `HG06-03`, `00 Setup`, `CONTRATO` | `SELECT` que confirma que la fila sobrevive con `activo=false` |
| **Transversales** | todos | `SEG`, `CONTRATO` | — |

### Criterios de aceptación incorporados en la semana 03

Casos del documento que la semana 02 no cubría:

| Criterio de aceptación | Carpeta | Resultado verificado |
|---|---|---|
| `leido=1` → `400 VALIDATION_ERROR` (el filtro no coerciona booleanos) | `RF-G6-01 @negative` | ✔ `400`, `details` nombra `leido` |
| `usuarioId` no numérico → `400` | `RF-G6-01 @negative` | ✔ `400`, `details` nombra `usuarioId` |
| Titular sin notificaciones → `200` con `data` vacío | `RF-G6-01 @negative` | ✔ `200`, `data: []`, y `COUNT`=0 en la base |
| Orden por id ascendente y límite de 100 | `RF-G6-01 @negative` | ✔ orden verificado; longitud = `min(total, 100)` |
| Asunto vacío → `400` | `RF-G6-02 @negative` | ✔ `400`, `details` nombra `asunto` |
| `usuarioId` inexistente → `400` **y no registra nada** | `RF-G6-02 @negative` | ✔ `400` por FK + `COUNT`=0 en la base |
| Cuerpo JSON malformado → `400` *"Invalid JSON body."* | `CONTRATO` | ✔ mensaje exacto |
| Verbo no soportado → `405` sin envoltura `{error}` | `CONTRATO` | ✔ `405`, cuerpo fuera del contrato |

---

## 3. Hallazgos actualizados

| ID | Estado | Descripción |
|----|--------|-------------|
| **HG06-01** | **Cerrado — no era un defecto** | En la semana 02 lo reportamos como "el alta no es idempotente". El documento de requerimientos lo declara **comportamiento esperado**: *"Al crear dos notificaciones idénticas seguidas, ambas son aceptadas y se registran por separado: no hay control de duplicados"*. El desvío está en **nuestro escenario BDD S3**, que asume una regla de unicidad que el módulo nunca ofreció. La carpeta `S3` ahora documenta el comportamiento real y aplica deduplicación del lado del consumidor. |
| **HG06-02** | Abierto (baja) | `id` y `usuario_id` se devuelven como `string` aunque el OpenAPI los declara `integer`, y la respuesta incluye un campo `activo` no documentado. Confirmado también por SQL: el driver de Postgres serializa `bigint` como string para no perder precisión en JS. El desvío es de **documentación**, no de implementación. |
| **HG06-03** | **Abierto (media) — nuevo** | `PATCH /{id}/leer` **no filtra por `activo`**: marca como leída una notificación dada de baja. El propio documento lo reconoce: *"una inconsistencia real del sandbox, no un comportamiento a asumir como intencional"*. Reproducido de punta a punta en su carpeta y evidenciado con SQL: la fila queda con `activo=false` **y** `leido=true`, un estado que ningún listado de la API puede mostrar. |

Evidencia de HG06-03 en `evidence/semana-03/evidencia-sql.txt`:

```
{"id":"161","asunto":"Baja logica + lectura HG06-03","activo":false,"leido":true,"estado":"enviada"}
```

---

## 4. Uso de Skills de IA

| Herramienta | Qué aportó | Dónde se ve |
|---|---|---|
| **Skill `postman-newman`** del repo (`skills/postman-newman-skill/`), referencia `sql-prerequest-pattern.md` | Definió la arquitectura del patrón SQL adoptado: helper declarado una sola vez en el pre-request de la colección, una variable por campo que varía (nunca el body entero serializado), y `pm.variables` para datos de un solo request. La colección sigue ese patrón tal cual. | Pre-request de la colección y las 11 verificaciones SQL |
| **MCP `aiquaa-api-quality`**, tool `api_requisitos` | Estructuró los criterios de aceptación del PDF en un modelo con IDs estables (`REQ-001`…`REQ-006`, `BR-001`), usado para armar la matriz RF → endpoint de la sección 2. | Sección 2 de este documento |
| **MCP `aiquaa-api-quality`**, tool `api_cobertura` | Reveló un criterio que no estábamos cumpliendo: **la herramienta considera un requisito cubierto solo si el nombre de la assertion referencia el ID del requisito**. Nuestras assertions describen la regla en prosa pero no la etiquetan, por lo que la trazabilidad es legible para una persona y no para una máquina. | Ver limitación abajo |

**Limitación declarada.** El cruce de `api_cobertura` se ejecutó sobre una colección de muestra, no sobre la colección completa: la reducción que preparamos para alimentarla resultó incompleta (perdía assertions) y usarla habría producido una matriz de cobertura falsa. Se decidió no publicar ese resultado. La mejora que sí se adoptó del análisis es la recomendación de etiquetar assertions con el ID del requerimiento, aplicada parcialmente: las carpetas nuevas y las assertions SQL ya nombran el `RF-G6-0x` que verifican.

**Próximo paso sugerido:** completar el etiquetado `RF-G6-0x` en las assertions heredadas de la semana 02 y volver a correr `api_cobertura` sobre la colección íntegra.

---

## 5. Ejecución

La última corrida ejecutó **69 requests: 58 contra los endpoints REST y 11 contra `/api/v1/sql/select`**. El total de REST varía entre corridas porque la carpeta `00 Setup` repite su `DELETE` una vez por cada notificación residual que encuentre.

Como el límite de la API es de **30 requests por minuto por API key** y cada `pm.sendRequest` cuenta contra esa cuota igual que un request normal, el espaciado debe ser mayor que en la semana 02:

```bash
npx newman run postman/grupo-06-notificaciones-alertas.postman_collection.json \
  -e postman/grupo-06-aiquaa.postman_environment.json \
  --env-var "apiKey=LA_API_KEY" \
  --delay-request 5000
```

Duración esperada: ~5 minutos. Con un delay menor la corrida choca contra `429 RATE_LIMITED`; la assertion transversal *"La cuota de requests no está agotada"* lo hace visible de inmediato en vez de dejar fallos crípticos.

---

## 6. Resumen

| Métrica | Semana 02 | Semana 03 |
|---|---|---|
| Carpetas | 11 | **15** |
| Requests en la colección | 38 | **52** |
| Requests ejecutados (incluye SQL) | 39 | **69** (58 REST + 11 SQL) |
| Assertions | 341 | **455** |
| Assertions contra base de datos | 0 | **11** |
| Endpoints cubiertos | 5 | **6 de 6** (RF-G6-01 a 06) |
| Escenarios BDD con request asociado | 8 de 9 | **9 de 9** |
| Hallazgos abiertos | 2 | **2** (HG06-01 cerrado, HG06-03 nuevo) |
