# Solución de problemas — SMCAMDProcessor / AMD Power Gadget

Versión de referencia: **3.16.x**

---

## Árbol rápido

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| **“No AMDRyzenCPUPowerManagement Found!”** | Kext no cargado o versiones desalineadas | `kextstat`; orden OC; reinstalar kexts pareados |
| Controles fallan + **banner naranja** | Usuario normal sin `-amdpnopchk` | Añadir boot-arg o modo solo lectura — [BOOT_ARGS_ES.md](BOOT_ARGS_ES.md) |
| Telemetría OK, ventiladores no cambian | Mismo modelo de privilegios | Igual |
| RPM incorrectas / fantasma | SuperIO | Ocultar fan; kext actualizado |
| EPP / CPPC inactivo | Falta `-amdcppcactive` | Añadir y reiniciar |
| Idioma no cambia | No se reinició la app | **Aplicar y reiniciar** |
| Spam de alertas del kext | Corregido en 3.16.2 | Actualizar |

---

## 1. Diálogo “kext not found”

```bash
kextstat | grep -i AMDRyzen
```

Si no aparece: EFI, orden Lilu → VirtualSMC → AMDRyzen → SMCAMD, o fallo de Lilu.

Desde **v3.16.1**, un cliente **sin root** debe poder abrir el UserClient en lectura. Un kext viejo que rechazaba `initWithTask` muestra un **falso** “kext not found”.

**Solución:** actualizar kext **y** app a **≥ 3.16.1**.

---

## 2. Banner de privilegios

Mensaje típico: se requiere administrador, o el boot-arg **`-amdpnopchk`**.

| Modo | Lecturas | Escrituras |
|------|----------|------------|
| Usuario normal, sin flag | Sí | No |
| Root | Sí | Sí |
| Cualquiera + **`-amdpnopchk`** | Sí | Sí |

```bash
nvram boot-args
```

OpenCore debe **Delete** + **Add** de `boot-args` o NVRAM puede quedar obsoleta.

Más detalle: [PRIVILEGE_AND_SECURITY_ES.md](PRIVILEGE_AND_SECURITY_ES.md)

---

## 3. Ventiladores

- Ocultar headers fantasma en la pestaña Fan Control.
- ITE a 0 RPM: kext con modo tacómetro 16-bit.
- NCT668X: 3.16.2 usa `IODelay` bajo el lock SuperIO.
- GPU como fuente de curva: la app inyecta °C (selector 103).
- PWM de GPU AMD en macOS: **no soportado** (usar SPPT).

---

## 4. Curve Optimizer / P-State

Requiere privilegios. Soporte SMU depende de la familia. Valores agresivos = riesgo de pánico o apagado.

---

## 5. Logs útiles

```bash
log show --last 10m --predicate 'eventMessage CONTAINS[c] "AMDRyzen"' --style compact
kextstat -l | grep -iE 'Lilu|VirtualSMC|AMDRyzen|SMCAMD'
nvram boot-args
```

Flag de depuración: **`-amdpdbg`** (solo diagnóstico).

---

## Relacionado

- [INSTALLATION_ES.md](INSTALLATION_ES.md)
- [BOOT_ARGS_ES.md](BOOT_ARGS_ES.md)
- [FEATURES_ES.md](FEATURES_ES.md)
- Manual: `AMD_Power_Gadget_Manual_ES.md`
