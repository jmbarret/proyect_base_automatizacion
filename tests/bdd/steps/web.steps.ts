// web.steps.ts — steps genéricos de navegador. Siempre por data-testid.
// Reutilizables para cualquier escenario que solo necesite navegar,
// completar campos, hacer click y verificar textos/visibilidad.

import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { AiquaaWorld } from '../support/world';

Given('que estoy en la página {string}', async function (this: AiquaaWorld, ruta: string) {
  await this.page!.goto(ruta);
});

When('completo el campo {string} con {string}',
  async function (this: AiquaaWorld, testid: string, valor: string) {
    await this.page!.getByTestId(testid).fill(valor);
  });

When('hago click en {string}', async function (this: AiquaaWorld, testid: string) {
  await this.page!.getByTestId(testid).click();
});

Then('veo el elemento {string}', async function (this: AiquaaWorld, testid: string) {
  await expect(this.page!.getByTestId(testid)).toBeVisible();
});

Then('el titulo de la pagina contiene {string}', async function (this: AiquaaWorld, texto: string) {
  await expect(this.page!).toHaveTitle(new RegExp(texto, 'i'));
});

Then('el elemento {string} contiene el texto {string}',
  async function (this: AiquaaWorld, testid: string, texto: string) {
    await expect(this.page!.getByTestId(testid)).toContainText(texto);
  });

Then('el elemento {string} esta deshabilitado', async function (this: AiquaaWorld, testid: string) {
  await expect(this.page!.getByTestId(testid)).toBeDisabled();
});
