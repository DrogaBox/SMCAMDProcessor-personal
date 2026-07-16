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
| Idle strategy | Runtime `pmRyzen_idle_strategy_t` enum (v3.30.0): MWAIT para Zen 4/5, SIMPLE para Zen 3- |
| Symbol resolve | `symresolver` + KASLR dual-anchor (v3.30.0): `_mh_execute_header` primary + `&version` fallback |
| SMU mailbox | `smuCmdLock` + `mfence` barrier between command write and poll (v3.30.0) |
| Privilege | `disablePrivilegeCheck` from `-amdpnopchk`; `hasPrivilege` cached en `initWithTask` |
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

Publishes SMC keys derived from the power-management provider. Third-party tools (iStat Menus, etc.) read these without talking to the UserClient.

### Active SMC keys

| Key | Class | Format | Source |
|-----|-------|--------|--------|
| TC0E, TC0F, TC0P, TC0T, TC0p | TempPackage | SP78 | `PACKAGE_TEMPERATURE_perPackage[0]` |
| TCxC(i), TCxc(i) | TempCore (per CCD) | SP78 | `getCCDTemp(i)` con fallback a package temp |
| PCPR, PSTR | EnergyPackage | SP96 / Float | `uniPackagePowerW` |

- Key indexing: 36 positions (0-9, A-Z), defined in `KeyIndexes` constant
- TempCore fallback: if CCD temp ≤ 0, usa package temperature
- EnergyPackage soporta dual-format (SP78 y Float) para compatibilidad con apps de terceros

---

## Application (`AMD Power Gadget`)

| Module | Responsibility |
|--------|----------------|
| `ProcessorModel` | Swift `actor` — IOKit open, selector calls nonisolated, privilege error detection |
| `TelemetryModel` | `@MainActor` ObservableObject — sampling via `Task.detached(priority: .utility)`, history JSONL, charts |
| `MainDashboardView` | SwiftUI tabs, privilege banner, language UI |
| `AppLanguage` | `app_language_code` + `AppleLanguages` |
| `StatusbarController` | Menu bar extra, diff-based redraw |
| `NetworkStats` | `sysctl` IF list parsing, low alloc |
| `GraphView/*` | Custom Core Animation charts (drawsAsynchronously) |
| `DesktopWidgetExtensions` | Desktop widgets with magnetic grid-snapping (20px) |

### Concurrency model (v3.30.0)

- `ProcessorModel` es un `actor` Swift — métodos IOKit son `nonisolated`, el estado interno está protegido por el actor
- `TelemetryModel.init()` usa `nonisolated init` + `Task { await _finishInit() }` para evitar warnings de Swift 6
- Sample loop: `Timer → sample() (MainActor) → captureSnapshot() → Task.detached(utility) → performBackgroundSample() → MainActor.run → applySampleResult()` — 2 context switches
- `ioQueue` solo para CSV logging y `fetchTopProcesses` (operaciones no críticas)
- Caches TTL: GPU stats, CCD temps, fan RPMs, RAM/disk para reducir llamadas IOKit

---

## Security model summary

1. **Connect** freely (read telemetry).  
2. **Write** only if root **or** `-amdpnopchk`.  
3. **No** process-name trust.  
4. `hasPrivilege()` cacheado en `initWithTask` (`clientAuthorizedByUser`) — no se reevalúa `proc_suser()` en cada write.  
5. GPU temp inject ahora gated por `hasPrivilege()` (A-01), ya no es unprivileged.  
6. Thermal fan guard cannot be defeated by ramp/hysteresis ordering.

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
Binaries_Release/v3.30.0/
  AMD Power Gadget.app
  AMDRyzenCPUPowerManagement.kext
  SMCAMDProcessor.kext
  APGLaunchHelper.app
```

OpenCore consumes the two kexts; the app is installed under `/Applications`.

---

## Related

- [FEATURES.md](FEATURES.md)
- [INSTALLATION.md](INSTALLATION.md)
- [BOOT_ARGS.md](BOOT_ARGS.md)
- Source: `AMDRyzenCPUPowerManagement/`, `SMCAMDProcessor/`, `AMD Power Gadget/`
