#!/usr/bin/env bash
set -euo pipefail

KC_URL=${KC_URL:-http://keycloak.local}
REALM=${REALM:-task-api-realm}
CLIENT=${CLIENT:-app-client}
USER=${USER:-testuser}
PASS=${PASS:-testpass}

echo "Checking realm $REALM..."
curl -fsS "$KC_URL/realms/$REALM/.well-known/openid-configuration" >/dev/null && echo "Realm OK"

echo "Fetching token..."
TOKEN=$(curl -s -X POST "$KC_URL/realms/$REALM/protocol/openid-connect/token" \
  -d grant_type=password -d client_id="$CLIENT" -d username="$USER" -d password="$PASS" | jq -r .access_token)

if [[ -z "$TOKEN" || "$TOKEN" == null ]]; then
  echo "Failed to get token" >&2
  exit 1
fi

echo "Token acquired (first 40 chars): ${TOKEN:0:40}..."

API_HOST=${API_HOST:-http://task-api.local}
echo "Calling protected endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$API_HOST/api/tasks")

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "Success: API returned 200"
else
  echo "API returned $HTTP_CODE" >&2
  exit 2
fi