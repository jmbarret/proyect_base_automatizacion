# Evidencia — Semana 3 / Grupo 7

- Alcance: RF-G7-02, carpeta `Semana 3 - SQL dinamico`.
- Sandbox: https://aiquaa-sandbox-api.vercel.app
- Corrida real: 2026-09-07 00:22:42–00:22:51 UTC (6 de septiembre, 21:22 en Asunción).
- Newman: 6.2.2. Base Git: `199f26db36b82f4a703ba4e3dac0785df8f9af56` más cambios de Semana 3.
- Resultado: **18 assertions aprobadas, 0 fallos, 12 solicitudes**.
- Detalle reproducible sin headers ni credenciales: [semana-3-newman.json](semana-3-newman.json).

| Comprobación | Resultado observado |
|---|---|
| Comprador obtenido por SQL | usuario 1, leído dinámicamente en cada caso |
| Checkout | HTTP 201; orden 125; monto 26.25; estado pendiente |
| Persistencia | SQL confirmó 1 cabecera y 2 ítems con cantidades/precios/subtotales correctos |
| Cantidad cero | HTTP 400, VALIDATION_ERROR |
| Ausencia de inserciones del negativo | Ordenes 0 → 0; items_orden 0 → 0, filtrados por marcadores del intento |

Verificación adicional local: `node --test grupos/grupo-07-carrito-ecommerce/tests/api/sql-prerequest.test.cjs`.
**4/4 pruebas aprobadas**: clave ausente, SQL 401, respuesta SQL HTML y ausencia de compradores.
En todos los casos se registró el fallo de precondición y hubo cero requests de negocio,
incluso con un ID residual en el environment.

AIQUAA: colección estructuralmente válida; [reporte](semana-3-aiquaa-validacion.json).
Las advertencias corresponden a escenarios que comparten método/URL y a variables locales
generadas en runtime (`g7UsuarioId`, `g7Producto1/2`), no a errores de ejecución.

Integridad de la corrida registrada: los 20 requests originales son iguales a `199f26d`; 25 scripts JavaScript compilan;
`git diff --check` sin errores. Las colecciones individuales no fueron modificadas.
No se ejecutaron la regresión completa, BDD ni UI. La orden 125 permanece como dato de prueba.

Verificación de entrega: se integró `c5ad3a9` de la rama compartida, conservando las
correcciones de assertions y el trabajo de Andrea. Los 20 requests de regresión coinciden
con esa rama; los dos casos SQL de Semana 3 permanecen intactos y las cuatro pruebas
locales de protección vuelven a pasar. No se repitió la corrida del sandbox.
