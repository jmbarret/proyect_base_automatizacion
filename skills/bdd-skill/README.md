# bdd-skill

**Herramienta:** [Cucumber](https://cucumber.io/) (`@cucumber/cucumber`) + [Playwright](https://playwright.dev/)
**Lenguaje:** Gherkin (`.feature`) + TypeScript (steps)
**Reporte:** JSON nativo de cucumber-js → PDF con matriz de trazabilidad

Genera archivos `.feature`, step definitions reutilizables (API, web, base de datos),
`world.ts`/`hooks.ts`, `cucumber.js` y pipelines CI. Pensada para el curso de automatización
de aiquaa: cada grupo (1 a 10) automatiza su módulo del [sandbox](../sandbox-skill) en BDD.

## Instalación

```bash
npx skills add aiquaa-labs/bdd-skill
```

## Instalar el stack localmente

```bash
npm install -D @cucumber/cucumber @playwright/test ts-node typescript
npx playwright install --with-deps chromium
```

## Comandos

| Comando | Acción |
|---------|--------|
| `/bdd:generate` | Generar `.feature` desde criterios / grupo del curso / documento (vía `ocr-bdd-skill`) |
| `/bdd:steps` | Agregar o completar steps reutilizables |
| `/bdd:fix` | Analizar y reparar un escenario fallido |
| `/bdd:ci` | Generar pipeline GitHub Actions o Azure Pipelines |
| `/bdd:report` | Analizar resultados y describir el informe PDF |

## Salidas

`F_GRUPO_NN_MODULO.feature` · `S_<capa>.steps.ts` · `Y_<NOMBRE>_bdd.yml` · `INFORME_BDD_<NOMBRE>.pdf`

## Informe PDF

```bash
pip install reportlab

python reporter/bdd_report.py \
  --results results/cucumber-report.json \
  --grupo "Grupo 3 — Pagos de Servicios" \
  --author "Nombre — email@empresa.com"
```

→ [Documentación completa](./docs/uso.md) · [Skill de contrato del sandbox](../sandbox-skill)

## Licencia

MIT
