#!/bin/sh
set -euo pipefail

INPUT="$(cat || true)"

do_access_token="$(
  printf '%s' "${INPUT}" \
  | jq -r '(.params.do_access_token // .do_access_token // env.do_access_token // empty)'
)"
do_project_name="$(
  printf '%s' "${INPUT}" \
  | jq -r '(.params.do_project_name // .do_project_name // empty)'
)"

[ -n "${do_access_token:-}" ] || { echo "Error: do_access_token missing" >&2; exit 1; }
[ -n "${do_project_name:-}" ] || { echo "Error: do_project_name missing" >&2; exit 1; }

echo "Creating DigitalOcean project: ${do_project_name}" >&2

resp="$(
  curl -sS -f -X POST "https://api.digitalocean.com/v2/projects" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${do_access_token}" \
    -d "$(jq -nc --arg name "$do_project_name" '{
          name: $name,
          purpose: "Web Application",
          environment: "Development"
        }')"
)"; rc=$?

if [ $rc -ne 0 ]; then
  echo "DigitalOcean API call failed" >&2
  echo "$resp" | jq . >&2 || echo "$resp" >&2
  exit 1
fi

project_id="$(printf '%s' "$resp" | jq -r '.project.id // empty')"
[ -n "$project_id" ] || { echo "Error: could not parse .project.id" >&2; echo "$resp" | jq . >&2; exit 1; }

# ✅ Emit output that matches manifest
echo "::starthub:state::{\"project_id\":\"${project_id}\"}"

# Human logs
{
  echo "Created project:"
  printf '%s\n' "$resp" | jq .
} >&2
