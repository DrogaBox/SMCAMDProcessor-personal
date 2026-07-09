# Documentation index — SMCAMDProcessor / AMD Power Gadget

Complete documentation set for the **Tahoe Edition** (v3.16.x).  
Start here, then open the topic you need.

---

## By topic

| Document | EN | ES | Description |
|----------|----|----|-------------|
| Installation | [INSTALLATION.md](INSTALLATION.md) | [INSTALLATION_ES.md](INSTALLATION_ES.md) | OpenCore kexts, app install, verify, build, uninstall |
| Boot arguments | [BOOT_ARGS.md](BOOT_ARGS.md) | [BOOT_ARGS_ES.md](BOOT_ARGS_ES.md) | `-amdpnopchk`, `-amdcppcactive`, `-amdpdbg` |
| Privilege & security | [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md) | [PRIVILEGE_AND_SECURITY_ES.md](PRIVILEGE_AND_SECURITY_ES.md) | UserClient model, selector matrix, app banner |
| Features | [FEATURES.md](FEATURES.md) | [FEATURES_ES.md](FEATURES_ES.md) | Tabs, language, fans, CO, CPPC, safety |
| Troubleshooting | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | [TROUBLESHOOTING_ES.md](TROUBLESHOOTING_ES.md) | Kext not found, privilege banner, fans, i18n |
| Architecture | [ARCHITECTURE.md](ARCHITECTURE.md) | — | Kernel / UserClient / app stack diagram |
| i18n & Crowdin | [I18N_CROWDIN.md](I18N_CROWDIN.md) | — | Language picker, Crowdin mapping, scripts |

---

## Full user manuals (repo root)

| File | Language |
|------|----------|
| [../AMD_Power_Gadget_Manual.md](../AMD_Power_Gadget_Manual.md) | English |
| [../AMD_Power_Gadget_Manual_ES.md](../AMD_Power_Gadget_Manual_ES.md) | Español |
| PDF variants | Same base names with `.pdf` |

---

## Project-level docs (repo root)

| File | Description |
|------|-------------|
| [../README.md](../README.md) | Project overview, CPU support, install summary |
| [../CHANGELOG.md](../CHANGELOG.md) | Release history (include v3.16.x privilege & language) |
| [../COMPARISON.md](../COMPARISON.md) | vs original spinach project |

---

## Recommended reading order (new users)

1. **[INSTALLATION](INSTALLATION.md)** (or ES) — get kexts + app running  
2. **[BOOT_ARGS](BOOT_ARGS.md)** — add `-amdcppcactive -amdpnopchk` if you want full GUI control  
3. **[FEATURES](FEATURES.md)** / user manual — learn each tab  
4. **[TROUBLESHOOTING](TROUBLESHOOTING.md)** — if something fails  

Developers: [ARCHITECTURE.md](ARCHITECTURE.md) → [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md) → [I18N_CROWDIN.md](I18N_CROWDIN.md).

---

## Quick reference

```text
OpenCore kext order:
  Lilu → VirtualSMC → AMDRyzenCPUPowerManagement → SMCAMDProcessor

Recommended boot-args (personal machine):
  … -amdcppcactive -amdpnopchk

Language:
  Themes & Appearance → Language → Apply & Restart
```
