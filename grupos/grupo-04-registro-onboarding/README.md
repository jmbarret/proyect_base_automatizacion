# Grupo 04 — Registro de Usuario / Onboarding

**Módulo:** Alta de nuevo cliente (KYC básico)
**Rama:** `grupo-04-registro-onboarding`

## Integrantes

- (completar: nombre y email — ver `inscripcion-grupos-bdd2.xlsx`)
- Sandra Penayo - sandrapenayo3@gmail.com
- Mathias Olmedo - olmedomathias1208@gmail.com
- Fabiola Fretes - fabiolafretes14@gmail.com
- Natalia Valdez - nataliaval1912@gmail.com
## Alcance

- TODO: objetivo del flujo automatizado
- TODO: supuestos
- TODO: riesgos
- TODO: cobertura incluida / excluida

## Entregables

Checklist según [ENTREGABLES.md](../../ENTREGABLES.md):

- [ ] Análisis y alcance
- [ ] BDD — `features/` (mínimo 3 escenarios: happy path, negativo, edge case)
- [ ] API — colección Postman/Newman (si aplica al módulo)
- [ ] UI — `tests/e2e/` con Playwright
- [ ] Evidencias en `evidence/`
- [ ] CI/CD verde
- [ ] PR a `main` usando la plantilla del repo

## Tarea 3.0 - Pre Request y Post Request con validación en BD

Se implementaron consultas SQL mediante `/api/v1/sql/select`.

### Casos realizados

- Obtención dinámica de un documento existente desde la base de datos.
- Validación de documento duplicado con respuesta `409 CONFLICT`.
- Alta válida con datos generados dinámicamente.
- Validación posterior en base de datos del usuario creado.
- Assertions para validar status, KYC, estado activo y existencia en BD.

### Manejo de variables

Se utilizaron variables de colección para reutilizar datos entre requests y `Date.now()` para generar valores únicos.

### Uso de IA / Skill

Se utilizó la Skill BDD mediante OpenCode para generar escenarios API + BD del Grupo 04.

Resultado de ejecución:

- 5 escenarios aprobados
- 32 steps aprobados

### Evidencias

Las evidencias de la tarea se encuentran en:

`evidence/semana-03/`

## Semana 4 - Automatización y rendimiento

Se agregaron dos pipelines independientes:

- `postman-grupo04-onboarding.yml`: ejecuta con Newman las dos carpetas de
  validación dinámica de la Semana 3, exporta el resultado JSON, genera un
  informe PDF con Python y publica ambos archivos como artefacto.
- `jmeter-grupo04-performance.yml`: ejecuta el flujo de creación y consulta con
  JMeter, genera el dashboard HTML y un informe PDF, evalúa los umbrales y
  publica la evidencia.

El plan `Grupo04_Onboarding.jmx` consume datos desde CSV, genera datos únicos,
extrae el ID del usuario creado mediante JSONPath y lo correlaciona con la
consulta GET. La API key se configura únicamente como secreto de GitHub con el
nombre `GRUPO04_API_KEY`.
