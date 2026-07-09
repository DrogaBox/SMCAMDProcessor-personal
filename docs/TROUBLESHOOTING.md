# Troubleshooting — SMCAMDProcessor / AMD Power Gadget

Version reference: **3.16.x**

---

## Quick decision tree

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| **“No AMDRyzenCPUPowerManagement Found!”** | Kext not loaded **or** app/kext version mismatch | `kextstat`; check OC order; reinstall matching kexts |
| App opens but **all controls fail** + orange banner | Non-root + no `-amdpnopchk` | Add boot-arg or accept read-only mode — [BOOT_ARGS.md](BOOT_ARGS.md) |
| Telemetry OK, fans don’t change | Same privilege model | As above |
| Fans stuck / wrong RPM | SuperIO family/regs | Check chip family; NCT/ITE support list in [FEATURES.md](FEATURES.md) |
| CPPC / EPP inactive | Missing `-amdcppcactive` or firmware | Add boot-arg; reboot |
| Black screen (Navi GPU) | Unrelated OC arg | `agdpmod=pikera` (GPU, not this project) |
| Language doesn’t change | Did not restart | **Apply & Restart** after language pick |
| Modal “kext load” spam | Fixed in 3.16.2 | Update kext/app so `kunc_alert` fires once |

---

## 1. “Kext not found” dialog

### Confirm the driver is loaded

```bash
kextstat | grep -i AMDRyzen
kextstat | grep -i SMCAMD
```

If empty:

1. Kexts missing from `EFI/OC/Kexts`.
2. Wrong **Kernel → Add** order (must be Lilu → VirtualSMC → AMDRyzen → SMCAMD).
3. Failed Lilu/VirtualSMC load (check OpenCore log / `log show`).
4. Wrong architecture / MinKernel filter.

### Confirm UserClient opens (v3.16.1+)

Since **v3.16.1**, non-root clients **must** be able to open the UserClient for reads. If an older kext still rejects non-root `initWithTask`, you get a **false** “kext not found” even though `kextstat` shows the driver.

**Fix:** update both kext **and** app to **≥ 3.16.1**.

```bash
# App version
defaults read "/Applications/AMD Power Gadget.app/Contents/Info" CFBundleShortVersionString
```

---

## 2. Privilege banner / controls don’t stick

Orange banner text (EN):

> This action requires administrator privileges. Run AMD Power Gadget as root, or add the boot argument `-amdpnopchk` for debugging.

| Mode | Reads | Writes (fans, EPP, CO, P-State, …) |
|------|-------|-------------------------------------|
| Normal user, no boot-arg | Yes | No (`kIOReturnNotPrivileged`) |
| Root process | Yes | Yes |
| Any user + **`-amdpnopchk`** | Yes | Yes |

```bash
nvram boot-args   # must include -amdpnopchk after reboot
```

Remember: OpenCore must **Delete** then **Add** `boot-args` or NVRAM may stay stale.

Deep dive: [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md)

---

## 3. Fan control issues

| Issue | Notes |
|-------|-------|
| Ghost headers / 40 RPM disconnected | Use **Hide fan** in Fan Control |
| 0 RPM on ITE | Needs 16-bit tach mode (IT86XXE driver writes reg `0x0C`) — use current kext |
| NCT668X latency / freezes under load | 3.16.2 uses `IODelay` under `superIOLock` instead of long `IOSleep` |
| Curves ignore GPU | App injects GPU °C via selector **103** (clamped 0–120); ensure app is running |
| GPU fan curve | **Not supported** on macOS AMD GPUs — use SPPT / MorePowerTool |

---

## 4. Curve Optimizer / P-State

- Requires privilege (root or `-amdpnopchk`).
- SMU support varies by family (Zen 3+ typical for CO mailbox).
- Wrong VID / aggressive negative CO can panic or shut down — user risk.
- Safety UI lock must be unlocked in Profiles / CO section.

---

## 5. Localization

| Issue | Fix |
|-------|-----|
| Still English after picking Spanish | Restart app via **Apply & Restart** |
| Language missing from list | Locale not in bundle; rebuild with all `*.lproj` (3.16.2 packages all knownRegions) |
| Crowdin export overwrites local edits | Pull carefully; source of truth is `en.lproj` |

See [I18N_CROWDIN.md](I18N_CROWDIN.md).

---

## 6. Logs useful for reports

```bash
# Kernel / Lilu style logs (may need sudo / full disk)
log show --last 10m --predicate 'eventMessage CONTAINS[c] "AMDRyzen"' --style compact

# Loaded kext versions
kextstat -l | grep -iE 'Lilu|VirtualSMC|AMDRyzen|SMCAMD'

# Active boot-args
nvram boot-args
```

With **`-amdpdbg`** the kext emits more verbose `IOLog` (debug only).

---

## 7. Known intentional behaviors

- **No process-name allowlist** for security (cannot spoof app name to gain writes).
- **Selector 103** (GPU temp) is intentionally unprivileged but value-clamped.
- **Disclaimer modal** only until `disclaimer_accepted`.
- **amdtelemetryd** exits/skips when GUI is open to avoid JSONL races.

---

## Related

- [INSTALLATION.md](INSTALLATION.md)
- [BOOT_ARGS.md](BOOT_ARGS.md)
- [FEATURES.md](FEATURES.md)
- [CHANGELOG.md](../CHANGELOG.md)
