// world.ts — contexto compartido entre steps (Cucumber World).
// Cada escenario recibe su propia instancia: browser + page aislados.

import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';
import { Browser, Page, chromium } from '@playwright/test';
import * as dotenv from 'dotenv';

dotenv.config();

export class AiquaaWorld extends World {
  browser?: Browser;
  page?: Page;

  baseUrl = process.env.BASE_URL || 'https://aiquaa-sandbox-web.vercel.app/';

  constructor(options: IWorldOptions) {
    super(options);
  }

  async initWeb() {
    this.browser = await chromium.launch({ headless: process.env.HEADED !== 'true' });
    this.page = await this.browser.newPage({ baseURL: this.baseUrl });
  }

  async teardown() {
    await this.page?.close();
    await this.browser?.close();
  }
}

setWorldConstructor(AiquaaWorld);
