# postman-newman-skill — CLAUDE.md

## Project

QA automation skill for Postman + Newman. Owned by aiquaa-labs. Lives at `Z:\Proyectos\aiquaa-labs\postman-newman-skill`.

## Structure

```
skills/postman-newman/   ← main skill (context intake + generation)
skills/caveman*/         ← compression skills (from JuliusBrussee/caveman fork)
reporter/                ← PDF report generator (Python)
examples/                ← C_, E_, Y_ templates
docs/                    ← usage guide in Spanish
.github/workflows/       ← CI for the skill itself
```

## File naming convention

- Collections: `C_NOMBRE_DE_API.json`
- Environments: `E_NOMBRE_DE_API.json`
- Pipelines: `Y_NOMBRE_DE_API.yml`
- Reports: `INFORME_DE_AUT_NOMBRE_DE_API.pdf`

## Skills source

- `postman-newman` — original, owned here
- `caveman*` — forked from JuliusBrussee/caveman (MIT). Edit `skills/caveman*/SKILL.md` only. Do not diverge naming.

## Reporter

- Entry: `reporter/newman_report.py`
- Deps: `reporter/requirements.txt` (reportlab, Pillow)
- Assets: `reporter/assets/` (logos, banner)
- Lang: Spanish output, technical terms stay in English
- Skill name constant: `SKILL_NAME = "postman-newman"` in reporter

## Key rules

- Never hardcode URLs in collections — always `{{baseUrl}}`
- caveman skills: edit SKILL.md only, CI syncs the rest
- Reporter: all user-facing text in Spanish except HTTP methods, URLs, status codes
- PDF filename derived auto from collection name if `--output` not passed
