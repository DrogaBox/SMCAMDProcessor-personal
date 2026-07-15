#!/bin/bash
#===============================================================================
# CPU Compatibility Report Generator for SMCAMDProcessor
# ===============================================================================
# Usage:
#   chmod +x cpu_compat_report.sh
#   sudo ./cpu_compat_report.sh
#
# This script collects all the information needed to add support for a new
# AMD CPU family or model in SMCAMDProcessor. Run it on your Hackintosh and
# attach the output to your GitHub issue at:
#   https://github.com/DrogaBox/SMCAMDProcessor-personal/issues/new
# ===============================================================================

set -u

OUTPUT="/tmp/cpu_compat_report_$(date +%Y%m%d_%H%M%S).txt"

echo "============================================" | tee "$OUTPUT"
echo "SMCAMDProcessor - CPU Compatibility Report" | tee -a "$OUTPUT"
echo "Generated: $(date)" | tee -a "$OUTPUT"
echo "============================================" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# ---- System Info ----
echo "--- SYSTEM INFO ---" | tee -a "$OUTPUT"
sw_vers 2>/dev/null >> "$OUTPUT"
uname -a >> "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# ---- CPUID ----
echo "--- CPUID ---" | tee -a "$OUTPUT"
echo "Raw CPUID 0x01 (EAX): $(sudo sysctl -n machdep.cpu.signature 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Family:  $(sysctl -n machdep.cpu.family 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Model:   $(sysctl -n machdep.cpu.model 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Stepping: $(sysctl -n machdep.cpu.stepping 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Brand:   $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Vendor:  $(sysctl -n machdep.cpu.vendor 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Ext Features: $(sysctl -n machdep.cpu.features 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Ext Features 7: $(sysctl -n machdep.cpu.leaf7_features 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "CPU Ext Features 8: $(sysctl -n machdep.cpu.extfeatures 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "Logical CPUs: $(sysctl -n hw.logicalcpu 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "Physical CPUs: $(sysctl -n hw.physicalcpu 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "TSC Frequency: $(sysctl -n machdep.tsc.frequency 2>/dev/null || echo 'N/A')" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# ---- PCI Devices (AMD related) ----
echo "--- AMD PCI HOST BRIDGES ---" | tee -a "$OUTPUT"
echo "These are candidates for the SMN (System Management Network) aperture." | tee -a "$OUTPUT"
echo "We need the device that exposes SMN at PCI config offset 0x60." | tee -a "$OUTPUT"
system_profiler SPHardwareDataType 2>/dev/null | grep -i "model" >> "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# List AMD PCI devices with full details
echo "Full AMD PCI device list:" | tee -a "$OUTPUT"
if command -v ioreg &>/dev/null; then
    ioreg -r -c IOPCIDevice -w0 2>/dev/null | grep -A 30 '"AMD\|"amd\|Advanced Micro\|1022' | head -80 >> "$OUTPUT"
fi
echo "" | tee -a "$OUTPUT"

# Simpler: scan via lspci equivalent on macOS
if command -v pcimmu &>/dev/null; then
    pcimmu -l 2>/dev/null | grep -i "1022" | tee -a "$OUTPUT"
fi

# Try to list PCI devices using ioreg
echo "PCI devices with vendor 0x1022 (AMD):" | tee -a "$OUTPUT"
ioreg -r -c IOPCIDevice 2>/dev/null | while read -r line; do
    if echo "$line" | grep -q "IOPCIDevice"; then
        dev_path=$(echo "$line" | awk '{print $NF}')
        if [ -n "$dev_path" ]; then
            VENDOR=$(ioreg -r -c IOPCIDevice "$dev_path" 2>/dev/null | grep -i "vendor-id" | awk '{print $NF}')
            if [ "$VENDOR" = "0x1022" ]; then
                DEVICE=$(ioreg -r -c IOPCIDevice "$dev_path" 2>/dev/null | grep -i "device-id" | awk '{print $NF}')
                echo "  Vendor=0x1022 Device=$DEVICE Path=$dev_path" | tee -a "$OUTPUT"
            fi
        fi
    fi
done
echo "" | tee -a "$OUTPUT"

# ---- Kernel Extension Status ----
echo "--- KEXT STATUS ---" | tee -a "$OUTPUT"
kextstat 2>/dev/null | grep -E "spinach|Ryzen|AMD" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# Check if our kexts are loaded
if kextstat 2>/dev/null | grep -q "spinach.AMDRyzen"; then
    echo "AMDRyzenCPUPowerManagement: LOADED" | tee -a "$OUTPUT"
else
    echo "AMDRyzenCPUPowerManagement: NOT LOADED" | tee -a "$OUTPUT"
fi
if kextstat 2>/dev/null | grep -q "spinach.SMCAMDProcessor"; then
    echo "SMCAMDProcessor: LOADED" | tee -a "$OUTPUT"
else
    echo "SMCAMDProcessor: NOT LOADED" | tee -a "$OUTPUT"
fi
echo "" | tee -a "$OUTPUT"

# ---- Boot args ----
echo "--- BOOT ARGS ---" | tee -a "$OUTPUT"
if command -v nvram &>/dev/null; then
    nvram boot-args 2>/dev/null | tee -a "$OUTPUT"
fi
echo "" | tee -a "$OUTPUT"

# ---- Kext logs (last 100 lines) ----
echo "--- KEXT LOG (last 100 lines) ---" | tee -a "$OUTPUT"
log show --predicate 'subsystem contains "spinach"' --last 5m 2>/dev/null | tail -100 >> "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# Also try generic kernel log for AMDRyzen
log show --predicate 'eventMessage contains "AMDRyzen" OR eventMessage contains "pmRyzen"' --last 5m 2>/dev/null | tail -100 >> "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# ---- SuperIO detection (if available via kext) ----
echo "--- SUPERIO (if detected) ---" | tee -a "$OUTPUT"
if command -v system_profiler &>/dev/null; then
    system_profiler SPExtensionsDataType 2>/dev/null | grep -A 20 "AMDRyzen" | head -40 >> "$OUTPUT"
fi
echo "" | tee -a "$OUTPUT"

# ---- OpenCore config hints ----
echo "--- OPENCORE SETUP ---" | tee -a "$OUTPUT"
echo "OpenCore version: $(strings /System/Library/CoreServices/boot.efi 2>/dev/null | grep -i "OpenCore" | head -3)" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# ---- CPU temperature from SMC (if available) ----
echo "--- CPU TEMPERATURE via SMC (if available) ---" | tee -a "$OUTPUT"
if [ -f ./smcread ]; then
    ./smcread -l 2>/dev/null | grep -i temp | head -10 | tee -a "$OUTPUT"
elif command -v smc &>/dev/null; then
    smc -k -r 2>/dev/null | grep -i temp | head -10 | tee -a "$OUTPUT"
else
    echo "No SMC reading tools found." | tee -a "$OUTPUT"
fi
echo "" | tee -a "$OUTPUT"

# ---- macOS kernel version details ----
echo "--- KERNEL VERSION ---" | tee -a "$OUTPUT"
sysctl kern.version | tee -a "$OUTPUT"
sysctl kern.osversion | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

echo "============================================" | tee -a "$OUTPUT"
echo "Report saved to: $OUTPUT" | tee -a "$OUTPUT"
echo "Please open a GitHub issue at:" | tee -a "$OUTPUT"
echo "  https://github.com/DrogaBox/SMCAMDProcessor-personal/issues/new" | tee -a "$OUTPUT"
echo "And attach this file." | tee -a "$OUTPUT"
echo "============================================" | tee -a "$OUTPUT"

# macOS version detection for OpenCore/Lilu compat
OSVERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
echo ""
echo "Prerequisite check:"
echo "  macOS version  : $OSVERSION"
echo "  Lilu kext      : $(kextstat 2>/dev/null | grep as.vit9696.Lilu | awk '{print $6 " " $7}')"
echo "  VirtualSMC     : $(kextstat 2>/dev/null | grep as.vit9696.VirtualSMC | awk '{print $6 " " $7}')"
echo "  Python3        : $(which python3 2>/dev/null || echo 'NOT FOUND')"
echo "  Git            : $(which git 2>/dev/null || echo 'NOT FOUND')"
echo ""
echo "Upload '$OUTPUT' to your GitHub issue."
