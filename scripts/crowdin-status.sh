#!/bin/bash
# Show Crowdin project + Spanish progress (requires .crowdin-credentials)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/crowdin-env.sh"

API="${CROWDIN_BASE_URL}/api/v2"
AUTH="Authorization: Bearer ${CROWDIN_PERSONAL_TOKEN}"

echo "=== Project ${CROWDIN_PROJECT_ID} ==="
curl -sS -H "$AUTH" "${API}/projects/${CROWDIN_PROJECT_ID}" | python3 -c '
import sys,json
d=json.load(sys.stdin).get("data",{})
print("name:", d.get("name"))
print("identifier:", d.get("identifier"))
print("sourceLanguage:", d.get("sourceLanguageId"))
print("targetLanguages:", ", ".join(l.get("id","") for l in d.get("targetLanguages",[])))
'

echo
echo "=== Language progress ==="
curl -sS -H "$AUTH" "${API}/projects/${CROWDIN_PROJECT_ID}/languages/progress?limit=50" | python3 -c '
import sys,json
items=json.load(sys.stdin).get("data",[])
for it in items:
    d=it.get("data",{})
    lang=d.get("languageId")
    t=d.get("translationProgress")
    a=d.get("approvalProgress")
    print(f"  {lang:8} translation={t:3}%  approved={a:3}%")
'
