#!/bin/bash
# Dry-run format check for C/C++ kernel sources (fails if clang-format would change a file).
set -euo pipefail

errs=0
if ! command -v clang-format &> /dev/null; then
    echo "Warning: clang-format is not installed. Skipping format check."
    exit 0
fi

while IFS= read -r -d '' f; do
    if ! clang-format --dry-run --Werror "$f" 2>/dev/null; then
        echo "Format check failed: $f"
        errs=1
    fi
done < <(find AMDRyzenCPUPowerManagement SMCAMDProcessor \( -name "*.cpp" -o -name "*.hpp" -o -name "*.c" -o -name "*.h" \) -print0 2>/dev/null)

if [ "$errs" -ne 0 ]; then
    echo "clang-format check failed. Run scripts/format.sh to auto-fix."
    exit 1
fi

echo "Format check passed."
exit 0
