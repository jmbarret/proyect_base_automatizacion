# bdd-skill — CLAUDE.md

## Project

BDD skill (Gherkin + cucumber-js + Playwright) for the aiquaa automation course.
Owned by aiquaa-labs. Depends on `sandbox-skill` for the practice API contract —
never duplicate endpoint/table facts here, reference sandbox-skill instead.

## Structure

```
skills/bdd/      ← main skill (context intake + step catalog)
examples/        ← F_, S_, world.ts, hooks.ts, cucumber.js, Y_ templates
reporter/        ← PDF report generator (Python + reportlab), reads cucumber JSON
docs/            ← usage guide in Spanish
```

## File naming convention

- Features: `F_GRUPO_NN_MODULO.feature` (NN zero-padded, MODULO UPPER_SNAKE_CASE)
- Steps:    `S_<capa>.steps.ts` (`api`, `web`, `db`)
- Pipeline: `Y_<NOMBRE>_bdd.yml`
- Report:   `INFORME_BDD_<NOMBRE>.pdf`

## Key rules

- Steps are parametrized and reused across features — never write a one-off step
  when the catalog in SKILL.md already covers the shape.
- DB verification steps always use `params` placeholders against
  `POST /api/v1/sql/select` — never string-interpolate a value into SQL.
- Table/column names in DB steps are checked against a local whitelist
  (`S_db.steps.ts`) in addition to the server-side one — defense in depth.
- Each escaped criterio ("# criterio: ...") comment above a Scenario feeds the
  traceability matrix in the PDF reporter — encourage writing them.
- Reporter lang: Spanish output.
