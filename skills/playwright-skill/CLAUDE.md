# playwright-skill — CLAUDE.md

## Project

E2E and API automation skill for Microsoft Playwright. Owned by aiquaa-labs.
Lives at `Z:\Proyectos\aiquaa-labs\playwright-skill`.
Complementary to postman-newman-skill (functional JSON), hurl-skill (declarative CLI),
and jmeter-skill (performance). Playwright = E2E browser + API in TypeScript.

## Structure

```
skills/playwright/   ← main skill (context intake + spec generation)
examples/            ← T_, Y_, config, auth templates
reporter/            ← PDF executive report (Python + reportlab)
docs/                ← usage guide in Spanish
.github/workflows/   ← CI for the skill itself
```

## File naming convention

- Test specs:    `T_NOMBRE_DE_FLUJO.spec.ts`
- Page Objects:  `pages/NombrePage.ts`
- Auth setup:    `auth.setup.ts`
- Config:        `playwright.config.ts`
- Pipelines:     `Y_NOMBRE_playwright.yml`
- Reports:       `INFORME_E2E_NOMBRE.pdf`

## Key rules

- Always use role-based selectors first: `getByRole`, `getByLabel`, `getByText`
- Never hardcode credentials — always `process.env.TEST_USER` / `process.env.TEST_PASSWORD`
- Auth via storageState — one login in auth.setup.ts, all tests reuse the session
- Reporters: always include json + junit + html in playwright.config.ts
- Pipeline: PublishTestResults@2 with JUnit XML — same pattern as hurl-skill
- PDF: executive report with suite summary + failures + verdict
- Verdict logic: failed=0 = VERDE | pass_rate>=85% = FALLOS MENORES | else = REGRESIÓN CRÍTICA
