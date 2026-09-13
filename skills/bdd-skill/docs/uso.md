# Guía de uso — bdd-skill

## Instalación

```bash
npx skills add aiquaa-labs/bdd-skill
```

Para agentes específicos:

```bash
npx skills add aiquaa-labs/bdd-skill -a cursor
npx skills add aiquaa-labs/bdd-skill -a windsurf
npx skills add aiquaa-labs/bdd-skill -a cline
```

## Instalar el stack localmente

```bash
npm install -D @cucumber/cucumber @playwright/test ts-node typescript
npx playwright install --with-deps chromium
```

## Uso típico en el curso

1. El docente da el número de grupo (1 a 10).
2. `/bdd:generate` — la skill resuelve módulo/endpoints/tablas contra `sandbox-skill` y pregunta
   capa (API / Web / API+BD) y criterios de aceptación.
3. Se generan `F_GRUPO_NN_MODULO.feature` + los `.steps.ts` que falten (reusando el catálogo).
4. `npx cucumber-js --dry-run` para validar que no hay steps sin definir.
5. `npx cucumber-js --tags "@grupo-N"` para correr.
6. `python reporter/bdd_report.py --results results/cucumber-report.json --grupo "..."` para el PDF.
7. Entrega con `course-pr-skill` (`/curso:entregar`).

## Comandos

| Comando | Acción |
|---------|--------|
| `/bdd:generate` | Generar `.feature` + steps desde criterios / grupo del curso |
| `/bdd:steps` | Agregar o completar steps para un `.feature` existente |
| `/bdd:fix` | Analizar y reparar un escenario fallido |
| `/bdd:ci` | Generar pipeline GitHub Actions o Azure Pipelines |
| `/bdd:report` | Analizar el JSON de cucumber y describir el PDF |

## Salidas

`F_GRUPO_NN_MODULO.feature` · `S_<capa>.steps.ts` · `Y_<NOMBRE>_bdd.yml` · `INFORME_BDD_<NOMBRE>.pdf`

→ Contrato de la API y datos sembrados: skill `sandbox`.
