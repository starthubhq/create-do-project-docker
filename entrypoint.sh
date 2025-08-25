#!/bin/sh
set -euo pipefail

if [ -z "${do_access_token:-}" ]; then
  echo "Error: do_access_token env variable is required" >&2
  exit 1
fi

if [ -z "${do_project_name:-}" ]; then
  echo "Error: do_project_name env variable is required" >&2
  exit 1
fi

echo "Creating DigitalOcean project: $do_project_name"

resp=$(curl -s -X POST "https://api.digitalocean.com/v2/projects" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $do_access_token" \
  -d "{
    \"name\": \"$do_project_name\",
    \"purpose\": \"Web Application\",
    \"environment\": \"Development\"
  }")

echo "$resp" | jq .
