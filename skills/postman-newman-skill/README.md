# postman-newman-skill

> Automatización de pruebas de API con Postman + Newman — powered by [aiquaa](https://aiquaa.com/)

Skill para Claude Code, Cursor, Windsurf y 40+ agentes de IA. Genera colecciones Postman, corre Newman, analiza fallos y produce informes PDF profesionales — todo con salidas ultra-compactas estilo caveman.

---

## ¿Qué incluye?

| Componente | Qué hace |
|------------|----------|
| `skills/postman-newman` | Skill principal — genera colecciones, tests, CI pipelines |
| `skills/postman-newman/references/sql-prerequest-pattern.md` | Patrón SQL REST dinámico — pre-request + post-response validando la base de datos, con helper reutilizable y casos negativos |
| `skills/caveman` | Modo comprimido — reduce tokens ~75% sin perder precisión técnica |
| `skills/caveman-review` | Code review en una línea por hallazgo |
| `skills/caveman-commit` | Mensajes de commit Conventional Commits, sin ruido |
| `skills/caveman-compress` | Comprime archivos de memoria (CLAUDE.md, docs) para ahorrar tokens de entrada |
| `reporter/newman_report.py` | Generador de informe PDF con logos, estadísticas y detalle por petición |

---

## Instalación

```bash
# Claude Code
npx skills add aiquaa-labs/postman-newman-skill

# Cursor
npx skills add aiquaa-labs/postman-newman-skill -a cursor

# Windsurf
npx skills add aiquaa-labs/postman-newman-skill -a windsurf

# Cualquier otro agente
npx skills add aiquaa-labs/postman-newman-skill
```

---

## Uso rápido — skill

Activá la skill con cualquiera de estos triggers:

```
/postman:generate   → generar colección desde spec / curl / código fuente
/postman:add-test   → agregar pm.tests a requests existentes
/postman:fix        → analizar y reparar test fallido
/postman:ci         → generar pipeline GitHub Actions o Azure Pipelines
/postman:env        → crear o actualizar environment file
/postman:run        → correr colección y reportar resultados
```

La skill siempre recolecta contexto antes de generar — URL, endpoints, body, auth, validadores. Ver [Context Intake](skills/postman-newman/SKILL.md).

---

## Uso rápido — reporte PDF

```bash
pip install reportlab Pillow

python reporter/newman_report.py \
  --results results/output.json \
  --banner  reporter/assets/banner_portada.png \
  --logo-aiquaa reporter/assets/logo_aiquaa_circle.png \
  --logo-postman reporter/assets/logo_postman_clean.png \
  --api-version "v1.0.0" \
  --repo-url "https://github.com/org/repo" \
  --author "Nombre — email@dominio.com"
```

Salida: `INFORME_DE_AUT_<NOMBRE_API>.pdf`

---

## Convención de nombres de archivos

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Colección | `C_NOMBRE_DE_API.json` | `C_MYTHS_API.json` |
| Environment | `E_NOMBRE_DE_API.json` | `E_MYTHS_API.json` |
| Pipeline CI | `Y_NOMBRE_DE_API.yml` | `Y_MYTHS_API.yml` |
| Informe PDF | `INFORME_DE_AUT_NOMBRE_DE_API.pdf` | `INFORME_DE_AUT_MYTHS_API.pdf` |

---

## Stack de skills incluidas

Las skills de caveman viajan con esta skill para mantener las salidas comprimidas y eficientes. Se activan de forma independiente:

```
/caveman              → modo comprimido (~75% menos tokens)
/caveman lite|ultra   → ajustar intensidad
/caveman-review       → code review en una línea
/caveman-commit       → commit message Conventional Commits
/caveman:compress     → comprimir CLAUDE.md u otros archivos de memoria
```

---

## Estructura del repositorio

```
postman-newman-skill/
├── skills/
│   ├── postman-newman/     → skill principal
│   ├── caveman/            → modo comprimido
│   ├── caveman-review/     → review comprimido
│   ├── caveman-commit/     → commits comprimidos
│   └── caveman-compress/   → compresión de memoria
├── reporter/
│   ├── newman_report.py    → generador PDF
│   ├── requirements.txt    → dependencias Python
│   └── assets/             → logos y banner
├── examples/
│   ├── C_EXAMPLE_API.json
│   ├── E_EXAMPLE_API.json
│   ├── Y_EXAMPLE_API_github.yml
│   ├── Y_EXAMPLE_API_azure.yml
│   └── sample_results.json
├── docs/
│   └── uso.md
└── .github/
    └── workflows/
        └── Y_POSTMAN_NEWMAN_SKILL_CI.yml
```

---

## Créditos

Creado por [aiquaa](https://aiquaa.com/) — *Saber es calidad*

Skills de caveman basadas en [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — MIT License.

## Licencia

MIT
