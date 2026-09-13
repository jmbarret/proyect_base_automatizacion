---
name: postman-newman
description: >
  Automate Postman collections with Newman. Generate, run, analyze, and maintain
  Postman collections and Newman CI pipelines. Use when user says "run postman",
  "newman", "create postman collection", "add test to postman", "postman to CI",
  "update collection", "postman environment", "run collection", or shows a
  .postman_collection.json / .postman_environment.json file, a curl command,
  a URL, an OpenAPI spec, or any API-related file. Auto-triggers for any
  Postman/Newman workflow: authoring, running, debugging, or CI integration.
---

Newman run collection. Claude write tests. Terse output. No fluff.

---

## Context Intake — ALWAYS run this first

**Before doing anything else, collect context.** No exceptions. Not one line of collection JSON gets written without knowing what API is being tested.

The user might give you nothing, a URL, a curl, a collection, a spec, source code, or everything at once. Your job is to figure out what's missing and ask — one question at a time, most important first. Never dump a list of 10 questions. Never start generating without the mandatory fields.

---

### Step 1 — Detect what the user already gave you

Scan the conversation for these signals and mark each as known or missing:

| Signal | What it tells you |
|--------|------------------|
| Full URL (e.g. `https://api.example.com/v1/users`) | baseUrl + endpoint path |
| curl command | method + url + headers + body (partial or full) |
| `C_*.json` collection file | existing requests, may have tests or not |
| `E_*.json` environment file | baseUrl, existing variables, auth tokens |
| OpenAPI / Swagger spec | full contract: endpoints, schemas, validations |
| Validator / DTO source code | exact field rules — most valuable for negative tests |
| Enum source code | valid values per field — required for enum edge cases |
| Newman JSON results | failures to fix |
| "just a URL" with no other info | almost nothing — need to ask |

---

### Step 2 — Ask for what's missing (one question at a time)

Work through this priority order. Stop after the first unanswered question and wait for the response before asking the next.

#### Priority 1 — The URL (always mandatory)

If you don't have a full base URL yet, ask:

> ¿Cuál es la URL base de la API? Ejemplo: `https://api.miempresa.com` o `http://localhost:5000`
>
> Si tenés un curl, pegalo directamente — lo proceso yo.

Do not proceed without this. "la API de usuarios" is not a URL. A path like `/users` without a host is not a URL.
If the user gives only a path, ask for the host. If they give only a host, ask for the paths.

#### Priority 2 — The endpoint(s)

If you have the base URL but no endpoints, ask:

> ¿Qué endpoints querés cubrir? Podés darme cualquiera de esto:
>
> - Lista directa: `GET /users`, `POST /users`, `DELETE /users/:id`
> - Un curl: `curl -X POST https://... -H "..." -d "..."`
> - Archivo OpenAPI/Swagger (JSON o YAML)
> - Código fuente de los endpoints (cualquier lenguaje)
>
> Si no sabés qué endpoints tiene la API, compartí la URL del Swagger si existe — ejemplo: `http://localhost:5000/swagger`

If the user gives a curl, extract from it: method, full URL, headers, body. Echo back what you extracted and ask "¿es correcto?" before continuing.

#### Priority 3 — The request body (for POST / PUT / PATCH)

If the method is POST, PUT, or PATCH and you don't have the body schema, ask:

> Para `<METHOD> <endpoint>` necesito la estructura del body. Podés darme:
>
> - Un JSON de ejemplo: `{ "name": "valor", "email": "valor" }`
> - El modelo o DTO del backend (C#, Java, TypeScript, Python, lo que sea)
> - El archivo de validaciones (FluentValidation, Zod, Joi, Pydantic, etc.)
>
> Sin esto no puedo saber qué campos son obligatorios ni qué validaciones cubrir.

Never invent field names. If the user says "ya sabés el body" but you don't — ask again.

#### Priority 4 — Authentication

If the API might require auth and you haven't been told it's public, ask:

> ¿La API requiere autenticación?
>
> - Sin auth (pública)
> - Bearer token → ¿ya tenés el token o hay un endpoint de login (`POST /auth/login`)?
> - API Key → ¿en qué header va? ¿cómo se llama?
> - Basic Auth
> - Otro

If Bearer with login endpoint: ask for the login endpoint URL + body (user/password fields). You'll add the login request as the first item in the collection and chain the token automatically.

If Bearer with static token: ask if the token goes in the `E_*.json` environment file or in CI secrets.

#### Priority 5 — Existing collection

If generating new tests and there might be an existing collection, ask:

> ¿Ya tenés una colección `C_*.json`? Compartila si existe — la expando sin pisar lo que ya tenés.
> Si no hay colección, genero desde cero.

#### Priority 6 — Validation rules (for negative test generation)

If the user asks for negative tests, edge cases, or "validaciones de campos vacíos" and you don't have validator source code, ask:

> Para generar casos negativos (campos vacíos, valores inválidos, límites de largo, enums fuera de rango) necesito las reglas de validación. Podés darme:
>
> - El archivo de validadores del backend (`Validators.cs`, `validators.py`, `schema.ts`, etc.)
> - O decirme manualmente: qué campos son obligatorios, límites de largo, valores permitidos en campos de tipo enum
>
> Sin esto los casos negativos son aproximados — te lo aviso si tengo que adivinar.

#### Priority 7 — CI target (only for `/postman:ci`)

Ask only when the user invokes `/postman:ci`:

> ¿Qué plataforma de CI usás?
> - GitHub Actions
> - Azure Pipelines
> - Otra (decime cuál)

#### Priority 8 — YML personalizado (only for `/postman:ci`)

Ask only when the user invokes `/postman:ci`, after Priority 7:

> ¿Tenés un workflow de CI existente que quieras que tome como base?
> - Sí → compartilo (pegá el contenido o el path) — lo adapto para Newman sin romper lo que ya tiene
> - No → genero desde cero con el template estándar

If the user shares an existing YML: read it, identify the existing jobs/steps, and inject the Newman job without removing or breaking anything already there. Confirm what you're adding and what you're preserving before writing the final file.

---

#### Priority 9 — Metadata del informe (opcional, para el reporte PDF)

Ask once, after confirming the base context. These are optional — skip if the user seems in a hurry:

> Para el informe PDF, ¿tenés esta info? (todo opcional, podés saltar lo que no tenés)
>
> - **Versión o release** de la API que se va a probar — ejemplo: `v1.2.0`, `Release 2024-Q2`, o el link del release: `https://github.com/org/repo/releases/tag/v1.2.0`
> - **Link del repositorio** de la API — ejemplo: `https://github.com/org/repo`
>
> Si los tenés, los muestro en la portada del informe. Si no, no pasa nada.

Store whatever the user provides as:
- `api_version` — string (version number, label, or release URL)
- `repo_url` — string (repository URL)

Pass both to the report generator via `--api-version` and `--repo-url` flags.

---

### Step 3 — Confirm understanding before generating

Once you have enough to proceed, confirm in this format before writing any JSON:

```
CONTEXTO DETECTADO:
  API:          <nombre o descripción>
  BASE URL:     <url completa>
  ENDPOINTS:    <lista de METHOD /path>
  AUTH:         <tipo o "ninguna">
  BODY:         <esquema conocido o "no proporcionado">
  VALIDACIONES: <fuente o "no proporcionadas — casos negativos serán aproximados">
  COLECCIÓN:    <C_*.json existente o "nueva desde cero">
  VERSIÓN API:  <versión / link release o "no proporcionada">
  REPO:         <url o "no proporcionado">
  SALIDA:       C_<NOMBRE>.json + E_<NOMBRE>.json [+ Y_<NOMBRE>.yml si aplica]

¿Confirmas o corregís algo antes de que genere?
```

Wait for confirmation. Then generate.

---

### Escalation rules

- User gives only "quiero testear mi API" → ask Priority 1
- User gives a curl with no body for a POST → ask Priority 3
- User pastes a URL and says "generá los tests" → ask Priorities 2, 3, 4 in sequence
- User gives source code in unknown language → read it, extract what you can, confirm understanding before generating
- User gives a Swagger URL → fetch it, extract endpoints and schemas from it, confirm before generating
- User says "agregá más tests" with no collection → ask Priority 5 first
- User says "arreglá el test roto" with no error → ask for Newman JSON output or the exact error message
- User says "ya te dije todo" but context is incomplete → list exactly what you still need, one item

---

## File Naming Convention

**Always use this naming pattern. No exceptions.**

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Colección | `C_NOMBRE_DE_API.json` | `C_MYTHS_API.json` |
| Environment | `E_NOMBRE_DE_API.json` | `E_MYTHS_API.json` |
| Pipeline CI | `Y_NOMBRE_DE_API.yml` | `Y_MYTHS_API.yml` |

Rules:
- `NOMBRE_DE_API` = UPPER_SNAKE_CASE
- Un set de tres archivos por API
- Mismo nombre base en los tres — nunca divergir
- Múltiples environments: sufijo → `E_MYTHS_API_STAGING.json`, `E_MYTHS_API_PROD.json`

```
tests/
  postman/
    C_MYTHS_API.json
    E_MYTHS_API.json
    E_MYTHS_API_STAGING.json
.github/
  workflows/
    Y_MYTHS_API.yml
```

---

## Stack

- Collections: Postman Collection v2.1 (JSON)
- Runner: Newman (Node.js CLI)
- Reporters: `cli`, `json`, `htmlextra`
- Environments: `.postman_environment.json`
- Languages for pre-request / test scripts: JavaScript (pm.* API)
- CI targets: GitHub Actions (`Y_*.yml` en `.github/workflows/`), Azure Pipelines (`Y_*.yml` en `azure-pipelines/`)

---

## Commands

| Trigger | Action |
|---------|--------|
| `/postman:run` | Run collection with Newman, report results terse |
| `/postman:add-test` | Add pm.test assertions to existing request |
| `/postman:generate` | Generate collection from spec / source / curl / URL |
| `/postman:fix` | Fix failing test — analyze error, patch script |
| `/postman:ci` | Generate `Y_NOMBRE.yml` — GitHub Actions o Azure Pipelines |
| `/postman:env` | Create or update environment file |

---

## Rules

Drop: "It looks like...", "I'd suggest...", "You might want to...". Fragments OK. Technical terms exact.

**Output format for run result (`/postman:run`):**

```
COLLECTION: <name>
ENV: <environment name>
RESULT: ✅ PASS <n> | ❌ FAIL <n> | ⏭ SKIP <n>
DURATION: <ms>ms

FAILURES (if any):
  ❌ <request name> → <test name>
     GOT: <actual>
     EXPECTED: <expected>
     FIX: <one-line action>
```

**Output format for test authoring (`/postman:add-test`):**

```
REQUEST: <name>
ADDED:
  ✅ status is 200
  ✅ body has id
  ✅ response time < 500ms
SCRIPT:
  <pm.test block — code only>
```

**Output format for failure analysis (`/postman:fix`):**

```
TEST: <test name>
REQUEST: <method> <url>
STATUS: 🔴 ROTO | 🟡 FLAKY | 🔵 DESACTUALIZADO
CAUSA: <one line>
FIX: <one line or code patch>
CONFIANZA: ALTA | MEDIA | BAJA
```

---

## Postman Script Patterns

### Standard assertions

```javascript
pm.test("status is 200", () => pm.response.to.have.status(200));

pm.test("body has id", () => {
  pm.expect(pm.response.json()).to.have.property("id");
});

pm.test("response time < 500ms", () => pm.expect(pm.response.responseTime).to.be.below(500));
```

### Variable chaining (POST → GET → DELETE)

```javascript
// POST test script
pm.environment.set("resourceId", pm.response.json().id);

// GET url: {{baseUrl}}/resource/{{resourceId}}

// DELETE cleanup
pm.environment.unset("resourceId");
```

### Login y guardar token

```javascript
// POST /auth/login test script
pm.environment.set("token", pm.response.json().access_token);
```

### Auth header pre-request

```javascript
pm.request.headers.add({
  key: "Authorization",
  value: `Bearer ${pm.environment.get("token")}`
});
```

---

## Database Verification (SQL Sandbox)

When the API under test is the course sandbox (`aiquaa-sandbox-api`), close the
**action → database verification** loop with `POST /api/v1/sql/select`. See skill
`sandbox` → `references/sql-endpoint.md` for the full contract (guardrails, table
whitelist, `rowCount`). Only use this pattern against APIs that expose an equivalent
SQL endpoint — don't assume it exists elsewhere.

Two levels. Pick based on what the request actually needs.

### Simple — one-off verify, no variants

Two separate collection items chained via environment variable. Fine for a single
check with no negative case.

```javascript
// Request 1 — POST /api/v1/ordenes
// test script:
pm.test("status 201", () => pm.response.to.have.status(201));
pm.environment.set("ordenId", pm.response.json().data.id);
pm.environment.set("montoEsperado", pm.response.json().data.monto);
```

```javascript
// Request 2 — POST /api/v1/sql/select
// body:
// {
//   "sql": "SELECT monto FROM ordenes WHERE id = $1",
//   "params": [{{ordenId}}]
// }
// test script:
pm.test("row exists", () => pm.expect(pm.response.json().rowCount).to.equal(1));
pm.test("monto persisted matches API response", () => {
  const persisted = pm.response.json().data[0].monto;
  pm.expect(persisted).to.equal(Number(pm.environment.get("montoEsperado")));
});
```

### Full pattern — SQL REST dinámico (pre-request + post-response)

Use when the endpoint needs a happy path **and** at least one negative/edge case, or
when more than one request in the collection hits `/api/v1/sql/select` — the reusable
helper stops the same 10-line `pm.sendRequest` block from being copy-pasted everywhere.
Two ideas: (1) declare a `utils.bodySqlRest(sql, params)` helper **once**, in the
**collection's** Pre-request Script; (2) only the field(s) that vary between cases are
`{{variable}}` — never the whole body serialized into one variable.

```javascript
// Collection-level Pre-request Script — runs before EVERY request.
if (typeof utils === "undefined") {
  utils = {
    bodySqlRest: (sql, params) => ({
      url: pm.collectionVariables.get("baseUrl") + "/api/v1/sql/select",
      method: "POST",
      header: {
        "Content-Type": "application/json",
        "x-api-key": pm.collectionVariables.get("apiKey"),
      },
      body: { mode: "raw", raw: JSON.stringify({ sql, params: params || [] }) },
    }),
  };
}
pm.collectionVariables.set("monto", 25000); // one line per field that can vary
```

Body: `{ "monto": {{monto}}, ... }` — number placeholders unquoted, string placeholders
quoted.

Request-level Pre-request (negative case — override ONE variable, everything else
keeps its default):

```javascript
pm.collectionVariables.set("monto", -500);
const request = utils.bodySqlRest("SELECT COUNT(*) AS total FROM transferencias");
pm.sendRequest(request, (err, res) => pm.variables.set("totalAntes", res.json().data[0].total));
```

Tests (post-response — assert rejection, then confirm nothing landed in the DB):

```javascript
pm.test("status 400", () => pm.response.to.have.status(400));
const request = utils.bodySqlRest("SELECT COUNT(*) AS total FROM transferencias");
pm.sendRequest(request, (err, res) => {
  pm.test("no row inserted", () => {
    pm.expect(Number(res.json().data[0].total)).to.eql(Number(pm.variables.get("totalAntes")));
  });
});
```

Full worked example (happy path + 2 negative cases, plus the precondition-check side of
the pre-request) → `references/sql-prerequest-pattern.md`.

### Case that must fail — table whitelist

```javascript
// body: { "sql": "SELECT * FROM api_keys" }
pm.test("rejected — table outside qa_training whitelist", () => {
  pm.response.to.have.status(400);
  pm.expect(pm.response.json().error.code).to.equal("VALIDATION_ERROR");
});
```

⚠️ Every verification request also counts against the sandbox rate limit
(30 req/min per `x-api-key`) — factor it into collection size.

---

## Newman CLI Reference

```bash
# Basic run
newman run tests/postman/C_NOMBRE_DE_API.json \
  -e tests/postman/E_NOMBRE_DE_API.json

# Con reporters
newman run tests/postman/C_NOMBRE_DE_API.json \
  -e tests/postman/E_NOMBRE_DE_API.json \
  -r cli,json,htmlextra \
  --reporter-json-export results/output.json \
  --reporter-htmlextra-export results/report.html

# Fail on first error — siempre en CI
newman run tests/postman/C_NOMBRE_DE_API.json \
  -e tests/postman/E_NOMBRE_DE_API.json \
  --bail
```

---

## CI Pipeline Templates

### GitHub Actions — `.github/workflows/Y_NOMBRE_DE_API.yml`

```yaml
name: Newman — NOMBRE DE API
on:
  push:
    branches: [main, develop]
  pull_request:
jobs:
  newman:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - name: Install Newman
        run: npm install -g newman newman-reporter-htmlextra
      - name: Run collection
        run: |
          newman run tests/postman/C_NOMBRE_DE_API.json \
            -e tests/postman/E_NOMBRE_DE_API.json \
            -r cli,json,htmlextra \
            --reporter-json-export results/newman-results.json \
            --reporter-htmlextra-export results/newman-report.html \
            --bail
      - name: Upload report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: newman-report
          path: results/
```

### Azure Pipelines — `azure-pipelines/Y_NOMBRE_DE_API.yml`

```yaml
trigger:
  branches:
    include: [main, develop]
pool:
  vmImage: ubuntu-latest
steps:
  - task: NodeTool@0
    inputs:
      versionSpec: '20.x'
    displayName: Setup Node
  - script: npm install -g newman newman-reporter-htmlextra
    displayName: Install Newman
  - script: |
      newman run tests/postman/C_NOMBRE_DE_API.json \
        -e tests/postman/E_NOMBRE_DE_API.json \
        -r cli,json,htmlextra \
        --reporter-json-export $(Build.ArtifactStagingDirectory)/newman-results.json \
        --reporter-htmlextra-export $(Build.ArtifactStagingDirectory)/newman-report.html \
        --bail
    displayName: Run Newman
  - task: PublishBuildArtifacts@1
    condition: always()
    inputs:
      pathToPublish: $(Build.ArtifactStagingDirectory)
      artifactName: newman-report
    displayName: Upload report
```

---

## Common Failures & Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Cannot read property of undefined` | json() on non-JSON response | Assert status first, check Content-Type |
| `{{resourceId}}` empty | POST test script failed silently | console.log(json.id), check POST status |
| `expected 404 to equal 200` | Wrong baseUrl or service down | Verify env file, ping /health |
| All pass locally, fail in CI | Env variable missing in CI | Add to GitHub Secret or pipeline variable |
| Flaky timing | Threshold too tight for CI | Use below(1000) for CI |
| `ECONNREFUSED` | Service not running | Start service before newman run |
| 401 on all requests | Token expired or not set | Check token env var, re-run login request |
| 400 on valid-looking request | Missing Content-Type | Add Content-Type: application/json header |

---

## Auto-Clarity

Drop terse for: auth bypass or token leak findings, schema breaking changes affecting multiple consumers, env variable renames requiring migration. Resume terse after.

## Boundaries

Writes collection JSON, test scripts, environment files, Newman CLI commands, CI workflows.
Does NOT run Newman — outputs commands ready to execute.
Does NOT import into Postman UI — outputs files ready to import.
Does NOT invent field names, validation rules, or enum values — asks if unknown.
"stop postman-newman" or "normal mode": revert to verbose style.
