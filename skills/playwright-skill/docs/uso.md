# Guía de uso — playwright-skill

## Instalación

```bash
npx skills add aiquaa-labs/playwright-skill
```

Para agentes específicos:

```bash
npx skills add aiquaa-labs/playwright-skill -a cursor
npx skills add aiquaa-labs/playwright-skill -a windsurf
npx skills add aiquaa-labs/playwright-skill -a cline
```

---

## Instalar Playwright localmente

```bash
# Proyecto nuevo — crea estructura completa
npm init playwright@latest

# Agregar a proyecto existente
npm install -D @playwright/test
npx playwright install --with-deps chromium

# Instalar todos los browsers
npx playwright install --with-deps
```

---

## Comandos disponibles

| Comando | Qué hace |
|---------|----------|
| `/playwright:generate` | Genera spec `.ts` desde flujo / URL / código fuente |
| `/playwright:page` | Genera o actualiza Page Object en `pages/` |
| `/playwright:fix` | Analiza y repara test fallido |
| `/playwright:ci` | Genera pipeline Azure Pipelines o GitHub Actions |
| `/playwright:auth` | Genera `auth.setup.ts` con storageState |
| `/playwright:config` | Genera o actualiza `playwright.config.ts` |
| `/playwright:report` | Analiza JSON de resultados y describe el PDF |

La skill siempre pregunta antes de generar. En orden de prioridad:
1. URL base de la aplicación
2. Tipo de prueba (E2E web / API / ambos / visual)
3. Flujo a automatizar (descripción en lenguaje natural)
4. Autenticación (login, SSO, sin auth)
5. Endpoints de API (si aplica)
6. Browsers (Chromium / Firefox / WebKit)
7. Patrón (Page Object Model o tests directos)
8. CI target (Azure Pipelines / GitHub Actions)
9. Metadata del informe (nombre app, ambiente, versión, autor — opcionales)

---

## Uso rápido — ejecución local

### Correr todos los tests

```bash
npx playwright test
```

### Correr un spec específico

```bash
npx playwright test tests/playwright/T_LOGIN.spec.ts
```

### Correr en modo UI (debugging visual)

```bash
npx playwright test --ui
```

### Correr en browser visible (no headless)

```bash
npx playwright test --headed
```

### Correr solo en Chromium

```bash
npx playwright test --project=chromium
```

### Debug paso a paso

```bash
npx playwright test --debug tests/playwright/T_LOGIN.spec.ts
```

### Ver el reporte HTML después de la ejecución

```bash
npx playwright show-report results/playwright-report
```

---

## Auth con storageState — flujo completo

La skill genera un `auth.setup.ts` que corre una sola vez antes de todos los tests.
Guarda el estado de sesión (cookies + localStorage) en `playwright/.auth/user.json`.
Los tests cargan ese estado y arrancan ya autenticados — sin volver a hacer login.

```bash
# Asegurarse de que el directorio exista
mkdir -p playwright/.auth

# El setup corre automáticamente como proyecto dependencia
npx playwright test
```

Variables de entorno para credenciales (nunca hardcodear en el código):

```bash
# Windows PowerShell
$env:TEST_USER="testuser@empresa.com"
$env:TEST_PASSWORD="TestPass123"
npx playwright test

# Linux / macOS
TEST_USER="testuser@empresa.com" TEST_PASSWORD="TestPass123" npx playwright test
```

---

## Selectores — guía rápida

```typescript
// Orden de preferencia — de más estable a más frágil

// 1. Por rol (recomendado — accesible y estable)
page.getByRole('button', { name: 'Guardar' })
page.getByRole('textbox', { name: 'Email' })
page.getByRole('heading', { name: 'Dashboard' })
page.getByRole('link', { name: 'Inicio' })

// 2. Por texto visible
page.getByText('Bienvenido')
page.getByLabel('Contraseña')
page.getByPlaceholder('Ingresá tu email')

// 3. Por test-id (si el equipo los agrega al HTML)
page.getByTestId('submit-button')

// 4. Por CSS — solo si no hay otra opción
page.locator('.btn-primary')
page.locator('#login-form input[type="email"]')

// NUNCA — frágil, rompe con cualquier cambio de DOM
// page.locator('div > div:nth-child(3) > button')
```

---

## Assertions más usadas

```typescript
// URL
await expect(page).toHaveURL(/dashboard/);
await expect(page).toHaveURL('https://app.com/home');

// Visibilidad
await expect(locator).toBeVisible();
await expect(locator).toBeHidden();

// Texto
await expect(locator).toHaveText('Bienvenido, Juan');
await expect(locator).toContainText('Juan');

// Valor de input
await expect(input).toHaveValue('texto esperado');

// Estado
await expect(button).toBeEnabled();
await expect(button).toBeDisabled();
await expect(checkbox).toBeChecked();

// Cantidad de elementos
await expect(page.getByRole('listitem')).toHaveCount(5);

// API response
expect(response.status()).toBe(200);
expect(await response.json()).toMatchObject({ id: expect.any(String) });
```

---

## Generar el informe PDF ejecutivo

### Instalación de dependencias

```bash
pip install reportlab
```

### Uso básico

```bash
# Playwright genera el JSON con: --reporter=json
npx playwright test --reporter=json

python reporter/playwright_report.py \
  --results results/playwright-results.json \
  --app-name "Mi App" \
  --environment "QA"
```

### Uso completo

```bash
python reporter/playwright_report.py \
  --results     results/playwright-results.json \
  --output      results/INFORME_E2E_MI_APP.pdf \
  --app-name    "Portal de Clientes" \
  --environment "QA" \
  --app-version "v2.1.0" \
  --repo-url    "https://dev.azure.com/org/repo" \
  --author      "Juan Pérez — juan@empresa.com"
```

### Qué contiene el informe

- Portada con estadísticas: total tests, pasaron, fallaron, tasa de éxito
- Veredicto automático:
  - `SUITE VERDE` → 0 fallos
  - `FALLOS MENORES` → tasa de éxito ≥ 85%
  - `REGRESIÓN CRÍTICA` → tasa de éxito < 85%
- Resumen por suite con estado (VERDE / FALLO / OMITIDO)
- Detalle de cada fallo: suite, archivo, línea y mensaje de error
- Footer con autor y `Powered by skill playwright · aiquaa.com`

---

## Azure Pipelines — puntos clave

El pipeline estándar (`Y_*_playwright.yml`) incluye:

1. Instalación Node.js + `npm ci`
2. Instalación de browsers con `npx playwright install --with-deps chromium`
3. Ejecución con reporters `list,json,junit,html`
4. `PublishTestResults@2` con JUnit XML → pestaña Tests de Azure DevOps
5. Generación de informe PDF con `condition: always()`
6. Upload de artefactos (JSON + XML + HTML report + PDF)

Variables sensibles en Azure Pipeline Secrets:

```yaml
env:
  BASE_URL:      $(baseUrl)        # URL de la app en el ambiente a testear
  TEST_USER:     $(testUser)       # secret en Pipeline > Variables
  TEST_PASSWORD: $(testPassword)   # secret en Pipeline > Variables
  API_TOKEN:     $(apiToken)       # secret en Pipeline > Variables
```

---

## Convención de archivos

```
tests/playwright/
  T_LOGIN.spec.ts              ← spec de login
  T_DASHBOARD.spec.ts          ← spec de dashboard
  T_API_USERS.spec.ts          ← spec de API sin navegador
  auth.setup.ts                ← setup de autenticación
  pages/
    LoginPage.ts               ← page object
    DashboardPage.ts
playwright/.auth/
  user.json                    ← estado de sesión (gitignored)
playwright.config.ts           ← configuración global
results/
  playwright-results.json      ← JSON de resultados
  playwright-junit.xml         ← JUnit XML para Azure
  playwright-report/           ← HTML report
  INFORME_E2E_MI_APP.pdf       ← informe PDF ejecutivo
azure-pipelines/
  Y_MI_APP_playwright.yml      ← pipeline Azure
```

---

## Créditos

Creado por [aiquaa](https://aiquaa.com/) — *Saber es calidad*

Compatible con el stack:
- [postman-newman-skill](../postman-newman-skill) — pruebas funcionales Postman
- [hurl-skill](../hurl-skill) — pruebas funcionales declarativas
- [jmeter-skill](../jmeter-skill) — pruebas de rendimiento
