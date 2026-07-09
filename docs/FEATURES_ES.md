# Guía de funciones — AMD Power Gadget (Tahoe Edition)

Complemento de los manuals (`AMD_Power_Gadget_Manual_ES.md`).  
Referencia de versión: **3.16.x**.

Inglés: [FEATURES.md](FEATURES.md)

---

## Arquitectura (breve)

| Componente | Rol |
|------------|-----|
| `AMDRyzenCPUPowerManagement.kext` | MSR/SMU/SuperIO, IPC UserClient |
| `SMCAMDProcessor.kext` | Claves VirtualSMC |
| `AMD Power Gadget.app` | Dashboard SwiftUI + barra de menús |
| `APGLaunchHelper` | Ítem de inicio opcional |
| `amdtelemetryd` | Logging JSONL en segundo plano |

Orden OpenCore: **Lilu → VirtualSMC → AMDRyzenCPUPowerManagement → SMCAMDProcessor**.

---

## Pestañas del dashboard

| Pestaña | Contenido |
|---------|-----------|
| **Dashboard** | Gráficas freq/temp/potencia/red, rejilla de núcleos, HUD |
| **Telemetry** | Historial, CSV, logging continuo |
| **Fan Control** | SuperIO, ocultar fans, presets, curvas en kernel |
| **Themes & Appearance** | **Selector de idioma**, temas, estilos de gráfica |
| **Profiles** | EPP / CPPC, P-States, Curve Optimizer |
| **Advanced** | CPB/PPM/LPM, alertas, editor raw P-State |
| **Menu Bar / Popover / Widgets** | Apariencia de extras |
| **System Info** | CPU/placa/caché |
| **Analysis** | Picos máx/mín del periodo |

---

## Idioma (en la app)

**Ubicación:** Temas y apariencia → **Idioma**.

| Opción | Comportamiento |
|--------|----------------|
| **Predeterminado del sistema** | Sigue el idioma de macOS |
| **Idioma concreto** | Fuerza ese `.lproj` |

- Clave: `app_language_code` (vacío = sistema).
- Se aplica al arrancar vía `AppleLanguages`.
- Cambiar idioma pide **Aplicar y reiniciar** (no es en caliente).
- Todos los `*.lproj` empaquetados van en el bundle.

Crowdin: [I18N_CROWDIN.md](I18N_CROWDIN.md).

---

## Privilegios / controles

Ver [PRIVILEGE_AND_SECURITY_ES.md](PRIVILEGE_AND_SECURITY_ES.md) y [BOOT_ARGS_ES.md](BOOT_ARGS_ES.md).

**Consejo:** control total sin root → **`-amdpnopchk`** en OpenCore y reiniciar.

---

## Curve Optimizer

- Rango **[-30, +30]** por núcleo físico.
- UI con interruptor de seguridad + HUD opcional.
- Requiere privilegio (root o `-amdpnopchk`).
- SMU Zen 3+ típico para apply real.

---

## Ventiladores y curvas

- SuperIO: Nuvoton NCT668X / NCT67XX, ITE IT86XXE.
- Ocultar headers; etiquetas personalizadas.
- **Dynamic Next-Gen Fan Curves**: LUT 256, EMA, histéresis, rampa; suelo térmico **85 °C → ≥ 80 % PWM**.
- Temp GPU inyectada por la app (selector 103), clamp **[0, 120] °C**.
- Override PWM de ventilador **GPU** no disponible en macOS (SPPT / MPT).

---

## CPPC / EPP / energía

- Perfiles: Rendimiento / Equilibrado / Ahorro.
- Auto-EPP por carga y opcional AC/batería.
- Boot-arg **`-amdcppcactive`** recomendado.

---

## Seguridad

- Disclaimer al primer arranque.
- Ajustes incorrectos de CO / P-State / SuperIO pueden causar pánico o daño — responsabilidad del usuario.

---

## Extras para desarrolladores

| Ruta | Uso |
|------|-----|
| `scripts/format.sh` / `check-format.sh` | Formato |
| `scripts/crowdin-*.sh` | Crowdin local |
| `scratch/dump_sio.c` / `write_sio.c` | Diagnóstico SuperIO |
| `AMDPowerGadgetTests/` | Tests unitarios |
