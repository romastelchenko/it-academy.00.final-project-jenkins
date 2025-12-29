#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://localhost:3000/api/v1}"
PLAYER_NICKNAME="${PLAYER_NICKNAME:-cd_test_player}"
PLAYER_FIRST_NAME="${PLAYER_FIRST_NAME:-CD}"
PLAYER_LAST_NAME="${PLAYER_LAST_NAME:-Player}"
PLAYER_SHIRT_NUMBER="${PLAYER_SHIRT_NUMBER:-9999}"
PLAYER_RATING="${PLAYER_RATING:-50}"
EXPECTED_FIELDS_COUNT="${EXPECTED_FIELDS_COUNT:-9}"

fetch_players() {
  local search="$1"
  curl -sSf "${API_URL}/players?page=1&limit=50&search=${search}&includeDeleted=false"
}

create_player() {
  curl -sSf -X POST "${API_URL}/players" \
    -H 'Content-Type: application/json' \
    -d "{\"nickname\":\"${PLAYER_NICKNAME}\",\"firstName\":\"${PLAYER_FIRST_NAME}\",\"lastName\":\"${PLAYER_LAST_NAME}\",\"shirtNumber\":${PLAYER_SHIRT_NUMBER},\"rating\":${PLAYER_RATING}}"
}

echo "Checking for player ${PLAYER_NICKNAME} #${PLAYER_SHIRT_NUMBER}..."
players_json=$(fetch_players "${PLAYER_NICKNAME}")
player_id=$(echo "$players_json" | jq -r \
  --arg nickname "$PLAYER_NICKNAME" \
  --argjson shirtNumber "$PLAYER_SHIRT_NUMBER" \
  '.items[] | select(.nickname == $nickname and .shirtNumber == $shirtNumber) | .id' | head -n1)

if [ -z "$player_id" ] || [ "$player_id" = "null" ]; then
  echo "Player not found, creating..."
  create_response=$(create_player)
  player_id=$(echo "$create_response" | jq -r '.id')
fi

if [ -z "$player_id" ] || [ "$player_id" = "null" ]; then
  echo "Failed to resolve player id"
  exit 1
fi

echo "Fetching player ${player_id}..."
player_json=$(curl -sSf "${API_URL}/players/${player_id}")
fields_count=$(echo "$player_json" | jq -r 'keys | length')
if [ "$fields_count" -ne "$EXPECTED_FIELDS_COUNT" ]; then
  echo "Unexpected field count: expected ${EXPECTED_FIELDS_COUNT}, got ${fields_count}"
  exit 1
fi

echo "Player check passed"
