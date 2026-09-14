# Grupo 07: CSV-driven order creation and correlated retrieval

Source: `postman/grupo-07-juan-barreto-carrito-e-commerce.postman_collection.json`,
request `01 - Checkout exitoso`. New plan, independent of the GET baseline.

## Artifacts

- `plans/P_GRUPO_07_ORDENES_CSV.jmx`: JMeter 5.6.3 plan using core components.
- `data/D_GRUPO_07_ORDENES_CSV.csv`: the exact header and three user-supplied rows.
- `properties/GRUPO_07_ORDENES_CSV.properties`: required retry/result settings.
- This document. No additional threshold file is needed for the requested
  per-response assertions; no existing thresholds or workflows were changed.

AIQUAA `perf_generar` produced the initial plan. Its placeholder dataset,
recycling configuration, missing authentication/correlation and incomplete
assertions were corrected before saving these artifacts.

## Request and data

`01 - Checkout exitoso (CSV)` sends
`POST https://aiquaa-sandbox-api.vercel.app/api/v1/ordenes`.
After a successful POST and correlation check, `02 - Consultar orden creada (correlacionada)`
sends `GET https://aiquaa-sandbox-api.vercel.app/api/v1/ordenes/${ordenId}`.
Both requests stay in the same worker and CSV iteration. There are no query
parameters, SQL calls or cleanup requests.

The CSV columns are:

```text
usuarioId,producto1,cantidad1,precioUnitario1,producto2,cantidad2,precioUnitario2,montoEsperado
```

Expected totals are 26.25, 21.00 and 36.75. The JSON body uses the CSV
variables directly: `usuarioId`, quantities and prices are unquoted numbers;
product names are quoted strings. `montoEsperado` is assertion input only
and is not sent in the request body.

CSV Data Set Config uses UTF-8, comma delimiter, quoted CSV support, explicit
variable names and `ignoreFirstLine=true`. Recycling is disabled and EOF
stops the worker. The dataset path is relative to the JMX directory:
`../data/D_GRUPO_07_ORDENES_CSV.csv`. Do not move the plan independently of
the data directory.

The local input guard reads each current CSV row at runtime, checks numeric
JSON syntax and rejects invalid product-string interpolation before HTTP.
The supplied plain product names are supported. Future values containing
quotes, backslashes or control characters may require JSON escaping; the
guard rejects unsafe raw interpolation rather than silently altering it.

## Authentication

The `x-api-key` header comes only from the process environment variable
`API_KEY`. Missing, blank or multiline values stop the worker before HTTP.
The key is copied to a thread variable in memory, never to a file or CSV.
The other header is `Content-Type: application/json`. A single Header Manager
at thread-group scope supplies both POST and GET; authentication is not duplicated.

Load the dedicated properties file. It disables retries and request/response
header/body persistence. Do not enable HTTP wire/header logging or export
live variables. No credential value is present in these artifacts.

## Assertions and correlation

Every POST response must satisfy:

- HTTP status 201.
- Top-level `data` exists and is an object.
- `data.id` exists and is not null.
- `data.estado` equals `pendiente`.
- `data.items` is an array with exactly two entries.
- Numeric `data.monto` equals the current CSV `montoEsperado`.
  Decimal comparison accepts JSON numbers and numeric strings and ignores
  insignificant trailing zeros (21 and 21.00 compare equal).

A built-in **JSON Extractor** under the POST sampler extracts `$.data.id`
to thread-local variable `ordenId`, first match, default `NOT_FOUND`.
The input guard clears `ordenId` and resets `g7.correlationReady=false` at the
beginning of each iteration. JMeter runs the extractor before POST assertions;
the following JSR223 correlation sampler runs after those assertions complete.

Correlation succeeds only when the POST sample passed and the extracted ID
exists, is not blank and is not `NOT_FOUND`. It reads `vars.get('ordenId')`
at runtime and only then sets `g7.correlationReady=true`. The GET is inside
an If Controller using that flag, so it never uses a hardcoded order ID.

On failure, the correlation sampler sets the flag false, clears the unusable
ID, records an unsuccessful `CORRELATION_ERROR` control sample with a generic
reason, and returns without stopping the worker. The GET is skipped for that
iteration; the next CSV row continues under `on_sample_error=continue`.
Failed control samples are not ignored. Successful control samples are ignored.
The existing input/authentication guard still stops the worker on invalid
configuration or malformed CSV input; that behavior is distinct from a failed
POST or correlation check.

The GET asserts exactly:
- HTTP 200 and valid JSON.
- Top-level `data` exists and is an object.
- `data.id` exists and is not null.
- `String.valueOf(data.id) == vars.get('ordenId')`.

Groovy source reads the ID through `vars.get`; only the HTTP path uses the
JMeter variable placeholder. No extra order fields are asserted for GET.
A failed GET marks that HTTP sample unsuccessful and the next CSV row still
continues. No retry or eventual-consistency assumption is introduced.

The element sequence is:

```text
Thread Group (1 worker, 3 CSV iterations; continue on sample error)
  CSV Data Set Config (read one row)
  Shared Header Manager
  Input/authentication guard (clear correlation state)
  If row/authentication valid:
    POST /api/v1/ordenes
      6000 ms timer
      JSON Extractor: ordenId = $.data.id (first match; NOT_FOUND default)
      Existing POST assertions
    Correlation-validation JSR223 sampler
    If g7.correlationReady:
      GET /api/v1/ordenes/${ordenId}
        6000 ms timer
        HTTP 200 / JSON / matching data.id assertions
```

No 3000 ms assertion or other latency pass/fail gate is included. Raw elapsed
times and observational P50/P95/P99 settings are retained. Three samples per
endpoint are not enough for meaningful tail-latency conclusions.

## Bounded execution defaults

The user supplied three cases without a new POST workload profile. The plan
therefore uses **one worker and three iterations**, reading each provided row
once per POST/GET pair. Each HTTP sampler has its own **6000 ms Constant Timer**,
so both POST and GET are paced, including the first POST. With one worker,
requests are sequential and cannot execute concurrently or catch up in bursts.
This conservative default is at most 10 RPM across both methods for this one
process and stays below the previously declared 30 RPM ceiling. Actual
throughput is lower because response times add to the interval.

This is a finite, sequential data-driven scenario, not the GET plan's open
120-second baseline. No total duration or ramp-up SLA is implied.
Connect/read timeouts of 10/30 seconds are transport bounds, not latency SLAs.
Redirects, embedded-resource fetching and transparent retries are disabled.

The plan can create up to three real orders and retrieve each by its extracted
ID on a future authorized run: at most **six HTTP requests** for the three rows.
It assumes `usuarioId=1` is valid and intentionally performs no cleanup.
Other clients/processes can consume the shared API rate budget. Immediate
read-after-create visibility and the API's full ID format remain unverified;
the plan adds neither retries nor undocumented numeric-ID restrictions.
JMeter records assertion failures in results; it does not automatically
convert those failures into a nonzero process exit code.

## Future execution (not performed)

Supply `API_KEY` through external secret injection, prepare an empty output
directory and run from the repository root only when execution is authorized:

```text
jmeter -n -t tests/performance/plans/P_GRUPO_07_ORDENES_CSV.jmx -q tests/performance/properties/GRUPO_07_ORDENES_CSV.properties -l test-results/performance/grupo-07-ordenes-csv/results.jtl
```

There is no embedded results writer: `-l` saves one JTL without duplicate
listeners. Successful local validation/correlation samples are ignored; input
and correlation failures remain visible. Results include the HTTP response
codes and `CORRELATION_ERROR` for correlation failures; the control message
also attaches a failed assertion with the generic reason, so the existing
JTL assertion-failure-message setting preserves it without saving response
content. GET/POST assertion failures retain their generic assertion messages.
Missing/truncated results, any failed samples, or fewer than three
successful POST and three successful GET samples must not be treated as
successful completion of all three correlated cases.

No JMeter execution or API call was performed during generation. Verification
is static only. Existing GET baseline files remain unchanged.

Reference: [JMeter component reference](https://jmeter.apache.org/usermanual/component_reference)
for CSV Data Set Config and JSON Extractor behavior.
