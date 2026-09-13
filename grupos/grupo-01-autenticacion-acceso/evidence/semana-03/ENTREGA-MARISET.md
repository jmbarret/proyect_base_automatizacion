# Entrega Semana 03 - Mariset C. Lorente

## Grupo 01 - Autenticación y Acceso

### Trabajo realizado

Se desarrollaron y validaron casos de prueba de API utilizando Postman para el módulo de Autenticación y Acceso.

Casos trabajados:

1. **01 - Login rechazado con credenciales inválidas**
   - Validación del rechazo de autenticación utilizando credenciales inválidas.

2. **02 - Login con correo válido ingresado con espacios**
   - Validación del comportamiento del servicio cuando el correo electrónico contiene espacios adicionales.

3. **03 - Login con usuario inactivo obtenido dinámicamente desde BD**
   - Consulta dinámica de un usuario inactivo desde la base de datos mediante Pre-request Script.
   - Almacenamiento del email e ID obtenidos desde BD en variables.
   - Ejecución del intento de autenticación utilizando el usuario obtenido.
   - Validación de respuesta HTTP 400.
   - Validación de respuesta en formato JSON.
   - Validación del error `VALIDATION_ERROR`.
   - Verificación mediante tests de que el usuario utilizado fue obtenido dinámicamente desde BD.

### Herramientas utilizadas

- Postman
- JavaScript para Pre-request Scripts y Tests
- Consulta SQL mediante API
- Git / GitHub

### Evidencia

La colección de Postman correspondiente se encuentra en el directorio `postman/`.

Los resultados y evidencias de ejecución de la Semana 03 se almacenan en este directorio.