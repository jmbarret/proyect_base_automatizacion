---
name: bdd
description: >
  Automatización BDD con Cucumber (cucumber-js) + Playwright en TypeScript.
  Genera archivos .feature en Gherkin, step definitions reutilizables para
  API, web y verificación en base de datos, configuración cucumber.js,
  pipelines CI y reportes PDF con matriz de trazabilidad. Compatible con el
  stack aiquaa (caveman mode incluido) y con el entorno de práctica del curso
  (ver skill sandbox).
  Usar cuando el usuario mencione "BDD", "Gherkin", "cucumber", "feature file",
  "Given When Then", "steps", "escenario", "criterios de aceptación", o pida
  convertir requisitos/documentos/historias de usuario en pruebas automatizadas.
  Auto-activa para cualquier flujo BDD: autoría de features, steps, ejecución,
  fix o CI.
---

BDD write feature. Claude generate steps. Terse output. No fluff.

---

## ¿Qué es BDD en este contexto?

BDD (Behavior-Driven Development) describe comportamiento en lenguaje natural estructurado
(Gherkin: `Given/When/Then`) y lo ejecuta como prueba automatizada real. El archivo `.feature`
es el documento vivo — mismo texto para el docente, el alumno y el pipeline de CI.

Stack de esta skill:

- **Gherkin** — archivos `.feature`, texto plano, legible por humanos y por CI.
- **cucumber-js** — runner que conecta `.feature` con step definitions TypeScript.
- **Playwright** — motor debajo de los steps: `request` fixture para API, `page` para web.
- **Base de datos** — steps de verificación vía `POST /api/v1/sql/select` del sandbox
  (ver skill `sandbox` para el contrato completo — nunca inventar campos o tablas).

Un mismo `.feature` puede mezclar pasos de API, web y BD en el mismo escenario — es lo que
enseña el ciclo completo: **acción → efecto visible → efecto persistido**.

---

## Context Intake — SIEMPRE ejecutar primero

**Antes de generar cualquier archivo, recolectar contexto.** Sin excepciones.
Una pregunta a la vez, en orden de prioridad. Nunca generar `.feature` ni steps sin al menos
el grupo/módulo y el tipo de prueba.

### Paso 1 — Detectar qué ya dio el usuario

| Señal | Qué aporta |
|-------|-----------|
| "grupo 3" / "pagos de facturas" | módulo, endpoints y tablas — resolver con skill `sandbox` → `references/grupos.md` |
| Documento / imagen de requisitos | pasar primero por `ocr-bdd-skill` si no está ya en texto |
| `.feature` existente | expandir sin pisar escenarios ya escritos |
| Steps `.steps.ts` existentes | reusar antes de generar nuevos — evitar duplicar definiciones |
| URL o curl de un endpoint puntual | suficiente para un escenario `@api` aislado |
| "quiero probar el login" sin más | casi nada — preguntar |

### Paso 2 — Preguntar lo que falta

#### Prioridad 1 — Grupo / módulo del curso

> ¿Qué grupo del curso es? (1 a 10 — o el nombre del módulo si no es del sandbox)
>
> Con el número resuelvo endpoints y tablas desde la skill `sandbox`.

#### Prioridad 2 — Tipo de escenario

> ¿Qué capa probamos?
>
> - **API** — request/response contra el sandbox
> - **Web** — flujo de navegador contra el front (`data-testid`)
> - **API + BD** — acción por API, verificación en base de datos
> - **Web + API + BD** — flujo completo de punta a punta
>
> Si no especificás, hago API + BD — es el mínimo que cierra el ciclo.

#### Prioridad 3 — Criterios de aceptación

> ¿Tenés los criterios de aceptación o la historia de usuario? Pegalos, o decime el flujo en tus
> palabras: qué hace el usuario, qué debería pasar, qué NO debería pasar.
>
> Si viene de un documento/imagen que todavía no está en texto, uso primero `ocr-bdd-skill`.

Nunca inventar un criterio de aceptación no dado. Si falta, generar el escenario con
`# TODO: confirmar criterio de aceptación` en vez de asumir.

#### Prioridad 4 — Datos de prueba

> ¿Usamos datos sembrados del sandbox (usuarios, cuentas, etc. ya existentes) o generamos datos
> nuevos en el escenario (`Background` con un `POST` de setup)?
>
> Recordar: las escrituras del sandbox no están aisladas — mejor que cada escenario cree su
> propio dato cuando el flujo es de creación.

#### Prioridad 5 — Casos negativos

> ¿Incluyo casos negativos? El sandbox ya tiene fixtures listos:
> - usuarios inactivos (id 4, 8, 13) → login debe fallar
> - ids inexistentes → 404
> - email/documento duplicado → 400 `EXECUTION_ERROR`
>
> ¿Agrego alguno de estos o tenés otros en mente?

### Paso 3 — Confirmar antes de generar

```
CONTEXTO DETECTADO:
  GRUPO:        <n> — <módulo>
  CAPA:         API | Web | API+BD | Web+API+BD
  ENDPOINTS:    <lista>
  TABLAS:       <tablas a verificar o "sin verificación en BD">
  CRITERIOS:    <resumen o "TODO — confirmar">
  DATOS:        <sembrados | generados en Background>
  NEGATIVOS:    <lista o "ninguno">
  SALIDA:       F_GRUPO_<NN>_<MODULO>.feature + S_<capa>.steps.ts (si son nuevos)

¿Confirmás o corregís algo antes de que genere?
```

Esperar confirmación. Luego generar.

---

## Reglas de escritura Gherkin

- **`Feature`** = el módulo del grupo, una línea, sin implementación.
- **`Scenario`** declarativo — describe **qué** se verifica, nunca **cómo** (sin selectores,
  sin URLs, sin JSON crudo en el texto del escenario — eso vive en los steps).
- **`Scenario Outline` + `Examples`** para variar solo los datos de entrada, no el flujo.
- **`Background`** solo para lo que se repite en *todos* los escenarios del feature —
  típicamente autenticación (`Given que tengo una API key válida`). No abusar: un Background
  largo esconde precondiciones que deberían ser explícitas en cada escenario.
- **Tags obligatorios**: `@grupo-N` siempre. Agregar `@api`, `@web`, `@db` según capa,
  `@smoke` para el subconjunto rápido de CI, `@negativo` para casos de error.
- Un escenario, un comportamiento. Si el `When` tiene más de una acción de negocio, partirlo.

### Ejemplo mínimo

```gherkin
@grupo-1 @api
Feature: Autenticación y Acceso

  Background:
    Given que tengo una API key válida

  Scenario: Login exitoso con usuario activo
    When hago login con el email "ana.torres@example.com"
    Then la respuesta tiene status 200
    And el campo "activo" de la respuesta es true

  @negativo
  Scenario: Login falla con usuario inactivo
    When hago login con el email del usuario inactivo con id 4
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"
```

---

## Catálogo de steps reutilizables

Esto es lo central de la skill: **no reescribir un step por escenario.** Los steps abajo son
parametrizados — un escenario nuevo debería poder armarse combinándolos, sin tocar `.steps.ts`.

### Autenticación (`S_api.steps.ts`)

```gherkin
Given que tengo una API key válida
Given que tengo una API key inválida
```

### Requests genéricos — API (`S_api.steps.ts`)

```gherkin
When hago GET a "{endpoint}"
When hago GET a "{endpoint}" con query {"usuarioId": 7}
When hago POST a "{endpoint}" con body:
  """
  { "usuarioId": 7, "monto": 100 }
  """
When hago PATCH a "{endpoint}" con body:
  """
  { "kycEstado": "verificado" }
  """
When hago DELETE a "{endpoint}"
```

`{endpoint}` acepta placeholders con valores guardados en pasos anteriores:
`"/api/v1/ordenes/{ordenId}"`.

### Assertions — API (`S_api.steps.ts`)

```gherkin
Then la respuesta tiene status {int}
Then el campo "{jsonPath}" de la respuesta es {value}
Then el campo "{jsonPath}" de la respuesta existe
Then la respuesta tiene un array "data" con {int} elementos
Then el código de error es "{code}"
```

### Guardar valores entre steps (`S_api.steps.ts` + `world.ts`)

```gherkin
Then guardo el campo "{jsonPath}" de la respuesta como "{alias}"
```

Guarda en `this.context[alias]` (World) para reusar en un step posterior —
p. ej. capturar `data.id` de un `POST` y usarlo en el `GET` siguiente.

### Web (`S_web.steps.ts`)

```gherkin
Given que estoy en la página "{ruta}"
When completo el campo "{testid}" con "{valor}"
When hago click en "{testid}"
Then veo el elemento "{testid}"
Then el elemento "{testid}" contiene el texto "{texto}"
```

`{testid}` es siempre un `data-testid` — ver skill `sandbox` →
`references/web-testids.md` para la convención `{modulo}-{elemento}[-{id}][-{accion}]`.
Nunca un selector CSS ni texto visible en un step web.

### Base de datos (`S_db.steps.ts`)

```gherkin
Then en la base de datos, "{tabla}" tiene {int} fila(s) con "{columna}" igual a "{valor}"
Then en la base de datos, "{tabla}" con id "{alias}" tiene "{columna}" igual a "{valor}"
Then en la base de datos, no existe ninguna fila en "{tabla}" con "{columna}" igual a "{valor}"
```

Estos steps llaman internamente a `POST /api/v1/sql/select` con params — **nunca** interpolan
el valor directamente en el string SQL. Cada llamada consume una petición del rate limit
(30/min) — avisar si el escenario ya tiene varias.

### Anti-patrón — qué NO hacer

```gherkin
# MAL — URL literal repetida, no reutilizable, rompe si cambia el endpoint
When hago un POST a "https://aiquaa-sandbox-api.vercel.app/api/v1/ordenes" con headers
  x-api-key: sbx_alumno01_abc123
  y body { "usuarioId": 7, "items": [...] }
```

```gherkin
# BIEN — parametrizado, la URL base y la key viven en world.ts / .env
When hago POST a "/api/v1/ordenes" con body:
  """
  { "usuarioId": 7, "items": [{"producto": "Mouse", "cantidad": 1, "precioUnitario": 15.5}] }
  """
```

---

## Estructura de proyecto

```
tests/
  bdd/
    features/
      F_GRUPO_01_AUTENTICACION.feature
      F_GRUPO_02_TRANSFERENCIAS.feature
    steps/
      S_api.steps.ts
      S_web.steps.ts
      S_db.steps.ts
    support/
      world.ts
      hooks.ts
    cucumber.js
results/
  cucumber-report.json
  INFORME_BDD_<NOMBRE>.pdf
```

## Convención de nombres

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Feature | `F_GRUPO_NN_MODULO.feature` | `F_GRUPO_03_PAGOS.feature` |
| Steps | `S_<capa>.steps.ts` | `S_api.steps.ts`, `S_web.steps.ts`, `S_db.steps.ts` |
| Pipeline CI | `Y_<NOMBRE>_bdd.yml` | `Y_GRUPO_03_bdd.yml` |
| Informe PDF | `INFORME_BDD_<NOMBRE>.pdf` | `INFORME_BDD_GRUPO_03.pdf` |

`NN` = número de grupo con cero a la izquierda. `MODULO` = UPPER_SNAKE_CASE.

---

## `world.ts` — contexto compartido entre steps

```ts
import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';
import { APIRequestContext, request } from '@playwright/test';

export class SandboxWorld extends World {
  apiContext!: APIRequestContext;
  baseUrl = process.env.SANDBOX_API_BASE_URL ?? 'http://localhost:3000';
  apiKey = process.env.SANDBOX_API_KEY ?? '';
  lastResponse: any;
  lastStatus = 0;
  context: Record<string, unknown> = {}; // valores guardados entre steps

  constructor(options: IWorldOptions) {
    super(options);
  }

  async init() {
    this.apiContext = await request.newContext({
      baseURL: this.baseUrl,
      extraHTTPHeaders: this.apiKey ? { 'x-api-key': this.apiKey } : {},
    });
  }
}

setWorldConstructor(SandboxWorld);
```

## `hooks.ts` — setup/teardown

```ts
import { Before, After, Status } from '@cucumber/cucumber';
import { SandboxWorld } from './world';

Before(async function (this: SandboxWorld) {
  await this.init();
});

After(async function (this: SandboxWorld, { result }) {
  if (result?.status === Status.FAILED && (this as any).page) {
    const screenshot = await (this as any).page.screenshot();
    this.attach(screenshot, 'image/png');
  }
  await this.apiContext?.dispose();
});
```

## `cucumber.js`

```js
module.exports = {
  default: {
    paths: ['tests/bdd/features/**/*.feature'],
    require: ['tests/bdd/steps/**/*.ts', 'tests/bdd/support/**/*.ts'],
    requireModule: ['ts-node/register'],
    format: ['progress', 'json:results/cucumber-report.json'],
    formatOptions: { snippetInterface: 'async-await' },
    publishQuiet: true,
  },
};
```

---

## Ejecución CLI — referencia rápida

```bash
npm install -D @cucumber/cucumber @playwright/test ts-node typescript
npx playwright install --with-deps chromium

# correr todo
npx cucumber-js

# solo un grupo
npx cucumber-js --tags "@grupo-3"

# solo smoke, sin abrir navegador salvo que el step lo pida
npx cucumber-js --tags "@smoke"

# dry-run — valida que todos los steps existen, no ejecuta nada
npx cucumber-js --dry-run

# un feature puntual
npx cucumber-js tests/bdd/features/F_GRUPO_03_PAGOS.feature
```

---

## Verificación en base de datos — resumen

Detalle completo en la skill `sandbox` → `references/sql-endpoint.md`. Patrón dentro de un step:

```ts
Then('en la base de datos, {string} con id {string} tiene {string} igual a {string}',
  async function (this: SandboxWorld, tabla: string, alias: string, columna: string, valor: string) {
    const id = this.context[alias];
    const res = await this.apiContext.post('/api/v1/sql/select', {
      data: { sql: `SELECT ${columna} FROM ${tabla} WHERE id = $1`, params: [id] },
    });
    const body = await res.json();
    if (body.data[0][columna] != valor) {
      throw new Error(`esperado ${valor}, encontrado ${body.data[0][columna]}`);
    }
  });
```

⚠️ `tabla` y `columna` llegan del `.feature` — en un proyecto real, validar contra un whitelist
local antes de interpolar en el SQL (el sandbox ya valida tablas, pero nunca confiar solo en
validación del lado servidor para evitar SQL injection en el propio step).

---

## Pipeline CI — plantillas

Ver `examples/Y_EXAMPLE_BDD_github.yml` y `examples/Y_EXAMPLE_BDD_azure.yml`.
Ambas corren `npx cucumber-js --tags "@smoke"` en cada push y el suite completo en `main`,
publican el JSON de resultados como artefacto, y generan `INFORME_BDD_*.pdf` con `continueOnError`
en el paso de tests y `condition: always()` en el de reporte — mismo patrón que las otras skills.

---

## Informe PDF (`reporter/bdd_report.py`)

```bash
pip install reportlab

python reporter/bdd_report.py \
  --results results/cucumber-report.json \
  --grupo "Grupo 3 — Pagos de Servicios" \
  --author "Nombre — email@empresa.com"
```

Contenido: portada, resumen (escenarios pasados/fallados/pendientes), **matriz de trazabilidad**
(criterio de aceptación → escenario → resultado) cuando el `.feature` tiene comentarios
`# criterio: <texto>` sobre cada `Scenario`, detalle de pasos fallidos, veredicto.

---

## Formato de salida — análisis de resultados (`/bdd:report`)

```
FEATURE: F_GRUPO_<NN>_<MODULO>.feature
ESCENARIOS: <n> total — <n> ✅ pasados — <n> ❌ fallados — <n> ⏳ pendientes

FALLOS (si hay):
  ❌ <Scenario> → step "<texto del step>"
     CAUSA: <una línea>
     FIX:   <acción>

VEREDICTO: ✅ criterios cumplidos | ⚠️ parcial | ❌ criterios no cumplidos
```

---

## Fallos comunes y fixes

| Síntoma | Causa | Fix |
|---------|-------|-----|
| `Undefined step` | texto del step no coincide con ningún `.steps.ts` | revisar el catálogo de steps reutilizables antes de escribir uno nuevo |
| Step ambiguo (`Ambiguous`) | dos definiciones con regex que matchean el mismo texto | unificar en una sola definición parametrizada |
| 429 a mitad de escenario | rate limit del sandbox (30/min) | reducir steps de verificación en BD, o repartir escenarios entre varias keys |
| `TypeError: Cannot read properties of undefined` en step de BD | el alias no fue guardado en un step anterior | revisar orden de ejecución y el step "guardo el campo ... como ..." |
| Screenshot no adjunto en fallo | `hooks.ts` no encuentra `this.page` | confirmar que el step web inicializó `this.page` en el World |
| `EXECUTION_ERROR` en step de creación | email/documento UNIQUE ya sembrado | generar el dato con `Date.now()` o UUID en vez de un valor fijo en el `.feature` |

---

## Auto-Clarity

Salir de caveman para: criterios de aceptación ambiguos o contradictorios (aclarar antes de
generar), hallazgos de seguridad durante la escritura de steps de BD, y cuando el usuario pide
explicar la diferencia entre BDD y testing tradicional. Retomar caveman después.

## Boundaries

Escribe `.feature`, `.steps.ts`, `world.ts`, `hooks.ts`, `cucumber.js`, pipelines CI.
NO ejecuta cucumber — da los comandos listos.
NO inventa criterios de aceptación ni endpoints — usa la skill `sandbox` o pregunta.
NO interpola valores de usuario directo en SQL sin params — siempre `$N` + `params`.
"stop bdd" o "normal mode": volver a estilo verbose.
