// S_web.steps.ts — steps de navegador. Siempre por data-testid.
// Ver skill sandbox → references/web-testids.md para la convención de nombres.

import { Given, When, Then } from '@cucumber/cucumber';
import { expect } from '@playwright/test';
import { SandboxWorld } from './world';

Given('que estoy en la página {string}', async function (this: SandboxWorld, ruta: string) {
  await this.page!.goto(ruta);
});

When('completo el campo {string} con {string}',
  async function (this: SandboxWorld, testid: string, valor: string) {
    await this.page!.getByTestId(testid).fill(this.resolve(valor));
  });

When('hago click en {string}', async function (this: SandboxWorld, testid: string) {
  await this.page!.getByTestId(testid).click();
});

Then('veo el elemento {string}', async function (this: SandboxWorld, testid: string) {
  await expect(this.page!.getByTestId(testid)).toBeVisible();
});

Then('el elemento {string} contiene el texto {string}',
  async function (this: SandboxWorld, testid: string, texto: string) {
    await expect(this.page!.getByTestId(testid)).toContainText(this.resolve(texto));
  });
