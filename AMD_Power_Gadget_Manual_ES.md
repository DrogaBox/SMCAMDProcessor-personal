<div class="cover-page">
    <span class="cover-title">AMD Power Gadget</span>
    <span class="cover-subtitle">Manual de Usuario y Guía Completa</span>
    <br><br>
    <span style="color: var(--accent-cyan);">Versión 3.31.0 (Tahoe Edition)</span>
</div>

## Introducción

Bienvenido a **AMD Power Gadget** y **SMCAMDProcessor**. Esta suite ofrece telemetría y gestión de energía para procesadores AMD Ryzen en macOS (Hackintosh).

Este manual describe las opciones de la aplicación. Para detalle técnico (privilegios del UserClient, arquitectura, Crowdin), consulta la carpeta **[docs/](docs/README.md)** (índice bilingüe).

---

## 1. Requisitos del sistema y OpenCore

### 1.1 Kexts esenciales
En `EFI/OC/Kexts` e inyectados en `Kernel → Add`, en este **orden exacto**:
1. `Lilu.kext` (primero)
2. `VirtualSMC.kext` (no use FakeSMC)
3. `AMDRyzenCPUPowerManagement.kext` (CPU, SuperIO, UserClient)
4. `SMCAMDProcessor.kext` (claves VirtualSMC para iStat Menus, etc.)

### 1.2 Quirks y boot-args generales
- **ProvideCurrentCpuInfo** = `True`.
- **agdpmod=pikera**: RX 6000 (Navi) — no es de este proyecto.

### 1.3 Boot-args del proyecto

En **NVRAM → Add → `7C436110-AB2A-4BBB-A880-FE41995C9F82` → boot-args**. Incluya `boot-args` también en **NVRAM → Delete** del mismo GUID.

| Argumento | Función |
|-----------|---------|
| **`-amdpnopchk`** | Desactiva chequeos de **escritura** del UserClient. La app en barra de menús (sin root) puede cambiar ventiladores, EPP, P-States, Curve Optimizer, SuperIO. **Recomendado en PCs personales de confianza** para control total. |
| **`-amdcppcactive`** | Activa CPPC Active Mode al arrancar (perfiles EPP). |
| **`-amdpdbg`** | Logs de depuración del kext (solo diagnóstico). |

**Modelo de privilegios (v3.16.1+):**
- **Cualquier usuario** puede **leer** telemetría.
- Las **escrituras** requieren **root** o **`-amdpnopchk`**.
- Sin el flag: monitorización OK; los controles fallan y aparece el **banner naranja**.

Docs: [docs/BOOT_ARGS_ES.md](docs/BOOT_ARGS_ES.md) · [docs/PRIVILEGE_AND_SECURITY_ES.md](docs/PRIVILEGE_AND_SECURITY_ES.md)

> [!WARNING]
> `-amdpnopchk` reduce la seguridad: cualquier proceso local que abra el UserClient puede escribir en hardware sensible. Solo en máquinas de confianza.

### 1.4 Instalar la aplicación
Copie `AMD Power Gadget.app` a `/Applications`. Si hace falta: `xattr -cr "/Applications/AMD Power Gadget.app"`. En el primer arranque acepte el **aviso de seguridad**.

---

## 2. Banner de privilegios

Si intenta controlar ventiladores, EPP, Curve Optimizer u otras escrituras sin root y sin `-amdpnopchk`, aparece un banner naranja indicando que se requieren privilegios de administrador o el boot-arg.

**Solución:** añada `-amdpnopchk` en OpenCore y reinicie (preferido), o ejecute la app como root (poco práctico para un extra de barra de menús).

---

## 3. Pestaña Dashboard (Energía y frecuencias)

### 3.1 Métricas y Silicon Quality
- **Frecuencias de núcleo** en tiempo real.
- **Silicon Quality (1. ~ X.)**: ranking CPPC en Zen 3/4; el núcleo `1.` es el mejor para estrategia de Curve Optimizer.
- **PPT** y **Tctl / Tdie**.
- **HUD**: mostrar/ocultar freq, carga y temp CCD por núcleo.

### 3.2 Gráficas
Frecuencia, temperatura, potencia y red, con promedio / máx / mín. Intervalo de actualización configurable.

**v3.31.0+ — Menú contextual:** Cada gráfica tiene un menú contextual nativo (Size, Hide, Show, Move Position) que ya no parpadea con las actualizaciones de telemetría. El submenú Size está deshabilitado en el Core Grid (tamaño fijo).

**v3.31.0+ — Badge de perfil CPU:** Debajo de las tarjetas de estadísticas, un badge compacto muestra el perfil activo (ej. "Telemetry-only — Zen 3 Vermeer") con chips de capacidades (ej. "CPPC", "PM Dispatch", "Legacy P-States").

---

## 4. Pestaña Perfiles

### 4.1 Perfiles EPP
- **Ahorro de energía**, **Equilibrado**, **Rendimiento**.
- Preferible **`-amdcppcactive`** al arrancar. Auto-EPP por carga / AC-batería cuando esté disponible.

### 4.2 P-States legacy
- Bloqueo a un P-State.
- Editor raw FID/VID/DID (**privilegiado**; VID incorrecto puede apagar o dañar el silicio).

---

## 5. Curve Optimizer

- Offsets **[-30, +30]** por núcleo físico.
- Offset negativo = menos voltaje a una frecuencia (a menudo más boost sostenido si es estable).
- Interruptor de seguridad en la UI; requiere privilegios y SMU (típico Zen 3+).

> [!CAUTION]
> Ajustes agresivos pueden causar pánicos o estrés de hardware. El riesgo es del usuario.

---

## 6. Control de ventiladores

SuperIO: Nuvoton NCT668X/NCT67XX, ITE IT86XXE (incl. NCT6799D, NCT6701D, IT8686E, IT8689E, …).

### 6.1 Monitoreo y ocultación
Lista RPM/PWM, ocultar fans fantasma, etiquetas personalizadas.

### 6.2 Presets
**Todo automático** (BIOS) y **velocidad máxima** (100 % PWM).

### 6.3 Dynamic Next-Gen Fan Curves
Curvas evaluadas en el **kernel**: LUT 256, EMA, histéresis, rampa; suelo **85 °C → ≥ 80 % PWM**. Fuente CPU o GPU (la app inyecta °C GPU, clamp 0–120).

### 6.4 Ventilador de GPU
No hay override PWM de GPU AMD en macOS. Use **MorePowerTool** + SPPT en OpenCore.

---

## 7. Temas y apariencia (incluido idioma)

### 7.1 Idioma
- **Predeterminado del sistema** o un idioma empaquetado (Español, English, Deutsch, Italiano, …).
- Se aplica al arrancar; tras cambiar, **Aplicar y reiniciar** (no es cambio en caliente).

Ver [docs/I18N_CROWDIN.md](docs/I18N_CROWDIN.md) y [docs/FEATURES_ES.md](docs/FEATURES_ES.md).

### 7.2 Temas visuales
Oscuro / claro / sistema, temas personalizados y estilos de gráfica.

---

## 8. Telemetría, análisis y avanzado

- **Telemetry**: historial, CSV, logging; daemon opcional `amdtelemetryd`.
- **Analysis**: máx/mín de la sesión.
- **Advanced**: CPB/PPM/LPM, alertas, diagnósticos (escrituras privilegiadas).
- **Menu Bar / widgets**: qué sensores mostrar e intervalo de actualización.

---

## 9. Menu Bar Extra

Incluir CPU/GPU/ventiladores, picos de sesión, intervalo de sondeo.

---

## 10. System Info

Marca de CPU, placa cuando esté disponible, topología de caché, estado del driver.

**v3.31.0+ — Perfil CPU:** Muestra el nombre del perfil activo (ej. "Zen 3 Vermeer"), el modo de operación ("Telemetry-only" vs "Full PM Dispatch") y las capacidades soportadas (CPPC, Legacy P-States, PM Dispatch). Datos obtenidos del kext mediante el selector IOKit 26.

---

## 11. Aviso de seguridad

Modal al primer arranque. Ajustes incorrectos de MSR/SMU/SuperIO pueden causar inestabilidad, pérdida de datos, pánicos o daño. **Use bajo su propia responsabilidad.**

---

## 12. Solución de problemas (resumen)

| Problema | Acción |
|----------|--------|
| “No AMDRyzenCPUPowerManagement Found!” | `kextstat`; orden OC; kext+app ≥ 3.16.1 |
| Banner naranja de privilegios | `-amdpnopchk` o solo lectura |
| Idioma no cambia | Aplicar y reiniciar |
| RPM incorrectas | Actualizar kext; ocultar fans fantasma |

Guía completa: [docs/TROUBLESHOOTING_ES.md](docs/TROUBLESHOOTING_ES.md)

---

## 13. Más documentación

| Doc | Contenido |
|-----|-----------|
| [docs/README.md](docs/README.md) | Índice |
| [docs/INSTALLATION_ES.md](docs/INSTALLATION_ES.md) | Instalación |
| [docs/BOOT_ARGS_ES.md](docs/BOOT_ARGS_ES.md) | Boot-args |
| [CHANGELOG.md](CHANGELOG.md) | Historial de versiones |

---

## 14. Utilidad de volcado (avanzado)

Para registros SuperIO mal mapeados, use las utilidades en `scratch/` (`dump_sio` / `write_sio`) o scripts de placa si existen. Prefiera kexts de release actual antes de parchear registros a mano.
