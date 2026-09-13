// hooks.ts — setup/teardown por escenario
import { Before, After, Status } from '@cucumber/cucumber';
import { SandboxWorld } from './world';

Before({ tags: '@api or @db' }, async function (this: SandboxWorld) {
  await this.initApi();
});

Before({ tags: '@web' }, async function (this: SandboxWorld) {
  await this.initApi(); // los steps @web también pueden verificar por API/BD
  await this.initWeb();
});

After(async function (this: SandboxWorld, { result }) {
  if (result?.status === Status.FAILED && this.page) {
    const screenshot = await this.page.screenshot();
    this.attach(screenshot, 'image/png');
  }
  await this.teardown();
});
