# Grupo 10 — Administración de Roles y Permisos

**Módulo:** Gestión de usuarios internos (backoffice)
**Rama:** `grupo-10-roles-permisos`

## Integrantes

- Mathias Osorio, mathialexoso@gmail.com
- Nestor Prieto, nestorprieto28@gmail.com
- Nicole Fernandez, nicole.fernandez.consult@gmail.com
- Julieta Sanabria, julietajazmin0106@gmail.com
- Clara Ferreira, monseferreira121@gmail.com

## Alcance

**Objetivo del flujo automatizado:**
Validar que el sistema de backoffice controla correctamente el acceso y las acciones
de los usuarios segun el rol asignado, garantizando que solo los usuarios con los
permisos adecuados puedan crear, editar o eliminar usuarios internos.

**Supuestos:**
- Existen al menos dos roles definidos en el sistema (ej. Administrador y Operador)
  con distintos niveles de permiso sobre el modulo de usuarios.
- El entorno de pruebas cuenta con usuarios seed para cada rol a validar.
- La sesion del usuario determina que acciones estan disponibles en la interfaz.

**Riesgos:**
- Los selectores de la interfaz pueden no estar disponibles como `data-testid`,
  lo que podria requerir ajustar los Page Objects una vez accedamos al ambiente real.
- Cambios en el esquema de roles y permisos durante el desarrollo podrian afectar
  la validez de los escenarios ya definidos.

**Cobertura incluida:**
- Creacion de usuario interno con asignacion de rol (happy path)
- Bloqueo de creacion de usuario por falta de permisos (negativo)
- Edge case relacionado a asignacion de roles (pendiente de definicion final)

**Cobertura excluida:**
- Gestion de permisos a nivel de API (cubierta por la coleccion Postman, si aplica)
- Pruebas de carga o rendimiento sobre el modulo de usuarios
- Integracion con sistemas externos de autenticacion (SSO, LDAP, etc.)

## Entregables

Checklist según [ENTREGABLES.md](../../ENTREGABLES.md):

- [ ] Análisis y alcance
- [ ] BDD — `features/` (mínimo 3 escenarios: happy path, negativo, edge case)
- [ ] API — colección Postman/Newman (si aplica al módulo)
- [ ] UI — `tests/e2e/` con Playwright
- [ ] Evidencias en `evidence/`
- [ ] CI/CD verde
- [ ] PR a `main` usando la plantilla del repo
