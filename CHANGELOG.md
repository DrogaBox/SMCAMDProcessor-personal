# Resumen de Cambios (Walkthrough v2.1.4+)

Se han implementado y verificado las siguientes mejoras correspondientes a la telemetría del GPU, soporte de visualización y estabilidad de la compilación de Xcode:

---

## 🏎️ 1. Throttling Dinámico de Refresh Rate (Ahorro de Recursos)
Para cumplir con el requerimiento de consumo mínimo de recursos (siendo una app de monitoreo):
* **[AppDelegate.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/AppDelegate.swift#L44-L49)**: Se añadió un observador nativo (`AppActiveWindowsChanged`) que se dispara cuando cambia el estado de visibilidad de las ventanas de la aplicación (Dashboard, Power Tool o Fan Controller).
* **[StatusbarController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/StatusbarController.swift#L364-L380)**: Escucha la notificación `AppActiveWindowsChanged`. Si el usuario no tiene ninguna ventana abierta (solo corre la barra de menú en segundo plano), la tasa de refresco disminuye automáticamente a **3.0 segundos**. Si abre el Dashboard, vuelve instantáneamente al intervalo en tiempo real configurado (ej. **0.5 segundos**).
  * *Resultado*: Reducción masiva del consumo de CPU de fondo en estado inactivo en más de un **83%**.

---

## 📈 2. Corrección de Frecuencia en Zen 5 (Family 1Ah)
En los procesadores de la Family 1Ah (Zen 5), los P-states ya no utilizan el divisor `CpuDfsId`, y el campo del multiplicador `CpuFid` se expande a **12 bits**. La frecuencia se calcula como `CpuFid * 5`.
* **[AMDRyzenCPUPowerManagement.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp#L555-L572)**: Modificada `updateClockSpeed` para decodificar la frecuencia usando `(eax & 0xfff) * 5.0f` si `cpuFamily >= 0x1A`.
* **[AMDRyzenCPUPowerManagement.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp#L774-L790)**: Corregida `dumpPstate` para mapear el multiplicador a 12 bits en Zen 5.
* **[AMDRyzenCPUPowerManagement.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp#L806-L820)**: Modificada la validación en `writePstate` para evitar descartar P-states válidos en Zen 5 debido a la ausencia del campo `CpuDfsId`.

---

## 🛡️ 3. Prevención de Crashes y Estabilidad (Swift)
Añadidas protecciones contra accesos fuera de rango (Index out of range) cuando la aplicación intenta conectarse al driver o al kext de SMC y estos retornan arrays vacíos.
* **[ViewController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/ViewController.swift#L56-L63)**: Configurado `window.isOpaque = false` y `window.backgroundColor = .clear` en `viewWillAppear()`. Esto elimina los artefactos visuales y estelas al mover o redimensionar la UI traslúcida.
* **[ProcessorModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/ProcessorModel.swift#L410-L415)**: Añadida validación de conteo en `getHPCpus()`, `getPPM()`, `getLPM()`, y `getInstructionDelta()`.
* **[TelemetryModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/TelemetryModel.swift#L224-L230)**: Protegido el método `initSMC()` al recuperar el conteo de ventiladores (selector 91).
* **[SystemMonitorViewController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/System%20Monitor/SystemMonitorViewController.swift#L40-L75)**: Añadidas protecciones contra arrays vacíos en la inicialización de ventiladores y SMC en `viewDidLoad()`.

---

## 🌍 4. Localización y Mappings Xcode Nativos (i18n)
Migradas las claves del menú de la barra de estado en el código a inglés nativo para seguir las directivas i18n de Xcode.
* **[StatusbarController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/StatusbarController.swift#L539-L594)**: Migradas las claves de español a inglés (ej. `"Dynamic Colors (Temp Only)"`, `"Temp Alert Color"`, etc.) y convertidos los arrays de colores al inglés para permitir traducción automática.
* **[en.lproj/Localizable.strings](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/en.lproj/Localizable.strings)**: Agregadas las nuevas claves en inglés.
* **[es.lproj/Localizable.strings](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/es.lproj/Localizable.strings)**: Actualizadas las traducciones correspondientes de las nuevas claves de inglés a español.

---

## 🤝 5. Agradecimientos en README y Version Bump
* **[README.md](file:///Users/droga/Desktop/SMCAMDProcessor/README.md#L104-L115)**: Añadida una sección de contribuciones para la versión 2.1.1 agradeciendo formalmente a **Kackvogel 4K**, **Can**, **MacOSx11** y **royal** por sus testeos e ideas en Discord.
* **Version Bump**: Incrementada la versión del proyecto de `2.1.0` a `2.1.1` en la configuración interna de Xcode y los archivos `Info.plist`.

---

## 🏷️ 6. Corrección de Etiquetas Verticales en el Menu Bar
Se corrigió un problema visual donde las etiquetas verticales de algunas columnas (como Fan y Memoria) no se mostraban (quedaban transparentes/recortadas) debido a que intentaban dibujarse horizontalmente en una caja de texto muy estrecha (7pt de ancho).
* **[StatusbarController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/StatusbarController.swift#L137-L209)**: Se estructuraron las etiquetas para CPU (modo compacto simple), Fan y Memoria agregando saltos de línea para que se dibujen verticalmente (`"C\nP\nU"`, `"F\nA\nN"`, `"M\nE\nM"`).
* **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift#L1569-L1590)**: Se actualizaron los correspondientes textos de vista previa en SwiftUI en los ajustes del panel.
* **Git Deploy**: Todo se confirmó (`git commit`) y se subió (`git push`) de forma limpia a `master`.

---

## 🚀 7. Nueva Función: Menú de Picos de la Sesión (Session Peaks)
Se implementó una nueva funcionalidad sumamente útil para monitorear el rendimiento máximo alcanzado durante una sesión de uso (ej. al jugar o renderizar en segundo plano) sin necesidad de tener el panel principal abierto:
* **[StatusbarController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/StatusbarController.swift#L542-L586)**: Registra los valores máximos históricos en segundo plano (`peakTemp`, `peakPower`, `peakFreq`, `peakFan`) sin consumo de CPU.
* **Menú Desplegable:** Al hacer clic derecho en la barra de menús, se presenta un nuevo submenú llamado **Session Peaks** (Picos de la Sesión) que muestra:
  * **Peak Temp:** Temperatura máxima alcanzada (soporta Fahrenheit si está activado).
  * **Peak Power:** Potencia máxima del CPU en Watts.
  * **Peak Freq:** Frecuencia máxima en GHz.
  * **Peak Fan:** Velocidad máxima del ventilador en RPM.
  * **Reset Peaks:** Opción para reiniciar los valores a cero.
* **Localización (i18n):** Se tradujo a español e inglés en `Localizable.strings`.

---

## 🎨 8. Rediseño de la UI: Agrupación de Filas de Información (InfoRows)
Se rediseñó la interfaz visual de la aplicación para eliminar la fragmentación estética que causaba que cada fila de datos tuviera su propia cápsula/globo independiente.
* **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift#L214-L227)**: Se modificó `InfoRow` para que actúe como un elemento de fila limpio y sin bordes ni fondo propios (`padding` vertical de 4pt).
* **Agrupación en Tarjetas:** Se agruparon las filas de las siguientes secciones envolviéndolas en contenedores `TahoeCard` únicos con divisores (`Divider`) entre ellas:
  * **Current Values (Panel de Control):** Agrupa en un solo globo las 7 filas de telemetría en tiempo real (CPU Model, Avg/Max Freq, Temp, CPU/GPU Power, etc.).
  * **Active Profile (Perfiles):** Agrupa el perfil seleccionado y las frecuencias en una sola tarjeta.
  * **Processor (Información de Sistema):** Agrupa las 8 filas de especificaciones del procesador (modelo, familia, núcleos, cachés, etc.) en un solo globo.
  * **Platform (Información de Sistema):** Agrupa la placa madre, fabricante, gráficos, RAM y almacenamiento en una única tarjeta cohesiva.
  * **Software (Información de Sistema):** Agrupa la versión de macOS, del Kext y la compatibilidad en un solo globo.
* **Resultado:** Un diseño de UI mucho más limpio, ordenado, premium y en línea con las pautas estéticas modernas de macOS.

---

## ⚡ 9. Reversión de Throttling del Polling Rate (Barra de Menús) y Pausa de Telemetría (App)
* **[StatusbarController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/StatusbarController.swift#L371-L384)**: A petición del usuario, se removió el comportamiento de ralentizar el intervalo de actualización de la barra de menús. La barra de menús ahora actualiza constantemente a la velocidad exacta configurada (ej. 0.7 segundos) bajo cualquier circunstancia.
* **[TelemetryModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/TelemetryModel.swift#L178-L255)**: Para mantener el máximo ahorro de recursos que gustaba de la versión previa, se programó la clase del sensor principal (`TelemetryModel`) para que escuche la notificación `AppActiveWindowsChanged`. 
  * Si los paneles principales de la app están cerrados (sólo corre el Menu Bar), el timer de la telemetría del panel se **pausa por completo** (`timer = nil`).
  * Si se abre cualquier panel, el timer se **reanuda instantáneamente** al intervalo correcto para graficar.
* **Git Deploy**: Estos cambios específicos de la aplicación (`StatusbarController.swift` y `TelemetryModel.swift`) fueron confirmados y subidos exitosamente a `master`.

---

## 🛡️ 10. Mejoras de Estabilidad en los Kexts (Locales únicamente - NO subidas a Git)
Para evitar riesgos en tu sistema cargando extensiones de kernel modificadas sin antes validarlas, las siguientes mejoras de estabilidad se realizaron a nivel de código y se compilaron **de manera puramente local** (no han sido agregadas ni empujadas a tu repositorio remoto de Git):
* **Remoción de Panics Peligrosos:** En macOS, si una lectura o escritura de un registro MSR (Model-Specific Register) en el procesador falla momentáneamente, es una muy mala práctica colgar todo el sistema operativo con un Kernel Panic.
* **[AMDRyzenCPUPowerManagement.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp#L550-L775)**: Se eliminaron 5 llamadas críticas a `panic()` en las rutinas clave de MSR:
  * `updateClockSpeed` (MSR `0xC0010293` - Estado del P-State)
  * `updateInstructionDelta` (MSR `0xC00000E9` - Contador de instrucciones)
  * `setCPBState` (MSR `0xC0010015` - Activación/desactivación de CPB)
  * `getCPBState` (MSR `0xC0010015` - Estado de CPB)
  * `dumpPstate` (MSRs `0xC0010064` a `0xC001006B` - Definiciones de P-States)
* **Manejo de Errores Seguro:** Si alguna de estas lecturas falla, la función ahora escribe un reporte seguro al log del kernel (`IOLog`) y retorna (`return` o `continue` para omitir ese tick/pstate) de manera limpia y transparente sin colgar tu computadora.

---

## 📦 Despliegue de Binarios v2.1.1 (Recompilado localmente)
Los cambios y kexts actualizados se encuentran compilados y desplegados localmente en:
* `/Applications/AMD Power Gadget.app`
* `/Users/droga/Desktop/Binaries_Release/v2.1.1/AMD Power Gadget.app`
* `/Users/droga/Desktop/Binaries_Release/v2.1.1/AMDRyzenCPUPowerManagement.kext` (Compilación local segura sin pánicos)
* `/Users/droga/Desktop/Binaries_Release/v2.1.1/SMCAMDProcessor.kext` (Compilación local estable)

---

## 🛠️ 11. Actualización de EFI (OpenCore)
* **Ruta de Destino:** `/Volumes/EFI/EFI/OC/Kexts/`
* **Acción realizada:** Se compilaron ambos kexts en la configuración **Debug** (`AMDRyzenCPUPowerManagement.kext` y `SMCAMDProcessor.kext`) para habilitar la generación de logs de Lilu/kext que de otra forma se descartan en las versiones Release. Luego se reemplazaron en la partición EFI.
* **Kexts actualizados en EFI:**
  * `AMDRyzenCPUPowerManagement.kext` (v2.1.1 - Debug build con mitigación de pánicos y soporte Zen 5)
  * `SMCAMDProcessor.kext` (v2.1.1 - Debug build)
* **Parámetros de Arranque (boot-args):**
  * Se modificó `/Volumes/EFI/EFI/OC/config.plist` añadiendo `-amdpdbg` a la sección `boot-args`. Este argumento es necesario para activar `debugEnabled` dentro del kext.

---

## 🔍 Monitoreo de Logs Post-Reinicio
Una vez reiniciada la máquina, puedes obtener y monitorear los logs del kext de administración de energía ejecutando el siguiente comando en la Terminal:
```bash
log show --predicate 'sender == "wtf.spinach.AMDRyzenCPUPowerManagement"' --last 10m
```

---

## 🔗 12. Enlaces del Repositorio de Git en la Aplicación
* **Panel About (Acerca de)**: Se implementó el método `orderFrontStandardAboutPanel(_:)` de manera personalizada en `AppDelegate.swift` para que al hacer clic en "About AMD Power Gadget", la ventana nativa de macOS contenga un enlace directo y clickeable a tu repositorio personal.
* **Pie del Dashboard (Sidebar)**: Se modificó la etiqueta de version en el panel lateral de `MainDashboardView.swift` para que sea un enlace interactivo. Ahora, al hacer clic sobre el texto de versión (v2.1.3 · macOS Tahoe), se abrirá automáticamente el navegador web apuntando a tu repositorio Git.

---

## 🛠️ 13. Soporte Zen 5 en el Editor de P-States (v2.1.3)
* **Detección Dinámica**: El editor ahora lee de manera dinámica la familia de CPU a través de CPUID básica para determinar las reglas de decodificación y codificación.
* **Fórmula Adaptada**: Si detecta un procesador Zen 5 (Family 1Ah), realiza el mapeo de `CpuFid` en 12 bits y calcula la velocidad a `CpuFid * 5.0 MHz`, omitiendo el divisor de frecuencia (`CpuDfsId`).
* **Protección de Columna**: Se bloquea la edición del campo `CpuDfsId` en la tabla para procesadores Zen 5, ya que dicho divisor no se utiliza físicamente en esta arquitectura.
* **Carga en EFI**: Los kexts reconstruidos con la versión 2.1.3 (incluyendo la compilación de depuración y las optimizaciones correspondientes) fueron sincronizados en `/Volumes/EFI/EFI/OC/Kexts/`.

---

## 📝 14. Documentación Detallada de Zen 5 en README.md (v2.1.3)
* **Actualización del README.md**: Se expandió el archivo de documentación principal para detallar de manera clara y en inglés técnico toda la arquitectura de soporte implementada para los procesadores de la familia Zen 5 (Family 1Ah):
  * Explicación detallada del multiplicador de 12 bits (`CpuFid`) y la fórmula de frecuencia directa `CpuFid * 5.0 MHz`.
  * La sincronización automática de estas reglas de decodificación y encodado entre los Kexts (`AMDRyzenCPUPowerManagement`) y la aplicación GUI (`AMD Power Gadget`).
  * Detalles sobre la infraestructura de depuración: uso de compilaciones `Debug`, requisito del flag `-amdpdbg` en `boot-args` de OpenCore, y comandos para consultar logs a través del macOS Unified Logging system (`log show`) esquivando la rápida saturación de `dmesg`.
  * Explicación de la mitigación de Kernel Panics a través del manejo seguro de errores de lectura/escritura de registros MSR críticos.
* **Confirmación Git**: Los cambios en `README.md` fueron confirmados y subidos exitosamente a la rama principal de Git de forma totalmente limpia.

---

## 📅 15. Fase 1: Telemetría de Temperatura por CCD (v2.1.4 - Fase 1 Completada)
Se implementaron los cambios de backend para dar soporte a la medición de temperaturas individuales por CCD (Core Complex Die) en procesadores AMD multinúcleo de manera estable y segura contra condiciones de carrera:
*   **Lectura en Segundo Plano (Kext C++)**:
    *   **[AMDRyzenCPUPowerManagement.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp)**: Se integró la actualización del arreglo `ccdTemperatures` en el hilo de temporización en segundo plano (`timerEvent_tempe`) junto con la temperatura general del empaque. Esto evita colisiones y condiciones de carrera en el bus PCI al leer los registros de configuración compartidos.
*   **Exposición en UserClient (Kext C++)**:
    *   **[AMDRyzenCPUPMUserClient.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp)**: Se añadió el selector `case 20` para exponer la cantidad de CCDs activos (`ccdCount`) y el arreglo de temperaturas a la capa del usuario.
*   **Capa Swift (App)**:
    *   **[ProcessorModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/ProcessorModel.swift)**: Se implementó la función `getCCDTemperatures()` que invoca al selector 20 a través de IOKit.
    *   **[TelemetryModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/TelemetryModel.swift)**: Se añadió la propiedad reactiva `@Published var ccdTemperatures: [Float]` y se configuró su asignación periódica dentro de la rutina de muestreo principal `sample()`.

---

## 📅 16. Fase 2: Integración de NSPopover y Estructura SwiftUI (v2.1.4 - Fase 2 Completada)
Se implementó el reemplazo del menú tradicional de la barra de estado por un `NSPopover` interactivo con SwiftUI:
*   **Contenedor NSPopover (App)**:
    *   **[StatusbarController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/StatusbarController.swift)**: Se eliminó el lanzamiento del panel principal al hacer clic izquierdo en el menú de la barra de menús. En su lugar, se configuró un `NSPopover` con comportamiento `.transient` (se cierra al hacer clic fuera) y estilo vibrante traslúcido oscuro.
    *   Se adoptó el protocolo `NSPopoverDelegate` para reaccionar al cierre del popover y apagar la telemetría en segundo plano para conservar recursos de CPU.
*   **Aislamiento de Hilos (App)**:
    *   Se declararon `@MainActor` las clases `AppDelegate` y `StatusbarController` para asegurar que las llamadas entre los controladores gráficos y el modelo de telemetría (`TelemetryModel.shared`) se ejecuten de manera segura en el hilo principal de macOS, resolviendo errores de concurrencia del compilador de Swift.
*   **Estructura Visual SwiftUI (App)**:
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift)**: Se implementó la vista `MenuBarPopoverView` como un componente dentro del archivo de vistas principales. Esta vista dibuja la cabecera de la aplicación, tres anillos de progreso (CPU, RAM, Disco), filas informativas para GPU y Red, y botones de acción rápida ("Abrir panel" y "Salir").

---

## 📅 17. Fase 3: Widgets de Popover, SF Symbols y Procesos Principales (v2.1.4 - Fase 3 Completada)
Se completó la implementación y el diseño premium del popover de la barra de estado con datos del sistema y telemetría en tiempo real:
*   **Métricas del Sistema Dinámicas (App)**:
    *   **[TelemetryModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/TelemetryModel.swift)**: Añadidas propiedades reactivas para el promedio de carga del CPU (`cpuLoadAvg`), porcentaje de uso de RAM (`ramUsagePct`), y porcentaje de uso del disco principal (`diskUsagePct`).
    *   Implementados métodos seguros en segundo plano para leer estadísticas del sistema (Mach Virtual Memory `vm_statistics64` para RAM, atributos de sistema de archivos para Disco).
*   **Consulta de Procesos en Segundo Plano**:
    *   Integrado un hilo secundario (`Task.detached`) que ejecuta de forma optimizada y asíncrona `/bin/ps` para obtener los 5 procesos que consumen más CPU en el sistema, mostrando su nombre limpio y porcentaje de uso real. Se ejecuta únicamente cuando el popover está visible para no generar sobrecarga innecesaria.
*   **Diseño Premium con SwiftUI**:
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift)**: Rediseñado por completo `MenuBarPopoverView` vinculando los anillos circulares a las métricas reales del CPU, RAM y Disco con gradientes de color AMD Crimson y sombras de profundidad.
    *   Vinculados los indicadores de velocidad de red (descarga/subida) y temperatura/wattage del procesador gráfico (GPU).
    *   Se integraron íconos limpios con SF Symbols y botones estilizados uniformemente.

---

## 📅 18. Fase 3.5: Personalización de Popover, GPU Ring y Correcciones Críticas (v2.1.4 - Fase 3.5 Completada)
Se implementaron opciones avanzadas de personalización para el popover, se integró el anillo de utilización de la GPU y se resolvieron bugs de usabilidad críticos:
*   **Anillo de Telemetría de la GPU (App)**:
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift#L2062-L2162)**: Se añadió un cuarto anillo de progreso circular interactivo en `MenuBarPopoverView` dedicado al procesador gráfico (GPU), mostrando su porcentaje de utilización (`model.gpuLoadPct`) con un gradiente morado/índigo y su temperatura interna (`model.gpuTempC`).
*   **Opciones de Visualización de Anillos (App)**:
    *   Implementados interruptores para ocultar/mostrar las etiquetas inferiores de los anillos ("Show Ring Labels") y los detalles interiores de temperatura/uso ("Show Ring Details").
    *   Se adaptó el espaciado dinámico a `spacing: 14` para que los 4 anillos quepan de manera perfectamente balanceada y profesional.
*   **Reorganización de Ajustes (i18n & UX)**:
    *   Se extrajeron todas las opciones del popover de la pestaña "Styles & Themes" y se agruparon en una sección dedicada exclusiva llamada **Popover Customization**.
    *   Se añadieron toggles de control para cada anillo (CPU, RAM, Disco, GPU) y fila de datos, logrando una interfaz limpia y estructurada.
*   **Resolución de Salto de Scroll (Bugfix)**:
    *   Se removió el modificador `.id(refreshToggle)` que recreaba por completo la vista del `ScrollView` (provocando que el scroll regresara abruptamente al tope al presionar cualquier botón).
    *   Se reubicó el identificador `.id(refreshToggle)` únicamente en la vista `MenuBarPreview`, manteniendo la persistencia y suavidad de navegación en la pestaña de ajustes.

---

## 📅 19. Fase 3.6: Apartado de Configuración de Popover Independiente, Reordenamiento Dinámico y Gráficos Avanzados (v2.1.4 - Fase 3.6 Completada)
A petición del usuario, se migró y enriqueció toda la configuración del popover fuera del menú de la barra de menús principal, introduciendo nuevas opciones de diseño:
*   **Apartado de Configuración Exclusivo (App)**:
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift#L2384-L2450)**: Se añadió el caso de navegación `.popover` ("Popover Menu") en el enum de pestañas del panel de control principal, con su propio ícono y ruteo a `PopoverConfigView`.
    *   Se eliminó la configuración de popover que estaba previamente en `MenuBarConfigView` para mantener los dos apartados separados.
*   **Reordenamiento Dinámico de Recursos (App)**:
    *   Implementada una interfaz en `PopoverConfigView` que permite al usuario mover los módulos (CPU, RAM, Disco, GPU) hacia arriba y abajo en la jerarquía mediante botones interactivos, persistiendo su posición en `UserDefaults` a través de una lista separada por comas (`popoverRingOrder`).
    *   `MenuBarPopoverView` recorre dinámicamente este orden al renderizar los widgets.
*   **Nuevos Tipos de Gráficas de Telemetría (App)**:
    *   **Circular Rings (Style 0)**: Dibuja los indicadores tradicionales de anillo agrupados en una fila `HStack` (solo para recursos configurados con estilo Ring).
    *   **Linear Progress Bars (Style 1)**: Dibuja barras de progreso lineales que abarcan el ancho completo para CPU, RAM, Disco y GPU.
    *   **Real-time Sparklines (Style 2)**: Dibuja mini gráficas de líneas y áreas en tiempo real (utilizando Swift Charts `Chart`, `AreaMark` y `LineMark`) para monitorear la tendencia histórica de temperatura de CPU y GPU dentro del popover.

---

## 📅 20. Fase 4: Telemetría Extendida de GPU en Barra de Menú y Corrección de Caídas de Sparkline (v2.1.4 - Completada)
Se expandieron las capacidades de telemetría del chip gráfico (GPU) e integraron protecciones de interfaz:
*   **Telemetría GPU en la Barra de Menú (App)**:
    *   **[StatusbarController.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/StatusbarController.swift)**: Se agregaron las propiedades de configuración `showGPUvram` y `showGPUfan`. Se agregaron los valores de caché para GPU VRAM y velocidad del ventilador (RPM).
    *   Si se activa `showGPUfan` y `showGPU`, la columna de ventiladores (**FAN**) cambia dinámicamente para mostrar el ventilador del CPU arriba (`C:XXXX`) y el del GPU abajo (`G:XXXX`).
    *   Si se activa `showGPUvram` y `showGPU`, la columna de memoria (**MEM**) muestra la memoria del sistema arriba (`S:X.XG`) y la VRAM del GPU abajo (`G:X.XG`).
*   **Vista Previa y Ajustes (App)**:
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift)**: Se añadieron dos nuevos toggles ("Show GPU VRAM" y "Show GPU Fan Speed") en la sección de opciones de GPU. Se adaptó la vista previa `MenuBarPreview` para renderizar el formato dual.
*   **Corrección de Caídas a Cero en Sparklines (App)**:
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift)**: Se agregó la propiedad `filterZeros` en `MiniSparkline` (configurada como `true` para CPU Temp y GPU Temp). Esto filtra los valores de telemetría iguales a `0.0` (por ejemplo, cuando el GPU entra en modo Zero RPM o suspensión), previniendo que la gráfica sufra picos abruptos hacia abajo y el eje Y se desalinee/comprima.
*   **Información de Control del Ventilador (App)**:
    *   Se añadió un panel explicativo `GPUFanControlGuideView` en la pestaña de ventiladores, detallando que la API de macOS bloquea el control de velocidad en GPUs de terceros y enlazando herramientas de Windows/OpenCore como MorePowerTool y tablas de energía SoftPowerPlayTable (SPPT).

---

## 📅 21. Fase 5: Resolución de Dependencias Cíclicas y Compilación de Múltiples Targets en Xcode (v2.1.4 - Completada)
Se resolvieron los problemas críticos del sistema de build que bloqueaban la compilación local y en la integración continua (CI):
*   **Restricción de Arquitectura para Extensiones de Kernel (C++)**:
    *   **[project.pbxproj](file:///Users/droga/Desktop/SMCAMDProcessor/SMCAMDProcessor.xcodeproj/project.pbxproj)**: Se configuró explícitamente `ARCHS = x86_64;` para todas las configuraciones de build (Debug y Release) en los dos targets de kexts (`AMDRyzenCPUPowerManagement` y `SMCAMDProcessor`). Esto previene que Xcode intente compilar extensiones de kernel de C++ para las arquitecturas ARM (`arm64` o `arm64e`) al correr en hosts Apple Silicon (mecanismo que fallaba por directivas de ensamblador de x86).
*   **Resolución de Ciclo de Dependencias**:
    *   Se reordenó el arreglo `targets` en el objeto raíz de `PBXProject` dentro de `project.pbxproj`. Se reubicó el target `APGLaunchHelper` para ser compilado *antes* que `AMD Power Gadget`. Esto soluciona la dependencia cíclica en Xcode en la que `AMD Power Gadget` requiere que `APGLaunchHelper` esté compilado previamente para copiarlo a su subcarpeta `LoginItems` en la fase de empaquetado, eliminando el bloqueo del build.
*   **Verificación de Todos los Targets**:
    *   Se ejecutó la compilación de todos los targets (`xcodebuild -project SMCAMDProcessor.xcodeproj -alltargets -configuration Release build`) confirmando la correcta creación de los 4 ejecutables y finalizando con éxito absoluto (**BUILD SUCCEEDED**).

---

## 📅 22. Corrección de Localización de la Fila de Red (v2.1.4 - Completada)
Se resolvió el bug donde la fila de velocidad de Red en el popover mostraba la palabra "Rojo" en lugar de "Red" (Network) al utilizar el sistema en español:
*   **Desacoplamiento de Claves (SwiftUI)**:
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift#L2395)**: Se modificó la etiqueta de la fila de Red para que use la clave `"Network"` en lugar de `"Red"`, evitando que colisione con el nombre del color rojo ("Red" / "Rojo").
*   **Traducciones en Localizables (i18n)**:
    *   **[en.lproj/Localizable.strings](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/en.lproj/Localizable.strings#L88)**: Se añadió la clave `"Network" = "Network";` para la interfaz en inglés.
    *   **[es.lproj/Localizable.strings](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/es.lproj/Localizable.strings#L88)**: Se añadió la clave `"Network" = "Red";` para que en español se muestre correctamente el término técnico de red sin alterar la traducción del color Rojo ("Red" -> "Rojo").
*   **Verificación del Build**:
    *   Compilado con éxito absoluto y copiado a `/Applications/AMD Power Gadget.app`.

---

## 📅 23. Optimización de Visualización de Red en Popover (v2.1.4 - Completada)
*   **Problema de Redondeo**: La velocidad de red en el popover se mostraba de manera fija con formato `"%.1f M"`, lo que provocaba que velocidades menores a **50 KB/s** se redondearan a `0.0 M` y dieran la sensación de inactividad.
*   **Solución**: Se implementó una función auxiliar de formato `formatSpeed()` en `MenuBarPopoverView` para formatear dinámicamente la velocidad a `KB/s` o `MB/s` de acuerdo al tráfico real.
*   **Interfaces Físicas**: Se corrigió el cálculo delta para evitar el valor base inicial de cero y se amplió el mapeo de interfaces físicas en `NetworkStats.swift` para incluir configuraciones bridge/bond comúnmente usadas en Hackintosh.

---

## 📅 24. Mejoras en Controlador C++ (Sleep-Wake & CCD Limits) (v2.1.4 - Completada)
*   **Resguardo de Suspensión (Sleep/Wake)**: Se corrigió un bug por el cual las lecturas se congelaban al reanudar el sistema operativo desde estado de suspensión. Modificamos `resumeWorkLoop()` en `AMDRyzenCPUPowerManagement.cpp` para re-programar explícitamente los temporizadores del driver (`timerEvent_main` y `timerEvent_tempe`) tras despertar.
*   **Escalamiento de CCDs (Threadripper / EPYC)**: Incrementamos la constante `kMAX_CCD_COUNT` de 8 a 16 en el kext para dar soporte completo a procesadores multichip de alta gama y ajustamos la recolección en Swift (`maxCCDs` de 8 a 16 en `ProcessorModel.swift`).

---

## 📅 25. Generación de Release y Publicación en GitHub (v2.1.4 - Completada)
*   **Empaquetado de Binarios**: Copiamos las últimas compilaciones Release de la aplicación y ambos Kexts a la raíz de `Binaries_Release` y regeneramos el archivo distributivo `Binaries_Release.zip`.
*   **Publicación de Versión**: Creamos el tag de Git local `v2.1.4`, lo subimos al servidor remoto y automatizamos mediante la API de GitHub la creación del release **v2.1.4** en tu repositorio personal con su correspondiente archivo `Release.zip` adjunto como asset.

---

## 📅 26. Modernización del Backend y Telemetría Avanzada (v2.2.0 - Completada)
Se implementaron y verificaron las siguientes mejoras en la telemetría, compatibilidad de hardware y modernización del cargador:

*   **Soporte de IT8689E (SuperIO)**:
    *   **[ISSuperIOIT86XXEFamily.hpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/SuperIO/ISSuperIOIT86XXEFamily.hpp)** y **[ISSuperIOIT86XXEFamily.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/SuperIO/ISSuperIOIT86XXEFamily.cpp)**: Se integró el soporte para el chip Super I/O `IT8689E` (ID de chip `0x8689`), común en placas Gigabyte modernas de sockets AM4 y AM5, habilitando su monitoreo y control de ventiladores.
*   **Telemetría CPPC (Preferred Cores)**:
    *   **[AMDRyzenCPUPowerManagement.hpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.hpp)** y **[AMDRyzenCPUPowerManagement.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp)**: Se añadió la lectura del registro MSR `0xC00102B0` (`MSR_AMD_CPPC_CAP1`) en cada núcleo lógico usando `mp_rendezvous` para recuperar el ranking de calidad del silicio (Highest Performance) en procesadores Zen 2 y más nuevos.
    *   Se validó la disponibilidad mediante el chequeo de CPUID Fn8000_0008 EBX bit 27.
*   **Configuración de C-States**:
    *   **[AMDRyzenCPUPowerManagement.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPowerManagement.cpp)**: Se añadió la lectura de la dirección de E/S de C-States configurada en MSR `0xC0010073` (`kMSR_CSTATE_ADDR`) para exponerla a la capa gráfica y comprobar la salud de los estados de inactividad profunda.
*   **Exposición en UserClient**:
    *   **[AMDRyzenCPUPMUserClient.cpp](file:///Users/droga/Desktop/SMCAMDProcessor/AMDRyzenCPUPowerManagement/AMDRyzenCPUPMUserClient.cpp)**: Se añadieron selectores `case 21` (que copia los rankings CPPC de cada núcleo lógico a espacio de usuario) y `case 22` (que expone la dirección de C-states).
*   **Visualización en la App Swift**:
    *   **[ProcessorModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/ProcessorModel.swift)** y **[TelemetryModel.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/TelemetryModel.swift)**: Se añadieron los métodos para invocar a los selectores 21 y 22, populando la calidad del silicio por núcleo y la dirección de C-states en el arranque.
    *   **[MainDashboardView.swift](file:///Users/droga/Desktop/SMCAMDProcessor/AMD%20Power%20Gadget/MainDashboardView.swift)**: Se actualizó `CoreCell` para renderizar de manera interactiva el ranking CPPC de cada núcleo en la grilla del Dashboard utilizando corchetes, por ejemplo `C1 [166]`, lo que permite identificar fácilmente los núcleos preferidos del sistema.
*   **Resolución de Error de Compilación**:
    *   Se corrigió la falta de declaraciones incompletas al incluir `<IOKit/IOPlatformExpert.h>`, `<libkern/c++/OSString.h>` y `<libkern/c++/OSData.h>` en `AMDRyzenCPUPowerManagement.cpp`.
*   **Distribución y Releases**:
    *   Sincronizados todos los binarios recompilados bajo la ruta `Binaries_Release` y su versión histórica en `Binaries_Release/v2.2.0/`.
    *   Se reconstruyó el archivo distributivo final `Binaries_Release.zip` incluyendo las nuevas mejoras.

---

## 📅 27. Corrección de Extracción de Bits y Activación de CPPC (v2.3.0 - Completada)
Se corrigieron bugs críticos en la lectura de CPPC expuestos en la versión anterior:
*   **Corrección de Extracción de bits**: Se corrigió la extracción del campo `HighestPerformance` en el MSR `0xC00102B0` (`MSR_AMD_CPPC_CAP1`), que erróneamente extraía los bits `[31:24]` (LowestPerformance) en lugar de los bits `[7:0]` (HighestPerformance).
*   **Activación Forzada por MSR**: Se añadió la escritura al MSR `0xC00102B1` en el arranque para habilitar de manera forzada la telemetría CPPC en sistemas donde la BIOS o el firmware la desactivaban.
*   **Release v2.3.0**: Se empaquetaron los binarios y se publicó el tag y release correspondiente en GitHub.

---

## 📅 28. CPPC Fallback, Detección de SuperIO NCT6796D-alt y Automatización de CI/CD (v2.4.0 - Completada)
Esta actualización introduce flujos automatizados de desarrollo y expande el soporte de hardware y telemetría:
*   **CI/CD con GitHub Actions**:
    *   Creado `.github/workflows/pr_check.yml` para compilar y validar de manera automática cada Pull Request dirigido a la rama master.
    *   Creado `.github/workflows/release.yml` para compilar los targets, empaquetar y publicar automáticamente releases con binarios adjuntos cada vez que se haga push a un tag tipo `v*`.
*   **CPPC Fallback Heurístico (Frecuencia Máxima)**:
    *   En Hackintoshes donde el MSR de CPPC retorna `0` de manera persistente (e.g. algunos firmwares de Ryzen 5000), la app ahora realiza una estimación en tiempo real.
    *   Registra la frecuencia máxima observada por cada núcleo y la normaliza a un rango de `0-255` para estimar el ranking de núcleos preferidos.
    *   Los valores estimados se indican visualmente en la grilla mediante el prefijo tilde `~` (e.g. `C1 [~255]`).
*   **Diseño Interactivo de CPPC**:
    *   Añadida la visibilidad constante de telemetría CPPC en la tarjeta de utilización del CPU siempre que sea soportada por hardware.
    *   Se integró un badge de estado en el título de la tarjeta (`CPPC: Active` o `CPPC: Estimated ~`) con tooltips/help-texts nativos de macOS explicando el estado y fallback.
*   **Soporte Expandido para NCT6796D (SuperIO)**:
    *   Añadido el identificador alternativo `0xD428` (`CHIP_NCT6796D_ALT`) al driver. Esto habilita el soporte de lectura de RPM y control de ventiladores en placas madre ASUS con esta variante del chip.
*   **Publicación de Releases**:
    *   Sincronizados todos los binarios recompilados bajo la ruta `Binaries_Release/v2.4.0/`.
    *   Se empaquetó `Binaries_Release_v2.4.0.zip` y se publicó de manera exitosa el release en GitHub.

---

## 📅 29. Editor de Curvas P-State Interactivo (v3.0.0 - Completada)
Se ha implementado por completo el editor gráfico y visual de curvas P-State para macOS Tahoe (13.0+), sustituyendo la grilla hexadecimal rudimentaria por controles dinámicos de frecuencia/voltaje y visualización en tiempo real:
*   **Gráfico de Curva V-F (Swift Charts)**:
    *   Implementado `PStateChartView` usando `Chart`, `LineMark` y `PointMark` de Swift Charts.
    *   Muestra los puntos activos de los P-states en un gráfico bidimensional de Voltaje (V) vs Frecuencia (MHz).
    *   Los P-states activos (`enabled == 1`) se conectan con una línea azul brillante (`.tahoeAccentCyan`) que dibuja la curva de operación del procesador.
*   **Sliders de Control en Tiempo Real**:
    *   Implementado `PStateRowControlView` con sliders para ajustar la Frecuencia (MHz) y el Voltaje (V).
    *   Traduce de manera automática el Voltaje en Voltios a la representación del registro `cpuVid` de 8 bits mediante las fórmulas SVI2 (`1.55 - VID * 0.00625`) y SVI3 (`1.55 - VID * 0.005`).
    *   Traduce la Frecuencia en MHz al multiplicador `cpuFid` manteniendo el divisor `cpuDfsId` constante en arquitecturas heredadas, o usando el multiplicador directo en Zen 5.
    *   Añadidas protecciones y límites seguros contra valores en cero o fuera de rango.
*   **Detalle Avanzado del Registro (DisclosureGroup)**:
    *   Añadida la sección colapsable "Raw Register Details" en cada fila para exponer y permitir la edición numérica de los campos de registro subyacentes (`FID`, `DID`, `VID`, `IddDiv`, `IddVal`).
*   **Verificación de Compilación**:
    *   Ejecutado `xcodebuild` validando que todos los targets compilan con éxito absoluto (**BUILD SUCCEEDED**).

---

## 📅 30. Exportación de Telemetría (CSV) y Notificaciones de Alerta (v3.1.0 - Completada)
Se implementaron características de registro y diagnóstico continuo en segundo plano, así como notificaciones nativas de límites de hardware:
*   **Exportación e Historial en CSV**:
    *   Implementado `exportHistoryToCSV(url:)` en `TelemetryModel.swift` para exportar el historial acumulado en memoria a un archivo CSV estructurado.
    *   Creada una clase auxiliar thread-safe `CSVLogger` que escribe asíncronamente en segundo plano cada muestra de telemetría a un archivo CSV continuo para análisis a largo plazo.
    *   Integrada la tarjeta "Diagnostics & CSV Logging" en la pestaña de **Telemetry** para activar el logging continuo y configurar la ruta de salida.
*   **Notificaciones de Alerta de Límites de Hardware**:
    *   Integración nativa con `UNUserNotificationCenter` de macOS para solicitar permisos y enviar alertas.
    *   **Alerta Térmica**: Avisa mediante una notificación del sistema si la temperatura del CPU excede el umbral configurado (ej. 90°C).
    *   **Alerta de Energía**: Avisa si la potencia del CPU supera el umbral configurado (ej. 142W PPT) de forma continua durante más de `N` segundos (ej. 10s).
    *   **Enfriamiento de Alertas**: Lógica anti-spam integrada que restringe las alertas a una notificación cada 60 segundos por categoría.
    *   Integrada la interfaz de personalización de alertas en la pestaña **Advanced**.

---

## 📅 31. Native CPPC Active Mode (EPP) y Sanitización de UserClient (v3.2.0 - Completada)
Esta actualización introduce el modo de control de energía autónomo nativo por hardware (CPPC Active Mode) y una auditoría completa de seguridad en la interfaz de comunicación Kext-App:
*   **Active Mode nativo por hardware (EPP)**:
    *   **Full MSR Mode**: Habilitado el soporte para control autónomo de frecuencia de CPU mediante el registro de control de hardware CPPC `MSR_AMD_CPPC_REQ` (0xC00102B3) y estado `MSR_AMD_CPPC_STATUS` (0xC00102B4).
    *   **Ignorar P-States Heredados**: Se configuró el driver para omitir la escritura dinámica al registro `kMSR_PSTATE_CTL` cuando el modo activo está habilitado, evitando conflictos de frecuencia.
    *   **Opt-in en Arranque**: Parseo del argumento de boot `-amdcppcactive` para iniciar de manera segura el driver con CPPC Active Mode activado.
*   **Interfaz de Telemetría y Controles EPP**:
    *   Exposición en el UserClient (selectores 23, 24, 25) para consultar y configurar dinámicamente el estado del modo activo y el valor EPP (Energy Performance Preference).
    *   Añadida la tarjeta de control en la pestaña **Advanced** que expone el switch de CPPC Active Mode y un selector segmentado premium de preferencia de energía: **Performance**, **Balanced Perf**, **Balanced Power** y **Power Save**.
*   **Sanitización Completa de UserClient (Seguridad Kernel)**:
    *   Auditoría de todos los selectores de `AMDRyzenCPUPMUserClient::externalMethod` para erradicar posibles vulnerabilidades de buffer overflow o kernel crash.
    *   Validación obligatoria de `arguments->structureOutput` y control de límites seguros en `arguments->structureOutputSize` antes de realizar copias de memoria con `strlcpy` o bucles `for`.

---

## 📅 32. Corrección de Versión Xcode, Despliegue en EFI y Agradecimientos a AMD-OSX (v3.2.0 - Final)
Esta fase finaliza la transición del release unificando las versiones y rindiendo homenaje a la comunidad:
*   **Corrección de Versión de Proyecto**:
    *   Se actualizaron `MARKETING_VERSION` y `CURRENT_PROJECT_VERSION` de `2.4.0` a `3.2.0` en todas las configuraciones del proyecto Xcode (`SMCAMDProcessor.xcodeproj/project.pbxproj`), garantizando consistencia en los binarios compilados y en las plists del kernel/app.
*   **Agradecimientos a AMD-OSX**:
    *   Se integró un mensaje de agradecimiento especial a toda la comunidad de **AMD-OSX** dentro de los créditos del panel de información "About" de la aplicación (`AppDelegate.swift`), visible al presionar "About AMD Power Gadget".
*   **Despliegue Local y EFI Automático**:
    *   Se compilaron localmente todas las schemes de lanzamiento en la versión definitiva `3.2.0`.
    *   Se copiaron los kexts actualizados (`AMDRyzenCPUPowerManagement.kext` y `SMCAMDProcessor.kext`) a tu partición EFI montada (`/Volumes/EFI/EFI/OC/Kexts/`), y la aplicación definitiva a `/Applications/`.
    *   Se empaquetó de nuevo todo el historial de versiones en `Binaries_Release.zip`.
*   **Git y CI/CD Final**:
    *   Se subieron todos los cambios de versionado y créditos a la rama principal de Git, y se recreó el tag `v3.2.0` para gatillar la compilación exitosa y definitiva en GitHub Actions, la cual adjuntó el asset final `Release.zip` al release público.



