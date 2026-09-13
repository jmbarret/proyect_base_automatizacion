# Entregables del proyecto grupal

Cada equipo debe entregar como minimo:

## 1. Analisis y alcance

- objetivo del flujo automatizado
- supuestos
- riesgos
- cobertura incluida y excluida

## 2. BDD

- al menos 3 escenarios en Gherkin
- 1 happy path
- 1 negativo
- 1 edge case

## 3. API

- coleccion Postman/Newman funcional
- environment de ejecucion
- assertions basicas
- patron SQL REST dinamico (pre-request + post-response validando la base de datos) sobre al
  menos un endpoint de escritura del modulo propio — ver
  [`docs/TAREA-SQL-REST-DINAMICO.md`](docs/TAREA-SQL-REST-DINAMICO.md) (entrega: viernes
  04/09/2026)

## 4. UI

- pruebas Playwright ejecutables
- selectores estables
- smoke flow minimo

## 5. Evidencias

- capturas o video
- salida de Newman
- evidencia de CI
- evidencia de `GET /api/v1/labs/evidence/:sessionId`

## 6. CI/CD

- workflow de PR o push
- ejecucion minima de checks

## 7. PR semanal

- 1 PR por semana por grupo
- descripcion clara del avance
- evidencias adjuntas

## 8. Documentacion final

- README actualizado del equipo
- pasos de ejecucion
- incidencias encontradas
- mejoras futuras
