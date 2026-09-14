# Grupo 07 — Evidencia Tarea 2 — Juan Barreto

## Objetivo

Documentar la ejecución de la automatización CI/CD correspondiente a la
Tarea 2 mediante GitHub Actions, Newman y un reporter Python autocontenido.

## Componentes

- Workflow: `.github/workflows/postman-grupo07-juan-regression.yml`
- Colección: `postman/grupo-07-juan-barreto-carrito-e-commerce.postman_collection.json`
- Reporter: `scripts/grupo07/newman_report.py`

## Flujo automatizado

GitHub Actions → Newman → `newman/results.json` → reporter Python
→ `newman/report.pdf` → GitHub Actions artifact.

## Ejecución completa

La ejecución completa se realizó en el fork del contribuidor, donde las
GitHub Actions Variables y Secrets requeridas están disponibles.

Run: [34864902273 — ejecución completa exitosa](https://github.com/jmbarret/proyect_base_automatizacion/actions/runs/34864902273).

Resultado verificado en los logs y en el estado de los pasos del workflow:

- 3 requests ejecutadas.
- 0 requests fallidas.
- 14 assertions aprobadas.
- 0 assertions fallidas.
- Reporte PDF generado correctamente.

Artifact: `informe-regresion-grupo07-juan`, publicado con retención de 7 días.
El artifact contiene únicamente el PDF; `newman/results.json` es una salida
temporal y no se publica como artifact.

## Validación del Pull Request

El workflow del PR también se ejecutó correctamente:
[34864907602 — validación segura del PR](https://github.com/stevenayal/proyect_base_automatizacion/actions/runs/34864907602).

En este contexto Newman fue omitido intencionalmente porque GitHub no
expone los repository secrets del repositorio destino a workflows
ejecutados desde pull requests provenientes de forks.

El paso informativo finalizó correctamente; Newman, la generación del PDF
y la publicación del artifact fueron omitidos. Este comportamiento evita
exponer credenciales y no representa una ejecución de Newman.

## Seguridad

- `GRUPO07_BASE_URL` se obtiene desde GitHub Actions Variables.
- `GRUPO07_API_KEY` se obtiene desde GitHub Secrets.
- El valor real de la API key no está almacenado en la colección, workflow,
  reporter ni documentación.
- El workflow no utiliza `pull_request_target`.
- No se imprimen valores secretos durante la ejecución.

## Resultado

La automatización completa finalizó exitosamente:

- 3 requests.
- 14 assertions aprobadas.
- 0 fallas.
- PDF generado.
- Artifact publicado.
