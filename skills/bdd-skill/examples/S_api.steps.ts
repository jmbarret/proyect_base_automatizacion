// S_api.steps.ts — steps genéricos de API contra el sandbox.
// Ver skill sandbox → references/api-contract.md para el envelope { data } / { error }.

import { Given, When, Then } from '@cucumber/cucumber';
import { strict as assert } from 'node:assert';
import { SandboxWorld } from './world';

function getByPath(obj: any, path: string): any {
  return path.split('.').reduce((acc, key) => (acc == null ? undefined : acc[key]), obj);
}

Given('que tengo una API key válida', async function (this: SandboxWorld) {
  await this.initApi();
});

Given('que tengo una API key inválida', async function (this: SandboxWorld) {
  await this.initApi('sbx_invalida_00000000');
});

Given('hago login con el email {string} y guardo el id como {string}',
  async function (this: SandboxWorld, email: string, alias: string) {
    const res = await this.apiContext.post('/api/v1/auth/login', { data: { email } });
    const body = await res.json();
    this.context[alias] = body.data.id;
  });

When('hago GET a {string}', async function (this: SandboxWorld, endpoint: string) {
  const res = await this.apiContext.get(this.resolve(endpoint));
  this.lastStatus = res.status();
  this.lastResponse = await res.json();
});

When('hago GET a {string} con query {string}',
  async function (this: SandboxWorld, endpoint: string, queryJson: string) {
    const params = JSON.parse(queryJson);
    const res = await this.apiContext.get(this.resolve(endpoint), { params });
    this.lastStatus = res.status();
    this.lastResponse = await res.json();
  });

When('hago POST a {string} con body:', async function (this: SandboxWorld, endpoint: string, body: string) {
  const data = JSON.parse(this.resolve(body));
  const res = await this.apiContext.post(this.resolve(endpoint), { data });
  this.lastStatus = res.status();
  this.lastResponse = await res.json();
});

When('hago PATCH a {string} con body:', async function (this: SandboxWorld, endpoint: string, body: string) {
  const data = JSON.parse(this.resolve(body));
  const res = await this.apiContext.patch(this.resolve(endpoint), { data });
  this.lastStatus = res.status();
  this.lastResponse = await res.json();
});

When('hago DELETE a {string}', async function (this: SandboxWorld, endpoint: string) {
  const res = await this.apiContext.delete(this.resolve(endpoint));
  this.lastStatus = res.status();
  this.lastResponse = await res.json();
});

Then('la respuesta tiene status {int}', function (this: SandboxWorld, status: number) {
  assert.equal(this.lastStatus, status,
    `esperaba status ${status}, recibí ${this.lastStatus} — body: ${JSON.stringify(this.lastResponse)}`);
});

Then('el campo {string} de la respuesta es {word}',
  function (this: SandboxWorld, path: string, expected: string) {
    const value = getByPath(this.lastResponse, path);
    const parsed = expected === 'true' ? true : expected === 'false' ? false : expected;
    assert.equal(value, parsed, `campo "${path}" — esperaba ${parsed}, encontré ${value}`);
  });

Then('el campo {string} de la respuesta existe', function (this: SandboxWorld, path: string) {
  const value = getByPath(this.lastResponse, path);
  assert.notEqual(value, undefined, `campo "${path}" no existe en la respuesta`);
});

Then('la respuesta tiene un array {string} con {int} elementos',
  function (this: SandboxWorld, path: string, count: number) {
    const value = getByPath(this.lastResponse, path);
    assert.ok(Array.isArray(value), `"${path}" no es un array`);
    assert.equal(value.length, count, `"${path}" tiene ${value.length} elementos, esperaba ${count}`);
  });

Then('el código de error es {string}', function (this: SandboxWorld, code: string) {
  assert.equal(this.lastResponse?.error?.code, code,
    `código esperado "${code}", recibido "${this.lastResponse?.error?.code}"`);
});

Then('guardo el campo {string} de la respuesta como {string}',
  function (this: SandboxWorld, path: string, alias: string) {
    this.context[alias] = getByPath(this.lastResponse, path);
  });
