# Pruebas de rendimiento - Grupo 07 (Ordenes / E-commerce)

Plan de pruebas JMeter sobre los endpoints del modulo Ordenes del Grupo 07
(`POST /api/v1/ordenes` + `GET /api/v1/ordenes/{id}`), contra el sandbox AIQUAA
(`aiquaa-sandbox-api.vercel.app`). Corrido por **Andrea Escurra**.

## Archivos

| Archivo | Descripcion |
|---|---|
| `plans/P_ORDENES.jmx` | Plan JMeter generado con el MCP `aiquaa-performance-mcp-server`. 3 hilos x 20 loops, `ConstantThroughputTimer` a 27 req/min totales (rate limit real de la API: 30 req/min por api-key), correlacion via JSON Extractor (`$.data.id` -> `ordenId`) entre el POST y el GET. |
| `data/D_ORDENES.csv` | Datos dinamicos con variables `usuarioId,producto,cantidad,precioUnitario`. |
| `thresholds/thresholds.json` | SLA: error rate < 5%, p95 < 2000 ms. |
| `properties/local.properties` | Defaults generados por el MCP: `threads=3`, `rampUp=0`, `loops=20`, `csvFile`, `jtlFile`. |

La api-key se pasa fuera del repositorio como propiedad JMeter: `-JapiKey=...`
(default de demostracion en el `.jmx`).

## Como correr (local)

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
& "C:\Users\admin\Downloads\apache-jmeter-5.6.3\apache-jmeter-5.6.3\bin\jmeter.bat" `
  -n -t grupos\grupo-07-carrito-ecommerce\tests\performance\plans\P_ORDENES.jmx `
  -l test-results\performance\grupo-07\R_ORDENES.jtl `
  -e -o test-results\performance\grupo-07\dashboard `
  -Jjmeter.save.saveservice.print_field_names=true `
  -JapiKey=<API_KEY>
```

> Nota: pasar `-JcsvFile` desde PowerShell pasa el literal `$csv` al `.bat`, rompiendo el plan;
> usar el default relativo del `.jmx`. El PATH debe apuntar a Java 21 (no Java 8) y
> `print_field_names=true` es obligatorio para que el MCP pueda analizar el JTL por columnas.

## Resultados de la corrida (Semana 4)

- **120 requests** (60 POST -> 201, 60 GET -> 200), 0 errores, sin `429`.
- Duracion aproximada: 4 min 38 s (~26 req/min).
- Latencia promedio: POST 1321 ms (incluye warm-up de ~20 s al inicio) / GET 411 ms.
- Percentil p95: POST 540 ms / GET 774 ms.
- SLA (`thresholds.json`): **veredicto PASS** (error 0%, p95 < 2000 ms).

## Evidencias

- Informe PDF: `evidence/semana-04/informe-perf-ordenes-andrea.pdf` (generado con
  `aiquaa-performance-mcp-server --report ... --author Andrea`).
- JTL y dashboard HTML: carpetas locales `test-results/` (no versionadas).