import { test, expect } from '@playwright/test';

test.describe('Smoke — AIQUAA', () => {
  test('la página principal carga correctamente', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.goto('/');

    const title = await page.title();
    expect(title.length).toBeGreaterThan(0);

    expect(errors).toHaveLength(0);
  });

  test('la sección de laboratorios responde', async ({ page }) => {
    await page.goto('/labs');
    await expect(page).toHaveURL(/\/labs/);
  });

  test('el login del laboratorio carga sin error', async ({ page }) => {
    const response = await page.goto('/auth/login');
    expect(response?.status()).toBeLessThan(400);
    await expect(page.getByTestId('auth-login-form')).toBeVisible();
  });
});
