# Guía de instalación — SMCAMDProcessor y AMD Power Gadget

Versión de referencia: **3.16.x**

---

## Componentes

| Artefacto | Destino | Función |
|-----------|---------|---------|
| `AMDRyzenCPUPowerManagement.kext` | `EFI/OC/Kexts/` | Driver MSR / SMU / SuperIO + UserClient |
| `SMCAMDProcessor.kext` | `EFI/OC/Kexts/` | Plugin VirtualSMC (claves de temp/potencia) |
| `AMD Power Gadget.app` | `/Applications/` | Dashboard SwiftUI + extra de barra de menús |
| `APGLaunchHelper.app` | Opcional | Ayuda de inicio de sesión |
| `amdtelemetryd` | LaunchAgent opcional | Telemetría JSONL en segundo plano |

Binarios de release: `Binaries_Release/vX.Y.Z/`. Builds locales: Xcode / `build_release/`.

---

## Requisitos previos

- macOS **13 Ventura** hasta **26 Tahoe**
- **OpenCore 0.7.1+** con parches **AMD Vanilla**
- **Lilu.kext** + **VirtualSMC.kext** (no FakeSMC)
- Quirk **`ProvideCurrentCpuInfo`** = `True`
- CPU AMD Zen soportada (Zen 1 … Zen 5) — ver [README.md](../README.md)

---

## 1. Instalar kexts (OpenCore)

1. Copia a `EFI/OC/Kexts/`:
   - `AMDRyzenCPUPowerManagement.kext`
   - `SMCAMDProcessor.kext`
2. En `config.plist` → **Kernel → Add**, en este **orden exacto**:

   | Orden | Bundle |
   |-------|--------|
   | 1 | `Lilu.kext` |
   | 2 | `VirtualSMC.kext` |
   | 3 | `AMDRyzenCPUPowerManagement.kext` |
   | 4 | `SMCAMDProcessor.kext` |

3. `Enabled` = true en cada entrada.

### boot-args recomendados

En **NVRAM → Add → `7C436110-AB2A-4BBB-A880-FE41995C9F82` → `boot-args`**, añade:

```text
-amdcppcactive -amdpnopchk
```

Incluye también `boot-args` en **NVRAM → Delete** del mismo GUID.

Detalle: [BOOT_ARGS_ES.md](BOOT_ARGS_ES.md) · [PRIVILEGE_AND_SECURITY_ES.md](PRIVILEGE_AND_SECURITY_ES.md)

> **Seguridad:** `-amdpnopchk` permite **escrituras** del UserClient sin root. Solo en máquinas personales de confianza.

---

## 2. Instalar la app

```bash
cp -R "AMD Power Gadget.app" /Applications/
xattr -cr "/Applications/AMD Power Gadget.app"
open "/Applications/AMD Power Gadget.app"
```

En el primer arranque acepta el **aviso de seguridad**.

### Idioma

**Temas y apariencia → Idioma** — Predeterminado del sistema o un locale empaquetado.  
Los cambios piden **Aplicar y reiniciar**. Ver [FEATURES_ES.md](FEATURES_ES.md).

---

## 3. Verificar tras reiniciar

```bash
kextstat | grep -iE 'AMDRyzen|SMCAMD'
nvram boot-args
```

En la app:

1. El dashboard debe mostrar frecuencia / potencia / temperaturas.
2. Con `-amdpnopchk`, ventiladores / EPP / CO **sin** banner naranja de privilegios.
3. Sin el flag: solo lectura fiable; las escrituras muestran el banner.

---

## 4. Compilar desde el código

```bash
open SMCAMDProcessor.xcodeproj
```

Scripts: `scripts/format.sh`, `scripts/check-format.sh`, `scripts/crowdin-*.sh`.

---

## 5. Desinstalar

1. Quita los kexts del EFI y las entradas **Kernel → Add**; reinicia.
2. Borra `/Applications/AMD Power Gadget.app`.
3. Opcional: limpia preferencias y LaunchAgents de `amdtelemetryd`.

---

## Documentación relacionada

- [BOOT_ARGS_ES.md](BOOT_ARGS_ES.md)
- [PRIVILEGE_AND_SECURITY_ES.md](PRIVILEGE_AND_SECURITY_ES.md)
- [TROUBLESHOOTING_ES.md](TROUBLESHOOTING_ES.md)
- Manual: `AMD_Power_Gadget_Manual_ES.md`
