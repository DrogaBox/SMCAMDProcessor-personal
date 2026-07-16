# Per-CPU-Family Profiles Implementation Plan

> **For agentic workers:** Execute this plan task-by-task in order. Each task builds on the previous one.

**Goal:** Add explicit capability profiles for all 8 AMD CPU families, enabling correct features per family, and remove dead idle code paths.

**Architecture:** Extend the existing `ZenCpuFeatureMap` pattern (currently only Vermeer) to all detected CPU groups. Remove Intel-style MWAIT, IO_CSTATE, and `supportsMwait` flag — all dead code.

**Files modified:**
- `AMDRyzenCPUPowerManagement.hpp`
- `AMDRyzenCPUPowerManagement.cpp`
- `pmAMDRyzen.h`
- `pmAMDRyzen.c`

---

### Task 1: Update `pmAMDRyzen.h` — Clean enum and dead defines

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/pmAMDRyzen.h`

Changes:
- Remove `PMRYZEN_IDLE_STRATEGY_MWAIT` (Intel-style, unsafe on AMD)
- Remove `PMRYZEN_IDLE_STRATEGY_IO_CSTATE` (legacy, unused)
- Remove `#undef PMRYZEN_IDLE_MWAIT` and related comment block about compile-time guards
- Keep `PMRYZEN_IDLE_STRATEGY_SIMPLE` as the only strategy
- Remove `PMRYZEN_IDLE_STRATEGY_MWAITX` if it was added (it wasn't in the current codebase)

The enum becomes:
```c
typedef enum {
    PMRYZEN_IDLE_STRATEGY_SIMPLE = 0,  // sti; hlt — safe for all AMD CPUs
} pmRyzen_idle_strategy_t;
```

---

### Task 2: Update `pmAMDRyzen.c` — Remove dead idle paths

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/pmAMDRyzen.c`

Changes:
- Remove the entire `case PMRYZEN_IDLE_STRATEGY_MWAIT` block
- Remove the entire `case PMRYZEN_IDLE_STRATEGY_IO_CSTATE` block
- Remove the `#ifdef PMRYZEN_IDLE_MWAIT` / `#else` / `#endif` guard in `exitIdle` field of `pmRyzen_cpuFuncs` — always set `.exitIdle = 0`
- Remove `pmRyzen_exit_idle()` function (only used by the MWAIT exit path)
- Remove `#include <i386/proc_reg.h>` if it was only needed for monitor/mwait (keep it if used elsewhere)
- Simplify the switch to just the SIMPLE case:
```c
switch (pmRyzen_idle_strategy) {
case PMRYZEN_IDLE_STRATEGY_SIMPLE:
default: {
    __asm__ volatile("sti;hlt;");
    break;
}
}
```

---

### Task 3: Update `AMDRyzenCPUPowerManagement.hpp` — Profile constants

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.hpp`

Changes:
- Remove `supportsMwait` from the `ZenCpuFeatureMap` struct
- Remove `supportsMwait` from the `VERMEER_ZEN3_PROFILE` constant
- Add profile constants for all 8 CPU groups
- Remove `supportsMwait` member variable from class

New profile constants:
```cpp
static constexpr ZenCpuFeatureMap ZEN1_PROFILE = {
    0x17, 0x00, 0x0F, "Zen",
    false, false,
    true, true
};
static constexpr ZenCpuFeatureMap ZEN_PLUS_PROFILE = {
    0x17, 0x10, 0x2F, "Zen+",
    false, false,
    true, true
};
static constexpr ZenCpuFeatureMap ZEN2_PROFILE = {
    0x17, 0x30, 0xFF, "Zen 2",
    false, false,
    true, true
};
static constexpr ZenCpuFeatureMap ZEN3_CEZANNE_PROFILE = {
    0x19, 0x10, 0x1F, "Zen 3 Cezanne",
    true, false,
    false, false
};
static constexpr ZenCpuFeatureMap ZEN3_VERMEER_PROFILE = {
    0x19, 0x21, 0x2F, "Zen 3 Vermeer",
    true, false,
    false, false
};
static constexpr ZenCpuFeatureMap ZEN3_PLUS_PROFILE = {
    0x19, 0x40, 0x5F, "Zen 3+",
    true, false,
    false, false
};
static constexpr ZenCpuFeatureMap ZEN4_PROFILE = {
    0x19, 0x60, 0x7F, "Zen 4",
    true, false,
    false, false
};
static constexpr ZenCpuFeatureMap ZEN5_PROFILE = {
    0x1A, 0x00, 0xFF, "Zen 5",
    true, false,
    false, false
};
```

Update struct (remove `supportsMwait`):
```cpp
struct ZenCpuFeatureMap {
    uint32_t family;
    uint32_t modelStart;
    uint32_t modelEnd;
    const char *generationName;
    bool supportsCPPC;
    bool supportsCPPCv2;
    bool legacyPstateAllowed;
    bool pmDispatchAllowed;
};
```

Remove `supportsMwait` member variable from class body.

---

### Task 4: Update `AMDRyzenCPUPowerManagement.cpp` — Profile dispatch + cleanup

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp`

Changes:
- Replace the Vermeer-specific profile if-check with a function/macro that matches ANY profile
- Apply profile to ALL CPU groups (not just Vermeer)
- Remove `supportsMwait = ...` lines
- Remove the MWAIT idle strategy selection block (the `if (cpuFamily == 0x1A || ...)` check)
- Set `cpuIdleStrategy = PMRYZEN_IDLE_STRATEGY_SIMPLE` unconditionally

The profile matching should look like:

```cpp
// Helper: find matching profile
const ZenCpuFeatureMap *activeProfile = nullptr;
const ZenCpuFeatureMap *allProfiles[] = {
    &ZEN1_PROFILE, &ZEN_PLUS_PROFILE, &ZEN2_PROFILE,
    &ZEN3_CEZANNE_PROFILE, &ZEN3_VERMEER_PROFILE, &ZEN3_PLUS_PROFILE,
    &ZEN4_PROFILE, &ZEN5_PROFILE,
};
for (auto *profile : allProfiles) {
    if (cpuFamily == profile->family &&
        cpuModel >= profile->modelStart &&
        cpuModel <= profile->modelEnd) {
        activeProfile = profile;
        break;
    }
}

if (activeProfile) {
    telemetryAllowed = activeProfile->supportsCPPC;
    cppcReadAllowed = false;
    cppcWriteAllowed = false;
    legacyPstateAllowed = activeProfile->legacyPstateAllowed;
    pmDispatchAllowed = activeProfile->pmDispatchAllowed;
    zenGeneration = /* derived from family */;
    supportsCPPC = activeProfile->supportsCPPC;
    supportsCPPCv2 = activeProfile->supportsCPPCv2;
    strlcpy(cpuArchName, activeProfile->generationName, sizeof(cpuArchName));
    IOLog("AMDRyzenCPUPowerManagement::start Profile: %s%s\n",
          activeProfile->generationName,
          activeProfile->pmDispatchAllowed ? " (full)" : " (telemetry-only)");
}
```

---

### Task 5: Build verification

**Files:**
- Build: `xcodebuild -scheme "AMDRyzenCPUPowerManagement" -arch x86_64 -configuration Release -derivedDataPath ./build`

Verify the kext compiles cleanly.
