#!/bin/sh
set -euo pipefail

# Read entire JSON payload from stdin:
# Expecting: { "state": { ... }, "params": { "do_access_token": "...", "do_project_name": "..." } }
INPUT="$(cat || true)"

# Extract params with fallbacks:
# - Prefer stdin.params.*
# - Fallback to top-level keys (stdin.do_access_token) if present
# - Finally, fallback to env for secrets (do_access_token) for flexibility
do_access_token="$(
  printf '%s' "${INPUT}" \
  | jq -r '(.params.do_access_token // .do_access_token // env.do_access_token // empty)'
)"
do_project_name="$(
  printf '%s' "${INPUT}" \
  | jq -r '(.params.do_project_name // .do_project_name // empty)'
)"

# Validate
[ -n "${do_access_token:-}" ] || { echo "Error: do_access_token missing (stdin.params.do_access_token or env.do_access_token)" >&2; exit 1; }
[ -n "${do_project_name:-}" ] || { echo "Error: do_project_name missing (stdin.params.do_project_name)" >&2; exit 1; }

echo "Creating DigitalOcean project: ${do_project_name}" >&2

# Call DO API (fail on non-2xx)
resp="$(
  curl -sS -f -X POST "https://api.digitalocean.com/v2/projects" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${do_access_token}" \
    -d "$(jq -nc --arg name "$do_project_name" '{
          name: $name,
          purpose: "Web Application",
          environment: "Development"
        }')" \
)"; rc=$?

if [ $rc -ne 0 ]; then
  echo "DigitalOcean API call failed (HTTP non-2xx). Raw response below:" >&2
  echo "$resp" | jq . >&2 || echo "$resp" >&2
  exit 1
fi

# Parse project_id
project_id="$(printf '%s' "$resp" | jq -r '.project.id // empty')"
[ -n "$project_id" ] || { echo "Error: could not parse .project.id from response" >&2; echo "$resp" | jq . >&2; exit 1; }

# Emit the single-line state patch for the runner to merge (canonical output)
# ::starthub:state::<JSON>
# Note: use jq -Rn to safely quote strings
project_name_json="$(jq -Rn --arg n "$do_project_name" '$n')"
echo "::starthub:state::{\"project\":{\"id\":\"${project_id}\",\"name\":${project_name_json}}}"

# Optional: pretty log to stderr so it doesn't interfere with the marker line
{
  echo "Created project:"
  printf '%s\n' "$resp" | jq .
} >&2
