# Grupo 05 — Tarjetas de Crédito/Débito

**Módulo:** Gestión de tarjetas
**Rama:** `grupo-05-tarjetas-credito-debito`

## Integrantes

- Marcos Trinidad ---> (trinidad.py@gmail.com)
- Rafael Estigarribia ---> (rafaer93@gmail.com)
- Emilio Oheler ---> (ohelerhernan@gmail.com)
- Matias Murto ---> (matiasmurto1@gmail.com)
- Ivan Bolaños ---> (ivanbolanos92@gmail.com)

## Alcance

- **Objetivo:** validar las gestiones que el cliente realiza sobre sus tarjetas de
  crédito/débito: consulta de datos, cambio de PIN, bloqueo y desbloqueo, modificación
  de límites y pago de la tarjeta desde cuenta propia.
- **Supuestos:**
  - El cliente está autenticado en la app con biometría válida y posee al menos una
    tarjeta de crédito/débito vigente.
  - Las operaciones sensibles (cambio de límite) requieren confirmación por OTP.
  - Los datos de tarjeta usados en las pruebas son de prueba, nunca reales.
- **Riesgos:**
  - Los cambios de estado de tarjeta (bloqueo/desbloqueo) deben propagarse a todos los
    canales; una propagación asíncrona puede generar resultados intermitentes.
  - La dependencia de OTP y biometría exige datos de prueba controlados.
- **Cobertura incluida:** consulta de datos de la tarjeta, cambio de PIN, bloqueo
  temporal por pérdida, desbloqueo, aumento de límite diario (con OTP válido e inválido)
  y pago desde cuenta propia.
- **Cobertura excluida:** alta y emisión de tarjetas, tarjetas adicionales, 3-D Secure,
  reversos y reclamos, y conciliación con la marca (Visa/Mastercard).

## Escenarios entregados

11 escenarios en [`features/tarjetas-credito-debito.feature`](features/tarjetas-credito-debito.feature):
6 happy paths, 3 casos negativos (OTP inválido, PIN actual incorrecto, saldo insuficiente) y
2 edge cases (compra igual al límite diario, desbloqueo denegado por motivo "ROBO").

## Entregables

Checklist según [ENTREGABLES.md](../../ENTREGABLES.md):

- [x] Análisis y alcance
- [x] BDD — `features/` (happy path caso negativo, y edge case cubiertos)
- [x] API — colección Postman/Newman
- [ ] UI — `tests/e2e/` con Playwright
- [x] Evidencias en `evidence/semana-03/` (salida Newman de la corrida SQL)
- [x] Rendimiento — plan JMeter + CSV (`tests/performance/`, ver más abajo)
- [ ] CI/CD verde
- [ ] PR a `main` usando la plantilla del repo

## Trazabilidad BDD -> API (AIQUAA)

| Escenario BDD | Tipo | Endpoint AIQUAA / Postman | Método | Datos Entrada | Validaciones / Assertions |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Ver datos tarjeta** | Happy Path | `https://aiquaa-sandbox-api.vercel.app/api/v1/tarjetas/:id` | `GET` | `id` de la tarjeta | Status 200, `data` presente, contiene `id`, `numero_enmascarado`, `tipo`, `marca`, `estado`. |
| **Bloqueo temporal por tarjeta perdida** | Happy Path | `https://aiquaa-sandbox-api.vercel.app/api/v1/tarjetas/:id/bloquear` | `PATCH` | `id` de la tarjeta | Status 200, `estado` = `"bloqueada"`, contiene `id`, `usuario_id`, `tipo`, `marca`, `numero_enmascarado`, `estado`, `activo`. |
| **Desbloqueo exitoso de tarjeta bloqueada** | Happy Path | `https://aiquaa-sandbox-api.vercel.app/api/v1/tarjetas/:id/activar` | `PATCH` | `id` de la tarjeta | Status 200, `data` presente, `estado` = `"activa"`. |

## Variables de Entorno Utilizadas

* **`Api-Key`**: clave de autenticación (`x-api-key`) para las peticiones a la sandbox de AIQUAA.

## Validación SQL dinámica (pre-request + post-response)

Carpeta `E2E - Flujos con validacion SQL` en la colección Postman, sobre `PATCH /api/v1/tarjetas/:id/bloquear` y `/activar` (columna `estado` de la tabla `tarjetas`). Sigue el patrón de [`docs/TAREA-SQL-REST-DINAMICO.md`](../../docs/TAREA-SQL-REST-DINAMICO.md) y de la skill `postman-newman` (`skills/postman-newman-skill/skills/postman-newman/references/sql-prerequest-pattern.md`).

- Pre-request Script de la colección: helper `utils.bodySqlRest(sql, params)` (consulta `/api/v1/sql/select`) declarado una sola vez, y default `tarjetaId = 1`.
- **Bloquear tarjeta (UPDATE + validación SQL)**: pre-request confirma en la BD que la tarjeta id=1 está `activa`; post-response relee la BD y confirma `estado = 'bloqueada'`.
- **Activar tarjeta (UPDATE + validación SQL)**: cierra el ciclo — confirma `bloqueada` antes, `activa` después. La corrida completa deja la BD en el mismo estado en que empezó (repetible).
- **Bloquear tarjeta - id inexistente (validación negativa)**: sobreescribe `tarjetaId` a `999999`; la API responde 404 y un `COUNT(*)` antes/después confirma que no se modificó ninguna fila.

Evidencia de la corrida (Newman): [`evidence/semana-03/newman-sql-e2e.txt`](evidence/semana-03/newman-sql-e2e.txt) — 9 requests, 8/8 assertions OK.

## Pruebas de rendimiento (JMeter)

Plan del grupo: [`tests/performance/plans/Grupo05_Tarjetas_v1.jmx`](../../tests/performance/plans/Grupo05_Tarjetas_v1.jmx),
ejecutado en CI por [`jmeter-grupo05-performance.yml`](../../.github/workflows/jmeter-grupo05-performance.yml).

| Ruta | Qué es |
|------|--------|
| `tests/performance/plans/Grupo05_Tarjetas_v1.jmx` | Plan de carga: consulta y emisión de tarjetas. |
| `tests/performance/data/grupo05_consulta_tarjetas.csv` | `tarjetaId,codigoEsperado` para el GET. |
| `tests/performance/data/grupo05_emision_tarjetas.csv` | `usuarioId,tipo,marca,codigoEsperado` para el POST. |

### Qué cubre

1. **Consulta — `GET /api/v1/tarjetas/{id}`**, con ids del CSV: ids del seed (200), un id
   inválido (`0` → 400) y uno inexistente (`9999` → 404).
2. **Creación — `POST /api/v1/tarjetas`**, con filas válidas (201) y de borde
   (`usuarioId` 0 e inexistente, `tipo` y `marca` fuera del enum → 400).
3. **Dato dinámico**: un JSON Extractor toma `$.data.id` de la respuesta del POST y un
   If Controller encadena `GET /api/v1/tarjetas/${tarjetaCreadaId}`, que valida 200 y que
   el `id` devuelto sea el mismo que emitió la creación. Así la prueba no depende de ids
   fijos del seed, que otros grupos borran (el id 1 del seed ya no existe).

Cada fila del CSV lleva el código HTTP que espera, y la Response Assertion compara contra
esa columna con *ignorar estado* activado: un 400 esperado cuenta como éxito y un 429 del
rate limit cuenta como fallo, que es justamente lo que interesa medir.

### Restricciones de la API

El sandbox limita a **30 req/min por api-key** y responde `429` al pasarse. Esa ventana es de
la key, no de la corrida, y la key pública la comparte toda la clase: dos ejecuciones
simultáneas se roban el cupo entre sí y las dos terminan en 429. Tres defensas:

1. El plan lleva un Constant Throughput Timer a **18 muestras/min** sobre todo el grupo de
   hilos, con margen para el tráfico ajeno.
2. El workflow declara `concurrency: aiquaa-sandbox-grupo05`, que serializa sus propias
   corridas en vez de cancelarlas.
3. Antes de arrancar, el workflow espera hasta 6 minutos a que **haya cupo** en la ventana.
   Mide holgura, no disponibilidad: manda una ráfaga de 5 requests y solo arranca si
   ninguna dio 429. Sondear una sola no alcanza, porque mientras otra corrida se mantenga
   bajo las 30/min la API responde 200 y el límite se pasa recién al sumarnos nosotros.

Ojo con un choque propio del repo: el plan del curso
([`jmeter-performance.yml`](../../.github/workflows/jmeter-performance.yml)) se dispara con
`tests/performance/**`, que incluye los archivos de este grupo, y corre a 27 muestras/min
sobre la misma key. Por eso el paso de espera es imprescindible: sin él, ambos planes se
pisan en cada sincronización del PR.

En local, conviene esperar un minuto entre corridas por el mismo motivo.

`threads` (2), `loops` (5) y `rampUp` (0) son propiedades: se cambian con `-J` sin tocar el plan.

### Correr en local

```bash
jmeter -n -t tests/performance/plans/Grupo05_Tarjetas_v1.jmx \
  -l test-results/performance/grupo05/R_GRUPO05_TARJETAS.jtl \
  -e -o test-results/performance/grupo05/dashboard \
  -JapiKey=<api-key> \
  -Jthreads=2 -Jloops=5
```

La api key **no está en el plan**: entra por `-JapiKey`. En CI la aporta el secret
`GRUPO05_API_KEY`; si no está cargado, el workflow cae a la key pública de la sandbox que
se repartió en clase.

Informe PDF a partir del `.jtl`, con el MCP del curso:

```bash
npx -y aiquaa-performance-mcp-server --report \
  test-results/performance/grupo05/R_GRUPO05_TARJETAS.jtl \
  tests/performance/thresholds/thresholds.json \
  test-results/performance/grupo05/INFORME_PERF_GRUPO05.pdf \
  --api-name "AIQUAA Sandbox API (tarjetas credito/debito)" \
  --plan tests/performance/plans/Grupo05_Tarjetas_v1.jmx \
  --test-type carga
```

### Mantenimiento del CSV de consulta

Los ids del seed se borran con el uso. Si una fila `200` empieza a dar 404, se refresca la
columna con los ids vigentes; el tramo dinámico (punto 3) no necesita mantenimiento.
