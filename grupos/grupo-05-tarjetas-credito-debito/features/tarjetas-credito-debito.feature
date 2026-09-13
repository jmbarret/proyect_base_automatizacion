# Grupo 05 — Tarjetas de Crédito/Débito
# Módulo: Gestión de tarjetas
#
# Escenarios BDD del módulo de gestión de tarjetas de crédito/débito.
# Ver ENTREGABLES.md: mínimo 3 escenarios (1 happy path, 1 negativo, 1 edge case).

Feature: Gestión de tarjetas de crédito/débito
  Como cliente del banco
  Quiero realizar gestiones de mis tarjetas de crédito/débito
  Para mantenerme al día con los últimos ajustes de mi tarjeta

  # Scenario: happy path - Emilio Oheler
  Scenario: Ver datos tarjeta
    Given el cliente está autenticado en la app con biometría válida
    And posee una tarjeta de crédito/débito
    When el cliente solicita visualizar los datos de la tarjeta
    Then se muestra el numero de tarjeta, vencimiento y datos adicionales

  # Scenario: happy path - Emilio Oheler
  Scenario: Cambio exitoso de PIN
    When el cliente cambia el PIN actual por un nuevo PIN
    Then el sistema confirma el cambio con el mensaje "PIN actualizado"
    And el nuevo PIN es requerido en la siguiente transacción

  # Scenario: happy path - Rafael Estigarribia
  Scenario: Bloqueo temporal por tarjeta perdida
    When el cliente reporta la tarjeta como "PERDIDA"
    Then la tarjeta queda con estado "BLOQUEO_TEMPORAL"
    And el bloqueo se aplica en todos los canales
    And las autorizaciones posteriores son rechazadas
    And se genera una notificación correspondiente al cliente

  # Scenario: happy path - Rafael Estigarribia
  Scenario: Desbloqueo exitoso de tarjeta bloqueada
    Given la tarjeta tiene estado "BLOQUEADA" por motivo del "CLIENTE"
    When el cliente solicita el desbloqueo
    And autentica con biometría válida
    Then la tarjeta queda con estado "ACTIVA"
    And el sistema confirma el desbloqueo por el medio de notificacion optado por el cliente

  # Scenario: happy path - Ivan Bolaños
  Scenario: Aumento exitoso de límite diario de compras
    When el cliente modifica el límite "compras_comercio" a un monto diario superior
    And confirma con OTP válido
    Then el nuevo límite diario queda confirmado
    And el cambio es efectivo inmediatamente para nuevas autorizaciones

  # Scenario: happy path - Ivan Bolaños
  Scenario: Pago exitoso desde cuenta propia
    When el cliente paga un monto generado a la tarjeta desde su cuenta vista
    Then el pago se registra con estado "APROBADA"
    And se genera el comprobante con número único

  # Scenario: caso negativo - Marcos Trinidad
  Scenario: Aumento de límite diario rechazado por OTP inválido
    Given la tarjeta tiene estado "ACTIVA"
    When el cliente modifica el límite "compras_comercio" a un monto diario superior
    And confirma con un OTP inválido
    Then el sistema rechaza el cambio con el mensaje "Código OTP inválido"
    And el límite diario se mantiene sin cambios
    And se registra el intento fallido en la bitácora de la tarjeta

      # Scenario: caso negativo - Matias Murto
  Scenario: Cambio de PIN rechazado por PIN actual incorrecto
    Given la tarjeta tiene estado "ACTIVA"
    When el cliente intenta cambiar el PIN ingresando un PIN actual incorrecto
    Then el sistema rechaza el cambio con el mensaje "PIN actual incorrecto"
    And el PIN vigente se mantiene sin cambios
    And se incrementa el contador de intentos fallidos de la tarjeta

  # Scenario: caso negativo - Matias Murto
  Scenario: Pago rechazado por saldo insuficiente en cuenta vista
    Given la tarjeta tiene estado "ACTIVA"
    And el saldo disponible de la cuenta vista es 100000 PYG
    When el cliente intenta pagar 500000 PYG a la tarjeta
    Then el pago se registra con estado "RECHAZADA"
    And el motivo de rechazo es "Fondos insuficientes"
    And el saldo adeudado de la tarjeta se mantiene sin cambios

  # Scenario: edge case - Matias Murto
  Scenario: Compra autorizada por un monto exactamente igual al límite diario
    Given la tarjeta tiene estado "ACTIVA"
    And el límite "compras_comercio" es 5000000 PYG
    And el consumo acumulado del día es 0 PYG
    When se solicita la autorización de una compra por 5000000 PYG
    Then la autorización se registra con estado "APROBADA"
    And el disponible diario de "compras_comercio" queda en 0 PYG
    And una compra adicional por 1 PYG es rechazada por "Límite diario excedido"

  # Scenario: edge case - Matias Murto
  Scenario: Desbloqueo denegado cuando el bloqueo fue por motivo "ROBO"
    Given la tarjeta tiene estado "BLOQUEADA" por motivo "ROBO"
    When el cliente solicita el desbloqueo
    And autentica con biometría válida
    Then el sistema rechaza la solicitud con el mensaje "Tarjeta no habilitada para desbloqueo"
    And la tarjeta mantiene el estado "BLOQUEADA"
    And el sistema ofrece iniciar el proceso de reposición de tarjeta
