# Grupo 06 — Notificaciones y Alertas
# Módulo: Sistema de notificaciones (push/email/SMS)
#
# Flujo objetivo: notificación multicanal al usuario tras una operación bancaria.
# Este archivo entrega 8 escenarios:
# 2 happy path, 2 alternative path, 2 negativos y 2 edge case.

Feature: Notificaciones y Alertas
  Como usuario del sistema
  Quiero recibir alertas sobre mis operaciones
  Para mantenerme informado de manera oportuna y segura

  @happy_path
  Scenario: Enviar una notificación push después de una transferencia exitosa
    Given el usuario tiene habilitadas las notificaciones push
    And el usuario tiene un dispositivo registrado con un token vigente
    When se confirma una transferencia exitosa de 500000 Gs con el identificador "TRX-001"
    Then el sistema debe enviar una notificación push al dispositivo registrado
    And la notificación debe incluir el monto y el identificador de la transferencia

  @negative
  Scenario: No enviar una notificación push cuando el canal está desactivado
    Given el usuario tiene deshabilitadas las notificaciones push
    When se confirma una transferencia exitosa de 500000 Gs con el identificador "TRX-002"
    Then el sistema no debe enviar una notificación push al usuario
    And debe registrar que el canal fue omitido por preferencia del usuario

  @edge_case
  Scenario: Evitar notificaciones duplicadas ante el reprocesamiento de un evento
    Given el usuario tiene habilitadas las notificaciones push
    And existe una transferencia exitosa con el identificador "TRX-003"
    When el sistema procesa dos veces el evento de la transferencia "TRX-003"
    Then el usuario debe recibir una sola notificación push
    And debe existir un único registro de entrega asociado al identificador "TRX-003"

  @alternative_path
  Scenario: Usar email como canal de respaldo cuando el push no puede entregarse
    Given el usuario tiene habilitadas las notificaciones push y email
    And el usuario tiene un dispositivo registrado con un token vencido
    When se confirma una transferencia exitosa de 750000 Gs con el identificador "TRX-004"
    Then el sistema no debe entregar la notificación push por el token vencido
    And el sistema debe enviar una notificación por email al usuario
    And debe registrar el canal push como fallido y el email como entregado

  @edge_case
  Scenario: Diferir la notificación durante el horario silencioso del usuario
    Given el usuario tiene habilitadas las notificaciones push
    And el usuario configuró un horario silencioso entre las 22:00 y las 07:00
    When se confirma una transferencia exitosa de 500000 Gs con el identificador "TRX-005" a las 23:30
    Then el sistema no debe enviar la notificación push de inmediato
    And el sistema debe programar la entrega para las 07:00 del día siguiente

  @happy_path
  Scenario: Enviar una notificación por SMS después de una transferencia exitosa
    Given el usuario tiene habilitadas las notificaciones por SMS
    And el usuario tiene un número de teléfono válido registrado
    When se confirma una transferencia exitosa de 1000000 Gs con el identificador "TRX-006"
    Then el sistema debe enviar una notificación por SMS al número registrado
    And la notificación debe incluir el monto y el identificador de la transferencia

  @negative
  Scenario: No enviar una notificación por SMS cuando el número de teléfono es inválido
    Given el usuario tiene habilitadas las notificaciones por SMS
    And el usuario tiene un número de teléfono inválido registrado
    When se confirma una transferencia exitosa de 600000 Gs con el identificador "TRX-007"
    Then el sistema no debe entregar la notificación por SMS
    And debe registrar el intento de entrega como fallido

  @alternative_path
  Scenario: Enviar notificaciones por múltiples canales según las preferencias del usuario
    Given el usuario tiene habilitadas las notificaciones push y email
    And el usuario tiene un dispositivo y un correo electrónico válidos registrados
    When se confirma una transferencia exitosa de 1200000 Gs con el identificador "TRX-009"
    Then el sistema debe enviar una notificación push al dispositivo registrado
    And el sistema debe enviar una notificación por email al usuario
    And debe registrar ambos canales como entregados

  @happy_path
  Scenario: Enviar una notificación por email como canal principal después de una transferencia exitosa
    Given el usuario tiene habilitadas las notificaciones por email como canal principal
    And el usuario tiene una dirección de correo electrónico válida registrada
    When se confirma una transferencia exitosa de 850000 Gs con el identificador "TRX-010"
    Then el sistema debe enviar una notificación por email a la dirección registrada
    And la notificación debe incluir el monto y el identificador de la transferencia
