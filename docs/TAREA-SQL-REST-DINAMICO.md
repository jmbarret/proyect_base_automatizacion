# Tarea grupal — Patrón SQL REST dinámico en Postman

**Fecha límite: viernes 4 de septiembre de 2026, 23:59.**
**Entrega: 1 Pull Request por grupo** de su rama (`grupo-XX-modulo`) hacia `main` en este
repositorio, siguiendo el flujo de [`docs/FLUJO_SEMANAL.md`](./FLUJO_SEMANAL.md) y la plantilla
de PR del repo.

## Objetivo

Aplicar a un endpoint de escritura de **su propio módulo** el patrón de automatización
end-to-end que se explica en [`docs/patron-postman-pre-post-request.pdf`](./patron-postman-pre-post-request.pdf)
y que ya está implementado como ejemplo en la carpeta `E2E - Flujos con validación SQL` de
[`postman/aiquaa Sandbox API.json`](../postman/aiquaa%20Sandbox%20API.json) (recién actualizada
con la última versión del patrón — impórtenla de nuevo en Postman si ya tenían una copia vieja).

En criollo: que el POST/PATCH/DELETE de su módulo no se dé por "probado" solo porque devolvió el
status code esperado — hay que **volver a consultar la base de datos** (vía
`/api/v1/sql/select`, de solo lectura) antes y después de la operación, para confirmar que
realmente pasó lo que tenía que pasar.

## Por qué esta tarea

Todas las colecciones armadas hasta ahora (la propia de cada grupo y la copia de
`aiquaa Sandbox API.json`) tienen **cero validación de base de datos** — solo assertions sobre
la respuesta HTTP (`pm.response.to.have.status(...)`, algún `pm.expect(jsonData...)`). Esta
tarea agrega la segunda mitad de lo que hace falta para decir que un endpoint está realmente
probado: que la operación quedó reflejada en la BD, no solo que la API respondió bien.

## Cómo funciona el patrón (resumen — el detalle completo está en el PDF)

1. **Pre-request Script de la COLECCIÓN** (ícono de la colección → pestaña *Scripts* →
   *Pre-request script*): se declara **una sola vez** el helper `utils.bodySqlRest(sql, params)`
   que arma la consulta a `/api/v1/sql/select`, y se resetean a su valor por defecto las
   variables de colección que arma el body de su request (una variable por cada campo que en
   algún caso va a variar — **no todo el body**, ver sección 3.2 del PDF).
2. **Body del request**: JSON normal y legible, con `{{variable}}` solo en el/los campo(s) que
   necesitan cambiar entre casos.
3. **Pre-request Script del request**: valida la precondición en la BD (¿existe el dato? ¿está
   en el estado esperado antes de mutarlo?) y, si el caso es negativo, sobreescribe **una sola
   variable** con el valor inválido.
4. **Tests Script (post-response)**: valida el status code y la forma de la respuesta, y hace un
   segundo `pm.sendRequest` con `utils.bodySqlRest(...)` para releer la BD y confirmar el
   INSERT/UPDATE — o, en un caso negativo, que un `COUNT(*)` no cambió.

## Qué endpoint le toca a cada grupo

Usen el endpoint sugerido de su módulo (tabla y ruta según el README de
[`aiquaa-sandbox-api`](https://github.com/stevenayal/aiquaa-sandbox-api)). Si su equipo ya viene
automatizando otro endpoint de escritura de su propio módulo, pueden usar ese en su lugar —
lo importante es que sea un POST/PATCH/DELETE de **su** grupo, no de otro.

| Grupo | Endpoint sugerido | Tabla afectada | Notas |
|---|---|---|---|
| 01 — Autenticación y Acceso | `POST /api/v1/sesiones` | `sesiones` | INSERT simple; probar `usuarioId` inexistente como caso negativo (viola FK). |
| 02 — Transferencias entre Cuentas | `POST /api/v1/transferencias` | `transferencias` | **Ya está resuelto como ejemplo completo** en la carpeta E2E. Estudien ese ejemplo y agreguen un 3er caso propio (ej. `cuentaOrigenId === cuentaDestinoId`) que todavía no esté cubierto. |
| 03 — Pagos de Servicios | `POST /api/v1/facturas/{id}/pagar` | `facturas` + `pagos` | **Ya está resuelto como ejemplo completo.** Agreguen un caso propio (ej. pagar una factura ya `'pagada'` → 404, y confirmar que no se duplicó el pago). |
| 04 — Registro de Usuario / Onboarding | `PATCH /api/v1/usuarios/{id}/kyc` | `usuarios` (columna `kyc_estado`) | UPDATE simple; caso negativo con un `kyc_estado` fuera del CHECK permitido. |
| 05 — Tarjetas | `PATCH /api/v1/tarjetas/{id}/bloquear` (o `/activar`) | `tarjetas` (columna `estado`) | Verificar precondición: la tarjeta debe estar en el estado contrario antes de la acción. |
| 06 — Notificaciones y Alertas | `PATCH /api/v1/notificaciones/{id}/leer` | `notificaciones` (columna `leido`/`estado`) | Precondición: la notificación no debe estar ya marcada como leída. |
| 07 — Carrito / E-commerce | `POST /api/v1/ordenes` | `ordenes` + `items_orden` | INSERT en 2 tablas (transaccional); revisen `app/api/v1/ordenes/route.ts` en aiquaa-sandbox-api para el shape exacto del body (`items[]`). |
| 08 — Reservas / Turnos | `PATCH /api/v1/reservas/{id}/confirmar` (o `/cancelar`) | `reservas` (columna `estado`) | Precondición: la reserva debe estar `pendiente` antes de confirmar/cancelar. |
| 09 — Reportes y Dashboard | `POST /api/v1/movimientos` | `movimientos` | INSERT simple; caso negativo con `usuarioId` inexistente (FK). |
| 10 — Roles y Permisos | `DELETE /api/v1/usuarios/{id}/roles/{roleId}` | `usuario_roles` (columna `activo`) | **Ya está resuelto como ejemplo completo** (soft-delete). Agreguen el caso complementario: `POST /api/v1/usuarios/{id}/roles` para **asignar** un rol (INSERT/upsert) con su propia validación pre/post. |

Los grupos 02, 03 y 10 tienen su endpoint ya resuelto en el ejemplo de referencia — la tarea para
ellos es **entender el ejemplo y sumar un caso propio**, no copiarlo tal cual.

## Qué tienen que entregar

Agreguen esto a la colección Postman de **su propio grupo** (en `postman/`, duplicando/extendiendo
la carpeta correspondiente a su módulo dentro de `postman/aiquaa Sandbox API.json` si todavía no
tienen un archivo propio — ver [`postman/README.md`](../postman/README.md)):

- [ ] Pre-request Script de la colección con `utils.bodySqlRest` declarado una sola vez.
- [ ] Al menos un campo del body es `{{variable}}` — el resto del JSON queda igual de legible
      que un body fijo (no conviertan todo el body en una sola variable).
- [ ] **1 request "caso feliz"**: Pre-request valida la precondición en la BD; Test
      (post-response) valida el status esperado y relee la fila para confirmar el
      INSERT/UPDATE.
- [ ] **1 request "caso negativo"** (mínimo): sobreescribe una sola variable con un valor
      inválido; Test valida el status de rechazo y confirma — con `COUNT(*)` antes/después o
      releyendo el estado — que la base **no cambió**.
- [ ] Corre contra los ids reales de `scripts/seed-data.sql` de `aiquaa-sandbox-api` (no
      inventen ids que no existen en el seed).
- [ ] Evidencia de la corrida (captura del Postman Runner o salida de `newman run`) en la
      carpeta `evidence/` de su grupo.
- [ ] 1 Pull Request de su rama hacia `main`, con la descripción del avance (ver
      [`docs/FLUJO_SEMANAL.md`](./FLUJO_SEMANAL.md)).

Esto cuenta como parte de la sección **"3. API"** de [`ENTREGABLES.md`](../ENTREGABLES.md).

## Dudas

Cualquier duda puntual sobre una línea de script, compárenla contra los 5 requests de la carpeta
`E2E - Flujos con validación SQL` en `postman/aiquaa Sandbox API.json` — los comentarios `//`
de esos scripts siguen la misma numeración de pasos que el PDF.
