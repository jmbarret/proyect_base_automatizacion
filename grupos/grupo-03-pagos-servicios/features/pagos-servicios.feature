# Grupo 03 — Pagos de Servicios
# Módulo: Pago de facturas (ANDE, ESSAP, telefonía)
#
# Completar los escenarios BDD de este módulo.
# Ver ENTREGABLES.md: mínimo 3 escenarios (1 happy path, 1 negativo, 1 edge case).

Feature: Pagos de Servicios
  Como usuario
  Quiero realizar el pago de mis facturas (ANDE, ESSAP, telefonía)
  Para mantener mis cuentas al día

  # TODO: Scenario: happy path
  
    Scenario: Pago exitoso de factura de ANDE
      Given el usuario posee factura ANDE pendiente de pago
      When el usuario realiza el pago de la factura
      Then la factura cambia a estado pagada
      And se genera el comprobante de pago procesado
      And el monto del comprobante de pago coincide con el monto de la factura

    Scenario: Pago exitoso de una factura ESSAP
      Given el usuario tiene una factura de ESSAP pendiente de pago
      When el usuario realiza el pago de la factura
      Then el sistema debe confirmar el pago correctamente
      And se genera el comprobante de pago procesado
      And el monto de pago coincide con el de la factura

    Scenario: Pago exitoso de factura de telefonia
      Given el usuario tiene una factura de telefonia pendiente de pago
      When el usuario selecciona el numero de linea y confirma el pago
      Then el sistema muestra el comprobante de pago exitoso
    

  # TODO: Scenario: caso negativos
  
    Scenario: Pago de una factura de ANDE inexistente
      Given que el usuario ingresa un identificador de factura que no existe en el sistema
      When el usuario realiza el pago de la factura inexistente
      Then el sistema rechaza la operación
      And muestra el mensaje indicando que la factura no fue encontrada o ya pagada

    Scenario: Pago de una factura con numero invalido de ESSAP 
      Given el usuario ingresa un numero identificador de ESSAP inexistente
      When el usuario intenta realizar el pago
      Then el sistema debe mostrar un mensaje de error
      And muestra el mensaje indicando que la factura no fue encontrada o ya fue pagada

    Scenario: Intento de pago de telefonia sin deuda pendiente
      Given el usuario no tiene facturas de telefonia pendientes de pago
      When el usuario intenta realizar un pago
      Then el sistema muestra un mensaje indicando que no existe deuda pendiente
    
    Scenario: Pago de telefonía rechazado por número de línea inválido
      Given el usuario ingresa un número de línea de telefonía inexistente
      When el usuario intenta realizar un pago
      Then el el sistema rechaza la operación

    Scenario: Pago de factura de telefonia con numero de linea invalido
      Given el usuario ingresa un numero de linea de telefonia invalido
      When el usuario intenta consultar la factura
      Then el sistema muestra un mensaje indicando que no se encontro la linea
      And no permite continuar con el pago

  # TODO: Scenario: edge case
  
    Scenario: Factura de ANDE ya pagada anteriormente
      Given la factura de ANDE ya fue pagada con anterioridad
      When el usuario intenta pagar nuevamente la misma factura
      Then el sistema indica que la factura no fue encontrada o ya se encuentra pagada

    Scenario: Factura de ESSAP ya pagada anteriormente
      Given la factura de ESSAP ya fue pagada con anterioridad
      When el usuario intenta pagar nuevamente la misma factura
      Then el sistema indica que la factura no fue encontrada o ya se encuentra pagada

    Scenario: Pago de factura de telefonia el mismo dia del vencimiento
      Given el usuario tiene una factura de telefonia pendiente con vencimiento en el dia de hoy
      When el usuario realiza el pago antes de la hora limite
      Then el sistema procesa el pago correctamente
      And el sistema muestra el comprobante de pago

  # ===== ESCENARIOS MEJORADOS BASADOS EN REQUERIMIENTOS REALES =====
  
  Background:
    Given el usuario tiene una API key válida y activa
    And el sandbox tiene datos de prueba con facturas pendientes, pagadas y vencidas

  # Happy Path - RF-G3-03: Pagar una factura (todos los proveedores)
  @happy-path @pago-exitoso
  Scenario: Pago exitoso de factura ANDE pendiente
    Given existe una factura de ANDE en estado pendiente para el usuario
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el monto del pago es igual al monto de la factura
    And el usuario_id del pago coincide con el titular de la factura

  @happy-path @pago-exitoso
  Scenario: Pago exitoso de factura ESSAP pendiente
    Given existe una factura de ESSAP en estado pendiente para el usuario
    When el usuario paga la factura con metodoPago "cuenta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el monto del pago es igual al monto de la factura

  @happy-path @pago-exitoso
  Scenario: Pago exitoso de factura COPACO pendiente
    Given existe una factura de COPACO en estado pendiente para el usuario
    When el usuario paga la factura con metodoPago "efectivo"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el monto del pago es igual al monto de la factura

  @happy-path @pago-exitoso
  Scenario: Pago exitoso de factura Tigo pendiente
    Given existe una factura de Tigo en estado pendiente para el usuario
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"

  @happy-path @pago-exitoso
  Scenario: Pago exitoso de factura Personal pendiente
    Given existe una factura de Personal en estado pendiente para el usuario
    When el usuario paga la factura con metodoPago "cuenta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"

  @happy-path @pago-exitoso @edge-case
  Scenario: Pago exitoso de factura vencida (sin recargos)
    Given existe una factura de ANDE en estado vencida para el usuario
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el monto del pago es igual al monto original de la factura (sin recargos)

  # Casos Negativos - RF-G3-03
  @negativo @factura-inexistente
  Scenario: Pago de factura inexistente
    Given el usuario intenta pagar una factura con ID que no existe
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"
    And el mensaje de error es "Factura no encontrada o ya pagada."
    And no se crea ningún registro en la tabla pagos

  @negativo @factura-ya-pagada
  Scenario: Pago de factura ya pagada (doble pago)
    Given existe una factura de ANDE en estado pagada para el usuario
    When el usuario intenta pagar nuevamente la misma factura
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"
    And el mensaje de error es "Factura no encontrada o ya pagada."
    And no se crea un segundo registro de pago

  @negativo @metodo-pago-invalido
  Scenario: Pago con metodoPago inválido
    Given existe una factura de ANDE en estado pendiente para el usuario
    When el usuario paga la factura con metodoPago "cripto"
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"
    And la factura conserva su estado anterior "pendiente"
    And no se crea ningún registro en la tabla pagos

  @negativo @metodo-pago-faltante
  Scenario: Pago sin metodoPago en el cuerpo
    Given existe una factura de ESSAP en estado pendiente para el usuario
    When el usuario intenta pagar la factura sin enviar metodoPago
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"
    And la factura conserva su estado "pendiente"

  @negativo @id-invalido
  Scenario: Pago con ID de factura no numérico
    When el usuario intenta pagar con ID "abc" en la ruta
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  # Edge Cases - RF-G3-03
  @edge-case @pago-mismo-dia-vencimiento
  Scenario: Pago de factura el mismo día del vencimiento
    Given existe una factura de Tigo pendiente con fecha_vencimiento igual a hoy
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"

  @edge-case @factura-dada-de-baja
  Scenario: Pago de factura dada de baja (soft delete)
    Given existe una factura de ANDE que fue dada de baja (activo = false)
    When el usuario intenta pagar la factura
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"

  @edge-case @concurrencia
  Scenario: Intentos concurrentes de pago de la misma factura
    Given existe una factura de ANDE en estado pendiente para el usuario
    When dos usuarios intentan pagar la misma factura simultáneamente
    Then una transacción tiene éxito (200 OK) y la factura queda "pagada"
    And la otra transacción falla con 404 NOT_FOUND ("Factura no encontrada o ya pagada.")
    And solo se crea un registro en la tabla pagos

  # Listar facturas - RF-G3-01
  @listar-facturas
  Scenario: Listar facturas filtrando por estado pendiente
    Given existen facturas de varios estados para el usuario
    When el usuario lista facturas con filtro estado="pendiente"
    Then la respuesta tiene código 200 OK
    And todas las facturas devueltas tienen estado "pendiente"
    And el número de resultados es menor o igual a 100

  @listar-facturas
  Scenario: Listar facturas filtrando por usuario y estado
    Given existen facturas de ANDE y ESSAP para el usuario 1
    When el usuario lista facturas con filtro usuarioId=1 y estado="pagada"
    Then la respuesta tiene código 200 OK
    And todas las facturas devueltas pertenecen al usuario 1
    And todas las facturas devueltas tienen estado "pagada"

  @listar-facturas
  Scenario: Listar facturas con estado inválido
    When el usuario lista facturas con filtro estado="anulada"
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  @listar-facturas
  Scenario: Listar facturas de usuario sin facturas
    Given el usuario 999 no tiene facturas asociadas
    When el usuario lista facturas con filtro usuarioId=999
    Then la respuesta tiene código 200 OK
    And la lista de facturas está vacía

  # Consultar factura - RF-G3-02
  @consultar-factura
  Scenario: Consultar factura existente
    Given existe una factura con ID 1 de proveedor ANDE
    When el usuario consulta la factura por ID
    Then la respuesta tiene código 200 OK
    And la factura devuelta tiene numero_factura correspondiente
    And la factura incluye proveedor, monto, fecha_vencimiento, estado

  @consultar-factura
  Scenario: Consultar factura inexistente
    When el usuario consulta una factura con ID 999999
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"
    And el mensaje de error es "Factura no encontrada."

  @consultar-factura
  Scenario: Consultar factura después de pagarla
    Given existe una factura de ANDE en estado pendiente
    When el usuario paga la factura
    And el usuario consulta la misma factura por ID
    Then la respuesta tiene código 200 OK
    And la factura devuelta tiene estado "pagada"

  # Crear factura - RF-G3-04
  @crear-factura
  Scenario: Crear factura válida
    Given el usuario tiene ID 1
    When el usuario crea una factura con proveedor "ANDE", numeroFactura "FAC-NEW-001", monto 50000, fechaVencimiento "2026-12-31"
    Then la respuesta tiene código 201 Created
    And la factura creada tiene estado "pendiente"
    And la factura aparece en el listado filtrando por ese usuario

  @crear-factura
  Scenario: Crear factura con numeroFactura duplicado
    Given existe una factura con numeroFactura "FAC-EXISTENTE"
    When el usuario intenta crear otra factura con el mismo numeroFactura
    Then la respuesta tiene código 409 CONFLICT
    And el error tiene código "CONFLICT"

  @crear-factura
  Scenario: Crear factura con proveedor inválido
    When el usuario crea una factura con proveedor "Claro"
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  @crear-factura
  Scenario: Crear factura para usuario inexistente
    When el usuario crea una factura con usuarioId 999999
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  @crear-factura
  Scenario: Crear factura con fechaVencimiento pasada
    When el usuario crea una factura con fechaVencimiento "2020-01-01"
    Then la respuesta tiene código 201 Created
    And la factura se crea con estado "pendiente"
    And la fecha_vencimiento se guarda como enviada

  # Reemplazar factura - RF-G3-05
  @reemplazar-factura
  Scenario: Reemplazar factura pendiente
    Given existe una factura de ANDE en estado pendiente
    When el usuario reemplaza la factura con nuevo monto 75000
    Then la respuesta tiene código 200 OK
    And la factura actualizada tiene monto 75000
    And la factura mantiene estado "pendiente"

  @reemplazar-factura
  Scenario: Reemplazar factura con numeroFactura duplicado
    Given existe una factura con numeroFactura "FAC-001"
    And existe otra factura con ID 2 y numeroFactura "FAC-002"
    When el usuario intenta reemplazar la factura 2 con numeroFactura "FAC-001"
    Then la respuesta tiene código 409 CONFLICT
    And el error tiene código "CONFLICT"

  @reemplazar-factura
  Scenario: Reemplazar factura inexistente o dada de baja
    When el usuario intenta reemplazar una factura con ID 999999
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"

  # Dar de baja factura - RF-G3-06
  @dar-de-baja
  Scenario: Dar de baja factura vigente
    Given existe una factura de ANDE en estado pendiente
    When el usuario da de baja la factura
    Then la respuesta tiene código 204 No Content
    And la factura no aparece en GET /facturas
    And GET /facturas/{id} responde 404

  @dar-de-baja
  Scenario: Dar de baja factura ya pagada
    Given existe una factura de ESSAP en estado pagada
    When el usuario da de baja la factura
    Then la respuesta tiene código 204 No Content
    And los pagos asociados se conservan en la tabla pagos

  @dar-de-baja
  Scenario: Dar de baja factura inexistente
    When el usuario intenta dar de baja una factura con ID 999999
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"

  # Reglas transversales
  @transversal @auth
  Scenario: Request sin API key
    When el usuario hace request a cualquier endpoint sin header x-api-key
    Then la respuesta tiene código 401 UNAUTHORIZED
    And el mensaje es "Invalid or inactive API key."

  @transversal @auth
  Scenario: Request con API key inválida
    When el usuario hace request con x-api-key inválida
    Then la respuesta tiene código 401 UNAUTHORIZED
    And el mensaje es "Invalid or inactive API key."

  @transversal @rate-limit
  Scenario: Rate limit excedido
    Given una API key con límite de 30 requests/minuto
    When el usuario hace 31 requests en menos de un minuto
    Then la respuesta 31 tiene código 429 RATE_LIMITED
    And la respuesta incluye headers Retry-After, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
