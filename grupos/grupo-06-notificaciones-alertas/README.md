# Grupo 06 — Notificaciones y Alertas

**Módulo:** Sistema de notificaciones push/email/SMS
**Rama:** `grupo-06-notificaciones-alertas`

## Integrantes

* Fabian Machado — [maeze02@gmail.com](mailto:maeze02@gmail.com)
* Fernando Servian — [fernandosa305@fpuna.edu.py](mailto:fernandosa305@fpuna.edu.py)
* Karina Bogarin — [kariarganha@gmail.com](mailto:kariarganha@gmail.com)
* Ana Mendoza — [anajazmendoza@gmail.com](mailto:anajazmendoza@gmail.com)
* Madhy Avalos — [Magavalos15@gmail.com](mailto:Magavalos15@gmail.com)

## Objetivo del flujo

Validar que el sistema genere y gestione correctamente las notificaciones asociadas a transferencias bancarias, respetando las preferencias configuradas por el usuario, utilizando canales alternativos cuando corresponda y evitando entregas duplicadas.

## Alcance

### Supuestos

* El usuario se encuentra registrado en el sistema.
* El usuario posee preferencias de notificación configuradas.
* Cada transferencia cuenta con un identificador único.
* El usuario dispone de un dispositivo, correo electrónico o número telefónico registrado, según el canal utilizado.
* Los servicios de notificaciones se encuentran disponibles, excepto cuando el escenario indique expresamente una falla.
* La zona horaria del usuario se encuentra correctamente configurada.

### Riesgos

* Indisponibilidad temporal de los proveedores de notificaciones.
* Tokens de dispositivos vencidos o inválidos.
* Números telefónicos o correos electrónicos incorrectos.
* Procesamiento repetido de un mismo evento.
* Configuración incorrecta del horario silencioso.
* Diferencias de zona horaria al programar una entrega.
* Envío de información sensible dentro de una notificación.

### Cobertura incluida

* Envío de una notificación push después de una transferencia exitosa.
* Respeto de la preferencia del usuario cuando el canal push está desactivado.
* Prevención de notificaciones duplicadas ante el reprocesamiento de un evento.
* Uso del email como canal de respaldo cuando el push no puede entregarse.
* Programación de la entrega durante el horario silencioso.
* Envío de notificaciones mediante SMS.
* Gestión de un número telefónico inválido.
* Envío por múltiples canales según las preferencias del usuario.

### Cobertura excluida

* Pruebas de carga, rendimiento o concurrencia masiva.
* Validación del proceso interno completo de una transferencia bancaria.
* Personalización visual y traducción de las notificaciones.
* Pruebas con proveedores reales de email, SMS o push.
* Administración y recuperación de las credenciales del usuario.
* Configuración interna de los proveedores externos de mensajería.

## Escenarios BDD

Los escenarios se encuentran definidos en `features/notificaciones-alertas.feature`.

Actualmente se contemplan ocho escenarios:

1. Envío push después de una transferencia exitosa.
2. No envío cuando el usuario tiene desactivado el canal push.
3. Prevención de notificaciones duplicadas.
4. Uso de email como canal de respaldo.
5. Entrega diferida durante el horario silencioso.
6. Envío de SMS después de una transferencia exitosa.
7. Gestión de un número telefónico inválido.
8. Envío por múltiples canales según las preferencias del usuario.

## Auditoría de la propuesta generada por IA

La propuesta inicial generada con inteligencia artificial fue utilizada como punto de partida y posteriormente revisada por el equipo. Durante la auditoría se identificaron y aplicaron las siguientes correcciones:

1. **Precondiciones más específicas:** se incorporaron condiciones verificables, como las preferencias del usuario, el estado del token, la validez del número telefónico y la configuración del horario silencioso.

2. **Datos de prueba trazables:** se agregaron montos concretos e identificadores únicos de transferencia para facilitar la ejecución y validación de los escenarios.

3. **Resultados esperados medibles:** se reemplazaron resultados genéricos por validaciones concretas, como la existencia de un único registro de entrega, el estado de cada canal y la hora programada de envío.

4. **Cobertura multicanal:** se amplió la propuesta inicial para contemplar notificaciones push, email y SMS, incluyendo el uso de canales alternativos.

5. **Casos negativos y límites:** se añadieron validaciones para canales desactivados, tokens vencidos, números inválidos, eventos duplicados y horarios silenciosos.

6. **Separación de responsabilidades:** los escenarios se enfocan en el sistema de notificaciones sin intentar validar el funcionamiento interno completo de las transferencias bancarias.

## Evidencia de setup

Se debe adjuntar una captura que demuestre la disponibilidad de las herramientas necesarias para trabajar con el repositorio:

* Git
* Node.js
* npm
* Playwright
* Visual Studio Code

Ruta prevista para la evidencia:

`evidence/setup-grupo-06.png`

## Estado del entregable semanal

* [x] Flujo objetivo definido.
* [x] Escenarios BDD redactados.
* [x] Propuesta generada por IA auditada.
* [x] Integrantes registrados.
* [ ] Evidencia de setup cargada.
* [ ] Revisión final del grupo.
* [ ] Pull Request grupal hacia `main`.

## Entregables generales del proyecto

Checklist según [ENTREGABLES.md](../../ENTREGABLES.md):

* [x] Análisis y alcance.
* [x] BDD en `features/`.
* [ ] API — colección Postman/Newman.
* [ ] UI — pruebas en `tests/e2e/` con Playwright.
* [ ] Evidencias en `evidence/`.
* [ ] CI/CD verde.
* [ ] Pull Request hacia `main`.
