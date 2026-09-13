@grupo-1 @api @db
Feature: Autenticación y Acceso
  Como usuario del sistema
  Quiero poder iniciar sesión, cerrar sesión y recuperar mi contraseña
  Para acceder de forma segura a mis datos financieros

  Background:
    Given que tengo una API key válida

  # criterio: un usuario activo puede iniciar sesión con su email
  Scenario: Login exitoso con usuario activo
    When hago POST a "/api/v1/auth/login" con body:
      """
      { "email": "ana.torres@example.com" }
      """
    Then la respuesta tiene status 200
    And el campo "data.activo" de la respuesta es true
    And guardo el campo "data.id" de la respuesta como "usuarioId"
    And en la base de datos, "sesiones" tiene 1 fila(s) con "usuario_id" igual a "{usuarioId}"

  # criterio: un usuario inactivo no puede iniciar sesión
  @negativo
  Scenario: Login falla con usuario inactivo
    When hago POST a "/api/v1/auth/login" con body:
      """
      { "email": "usuario.inactivo.04@example.com" }
      """
    Then la respuesta tiene status 400
    And el código de error es "VALIDATION_ERROR"

  # criterio: cerrar sesión registra el evento correspondiente
  Scenario: Logout registra el evento en sesiones
    Given hago login con el email "ana.torres@example.com" y guardo el id como "usuarioId"
    When hago POST a "/api/v1/auth/logout" con body:
      """
      { "usuarioId": "{usuarioId}" }
      """
    Then la respuesta tiene status 200
    And en la base de datos, "sesiones" tiene 1 fila(s) con "tipo_evento" igual a "logout"

  @negativo
  Scenario Outline: Sin API key no se puede operar
    Given que tengo una API key inválida
    When hago POST a "<endpoint>" con body:
      """
      { "email": "ana.torres@example.com" }
      """
    Then la respuesta tiene status 401

    Examples:
      | endpoint                          |
      | /api/v1/auth/login                |
      | /api/v1/auth/forgot-password      |
