#!/bin/bash
# Upload English sources + Spanish translations (es-ES and es-419) to Crowdin.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/crowdin-env.sh"
cd "$ROOT"

export CROWDIN_PROJECT_ID
export CROWDIN_PERSONAL_TOKEN

echo "==> Upload sources (en)"
crowdin upload sources --no-progress

# Project targets: es-ES (Spain) and es-419 (Latin America), both use es.lproj via mapping
echo "==> Upload Spanish translations → es-ES"
crowdin upload translations -l es-ES --auto-approve-imported --import-eq-suggestions --no-progress

echo "==> Upload Spanish translations → es-419"
crowdin upload translations -l es-419 --auto-approve-imported --import-eq-suggestions --no-progress

echo "==> Done."
"$ROOT/scripts/crowdin-status.sh"
