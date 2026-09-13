# Grupo 01 — Autenticación y Acceso
# Módulo: Login / Logout / Recuperación de contraseña
#
# Completar los escenarios BDD de este módulo.
# Ver ENTREGABLES.md: mínimo 3 escenarios (1 happy path, 1 negativo, 1 edge case).

Feature: Autenticación y Acceso

  # TODO: Agregar escenarios adicionales del equipo (happy path, caso negativo o edge case)

  # Scenario: caso negativo - Mariset C. Lorente Castillo
  Scenario: Login rechazado con credenciales invalidas
  Given existe una sesion seeded para la cohorte "demo"
  When el usuario intenta iniciar sesion con credenciales invalidas
  Then se debe ver un mensaje de error de autenticacion

  # Scenario: edge case - Mariset C. Lorente Castillo
  Scenario: Login con correo valido ingresado con espacios
  Given el usuario se encuentra en la pantalla de inicio de sesion
  When ingresa un correo valido con espacios adicionales
  Then se debe ver el mensaje "Correo inválido" y no se debe permitir iniciar sesion

# Scenario: happy path - Mariel Aquino
  Scenario: Login exitoso con credenciales validas
  Given el usuario se encuentra en la pantalla de inicio de sesion
  When ingresa credenciales validas de acceso
  Then el sistema debe permitir el ingreso y mostrar el panel principal

  # Scenario: caso negativo - Mariel Aquino
  Scenario: Solicitud de recuperacion de clave con correo no registrado
  Given el usuario se encuentra en la pantalla de recuperacion
  When solicita restablecer la contraseña con un correo no registrado
  Then el sistema debe mostrar un mensaje de error "Correo no encontrado"

  # Scenario: edge case - Mariel Aquino
  Scenario: Cierre de sesion con token expirado
  Given el usuario tiene una sesion activa pero el token expirado
  When selecciona la opcion de cerrar sesion
  Then el sistema debe finalizar la sesion de forma segura y redirigir al login

 # Scenario: edge case - Gloria Figueredo
  Scenario: Login con campos obligatorios vacíos
  Given el usuario se encuentra en la pantalla de inicio de sesion
  When intenta iniciar sesion sin ingresar usuario ni contraseña
  Then el sistema debe impedir el acceso
  And debe informar que los campos de autenticacion son obligatorios

  # Scenario: caso negativo - Oscar Benítez
  Scenario: Redireccion al login al intentar acceder a un laboratorio protegido
  Given el usuario no tiene una sesion autenticada
  When intenta acceder a una herramienta protegida del laboratorio
  Then el sistema debe redirigirlo a la pagina de inicio de sesion
  And debe ofrecer las opciones de iniciar sesion o crear una cuenta

  # Scenario: happy path - Oscar Benítez
  Scenario: Acceso al recurso solicitado despues de iniciar sesion
  Given existe una sesion seeded para la cohorte "demo"
  And el usuario no autenticado intenta acceder a una herramienta protegida
  And el sistema lo redirige a la pagina de inicio de sesion
  When inicia sesion con credenciales validas
  Then debe autenticarse correctamente
  And debe acceder a la herramienta protegida solicitada

  # Scenario: happy path - David Cristaldo
  Scenario: Recuperacion de contraseña exitosa con correo registrado
  Given el usuario se encuentra en la pantalla de recuperacion
  When solicita restablecer la contraseña con un correo registrado
  Then el sistema debe enviar un correo con el enlace de restablecimiento
  And debe informar que la solicitud fue procesada correctamente