import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/playwright',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 4 : undefined,
  reporter: [
    ['list'],
    ['json',  { outputFile: 'results/playwright-results.json' }],
    ['junit', { outputFile: 'results/playwright-junit.xml' }],
    ['html',  { outputFolder: 'results/playwright-report', open: 'never' }],
  ],
  use: {
    baseURL:    process.env.BASE_URL || 'http://localhost:4200',
    trace:      'on-first-retry',
    screenshot: 'only-on-failure',
    video:      'on-first-retry',
  },
  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'playwright/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
});
