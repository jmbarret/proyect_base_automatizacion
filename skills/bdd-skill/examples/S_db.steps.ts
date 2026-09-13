// S_db.steps.ts — verificación en base de datos vía POST /api/v1/sql/select.
// Ver skill sandbox → references/sql-endpoint.md para guardrails y whitelist de tablas.
// Cada step consume una petición del rate limit (30/min) — no abusar por escenario.

import { Then } from '@cucumber/cucumber';
import { strict as assert } from 'node:assert';
import { SandboxWorld } from './world';

// whitelist local — defensa adicional, el sandbox también valida del lado servidor
const TABLAS_PERMITIDAS = new Set([
  'usuarios', 'sesiones', 'cuentas', 'transferencias', 'facturas', 'pagos', 'tarjetas',
  'notificaciones', 'ordenes', 'items_orden', 'reservas', 'movimientos', 'roles',
  'usuario_roles', 'tickets',
]);
const COLUMNA_VALIDA = /^[a-z_][a-z0-9_]*$/;

function assertTablaColumna(tabla: string, columna: string) {
  assert.ok(TABLAS_PERMITIDAS.has(tabla), `tabla "${tabla}" no está en la whitelist de qa_training`);
  assert.ok(COLUMNA_VALIDA.test(columna), `nombre de columna inválido: "${columna}"`);
}

async function selectSql(world: SandboxWorld, sql: string, params: unknown[]) {
  const res = await world.apiContext.post('/api/v1/sql/select', { data: { sql, params } });
  const body = await res.json();
  assert.equal(res.status(), 200, `sql/select falló: ${JSON.stringify(body)}`);
  return body as { data: any[]; rowCount: number };
}

Then('en la base de datos, {string} tiene {int} fila(s) con {string} igual a {string}',
  async function (this: SandboxWorld, tabla: string, cantidad: number, columna: string, valor: string) {
    assertTablaColumna(tabla, columna);
    const resuelto = this.resolve(valor);
    const { rowCount } = await selectSql(this,
      `SELECT * FROM ${tabla} WHERE ${columna} = $1`, [resuelto]);
    assert.equal(rowCount, cantidad,
      `"${tabla}.${columna} = ${resuelto}" tiene ${rowCount} filas, esperaba ${cantidad}`);
  });

Then('en la base de datos, {string} con id {string} tiene {string} igual a {string}',
  async function (this: SandboxWorld, tabla: string, alias: string, columna: string, valor: string) {
    assertTablaColumna(tabla, columna);
    const id = this.context[alias];
    const resuelto = this.resolve(valor);
    const { data } = await selectSql(this, `SELECT ${columna} FROM ${tabla} WHERE id = $1`, [id]);
    assert.equal(data.length, 1, `no encontré fila en "${tabla}" con id ${id}`);
    assert.equal(String(data[0][columna]), resuelto,
      `"${tabla}.${columna}" es "${data[0][columna]}", esperaba "${resuelto}"`);
  });

Then('en la base de datos, no existe ninguna fila en {string} con {string} igual a {string}',
  async function (this: SandboxWorld, tabla: string, columna: string, valor: string) {
    assertTablaColumna(tabla, columna);
    const resuelto = this.resolve(valor);
    const { rowCount } = await selectSql(this,
      `SELECT * FROM ${tabla} WHERE ${columna} = $1`, [resuelto]);
    assert.equal(rowCount, 0, `esperaba 0 filas, encontré ${rowCount}`);
  });
