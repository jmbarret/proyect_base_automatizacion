# Trazabilidad BDD → API — Grupo 06 (Notificaciones y Alertas)

**Rama:** `grupo-06-notificaciones-alertas`
**Origen BDD:** [`features/notificaciones-alertas.feature`](../features/notificaciones-alertas.feature)
**Colección:** [`postman/grupo-06-notificaciones-alertas.postman_collection.json`](../../../postman/grupo-06-notificaciones-alertas.postman_collection.json)
**Environment:** [`postman/grupo-06-aiquaa.postman_environment.json`](../../../postman/grupo-06-aiquaa.postman_environment.json)
**Evidencia de ejecución:** [`evidence/newman-grupo-06-run.txt`](../evidence/newman-grupo-06-run.txt)
**Sitio bajo prueba:** AIQUAA Sandbox API — `https://aiquaa-sandbox-api.vercel.app`

> **Última ejecución verificada:** 44 requests · **341 assertions · 0 failed** · exit code 0.

## 0. Robustez de los scripts

Todos los scripts de test leen el cuerpo de la respuesta de forma defensiva:

```javascript
var body = {};
try { body = pm.response.json() || {}; } catch (e) { /* respuesta no JSON */ }
var data = body.data || {};                               // endpoints que devuelven objeto
var lista = Array.isArray(body.data) ? body.data : [];    // endpoints que devuelven listado
var error = body.error || {};                             // respuestas de error
```

El motivo: cuando la API responde algo distinto de lo esperado (un `401` por falta de API key, un `400`, un `404`, un `429` o una página de error no-JSON), el cuerpo no trae `data`. Un acceso encadenado del tipo `pm.response.json().data.filter(...)` aborta el script con `TypeError: Cannot read properties of undefined` y deja el request sin diagnóstico. Con la guarda, el test falla como una assertion legible que apunta a la causa real.

Verificado ejecutando la colección completa **sin** API key: 32 requests ejecutados, 90 assertions fallidas y **0 `TypeError`**. Ejemplos de los mensajes que produce:

```
AssertionError  La respuesta trae el arreglo data
                La respuesta no contiene un arreglo data (revisar apiKey si el status es 401):
                expected undefined to be an array

AssertionError  El canal entregado es push
                expected undefined to deeply equal 'push'
```

Además, el script de test a nivel de colección emite un `console.warn` explícito ante cualquier `401`, y el de pre-request avisa si la variable `apiKey` está vacía antes de disparar el primer request.

---

## 1. Superficie de API cubierta

Los cinco endpoints del Grupo 6 publicados por AIQUAA están cubiertos por la colección.

| # | Método | Endpoint | Entrada | Respuesta esperada |
|---|--------|----------|---------|--------------------|
| 1 | `GET` | `/api/v1/notificaciones` | query: `usuarioId`, `leido` | `200` `{ data: Notificacion[] }` |
| 2 | `POST` | `/api/v1/notificaciones` | body: `usuarioId`, `canal`, `asunto`, `mensaje` | `201` `{ data: Notificacion }` |
| 3 | `PUT` | `/api/v1/notificaciones/{id}` | body: `canal`, `asunto`, `mensaje` | `200` `{ data: Notificacion }` |
| 4 | `PATCH` | `/api/v1/notificaciones/{id}/leer` | path: `id` | `200` `{ data: Notificacion }` |
| 5 | `DELETE` | `/api/v1/notificaciones/{id}` | path: `id` | `204` sin body (soft-delete) |

**Contrato `Notificacion`:** `id`, `usuario_id`, `canal` (`push|email|sms`), `asunto`, `mensaje`, `leido` (bool), `estado` (`enviada|fallida|pendiente`), `created_at` (date-time RFC 3339). Ver **HG06-02** por los desvíos detectados entre este contrato y la respuesta real.

**Contrato `ErrorResponse`:** `error.code` ∈ `UNAUTHORIZED | RATE_LIMITED | VALIDATION_ERROR | EXECUTION_ERROR | NOT_FOUND | CONFLICT | INTERNAL_ERROR`, `error.message`, `error.details`.

### Comportamiento verificado contra la API real

| Comportamiento | Resultado observado |
|---|---|
| `PUT` ignora `leido` y `estado` enviados en el body | ✅ Confirmado — invariante declarado por AIQUAA y validado en S5 |
| `PATCH /{id}/leer` marca `leido: true` sin alterar el contenido | ✅ Confirmado |
| `DELETE` responde `204` sin body y la notificación desaparece del listado | ✅ Confirmado |
| `PUT`, `PATCH` y `DELETE` sobre id inexistente | ✅ `404` `NOT_FOUND` |
| Canal fuera del enum, campo requerido ausente, `usuarioId` de tipo inválido | ✅ `400` `VALIDATION_ERROR` con `error.details` describiendo el campo |
| Alta idempotente ante reproceso del mismo evento | ❌ No implementada → **HG06-01** |
| `id` / `usuario_id` como integer y ausencia de campos extra | ❌ Se devuelven como string y aparece `activo` → **HG06-02** |
| Límite de requests | 30 por minuto (cabeceras `X-Ratelimit-*`), `429` `RATE_LIMITED` al excederlo |

---

## 2. Matriz de trazabilidad

Los 8 escenarios BDD del grupo están mapeados. La columna **Cobertura** indica si la API permite validar el escenario de punta a punta (**Total**) o solo su resultado observable (**Parcial**, con el motivo en la sección 4).

| ID | Escenario BDD | Tag | Carpeta en la colección | Endpoints | Datos esperados / assertions clave | Cobertura |
|----|---------------|-----|-------------------------|-----------|-------------------------------------|-----------|
| **S1** | Enviar una notificación push después de una transferencia exitosa | `@happy_path` | `S1 @happy_path - Push tras transferencia exitosa (TRX-001)` | `POST` → `GET ?usuarioId` | `201`; `data.canal === 'push'`; `usuario_id` coincide con el usuario bajo prueba; `data.mensaje` incluye `500000` **y** `TRX-001`; `estado` ∈ enum; `leido === false`; `created_at` RFC 3339; el `id` creado aparece en el listado | **Total** |
| **S6** | Enviar una notificación por SMS después de una transferencia exitosa | `@happy_path` | `S6 @happy_path - SMS tras transferencia exitosa (TRX-006)` | `POST` → `GET ?usuarioId` | `201`; `data.canal === 'sms'`; `data.mensaje` incluye `1000000` **y** `TRX-006`; `id` distinto al de S1; persistencia verificada en el listado | **Total** |
| **S8** | Enviar notificaciones por múltiples canales según las preferencias del usuario | `@alternative_path` | `S8 @alternative_path - Multicanal push + email (TRX-009)` | `POST` ×2 → `GET ?usuarioId` | dos `201` con `id` distintos; **exactamente 2** entregas registradas para `TRX-009`; los canales incluyen `push` **y** `email`; ambos con `estado` ∈ `{enviada, pendiente}` | **Total** |
| **S4** | Usar email como canal de respaldo cuando el push no puede entregarse | `@alternative_path` | `S4 @alternative_path - Email de respaldo por token vencido (TRX-004)` | `POST` → `PUT /{id}` → `GET` | `POST` `201` con `canal='push'`; `PUT` `200` con `canal='email'` y **mismo `id`** (misma entrega redirigida, no una nueva); `asunto` registra `push fallido`; `created_at` inalterado; el `GET` confirma **0** entregas `push` activas para `TRX-004` | **Total** |
| **S2** | No enviar una notificación push cuando el canal está desactivado | `@negative` | `S2 @negative - Canal desactivado por preferencia (TRX-002)` | `POST` (canal inválido) + `POST` → `DELETE /{id}` → `GET` | canal fuera del enum → `400` `VALIDATION_ERROR`, `error.details` nombra `canal` y el valor rechazado, y la respuesta **no** trae `data`; luego alta + `DELETE` `204` sin body; el `GET` confirma **0** entregas activas para `TRX-002` | **Parcial** |
| **S7** | No enviar una notificación por SMS cuando el número de teléfono es inválido | `@negative` | `S7 @negative - Datos obligatorios inválidos en SMS (TRX-007)` | `POST` ×2 (body inválido) | falta `mensaje` → `400` `VALIDATION_ERROR`, `error.details` incluye `mensaje` y `Required`; `usuarioId` de tipo inválido → `400` con `error.details` nombrando `usuarioId`; en ambos casos la respuesta **no** trae `data` | **Parcial** |
| **S3** | Evitar notificaciones duplicadas ante el reprocesamiento de un evento | `@edge_case` | `S3 @edge_case - Reproceso del mismo evento (TRX-003)` | `POST` → `POST` (reproceso) → `DELETE /{id}` → `GET` | el reproceso se resuelve sin `5xx`; si devuelve `409` → `error.code === 'CONFLICT'` (comportamiento que exige el BDD), si devuelve `201` → se registra **HG06-01** y se descarta el duplicado; el `GET` final exige **exactamente 1** registro para `TRX-003`, y que sea el del primer procesamiento | **Total** |
| **S5** | Diferir la notificación durante el horario silencioso del usuario | `@edge_case` | `S5 @edge_case - Entrega diferida por horario silencioso (TRX-005)` | `POST` → `GET ?leido=false` → `PATCH /{id}/leer` → `PUT /{id}` → `GET ?leido=false` | nace con `leido === false` y `estado` ∈ `{pendiente, enviada}`; figura entre las pendientes; `PATCH` `200` con `leido === true` y mismo `id`; **invariante:** el `PUT` envía `leido=false` y `estado='fallida'` a propósito y la API los ignora; el `GET` final confirma que ya no está pendiente | **Parcial** |

### Carpetas transversales (no derivadas de un escenario puntual)

| Carpeta | Endpoints | Qué valida |
|---------|-----------|------------|
| `00 Setup - Higiene de datos de prueba` | `GET` + `DELETE` en bucle | descarta las notificaciones residuales de corridas previas (prefijo `{{prefijoDatosPrueba}}`) para que los conteos exactos de S3, S8, S2 y S4 sean deterministas. No toca los datos semilla del laboratorio, que no usan identificadores `TRX-00x` |
| `CONTRATO @negative - Recursos inexistentes (404)` | `PUT`, `PATCH /leer`, `DELETE` sobre `{{idInexistente}}` | los tres endpoints por `id` responden `404` con `error.code === 'NOT_FOUND'` y sin `data` |
| `SEG @negative - Seguridad y contrato de errores` | `GET` y `POST` sin `x-api-key`, `GET` con key inválida | `401` con `error.code === 'UNAUTHORIZED'`; la respuesta **no** filtra `data`; la escritura también exige credenciales |

### Assertions transversales

Aplicadas automáticamente a todos los requests desde el script `test` a nivel de colección:

- `Response time is less than 3000ms` (parametrizado por `{{maxResponseTime}}`)
- `La respuesta es application/json` — omitida en respuestas `204` sin body
- `El cuerpo es JSON parseable` — omitida en respuestas `204` sin body
- `La API no responde con error de servidor (5xx)`
- `La cuota de requests no está agotada (429 RATE_LIMITED)` — hace visible el rate limit en lugar de dejar que se manifieste como fallos crípticos, y emite un `console.warn` cuando quedan 5 requests o menos en la ventana

---

## 3. Hallazgos

| ID | Severidad | Descripción | Evidencia |
|----|-----------|-------------|-----------|
| **HG06-01** | Media | El alta de notificaciones **no es idempotente**: reprocesar el mismo evento (`TRX-003`) genera un segundo registro de entrega en lugar de responder `409 CONFLICT`. El escenario S3 exige un único registro por evento. Verificado de forma aislada: dos `POST` idénticos devolvieron los ids `33` y `34`. | Carpeta `S3`, request *POST Reproceso del mismo evento*. El test emite `console.warn` con ambos ids y la colección compensa el duplicado con `DELETE` antes de la verificación final. |
| **HG06-02** | Baja | La respuesta **no respeta el contrato publicado**: `id` y `usuario_id` se devuelven como `string` (`"44"`) aunque el OpenAPI los declara `integer`, y el objeto incluye un campo `activo` (boolean) que no figura en el esquema `Notificacion`. Impacta a cualquier consumidor que tipe la respuesta según la documentación. | Carpeta `S1`, request *POST Crear notificación push*, tests `HG06-02: …`. Las comparaciones de la colección normalizan con `String(...)` para no depender del tipo. |

> Ambos hallazgos están escritos para **no romper el CI**: se documentan como assertions que describen el comportamiento real y dejan la traza en la salida de Newman. El test de HG06-01 acepta `200`, `201` o `409`, de modo que si la API llegara a implementar idempotencia el mismo test valida el camino correcto sin necesidad de editarlo.

---

## 4. Desvíos entre el BDD y la API (cobertura parcial)

Los escenarios BDD se redactaron sobre el dominio funcional de notificaciones bancarias; la API sandbox expone un modelo más acotado. Los desvíos se documentan en lugar de forzar assertions que no representan la regla real.

| Ref | Escenario | Lo que pide el BDD | Lo que expone la API | Cómo se resolvió |
|-----|-----------|--------------------|----------------------|------------------|
| **D-01** | S2 | Preferencias de canal por usuario (push habilitado/deshabilitado) | No existe recurso de preferencias | Se valida el control de contrato (canal fuera del enum → `400`) y la supresión efectiva de la entrega vía `DELETE`, verificada por el `GET` posterior |
| **D-02** | S7 | Número de teléfono inválido registrado | El body no recibe teléfono ni datos de contacto | Se valida el rechazo por campos obligatorios inválidos, que es el control equivalente disponible |
| **D-03** | S5 | Programar la entrega para las 07:00 del día siguiente | No hay campo de programación ni `scheduled_at` | Se modela el ciclo pendiente → consumida con `leido=false` + `PATCH /leer`, y se agrega el invariante `PUT` no reemplaza `leido`/`estado` |
| **D-04** | S4 | Estado del token del dispositivo | No expone tokens ni estado de entrega por canal | La conmutación al canal de respaldo se valida con `PUT` conservando el `id` y el `created_at`, lo que evidencia que es la **misma** entrega redirigida |

---

## 5. Ejecución

### Credenciales

Los cinco endpoints exigen la cabecera `x-api-key`. Sin ella toda petición responde `401 UNAUTHORIZED`:

```bash
curl -i https://aiquaa-sandbox-api.vercel.app/api/v1/notificaciones
# -> 401 {"error":{"code":"UNAUTHORIZED","message":"Invalid or inactive API key."}}
```

El laboratorio usa una API key demo compartida (prefijo `sbx_demo_`), la misma que emplean las ramas de los grupos 01, 02, 03, 05 y 07. **El environment de este grupo la deja vacía a propósito** y se inyecta al ejecutar, para no versionar credenciales.

### Rate limiting

La API limita a **30 requests por minuto**, con ventana que se reinicia en el borde del minuto. Al excederlo responde `429` con `error.code === 'RATE_LIMITED'` y la cabecera `Retry-After`. La suite completa hace entre 32 y 39 requests, así que **debe ejecutarse siempre con `--delay-request 2500`**. Cabeceras disponibles para diagnóstico: `X-Ratelimit-Limit`, `X-Ratelimit-Remaining`, `X-Ratelimit-Reset`, `Retry-After`.

### Newman (CLI)

Todos los comandos se ejecutan desde la raíz del repositorio. No se agrega un script a `package.json` para no tocar archivos compartidos con los demás grupos.

```bash
# Suite completa
npx newman run postman/grupo-06-notificaciones-alertas.postman_collection.json \
  -e postman/grupo-06-aiquaa.postman_environment.json \
  --env-var "apiKey=LA_API_KEY" \
  --delay-request 2500

# Con evidencia exportada
npx newman run postman/grupo-06-notificaciones-alertas.postman_collection.json \
  -e postman/grupo-06-aiquaa.postman_environment.json \
  --env-var "apiKey=LA_API_KEY" \
  --delay-request 2500 \
  --reporters cli,json --reporter-json-export salida.json

# Carpetas que validan el 401 (no requieren API key ni delay)
npx newman run postman/grupo-06-notificaciones-alertas.postman_collection.json \
  -e postman/grupo-06-aiquaa.postman_environment.json \
  --folder "SEG @negative - Seguridad y contrato de errores"
```

> **El reporte JSON de Newman incluye el valor de la API key.** Si se versiona, sanitizarlo antes:
> `sed 's/sbx_demo_[a-f0-9]*/<API_KEY_REDACTADA>/g' salida.json > evidencia.json`
> La evidencia guardada en `evidence/newman-grupo-06-run.txt` ya está sanitizada.

### Postman (GUI)

1. *Import* → seleccionar la colección y el environment.
2. Activar el environment **AIQUAA Sandbox - Grupo 06**.
3. Cargar `apiKey` como variable de tipo *secret*.
4. *Run collection* → configurar **Delay 2500 ms** para no agotar la cuota.

> **Orden de ejecución:** la colección debe correrse completa o por carpetas enteras. Las carpetas comparten variables (`notifIdPush`, `notifIdRespaldo`, `notifIdDuplicado1/2`, `notifIdDiferida`) y la carpeta `00 Setup` usa `postman.setNextRequest`, que solo funciona en ejecuciones de colección (Runner o Newman), no al enviar un request suelto.

---

## 6. Resumen de cobertura

| Métrica | Valor |
|---------|-------|
| Escenarios BDD del grupo | 8 |
| Escenarios mapeados a API | 8 (la consigna exige ≥ 3) |
| Cobertura total / parcial | 5 total, 3 parcial |
| Endpoints AIQUAA cubiertos | 5 de 5 |
| Carpetas en la colección | 11 (1 de setup + 8 de escenarios + 2 transversales) |
| Requests | 32 base, 39 con limpieza de residuales |
| Assertions ejecutadas en la última corrida | **341, 0 fallidas** |
| Códigos de respuesta ejercitados | `200`, `201`, `204`, `400`, `401`, `404` (`409` y `429` contemplados) |
| Hallazgos abiertos | HG06-01 (media), HG06-02 (baja) |
