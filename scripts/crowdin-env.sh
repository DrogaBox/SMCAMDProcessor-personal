#!/bin/bash
# Load Crowdin API credentials for local agent / CLI use.
# Expected file (gitignored): .crowdin-credentials in repo root
# Format:
#   CROWDIN_PROJECT_ID=123456
#   CROWDIN_PERSONAL_TOKEN=your_token_here
#
# Optional:
#   CROWDIN_BASE_URL=https://api.crowdin.com  (default; use https://*.crowdin.com/api/v2 for Enterprise)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRED="${CROWDIN_CREDENTIALS_FILE:-$ROOT/.crowdin-credentials}"

if [[ ! -f "$CRED" ]]; then
  echo "Missing credentials file: $CRED" >&2
  echo "Create it with:" >&2
  echo "  CROWDIN_PROJECT_ID=<numeric id>" >&2
  echo "  CROWDIN_PERSONAL_TOKEN=<personal access token>" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "$CRED"
set +a

if [[ -z "${CROWDIN_PROJECT_ID:-}" || -z "${CROWDIN_PERSONAL_TOKEN:-}" ]]; then
  echo "CROWDIN_PROJECT_ID and CROWDIN_PERSONAL_TOKEN must be set in $CRED" >&2
  exit 1
fi

export CROWDIN_BASE_URL="${CROWDIN_BASE_URL:-https://api.crowdin.com}"
export CROWDIN_PROJECT_ID
export CROWDIN_PERSONAL_TOKEN
