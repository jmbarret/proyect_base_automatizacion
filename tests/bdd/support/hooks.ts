// hooks.ts — abre/cierra el navegador alrededor de cada escenario.

import { Before, After, Status } from '@cucumber/cucumber';
import { AiquaaWorld } from './world';

Before(async function (this: AiquaaWorld) {
  await this.initWeb();
});

After(async function (this: AiquaaWorld, { result }) {
  // captura evidencia solo si el escenario falló
  if (result?.status === Status.FAILED && this.page) {
    const buffer = await this.page.screenshot();
    await this.attach(buffer, 'image/png');
  }
  await this.teardown();
});
