#!/bin/bash
# Upload English sources + Spanish translations from the repo to Crowdin.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/crowdin-env.sh"
cd "$ROOT"

# crowdin.yml uses project_id_env / api_token_env
export CROWDIN_PROJECT_ID
export CROWDIN_PERSONAL_TOKEN

echo "==> Upload sources (en)"
crowdin upload sources --no-progress

echo "==> Upload Spanish translations"
crowdin upload translations -l es --auto-approve-imported --import-eq-suggestions --no-progress

echo "==> Done. Spanish should now appear in Crowdin."
"$ROOT/scripts/crowdin-status.sh"
