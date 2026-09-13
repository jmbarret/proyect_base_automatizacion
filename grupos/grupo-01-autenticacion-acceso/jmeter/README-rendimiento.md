# Ejecución y evidencias de JMeter

Esta configuración agrega pausas aleatorias de 1 a 2 segundos para reducir respuestas `429`, timeouts y una aserción global de tiempo máximo. Los valores pueden ajustarse por propiedades sin editar el plan.

## Ejecución recomendada

Ejecutar desde la carpeta `jmeter` del grupo:

```powershell
jmeter -n -t datos_dinamicos-sesiones.jmx `
  -JapiKey="API_KEY_DEL_ENTORNO" `
  -JconnectTimeoutMs=10000 `
  -JresponseTimeoutMs=30000 `
  -JmaxResponseMs=10000 `
  -JpauseBaseMs=1000 `
  -JpauseVariationMs=1000 `
  -l sesiones-resultados.jtl `
  -e -o reporte-html
```

Antes de repetir una ejecución, usar otro nombre para el archivo JTL y otro directorio de reporte, o retirar los resultados de la ejecución anterior. JMeter requiere que el directorio indicado con `-o` no exista o esté vacío.

## Qué revisar

- **Cantidad de solicitudes:** columna `# Samples` del reporte HTML o del Resumen de Resultados. El `Debug Sampler` también se contabiliza; deshabilitarlo para medir solamente las solicitudes HTTP finales.
- **Tiempos de respuesta:** promedio, mediana, percentiles 90/95/99, mínimo y máximo.
- **Porcentaje de errores:** columna `Error %`; revisar códigos HTTP y mensajes de assertions en el JTL.
- **Límite esperado:** toda respuesta que supere `maxResponseMs` falla la aserción `Tiempo máximo de respuesta`.
- **Respuestas 429:** aumentar `pauseBaseMs` o `pauseVariationMs` si aparecen; no ocultarlas ni excluirlas del porcentaje de errores.

Para una prueba de carga, ejecutar en modo no gráfico (`-n`). El listener `Ver Árbol de Resultados` es útil solamente para depuración con pocos usuarios; el JTL y el reporte HTML son las evidencias principales.

## Evidencias para el PR

Adjuntar o registrar: comando utilizado (sin exponer la API key), fecha y entorno, número de usuarios/iteraciones, total de solicitudes, promedio y p95, porcentaje de errores, códigos encontrados y una conclusión breve sobre el comportamiento observado.
