# language: es
# Grupo 07 — Carrito de Compras / E-commerce (módulo ordenes)
#
# Completar los escenarios BDD de este módulo.
# Ver ENTREGABLES.md: mínimo 3 escenarios (1 happy path, 1 negativo, 1 edge case).

Feature: Carrito de Compras / E-commerce

  Scenario: Calcular el total del carrito con múltiples productos
    Given el usuario tiene los siguientes productos en el carrito:
      | producto   | cantidad | precio |
      | Zapatillas | 1        | 250000 |
      | Medias     | 2        | 15000  |
      | Remera     | 1        | 80000  |
    When el sistema calcula el total del carrito
    Then el total debe ser 360000

  # Happy Path - Juan Barreto
  Scenario: Completar una compra con productos disponibles
    Given que el cliente tiene productos disponibles en el carrito
    And el cliente corresponde a un usuario válido
    When confirma la compra
    Then el pedido se registra correctamente
    And el pedido queda en estado pendiente

  # Caso negativo - Juan Barreto
  Scenario: No permitir finalizar una compra con el carrito vacío
    Given que el cliente tiene el carrito vacío
    And el cliente corresponde a un usuario válido
    When intenta confirmar la compra
    Then el sistema debe impedir finalizar la compra
    And debe indicar que los datos de la compra no son válidos

  # Edge case - Juan Barreto
  Scenario: No permitir confirmar una compra con cantidad cero de un producto
    Given que el cliente tiene un producto en el carrito con cantidad cero
    And el cliente corresponde a un usuario válido
    When intenta confirmar la compra
    Then el sistema debe impedir finalizar la compra
    And debe indicar que la cantidad del producto no es válida


Feature: Agregar producto en stock al carrito

Como usuario del e-commerce
Quiero agregar productos disponibles al carrito
Para realizar una compra de los productos seleccionados

# Scenario: happy path - Armin Avezada Aquino
Scenario: Agregar producto disponible al carrito
Given el usuario se encuentra en la página de productos
And existe un producto disponible con stock
When selecciona el producto y lo agrega al carrito
Then el producto debe ser agregado correctamente al carrito
And la cantidad del producto en el carrito debe ser 1
And el stock disponible del producto debe actualizarse correctamente

# Scenario: caso negativo - Armin Avezada Aquino
Scenario: Intentar agregar un producto sin stock al carrito
Given el usuario se encuentra en la página de productos
And existe un producto sin stock disponible
When intenta agregar el producto al carrito
Then el producto no debe ser agregado al carrito
And debe visualizar un mensaje indicando que el producto no está disponible

# Scenario: edge case- Armin Avezada Aquino
Scenario: Agregar al carrito la cantidad máxima disponible en stock
Given el usuario se encuentra en la página de productos
And existe un producto con una cantidad limitada de stock
When agrega al carrito una cantidad igual al stock disponible
Then el producto debe ser agregado correctamente al carrito
And la cantidad agregada debe coincidir con el stock disponible
And el producto no debe permitir agregar una cantidad superior al stock disponible


Feature: Eliminar producto del carrito   - Andrea Escurra
  Como cliente del e-commerce
  quiero eliminar productos de mi carrito
  para ajustar mi compra antes del checkout

  Scenario: Eliminar un producto existente del carrito (happy path)   - Andrea Escurra
    Given el carrito contiene "Auriculares Bluetooth" con cantidad 1
    When elimino el producto "Auriculares Bluetooth" del carrito
    Then el producto ya no se lista en el carrito
    And se muestra el mensaje "Tu carrito esta vacio"

  Scenario: Intentar eliminar un producto inexistente en el carrito (caso negativo)   - Andrea Escurra
    Given el carrito contiene solo "Teclado USB"
    When intento eliminar el producto "Mouse Gamer" que no esta en el carrito
    Then el sistema muestra el error "El producto no existe en el carrito"
    And el carrito conserva el producto "Teclado USB"

  Scenario: Doble clic en eliminar sobre un producto ya removido (edge case)   - Andrea Escurra
    Given el carrito contiene solo "Cable HDMI"
    When elimino el producto "Cable HDMI" del carrito
    And hago doble clic sobre el boton eliminar del item ya removido
    Then el sistema no muestra errores
    And el carrito permanece vacio con total 0
# Análisis funcional BDD alineado al contrato real de la API del sandbox
# (app/api/v1/ordenes, RF-G7-01..05). Sustituye el stub de alumnos
# (ver carrito-ecommerce.stub.feature.bak).
#
# Steps reutilizables de la skill `bdd` (S_api.steps.ts):
#   Given que tengo una API key válida
#   When hago GET/POST/PUT/DELETE a "{endpoint}" [con query {...}] [con body: ...]
#   Then la respuesta tiene status {int}
#   Then el campo "{jsonPath}" de la respuesta es {value}
#   Then el campo "{jsonPath}" de la respuesta existe
#   Then la respuesta tiene un array "data" con {int} elementos
#   Then el código de error es "{code}"
#   Then guardo el campo "{jsonPath}" de la respuesta como "{alias}"
#
# Notas de diseño capturadas como comportamiento esperado:
#   - monto/subtotal siempre calculados por el servidor; un total del cliente se ignora.
#   - PUT recalcula producto/monto pero NO toca items_orden (desincronía deliberada).
#   - DELETE es soft-delete (activo=false); deja items_orden huérfanos.

@grupo-7 @api
Feature: Carrito de Compras / E-commerce (ordenes)

  Background:
    Given que tengo una API key válida

  # ---- RF-G7-01: Listar órdenes ----
  @RF-G7-01 @smoke
  Scenario: Listar todas las órdenes activas sin filtro
    When hago GET a "/api/v1/ordenes"
    Then la respuesta tiene status 200
    And el campo "data" de la respuesta existe

  @RF-G7-01
  Scenario: Filtrar órdenes por comprador
    When hago GET a "/api/v1/ordenes" con query {"usuarioId": 1}
    Then la respuesta tiene status 200
    And el campo "data" de la respuesta existe

  @RF-G7-01
  Scenario: Un comprador sin órdenes devuelve lista vacía
    When hago GET a "/api/v1/ordenes" con query {"usuarioId": 999999}
    Then la respuesta tiene status 200
    And la respuesta tiene un array "data" con 0 elementos

  @RF-G7-01 @negativo
  Scenario: usuarioId no numérico es rechazado con 400
    When hago GET a "/api/v1/ordenes" con query {"usuarioId": "abc"}
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  # ---- RF-G7-02: Cerrar la compra (checkout) ----
  @RF-G7-02 @smoke
  Scenario: Checkout con dos ítems calcula el total server-side
    # criterio: data.monto = 2*10.50 + 1*5.25 = 26.25; producto = primer item; estado pendiente
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 1, "items": [ { "producto": "Teclado", "cantidad": 2, "precioUnitario": 10.50 }, { "producto": "Mouse", "cantidad": 1, "precioUnitario": 5.25 } ] }
      """
    Then la respuesta tiene status 201
    And el campo "data.monto" de la respuesta es 26.25
    And el campo "data.producto" de la respuesta es "Teclado"
    And el campo "data.estado" de la respuesta es "pendiente"
    And el campo "data.items" de la respuesta existe
    And guardo el campo "data.id" de la respuesta como "ordenId"

  @RF-G7-02 @negativo
  Scenario: El array de ítems vacío es rechazado
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 1, "items": [] }
      """
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  @RF-G7-02 @negativo
  Scenario: Un ítem con cantidad cero es rechazado
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 1, "items": [ { "producto": "X", "cantidad": 0, "precioUnitario": 9.99 } ] }
      """
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  @RF-G7-02 @negativo
  Scenario: Cantidad enviada como texto es rechazada por validación
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 1, "items": [ { "producto": "X", "cantidad": "2", "precioUnitario": 9.99 } ] }
      """
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  @RF-G7-02 @negativo
  Scenario: Comprador inexistente no crea ni cabecera ni ítems
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 999999, "items": [ { "producto": "X", "cantidad": 1, "precioUnitario": 9.99 } ] }
      """
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  # ---- RF-G7-03: Consultar una orden con su detalle ----
  @RF-G7-03 @smoke
  Scenario: Consultar una orden recién creada devuelve cabecera + ítems
    # criterio: data.items coincide con los ítems del checkout; suma subtotales = data.monto
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 3, "items": [ { "producto": "A", "cantidad": 2, "precioUnitario": 10 } ] }
      """
    Then la respuesta tiene status 201
    And guardo el campo "data.id" de la respuesta como "ordenId"
    When hago GET a "/api/v1/ordenes/{ordenId}"
    Then la respuesta tiene status 200
    And el campo "data.items" de la respuesta existe

  @RF-G7-03 @negativo
  Scenario: Consultar una orden inexistente devuelve 404
    When hago GET a "/api/v1/ordenes/999999"
    Then la respuesta tiene status 404

  @RF-G7-03 @negativo
  Scenario: Id no entero positivo es rechazado con 400
    When hago GET a "/api/v1/ordenes/abc"
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  # ---- RF-G7-04: Recalculcar una orden (solo cabecera) ----
  @RF-G7-04
  Scenario: Recálculo actualiza monto/producto pero NO el detalle original
    # criterio: PUT recalcula monto=3*7=21 y producto="B"; GET posterior muestra items originales
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 4, "items": [ { "producto": "A", "cantidad": 1, "precioUnitario": 10 } ] }
      """
    Then la respuesta tiene status 201
    And guardo el campo "data.id" de la respuesta como "ordenId"
    When hago PUT a "/api/v1/ordenes/{ordenId}" con body:
      """
      { "items": [ { "producto": "B", "cantidad": 3, "precioUnitario": 7 } ] }
      """
    Then la respuesta tiene status 200
    And el campo "data.monto" de la respuesta es 21
    And el campo "data.producto" de la respuesta es "B"
    When hago GET a "/api/v1/ordenes/{ordenId}"
    Then la respuesta tiene status 200
    And el campo "data.items[0].producto" de la respuesta es "A"

  @RF-G7-04 @negativo
  Scenario: Recálculo con items vacíos es rechazado
    When hago PUT a "/api/v1/ordenes/1" con body:
      """
      { "items": [] }
      """
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  @RF-G7-04 @negativo
  Scenario: Recálculo de orden inexistente devuelve 404
    When hago PUT a "/api/v1/ordenes/999999" con body:
      """
      { "items": [ { "producto": "Z", "cantidad": 1, "precioUnitario": 1 } ] }
      """
    Then la respuesta tiene status 404

  # ---- RF-G7-05: Dar de baja (soft-delete) ----
  @RF-G7-05 @smoke
  Scenario: Dar de baja una orden vigente y dejarla fuera de consultas
    When hago POST a "/api/v1/ordenes" con body:
      """
      { "usuarioId": 5, "items": [ { "producto": "A", "cantidad": 1, "precioUnitario": 10 } ] }
      """
    Then la respuesta tiene status 201
    And guardo el campo "data.id" de la respuesta como "ordenId"
    When hago DELETE a "/api/v1/ordenes/{ordenId}"
    Then la respuesta tiene status 204
    When hago GET a "/api/v1/ordenes/{ordenId}"
    Then la respuesta tiene status 404

  @RF-G7-05 @negativo
  Scenario: Dar de baja de una orden ya dada de baja devuelve 404
    When hago DELETE a "/api/v1/ordenes/1"
    Then la respuesta tiene status 404
