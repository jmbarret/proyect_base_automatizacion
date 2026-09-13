# Agente de IA de ejemplo — Carrito de Compras (Grupo 07)

Implementación de ejemplo de un **agente de IA** (function-calling) que opera el
módulo de Carrito de Compras del sandbox (`app/api/v1/ordenes`, RF-G7-01..05) mediante
sus 5 endpoints. Vive junto a la automatización del grupo para poder probarse desde este
repositorio (`proyect_base_automatizacion`).

## Archivos
- `agent.mjs` — bucle del agente: intención en lenguaje natural → elige y ejecuta el `tool`.
  Incluye un **LLM mock** para correr sin claves externas.
- `tools/carrito-tools.mjs` — los 5 `tools` (JSON Schema + `execute()` vía `fetch`), listos
  para enchufar a OpenAI/Anthropic function-calling.

## Cómo correr (demo)
```bash
# API en vivo + esquema qa_training (ver .env.example del repo aiqa-sandbox-api)
BASE_URL=http://localhost:3001 API_KEY=tu_api_key node agent.mjs
```
Sin servidor, el demo arranca y reporta `networkError` por cada llamada en vez de crashear.

## Usar un LLM real
Reemplaza `callLLM(messages)` en `agent.mjs` por la llamada a tu proveedor, devolviendo
`{ tool, args }` a partir de `carritoTools` (pásalas como `tools`/`functions` del modelo).

## Relación con la automatización del grupo
- El mismo contrato está cubierto por `features/carrito-ecommerce.feature` (BDD, skill `bdd`).
- Y por `postman/grupo-07-carrito-ecommerce.postman_collection.json` (regresión con Newman).
