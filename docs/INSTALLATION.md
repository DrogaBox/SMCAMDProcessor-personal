# Installation Guide — SMCAMDProcessor & AMD Power Gadget

Version reference: **3.16.x**

---

## Components

| Artifact | Destination | Purpose |
|----------|-------------|---------|
| `AMDRyzenCPUPowerManagement.kext` | `EFI/OC/Kexts/` | Core MSR / SMU / SuperIO driver + UserClient |
| `SMCAMDProcessor.kext` | `EFI/OC/Kexts/` | VirtualSMC plugin (temps/power keys for iStat, etc.) |
| `AMD Power Gadget.app` | `/Applications/` | SwiftUI dashboard + menu bar extra |
| `APGLaunchHelper.app` | Optional (bundle helper) | Login item helper |
| `amdtelemetryd` | Optional LaunchAgent | Background JSONL telemetry when GUI is closed |

Release binaries (when packaged) live under `Binaries_Release/vX.Y.Z/`. Local debug/release builds use Xcode / `build_release/`.

---

## Prerequisites

- macOS **13 Ventura** through **26 Tahoe**
- **OpenCore 0.7.1+** with **AMD Vanilla** kernel patches
- **Lilu.kext** + **VirtualSMC.kext** (no FakeSMC)
- Quirk **`ProvideCurrentCpuInfo`** = `True` (Kernel → Quirks)
- Supported AMD Zen CPU (Zen 1 … Zen 5) — see root [README.md](../README.md)

---

## 1. Install kexts (OpenCore)

1. Copy into `EFI/OC/Kexts/`:
   - `AMDRyzenCPUPowerManagement.kext`
   - `SMCAMDProcessor.kext`
2. In `config.plist` → **Kernel → Add**, inject in this **exact order**:

   | Order | Bundle |
   |-------|--------|
   | 1 | `Lilu.kext` |
   | 2 | `VirtualSMC.kext` |
   | 3 | `AMDRyzenCPUPowerManagement.kext` |
   | 4 | `SMCAMDProcessor.kext` |

3. Enable each entry (`Enabled` = true). Match `MinKernel` / `MaxKernel` only if you intentionally gate versions.

### Recommended boot-args

Under **NVRAM → Add → `7C436110-AB2A-4BBB-A880-FE41995C9F82` → `boot-args`**, append:

```text
-amdcppcactive -amdpnopchk
```

Also list `boot-args` under **NVRAM → Delete** for the same GUID so OpenCore refreshes NVRAM each boot.

Full detail: [BOOT_ARGS.md](BOOT_ARGS.md) · [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md)

> **Security:** `-amdpnopchk` allows non-root UserClient **writes**. Use on personal trusted machines only.

---

## 2. Install the app

```bash
# From a release folder or build products:
cp -R "AMD Power Gadget.app" /Applications/
xattr -cr "/Applications/AMD Power Gadget.app"   # clear quarantine if needed
open "/Applications/AMD Power Gadget.app"
```

On first launch accept the **safety disclaimer** (`disclaimer_accepted` preference).

### Language

**Themes & Appearance → Language** — System Default or a bundled locale (`en`, `es`, `de`, `it`, …).  
Change applies after **Apply & Restart**. See [FEATURES.md](FEATURES.md) and [I18N_CROWDIN.md](I18N_CROWDIN.md).

---

## 3. Verify after reboot

```bash
# Drivers present
kextstat | grep -iE 'AMDRyzen|SMCAMD'

# Boot args
nvram boot-args

# Optional: IORegistry
ioreg -l | grep -i AMDRyzen | head
```

In the app:

1. Dashboard should show frequency / power / temps (no “kext not found”).
2. With `-amdpnopchk`, Fan Control / EPP / CO should work **without** the orange privilege banner.
3. Without the flag, monitoring works; privileged writes show the banner.

---

## 4. Optional: background telemetry daemon

`Tools/amdtelemetryd` can be installed as a LaunchAgent to append JSONL history when the GUI is closed. The daemon skips logging if the main app is already running (avoids write conflicts).

Prefer the GUI **Telemetry** tab for interactive export/CSV unless you need headless collection.

---

## 5. Building from source

```bash
# Xcode (GUI targets + kexts)
open SMCAMDProcessor.xcodeproj

# Or xcodebuild (example)
xcodebuild -project SMCAMDProcessor.xcodeproj \
  -scheme "AMD Power Gadget" \
  -configuration Release \
  -derivedDataPath build_release
```

Kext development requires a properly signed/SIP-aware Hackintosh workflow (OpenCore injects unsigned kexts). Do not expect SIP-enabled Apple Silicon Macs to load these kexts.

Helpers:

| Script | Purpose |
|--------|---------|
| `scripts/format.sh` | Format C++/Swift |
| `scripts/check-format.sh` | Dry-run format check |
| `scripts/crowdin-*.sh` | Crowdin CLI (needs `.crowdin-credentials`) |

Unit tests: target `AMDPowerGadgetTests` (EPP mapping, colors, format helpers).

---

## 6. Uninstall

1. Remove kexts from `EFI/OC/Kexts` and corresponding **Kernel → Add** entries; reboot.
2. Delete `/Applications/AMD Power Gadget.app`.
3. Optional prefs: `defaults delete wtf.spinach.AMD-Power-Gadget` (bundle id may vary by build — check `Info.plist`).
4. Remove any LaunchAgent for `amdtelemetryd` if installed.

---

## Related docs

- [BOOT_ARGS.md](BOOT_ARGS.md) / [BOOT_ARGS_ES.md](BOOT_ARGS_ES.md)
- [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- User manuals: `AMD_Power_Gadget_Manual.md` / `_ES.md`
