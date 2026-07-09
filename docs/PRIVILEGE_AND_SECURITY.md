# Privilege & Security Model (v3.16.1+)

## Overview

`AMDRyzenCPUPowerManagement.kext` exposes an IOKit **UserClient** used by AMD Power Gadget (and tools such as `amdtelemetryd`).

Authorization is **not** based on process name (that was removed because any binary could be renamed to bypass checks).

---

## Connection vs privilege

### 1. Opening the UserClient (`initWithTask`)

| Client | Result |
|--------|--------|
| Any process (including non-root menu bar app) | Connection **allowed** (read-only by default) |
| Root **or** boot-arg `-amdpnopchk` | Connection marked **privileged** (`clientAuthorizedByUser = true`) |

Process name is logged only for audit (`IOLog`).

### 2. Per-selector privilege (`hasPrivilege`)

Write selectors call `hasPrivilege()` and return `kIOReturnNotPrivileged` if denied.

**Writes that require privilege** (non-exhaustive):

| Selector | Action |
|----------|--------|
| 10, 15 | P-State control / raw P-State defs |
| 12, 14, 19 | CPB / PPM / LPM |
| 24, 25 | CPPC active / EPP value |
| 95–97, 99 | Fan override / restore / bulk / raw SuperIO write |
| 101, 102 | Fan curve LUT / fan→curve map |
| 111 | Curve Optimizer set |

**Reads** (telemetry, fan RPM, package temp, sensor packet 100, Curve Optimizer get 110, etc.) do **not** require root.

### 3. Special case: GPU temperature inject (selector 103)

The app injects GPU °C so kernel fan curves can use GPU as a source **without** root (menu bar process).

- **Not** gated by `hasPrivilege()` (by design).  
- Values are **clamped to [0, 120] °C** so a malicious client cannot starve thermal curves with absurd numbers.

---

## Privilege UX in the app

When a privileged write fails, AMD Power Gadget:

1. Detects `kIOReturnNotPrivileged` (`0xe00002c1`).  
2. Shows an orange **banner** at the top of the main dashboard with a clear message.  
3. Does not silently pretend the toggle/slider succeeded (control state is reloaded from the kext).

Message (EN):

> This action requires administrator privileges. Run AMD Power Gadget as root, or add the boot argument `-amdpnopchk` for debugging.

---

## Recommended production setup (personal Hackintosh)

```text
boot-args: ... -amdcppcactive -amdpnopchk
```

- Telemetry works for the normal user.  
- Full control from the menu bar app without `sudo`.  
- You accept the security tradeoff of `-amdpnopchk`.

---

## Hardening notes (already implemented)

- No process-name allowlist.  
- SuperIO multi-step I/O protected by `IOLock` (`superIOLock`).  
- Thermal fan guard (85 °C / 80 % PWM) applied **after** hysteresis/ramp.  
- Invalid UserClient selectors return `kIOReturnUnsupported`.  
- Kext load `kunc_alert` shown at most once per alert cycle (no modal spam on every poll).
