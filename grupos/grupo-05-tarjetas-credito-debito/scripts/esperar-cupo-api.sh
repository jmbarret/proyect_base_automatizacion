#!/usr/bin/env bash
# Espera a que haya cupo en el rate limit de la sandbox AIQUAA antes de medir.
#
# El limite es de 30 req/min POR API-KEY, y la key publica la comparte toda la
# clase. Peor: en un PR que toque tests/performance/** se disparan a la vez el
# plan del curso (jmeter-performance.yml, 27 muestras/min) y los workflows de
# este grupo, todos contra la misma key.
#
# Sondear una sola request no alcanza: mientras las otras corridas se mantengan
# bajo las 30/min la API responde 200, y el limite se pasa recien al sumarnos
# nosotros. Por eso se mide HOLGURA: una rafaga corta solo pasa limpia si de
# verdad sobra cupo en la ventana.
#
# Uso: esperar-cupo-api.sh <api-key> [api-base] [rondas]
set -euo pipefail

API_KEY="${1:?Falta la api key}"
API_BASE="${2:-https://aiquaa-sandbox-api.vercel.app}"
RONDAS="${3:-12}"

RAFAGA=5
ESPERA=30

for ronda in $(seq 1 "${RONDAS}"); do
  limitado=0
  for _ in $(seq 1 "${RAFAGA}"); do
    # El "|| true" no es adorno: en Git Bash de Windows curl sale con 23
    # ("failed writing body") al combinar --output /dev/null con --write-out,
    # aunque el codigo HTTP sea correcto, y el set -e abortaria el script.
    code=$(curl --silent --max-time 15 --output /dev/null --write-out '%{http_code}' \
      --header "x-api-key: ${API_KEY}" \
      "${API_BASE}/api/v1/tarjetas/2" || true)
    code="${code:-000}"

    if [ "${code}" = "429" ]; then
      limitado=1
    fi
  done

  if [ "${limitado}" = "0" ]; then
    echo "Hay cupo en la ventana (rafaga de ${RAFAGA} sin 429) tras ${ronda} ronda(s). Se arranca."
    exit 0
  fi

  echo "Sin cupo: la rafaga dio 429, otra corrida esta usando la key. Reintento en ${ESPERA} s (${ronda}/${RONDAS})."
  sleep "${ESPERA}"
done

echo "::warning::Sigue sin haber cupo tras $((RONDAS * ESPERA / 60)) min. Se corre igual; esperar 429 en los resultados."
