---
name: playwright
description: >
  Automatización de pruebas E2E y de API con Microsoft Playwright. Genera tests
  en TypeScript, configuración playwright.config.ts, fixtures, page objects,
  pipelines Azure Pipelines y reportes PDF ejecutivos con capturas de pantalla
  y veredicto por suite. Compatible con el stack aiquaa (caveman mode incluido).
  Usar cuando el usuario mencione "playwright", "pruebas e2e", "end to end",
  "automatización web", "page object", "test.spec.ts", "chromium", "firefox",
  "webkit", o pida automatizar flujos de navegador o APIs con Playwright.
  Auto-activa para cualquier flujo Playwright: autoría, ejecución, debug o CI.
---

Playwright test write. Claude generate spec. Terse output. No fluff.

---

## ¿Qué es Playwright en este contexto?

Microsoft Playwright ejecuta pruebas E2E contra navegadores reales (Chromium, Firefox, WebKit)
y también pruebas de API HTTP sin navegador (`request` fixture). Es el estándar moderno para
automatización web — más rápido que Selenium, con soporte nativo para TypeScript y Azure DevOps.

Casos de uso cubiertos por esta skill:
- **E2E web** — flujos de usuario completos (login → navegar → acción → assert)
- **API testing** — requests HTTP con assertions sobre response, sin necesidad de Newman/Hurl
- **Visual testing** — comparación de capturas de pantalla (snapshot testing)
- **Validaciones externas** — SMS OTP, emails, estados en BD consultados vía API interna

---

## Context Intake — SIEMPRE ejecutar primero

**Antes de generar cualquier archivo, recolectar contexto.** Sin excepciones.
El usuario puede dar nada, una URL, un flujo descrito en texto, código fuente o una spec.
Identificar qué falta y preguntar — una pregunta a la vez, en orden de prioridad.

---

### Paso 1 — Detectar qué ya dio el usuario

| Señal | Qué aporta |
|-------|-----------|
| URL completa (`https://app.miempresa.com`) | baseURL para playwright.config.ts |
| Descripción de flujo ("el usuario hace login y ve el dashboard") | casos de prueba a generar |
| Código fuente de la página (HTML, React, Vue, Angular) | selectores reales — evitar inventar |
| Archivo `.spec.ts` existente | tests previos — expandir sin pisar |
| Archivo `playwright.config.ts` existente | configuración actual — respetar y extender |
| Page Object existente | clase a usar o extender |
| Spec OpenAPI / Swagger | endpoints para API tests sin navegador |
| Credenciales de prueba mencionadas | usuario/contraseña para fixtures de auth |
| URL de API interna de validación (SMS/BD) | endpoint para verificar notificaciones o estado |
| "quiero probar mi app" sin más | casi nada — preguntar |

---

### Paso 2 — Preguntar lo que falta (una pregunta a la vez)

Trabajar en este orden. Esperar respuesta antes de pasar a la siguiente.

#### Prioridad 1 — La URL base (siempre obligatoria)

> ¿Cuál es la URL de la aplicación a testear?
> Ejemplo: `https://app.miempresa.com` o `http://localhost:4200`
>
> Si es una API sin UI, también sirve: `https://api.miempresa.com`

No continuar sin esto.

#### Prioridad 2 — Tipo de prueba

> ¿Qué tipo de prueba necesitás?
>
> - **E2E web** — automatizar flujos en el navegador (login, formularios, navegación)
> - **API** — testear endpoints HTTP sin navegador (similar a Hurl pero con TypeScript)
> - **Ambos** — flujo web + validación de API en el mismo test
> - **Visual** — comparación de capturas de pantalla (snapshot testing)

Si E2E web o ambos → continuar con Prioridad 3.
Si solo API → saltar a Prioridad 5.

#### Prioridad 3 — El flujo a automatizar

> Describí el flujo que querés automatizar en lenguaje natural.
> Ejemplo:
> - "El usuario entra a /login, ingresa usuario y contraseña, hace click en Iniciar sesión
>   y debe ver el dashboard con su nombre en el header"
> - "El usuario se registra, recibe un SMS con un código OTP y lo ingresa para activar la cuenta"
>
> Si tenés el código fuente de la página, compartilo — extraigo los selectores reales.
> Si no, voy a usar selectores por rol y texto (más estables que IDs o clases CSS).

#### Prioridad 4 — Autenticación web

> ¿La app requiere login?
>
> - No (pública)
> - Sí → ¿tenés credenciales de prueba? (usuario y contraseña de un usuario de test)
> - Sí, con SSO / OAuth → ¿hay un bypass para tests o hay que manejar el redirect?
>
> Si hay login: genero un `auth.setup.ts` que guarda el estado de sesión en
> `playwright/.auth/user.json` y lo reutiliza en todos los tests (storageState).
> Los tests no vuelven a hacer login — corren directamente autenticados.

#### Prioridad 5 — Endpoints de API (si aplica)

> ¿Qué endpoints de API querés cubrir con Playwright?
>
> - Lista directa: `POST /api/auth/login`, `GET /api/users`
> - Spec OpenAPI / Swagger (URL o archivo)
> - Curl de ejemplo
>
> Playwright API tests usan el fixture `request` — no abren navegador, son más rápidos.

#### Prioridad 6 — Browsers a usar

> ¿En qué navegadores querés correr los tests?
>
> - Solo Chromium (más rápido, default)
> - Chromium + Firefox
> - Chromium + Firefox + WebKit (Safari) — suite completa, más lento
>
> Default si no especificás: **Chromium solamente**.

#### Prioridad 7 — Validaciones externas: SMS / notificaciones / estado en BD (opcional)

> ¿El flujo que vas a testear dispara alguna notificación o guarda datos en BD
> que también necesitás validar dentro del test?
>
> Ejemplos comunes:
> - SMS con código OTP (registro, login de dos factores, recuperación de contraseña)
> - Email de confirmación o link de activación
> - Estado de un registro en BD (ej: "el pedido quedó en estado CONFIRMADO")
> - Push notification o mensaje interno del sistema
>
> Si sí → ¿tenés una **API interna** que consulta la BD o el gateway de notificaciones?
>
> Necesito saber:
> 1. URL de la API de validación — ej: `https://api-interna.empresa.com/test/sms/latest`
> 2. ¿Requiere autenticación? (Bearer token, API Key, ninguna)
> 3. ¿Qué devuelve? — ej: `{ "code": "123456", "phone": "+595...", "createdAt": "..." }`
> 4. ¿Qué campo del response necesitás validar? — ej: `$.code`, `$.status`, `$.message`
> 5. Tiempo máximo de espera para que llegue la notificación — ej: 15 segundos
>
> Si no tenés API propia → ¿usás algún servicio de testing como:
> - **Twilio Test Credentials** (sandbox para SMS sin costo)
> - **AWS SNS Sandbox**
> - **Mailhog / Mailosaur / Mailtrap** (para emails)
> - **Mock API propia** que retorna datos de prueba
>
> Si no aplica o querés saltearlo → decime "no aplica" y pasamos a la siguiente.

Guardar si el usuario confirma:
- `notificationApiUrl` — URL de la API de validación
- `notificationApiToken` — token (va como `process.env.NOTIFICATION_API_TOKEN`)
- `notificationType` — `sms` | `email` | `push` | `db-state` | `otro`
- `notificationResponseField` — JSONPath del campo a validar (ej: `$.code`, `$.status`)
- `notificationTimeout` — ms de espera máxima (default: 15000)
- `notificationIdentifier` — campo para identificar el registro correcto (ej: número de teléfono, email, ID de pedido)

Con estos datos generar el helper `NotificationHelper.ts` y los steps de validación en el spec.

#### Prioridad 8 — Patrón de organización

> ¿Usamos Page Object Model (POM)?
>
> - **Sí** → genero clases en `pages/` con métodos por acción (recomendado para suites grandes)
> - **No** → tests directos sin abstracción (ok para suites pequeñas o pruebas rápidas)
>
> Default si no especificás: **Page Object Model**.

#### Prioridad 9 — Configuración CI

> ¿El pipeline es solo Azure Pipelines o también GitHub Actions?
>
> - Azure Pipelines
> - GitHub Actions
> - Ambos
>
> Default si no especificás: **Azure Pipelines**.

#### Prioridad 10 — Metadata del informe ejecutivo (opcional)

> Para el informe PDF ejecutivo, ¿tenés esta info? (todo opcional)
>
> - **Nombre de la aplicación** — ej: `Portal de Clientes`
> - **Versión** — ej: `v2.1.0`
> - **Link del repositorio** — ej: `https://dev.azure.com/org/repo`
> - **Autor** — ej: `Juan Pérez — juan@empresa.com`
> - **Ambiente** — ej: `QA`, `Staging`, `Producción`
>
> Si los tenés, aparecen en la portada del PDF.

---

### Paso 3 — Confirmar antes de generar

```
CONTEXTO DETECTADO:
  APP:             <nombre o descripción>
  BASE URL:        <url completa>
  TIPO:            <E2E web | API | Ambos | Visual>
  FLUJO:           <descripción del flujo a automatizar>
  AUTH:            <tipo o "ninguna">
  BROWSERS:        <Chromium | Chromium + Firefox | Suite completa>
  NOTIFICACIONES:  <SMS | Email | Push | DB-state | no aplica>
    API URL:       <url o "no aplica">
    CAMPO:         <jsonpath del valor a validar o "no aplica">
    TIMEOUT:       <ms o "15000 default">
    IDENTIFICADOR: <campo para filtrar el registro correcto>
  PATRÓN:          <Page Object Model | Tests directos>
  CI:              <Azure Pipelines | GitHub Actions | Ambos>
  AMBIENTE:        <QA | Staging | Producción | no especificado>
  VERSIÓN APP:     <versión o "no proporcionada">
  REPO:            <url o "no proporcionado">
  AUTOR:           <nombre o "anónimo">
  SALIDA:          T_<NOMBRE>.spec.ts [+ pages/<NOMBRE>Page.ts]
                   [+ helpers/NotificationHelper.ts si hay validaciones externas]
                   + playwright.config.ts
                   + Y_<NOMBRE>_playwright.yml
                   + INFORME_E2E_<NOMBRE>.pdf

¿Confirmás o corregís algo antes de que genere?
```

Esperar confirmación. Luego generar.

---

### Escalation rules

- Usuario dice "quiero probar mi app" → preguntar Prioridad 1
- Usuario da URL sin describir flujo → preguntar Prioridad 2 y 3
- Usuario describe flujo sin mencionar auth → preguntar Prioridad 4
- Usuario pide API tests → preguntar Prioridad 5
- Usuario menciona OTP / SMS / código / verificación / email de confirmación → activar Prioridad 7 aunque no haya sido preguntada aún
- Usuario dice "verificar que llegó el SMS" sin URL de API → preguntar la API de validación antes de generar
- Usuario dice "validar estado en la BD" → preguntar URL de API interna que expone ese estado
- Usuario pide "arreglá el test roto" sin error → pedir output de `npx playwright test` o el mensaje exacto
- Usuario dice "ya te dije todo" con contexto incompleto → listar exactamente qué falta, de a uno
- Usuario da código fuente HTML/React → activar protocolo de reconocimiento de componentes antes de generar specs

---

## Validaciones externas — patrones de código

### NotificationHelper.ts — helper genérico

```typescript
import { APIRequestContext, expect } from '@playwright/test';

export interface NotificationResult {
  found: boolean;
  value: string | null;
  raw: Record<string, unknown>;
}

export class NotificationHelper {
  private readonly request: APIRequestContext;
  private readonly apiUrl: string;
  private readonly apiToken: string;
  private readonly timeoutMs: number;
  private readonly pollIntervalMs: number;

  constructor(request: APIRequestContext, options?: {
    timeoutMs?: number;
    pollIntervalMs?: number;
  }) {
    this.request      = request;
    this.apiUrl       = process.env.NOTIFICATION_API_URL || '';
    this.apiToken     = process.env.NOTIFICATION_API_TOKEN || '';
    this.timeoutMs    = options?.timeoutMs    ?? 15000;
    this.pollIntervalMs = options?.pollIntervalMs ?? 2000;
  }

  // Espera con polling hasta que la API retorne el valor buscado
  async waitForNotification(
    identifier: string,   // nro de teléfono, email, ID de pedido
    field: string,        // campo del JSON a extraer: "code", "status", etc.
  ): Promise<NotificationResult> {
    const deadline = Date.now() + this.timeoutMs;

    while (Date.now() < deadline) {
      try {
        const response = await this.request.get(this.apiUrl, {
          headers: {
            'Authorization': `Bearer ${this.apiToken}`,
            'Content-Type': 'application/json',
          },
          params: { identifier },
        });

        if (response.ok()) {
          const body = await response.json();
          const value = this.extractField(body, field);
          if (value !== null && value !== undefined && value !== '') {
            return { found: true, value: String(value), raw: body };
          }
        }
      } catch {
        // reintentar
      }

      await new Promise(resolve => setTimeout(resolve, this.pollIntervalMs));
    }

    return { found: false, value: null, raw: {} };
  }

  private extractField(obj: Record<string, unknown>, field: string): unknown {
    // Soporte para dot notation: "data.code", "result.status"
    return field.split('.').reduce((acc: unknown, key) => {
      if (acc && typeof acc === 'object') {
        return (acc as Record<string, unknown>)[key];
      }
      return undefined;
    }, obj);
  }
}
```

### Caso de uso 1 — SMS OTP: registro con verificación de código

```typescript
import { test, expect } from '@playwright/test';
import { NotificationHelper } from './helpers/NotificationHelper';

test.describe('Registro — verificación SMS OTP', () => {

  test('usuario se registra y verifica cuenta con código SMS', async ({ page, request }) => {
    const phone = process.env.TEST_PHONE || '+595981000001';
    const notifications = new NotificationHelper(request, { timeoutMs: 20000 });

    // 1. Completar el formulario de registro
    await page.goto('/registro');
    await page.getByLabel('Nombre').fill('Juan Test');
    await page.getByLabel('Teléfono').fill(phone);
    await page.getByLabel('Contraseña').fill('TestPass123!');
    await page.getByRole('button', { name: 'Registrarse' }).click();

    // 2. Esperar pantalla de verificación
    await expect(page.getByText(/ingresá el código/i)).toBeVisible();

    // 3. Consultar API interna para obtener el OTP enviado
    const result = await notifications.waitForNotification(phone, 'code');
    expect(result.found, 'El SMS OTP no llegó en el tiempo esperado').toBe(true);
    expect(result.value).toMatch(/^\d{4,8}$/);

    // 4. Ingresar el código en la app
    await page.getByLabel(/código/i).fill(result.value!);
    await page.getByRole('button', { name: /verificar|confirmar/i }).click();

    // 5. Verificar activación exitosa
    await expect(page).toHaveURL(/dashboard|bienvenido/);
    await expect(page.getByText(/cuenta activada|verificada/i)).toBeVisible();
  });

});
```

### Caso de uso 2 — Email de confirmación

```typescript
import { test, expect } from '@playwright/test';
import { NotificationHelper } from './helpers/NotificationHelper';

test.describe('Recuperación de contraseña — email', () => {

  test('link de reseteo llega al email del usuario', async ({ page, request }) => {
    const email = process.env.TEST_EMAIL || 'test@empresa.com';
    const notifications = new NotificationHelper(request, { timeoutMs: 30000 });

    // 1. Solicitar reseteo
    await page.goto('/recuperar-contrasena');
    await page.getByLabel('Email').fill(email);
    await page.getByRole('button', { name: /enviar|recuperar/i }).click();
    await expect(page.getByText(/revisá tu correo/i)).toBeVisible();

    // 2. Consultar API de email (Mailosaur, MailHog, API interna)
    const result = await notifications.waitForNotification(email, 'resetLink');
    expect(result.found, 'El email de recuperación no llegó').toBe(true);
    expect(result.value).toContain('/reset-password/');

    // 3. Navegar al link recibido
    await page.goto(result.value!);
    await expect(page.getByRole('heading', { name: /nueva contraseña/i })).toBeVisible();

    // 4. Completar el reseteo
    await page.getByLabel(/nueva contraseña/i).fill('NuevaPass456!');
    await page.getByLabel(/confirmar/i).fill('NuevaPass456!');
    await page.getByRole('button', { name: /guardar|confirmar/i }).click();
    await expect(page).toHaveURL(/login/);
  });

});
```

### Caso de uso 3 — Estado en base de datos

```typescript
import { test, expect } from '@playwright/test';
import { NotificationHelper } from './helpers/NotificationHelper';

test.describe('Pedido — validación de estado en BD', () => {

  test('pedido queda CONFIRMADO en BD después de completar checkout', async ({ page, request }) => {
    const notifications = new NotificationHelper(request, {
      timeoutMs: 10000,
      pollIntervalMs: 1000,
    });

    // 1. Completar el flujo de compra
    await page.goto('/carrito');
    await page.getByRole('button', { name: 'Confirmar pedido' }).click();
    await expect(page.getByText(/pedido confirmado/i)).toBeVisible();

    // 2. Obtener el ID del pedido desde la UI o URL
    const orderId = page.url().match(/orders\/([a-z0-9-]+)/)?.[1];
    expect(orderId, 'No se encontró ID de pedido en la URL').toBeTruthy();

    // 3. Validar estado en BD via API interna
    const result = await notifications.waitForNotification(orderId!, 'status');
    expect(result.found, 'El pedido no aparece en la BD').toBe(true);
    expect(result.value).toBe('CONFIRMADO');
  });

});
```

### Variables de entorno para validaciones externas

```bash
# En .env.test (gitignored) o Azure Pipeline secrets
NOTIFICATION_API_URL=https://api-interna.empresa.com/test/notifications/latest
NOTIFICATION_API_TOKEN=tu-token-interno

# Para SMS
TEST_PHONE=+595981000001

# Para email
TEST_EMAIL=test@empresa.com

# Para BD state
TEST_ORDER_ID=  # se obtiene dinámicamente del test
```

En Azure Pipelines, agregar al step de ejecución:
```yaml
env:
  NOTIFICATION_API_URL:   $(notificationApiUrl)
  NOTIFICATION_API_TOKEN: $(notificationApiToken)
  TEST_PHONE:             $(testPhone)
  TEST_EMAIL:             $(testEmail)
```

---

## Reconocimiento de componentes web — protocolo anti-falla

**El 80% de los tests que fallan en CI usan selectores inventados.** Esta sección define
el protocolo obligatorio para reconocer componentes reales antes de generar cualquier locator.

### Regla de oro

**NUNCA generar un selector sin haberlo inferido de una fuente real.**
Si no hay código fuente ni HTML disponible → usar selectores semánticos genéricos
y declarar explícitamente que son estimados y pueden necesitar ajuste.

---

### Paso 1 — Solicitar el código fuente del componente

Antes de generar specs E2E, pedir siempre:

> Para generar selectores que no fallen, necesito ver el componente real.
> Podés compartir cualquiera de estos:
>
> - El HTML renderizado (F12 → Inspector → copiar el elemento)
> - El componente React/Vue/Angular (archivo `.tsx`, `.vue`, `.component.ts`)
> - La URL pública de la app (la inspecciono con `page.content()`)
>
> Sin esto uso selectores por rol estimados — funcionan en el 70% de los casos
> pero pueden fallar si la app usa labels no estándar o componentes de UI library.

---

### Paso 2 — Analizar el código fuente recibido

Buscar en orden de prioridad:

```
1. data-testid="..."          → getByTestId('...')        ← MÁS ESTABLE
2. aria-label="..."           → getByLabel('...')
3. role="..." + texto visible → getByRole('...', { name })
4. placeholder="..."          → getByPlaceholder('...')
5. id="..."                   → locator('#id')            ← SOLO SI NO HAY NADA MEJOR
6. class="..."                → locator('.clase')         ← ÚLTIMO RECURSO
```

**NUNCA usar:** selectores de posición (`nth-child`, `nth-of-type`), XPath absolutos.

#### Componentes de UI libraries reconocidas

**Material UI (MUI):**
```typescript
page.getByLabel('Email')
page.getByRole('button', { name: 'Guardar' })
page.getByRole('combobox', { name: 'País' })
page.getByRole('dialog').getByRole('button', { name: 'Confirmar' })
```

**Ant Design:**
```typescript
page.locator('.ant-input[placeholder="Ingresá tu email"]')
page.locator('.ant-select-selector').filter({ hasText: 'Seleccioná' })
page.locator('.ant-modal').getByRole('button', { name: 'Aceptar' })
page.locator('.ant-table-row').filter({ hasText: 'Juan Pérez' })
```

**PrimeNG / PrimeReact:**
```typescript
page.locator('input.p-inputtext[placeholder="..."]')
page.locator('.p-dropdown').filter({ hasText: 'Seleccioná' }).click()
page.locator('.p-dropdown-item').filter({ hasText: 'Opción' }).click()
page.locator('.p-datatable-row').filter({ hasText: 'texto' })
```

**Angular Material:**
```typescript
page.getByLabel('Nombre')
page.locator('mat-select[formcontrolname="pais"]').click()
page.locator('mat-option').filter({ hasText: 'Paraguay' }).click()
page.locator('mat-dialog-container').getByRole('button', { name: 'Confirmar' })
```

**Bootstrap:**
```typescript
page.getByLabel('Email')
page.locator('button.btn-primary').filter({ hasText: 'Enviar' })
page.locator('.modal.show').getByRole('button', { name: 'Aceptar' })
```

---

### Paso 3 — Protocolo cuando NO hay código fuente

**Nivel 1 — Selectores semánticos:**
```typescript
page.getByRole('button', { name: /guardar|save|enviar|submit/i })
page.getByRole('textbox', { name: /email|correo/i })
page.getByRole('textbox', { name: /contraseña|password/i })
```

**Advertencia obligatoria:**
```
⚠️  SELECTORES ESTIMADOS — sin código fuente disponible.
    Si algún test falla con "element not found":
    → Compartí el HTML del componente, o
    → Corré: npx playwright codegen <URL>
```

---

### Paso 4 — Recomendar data-testid cuando el selector es frágil

```
💡 RECOMENDACIÓN: agregar data-testid al elemento en el código fuente.
   <button data-testid="btn-verificar-otp">Verificar</button>
   → page.getByTestId('btn-verificar-otp').click()
   Convención: kebab-case, descriptivo.
```

---

### Paso 5 — Waiters por tipo de componente

```typescript
// Elemento visible antes de interactuar
await expect(locator).toBeVisible()

// Esperar red después de acción
await Promise.all([
  page.waitForResponse(r => r.url().includes('/api/pedidos') && r.status() === 200),
  page.getByRole('button', { name: 'Confirmar' }).click(),
])

// Dropdown asincrónico
await page.getByRole('combobox', { name: 'País' }).click()
await expect(page.getByRole('option', { name: 'Paraguay' })).toBeVisible()
await page.getByRole('option', { name: 'Paraguay' }).click()

// Modal con animación
await expect(page.getByRole('dialog')).toBeVisible()
await page.getByRole('button', { name: 'Confirmar' }).click()
await expect(page.getByRole('dialog')).toBeHidden()

// Tabla que carga datos
await expect(page.locator('table tbody tr')).not.toHaveCount(0)

// Spinner que desaparece
await expect(page.locator('[data-testid="spinner"]')).toBeHidden()
```

---

### Paso 6 — Inspección en vivo

```bash
# Debug paso a paso
npx playwright test T_LOGIN.spec.ts --debug

# UI visual interactivo
npx playwright test --ui

# Grabar flujo y generar código automáticamente
npx playwright codegen https://app.miempresa.com
```

---

## Convención de nombres de archivos

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Test spec | `T_NOMBRE_DE_FLUJO.spec.ts` | `T_LOGIN.spec.ts` |
| Page Object | `pages/NombrePage.ts` | `pages/LoginPage.ts` |
| Helper externo | `helpers/NombreHelper.ts` | `helpers/NotificationHelper.ts` |
| Auth setup | `auth.setup.ts` | `auth.setup.ts` |
| Config | `playwright.config.ts` | `playwright.config.ts` |
| Pipeline Azure | `Y_NOMBRE_playwright.yml` | `Y_PORTAL_playwright.yml` |
| Informe PDF | `INFORME_E2E_NOMBRE.pdf` | `INFORME_E2E_PORTAL.pdf` |

Estructura recomendada:
```
tests/playwright/
  T_LOGIN.spec.ts
  T_REGISTRO_OTP.spec.ts
  T_CHECKOUT.spec.ts
  auth.setup.ts
  pages/
    LoginPage.ts
    RegistroPage.ts
  helpers/
    NotificationHelper.ts   ← SMS / email / BD state
playwright.config.ts
results/
  playwright-report/
  INFORME_E2E_PORTAL.pdf
```

---

## Stack

- Runner: Playwright Test (`@playwright/test`)
- Lenguaje: TypeScript
- Browsers: Chromium, Firefox, WebKit
- Reporters nativos: `html`, `json`, `junit`, `list`
- Auth: `storageState` (sesión guardada, no login por test)
- Validaciones externas: `NotificationHelper` con polling sobre API interna
- CI: Azure Pipelines + GitHub Actions
- PDF: reporter Python con ReportLab

---

## Comandos

| Trigger | Acción |
|---------|--------|
| `/playwright:generate` | Generar spec `.ts` desde flujo / URL / código fuente |
| `/playwright:page` | Generar o actualizar Page Object |
| `/playwright:helper` | Generar `NotificationHelper.ts` para SMS / email / BD |
| `/playwright:fix` | Analizar y reparar test fallido |
| `/playwright:ci` | Generar pipeline Azure Pipelines o GitHub Actions |
| `/playwright:auth` | Generar setup de autenticación (`auth.setup.ts`) |
| `/playwright:config` | Generar o actualizar `playwright.config.ts` |
| `/playwright:report` | Analizar resultado JSON y describir el PDF ejecutivo |
| `/playwright:inspect` | Mostrar comandos de inspección y codegen para la URL dada |

---

## Patrones de código — referencia

### playwright.config.ts estándar

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/playwright',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 4 : undefined,
  reporter: [
    ['list'],
    ['json', { outputFile: 'results/playwright-results.json' }],
    ['junit', { outputFile: 'results/playwright-junit.xml' }],
    ['html', { outputFolder: 'results/playwright-report', open: 'never' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:4200',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
    {
      name: 'firefox',
      use: {
        ...devices['Desktop Firefox'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
});
```

### auth.setup.ts

```typescript
import { test as setup, expect } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, '../playwright/.auth/user.json');

setup('autenticar usuario de prueba', async ({ page }) => {
  await page.goto('/login');
  await page.getByRole('textbox', { name: /usuario|email/i })
    .fill(process.env.TEST_USER || 'testuser@empresa.com');
  await page.getByRole('textbox', { name: /contraseña|password/i })
    .fill(process.env.TEST_PASSWORD || 'TestPass123');
  await page.getByRole('button', { name: /iniciar sesión|login|entrar/i }).click();
  await expect(page).toHaveURL(/dashboard|home|inicio/);
  await page.context().storageState({ path: authFile });
});
```

### Page Object — LoginPage.ts

```typescript
import { type Page, type Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = page.getByRole('textbox', { name: /usuario|email/i });
    this.passwordInput = page.getByRole('textbox', { name: /contraseña|password/i });
    this.submitButton  = page.getByRole('button',  { name: /iniciar sesión|login/i });
    this.errorMessage  = page.getByRole('alert');
  }

  async goto() { await this.page.goto('/login'); }

  async login(username: string, password: string) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async loginAndExpectDashboard(username: string, password: string) {
    await this.login(username, password);
    await this.page.waitForURL(/dashboard|home/);
  }
}
```

---

## Pipeline Azure Pipelines — template estándar

```yaml
# Y_NOMBRE_playwright.yml
# Playwright E2E tests — NOMBRE APP
# Generado por skill playwright · aiquaa.com

trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: ubuntu-latest

variables:
  nodeVersion: '20.x'
  resultsDir: '$(Build.ArtifactStagingDirectory)/playwright-results'

steps:

  - task: NodeTool@0
    inputs:
      versionSpec: $(nodeVersion)
    displayName: Instalar Node.js

  - script: npm ci
    displayName: Instalar dependencias

  - script: npx playwright install --with-deps chromium
    displayName: Instalar browsers Playwright

  - script: mkdir -p $(resultsDir)
    displayName: Crear directorio de resultados

  - script: npx playwright test --reporter=list,json,junit,html
    displayName: Ejecutar tests Playwright
    continueOnError: true
    env:
      BASE_URL:               $(baseUrl)
      TEST_USER:              $(testUser)
      TEST_PASSWORD:          $(testPassword)
      API_TOKEN:              $(apiToken)
      NOTIFICATION_API_URL:   $(notificationApiUrl)
      NOTIFICATION_API_TOKEN: $(notificationApiToken)
      TEST_PHONE:             $(testPhone)
      TEST_EMAIL:             $(testEmail)
      CI:                     true

  - script: |
      cp results/playwright-results.json $(resultsDir)/ || true
      cp results/playwright-junit.xml    $(resultsDir)/ || true
      cp -r results/playwright-report    $(resultsDir)/ || true
    displayName: Copiar resultados
    condition: always()

  - task: PublishTestResults@2
    condition: always()
    inputs:
      testResultsFormat: JUnit
      testResultsFiles: '$(resultsDir)/playwright-junit.xml'
      testRunTitle: 'Playwright E2E — NOMBRE APP'
      failTaskOnFailedTests: true
    displayName: Publicar en Azure Test Plans

  - script: |
      pip install reportlab --quiet
      python reporter/playwright_report.py \
        --results     $(resultsDir)/playwright-results.json \
        --output      $(resultsDir)/INFORME_E2E_NOMBRE.pdf \
        --app-name    "NOMBRE APP" \
        --environment "QA"
    displayName: Generar informe PDF ejecutivo
    condition: always()

  - task: PublishBuildArtifacts@1
    condition: always()
    inputs:
      pathToPublish: $(Build.ArtifactStagingDirectory)
      artifactName: playwright-results
    displayName: Subir artefactos
```

---

## Formato de salida — autoría (`/playwright:generate`)

```
SPEC: T_<NOMBRE>.spec.ts
PAGE: pages/<NOMBRE>Page.ts (si POM)
HELPER: helpers/NotificationHelper.ts (si hay validaciones externas)
FUENTE SELECTORES: <código fuente | estimados | codegen>
TESTS GENERADOS:
  ✅ <descripción del test>
  ✅ <descripción del test — incluye validación SMS/BD si aplica>
SELECTORES USADOS:
  <lista de locators con su origen>
VALIDACIONES EXTERNAS:
  TIPO:    <SMS | Email | DB-state | no aplica>
  API:     <url de la API de validación>
  CAMPO:   <jsonpath del valor validado>
  TIMEOUT: <ms>
ADVERTENCIAS:
  ⚠️  <selectores estimados que pueden necesitar ajuste>
  💡  <recomendaciones de data-testid si aplica>
```

---

## Verificación en base de datos (SQL Sandbox)

Cuando la app bajo prueba corre contra el sandbox del curso (`aiquaa-sandbox-api`), cerrar el
ciclo **UI/API → verificación en BD** con `POST /api/v1/sql/select` usando la fixture `request`
de Playwright. Ver skill `sandbox` → `references/sql-endpoint.md` para el contrato completo
(guardrails, whitelist de tablas, `rowCount`). Solo aplica si la API expone un endpoint SQL
equivalente — no asumirlo en otros proyectos.

### DbHelper.ts — helper reutilizable

```typescript
import { APIRequestContext } from '@playwright/test';

export class DbHelper {
  constructor(
    private readonly request: APIRequestContext,
    private readonly apiKey: string = process.env.SANDBOX_API_KEY || '',
  ) {}

  async select<T = Record<string, unknown>>(sql: string, params: unknown[] = []) {
    const res = await this.request.post('/api/v1/sql/select', {
      headers: { 'x-api-key': this.apiKey },
      data: { sql, params },
    });
    const body = await res.json();
    if (!res.ok()) throw new Error(`sql/select falló: ${JSON.stringify(body)}`);
    return body as { data: T[]; rowCount: number };
  }
}
```

### Caso de uso — crear orden por UI, verificar monto en BD

```typescript
import { test, expect } from '@playwright/test';
import { DbHelper } from './helpers/DbHelper';

test('el monto de la orden creada por UI coincide con lo persistido', async ({ page, request }) => {
  const db = new DbHelper(request);

  await page.goto('/ordenes/nueva');
  await page.getByTestId('ordenes-field-producto').fill('Mouse');
  await page.getByTestId('ordenes-field-cantidad').fill('2');
  await page.getByTestId('ordenes-submit').click();

  const ordenId = await page.getByTestId('ordenes-row-id').textContent();

  const { rowCount, data } = await db.select(
    'SELECT monto FROM ordenes WHERE id = $1', [ordenId],
  );
  expect(rowCount).toBe(1);
  expect(data[0].monto).toBe(31.0); // 2 × 15.5 — calculado por el servidor, no por el cliente
});
```

### Caso que debe fallar — whitelist de tablas

```typescript
test('tabla fuera de qa_training es rechazada', async ({ request }) => {
  const res = await request.post('/api/v1/sql/select', {
    headers: { 'x-api-key': process.env.SANDBOX_API_KEY! },
    data: { sql: 'SELECT * FROM api_keys' },
  });
  expect(res.status()).toBe(400);
  expect((await res.json()).error.code).toBe('VALIDATION_ERROR');
});
```

⚠️ Cada verificación consume una petición del rate limit del sandbox (30 req/min por
`x-api-key`) — en un `test.describe` con muchos `it`, considerar una key dedicada para BD.

---

## Fallos comunes y fixes

| Síntoma | Causa | Fix |
|---------|-------|-----|
| `locator.click: element not found` | Selector incorrecto o elemento no visible | Correr `npx playwright codegen <URL>` para obtener el selector real |
| `locator resolved to hidden element` | Elemento existe pero no visible | Agregar `await expect(locator).toBeVisible()` antes del click |
| `Timeout 30000ms exceeded` | Página no cargó o selector equivocado | Usar `--debug`; revisar si el selector existe en DOM |
| `strict mode violation` | Selector matchea más de un elemento | Agregar `{ name: '...' }` o `.filter({ hasText: '...' })` |
| `storageState file not found` | Auth setup no corrió | Verificar dependencia `setup` en `playwright.config.ts` |
| SMS OTP: `found: false` | Timeout expirado sin respuesta | Aumentar `timeoutMs`; verificar que la API de validación funcione |
| SMS OTP: código incorrecto | API retorna código viejo (no el último) | Agregar filtro por timestamp en la API interna |
| BD state: `found: false` | La transacción tarda más de lo esperado | Aumentar `timeoutMs`; reducir `pollIntervalMs` |
| Notificación API: 401 | `NOTIFICATION_API_TOKEN` no seteado en CI | Agregar secret en Pipeline > Variables y mapear en `env:` |
| Tests pasan local, fallan en CI | Variables de entorno no seteadas | Verificar todo el bloque `env:` en el step de ejecución |
| Dropdown no abre opciones | Library usa portal fuera del DOM | Esperar `await expect(page.getByRole('option')).toBeVisible()` |
| Tests lentos en CI | Muchos workers o browsers | Reducir `workers`; usar solo Chromium en CI |

---

## Auto-Clarity

Salir de caveman para: hallazgos de seguridad encontrados durante E2E (XSS, datos expuestos),
regresiones críticas que bloquean el release, recomendaciones de arquitectura de tests,
explicaciones detalladas de cómo conectar la API de validación externa al helper.
Retomar caveman después.

## Boundaries

Escribe specs `.spec.ts`, Page Objects, `NotificationHelper.ts`, `playwright.config.ts`,
`auth.setup.ts`, fixtures, comandos CLI, pipelines Azure/GitHub.
NO ejecuta Playwright — da los comandos listos para ejecutar.
NO inventa selectores sin fuente — aplica el protocolo de reconocimiento y declara estimados.
NO inventa credenciales ni URLs de API — las pone como variables de entorno.
NO accede directamente a BD — siempre a través de la API interna del usuario.
Ante selector frágil → recomendar `data-testid` y `npx playwright codegen`.
"stop playwright" o "normal mode": volver a estilo verbose.
