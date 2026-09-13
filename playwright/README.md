# Guía de inicio — Playwright + BDD

Guía práctica para arrancar con Playwright en este repo, usando el sandbox del curso
([`https://aiquaa-sandbox-web.vercel.app/`](https://aiquaa-sandbox-web.vercel.app/)) como sitio
bajo prueba, y un caso de prueba completo con estructura BDD (Gherkin + Cucumber + Playwright).

> Para generación asistida (specs, Page Objects, CI, informe PDF) también está disponible
> [`skills/playwright-skill`](../skills/playwright-skill). Esta guía es la base manual —
> entendé el flujo primero, después apoyate en la skill para ir más rápido.

---

## 1. Prerrequisitos

| Herramienta | Versión mínima |
|-------------|----------------|
| Node.js     | 18 LTS o superior |
| npm         | incluido con Node.js |

---

## 2. Comandos iniciales

```bash
# 1. Instalar dependencias del proyecto (ya incluye @playwright/test y @cucumber/cucumber)
npm install

# 2. Instalar el navegador Chromium (el que usa este proyecto)
npx playwright install chromium

# 3. Copiar variables de entorno
cp .env.example .env
```

`BASE_URL` en `.env` / `playwright.config.ts` ya apunta al sandbox del curso:

```
https://aiquaa-sandbox-web.vercel.app/
```

Comandos de uso diario:

```bash
npx playwright test                 # correr toda la suite E2E (headless)
npx playwright test --headed        # con navegador visible
npx playwright test --ui            # modo UI, ideal para aprender/debuggear
npx playwright test --debug         # debug paso a paso
npx playwright codegen <url>        # graba clicks y genera código automáticamente
npx playwright show-report          # abre el último reporte HTML
```

Equivalentes ya definidos en `package.json`:

```bash
npm run test:e2e          # playwright test
npm run test:e2e:headed   # playwright test --headed
npm run smoke              # solo tests/e2e/smoke.spec.ts
npm run test:bdd:demo      # corre el caso BDD de ejemplo de esta guía (ver sección 4)
```

---

## 3. El sitio bajo prueba

El sandbox (`https://aiquaa-sandbox-web.vercel.app/`) sirve una pantalla de login en `/`
(redirige a `/auth/login`). Es una app Next.js — el HTML inicial casi no trae contenido
porque todo se renderiza por JavaScript, así que para inspeccionarla hay que abrirla con un
navegador real (`npx playwright codegen https://aiquaa-sandbox-web.vercel.app/`), no con un
fetch simple.

Elementos verificados del formulario de login (`data-testid`):

| `data-testid`                    | Elemento                                    |
|-----------------------------------|----------------------------------------------|
| `auth-login-form`                 | `<form>` de login                             |
| `auth-login-field-email`          | input de email                                |
| `auth-login-submit`               | botón "Ingresar" — **deshabilitado** mientras el campo email está vacío |
| `auth-login-field-email-error`    | mensaje de error, aparece tras enviar un email no registrado (texto: *"Usuario no encontrado o inactivo."*) |

Es un login sin contraseña (por email de usuario seedeado en el sandbox) — de ahí el lenguaje
"sesión seeded para la cohorte..." que ya usan `features/auth.feature` y `features/checkout.feature`.

---

## 4. Caso de prueba de ejemplo (estructura BDD)

La estructura BDD de este repo tiene 3 capas:

```
features/
  demo-login.feature          ← 1. Escenarios en Gherkin (el "qué")
tests/bdd/
  steps/
    web.steps.ts               ← 2. Steps: traducen cada línea Gherkin a Playwright (el "cómo")
  support/
    world.ts                   ← 3. World: contexto compartido (browser/page) por escenario
    hooks.ts                   ← 3. Hooks: abre/cierra el navegador antes/después de cada escenario
cucumber.js                    ← configuración de Cucumber (paths, ts-node, reporters)
```

### 4.1 Feature — `features/demo-login.feature`

```gherkin
Feature: Login en el sandbox AIQUAA
  Como estudiante del curso
  Quiero ver un ejemplo minimo de escenario BDD contra el sandbox
  Para replicar el patron en mis propios features

  Scenario: El boton de ingresar arranca deshabilitado
    Given que estoy en la página "/"
    Then el elemento "auth-login-submit" esta deshabilitado

  Scenario: Login con un usuario no registrado muestra error controlado
    Given que estoy en la página "/"
    When completo el campo "auth-login-field-email" con "estudiante-demo@aiquaa.com"
    And hago click en "auth-login-submit"
    Then veo el elemento "auth-login-field-email-error"
    And el elemento "auth-login-field-email-error" contiene el texto "Usuario no encontrado"
```

### 4.2 Steps — `tests/bdd/steps/web.steps.ts`

Steps genéricos, reutilizables por `data-testid` (no hace falta escribir un step nuevo por
cada pantalla — solo agregar escenarios en Gherkin que reusen estos verbos):

```typescript
import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AiquaaWorld } from '../support/world';

Given('que estoy en la página {string}', async function (this: AiquaaWorld, ruta: string) {
  await this.page!.goto(ruta);
});

When('completo el campo {string} con {string}',
  async function (this: AiquaaWorld, testid: string, valor: string) {
    await this.page!.getByTestId(testid).fill(valor);
  });

When('hago click en {string}', async function (this: AiquaaWorld, testid: string) {
  await this.page!.getByTestId(testid).click();
});

Then('veo el elemento {string}', async function (this: AiquaaWorld, testid: string) {
  await expect(this.page!.getByTestId(testid)).toBeVisible();
});

Then('el elemento {string} contiene el texto {string}',
  async function (this: AiquaaWorld, testid: string, texto: string) {
    await expect(this.page!.getByTestId(testid)).toContainText(texto);
  });

Then('el elemento {string} esta deshabilitado', async function (this: AiquaaWorld, testid: string) {
  await expect(this.page!.getByTestId(testid)).toBeDisabled();
});
```

### 4.3 World — `tests/bdd/support/world.ts`

```typescript
import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';
import { Browser, Page, chromium } from '@playwright/test';

export class AiquaaWorld extends World {
  browser?: Browser;
  page?: Page;
  baseUrl = process.env.BASE_URL || 'https://aiquaa-sandbox-web.vercel.app/';

  constructor(options: IWorldOptions) { super(options); }

  async initWeb() {
    this.browser = await chromium.launch({ headless: process.env.HEADED !== 'true' });
    this.page = await this.browser.newPage({ baseURL: this.baseUrl });
  }

  async teardown() {
    await this.page?.close();
    await this.browser?.close();
  }
}

setWorldConstructor(AiquaaWorld);
```

### 4.4 Hooks — `tests/bdd/support/hooks.ts`

```typescript
import { Before, After, Status } from '@cucumber/cucumber';
import { AiquaaWorld } from './world';

Before(async function (this: AiquaaWorld) {
  await this.initWeb();
});

After(async function (this: AiquaaWorld, { result }) {
  if (result?.status === Status.FAILED && this.page) {
    const buffer = await this.page.screenshot();
    await this.attach(buffer, 'image/png');
  }
  await this.teardown();
});
```

### 4.5 Correrlo

```bash
npm run test:bdd:demo
# equivale a: npx cucumber-js --profile demo

# con el navegador visible:
HEADED=true npx cucumber-js --profile demo   # Linux/macOS
$env:HEADED="true"; npx cucumber-js --profile demo   # PowerShell
```

Salida esperada:

```
2 scenarios (2 passed)
7 steps (7 passed)
```

> `npm run test:bdd` (sin `:demo`) corre **todos** los `.feature` del repo, incluidos los de
> `grupos/`. Algunos features de grupos todavía tienen errores de sintaxis Gherkin propios de
> cada equipo — no afectan a este ejemplo, que corre aislado con `--profile demo`.

---

## 5. Cómo escribir tu propio escenario

1. Agregá el `Scenario` en tu `.feature` dentro de `features/` o `grupos/grupo-XX-modulo/features/`.
2. Si tu paso ya existe en `tests/bdd/steps/web.steps.ts` (navegar, completar campo, click,
   verificar visibilidad/texto/deshabilitado), no escribas un step nuevo — reusalo.
3. Si necesitás un verbo nuevo (ej: "veo N elementos", "selecciono la opción..."), agregalo en
   `tests/bdd/steps/` como una función más, siguiendo el mismo patrón `async function (this: AiquaaWorld, ...)`.
4. Preferí siempre `data-testid` sobre selectores CSS/texto — son más estables ante cambios visuales.

---

## 6. Selectores — orden de preferencia

```typescript
// 1. Por rol (accesible y estable)
page.getByRole('button', { name: 'Guardar' })

// 2. Por test-id (recomendado en este proyecto — el sandbox ya los expone)
page.getByTestId('auth-login-submit')

// 3. Por texto/label visible
page.getByText('Bienvenido')
page.getByLabel('Email')

// 4. CSS — último recurso
page.locator('.btn-primary')

// NUNCA — frágil, rompe con cualquier cambio de DOM
// page.locator('div > div:nth-child(3) > button')
```

---

## 7. Suites mínimas sugeridas (Playwright puro, sin BDD)

- `auth.spec.ts`
- `onboarding.spec.ts`
- `checkout.spec.ts`
- `negative.spec.ts`

Recomendaciones:

- usar `data-testid` cuando exista
- resetear o seedear antes del flujo
- dejar capturas en `evidence/`
- separar smoke vs regression

Smoke sugerido:

1. login válido
2. acceso al catálogo
3. add to cart
4. checkout

---

## 8. Troubleshooting

| Problema | Causa probable | Solución |
|----------|-----------------|----------|
| `Cannot find module 'ts-node'` | falta instalar dependencias | `npm install` |
| `element is not enabled` al hacer click en `auth-login-submit` | el campo email está vacío | completá el campo antes del click (el botón queda deshabilitado a propósito) |
| Parse errors en `grupos/**/*.feature` al correr `npm run test:bdd` | `.feature` de otro equipo con sintaxis Gherkin inválida | no es tuyo — usá `npm run test:bdd:demo` o apuntá a tu propio archivo: `npx cucumber-js features/tu-archivo.feature` |
| Timeout esperando un `data-testid` | el sitio es una SPA (Next.js) — el DOM tarda en montar | usá `waitUntil: 'networkidle'` en el `goto` o dejá que Playwright reintente (ya lo hace por defecto con `expect`) |
