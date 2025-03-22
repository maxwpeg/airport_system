#!/bin/bash

DEBEZIUM_URL="http://debezium:8083/connectors"  # URL для запросов
CONNECTORS_DIR="/app/connectors"  # Директория с JSON-файлами
TOTAL_COUNT=8  # Число запросов

echo "Starting to send connector configurations..."

for ((i=0; i<=TOTAL_COUNT; i++)); do
  JSON_FILE="$CONNECTORS_DIR/connector_${i}.json"
  if [[ -f "$JSON_FILE" ]]; then
    echo "Sending $JSON_FILE to $DEBEZIUM_URL"
    curl -X POST \
      --location "$DEBEZIUM_URL" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d @"$JSON_FILE"
  else
    echo "File $JSON_FILE not found, skipping."
  fi
done

echo "Finished sending connectors."
exit 0
