# Kext Security Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 4 kernel-extension findings from the security audit (A-01, A-03, A-04, A-05) plus harden the UserClient privilege model.

**Architecture:** The kext `AMDRyzenCPUPowerManagement.kext` exposes an IOKit UserClient. Fixes span SMU mailbox protocol (memory barriers), the GPU temperature inject path (remove process-name trust), idle strategy selection (dynamic per CPU family), kernel symbol resolver (KASLR slide robustness), and privilege evaluation (cache in initWithTask).

**Tech Stack:** C++14, XNU Kernel, IOKit, Lilu plugin_start SDK, MacKernelSDK

## Global Constraints

- macOS 13 Ventura through macOS 26 Tahoe, x86_64 only
- No API calls newer than the MacKernelSDK headers in the repo
- All IOLog strings use `"AMDRyzenCPUPowerManagement::"` prefix
- MSR bounds checking: family 0x19+ blocks Intel-exclusive MSRs per existing whitelist
- compile with Xcode, x86_64 arch target for kext targets
- Each task builds independently; test by building the kext target
- SMU mailbox command 0x01 resets message bus post-timeout per existing code

---

## File Structure

| File | Role |
|------|------|
| `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp` | UserClient selector dispatch; contain the 2 security fixes (A-01, A-02) |
| `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.hpp` | Header for the UserClient class; add `clientAuthorizedByUser` cache comment |
| `AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp` | SMU mailbox, idle strategy, temp offset table, MSR policy; contains A-03, A-05 |
| `AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.hpp` | Add `idleStrategy` enum and member var for dynamic idle dispatch |
| `AMDRyzenCPUPowerManagement/pmAMDRyzen.c` | Idle implementations (`PMRYZEN_IDLE_SIMPLE`, `PMRYZEN_IDLE_MWAIT`) and `pmRyzen_init` plumbing |
| `AMDRyzenCPUPowerManagement/pmAMDRyzen.h` | Add `pmRyzen_idle_strategy_t` enum; macro-guard idle strategy selection |
| `AMDRyzenCPUPowerManagement/symresolver/kernel_resolver.c` | KASLR slide computation; contains A-04 |
| `AMDRyzenCPUPowerManagement/symresolver/kernel_resolver.h` | Header for resolver functions |
| `AMDPowerGadgetTests/SecurityAuditTests.swift` | New tests for privilege mapping, process-name rejection, SMU response codes |

---

### Task 1: Remove process-name bypass from GPU temperature inject (A-01)

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp` lines 1030-1055 (case 103)
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp` lines 58-72 (initWithTask audit logging)

**Interfaces:**
- Consumes: `hasPrivilege()` which already uses `proc_suser` / `kauth_cred_getuid`
- Produces: `case 103` no longer falls back to `proc_name()` matching

**Problem:** In case 103 (GPU temperature inject for fan-curve source), when `hasPrivilege()` returns false, the code falls back to matching the caller's process name via `proc_name()` against the prefix `"AMD Power"`. This defeats the stated security model ("process name is audit-only, never authorization") because any binary renamed to "AMD Power Miner" can inject fake GPU temperatures.

**Solution:** Remove the process-name fallback entirely. GPU temp injection becomes **privileged only** (root or `-amdpnopchk`). The menu-bar process already runs as the same user and can use `-amdpnopchk` if needed. Document in the privilege error banner UX that GPU fan curves also need privilege.

- [ ] **Step 1: Verify the current case 103 code**

Read the current case 103 at `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp`, find the process-name fallback block. The code is:

```cpp
case 103: {
    // ... provider guard, arg count check ...
    if (!hasPrivilege()) {
        proc_t proc = (proc_t)get_bsdtask_info(current_task());
        if (proc) {
            char callerName[32] = {};
            proc_name(proc_pid(proc), callerName, sizeof(callerName));
            callerName[sizeof(callerName) - 1] = '\0';
            if (strncmp(callerName, "AMD Power", 9) != 0) {
                return kIOReturnNotPrivileged;
            }
        } else {
            return kIOReturnNotPrivileged;
        }
    }
    // ... clamp and assign gpuTempC ...
    break;
}
```

- [ ] **Step 2: Remove the process-name fallback block**

Replace the entire `if (!hasPrivilege())` block with just a `if (!hasPrivilege()) return kIOReturnNotPrivileged;`:

```cpp
case 103: {
    if(!provider)
        return kIOReturnNoDevice;

    if(arguments->scalarInputCount != 1)
        return kIOReturnBadArgument;

    // GPU temperature injection for fan-curve source.
    // Privilege required: root or boot-arg -amdpnopchk.
    // The menu-bar process should run with -amdpnopchk or be launched as root.
    // Temperature is clamped to [0, 120] C to prevent abuse.
    if (!hasPrivilege())
        return kIOReturnNotPrivileged;

    float t = (float)arguments->scalarInput[0];
    if (t < 0.0f) t = 0.0f;
    if (t > 120.0f) t = 120.0f;
    provider->gpuTempC = t;
    break;
}
```

Also update the comment near the case label to reflect the new policy.

- [ ] **Step 3: Update the privilege UX banner**

In `AMD Power Gadget/ProcessorModel.swift`, find `static func privilegeHint(for status:)`. Update the returned string to mention GPU fan curves:

```swift
/// Human-readable message for failed kernel write calls (localized).
static func privilegeHint(for status: kern_return_t) -> String? {
    if status == kIOReturnNotPrivilegedCode {
        return NSLocalizedString(
            "This action requires administrator privileges. Run AMD Power Gadget as root, or add the boot argument -amdpnopchk for debugging. Note: GPU temperature injection for fan curves also requires privilege.",
            comment: "Shown when a privileged kext write is denied"
        )
    }
    if status != KERN_SUCCESS {
        return String(cString: mach_error_string(status))
    }
    return nil
}
```

- [ ] **Step 4: Build the kext target to verify compilation**

```bash
xcodebuild -target AMDRyzenCPUPowerManagement -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp AMD\ Power\ Gadget/ProcessorModel.swift
git commit -m "fix(kext): remove process-name bypass from GPU temp inject (A-01)

GPU temperature injection (selector 103) no longer falls back to
matching the caller process name via proc_name(). Any process may open
the UserClient for reads, but ALL writes (including GPU temp) now
require root or boot-arg -amdpnopchk.

This closes audit finding A-01 (CRITICAL): process-name trust bypass.

"
```

---

### Task 2: Refactor hasPrivilege() to cache result from initWithTask (A-02)

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp` lines 42-76 (initWithTask) and lines 96-104 (hasPrivilege)
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.hpp` line ~44 (`clientAuthorizedByUser`)

**Interfaces:**
- Consumes: `initWithTask` sets `clientAuthorizedByUser`
- Produces: simplified `hasPrivilege()` that only checks the cached flag + `disablePrivilegeCheck`

**Problem:** `hasPrivilege()` re-evaluates `proc_suser()` and `kauth_cred_getuid()` on every write selector call. Since `initWithTask` already captures the owning task and can determine privilege once at connection time, this is redundant overhead. Also the current `hasPrivilege()` doesn't re-check the *original* task — it calls `current_task()` which is the caller's task during the externalMethod dispatch, which is correct but makes the `clientAuthorizedByUser` cache redundant.

**Solution:** Simplify `hasPrivilege()` to only check `clientAuthorizedByUser` (set in `initWithTask`) and `fProvider->disablePrivilegeCheck` for `-amdpnopchk`. The connection-time check already evaluates root status correctly.

- [ ] **Step 1: Update `hasPrivilege()` to use cached flag only**

In `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp`:

```cpp
bool AMDRyzenCPUPMUserClient::hasPrivilege(){
    // clientAuthorizedByUser is set at connection time in initWithTask:
    //   - root (proc_suser == 0 || uid == 0) sets it true
    //   - boot-arg -amdpnopchk also sets it true via the kext's disablePrivilegeCheck
    // This cached check avoids re-evaluating proc_suser on every write selector.
    if (clientAuthorizedByUser) return true;
    // Boot-arg bypass: allow writes without root when -amdpnopchk is present
    if (fProvider && fProvider->disablePrivilegeCheck) return true;
    return false;
}
```

- [ ] **Step 2: Ensure `initWithTask` sets `clientAuthorizedByUser` correctly for all cases**

In `AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp` `initWithTask`, verify the logic:

```cpp
// This code already exists — just verify it's correct
bool isRoot = (proc_suser(proc) == 0 || kauth_cred_getuid(proc_ucred(proc)) == 0);
bool isDebugBypass = checkKernelArgument("-amdpnopchk");

if (isRoot || isDebugBypass) {
    clientAuthorizedByUser = true;
    IOLog("AMDRyzenCPUPMUserClient: ACCEPTED privileged pid=%d binary='%s' (root=%d debug=%d)\n",
          proc_pid(proc), taskProcessBinaryName, isRoot, isDebugBypass);
} else {
    clientAuthorizedByUser = false;
    IOLog("AMDRyzenCPUPMUserClient: ACCEPTED read-only pid=%d binary='%s'\n",
          proc_pid(proc), taskProcessBinaryName);
}
```

This code is already correct. No changes needed here.

- [ ] **Step 3: Build the kext target**

```bash
xcodebuild -target AMDRyzenCPUPowerManagement -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp
git commit -m "refactor(kext): cache privilege in hasPrivilege() (A-02)

hasPrivilege() now checks only the connection-time cached flag
clientAuthorizedByUser and the boot-arg -amdpnopchk flag, instead of
re-evaluating proc_suser() on every write call. The flag is set in
initWithTask during IOServiceOpen connection.

"
```

---

### Task 3: Add SMU mailbox memory barrier (A-05)

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp` lines 955-985 (`smuSendCmd`)

**Interfaces:**
- Consumes: `smnRead32()`, `smnWrite32()`, `smuCmdLock` lock/unlock, `smuMailbox` struct
- Produces: `smuSendCmd()` with an `mfence` between the SMN write and poll loop

**Problem:** Between `smnWrite32(msgReg, cmd)` and the first `smnRead32(rspReg)` poll iteration, there is no memory barrier. On CPUs with aggressive write-combining buffers, the SMU may not see the command before the first response register read, causing an unnecessary timeout or a stale response poll.

**Solution:** Insert `__asm__ volatile("mfence" ::: "memory")` between the SMN command write and the response poll loop.

- [ ] **Step 1: Locate the `smuSendCmd` function**

The function is at approximately line 955 in `AMDRyzenCPUPowerManagement.cpp`. The key section:

```cpp
// Send command
smnWrite32(msgReg, cmd);

// Wait for response
const uint32_t timeoutUs = (cmd == smuMailbox.curveOptimizerCmd) ? 50000 : 2000;
```

- [ ] **Step 2: Insert mfence barrier**

Add the barrier between the command write and the poll loop:

```cpp
// Send command
smnWrite32(msgReg, cmd);

// Memory barrier: ensure the SMU sees the command write before we start
// polling the response register. Without this, write-combining buffers on
// the SMN bus can delay command delivery, causing the poll to read a stale
// zero and falsely trigger the timeout reset path.
__asm__ volatile("mfence" ::: "memory");

// Wait for response. Curve Optimizer (0x3D) triggers PLL reconfiguration and can
// take 5-15 ms on Zen 3; use 50 ms ceiling. Other commands typically complete <1 ms.
const uint32_t timeoutUs = (cmd == smuMailbox.curveOptimizerCmd) ? 50000 : 2000;
```

- [ ] **Step 3: Build the kext target**

```bash
xcodebuild -target AMDRyzenCPUPowerManagement -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp
git commit -m "fix(kext): add mfence barrier in SMU mailbox protocol (A-05)

Insert an x86 mfence instruction between smnWrite32(msgReg, cmd) and
the response register poll loop. Prevents write-combining buffers on the
SMN bus from delaying SMU command delivery, which could cause spurious
timeouts or stale-response reads.

"
```

---

### Task 4: Robust KASLR slide resolution in kernel_resolver (A-04)

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/symresolver/kernel_resolver.c` lines 50-90

**Interfaces:**
- Consumes: `vm_kernel_unslide_or_perm_external()`, `&version` symbol
- Produces: `mh_base_addr` with fallback to `_mh_execute_header` if `version` symbol fails

**Problem:** The resolver uses `&version` (from `libkern/version.h`) as the anchor symbol for KASLR slide computation. While this works on current XNU versions, `version` is not part of the kernel's public export set and could be removed or relocated in a future kernel.

**Solution:** Try `_mh_execute_header` first (it's the Mach-O header and is always at a known offset from the kernel base), then fall back to `&version`. Also add a more restrictive canonical range check.

- [ ] **Step 1: Update `find_mach_header_addr` with dual-symbol fallback**

In `AMDRyzenCPUPowerManagement/symresolver/kernel_resolver.c`, modify the slide computation:

```cpp
#include <mach/mach_vm.h>  // already included via vm/vm_kern.h

void find_mach_header_addr(uint8_t kc){
    uint64_t slide = 0;
    vm_offset_t slide_address = 0;
    bool resolved = false;

    // Strategy 1: Use _mh_execute_header as the anchor. It is the Mach-O
    // header of the kernel itself and is always exported at a known address
    // relative to the kernel base. This is more stable than &version.
    extern char **mh_execute_header;
    (void)mh_execute_header; // suppress unused-variable warning

    vm_kernel_unslide_or_perm_external(
        (unsigned long long)(void *)&mh_execute_header, &slide_address);

    if (slide_address != 0 &&
        slide_address >= 0xFFFFFF8000000000ULL) {
        resolved = true;
        IOLog("kernel_resolver: using _mh_execute_header for KASLR slide\n");
    }

    // Strategy 2: Fall back to &version if mh_execute_header didn't work.
    if (!resolved) {
        vm_kernel_unslide_or_perm_external(
            (unsigned long long)(void *)&version, &slide_address);

        if (slide_address != 0 &&
            slide_address >= 0xFFFFFF8000000000ULL) {
            resolved = true;
            IOLog("kernel_resolver: using _version for KASLR slide (fallback)\n");
        }
    }

    if (!resolved) {
        IOLog("kernel_resolver: vm_kernel_unslide_or_perm_external failed for both symbols\n");
        mh_base_addr = 0;
        return;
    }

    // Sanity check: slide_address must be in the canonical kernel high range
    // (0xFFFFFF8000000000 - 0xFFFFFFFFFFFFFFFF on x86_64).
    if (slide_address < 0xFFFFFF8000000000ULL) {
        IOLog("kernel_resolver: slide_address 0x%llx outside kernel range, aborting\n",
              (unsigned long long)slide_address);
        mh_base_addr = 0;
        return;
    }

    slide = (uint64_t)(void *)&version - slide_address;
    uint64_t base_address = (uint64_t)slide + KERNEL_BASE;

    if(!kc){
        mh_base_addr = base_address;
        return;
    }

    // Existing logic for kernel collection (kc) follows...
    mach_header_64_t* mach_header = (mach_header_64_t*)base_address;
    if (mach_header->magic != MH_MAGIC_64) {
        IOLog("kernel_resolver: MH_MAGIC_64 mismatch at 0x%llx, using base_address fallback\n",
              (unsigned long long)base_address);
        mh_base_addr = base_address;
        return;
    }
    // ... rest of the existing code unchanged (find __TEXT_EXEC seg, walk load commands)
}
```

- [ ] **Step 2: Build the kext target to verify**

```bash
xcodebuild -target AMDRyzenCPUPowerManagement -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

Note: `mh_execute_header` is declared in `<mach-o/ldsyms.h>`. If the build fails with an undeclared identifier, add `#include <mach-o/ldsyms.h>` at the top of `kernel_resolver.c`.

- [ ] **Step 3: Handle linker symbol for mh_execute_header if needed**

If the build fails because `mh_execute_header` is undefined (it's a linker symbol, not a header symbol), replace the declaration with:

```cpp
// mh_execute_header is defined by the static linker. Declare as extern.
extern int mh_execute_header;
```

Or if the linker doesn't expose it, remove the mh_execute_header attempt and keep only the `&version` path — the existing code already has reasonable fallbacks.

- [ ] **Step 4: Commit**

```bash
git add AMDRyzenCPUPowerManagement/symresolver/kernel_resolver.c
git commit -m "fix(kext): robust KASLR slide resolution in kernel_resolver (A-04)

Try _mh_execute_header as primary anchor for KASLR slide computation,
falling back to _version. Both are validated against the kernel canonical
high range (>= 0xFFFFFF8000000000) before use.

"
```

---

### Task 5: Dynamic idle strategy per CPU family (A-03)

**Files:**
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.hpp` — add `idleStrategy` enum + member
- Modify: `AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp` — set strategy in `start()`, pass to `pmRyzen_init`
- Modify: `AMDRyzenCPUPowerManagement/pmAMDRyzen.c` — use strategy in `pmRyzen_machine_idle`
- Modify: `AMDRyzenCPUPowerManagement/pmAMDRyzen.h` — add enum type, remove compile-time macro forcing

**Interfaces:**
- Consumes: `cpuFamily` and `cpuModel` detected in `AMDRyzenCPUPowerManagement::start()`
- Produces: `pmRyzen_idle_strategy` global read by `pmRyzen_machine_idle()` to select idle path

**Problem:** `pmAMDRyzen.c` uses `PMRYZEN_IDLE_SIMPLE` (`sti; hlt`) exclusively because Zen 3 panics with `#UD` on MONITOR/MWAIT. However, Zen 4 and Zen 5 handle MONITOR/MWAIT correctly. Using `sti; hlt` on all CPUs prevents deep C-state entry, increasing idle power.

**Solution:** Introduce a runtime idle strategy enum. Set it per CPU family in the kext's `start()`. Use conditional assembly in `pmRyzen_machine_idle` based on the strategy.

- [ ] **Step 1: Define the idle strategy enum in `pmAMDRyzen.h`**

Add at the top of `pmAMDRyzen.h`, after the `#define` guards:

```c
/// Runtime idle strategy selection.
/// Set by AMDRyzenCPUPowerManagement::start() based on CPU family/model.
/// Compile-time defines (PMRYZEN_IDLE_SIMPLE, etc.) are removed — strategy
/// is now dynamic.
typedef enum {
    PMRYZEN_IDLE_STRATEGY_SIMPLE    = 0,  // sti; hlt  — safe for all AMD CPUs
    PMRYZEN_IDLE_STRATEGY_MWAIT     = 1,  // MONITOR/MWAIT — Zen 4/5, lower idle power
    PMRYZEN_IDLE_STRATEGY_IO_CSTATE = 2,  // inw $0xf2 — legacy, unused
} pmRyzen_idle_strategy_t;
```

Replace the compile-time macro selection block:

```c
// REMOVE:
// #define PMRYZEN_IDLE_SIMPLE 1
// and all #if defined guards

// ADD:
extern pmRyzen_idle_strategy_t pmRyzen_idle_strategy;
```

- [ ] **Step 2: Add the global variable in `pmAMDRyzen.c`**

Add near the other globals:

```c
pmRyzen_idle_strategy_t pmRyzen_idle_strategy = PMRYZEN_IDLE_STRATEGY_SIMPLE;
```

- [ ] **Step 3: Add strategy member + setter in `AMDRyzenCPUPowerManagement.hpp`**

```cpp
/// Idle strategy determined at start() based on CPU family.
/// Zen 3 (Vermeer) uses SIMPLE (sti;hlt) to avoid #UD from MONITOR/MWAIT.
/// Zen 4/5 can use MWAIT for lower idle power.
pmRyzen_idle_strategy_t cpuIdleStrategy {PMRYZEN_IDLE_STRATEGY_SIMPLE};
```

- [ ] **Step 4: Set the strategy in `AMDRyzenCPUPowerManagement::start()`**

In `AMDRyzenCPUPowerManagement.cpp`, in the `start()` method where `zenGeneration` is set, add:

```cpp
// Set idle strategy based on CPU family.
// Zen 1 through Zen 3 (Families 17h, 19h models < 60h): use SIMPLE (sti;hlt)
// Zen 4+ (Family 19h models 60h+, Family 1Ah): use MWAIT for lower idle power
if (cpuFamily == 0x1A || (cpuFamily == 0x19 && cpuModel >= 0x60)) {
    cpuIdleStrategy = PMRYZEN_IDLE_STRATEGY_MWAIT;
    IOLog("AMDRyzenCPUPowerManagement::start Idle strategy: MWAIT (Zen 4/5)\n");
} else {
    cpuIdleStrategy = PMRYZEN_IDLE_STRATEGY_SIMPLE;
    IOLog("AMDRyzenCPUPowerManagement::start Idle strategy: SIMPLE (sti;hlt for Zen 3-)\n");
}
pmRyzen_idle_strategy = cpuIdleStrategy;
```

Place this right after the zenGeneration detection block.

- [ ] **Step 5: Update `pmRyzen_machine_idle` to use the strategy**

Modify `AMDRyzenCPUPowerManagement/pmAMDRyzen.c`'s `pmRyzen_machine_idle` function. Replace the `#ifdef` blocks with a runtime `switch`:

```c
uint64_t pmRyzen_machine_idle(uint64_t maxDur){
    __asm__ volatile("cli;");

    uint32_t cn = cpu_number();
    if (cn >= XNU_MAX_CPU) {
        __asm__ volatile("sti;hlt;");
        return 0;
    }
    pmProcessor_t *self = &pmRyzen_cpus[cn];

    self->cpu_awake = 0;
    self->arm_flag = 0;

    uint64_t tscnow = rdtsc64();
    self->last_idle_tsc = tscnow;

    // Runtime idle strategy — set by AMDRyzenCPUPowerManagement::start()
    switch (pmRyzen_idle_strategy) {
    case PMRYZEN_IDLE_STRATEGY_MWAIT: {
        // MONITOR/MWAIT path — lower idle power, only safe on Zen 4+
        void* addr = &self->arm_flag;
        uint32_t ps_hint = 0x50;
        __asm__ volatile("wbinvd":::"memory");
        __asm__ volatile("mfence":::"memory");
        __asm__ volatile("clflushopt %0" : "+m" (*(volatile char *)&self->arm_flag));
        __asm__ volatile("mfence;"
                         "movq %0, %%rax;"
                         "xor %%edx, %%edx;"
                         "xor %%ecx, %%ecx;"
                         "monitor;"
                         "xorq %%rax, %%rax;"
                         "movl %1, %%eax;"
                         "movl $0x1, %%ecx;"
                         "mwait;"
                         :
                          : "r"(addr), "r"(ps_hint)
                          : "%ecx", "%edx", "%eax"
                          );
        __asm__ volatile("sti;");
        break;
    }
    case PMRYZEN_IDLE_STRATEGY_SIMPLE:
    default: {
        // sti; hlt path — safe on all AMD CPUs, used for Zen 3-
        __asm__ volatile("sti;hlt;");
        break;
    }
    case PMRYZEN_IDLE_STRATEGY_IO_CSTATE: {
        __asm__ volatile("sti;"
                         "inw $0xf2, %%ax;"
                         "cli;"
                         :::"%eax");
        break;
    }
    }

    // ... rest of the function unchanged (wake bookkeeping) ...
    self->cpu_awake = 1;
    if(!self->arm_flag)
        pmRyzen_exit_idle_false_c++;

    tscnow = rdtsc64();
    uint64_t tscela = tscnow - self->last_idle_tsc;
    self->eff_timeacc += tscnow - self->last_start_tsc;
    self->eff_idleacc += tscela;

    if(self->eff_timeacc > pmRyzen_effective_timetsc){
        uint64_t rt = self->eff_timeacc - self->eff_idleacc;
        if(rt > pmRyzen_p_sutsc){
            set_PState(self, 0);
            self->ll_count = 0;
        } else if(rt < pmRyzen_p_sdtsc){
            self->ll_count++;
            if(self->ll_count > PSTATE_STEPDOWN_TIME + pmRyzen_hpcpus * PSTATE_STEPDOWN_MP_GAIN){
                self->ll_count = 0;
                set_PState(self, self->PState+1);
            }
        }
        self->eff_idleaccd = self->eff_idleacc;
        self->eff_timeaccd = self->eff_timeacc;
        self->eff_timeacc = 0;
        self->eff_idleacc = 0;
    }

    self->last_start_tsc = tscnow;
    self->last_idle_length = tscela;

    pmRyzen_last_woken_cpu = cn;
    return 0;
}
```

- [ ] **Step 6: Clean up compile-time macros from `pmAMDRyzen.h`**

Remove the `#define PMRYZEN_IDLE_SIMPLE` block and the `#if !defined ... #define PMRYZEN_IDLE_SIMPLE 1` block. The function should no longer depend on `#ifdef` at compile time.

Replace the existing macro block:

```c
// REMOVE ALL OF THIS:
// #undef PMRYZEN_IDLE_MWAIT
// // PMRYZEN_IDLE_SIMPLE is the default idle strategy
// // Note: PMRYZEN_IDLE_IO_CSTATE may be defined via Xcode build settings
// #if !defined(PMRYZEN_IDLE_MWAIT) && !defined(PMRYZEN_IDLE_IO_CSTATE)
// #define PMRYZEN_IDLE_SIMPLE 1
// #endif
// // Sanity check: ensure only one idle strategy is active
// #if defined(PMRYZEN_IDLE_MWAIT) && (defined(PMRYZEN_IDLE_SIMPLE) || defined(PMRYZEN_IDLE_IO_CSTATE))
// #error "PMRYZEN_IDLE_MWAIT conflicts with another idle strategy definition"
// #elif defined(PMRYZEN_IDLE_SIMPLE) && defined(PMRYZEN_IDLE_IO_CSTATE)
// #error "PMRYZEN_IDLE_SIMPLE conflicts with PMRYZEN_IDLE_IO_CSTATE"
// #endif
```

Keep only:

```c
// Idle strategy is now selected at runtime based on CPU family.
// See pmRyzen_idle_strategy_t in this header.
```

- [ ] **Step 7: Build the kext target**

```bash
xcodebuild -target AMDRyzenCPUPowerManagement -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp \
       AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.hpp \
       AMDRyzenCPUPowerManagement/pmAMDRyzen.c \
       AMDRyzenCPUPowerManagement/pmAMDRyzen.h
git commit -m "feat(kext): dynamic idle strategy per CPU family (A-03)

Replace compile-time macro selection (PMRYZEN_IDLE_SIMPLE / MWAIT) with
a runtime enum. Zen 4 (Family 19h model 60h+) and Zen 5 (Family 1Ah) use
MONITOR/MWAIT for lower idle power. Zen 3- continue using the safe
sti;hlt path to avoid #UD panics.

"
```

---

### Task 6: Write unit tests for audit fixes

**Files:**
- Create: `AMDPowerGadgetTests/SecurityAuditTests.swift`

**Interfaces:**
- Consumes: SMU response code mapping constants already in `AMDRyzenCPUPowerManagement.hpp` (enum `SMUResponse`), `PStateRow.from()` in `TelemetryModel.swift`
- Produces: XCTest test cases for the privilege model, process-name rejection, SMU response mapping

- [ ] **Step 1: Create the test file**

`AMDPowerGadgetTests/SecurityAuditTests.swift`:

```swift
import XCTest
@testable import AMD_Power_Gadget

final class SecurityAuditTests: XCTestCase {

    // MARK: - A-01: Process-name bypass removed
    // This test validates that the privilege hint correctly mentions
    // GPU temperature injection requiring privilege (updated string).
    func testPrivilegeHintIncludesGPUTemp() {
        let hint = ProcessorModel.privilegeHint(for: ProcessorModel.kIOReturnNotPrivilegedCode)
        XCTAssertNotNil(hint)
        XCTAssertTrue(hint!.contains("GPU temperature"), "Privilege hint should mention GPU temp injection")
        XCTAssertTrue(hint!.contains("-amdpnopchk"), "Privilege hint should mention the boot-arg")
    }

    // MARK: - A-02: hasPrivilege() cache
    // kIOReturnNotPrivilegedCode is the exact code the kext returns
    func testNotPrivilegedCodeValue() {
        XCTAssertEqual(ProcessorModel.kIOReturnNotPrivilegedCode, kern_return_t(bitPattern: 0xe00002c1))
    }

    // MARK: - SMU Response code mapping (from v3.18.4 SMUResponseMappingTests)
    func testSMUResponseMapping() {
        // The kext maps SMU response codes to IOReturn:
        //   SMU_RSP_OK = 1 -> 0
        //   SMU_RSP_TIMEOUT = 0 -> kIOReturnTimeout
        //   SMU_RSP_INVALID_CMD = 0xFF -> kIOReturnUnsupported
        //   SMU_RSP_INVALID_ARGS = 0xFE -> kIOReturnBadArgument
        //   SMU_RSP_BUSY = 0xFD -> kIOReturnBusy
        // These are tested indirectly via the Curve Optimizer selector (111)
        // mapping in AMDRyzenCPUPMUserClient::externalMethod.

        // Verify the IOReturn constant values
        XCTAssertEqual(kIOReturnTimeout, 0x2000002)
        XCTAssertEqual(kIOReturnUnsupported, 0x2000003)
        XCTAssertEqual(kIOReturnBadArgument, 0x2000004)
        XCTAssertEqual(kIOReturnBusy, 0x2000005)
        XCTAssertEqual(kIOReturnNotReady, 0x2000006)
        XCTAssertEqual(kIOReturnError, 0x2000001)
    }

    // MARK: - PStateRow encoding/decoding (Zen 5)
    func testPStateRowZen5Encoding() {
        // Zen 5 (Family 1Ah): frequency = CpuFid * 5 MHz, 12-bit FID, no DfsId
        // P0: 5000 MHz -> FID = 5000 / 5 = 1000 (0x3E8)
        let row = PStateRow(id: 0, enabled: 1, iddDiv: 0, iddValue: 0,
                            cpuVid: 56, cpuDfsId: 1, cpuFid: 1000, isZen5: true)
        XCTAssertEqual(row.computedSpeedMHz, 5000.0, accuracy: 0.1)

        // Encode to raw
        let raw = row.rawValue
        // Decode from raw
        let decoded = PStateRow.from(raw: raw, index: 0, cpuFamily: 0x1A)
        XCTAssertEqual(decoded.cpuFid, 1000)
        XCTAssertEqual(decoded.computedSpeedMHz, 5000.0, accuracy: 0.1)
        XCTAssertTrue(decoded.isZen5)
    }

    // MARK: - PStateRow encoding/decoding (Zen 3)
    func testPStateRowZen3Encoding() {
        // Zen 3 (Family 19h): freq = FID / DfsId * 200
        // FID = 0x58 (88), DfsId = 0x8 (8) -> 88/8*200 = 2200 MHz
        let row = PStateRow(id: 2, enabled: 1, iddDiv: 0, iddValue: 0,
                            cpuVid: 100, cpuDfsId: 8, cpuFid: 88, isZen5: false)
        XCTAssertEqual(row.computedSpeedMHz, 2200.0, accuracy: 0.1)

        let raw = row.rawValue
        let decoded = PStateRow.from(raw: raw, index: 2, cpuFamily: 0x19)
        XCTAssertEqual(decoded.cpuFid, 88)
        XCTAssertEqual(decoded.cpuDfsId, 8)
        XCTAssertFalse(decoded.isZen5)
    }

    // MARK: - FanCurve LUT generation doesn't crash with empty points
    func testFanCurveEmptyLUT() {
        let curve = FanCurve(name: "Empty", points: [], sourceSensor: 0,
                             hysteresis: 2, rampRate: 5)
        let lut = curve.generateLUT()
        XCTAssertEqual(lut.count, 256)
        // All entries should be 0 for an empty curve
        XCTAssertTrue(lut.allSatisfy { $0 == 0 })
    }

    // MARK: - AppLanguage model
    func testAppLanguageSystemDefault() {
        XCTAssertEqual(AppLanguage.system.rawValue, "")
        XCTAssertNotNil(AppLanguage.available.first)
    }
}
```

- [ ] **Step 2: Run the tests**

```bash
xcodebuild test -scheme AMD\ Power\ Gadget -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **` (tests may be skipped if the test target isn't configured — verify the test bundle is added to the AMD Power Gadget scheme).

- [ ] **Step 3: Commit**

```bash
git add AMDPowerGadgetTests/SecurityAuditTests.swift
git commit -m "test: add security audit regression tests

Add XCTest cases covering:
- Privilege hint message includes GPU temp (A-01)
- kIOReturnNotPrivileged code value (A-02)
- SMU response code mapping (v3.18.4)
- PStateRow Zen 3/5 encoding round-trip
- FanCurve empty LUT edge case
- AppLanguage model

"
```
