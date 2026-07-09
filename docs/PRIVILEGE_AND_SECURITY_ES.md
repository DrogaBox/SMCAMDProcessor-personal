# Modelo de privilegios y seguridad (v3.16.1+)

Versión en inglés: [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md)

---

## Resumen

`AMDRyzenCPUPowerManagement.kext` expone un **UserClient** IOKit usado por AMD Power Gadget (y herramientas como `amdtelemetryd`).

La autorización **no** se basa en el nombre del proceso (se eliminó porque cualquier binario podía renombrarse para saltarse el control).

---

## Conexión vs privilegio

### 1. Abrir el UserClient (`initWithTask`)

| Cliente | Resultado |
|---------|-----------|
| Cualquier proceso (app de barra de menús sin root) | Conexión **permitida** (solo lectura por defecto) |
| Root **o** boot-arg `-amdpnopchk` | Conexión marcada como **privilegiada** |

El nombre del proceso se registra solo para auditoría (`IOLog`).

### 2. Privilegio por selector (`hasPrivilege`)

Los selectores de escritura llaman a `hasPrivilege()` y devuelven `kIOReturnNotPrivileged` si se deniega.

**Escrituras que requieren privilegio** (no exhaustivo):

| Selector | Acción |
|----------|--------|
| 10, 15 | Control P-State / definiciones raw |
| 12, 14, 19 | CPB / PPM / LPM |
| 24, 25 | CPPC activo / valor EPP |
| 95–97, 99 | Override de fans / restore / bulk / SuperIO raw |
| 101, 102 | LUT de curvas / mapa fan→curva |
| 111 | Curve Optimizer set |

**Lecturas** (telemetría, RPM, temp de paquete, paquete de sensores 100, CO get 110, etc.) **no** requieren root.

### 3. Caso especial: temperatura GPU (selector 103)

La app inyecta °C de GPU para que las curvas del kernel usen GPU como fuente **sin** root.

- **No** pasa por `hasPrivilege()` (diseño intencional).
- Valores **limitados a [0, 120] °C**.

---

## UX de privilegios en la app

Cuando falla una escritura privilegiada, AMD Power Gadget:

1. Detecta `kIOReturnNotPrivileged` (`0xe00002c1`).
2. Muestra un **banner naranja** en la parte superior del dashboard.
3. No finge que el control tuvo éxito (se recarga el estado desde el kext).

---

## Configuración recomendada (Hackintosh personal)

```text
boot-args: ... -amdcppcactive -amdpnopchk
```

- Telemetría con el usuario normal.
- Control total desde la barra de menús sin `sudo`.
- Aceptas el tradeoff de seguridad de `-amdpnopchk`.

> [!WARNING]
> Con `-amdpnopchk`, cualquier proceso local que abra el UserClient puede emitir escrituras privilegiadas. Solo en máquinas de confianza.

---

## Endurecimiento ya implementado

- Sin allowlist por nombre de proceso.
- I/O SuperIO multipaso protegido con `IOLock` (`superIOLock`).
- Guardia térmica de ventiladores (85 °C / 80 % PWM) **después** de histéresis/rampa.
- Selectores inválidos → `kIOReturnUnsupported`.
- `kunc_alert` del kext como máximo **una vez** por ciclo de alerta.
