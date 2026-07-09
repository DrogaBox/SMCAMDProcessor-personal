# OpenCore Boot Arguments — SMCAMDProcessor / AMD Power Gadget

These arguments are read by `AMDRyzenCPUPowerManagement.kext` at load time via `checkKernelArgument(...)`.  
Add them to OpenCore **`NVRAM → Add → 7C436110-AB2A-4BBB-A880-FE41995C9F82 → boot-args`**.

Ensure `boot-args` is also listed under **`NVRAM → Delete`** for the same GUID so OpenCore applies a fresh value each boot (does not leave a stale NVRAM string).

---

## Summary table

| Argument | Required? | Effect |
|----------|-----------|--------|
| **`-amdpnopchk`** | Optional (recommended for full GUI control without root) | Disables UserClient write privilege checks. Non-root apps (menu bar) can change fans, EPP, P-States, Curve Optimizer, SuperIO, etc. |
| **`-amdcppcactive`** | Optional | Enables **CPPC Active Mode** at boot so EPP / autonomous scaling is available to the OS and the app. |
| **`-amdpdbg`** | Optional (debug only) | Enables verbose Lilu/plugin debug logging for this project. |

Other boot-args you may already use (`agdpmod=pikera`, `alcid=…`, Lilu flags, etc.) are unrelated to this project and can coexist.

---

## `-amdpnopchk` — privilege bypass (admin / root equivalent for kext writes)

### What problem it solves

Since **v3.16.0 / v3.16.1** the kext uses this security model:

| Operation | Without `-amdpnopchk` | With `-amdpnopchk` |
|-----------|------------------------|---------------------|
| Open UserClient / read telemetry (temps, freq, power, fans RPM) | Any user | Any user |
| **Write** MSR / SMU / fans PWM / curves / Curve Optimizer / EPP / P-States | **Root only** | Any connected client |

The menu bar app normally runs as your login user (not root). Without this flag, **monitoring works** but **controls fail** and the dashboard shows a privilege banner.

### Example `boot-args` fragment

```text
…existing args… -amdcppcactive -amdpnopchk
```

### Security warning

> [!WARNING]
> `-amdpnopchk` is a **deliberate security downgrade**. Any local process that can open the UserClient can issue privileged writes (voltage/frequency/fan).  
> Use only on a **trusted personal machine**. Do not enable on multi-user or untrusted environments.

### Alternatives without the flag

1. Run AMD Power Gadget as root (not practical for a menu bar extra), or  
2. Accept read-only monitoring and leave controls to BIOS.

---

## `-amdcppcactive` — CPPC Active Mode at boot

Enables Collaborative Processor Performance Control so the SMU/OS can honor EPP profiles (Performance / Balanced / Power Save) from the app.

Without it, CPPC-related UI may report unsupported or inactive depending on firmware and CPU.

---

## `-amdpdbg` — debug logging

Turns on project debug logging (Lilu `debugEnabled` path). Use only when diagnosing panics or missing sensors; increases log noise.

---

## Verification after reboot

```bash
# Kext loaded?
kextstat | grep -i AMDRyzen

# Boot-args currently active (from NVRAM)
nvram boot-args

# Should include -amdpnopchk if configured
```

In the app:

1. Open **Profiles** or **Fan Control**.  
2. Change EPP or a fan override.  
3. You should **not** see the orange privilege banner if `-amdpnopchk` is active.

---

## Related documentation

- [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md) — full UserClient model  
- [FEATURES.md](FEATURES.md) — app features (language, curves, CO, …)  
- User manuals: `AMD_Power_Gadget_Manual.md` / `_ES.md`
