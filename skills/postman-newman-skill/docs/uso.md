# Guía de uso — postman-newman-skill

## Instalación

```bash
npx skills add aiquaa-labs/postman-newman-skill
```

Para agentes específicos:

```bash
npx skills add aiquaa-labs/postman-newman-skill -a cursor
npx skills add aiquaa-labs/postman-newman-skill -a windsurf
npx skills add aiquaa-labs/postman-newman-skill -a cline
```

---

## Skills disponibles

### postman-newman

La skill principal. Se activa automáticamente cuando mencionás Postman, Newman, colecciones, curl, o archivos `.postman_collection.json`.

**Comandos:**

| Comando | Qué hace |
|---------|----------|
| `/postman:generate` | Genera colección desde spec, curl, código fuente o URL |
| `/postman:add-test` | Agrega pm.tests a requests existentes |
| `/postman:fix` | Analiza y repara un test fallido |
| `/postman:ci` | Genera pipeline GitHub Actions o Azure Pipelines |
| `/postman:env` | Crea o actualiza environment file |
| `/postman:run` | Corre colección con Newman y reporta resultados |

**Verificación en base de datos:** cuando la API bajo prueba es el sandbox del curso
(`aiquaa-sandbox-api`), la skill cierra el ciclo acción → verificación consultando
`POST /api/v1/sql/select`. Patrón completo (helper reutilizable + campo dinámico +
caso negativo) en `skills/postman-newman/references/sql-prerequest-pattern.md`.

**La skill siempre pregunta antes de generar.** En orden de prioridad:
1. URL base de la API
2. Endpoints y métodos
3. Body (para POST/PUT/PATCH)
4. Autenticación
5. Colección existente
6. Reglas de validación (para casos negativos)
7. CI target (solo para `/postman:ci`)
8. YML existente a modificar (solo para `/postman:ci`)
9. Versión, repo y autor (para el informe PDF — opcionales)

---

### caveman

Reduce el output de Claude ~75% sin perder precisión técnica.

```
/caveman          → activar modo full (default)
/caveman lite     → menos agresivo, frases completas
/caveman ultra    → máxima compresión, telegráfico
stop caveman      → desactivar
```

---

### caveman-review

Code review en una línea por hallazgo.

```
/caveman-review   → activar para la sesión
```

Formato de salida: `L42: 🔴 bug: user can be null. Add guard.`

---

### caveman-commit

Genera mensajes de commit en formato Conventional Commits.

```
/caveman-commit   → generar mensaje para los cambios actuales
```

---

### caveman-compress

Comprime archivos de memoria para ahorrar tokens en cada sesión.

```
/caveman:compress CLAUDE.md
/caveman:compress docs/referencia.md
```

Genera backup en `CLAUDE.original.md`. Comprime solo prosa — código y URLs intactos.

---

## Generador de informes PDF

### Instalación de dependencias

```bash
pip install reportlab Pillow
```

### Uso básico

```bash
# Newman genera el JSON de resultados
newman run tests/postman/C_MI_API.json \
  -e tests/postman/E_MI_API.json \
  -r json \
  --reporter-json-export results/output.json

# Generar informe PDF
python reporter/newman_report.py \
  --results results/output.json
```

### Uso completo con todos los parámetros

```bash
python reporter/newman_report.py \
  --results  results/output.json \
  --banner   reporter/assets/banner_portada.png \
  --logo-aiquaa  reporter/assets/logo_aiquaa_circle.png \
  --logo-postman reporter/assets/logo_postman_clean.png \
  --api-version  "v1.2.0" \
  --repo-url     "https://github.com/org/repo" \
  --author       "Nombre Apellido — email@dominio.com" \
  --output       "INFORME_DE_AUT_MI_API.pdf"
```

Si no pasás `--output`, el nombre se genera automáticamente desde el nombre de la colección: `INFORME_DE_AUT_MI_API.pdf`.

Si elegís anónimo, omitís `--author`.

### Qué contiene el informe

- Portada con banner, estadísticas (peticiones / pruebas / aprobadas / fallidas), fecha, duración, versión, repo y autor
- Detalle por petición: método, URL, HTTP status, tiempo de respuesta, resultado de cada prueba, cuerpo de respuesta
- Header con logos Postman + aiquaa en todas las páginas internas
- Footer con autor y `Powered by skill postman-newman · aiquaa.com`

---

## Convención de archivos

```
tests/
  postman/
    C_MI_API.json              ← colección
    E_MI_API.json              ← environment local
    E_MI_API_STAGING.json      ← environment staging
.github/
  workflows/
    Y_MI_API.yml               ← GitHub Actions
azure-pipelines/
    Y_MI_API.yml               ← Azure Pipelines
results/
    INFORME_DE_AUT_MI_API.pdf  ← informe generado
```

---

## Créditos

Creado por [aiquaa](https://aiquaa.com/) — *Saber es calidad*

Skills de caveman basadas en [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — MIT License.
