# Grupo 07 - Tarea 2 - Pipeline Postman + Python

Evidencia de la regresión de Carrito Ecommerce de Juan Barreto. Tarea 1 y
Tarea 2 se entregan juntas en el PR grupal existente **#51**; no se crea otro PR.
Este documento registra la ejecución exitosa informada por el equipo, sin
volver a ejecutar Newman, JMeter, la API ni GitHub Actions.

## Colección ejecutada

`postman/grupo-07-juan-barreto-carrito-e-commerce.postman_collection.json`

## Pipeline

Workflow: `.github/workflows/postman-grupo07-regression.yml`.

```text
GitHub Actions → npm ci → npx newman run
→ newman/results.json → Python reporter
→ newman/report.pdf → GitHub Actions artifact
```

Runner `ubuntu-latest`, Node **22** y Python **3.11**. Newman se instala como
dependencia de desarrollo mediante `npm ci`, sin instalación global; usa
reporters `cli,json` y `--delay-request 800`.

El reporter existente `skills/postman-newman-skill/reporter/newman_report.py`
consume `newman/results.json` y genera `newman/report.pdf`. Sus dependencias
se instalan desde `skills/postman-newman-skill/reporter/requirements.txt`.
El PDF incluye metadatos del repositorio, commit SHA, actor y URL de ejecución.
La generación del PDF y su subida conservan `if: always()`.

## Resultado

| Métrica | Resultado |
|---|---|
| Requests | 3 |
| Assertions | 14 |
| Assertions aprobadas | 14 |
| Assertions fallidas | 0 |
| Resultado del workflow | success |
| Generación del PDF | Exitosa |

## Evidencia del workflow

[Ejecución exitosa 34803601974](https://github.com/stevenayal/proyect_base_automatizacion/actions/runs/34803601974).

Artifact: **`informe-regresion-grupo07`**, con el archivo `report.pdf`.
Retención configurada: **7 días**. La referencia principal es la URL del run,
no un enlace directo temporal al artifact; el PDF puede dejar de estar
disponible al vencer la retención.

## Seguridad

- `GRUPO07_BASE_URL` se proporciona mediante GitHub Actions variables
  (`vars.GRUPO07_BASE_URL`) y se pasa a Newman como `baseUrl`.
- `GRUPO07_API_KEY` se proporciona mediante GitHub Actions secrets
  (`secrets.GRUPO07_API_KEY`) y se pasa como `apiKey` para `x-api-key`.
- La API key real no se almacena en el workflow ni en este documento.
- `newman/results.json` es una entrada temporal del reporter: no se versiona
  ni se sube como artifact final. `.gitignore` excluye `newman/`.
- El único archivo subido por este workflow es `newman/report.pdf`.

## Archivos relevantes

- `.github/workflows/postman-grupo07-regression.yml`
- `postman/grupo-07-juan-barreto-carrito-e-commerce.postman_collection.json`
- `skills/postman-newman-skill/reporter/newman_report.py`
- `skills/postman-newman-skill/reporter/requirements.txt`
- `grupos/grupo-07-carrito-ecommerce/evidence/GRUPO_07_TAREA_2_EVIDENCIA.md`
