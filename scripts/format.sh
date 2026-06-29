#!/bin/bash
# Code formatting automation script for SMCAMDProcessor & AMD Power Gadget
set -e

echo "=== Running Code Format Verification ==="

if command -v swift-format &> /dev/null; then
    echo "[+] Formatting Swift files..."
    swift-format format --in-place --recursive "AMD Power Gadget"
else
    echo "[!] swift-format not installed, skipping Swift auto-format."
fi

if command -v clang-format &> /dev/null; then
    echo "[+] Formatting C/C++ files..."
    find AMDRyzenCPUPowerManagement SMCAMDProcessor -name "*.cpp" -o -name "*.hpp" -o -name "*.c" -o -name "*.h" | xargs clang-format -i
else
    echo "[!] clang-format not installed, skipping C/C++ auto-format."
fi

echo "=== Format verification complete ==="
