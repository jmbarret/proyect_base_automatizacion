# JMeter — Grupo 01: Autenticación y Acceso

Plan grupal para probar el rendimiento de los endpoints de sesiones con datos dinámicos.

## Distribución del trabajo

- **Mariel Aquino:** CSV `data/datos_sesiones_validado.csv`.
- **Mariset C. Lorente:** estructura principal, configuración HTTP, variables, cabeceras, grupo de hilos, lectura del CSV y control del rate limit.
- **Gloria Figueredo:** `GET /api/v1/sesiones` con `usuarioId` dinámico y assertions HTTP/JSON.
- **David Cristaldo:** `POST /api/v1/sesiones` con datos dinámicos y assertions HTTP/JSON.
- **Oscar Benítez:** timeouts, pausa anti-429, límite de duración, resultados y guía de evidencias.

## Configuración incluida por Mariset

- URL predeterminada del sandbox y timeouts HTTP.
- Cabeceras `Content-Type` y `x-api-key`.
- API key recibida mediante la propiedad `apiKey`, sin guardarla en Git.
- CSV compartido entre los usuarios virtuales, sin reciclar filas.
- Carga parametrizable y conservadora para respetar el rate limit.
- Controladores separados para incorporar el GET y el POST.

## Parámetros de ejecución

| Propiedad | Predeterminado | Descripción |
|---|---:|---|
| `apiKey` | vacío | API key obligatoria del sandbox. |
| `threads` | `1` | Usuarios virtuales. |
| `rampUp` | `1` | Arranque en segundos. |
| `loops` | `6` | Una iteración por fila del CSV. |
| `pauseBaseMs` | `3000` | Pausa mínima para evitar HTTP 429. |
| `pauseVariationMs` | `1000` | Variación aleatoria adicional de la pausa. |
| `connectTimeoutMs` | `10000` | Timeout de conexión. |
| `responseTimeoutMs` | `30000` | Timeout de respuesta. |
| `maxResponseMs` | `10000` | Duración máxima aceptada por la assertion global. |
| `csvPath` | CSV del grupo | Ruta del archivo dinámico. |

Ejemplo de ejecución del plan completo con GET y POST:

```bash
jmeter -n \
  -t grupos/grupo-01-autenticacion-acceso/jmeter/datos_dinamicos-sesiones.jmx \
  -JapiKey="API_KEY_DEL_SANDBOX" \
  -l resultados-grupo01.jtl
```

No se debe guardar la API key dentro del `.jmx` ni del CSV.
