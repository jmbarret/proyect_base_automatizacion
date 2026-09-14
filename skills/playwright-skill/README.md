# playwright-skill

> Automatización E2E y de API con Microsoft Playwright — powered by [aiquaa](https://aiquaa.com/)

Skill para Claude Code, Cursor, Windsurf y más de 40 agentes de IA. Genera specs TypeScript,
Page Objects, configuración, auth setup, pipelines Azure Pipelines e informes PDF ejecutivos
con veredicto automático por suite.

---

## ¿Qué problema resuelve?

Configurar Playwright desde cero — estructura de carpetas, `playwright.config.ts`, manejo de
autenticación con `storageState`, Page Objects y pipelines CI — toma horas. Esta skill lo genera
en segundos a partir de una descripción del flujo, preguntando exactamente lo que necesita.

---

## ¿Qué incluye?

| Componente | Descripción |
|------------|-------------|
| `skills/playwright/SKILL.md` | Instrucciones del agente — genera specs, POM, config, CI |
| `examples/playwright.config.ts` | Configuración lista con reporters json + junit + html |
| `examples/auth.setup.ts` | Setup de autenticación con `storageState` |
| `examples/T_EXAMPLE.spec.ts` | Spec de ejemplo con E2E + API tests |
| `examples/Y_EXAMPLE_playwright.yml` | Pipeline Azure Pipelines con PDF ejecutivo |
| `reporter/playwright_report.py` | Generador de informe PDF ejecutivo con veredicto |

---

## Instalación

```bash
# Claude Code
npx skills add aiquaa-labs/playwright-skill

# Cursor
npx skills add aiquaa-labs/playwright-skill -a cursor

# Windsurf
npx skills add aiquaa-labs/playwright-skill -a windsurf

# Cualquier otro agente
npx skills add aiquaa-labs/playwright-skill
```

---

## Instalar Playwright localmente

```bash
# Crear proyecto nuevo
npm init playwright@latest

# O agregar a proyecto existente
npm install -D @playwright/test
npx playwright install --with-deps chromium
```

---

## Uso rápido

```
/playwright:generate   → generar spec .ts desde flujo / URL / código fuente
/playwright:page       → generar o actualizar Page Object
/playwright:fix        → analizar y reparar test fallido
/playwright:ci         → generar pipeline Azure Pipelines o GitHub Actions
/playwright:auth       → generar auth.setup.ts con storageState
/playwright:config     → generar o actualizar playwright.config.ts
/playwright:report     → analizar JSON de resultados y describir el PDF
```

La skill pregunta antes de generar: URL, tipo de prueba (E2E / API / visual), flujo a automatizar,
auth, browsers, patrón (Page Object Model o directo) y CI target.

---

## Convención de nombres

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Test spec | `T_NOMBRE_DE_FLUJO.spec.ts` | `T_LOGIN.spec.ts` |
| Page Object | `pages/NombrePage.ts` | `pages/LoginPage.ts` |
| Auth setup | `auth.setup.ts` | `auth.setup.ts` |
| Pipeline CI | `Y_NOMBRE_playwright.yml` | `Y_PORTAL_playwright.yml` |
| Informe PDF | `INFORME_E2E_NOMBRE.pdf` | `INFORME_E2E_PORTAL.pdf` |

---

## Informe PDF ejecutivo

```bash
pip install reportlab

python reporter/playwright_report.py \
  --results     results/playwright-results.json \
  --app-name    "Portal de Clientes" \
  --environment "QA" \
  --app-version "v2.1.0" \
  --author      "Nombre — email@empresa.com" \
  --repo-url    "https://github.com/org/repo"
```

El informe incluye portada con estadísticas, veredicto automático, resumen por suite y detalle
de fallos con mensaje de error.

| Veredicto | Condición |
|-----------|-----------|
| ✅ Suite verde | 0 fallos |
| ⚠️ Fallos menores | Tasa de éxito ≥ 85% |
| ❌ Regresión crítica | Tasa de éxito < 85% |

Salida: `INFORME_E2E_PORTAL.pdf`

---

## Estructura recomendada

```
tests/playwright/
  T_LOGIN.spec.ts
  T_DASHBOARD.spec.ts
  auth.setup.ts
  pages/
    LoginPage.ts
    DashboardPage.ts
playwright.config.ts
results/
  playwright-results.json
  playwright-junit.xml
  playwright-report/
  INFORME_E2E_PORTAL.pdf
azure-pipelines/
  Y_PORTAL_playwright.yml
```

---

## Créditos

Creado por [aiquaa](https://aiquaa.com/) — *Saber es calidad*

## Licencia

MIT
