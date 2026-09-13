# Feature de ejemplo — usada en la guía playwright/README.md.
# Corre contra el sitio real (https://aiquaa-sandbox-web.vercel.app/), sin mocks.
# Sirve como plantilla mínima: navegar, completar por data-testid, verificar.

Feature: Login en el sandbox AIQUAA
  Como estudiante del curso
  Quiero ver un ejemplo minimo de escenario BDD contra el sandbox
  Para replicar el patron en mis propios features

  Scenario: El boton de ingresar arranca deshabilitado
    Given que estoy en la página "/"
    Then el elemento "auth-login-submit" esta deshabilitado

  Scenario: Login con un usuario no registrado muestra error controlado
    Given que estoy en la página "/"
    When completo el campo "auth-login-field-email" con "estudiante-demo@aiquaa.com"
    And hago click en "auth-login-submit"
    Then veo el elemento "auth-login-field-email-error"
    And el elemento "auth-login-field-email-error" contiene el texto "Usuario no encontrado"
