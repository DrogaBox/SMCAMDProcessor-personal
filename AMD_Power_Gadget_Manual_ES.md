<div class="cover-page">
    <span class="cover-title">AMD Power Gadget</span>
    <span class="cover-subtitle">Manual de Usuario y Guía Completa</span>
    <br><br>
    <span style="color: var(--accent-cyan);">Versión 3.15.0</span>
</div>

## Introducción

Bienvenido a **AMD Power Gadget** y **SMCAMDProcessor**. Esta suite proporciona telemetría completa y capacidades de gestión de energía para procesadores AMD Ryzen en macOS (Hackintosh).

Este manual explica cada opción, control deslizante y botón disponible en la aplicación, sin dejar nada a las conjeturas.

---

## 1. Requisitos del Sistema y Configuración de OpenCore

### 1.1 Kexts Esenciales
Asegúrese de que los siguientes kexts estén presentes en su carpeta `EFI/OC/Kexts` e inyectados en su `config.plist` bajo `Kernel -> Add`, en este orden exacto:
1. `Lilu.kext` (Debe ir primero)
2. `VirtualSMC.kext` (Emulador SMC - NO use FakeSMC)
3. `AMDRyzenCPUPowerManagement.kext` (Proporciona datos sin procesar de la CPU y acceso SuperIO)
4. `SMCAMDProcessor.kext` (Exporta datos a VirtualSMC para herramientas como iStat Menus)

### 1.2 Quirks de OpenCore y boot-args
- **ProvideCurrentCpuInfo** (Kernel -> Quirks): Establecer en `True`. Obligatorio para que macOS mapee correctamente las topologías de los núcleos AMD.
- **agdpmod=pikera** (boot-args): Requerido para la serie Radeon RX 6000 (Navi) para prevenir pantallas negras.

---

## 2. Pestaña de Energía y Frecuencias

Esta pestaña proporciona monitoreo en tiempo real de las métricas internas de su CPU.

### 2.1 Métricas de Núcleos y Silicon Quality
- **Frecuencias de Núcleo (Core Frequencies)**: Muestra la velocidad de reloj en tiempo real de cada núcleo físico y lógico.
- **Clasificación de Silicon Quality (1. ~ X.)**: Los procesadores Zen 3/4 evalúan la calidad del silicio núcleo por núcleo. La aplicación lee estas etiquetas CPPC y clasifica sus núcleos. El núcleo `1.` es su mejor núcleo absoluto, capaz de sostener las frecuencias de impulso (boost) más altas con los voltajes más bajos. Use estos datos al ajustar el Curve Optimizer.
- **Package Power Tracking (PPT)**: Muestra el vataje total consumido por el paquete de la CPU en tiempo real.
- **Temperaturas Tctl / Tdie**: La temperatura de unión (junction) absoluta de la CPU.

---

## 3. Pestaña de Perfiles (Gestión de Velocidad de la CPU)

La pestaña de Perfiles le permite alterar fundamentalmente cómo la CPU escala sus frecuencias y voltajes.

### 3.1 Perfiles EPP (Autonomía de Hardware)
La Preferencia de Rendimiento Energético (EPP) se basa en la interfaz CPPC (Collaborative Processor Performance Control). En lugar de que macOS dicte las frecuencias, usted proporciona una "pista" al SMU interno de la CPU, y el hardware escala de forma autónoma basándose en la carga en tiempo real.
- **Ahorro de Energía (Power Saver)**: Limita fuertemente los relojes de impulso para priorizar la duración de la batería y la acústica.
- **Equilibrado (Balanced)**: El estado predeterminado. Aumenta la frecuencia cuando es necesario, pero reduce agresivamente el reloj (downclocks) durante el reposo.
- **Rendimiento (Performance)**: Mantiene los núcleos altamente receptivos, conservando relojes base más altos y priorizando la velocidad de impulso de un solo hilo sobre la eficiencia energética.

### 3.2 Perfiles de Velocidad de la CPU (Legacy / P-State Manual)
Los procesadores Ryzen más antiguos (o escenarios específicos de ajuste manual) dependen de P-States (Power States) estáticos.
- **Anulación Manual de P-State**: Seleccionar un perfil aquí restringe completamente la CPU a un nivel específico de P-State (por ejemplo, P0 para máximo rendimiento, P2 para reloj base). La CPU NO escalará dinámicamente; queda bloqueada en el nivel seleccionado.
- **Editar Directamente los Registros en Bruto de P-State**: Una función muy avanzada. Hacer clic aquí le permite ingresar manualmente los valores hexadecimales (Hex) para Frecuencia, Voltaje (VID) y DID. 

> [!WARNING]
> Requiere que las comprobaciones de privilegios de los kexts estén desactivadas. Los valores VID incorrectos causarán el apagado instantáneo del sistema o una posible degradación del hardware.

---

## 4. Ajuste Avanzado de CPU: Curve Optimizer

El **Curve Optimizer** es la herramienta más poderosa para los usuarios de AMD Ryzen. Ajusta dinámicamente la curva de voltaje/frecuencia.

- **Desplazamientos de Curva por Núcleo (Offsets de -30 a +30)**: En lugar de aplicar un desplazamiento de voltaje general, puede asignar un desplazamiento único a *cada núcleo físico individual*.
- **Cómo funciona**: Un desplazamiento negativo (por ejemplo, `-15`) le dice a la CPU que use menos voltaje para una frecuencia dada. Debido a que la CPU funciona más fría a un voltaje menor, el algoritmo Precision Boost le permite automáticamente sostener relojes de impulso más altos por períodos más prolongados.
- **Estrategia**: Aplique desplazamientos negativos más grandes (por ejemplo, `-25`) a sus núcleos de clasificación más baja, y desplazamientos más pequeños (por ejemplo, `-10`) a sus núcleos mejor clasificados (que ya están empujados a sus límites de voltaje de fábrica).

---

## 5. Pestaña de Control de Ventiladores

Esta pestaña interactúa con el controlador SuperIO de su placa base (por ejemplo, ITE IT8686E) para gestionar los ventiladores del chasis y de la CPU.

### 5.1 Monitoreo y Ocultación de Ventiladores
- **Lista de Ventiladores**: Muestra todos los ventiladores detectados, sus RPM y el porcentaje de aceleración (Throttle) PWM.
- **Ocultar Ventilador (Icono de Ojo Tachado)**: Si su placa base reporta ventiladores fantasma o cabezales como `H_AMP` muestran valores erráticos (por ejemplo, `40 RPM` cuando están desconectados), haga clic en el icono del ojo tachado para ocultarlo permanentemente de la interfaz de usuario y del Menu Bar Extra.
- **Mostrar Todos (X ocultos)**: Restaura cualquier ventilador oculto.

### 5.2 Ajustes Preestablecidos Rápidos
- **Todo en Automático (Icono de Círculo de Flechas)**: Devuelve el control de todos los ventiladores a la lógica de la BIOS de la placa base.
- **Velocidad Máxima (Icono de Viento)**: Fuerza instantáneamente un ciclo de trabajo PWM del 100% en todos los ventiladores conectados (Modo Despegue).

### 5.3 Curvas de Ventilador Personalizadas de Bucle Cerrado y Protección
Active **"Dynamic Next-Gen Fan Curves"** para anular la BIOS y gestionar los ventiladores completamente a través del kernel de macOS.
- **Editor Interactivo**: Arrastre los puntos en el gráfico para definir su curva personalizada de temperatura a PWM.
- **Interpolación LUT de 256 Pasos**: El software traduce su curva en una tabla de búsqueda (Look-Up Table) fluida de 256 pasos.
- **Aceleración Suave (Histéresis)**: El kernel evalúa la curva con histéresis para evitar que los ventiladores aceleren y desaceleren agresivamente durante picos repentinos y momentáneos de temperatura en la CPU.

### 5.4 Control de Ventilador de la GPU (Zero RPM / SPPT)
Como se indica en la interfaz de usuario, las anulaciones directas de la velocidad del ventilador de la GPU basadas en software (como dibujar curvas para su Radeon RX 6800 XT) **no son compatibles** con el kernel de macOS para GPUs AMD.
- **La Solución**: Debe extraer su vBIOS, usar **MorePowerTool (MPT)** en Windows para modificar los límites acústicos y los interruptores de Zero RPM, e inyectar la cadena de la Soft PowerPlay Table (SPPT) resultante en el `config.plist` de OpenCore bajo `DeviceProperties`. La interfaz de usuario proporciona enlaces directos a la Guía SPPT y a las descargas de MPT.

---

## 6. Menu Bar Extra y Preferencias

El Menu Bar Extra proporciona una vista compacta y altamente personalizable de los signos vitales de su sistema directamente en la barra de menú de macOS.

### 6.1 Configuración de Pantalla
Haga clic en el icono de AMD Power Gadget -> **Preferencias**:
- **Incluir CPU/GPU/Ventiladores**: Active o desactive widgets específicos.
- **Rastreo de Picos (Peak Tracking)**: El menú desplegable registra automáticamente los valores Máximos (Peak) y Mínimos (Minimum) para todas las métricas seleccionadas durante la sesión actual.

### 6.2 Ajustes de la Aplicación
- **Intervalo de Actualización**: Ajuste la frecuencia con la que se sondean los sensores. Los intervalos de 1 segundo proporcionan precisión en tiempo real; los intervalos más altos ahorran ciclos de CPU.
- **Tema (Theme)**: Fuerce el Modo Oscuro, el Modo Claro o respete los ajustes del Sistema (utiliza la vibrancia Liquid Glass).

---

## 7. Utilidad de Volcado del Controlador (Avanzado)

Si sus ventiladores leen RPM incorrectas, generalmente significa que los registros del tacómetro de 16 bits o los divisores del reloj interno están desalineados para la revisión específica de su chip SuperIO.
Ejecute `Tools/IT8686E_Dump.sh` como `sudo` para generar los valores Hexadecimales en bruto de los registros del Controlador de Entorno (EC). Use esto para verificar si el byte en bruto de `FAN_RPM_REGS` necesita un ajuste de multiplicador en el código fuente del kext.
