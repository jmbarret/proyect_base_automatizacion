import { test, expect } from '@playwright/test';

// Reemplazá con los nombres reales de la app —
// la skill los genera con selectores del código fuente si lo compartís

test.describe('Login — flujo completo', () => {

  test('login exitoso redirige al dashboard', async ({ page }) => {
    await page.goto('/login');
    await page.getByRole('textbox', { name: /usuario|email/i })
      .fill(process.env.TEST_USER || 'testuser@empresa.com');
    await page.getByRole('textbox', { name: /contraseña|password/i })
      .fill(process.env.TEST_PASSWORD || 'TestPass123');
    await page.getByRole('button', { name: /iniciar sesión|login|entrar/i }).click();
    await expect(page).toHaveURL(/dashboard|home|inicio/);
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  });

  test('credenciales inválidas muestran error', async ({ page }) => {
    await page.goto('/login');
    await page.getByRole('textbox', { name: /usuario|email/i })
      .fill('usuario@invalido.com');
    await page.getByRole('textbox', { name: /contraseña|password/i })
      .fill('claveincorrecta');
    await page.getByRole('button', { name: /iniciar sesión|login|entrar/i }).click();
    await expect(page.getByRole('alert')).toBeVisible();
    await expect(page).toHaveURL(/login/);
  });

  test('campos vacíos no permiten submit', async ({ page }) => {
    await page.goto('/login');
    await page.getByRole('button', { name: /iniciar sesión|login|entrar/i }).click();
    await expect(
      page.getByRole('alert').or(page.locator('[aria-invalid="true"]'))
    ).toBeVisible();
  });

});

test.describe('API — /api/health', () => {

  test('health check retorna 200', async ({ request }) => {
    const response = await request.get('/api/health');
    expect(response.status()).toBe(200);
  });

  test('endpoint protegido sin token retorna 401', async ({ request }) => {
    const response = await request.get('/api/me');
    expect(response.status()).toBe(401);
  });

});
