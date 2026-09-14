# Grupo 07 - Tarea 1 - JMeter

Alcance: consulta, creación con CSV y consulta correlacionada de órdenes en
`aiquaa-sandbox-api.vercel.app`. Rama: `grupo-07-carrito-ecommerce`.
Solo **Tarea 1**; Tarea 2 no iniciada. Ambas se entregarán después en un único PR.
Esta preparación no incluye staging, commit, push, PR ni nuevas ejecuciones.

## Endpoint de consulta

`GET /api/v1/ordenes`

`tests/performance/plans/P_GRUPO_07_ORDENES_BASELINE.jmx` configura llegadas
abiertas deterministas: objetivo **10 solicitudes/minuto**, techo declarado
**30/minuto**, **120 s** totales con **15 s** de rampa lineal incluidos y 105 s
estables. La discretización programa 18 solicitudes sin ráfagas de recuperación.
Sus properties y thresholds específicos declaran aceptación de 0 % de errores.

Valida HTTP 200 y `data` arreglo con hasta 100 órdenes sin propiedad `items`.
P50/P95/P99 son observacionales, sin SLA de latencia.

**Observación del entorno, no corrida aprobada con 0 % de errores:** el JTL
local `test-results/performance/grupo07-ordenes-baseline-final.jtl` contiene
18 muestras: 10 HTTP 200 y 8 HTTP 429. Se documenta como observación del
rate limiter compartido; no demuestra capacidad máxima ni cumplimiento del
umbral de cero errores. El techo de 30 RPM consta en la configuración.
Los JTL revisados no guardan cabeceras para verificar aquí `X-Ratelimit-Limit`.
La evidencia principal es la corrida POST→GET descrita más abajo.

## POST con datos dinámicos

`POST /api/v1/ordenes`

`tests/performance/plans/P_GRUPO_07_ORDENES_CSV.jmx` implementa el comportamiento
de `01 - Checkout exitoso` de
`postman/grupo-07-juan-barreto-carrito-e-commerce.postman_collection.json`.

CSV Data Set Config lee `tests/performance/data/D_GRUPO_07_ORDENES_CSV.csv`:
UTF-8, coma, cabecera omitida como dato, sin reciclado y detención en EOF.
Un trabajador recorre las tres filas originales en tres iteraciones.

| Variable | Uso |
|---|---|
| `usuarioId` | Usuario, número JSON. |
| `producto1` | Nombre del primer producto. |
| `cantidad1` | Cantidad del primer producto, número JSON. |
| `precioUnitario1` | Precio del primer producto, número JSON. |
| `producto2` | Nombre del segundo producto. |
| `cantidad2` | Cantidad del segundo producto, número JSON. |
| `precioUnitario2` | Precio del segundo producto, número JSON. |
| `montoEsperado` | Total esperado para la aserción; no se envía en el body. |

Totales por fila: **26.25**, **21.00**, **36.75**.
El POST valida HTTP 201, `data` objeto, ID presente, estado `pendiente`,
dos ítems y monto igual al esperado de la fila actual. No incorpora los
3000 ms de Postman como SLA de rendimiento.

## Correlación dinámica

```text
CSV → POST /api/v1/ordenes
    → JSON Extractor $.data.id → ordenId
    → aserciones POST y validación de correlación
    → GET /api/v1/ordenes/${ordenId}
```

Ambos métodos permanecen en el mismo hilo y la misma iteración.
Al inicio se limpia `ordenId` y se reinicia `g7.correlationReady=false`.
El extractor usa primera coincidencia y valor por defecto `NOT_FOUND`.
El guard exige POST exitoso e ID existente, no vacío y distinto de ese valor.
Si falla, registra `CORRELATION_ERROR`, omite el GET y continúa con la
siguiente fila sin reutilizar el ID anterior ni reintentar.

El GET valida HTTP 200, JSON válido, `data` objeto e ID no nulo. La aserción
revisada exige `String.valueOf(data.id) == vars.get('ordenId')`; el código
marca falla cuando esos valores difieren. El ID procede del POST inmediatamente
anterior, no de un valor fijo. Cada POST y GET tiene una pausa previa de
**6000 ms**: hasta seis solicitudes secuenciales para los tres pares.

## Evidencia de ejecución

Fuente existente, leída sin volver a ejecutar:
`test-results/performance/grupo07-ordenes-csv-correlation.jtl`.

SHA-256:
`43244D0FFFD3741696E5AF84664EAFF09DCC625A2549E8446F1EC9B9D4BCF895`.

Ventana: **2026-09-14 01:05:45.457–01:06:18.707 UTC**, un único hilo.
El método se identifica por la etiqueta y su sampler en el JMX; el JTL
registra URL, código, tiempo y resultado, pero no una columna de método.

| Orden | Método | Ruta observada | HTTP | elapsed (ms) | success |
|---|---|---|---|---|---|
| 1 | POST | `/api/v1/ordenes` | 201 | 1155 | true |
| 2 | GET | `/api/v1/ordenes/232` | 200 | 396 | true |
| 3 | POST | `/api/v1/ordenes` | 201 | 305 | true |
| 4 | GET | `/api/v1/ordenes/233` | 200 | 338 | true |
| 5 | POST | `/api/v1/ordenes` | 201 | 309 | true |
| 6 | GET | `/api/v1/ordenes/234` | 200 | 454 | true |

Los IDs 232, 233 y 234 son observaciones de esta corrida, no valores fijos del plan.

| Métrica | Resultado |
|---|---|
| Creaciones | 3 POST → HTTP 201 |
| Consultas correlacionadas | 3 GET → HTTP 200 |
| Muestras HTTP | 6 |
| Errores / tasa | 0 / 0.00 % |
| Promedio | 492 ms truncados; media exacta 2957/6 = 492.83 ms |
| Mínimo / máximo | 305 ms / 1155 ms |
| Duración aproximada | ≈40 s; precisión detallada a continuación |

El JTL cubre **33.250 s** desde la primera muestra hasta el fin de la última,
calculado con `timeStamp + elapsed`. No registra el inicio del proceso ni
la espera anterior a la primera muestra. Sumando los **6 s** iniciales
configurados resulta **≈39.250 s**, compatible con aproximadamente 40 s;
no es una medición exacta de la duración total. Las pausas entre solicitudes
observadas van de 6.008 a 6.203 s.

Las seis muestras tienen `success=true` y `failureMessage` vacío. Los tres
pares son consistentes con las tres iteraciones CSV. El JMX actual verifica
la igualdad del ID; el JTL no guarda bodies, valores CSV, resultados separados
de cada aserción ni hash del plan ejecutado, por lo que no permite reconstruir
esos contenidos por sí solo. Esta corrida corta no certifica capacidad ni SLA.
No se fabricaron capturas ni se generaron reportes Python.

**Conservación:** `.gitignore` ignora `test-results/` (línea 8).
No se modifica la regla ni se recomienda forzar el JTL al commit. Esta tabla
Markdown conserva la evidencia para el futuro PR; el original permanece local.

## Seguridad

`API_KEY` se obtiene del entorno con `System.getenv`; su valor no se
almacena en JMX, CSV, properties, evidencia ni documentación. POST y GET
comparten `x-api-key` mediante una variable en memoria. Las properties
deshabilitan el guardado de headers, bodies y sampler data.

El escaneo de los archivos de Tarea 1 y del JTL no detectó credenciales:
se revisaron referencias de autenticación, patrones de secretos y coincidencias
con claves disponibles localmente sin mostrarlas. El JTL contiene métricas,
rutas e IDs de órdenes; no contiene headers de autenticación ni bodies.
La revisión no abarca archivos ajenos a Tarea 1.

## Archivos de la entrega

- `tests/performance/plans/P_GRUPO_07_ORDENES_BASELINE.jmx`
- `tests/performance/properties/GRUPO_07_ORDENES_BASELINE.properties`
- `tests/performance/thresholds/GRUPO_07_ORDENES_BASELINE.json`
- `tests/performance/GRUPO_07_ORDENES_BASELINE.md`
- `tests/performance/plans/P_GRUPO_07_ORDENES_CSV.jmx`
- `tests/performance/data/D_GRUPO_07_ORDENES_CSV.csv`
- `tests/performance/properties/GRUPO_07_ORDENES_CSV.properties`
- `tests/performance/GRUPO_07_ORDENES_CSV.md`
- `tests/performance/GRUPO_07_TAREA_1_EVIDENCIA.md`

Los ocho artefactos existentes se conservan sin cambios; esta preparación
solo agrega este documento. La Tarea 1 queda preparada para el futuro PR
conjunto, sin trabajo de Tarea 2 ni cambios de workflows.
