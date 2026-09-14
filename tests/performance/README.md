# Pruebas de rendimiento (JMeter)

Plan base del curso **Automatización CIT**, ejecutado en CI por el workflow
[`jmeter-performance.yml`](../../.github/workflows/jmeter-performance.yml).

La API bajo prueba es `https://aiquaa-sandbox-api.vercel.app` (endpoints
`api/v1/ordenes` y `api/v1/facturas`).

## Contenido

| Ruta | Qué es |
|------|--------|
| `plans/Curso_Automatizacion_CIT_v1.jmx` | Plan original del curso, **tal cual** se usó en local (Windows). Referencia, no lo usa el CI. |
| `plans/Curso_Automatizacion_CIT_v1.ci.jmx` | Misma prueba con rutas relativas. Es el que ejecuta el CI. |
| `data/datos_dinamicos.csv` | Datos de facturas **validos** que consume el CSV Data Set del plan. |
| `data/datos_negativos.csv` | Casos borde (monto 0, monto negativo, `numeroFactura` vacio, fecha vencida). No los usa la prueba de carga. |
| `thresholds/thresholds.json` | SLA evaluado tras la corrida (error rate y percentil 95). |

> El plan original apunta a `Z:\Jmeter\...`, rutas que solo existen en la
> máquina donde se dictó el curso. Por eso el CI usa la variante `.ci.jmx`, que
> lee el CSV desde la propiedad `csvPath` (por defecto,
> `tests/performance/data/datos_dinamicos.csv`).

## Restricciones de la API bajo prueba

Tres reglas del sandbox condicionan el diseño del plan; ignorarlas da 100 % de
error y un veredicto FAIL que no tiene nada que ver con el rendimiento:

1. **`numeroFactura` es UNIQUE en la base.** Repetir uno devuelve `409 Conflict`.
   El plan le concatena `runId`, número de hilo y contador
   (`${numeroFactura}-${__P(runId,...)}-${__threadNum}-${__counter(FALSE,)}`) para
   que cada POST sea nuevo, también entre corridas. El CI pasa
   `-JrunId=$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT`; en local, si no se pasa la
   propiedad, se usa el timestamp.
2. **Rate limit de 30 req/min por api-key**, con `429 Too Many Requests` al
   pasarse. El plan lleva un Constant Throughput Timer a 27 muestras/min sobre
   todo el grupo de hilos. Con 3 hilos × 20 iteraciones la corrida tarda ~2 min.
3. **`proveedor` es un enum sensible a mayúsculas**: `ANDE`, `ESSAP`, `COPACO`,
   `Tigo`, `Personal`. `TIGO` o `PERSONAL` devuelven `400 VALIDATION_ERROR`.

Subir hilos o iteraciones sin subir el throughput del timer solo alarga la
corrida; subir el throughput por encima de 30/min reintroduce los 429.

## Correr en local

```bash
jmeter -n -t tests/performance/plans/Curso_Automatizacion_CIT_v1.ci.jmx \
  -l test-results/performance/R_CURSO_CIT.jtl \
  -e -o test-results/performance/dashboard \
  -JcsvPath=tests/performance/data/datos_dinamicos.csv \
  -JrunId="local-$(date +%s)"
```

Informe PDF a partir del `.jtl`:

```bash
npx -y aiquaa-performance-mcp-server --report \
  test-results/performance/R_CURSO_CIT.jtl \
  tests/performance/thresholds/thresholds.json \
  test-results/performance/INFORME.pdf \
  --api-name "AIQUAA Sandbox API" --test-type carga \
  --plan tests/performance/plans/Curso_Automatizacion_CIT_v1.ci.jmx
```

El informe incluye los tiempos de respuesta con sus percentiles, las
transacciones por segundo separadas entre correctas y con error, y la tabla de
endpoints con su verbo HTTP. El `--plan` es lo que aporta el verbo: el `.jtl`
guarda la URL pero no el método.

## Evidencia de monitoreo (opcional)

Si se dispara el workflow a mano con `monitoring_dashboard_url`, se captura una
pantalla del dashboard (Grafana u otro) y se adjunta al PDF. La captura espera a
que el dashboard termine de arrancar: un stack de Grafana Cloud gratuito se
duerme cuando está inactivo y puede tardar más de un minuto en responder.

## SLA

`thresholds.json` declara error rate máximo de 5 % y percentil 95 bajo 2000 ms.
Con el plan paceado a 27 req/min la corrida de referencia da 60/60 en `201` y
p95 ≈ 580 ms, o sea PASS con margen.

El paso que genera el PDF nunca corta el job: si el veredicto es FAIL, el
informe se publica igual como artefacto y quien falla es el paso
`Evaluar umbrales (SLA)`, que es el gate real.
