# Patrón SQL REST dinámico — pre-request + post-response

Versión completa del patrón resumido en `SKILL.md` → *Database Verification (SQL Sandbox)*.
Úsala cuando el endpoint necesita **más de un caso** (feliz + negativo) o cuando la colección
ya tiene más de un request golpeando `/api/v1/sql/select` — a partir de ahí vale la pena el
helper reutilizable en vez de repetir el bloque de `pm.sendRequest` en cada script.

Requiere el contrato de `POST /api/v1/sql/select` — ver skill `sandbox` →
`references/sql-endpoint.md` (guardrails, whitelist de tablas, forma de la respuesta
`{ data, rowCount }`).

## Las 2 ideas del patrón

1. **Un helper declarado una sola vez**, en el Pre-request Script de la **colección** (no el de
   cada request) — corre antes de cada request, así que es el lugar correcto para declarar algo
   que todos van a reutilizar.
2. **Solo el/los campo(s) que varían son `{{variable}}`** — nunca conviertas el body entero en
   una sola variable serializada. El body queda como JSON normal y legible; cada campo que
   puede cambiar entre casos tiene su propia collection variable con un valor por defecto.

## 1 — Pre-request Script de la colección

```javascript
// Corre antes de CADA request de la colección.
if (typeof utils === "undefined") {
  utils = {
    bodySqlRest: function (sql, params) {
      return {
        url: pm.collectionVariables.get("baseUrl") + "/api/v1/sql/select",
        method: "POST",
        header: {
          "Content-Type": "application/json",
          "x-api-key": pm.collectionVariables.get("apiKey"),
        },
        body: { mode: "raw", raw: JSON.stringify({ sql: sql, params: params || [] }) },
      };
    },
  };
}

// Defaults del body — una variable por cada campo que en algún caso va a variar.
// Se resetean ANTES DE CADA request (porque este script corre siempre primero).
pm.collectionVariables.set("cuentaOrigenId", 1);
pm.collectionVariables.set("cuentaDestinoId", 2);
pm.collectionVariables.set("monto", 25000);
pm.collectionVariables.set("descripcion", "Pago de alquiler - E2E");
```

`utils` vive en memoria durante la corrida — no es una Postman variable. Si corrés un request
suelto sin pasar por el pre-request de la colección (ej. un solo item desde el editor sin
correr la carpeta completa), `utils` no existe y tira `ReferenceError`. Correr la carpeta
completa, no un request aislado.

## 2 — Body del request

```json
{
  "cuentaOrigenId": {{cuentaOrigenId}},
  "cuentaDestinoId": {{cuentaDestinoId}},
  "monto": {{monto}},
  "descripcion": "{{descripcion}}"
}
```

Placeholder de número **sin comillas** (`{{monto}}` → `"monto": 25000`). Placeholder de string
**con comillas** (`"{{descripcion}}"` → `"descripcion": "Pago de alquiler - E2E"`).

## 3 — Caso feliz: Pre-request + Tests del request

Pre-request (no sobreescribe nada — usa los defaults; valida la precondición en la BD):

```javascript
const cuentaOrigenId = Number(pm.collectionVariables.get("cuentaOrigenId"));
const cuentaDestinoId = Number(pm.collectionVariables.get("cuentaDestinoId"));
const request = utils.bodySqlRest(
  "SELECT id, activa FROM cuentas WHERE id IN ($1, $2)",
  [cuentaOrigenId, cuentaDestinoId]
);
pm.sendRequest(request, (err, res) => {
  if (err) { console.error("Pre-request SQL check failed:", err); return; }
  const rows = res.json().data || [];
  console.log("cuenta origen activa?", rows.find((r) => r.id === cuentaOrigenId)?.activa);
});
```

Tests (post-response — valida la respuesta HTTP, después vuelve a consultar la BD para
confirmar que el INSERT/UPDATE realmente quedó persistido):

```javascript
pm.test("status 201", () => pm.response.to.have.status(201));

const body = pm.response.json();
pm.test("respuesta trae la fila insertada", () => {
  pm.expect(body.data).to.have.property("id");
  pm.expect(body.data.estado).to.eql("pendiente");
});

const id = body.data.id;
const request = utils.bodySqlRest(
  "SELECT id, estado FROM transferencias WHERE id = $1",
  [id]
);
pm.sendRequest(request, (err, res) => {
  pm.test("la BD confirma la fila con estado 'pendiente'", () => {
    const row = res.json().data[0];
    pm.expect(row, "no se encontró la fila en la BD").to.not.be.undefined;
    pm.expect(row.estado).to.eql("pendiente");
  });
});
```

## 4 — Caso negativo: sobreescribir UNA variable

Pre-request — sobreescribe **solo** el campo que arma el caso de borde; las demás variables
quedan en el default que puso el pre-request de la colección; guarda el `COUNT(*)` de ANTES:

```javascript
pm.collectionVariables.set("monto", -500); // única línea distinta del caso feliz

const request = utils.bodySqlRest("SELECT COUNT(*) AS total FROM transferencias");
pm.sendRequest(request, (err, res) => {
  pm.variables.set("totalAntes", res.json().data[0].total); // pm.variables: solo para este request
});
```

Tests — valida el status de rechazo, después confirma con un segundo `COUNT(*)` que **no se
insertó nada**:

```javascript
pm.test("status 400 (monto inválido)", () => pm.response.to.have.status(400));

const request = utils.bodySqlRest("SELECT COUNT(*) AS total FROM transferencias");
pm.sendRequest(request, (err, res) => {
  pm.test("la BD no registró ninguna fila nueva", () => {
    const totalDespues = res.json().data[0].total;
    pm.expect(Number(totalDespues)).to.eql(Number(pm.variables.get("totalAntes")));
  });
});
```

Usá `pm.variables` (no `pm.collectionVariables`) para datos que solo hacen falta **dentro de
ese mismo request** (como `totalAntes`) — evita que la colección se llene de variables que
nadie más necesita. `pm.variables` es el único scope compartido entre el Pre-request Script y
el Tests Script de un mismo request.

## Cuándo usar la versión completa vs. la simple

| Situación | Patrón |
|---|---|
| Un solo chequeo puntual, sin variantes | "Verificación simple" (ver `SKILL.md`) — 2 requests encadenados, sin helper. |
| Mismo endpoint con caso feliz + 1 o más negativos | Este patrón — helper + variables por campo. |
| Colección con varios endpoints que van a verificar BD | Este patrón — el helper se declara una sola vez y lo usan todos. |

## Ejemplo de referencia completo

Implementación real con 5 requests (INSERT, UPDATE transaccional, soft-delete, y 2 casos
negativos): `postman_collection.json` → carpeta `E2E - Flujos con validación SQL` en
[`aiquaa-sandbox-api`](https://github.com/stevenayal/aiquaa-sandbox-api). Guía paso a paso,
componente por componente: `docs/patron-postman-pre-post-request.pdf` en ese mismo repo.
