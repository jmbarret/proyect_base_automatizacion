// world.ts — contexto compartido entre steps (Cucumber World)
// Ver skill bdd: catálogo de steps, y skill sandbox: contrato de la API.

import { setWorldConstructor, World, IWorldOptions } from '@cucumber/cucumber';
import { APIRequestContext, request, Page, Browser, chromium } from '@playwright/test';

export class SandboxWorld extends World {
  apiContext!: APIRequestContext;
  browser?: Browser;
  page?: Page;

  baseUrl = process.env.SANDBOX_API_BASE_URL ?? 'http://localhost:3000';
  webBaseUrl = process.env.SANDBOX_WEB_BASE_URL ?? 'http://localhost:3001';
  apiKey = process.env.SANDBOX_API_KEY ?? '';

  lastResponse: any;
  lastStatus = 0;

  // valores guardados entre steps: `guardo el campo "data.id" como "ordenId"`
  context: Record<string, unknown> = {};

  constructor(options: IWorldOptions) {
    super(options);
  }

  async initApi(apiKeyOverride?: string) {
    this.apiContext = await request.newContext({
      baseURL: this.baseUrl,
      extraHTTPHeaders: {
        'x-api-key': apiKeyOverride ?? this.apiKey,
        'Content-Type': 'application/json',
      },
    });
  }

  async initWeb() {
    this.browser = await chromium.launch();
    this.page = await this.browser.newPage({ baseURL: this.webBaseUrl });
  }

  // resuelve placeholders "{alias}" contra this.context antes de usarlos en un step
  resolve(value: string): string {
    return value.replace(/\{(\w+)\}/g, (_, key) => String(this.context[key] ?? `{${key}}`));
  }

  async teardown() {
    await this.apiContext?.dispose();
    await this.page?.close();
    await this.browser?.close();
  }
}

setWorldConstructor(SandboxWorld);
