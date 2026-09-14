# PR semanal

Título sugerido: test(grupo-07): agregar checkout con SQL dinámico y evidencia de Semana 3

## Grupo

07 — Carrito de Compras / E-commerce

Integrante: Juan Marcelo Barreto.

## Semana

3 — Newman y evidencia

## Objetivo del avance

Extender RF-G7-02 para que el checkout obtenga un comprador real por SQL y verifique la
persistencia en `ordenes` e `items_orden`. Antes la colección solo validaba HTTP; ahora
el flujo exitoso comprueba ambas tablas y cantidad cero confirma el rechazo sin inserciones.

## Cambios realizados

- Carpeta `Semana 3 - SQL dinamico` con dos casos en la colección grupal existente.
- Helper SQL parametrizado de colección, variables por campo y bloqueo ante precondiciones fallidas.
- Marcadores únicos por intento para evitar interferencias con compras concurrentes.
- Environment vacío de secretos y runner Newman que genera evidencia reducida sin credenciales.
- Trazabilidad a RF-G7-02 y a los escenarios BDD existentes; cuatro pruebas locales de protección.
- Se conservan los 20 requests previos y los aportes individuales del equipo.
- Se integran los avances de la rama compartida, incluidas las correcciones de assertions y la Tarea 3 de Andrea; el conflicto del README se resuelve conservando ambas secciones.

## Evidencias adjuntas

- `grupos/grupo-07-carrito-ecommerce/evidence/semana-3-newman.json`: 18 assertions, 0 fallos, 12 solicitudes.
- `grupos/grupo-07-carrito-ecommerce/evidence/SEMANA-3.md`: resultados y alcance.
- `grupos/grupo-07-carrito-ecommerce/evidence/semana-3-aiquaa-validacion.json`: estructura válida.
- Protección local: 4 pruebas aprobadas; integridad de 20 requests originales y sintaxis de 25 scripts verificada.

## Riesgos o bloqueos

- Se requiere una API key válida de sandbox. Límite compartido: 30 solicitudes/minuto.
- Cada corrida exitosa deja una orden con dos ítems de prueba; esta ejecución creó la orden 125.
- El negativo verifica rechazo por validación, no un fallo provocado dentro de la transacción.
- Evidencia limitada a Semana 3; regresión completa, BDD y UI no ejecutados.
- Entrega mediante el PR #54 desde `jmbarret:grupo-07-carrito-ecommerce` hacia la rama compartida `stevenayal:grupo-07-carrito-ecommerce`; el PR grupal #51 integra esa rama hacia `main`.

## Checklist

- [x] Actualicé documentación relevante
- [x] Adjunté evidencias
- [x] Probé lo implementado
- [x] El PR representa el avance semanal real del grupo
