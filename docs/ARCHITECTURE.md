# Architecture — SMCAMDProcessor stack

High-level design of the Tahoe Edition fork (personal / DrogaBox line).  
Compare with upstream spinach history in [COMPARISON.md](../COMPARISON.md).

---

## Component diagram

```text
┌─────────────────────────────────────────────────────────────┐
│  User space                                                 │
│  ┌──────────────────────┐  ┌─────────────────────────────┐  │
│  │ AMD Power Gadget.app │  │ amdtelemetryd (optional)    │  │
│  │  TelemetryModel      │  │  LaunchAgent JSONL logger   │  │
│  │  ProcessorModel      │  └──────────────┬──────────────┘  │
│  │  MainDashboardView   │                 │                 │
│  │  AppLanguage         │                 │                 │
│  └──────────┬───────────┘                 │                 │
│             │ IOConnectCall…              │                 │
│             └──────────────┬──────────────┘                 │
└────────────────────────────┼────────────────────────────────┘
                             │ UserClient
┌────────────────────────────▼────────────────────────────────┐
│  Kernel                                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ AMDRyzenCPUPowerManagement.kext                      │   │
│  │  · MSR / RAPL / CPPC / P-State (pmAMDRyzen)          │   │
│  │  · SMU mailbox (Curve Optimizer, limits)             │   │
│  │  · SuperIO fans (NCT / ITE) + fan curve engine       │   │
│  │  · UserClient selectors + hasPrivilege()             │   │
│  │  · superIOLock, thermal guard, kunc_alert once       │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │ provider / shared sensors         │
│  ┌──────────────────────▼───────────────────────────────┐   │
│  │ SMCAMDProcessor.kext (VirtualSMC plugin)             │   │
│  │  · Keys TCxx / power etc. for third-party apps       │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                   │
│  Lilu.kext → VirtualSMC.kext (must load first)              │
└─────────────────────────────────────────────────────────────┘
```

---

## Kernel driver (`AMDRyzenCPUPowerManagement`)

| Area | Implementation notes |
|------|----------------------|
| Lifecycle | `start` / `stop` teardown; sleep/wake via `reinitHwState()` |
| Per-CPU state | Cache-line aligned `pmProcessor_t`; bounds `XNU_MAX_CPU` |
| Symbol resolve | `symresolver` + Mach-O magic checks |
| Privilege | `disablePrivilegeCheck` from `-amdpnopchk`; `hasPrivilege` on writes |
| SuperIO | Families under `SuperIO/`; multi-step I/O under `IOLock` |
| Fan curves | 256-step LUT, EMA, hysteresis, ramp; thermal floor post-ramp |
| Alerts | `kunc_alert` at most once per alert cycle (`kextAlertDisplayed`) |

### UserClient (`AMDRyzenCPUPMUserClient`)

- `initWithTask`: accept all clients; mark privileged if root or `-amdpnopchk`.
- `externalMethod`: switch on selector; snapshot `fProvider`; invalid → `kIOReturnUnsupported`.
- Read path open to menu-bar apps; write path gated.

Selector groups (illustrative — see source for authoritative list):

| Range / IDs | Role |
|-------------|------|
| Low teens | P-State, CPB, PPM, LPM |
| ~24–25 | CPPC / EPP |
| ~93–103 | Fans, raw SuperIO, GPU temp inject |
| ~110–111 | Curve Optimizer get/set |
| 100 | Packed sensor packet |

---

## VirtualSMC plugin (`SMCAMDProcessor`)

Publishes SMC keys derived from the power-management provider (package temp, energy, CCD keys). Third-party tools (iStat Menus, etc.) read these without talking to the UserClient.

---

## Application (`AMD Power Gadget`)

| Module | Responsibility |
|--------|----------------|
| `ProcessorModel` | IOKit open, selector calls, privilege error detection |
| `TelemetryModel` | Sampling on `ioQueue`, history JSONL, charts data |
| `MainDashboardView` | SwiftUI tabs, privilege banner, language UI |
| `AppLanguage` | `app_language_code` + `AppleLanguages` |
| `StatusbarController` | Menu bar extra, diff-based redraw |
| `NetworkStats` | `sysctl` IF list parsing, low alloc |
| `GraphView/*` | Custom Core Animation charts |

Main-thread policy: heavy I/O offloaded to serial `ioQueue` with skip-if-busy; UI aims for smooth updates under load.

---

## Security model summary

1. **Connect** freely (read telemetry).  
2. **Write** only if root **or** `-amdpnopchk`.  
3. **No** process-name trust.  
4. GPU temp inject unprivileged but **clamped**.  
5. Thermal fan guard cannot be defeated by ramp/hysteresis ordering.

Full matrix: [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md).

---

## Data on disk (user)

| Kind | Typical location / key |
|------|------------------------|
| App preferences | App group / standard `UserDefaults` |
| Language | `app_language_code` |
| Disclaimer | `disclaimer_accepted` |
| Fan hide/labels/curves | preference keys + kext-applied LUTs |
| Telemetry history | JSONL under app support (HistoryManager) |

---

## Build products layout

```text
Binaries_Release/v3.16.x/
  AMD Power Gadget.app
  AMDRyzenCPUPowerManagement.kext
  SMCAMDProcessor.kext
```

OpenCore consumes the two kexts; the app is installed under `/Applications`.

---

## Related

- [FEATURES.md](FEATURES.md)
- [INSTALLATION.md](INSTALLATION.md)
- [BOOT_ARGS.md](BOOT_ARGS.md)
- Source: `AMDRyzenCPUPowerManagement/`, `SMCAMDProcessor/`, `AMD Power Gadget/`
