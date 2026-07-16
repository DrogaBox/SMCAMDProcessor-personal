# Per-CPU-Family Capability Profiles & Dead Code Cleanup

**Goal:** Define explicit capability profiles for every supported AMD CPU family, enabling the correct features for each and removing dead/inapplicable code paths that currently serve no CPU.

**Architecture:** Extend the existing `ZenCpuFeatureMap` approach (currently only used for Vermeer) to all 9 CPU groups. Remove Intel-style MWAIT, IO_CSTATE, and the `supportsMwait` flag, which are dead code. Keep only `sti;hlt` (SIMPLE) as the single idle strategy, active only on CPUs where `pmDispatch` is registered (Zen 1/2).

## Background

The kext currently detects 9 CPU groups in `start()` but only Vermeer (Family 19h, Models 21h-2Fh) has an explicit `ZenCpuFeatureMap` profile. All other groups fall through to generic code that sets `zenGeneration` and `cpuArchName` but leaves feature flags (`pmDispatchAllowed`, `legacyPstateAllowed`, `cppcWriteAllowed`) at their class defaults — all `false`.

This has two problems:

1. **Zen 1/2 (Family 17h)**: macOS lacks native AMD power management for these CPUs. They need `pmDispatchAllowed = true` and `legacyPstateAllowed = true` to function. The current `false` defaults break their core functionality (frequency control, P-state management).

2. **Zen 4/5**: The idle strategy is set to `PMRYZEN_IDLE_STRATEGY_MWAIT` but `pmDispatchAllowed = false` means the dispatch table is registered as NULL — so `pmRyzen_machine_idle()` never executes. The MWAIT setting is misleading dead code.

## CPU Family Taxonomy

| Group | Family | Model Range | Architecture | Code Name |
|-------|--------|-------------|--------------|-----------|
| ZEN1 | 0x17 | ≤ 0x0F | Zen | Summit Ridge, Whitehaven |
| ZEN_PLUS | 0x17 | 0x10 - 0x2F | Zen+ | Pinnacle Ridge |
| ZEN2 | 0x17 | ≥ 0x30 | Zen 2 | Matisse, Rome |
| ZEN3_CEZANNE | 0x19 | 0x10 - 0x1F | Zen 3 | Cezanne (mobile) |
| ZEN3_VERMEER | 0x19 | 0x21 - 0x2F | Zen 3 | Vermeer (desktop) |
| ZEN3_PLUS | 0x19 | 0x40 - 0x5F | Zen 3+ | Rembrandt, Barcelo |
| ZEN4 | 0x19 | 0x60 - 0x7F | Zen 4 | Raphael, Phoenix |
| ZEN5 | 0x1A | all | Zen 5 | Granite Ridge, Strix Point |

## Proposed Profiles

### Zen 1 / Zen+ / Zen 2 (Family 17h)

These CPUs predate macOS AMD Vanilla patches. macOS cannot manage their P-states natively. The kext must register its PM dispatch and handle frequency control.

| Field | Value | Rationale |
|-------|-------|-----------|
| `supportsCPPC` | `false` | Pre-CPPC architecture; no CPPC MSRs |
| `supportsCPPCv2` | `false` | N/A |
| `legacyPstateAllowed` | `true` | Kext MUST write P-states via MSR_PSTATE_CTL |
| `pmDispatchAllowed` | `true` | Kext MUST register MachineIdle + choose_cpu |
| Idle strategy | `SIMPLE` (sti;hlt) | Only safe path; MONITOR/MWAIT unreliable on these families |
| SMU mailbox | Supported | Zen 1/2 SMU addresses are known |
| Zen gen | 1, 1, 2 | Respectively |

### Zen 3 Cezanne / Vermeer / Zen 3+ (Family 19h, Models ≤ 0x5F)

macOS AMD Vanilla patches handle CPPC natively. The kext should be telemetry-only.

| Field | Value | Rationale |
|-------|-------|-----------|
| `supportsCPPC` | `true` | CPPC MSRs present and functional |
| `supportsCPPCv2` | `false` | No CPPCv2 on Zen 3 |
| `legacyPstateAllowed` | `false` | macOS handles frequency; P-state writes race with XCPM |
| `pmDispatchAllowed` | `false` | macOS handles idle natively |
| Idle strategy | `SIMPLE` (sti;hlt) | Unused (pmDispatch=false), but set for consistency |
| SMU mailbox | Supported | Known addresses (0x3B10524 etc.) |
| Zen gen | 3 | |

### Zen 4 (Family 19h, Models 0x60-0x7F)

macOS handles natively. SMU mailbox addresses are placeholders — Curve Optimizer blocked.

| Field | Value | Rationale |
|-------|-------|-----------|
| `supportsCPPC` | `true` | CPPC MSRs present |
| `supportsCPPCv2` | `false` | Not confirmed |
| `legacyPstateAllowed` | `false` | macOS handles frequency |
| `pmDispatchAllowed` | `false` | macOS handles idle |
| Idle strategy | `SIMPLE` (sti;hlt) | Unused, consistency |
| SMU mailbox | Unsupported | Addresses unverified; CO blocked |
| Zen gen | 4 | |

### Zen 5 (Family 1Ah)

macOS handles natively. SMU mailbox completely unsupported.

| Field | Value | Rationale |
|-------|-------|-----------|
| `supportsCPPC` | `true` | CPPC MSRs present |
| `supportsCPPCv2` | `false` | Not confirmed |
| `legacyPstateAllowed` | `false` | macOS handles frequency |
| `pmDispatchAllowed` | `false` | macOS handles idle |
| Idle strategy | `SIMPLE` (sti;hlt) | Unused, consistency |
| SMU mailbox | Unsupported | CO blocked |
| Zen gen | 5 | |

## Dead Code to Remove

### 1. Intel-style MONITOR/MWAIT path (`pmAMDRyzen.c`)
- `case PMRYZEN_IDLE_STRATEGY_MWAIT` — Uses Intel `monitor`/`mwait` instructions. AMD does not report `CPUID.01h:ECX[3]` for these. Not safe on any AMD CPU.
- **Action:** Delete the case block.

### 2. IO_CSTATE idle path (`pmAMDRyzen.c`)
- `case PMRYZEN_IDLE_STRATEGY_IO_CSTATE` — Legacy path using `inw $0xf2`. Never used, no CPU selects it.
- **Action:** Delete the case block.

### 3. `supportsMwait` feature flag (`.hpp` and `.cpp`)
- Field `supportsMwait` is set in profiles but never read by any decision logic. The idle strategy is selected by a separate hardcoded check in `start()`.
- **Action:** Remove `supportsMwait` from `ZenCpuFeatureMap` struct, the Vermeer profile, and the `start()` method.

### 4. Misleading MWAIT idle strategy selection for Zen 4/5 (`AMDRyzenCPUPowerManagement.cpp`)
```cpp
if (cpuFamily == 0x1A || (cpuFamily == 0x19 && cpuModel >= 0x60)) {
    cpuIdleStrategy = PMRYZEN_IDLE_STRATEGY_MWAIT;
```
This sets MWAIT for Zen 4/5 but the dispatch is never registered, so `pmRyzen_machine_idle()` never runs. Dead and misleading.
- **Action:** Replace with simple `SIMPLE` for all CPUs. Remove the conditional.

### 5. `#ifdef PMRYZEN_IDLE_MWAIT` and `exitIdle` (`pmAMDRyzen.c`, `pmAMDRyzen.h`)
- The `#ifdef PMRYZEN_IDLE_MWAIT` compile guard is never defined. `exitIdle` handler is never registered.
- **Action:** Remove the `#ifdef` block, always set `exitIdle = 0`. Remove `pmRyzen_exit_idle()` function.

## Files Modified

| File | Changes |
|------|---------|
| `AMDRyzenCPUPowerManagement.hpp` | Add profile constants for all 8 groups. Update `ZenCpuFeatureMap` to remove `supportsMwait`. |
| `AMDRyzenCPUPowerManagement.cpp` | Replace fallthrough chains with profile-based dispatch. Remove MWAIT idle strategy selection. Remove `supportsMwait` set. Add `supportsCPPC` read from profile for all groups. |
| `pmAMDRyzen.h` | Remove `PMRYZEN_IDLE_STRATEGY_MWAIT`, `PMRYZEN_IDLE_STRATEGY_IO_CSTATE` from enum. Remove `#define PMRYZEN_IDLE_MWAIT` comment. |
| `pmAMDRyzen.c` | Remove MWAIT case, IO_CSTATE case, and `pmRyzen_exit_idle()` function. Remove `#ifdef PMRYZEN_IDLE_MWAIT` guard. Keep only SIMPLE case. |

## Files NOT Modified

- `AMDRyzenCPUPMUserClient.cpp` — No changes needed (privilege model unchanged)
- `SMCAMDProcessor/*` — No changes needed (plugin is read-only telemetry)
- `SuperIO/*` — No changes needed (fan control is independent)

## Testing

- Build: `xcodebuild -scheme "AMDRyzenCPUPowerManagement" -arch x86_64 -configuration Release`
- No runtime test possible without the actual hardware for each family.

## Open Questions

- Zen 2: macOS AMD Vanilla support is partial. Should `pmDispatchAllowed` be true or false? Conservative answer: `true` for now (same as Zen 1/2).
