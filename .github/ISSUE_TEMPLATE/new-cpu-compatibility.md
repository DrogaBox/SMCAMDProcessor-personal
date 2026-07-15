---
name: New AMD CPU Compatibility Request
about: Report a new or untested AMD CPU for compatibility data collection
title: '[CPU] AMD <Your CPU Model> - <Family/Model>'
labels: cpu-compatibility, data-needed
assignees: DrogaBox
---

## CPU Information

<!-- Please fill in the exact model name -->
- **CPU**: 
- **Codename** (e.g. Vermeer, Raphael, Granite Ridge): 
- **Expected Zen generation**: Zen 

## Required Diagnostic Data

### Step 1: Run the Compatibility Report Script

If possible, run the official data collection script:

```bash
chmod +x Tools/cpu_compat_report.sh
sudo ./Tools/cpu_compat_report.sh
```

This creates a file in `/tmp/cpu_compat_report_<date>.txt`. Attach it to this issue.

### Step 2: Manual CPUID (if script fails)

```text
CPUID 0x01 EAX   : 
Family (dec)      : 
Model (dec)       : 
Stepping (dec)    : 
Brand string      : 
Logical cores     : 
Physical cores    : 
```

You can obtain these with:
```bash
sysctl machdep.cpu.family machdep.cpu.model machdep.cpu.stepping
sysctl machdep.cpu.brand_string
sysctl hw.logicalcpu hw.physicalcpu
```

### Step 3: AMD PCI Host Bridge

```text
AMD PCI Vendor ID : 0x1022
PCI Device ID(s)  : 
```

Check with:
```bash
ioreg -r -c IOPCIDevice | grep -A5 '"vendor-id" = 0x1022'
```

### Step 4: Linux k10temp Reference (if you dual-boot Linux)

```bash
# Run on Linux and paste output:
sudo rdmsr -a 0xC0010064   # MSR_PSTATE_0 (all cores)
cat /sys/class/hwmon/hwmon*/temp1_input
cat /sys/class/hwmon/hwmon*/temp1_label
sudo lspci -nn | grep -i "Host bridge"
```

### Step 5: macOS Kext Logs

Run `AMD Power Gadget` (or load the kext manually), wait 30 seconds, then:

```bash
log show --predicate 'eventMessage contains "AMDRyzen"' --last 10m
```

Paste the last 50 lines.

### Step 6 (Optional): SuperIO Chip

If you know your motherboard model:

```text
Motherboard : 
SuperIO chip: (e.g. NCT6799D, IT8686E, etc.)
```

## Additional Context

- macOS version: 
- OpenCore version: 
- Are you using `-amdpnopchk` or `-amdcppcactive` boot args? 
- Have you tested Curve Optimizer? (not recommended on unsupported families)

## Checklist

- [ ] I have attached the compatibility report script output
- [ ] I have provided CPUID family/model/stepping
- [ ] I have provided AMD PCI host bridge device ID(s)
- [ ] I have included the kext log output (if kext loads)

---

**Note**: Adding support for a new CPU family requires validating SMU mailbox register addresses, SMN aperture offsets, temperature compensation flags, and CPPC capabilities. Without the data above, the maintainers cannot safely enable features for your CPU.
