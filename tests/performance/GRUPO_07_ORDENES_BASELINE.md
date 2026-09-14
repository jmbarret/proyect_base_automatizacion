# Grupo 07: unfiltered orders baseline

Requirement: `PERF-ORDENES-GET-001`.

Generated with AIQUAA `perf_generar`, then corrected locally because the tool's
draft omitted authentication/JSON checks, used 120 seconds as a hold after
ramp-up, and targeted the existing shared thresholds file. Existing course
plans, shared thresholds, data and CI workflows remain unchanged.

## Files

- `plans/P_GRUPO_07_ORDENES_BASELINE.jmx`: standalone plan for JMeter 5.6.3,
  using core components and bundled Groovy; no arrival-thread-group plugin.
- `properties/GRUPO_07_ORDENES_BASELINE.properties`: fixed scenario, no retries,
  safe JTL settings, and observational percentile configuration. Required.
- `thresholds/GRUPO_07_ORDENES_BASELINE.json`: maximum error rate 0%, globally
  and for the target sampler. No latency thresholds.
- No CSV: this GET needs no dynamic input, identifiers, query, or body.

## Declared behavior

One HTTP sampler: `GET https://aiquaa-sandbox-api.vercel.app/api/v1/ordenes`,
named `G7-01 Listar todas las ordenes (sin filtro)`.

Headers: `Content-Type: application/json` and `x-api-key` loaded in memory
from the external process environment variable `API_KEY`. No key value is
stored in these artifacts. Missing/blank keys cause setup failure before HTTP.
The plan does not source credentials from collection files or properties.
Do not enable wire/header debugging, save request data, or export live variables.

Every response must be HTTP 200 and valid JSON with a top-level `data` array
of at most 100 order objects, with no `items` property on any entry. The
object-type check is an explicit interpretation of "order entries" and rejects
null/scalar entries. Empty arrays pass. Failure diagnostics contain neither
response content nor credentials. JMeter records assertion failures as failed
HTTP samples; the separate threshold evaluation enforces the aggregate 0% rule.

## Open, deterministic arrival schedule

- Target: **10 requests/minute = 1/6 requests/second**, not 10 RPS.
- Ceiling: **30 requests/minute**, not a load target.
- Total workload window: **120 seconds**, including **15 seconds** of ramp-up
  and **105 seconds** at the target rate.
- Think time: **0 ms**. Scheduling happens before the measured HTTP sampler.
- Ramp shape assumption: linear rate increase from zero to 10 RPM.
- Quantization assumption: issue a request each time integrated planned
  arrivals reaches an integer, rounding the total down (no initial t=0 burst).

The integral is `(15 / 2 + 105) / 6 = 18.75`; the plan therefore schedules
**18 HTTP requests**, not 19. The earlier approximate 19-request estimate is
resolved by this explicit rounding rule. Start offsets, in seconds:

`13.416408, 19.5, 25.5, 31.5, 37.5, 43.5, 49.5, 55.5, 61.5, 67.5, 73.5, 79.5, 85.5, 91.5, 97.5, 103.5, 109.5, 115.5`

This uses a core Thread Group as an execution pool for **18 one-shot workers**;
it is not a closed user-loop load model. Each worker waits independently for
its absolute offset and issues at most one GET, so slow responses do not delay
the planned arrival of other workers. Eighteen workers are a conservative
implementation allocation for 18 slots, **not a measured or required user
concurrency**. Actual in-flight concurrency remains unknown. Waiting workers
also count in JMeter thread-count columns; those columns are not in-flight
request counts. A separate one-thread control group enforces the deadline.

A shared gate separates admitted starts by at least 6 seconds. A scheduling
lateness tolerance of **500 ms** is an implementation assumption. A worker
that misses its slot beyond that tolerance is skipped and recorded as a
`SCHEDULE_ERROR`; it is never sent later as catch-up traffic. There are no
redirects, embedded-resource downloads, automatic HTTP retries, SQL helpers,
or additional API requests.

The epoch begins when the first HTTP worker enters the gate. Setup/JVM startup
is outside the workload window. At 120 seconds, the deadline guard requests
immediate test stop, interrupting unfinished HTTP requests; JMeter/JVM shutdown
may finish later. Connect/read timeouts also fit within the remaining budget
(up to 10 s / 30 s, respectively). These are execution bounds, **not latency
SLA thresholds**. Slow requests may be aborted or time out and count as errors.
Percentiles from this short, bounded run must not be interpreted as an
unconstrained latency distribution.

The gate is **per JMeter process**. Run only one process/engine and reserve the
traffic budget before any future execution. Distributed or simultaneous runs
multiply traffic. Server rate-limit scope/window and competing traffic remain
unknown; this plan cannot guarantee the API's aggregate ceiling in their
presence. Validate achieved starts/counts from the JTL after an authorized run.

## Results and later execution

No tests or API calls were performed while creating these files.

For a future authorized run, inject `API_KEY` into the process environment
through your secret-management mechanism (do not put its value on a command
line or in a properties file). From the repository root, after creating an
empty results directory, the following command would run the plan:

```text
jmeter -n -t tests/performance/plans/P_GRUPO_07_ORDENES_BASELINE.jmx -q tests/performance/properties/GRUPO_07_ORDENES_BASELINE.properties -l test-results/performance/grupo-07-ordenes/results.jtl -e -o test-results/performance/grupo-07-ordenes/dashboard
```

This command is documentation only and was not executed. Load the properties
unchanged; setup rejects conflicting declared scenario/retry settings.
Do not use the shared course thresholds, which contain a latency SLA.

The JTL retains timestamp, elapsed milliseconds, success, status, sampler label,
and generic assertion diagnostics; request/response headers, bodies and sampler
data are disabled. Successful setup/scheduling/deadline samples are ignored and
do not pollute HTTP metrics. Control failures remain visible for the global
zero-error rule. Calculate P50/P95/P99 on the **HTTP sampler's elapsed** values;
`Latency` is time to first response and is not total response time. The
properties select 50/95/99 for the aggregate percentile report. No latency
pass/fail gates are defined. With only 18 planned samples, upper percentiles
are descriptive and statistically weak.

Use the dedicated thresholds file with the repository's existing AIQUAA
post-run evaluator when execution is authorized. JMeter alone does not turn
assertion failures into a nonzero process exit code. A passing error-rate
evaluation must also be accompanied by a nonempty JTL and the expected count
of 18 target HTTP samples; missed slots, missing results, or interrupted
requests make the scenario incomplete or failed.

The existing CI workflow still runs the course plan, not this plan. It
already watches `tests/performance/**`, so publishing these changes in a
matching push/PR can trigger that pre-existing workflow. No workflow was
changed or triggered here.

Reference: [JMeter component documentation](https://jmeter.apache.org/usermanual/component_reference)
for JSR223 control samples, assertions, and core thread behavior.
