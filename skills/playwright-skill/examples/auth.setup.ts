import { test as setup, expect } from '@playwright/test';
import path from 'path';

// Guarda el estado de sesión — todos los tests la reutilizan sin volver a hacer login
const authFile = path.join(__dirname, '../playwright/.auth/user.json');

setup('autenticar usuario de prueba', async ({ page }) => {
  await page.goto('/login');

  await page.getByRole('textbox', { name: /usuario|email/i })
    .fill(process.env.TEST_USER || 'testuser@empresa.com');

  await page.getByRole('textbox', { name: /contraseña|password/i })
    .fill(process.env.TEST_PASSWORD || 'TestPass123');

  await page.getByRole('button', { name: /iniciar sesión|login|entrar/i }).click();

  // Esperar que llegue al dashboard antes de guardar el estado
  await expect(page).toHaveURL(/dashboard|home|inicio/);

  await page.context().storageState({ path: authFile });
});
