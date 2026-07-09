# Argumentos de arranque OpenCore — SMCAMDProcessor / AMD Power Gadget

El kext `AMDRyzenCPUPowerManagement` lee estos flags al cargar (`checkKernelArgument`).  
Añádelos en OpenCore: **`NVRAM → Add → 7C436110-AB2A-4BBB-A880-FE41995C9F82 → boot-args`**.

Incluye también `boot-args` en **`NVRAM → Delete`** del mismo GUID para que OpenCore aplique el valor nuevo en cada boot.

---

## Tabla resumen

| Argumento | ¿Obligatorio? | Efecto |
|-----------|---------------|--------|
| **`-amdpnopchk`** | Opcional (recomendado para control total de la app sin root) | Desactiva el chequeo de privilegios de escritura del UserClient. La app en la barra de menús puede cambiar ventiladores, EPP, P-States, Curve Optimizer, SuperIO, etc. |
| **`-amdcppcactive`** | Opcional | Activa **CPPC Active Mode** al arrancar (EPP / escalado autónomo). |
| **`-amdpdbg`** | Opcional (solo depuración) | Logs de depuración verbosos del proyecto. |

Otros boot-args (`agdpmod=pikera`, `alcid=…`, Lilu, etc.) pueden convivir sin problema.

---

## `-amdpnopchk` — bypass de privilegios

### Qué resuelve

Desde **v3.16.1**:

| Operación | Sin `-amdpnopchk` | Con `-amdpnopchk` |
|-----------|-------------------|-------------------|
| Abrir UserClient / leer telemetría | Cualquier usuario | Cualquier usuario |
| **Escribir** MSR / SMU / PWM / curvas / CO / EPP / P-States | **Solo root** | Cualquier cliente conectado |

La app suele correr como tu usuario (no root). Sin este flag, **monitorizas bien** pero **los controles fallan** y aparece el banner naranja de privilegios.

### Ejemplo

```text
…tus args… -amdcppcactive -amdpnopchk
```

### Aviso de seguridad

> [!WARNING]
> `-amdpnopchk` **baja deliberadamente la seguridad**. Cualquier proceso local que abra el UserClient puede escribir en hardware sensible.  
> Úsalo solo en un **PC personal de confianza**.

---

## Verificación tras reiniciar

```bash
kextstat | grep -i AMDRyzen
nvram boot-args
```

En la app, cambiar EPP o un ventilador **no** debería mostrar el banner de privilegios si el flag está activo.

---

## Documentación relacionada

- [PRIVILEGE_AND_SECURITY.md](PRIVILEGE_AND_SECURITY.md) (modelo completo, en inglés)  
- [FEATURES.md](FEATURES.md)  
- Manual: `AMD_Power_Gadget_Manual_ES.md`
