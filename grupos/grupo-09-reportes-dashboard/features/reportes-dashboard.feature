# Grupo 09 — Reportes y Dashboard
# Módulo: Panel de control / reportes financieros
#
# Completar los escenarios BDD de este módulo.
# Ver ENTREGABLES.md: mínimo 3 escenarios (1 happy path, 1 negativo, 1 edge case).

Feature: Reportes y Dashboard

  # TODO: Scenario: happy path
  # TODO: Scenario: caso negativo
  # TODO: Scenario: edge case
  # Todo: Scenario: Comparativa

# Scenario 1: happy path
Scenario: Generar reporte financiero correctamente
  Given el usuario se encuentra en el módulo de reportes
  When solicita generar un reporte financiero
  Then el sistema debe generar y mostrar el reporte correctamente

Caso Positivo -Claudio Cabrera
Escenario: Visualizar reporte financiero del mes 
Dado que el usuario ha iniciado sesión
Cuando consulta el reporte financiero del mes actual
Entonces se cargan las métricas y gráficos del panel de control.

Caso Negativo -Claudio Cabrera
Escenario: Consultar reporte en un período sin datos 
Dado que el usuario ha iniciado sesión
Cuando filtra el reporte para un año sin transacciones
Entonces se muestra un mensaje de "Sin datos disponibles".

Caso Limite - Claudio Cabrera
Escenario: Filtrar el rango máximo de años permitido 
Dado que el usuario ha iniciado sesión
Cuando selecciona un rango de fechas de 10 años
Entonces el reporte se genera agrupando los datos sin dar error de tiempo de espera.
