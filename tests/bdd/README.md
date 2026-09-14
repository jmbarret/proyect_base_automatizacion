# BDD workspace

Step definitions y soporte de Cucumber, compartidos por todos los `.feature` del repo
(`features/` y `grupos/**/features/`).

- `tests/bdd/steps/` — steps por `data-testid` (`web.steps.ts`), reutilizables entre escenarios
- `tests/bdd/support/world.ts` — World de Cucumber (browser/page por escenario)
- `tests/bdd/support/hooks.ts` — abre/cierra el navegador antes/después de cada escenario

Ver la guía completa con ejemplo funcional contra el sandbox en
[`playwright/README.md`](../../playwright/README.md#4-caso-de-prueba-de-ejemplo-estructura-bdd).

Correr solo el ejemplo:

```bash
npm run test:bdd:demo
```
