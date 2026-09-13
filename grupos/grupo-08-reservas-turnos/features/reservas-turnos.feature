# Grupo 08 — Reservas / Turnos
# Módulo: Sistema de reserva de citas
#
# Completar los escenarios BDD de este módulo.
# Ver ENTREGABLES.md: mínimo 3 escenarios (1 happy path, 1 negativo, 1 edge case).

Feature: Reservas / Turnos

  # CP001 - Paciente - Reservar un turno disponible correctamente
    *Give: El usuario encuentra turno disponible
    *When: El usuario selecciona especialidad, fecha y horario disponible.
    *Then: El sistema debe registrar la reserva correctamente.

  # CP002 - Paciente - Intentar reservar un horario ocupado
    *Give: El usuario se encuentra autenticado en el sistema.
    *When: El usaurio selecciona fecha y horario ya reservado.
    *Then: El sistema no debe permitir realizar la reserva.

  Scenario: Consulta exitosa de turnos disponibles
  Given existen turnos disponibles para reservar
  When el usuario consulta los turnos disponibles
  Then el sistema debe mostrar los turnos disponibles correctamente

  Scenario: Consulta exitosa de una reserva existente
  Given existe una reserva registrada
  When el usuario consulta la reserva
  Then el sistema debe mostrar los datos de la reserva correctamente
  
  Scenario: Consulta de turnos sin disponibilidad
  Given no existen turnos disponibles para la fecha seleccionada
  When el usuario consulta los turnos disponibles
  Then el sistema debe informar que no existen turnos disponibles
  
  Scenario: Reserva con fecha anterior a la actual
  Given existen turnos registrados en el sistema
  When el usuario intenta realizar una reserva para una fecha anterior a la actual
  Then el sistema debe rechazar la reserva
  
  Scenario: Reserva simultanea del ultimo turno disponible
  Given existe un unico turno disponible
  When dos usuarios intentan reservar el mismo turno al mismo tiempo
  Then el sistema debe confirmar la reserva para un solo usuario y rechazar la otra solicitud



  # TODO: Scenario: happy path
  # TODO: Scenario: caso negativo
Scenario: Reserva con fecha y hora pasada
	Given el usuario se encuentra en la pantalla de reserva e ingresa una fecha y  hora anterior al actual 
	When intenta confirmar la reserva 
	Then el sistema debe rechazar la reserva y mostrar mensaje de que la fecha no está disponible.
Scenario: Intentar reservar sin completar todos los datos requeridos
	Given el usuario se encuentra en la pantalla de reserva e ingresa los datos dejando al menos un campo obligatorio vacío
	When intenta confirmar la reserva
	Then el sistema debe rechazar la reserva y mostrar un mensaje indicando que el campo obligatorio debe ser completado



  # TODO: Scenario: edge case

  Scenario: Cancelación de turno exitosa
    Given el usuario tiene un turno reservado
    When el usuario solicita cancelar el turno
    Then el sistema debe liberar el horario para otros usuarios


Scenario: Confirmación de asistencia antes del turno
Given el usuario tiene una reserva en estado "Pendiente de confirmación"
And el sistema envía una notificación de recordatorio 24 horas antes
When el paciente presiona el botón "Confirmar Asistencia"
Then el sistema debe cambiar el estado del turno a "Confirmado por el usuario"

    
Scenario: Intentar cancelar un turno fuera del plazo permitido de cancelación
Given la política del local requiere cancelar con al menos 2 horas de anticipación
And el paciente posee un turno dentro de 30 minutos
When el usuaro solicita la cancelación del turno
Then el sistema debe rechazar la cancelación
  
  
Scenario: Cambio de horario de atención en día festivo
Given el local modifca su horario de atención para un día festivo de "09:00 a 12:00"
When el paciente intenta buscar turnos para ese día festivo a las "16:00"
Then el sistema debe restringir los los horarios visibles únicamente al rango de "09:00 a 12:00"