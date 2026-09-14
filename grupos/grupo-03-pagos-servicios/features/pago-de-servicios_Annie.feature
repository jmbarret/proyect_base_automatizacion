# Feature: Pagos de Servicios - Proveedor ESSAP
# Grupo 03 — Annie
# Basado en: docs/requerimientos/grupo-03-pagos-de-servicios.md (v1.0)
# Cobertura: RF-G3-01 a RF-G3-06 solo para proveedor ESSAP

Feature: Pagos de Servicios - Proveedor ESSAP
  Como usuario de negocio
  Quiero gestionar y pagar mis facturas de ESSAP
  Para mantener mis servicios de agua al día

  Background:
    Given el usuario tiene una API key válida y activa
    And el sandbox tiene datos de prueba con facturas de ESSAP en estados pendiente, pagada y vencida
    And el titular de prueba tiene usuario_id = 1

  # =========================================================================
  # RF-G3-01: Listar facturas GET /api/v1/facturas
  # =========================================================================

  @RF-G3-01 @listar @happy-path
  Scenario: Listar facturas de ESSAP filtrando por estado pendiente
    Given existen facturas de ESSAP con diferentes estados para el usuario 1
    When el usuario lista facturas con filtro proveedor="ESSAP" y estado="pendiente"
    Then la respuesta tiene código 200 OK
    And todas las facturas devueltas tienen proveedor "ESSAP"
    And todas las facturas devueltas tienen estado "pendiente"
    And el número de resultados es menor o igual a 100

  @RF-G3-01 @listar @happy-path
  Scenario: Listar facturas de ESSAP filtrando por usuario y estado
    Given existen facturas de ESSAP y ANDE para el usuario 1
    When el usuario lista facturas con filtro usuarioId=1 y estado="pagada" y proveedor="ESSAP"
    Then la respuesta tiene código 200 OK
    And todas las facturas devueltas pertenecen al usuario 1
    And todas las facturas devueltas tienen proveedor "ESSAP"
    And todas las facturas devueltas tienen estado "pagada"

  @RF-G3-01 @listar @negativo
  Scenario: Listar facturas con estado inválido
    When el usuario lista facturas con filtro estado="anulada"
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  @RF-G3-01 @listar @edge-case
  Scenario: Listar facturas de ESSAP para usuario sin facturas
    Given el usuario 999 no tiene facturas de ESSAP asociadas
    When el usuario lista facturas con filtro usuarioId=999 y proveedor="ESSAP"
    Then la respuesta tiene código 200 OK
    And la lista de facturas está vacía

  # =========================================================================
  # RF-G3-02: Consultar una factura GET /api/v1/facturas/{id}
  # =========================================================================

  @RF-G3-02 @consultar @happy-path
  Scenario: Consultar factura de ESSAP existente
    Given existe una factura de ESSAP con ID conocido para el usuario 1
    When el usuario consulta la factura por ID
    Then la respuesta tiene código 200 OK
    And la factura devuelta tiene proveedor "ESSAP"
    And la factura incluye numero_factura, monto, fecha_vencimiento, estado y created_at

  @RF-G3-02 @consultar @negativo
  Scenario: Consultar factura de ESSAP inexistente
    When el usuario consulta una factura con ID 999999
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"
    And el mensaje de error es "Factura no encontrada."

  @RF-G3-02 @consultar @happy-path
  Scenario: Consultar factura de ESSAP después de pagarla
    Given existe una factura de ESSAP en estado pendiente para el usuario 1
    When el usuario paga la factura con metodoPago "tarjeta"
    And el usuario consulta la misma factura por ID
    Then la respuesta tiene código 200 OK
    And la factura devuelta tiene estado "pagada"
    And la factura devuelta tiene proveedor "ESSAP"

  # =========================================================================
  # RF-G3-03: Pagar una factura POST /api/v1/facturas/{id}/pagar
  # =========================================================================

  @RF-G3-03 @pagar @happy-path
  Scenario: Pago exitoso de factura de ESSAP pendiente con tarjeta
    Given existe una factura de ESSAP en estado pendiente para el usuario 1
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el monto del pago es igual al monto de la factura
    And el usuario_id del pago coincide con el titular de la factura
    And el metodo_pago del pago es "tarjeta"

  @RF-G3-03 @pagar @happy-path
  Scenario: Pago exitoso de factura de ESSAP pendiente con cuenta
    Given existe una factura de ESSAP en estado pendiente para el usuario 1
    When el usuario paga la factura con metodoPago "cuenta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el metodo_pago del pago es "cuenta"

  @RF-G3-03 @pagar @happy-path
  Scenario: Pago exitoso de factura de ESSAP pendiente con efectivo
    Given existe una factura de ESSAP en estado pendiente para el usuario 1
    When el usuario paga la factura con metodoPago "efectivo"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el metodo_pago del pago es "efectivo"

  @RF-G3-03 @pagar @happy-path
  Scenario: Pago exitoso de factura de ESSAP vencida (sin recargos)
    Given existe una factura de ESSAP en estado vencida para el usuario 1
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"
    And el monto del pago es igual al monto original de la factura (sin recargos)

  @RF-G3-03 @pagar @negativo
  Scenario: Pago de factura de ESSAP inexistente
    Given el usuario intenta pagar una factura de ESSAP con ID que no existe
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"
    And el mensaje de error es "Factura no encontrada o ya pagada."
    And no se crea ningún registro en la tabla pagos

  @RF-G3-03 @pagar @negativo
  Scenario: Pago de factura de ESSAP ya pagada (doble pago)
    Given existe una factura de ESSAP en estado pagada para el usuario 1
    When el usuario intenta pagar nuevamente la misma factura
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"
    And el mensaje de error es "Factura no encontrada o ya pagada."
    And no se crea un segundo registro de pago

  @RF-G3-03 @pagar @negativo
  Scenario: Pago de factura de ESSAP con metodoPago inválido
    Given existe una factura de ESSAP en estado pendiente para el usuario 1
    When el usuario paga la factura con metodoPago "cripto"
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"
    And la factura conserva su estado anterior "pendiente"
    And no se crea ningún registro en la tabla pagos

  @RF-G3-03 @pagar @negativo
  Scenario: Pago de factura de ESSAP sin metodoPago en el cuerpo
    Given existe una factura de ESSAP en estado pendiente para el usuario 1
    When el usuario intenta pagar la factura sin enviar metodoPago
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"
    And la factura conserva su estado "pendiente"

  @RF-G3-03 @pagar @negativo
  Scenario: Pago de factura de ESSAP con ID no numérico
    When el usuario intenta pagar con ID "abc" en la ruta
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  @RF-G3-03 @pagar @edge-case
  Scenario: Pago de factura de ESSAP el mismo día del vencimiento
    Given existe una factura de ESSAP pendiente con fecha_vencimiento igual a hoy
    When el usuario paga la factura con metodoPago "tarjeta"
    Then la respuesta tiene código 200 OK
    And la factura en la respuesta tiene estado "pagada"
    And el pago en la respuesta tiene estado "procesado"

  @RF-G3-03 @pagar @edge-case
  Scenario: Intentos concurrentes de pago de la misma factura de ESSAP
    Given existe una factura de ESSAP en estado pendiente para el usuario 1
    When dos requests simultáneos intentan pagar la misma factura
    Then una transacción tiene éxito (200 OK) y la factura queda "pagada"
    And la otra transacción falla con 404 NOT_FOUND ("Factura no encontrada o ya pagada.")
    And solo se crea un registro en la tabla pagos

  # =========================================================================
  # RF-G3-04: Crear una factura POST /api/v1/facturas
  # =========================================================================

  @RF-G3-04 @crear @happy-path
  Scenario: Crear factura de ESSAP válida
    Given el usuario tiene ID 1
    When el usuario crea una factura con proveedor "ESSAP", numeroFactura "ESSAP-TEST-001", monto 50000, fechaVencimiento "2026-12-31"
    Then la respuesta tiene código 201 Created
    And la factura creada tiene estado "pendiente"
    And la factura creada tiene proveedor "ESSAP"
    And la factura aparece en el listado filtrando por usuarioId=1 y proveedor="ESSAP"

  @RF-G3-04 @crear @negativo
  Scenario: Crear factura de ESSAP con numeroFactura duplicado
    Given existe una factura de ESSAP con numeroFactura "ESSAP-EXISTENTE"
    When el usuario intenta crear otra factura de ESSAP con el mismo numeroFactura
    Then la respuesta tiene código 409 CONFLICT
    And el error tiene código "CONFLICT"

  @RF-G3-04 @crear @negativo
  Scenario: Crear factura con proveedor inválido (no ESSAP)
    When el usuario crea una factura con proveedor "Claro"
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  @RF-G3-04 @crear @negativo
  Scenario: Crear factura de ESSAP para usuario inexistente
    When el usuario crea una factura de ESSAP con usuarioId 999999
    Then la respuesta tiene código 400 VALIDATION_ERROR
    And el error tiene código "VALIDATION_ERROR"

  @RF-G3-04 @crear @edge-case
  Scenario: Crear factura de ESSAP con fechaVencimiento pasada
    When el usuario crea una factura de ESSAP con fechaVencimiento "2020-01-01"
    Then la respuesta tiene código 201 Created
    And la factura se crea con estado "pendiente"
    And la fecha_vencimiento se guarda como enviada

  # =========================================================================
  # RF-G3-05: Reemplazar una factura PUT /api/v1/facturas/{id}
  # =========================================================================

  @RF-G3-05 @reemplazar @happy-path
  Scenario: Reemplazar factura de ESSAP pendiente
    Given existe una factura de ESSAP en estado pendiente
    When el usuario reemplaza la factura con nuevo monto 75000
    Then la respuesta tiene código 200 OK
    And la factura actualizada tiene monto 75000
    And la factura mantiene estado "pendiente"
    And la factura mantiene proveedor "ESSAP"

  @RF-G3-05 @reemplazar @negativo
  Scenario: Reemplazar factura de ESSAP con numeroFactura duplicado
    Given existe una factura de ESSAP con numeroFactura "ESSAP-001"
    And existe otra factura de ESSAP con ID 2 y numeroFactura "ESSAP-002"
    When el usuario intenta reemplazar la factura 2 con numeroFactura "ESSAP-001"
    Then la respuesta tiene código 409 CONFLICT
    And el error tiene código "CONFLICT"

  @RF-G3-05 @reemplazar @negativo
  Scenario: Reemplazar factura de ESSAP inexistente o dada de baja
    When el usuario intenta reemplazar una factura de ESSAP con ID 999999
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"

  # =========================================================================
  # RF-G3-06: Dar de baja una factura DELETE /api/v1/facturas/{id}
  # =========================================================================

  @RF-G3-06 @baja @happy-path
  Scenario: Dar de baja factura de ESSAP vigente
    Given existe una factura de ESSAP en estado pendiente
    When el usuario da de baja la factura
    Then la respuesta tiene código 204 No Content
    And la factura no aparece en GET /facturas con proveedor="ESSAP"
    And GET /facturas/{id} sobre esa factura responde 404

  @RF-G3-06 @baja @happy-path
  Scenario: Dar de baja factura de ESSAP ya pagada
    Given existe una factura de ESSAP en estado pagada
    When el usuario da de baja la factura
    Then la respuesta tiene código 204 No Content
    And los pagos asociados se conservan en la tabla pagos

  @RF-G3-06 @baja @negativo
  Scenario: Dar de baja factura de ESSAP inexistente
    When el usuario intenta dar de baja una factura de ESSAP con ID 999999
    Then la respuesta tiene código 404 NOT_FOUND
    And el error tiene código "NOT_FOUND"

  # =========================================================================
  # Reglas transversales de la API
  # =========================================================================

  @transversal @auth @negativo
  Scenario: Request a endpoint de ESSAP sin API key
    When el usuario hace request a GET /api/v1/facturas sin header x-api-key
    Then la respuesta tiene código 401 UNAUTHORIZED
    And el mensaje es "Invalid or inactive API key."

  @transversal @auth @negativo
  Scenario: Request a endpoint de ESSAP con API key inválida
    When el usuario hace request a GET /api/v1/facturas con x-api-key inválida
    Then la respuesta tiene código 401 UNAUTHORIZED
    And el mensaje es "Invalid or inactive API key."

  @transversal @rate-limit @negativo
  Scenario: Rate limit excedido en endpoints de ESSAP
    Given una API key con límite de 30 requests/minuto
    When el usuario hace 31 requests en menos de un minuto a endpoints de ESSAP
    Then la respuesta 31 tiene código 429 RATE_LIMITED
    And la respuesta incluye headers Retry-After, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset