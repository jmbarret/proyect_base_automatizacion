# Grupo 02 — Transferencias entre Cuentas

**Módulo:** Transferencias internas (mismo banco)
**Rama:** `grupo-02-transferencias-cuentas`

## Integrantes

| N° | Nombre y Apellido | Email |
|----|--------------------|----------------------------------------|
| 1  | Liliana Salinas    | lilianasalinas_s02@fpuna.edu.py        |
| 2  | Karen Lezcano      | karencitalez98@gmail.com               |
| 3  | Patricia Urunaga   | patt83@gmail.com                       |
| 4  | Alicia Alvarez     | alialvarez0896@fpuna.edu.py            |
| 5  | Willian Benega     | williandavidbenega14@gmail.com         |

## Alcance

- **Objetivo:** automatizar el flujo de transferencias entre cuentas del mismo banco (transferencias internas), cubriendo los casos de transferencia exitosa, transferencia rechazada por saldo insuficiente, transferencia hacia una cuenta bloqueada, transferencia por el monto exacto del saldo disponible (caso límite), y transferencia entre cuentas de distintas monedas.
- **Supuestos:** el usuario ya se encuentra autenticado en el sistema; posee al menos dos cuentas propias habilitadas dentro del mismo banco; los datos de prueba (saldos, cuentas) están disponibles en el entorno de laboratorio AIQUAA.
- **Riesgos:** posibles cambios en los selectores de UI del formulario de transferencias; datos de prueba compartidos entre equipos que puedan generar inconsistencias de saldo; dependencia de la disponibilidad del entorno de laboratorio.
- **Cobertura incluida:** transferencias entre cuentas propias del mismo banco (montos válidos, saldo insuficiente, cuenta destino bloqueada, monto límite igual al saldo disponible, transferencia entre monedas distintas).
- **Cobertura excluida:** transferencias interbancarias (a otros bancos), transferencias internacionales, y validaciones de límites regulatorios (AML/KYC) fuera del flujo funcional básico.

## Entregables

Checklist según [ENTREGABLES.md](../../ENTREGABLES.md):

- [ ] Análisis y alcance
- [ ] BDD — `features/` (mínimo 3 escenarios: happy path, negativo, edge case)
- [ ] API — colección Postman/Newman (si aplica al módulo)
- [ ] UI — `tests/e2e/` con Playwright
- [ ] Evidencias en `evidence/`
- [ ] CI/CD verde
- [ ] PR a `main` usando la plantilla del repo
