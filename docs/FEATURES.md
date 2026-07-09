# Feature Guide — AMD Power Gadget (Tahoe Edition)

Companion to the full manuals (`AMD_Power_Gadget_Manual.md` / `_ES.md`).  
Version reference: **3.16.x** line.

---

## Architecture (short)

| Component | Role |
|-----------|------|
| `AMDRyzenCPUPowerManagement.kext` | MSR/SMU/SuperIO, UserClient IPC |
| `SMCAMDProcessor.kext` | VirtualSMC keys (temps/power for other apps) |
| `AMD Power Gadget.app` | SwiftUI dashboard + menu bar extra |
| `APGLaunchHelper` | Optional login item |
| `amdtelemetryd` | Optional background JSONL logging when GUI is closed |

OpenCore load order: **Lilu → VirtualSMC → AMDRyzenCPUPowerManagement → SMCAMDProcessor**.

---

## Dashboard tabs

| Tab | Contents |
|-----|----------|
| **Dashboard** | Frequency / temperature / power / network charts, core grid, HUD toggles |
| **Telemetry** | Configurable history charts, CSV export, continuous logging |
| **Fan Control** | SuperIO fans, hide fans, quick presets, custom kernel curves |
| **Themes & Appearance** | **Language picker**, visual themes, custom theme JSON, chart styles |
| **Profiles** | EPP / CPPC, legacy P-State profiles, Curve Optimizer |
| **Advanced** | CPB/PPM/LPM, alerts, raw P-State editor |
| **Menu Bar / Popover / Desktop Widgets** | Appearance and layout of extras |
| **System Info** | CPU/board/cache info |
| **Analysis** | Historical peaks min/max over timeframe |

---

## Language (in-app)

**Location:** Themes & Appearance → **Language / App Language**.

| Option | Behavior |
|--------|----------|
| **System Default** | Follow macOS preferred language |
| **Specific language** | Force that `.lproj` (en, es, de, it, fr, …) |

- Preference key: `app_language_code` (empty = system).  
- Applied at launch via `AppleLanguages`.  
- Changing language asks for **Apply & Restart** (full UI reload; no live switch).  
- All bundled `*.lproj` folders are packaged in the app (see Xcode `knownRegions`).

Crowdin source of truth: `AMD Power Gadget/en.lproj/Localizable.strings`.  
Sync: `.github/workflows/crowdin.yml` + local scripts under `scripts/crowdin-*.sh`.

---

## Privilege / controls

See [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md) and [BOOT_ARGS.md](BOOT_ARGS.md).

**Quick tip:** for full control without root, add **`-amdpnopchk`** to OpenCore `boot-args` and reboot.

---

## Curve Optimizer

- Range **[-30, +30]** per physical core (SMU mailbox).  
- UI locked behind safety switch + optional HUD (freq/load/CCD).  
- Requires privilege (root or `-amdpnopchk`).  
- Zen 3+ SMU support required for actual hardware apply.

---

## Fan control & custom curves

- SuperIO families: Nuvoton NCT668X / NCT67XX, ITE IT86XXE.  
- Hide/show individual headers; custom labels.  
- **Dynamic Next-Gen Fan Curves**: kernel LUT 256 steps, EMA, hysteresis, ramp; thermal floor **85 °C → ≥ 80 % PWM**.  
- GPU temp for curves is injected by the app (selector 103), clamped **[0, 120] °C**.  
- GPU fan PWM override is **not** available under macOS (use SPPT / MorePowerTool).

---

## CPPC / EPP / power

- Profiles: Performance / Balanced / Power Save (EPP hints).  
- Auto-EPP by load and optional AC/battery switching.  
- Boot flag **`-amdcppcactive`** recommended for Active Mode at boot.

---

## Safety

- First-launch disclaimer modal (`disclaimer_accepted`).  
- Footer / CAUTION in README and manuals.  
- Incorrect Curve Optimizer / raw P-State / SuperIO writes can panic or damage hardware — user responsibility.

---

## Developer extras

| Path | Purpose |
|------|---------|
| `scripts/format.sh` / `check-format.sh` | clang-format / swift-format helpers |
| `scripts/crowdin-*.sh` | Local Crowdin upload/status (needs `.crowdin-credentials`) |
| `scratch/dump_sio.c` / `write_sio.c` | SuperIO diagnostics |
| `AMDPowerGadgetTests/` | Small unit tests (EPP mapping, colors, …) |

---

## Related documentation

- [INSTALLATION.md](INSTALLATION.md) · [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- [ARCHITECTURE.md](ARCHITECTURE.md) · [I18N_CROWDIN.md](I18N_CROWDIN.md)
- Spanish: [FEATURES_ES.md](FEATURES_ES.md)
- User manuals: `AMD_Power_Gadget_Manual.md` / `_ES.md`
