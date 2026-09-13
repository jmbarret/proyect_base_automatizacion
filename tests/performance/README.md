# Rendimiento — Grupo 04 Onboarding

El plan prueba el flujo principal de alta de usuarios en AIQUAA Sandbox:

1. Lee una fila de `data/grupo04-usuarios.csv`.
2. Genera un correo y un documento únicos antes del `POST /api/v1/usuarios`.
3. Extrae el identificador con JSONPath `$.data.id`.
4. Usa ese valor en `GET /api/v1/usuarios/{id}`.
5. Verifica códigos HTTP 201 y 200.

La pausa predeterminada de 2500 ms evita exceder el límite de 30 solicitudes
por minuto del entorno de laboratorio con la configuración recomendada de un
usuario y tres iteraciones.

## Ejecución local

```bash
jmeter -n \
  -t tests/performance/plans/Grupo04_Onboarding.jmx \
  -l test-results/performance/grupo04-resultados.jtl \
  -e -o test-results/performance/dashboard \
  -JcsvPath=tests/performance/data/grupo04-usuarios.csv \
  -JapiKey=TU_API_KEY \
  -Jthreads=1 -Jloops=3 -JdelayMs=2500
```

No se debe guardar la API key en el repositorio. En GitHub se configura como
secreto `GRUPO04_API_KEY`. El workflow manual permite cambiar threads y loops;
para aumentar la carga también debe recalcularse la pausa y respetarse el rate
limit del sandbox.

Los umbrales se encuentran en `thresholds/grupo04-thresholds.json`: máximo 5 %
de errores y percentil 95 menor o igual a 2000 ms.
