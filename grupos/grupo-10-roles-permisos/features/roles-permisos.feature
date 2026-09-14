# Grupo 10 — Administración de Roles y Permisos
# Módulo: Gestión de usuarios internos (backoffice)
#
# Completar los escenarios BDD de este módulo.
# Ver ENTREGABLES.md: mínimo 3 escenarios (1 happy path, 1 negativo, 1 edge case).

Feature: Administración de Roles y Permisos
  Como administrador del backoffice
  Quiero gestionar usuarios internos y sus roles
  Para asegurar que cada usuario tenga los permisos correctos segun su funcion

  Scenario: Administrador crea un usuario interno y le asigna un rol exitosamente
    Given que un administrador ha iniciado sesion en el backoffice
    When crea un nuevo usuario interno con los datos requeridos
    And le asigna el rol "Editor"
    Then el sistema crea el usuario correctamente
    And el usuario queda visible en el listado con el rol "Editor" asignado

  Scenario: Usuario sin permisos de administracion intenta crear un usuario interno
    Given que un usuario con rol "Operador" ha iniciado sesion en el backoffice
    When intenta crear un nuevo usuario interno
    Then el sistema deniega la accion
    And muestra un mensaje indicando que no tiene permisos suficientes

  Scenario: Intentar desembolsar el monto límite máximo permitido para un Cajero
    Given que el usuario autenticado en el backoffice tiene el rol "Cajero"
    When intenta aprobar un desembolso por el monto límite exacto de "USD 49.999"
    Then el sistema procesa la transacción exitosamente
    And no solicita la autorización de un Gerente de Sucursal
  Scenario: Usuario con rol limitado intenta ejecutar una accion sobre el limite permitido
    Given que el usuario autenticado en el backoffice tiene el rol "Operador"
    When intenta ejecutar una accion que excede el limite permitido para su rol
    Then el sistema rechaza la accion
    And solicita la autorizacion de un usuario con rol "Administrador"

  Scenario: Intento de asignar un rol inexistente a un usuario interno
    Given que un administrador esta creando un nuevo usuario interno
    When intenta asignarle un rol que no existe en el sistema
    Then el sistema rechaza la asignacion
    And muestra un mensaje indicando que el rol no es valido

  Scenario: Usuario interno queda sin ningun rol asignado
    Given que un administrador edita un usuario interno existente
    When remueve el unico rol que tenia asignado sin seleccionar uno nuevo
    Then el sistema no permite guardar los cambios
    And muestra un mensaje solicitando que se asigne al menos un rol
