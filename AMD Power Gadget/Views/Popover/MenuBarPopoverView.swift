//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    /// Live theme (same store as RTL Wi-Fi Tahoe / Themes tab)
    @AppStorage("app_theme_preset") private var themePreset: String = AppTheme.tahoe.rawValue
    @AppStorage("custom_hex_card") private var customCardHex: String = "#16213E"
    @AppStorage("custom_hex_cyan") private var customCyanHex: String = "#4CC9F0"
    @AppStorage("custom_hex_orange") private var customOrangeHex: String = "#FF8C00"
    @AppStorage("custom_hex_green") private var customGreenHex: String = "#00FF7F"
    @AppStorage("custom_hex_purple") private var customPurpleHex: String = "#A020F0"
    @AppStorage("pop_processApp") private var processApp: String = "Activity Monitor"
    
    private var cfg: MenuBarConfig { MenuBarConfig.shared }
    private var theme: AppTheme { AppTheme.current }
    
    @State private var currentTab: PopoverTab = .telemetry



    @ViewBuilder
    private func telemetryTabContent() -> some View {
                // Dynamic Ordered Resource Widgets
                let rings = cfg.popoverRingOrder.split(separator: ",").map(String.init)
                
                // 1. Render Rings Row (Horizontal HStack) if any are style == 0
                let showRingsRow = rings.contains(where: { ring in
                    if ring == "cpu" && cfg.popoverShowCPU && cfg.popoverCPUStyle == 0 { return true }
                    if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 0 { return true }
                    if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 0 { return true }
                    if ring == "gpu" && cfg.popoverShowGPURing && cfg.popoverGPUStyle == 0 { return true }
                    if ring == "vram" && cfg.popoverShowVRAM && cfg.popoverGPUStyle == 0 { return true }
                    return false
                })
                
                if showRingsRow {
                    Divider().background(theme.cardBorder)
                    
                    HStack(spacing: 14) {
                        ForEach(rings, id: \.self) { ring in
                            if ring == "cpu" && cfg.popoverShowCPU && cfg.popoverCPUStyle == 0 {
                                // CPU Ring
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                            .frame(width: 46, height: 46)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.cpuLoadAvg / 100.0))))
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [theme.accentCyan, theme.accentCyan.opacity(0.55)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                            )
                                            .rotationEffect(Angle(degrees: -90))
                                            .frame(width: 46, height: 46)
                                        
                                        VStack(spacing: 0) {
                                            Text(String(format: "%.0f%%", model.cpuLoadAvg))
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(theme.text)
                                            if cfg.popoverRingShowTemp {
                                                Text(String(format: "%.0f°", model.cpuTempC))
                                                    .font(.system(size: 7.5, weight: .semibold))
                                                    .foregroundColor(theme.subtext)
                                            }
                                        }
                                    }
                                    if cfg.popoverRingShowLabels {
                                        Text("CPU")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(theme.subtext)
                                    }
                                }
                            } else if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 0 {
                                // RAM Ring
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                            .frame(width: 46, height: 46)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.ramUsagePct / 100.0))))
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [theme.accentOrange, theme.accentOrange.opacity(0.55)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                            )
                                            .rotationEffect(Angle(degrees: -90))
                                            .frame(width: 46, height: 46)
                                        
                                        VStack(spacing: 0) {
                                            Text(String(format: "%.0f%%", model.ramUsagePct))
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(theme.text)
                                            if cfg.popoverRingShowTemp {
                                                let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                                                Text(String(format: "%.0fG", usedGB))
                                                    .font(.system(size: 7.5, weight: .semibold))
                                                    .foregroundColor(theme.subtext)
                                            }
                                        }
                                    }
                                    if cfg.popoverRingShowLabels {
                                        Text("RAM")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(theme.subtext)
                                    }
                                }
                            } else if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 0 {
                                // Disk Ring
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                            .frame(width: 46, height: 46)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.diskUsagePct / 100.0))))
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [theme.accentGreen, theme.accentGreen.opacity(0.55)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                            )
                                            .rotationEffect(Angle(degrees: -90))
                                            .frame(width: 46, height: 46)
                                        
                                        VStack(spacing: 0) {
                                            Text(String(format: "%.0f%%", model.diskUsagePct))
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(theme.text)
                                            if cfg.popoverRingShowTemp {
                                                Text("SSD")
                                                    .font(.system(size: 7.5, weight: .semibold))
                                                    .foregroundColor(theme.subtext)
                                            }
                                        }
                                    }
                                    if cfg.popoverRingShowLabels {
                                        Text("DISK")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(theme.subtext)
                                    }
                                }
                            } else if ring == "gpu" && cfg.popoverShowGPURing && cfg.popoverGPUStyle == 0 {
                                // GPU Ring
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                            .frame(width: 46, height: 46)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.gpuLoadPct / 100.0))))
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [theme.accentPurple, theme.accentPurple.opacity(0.55)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                            )
                                            .rotationEffect(Angle(degrees: -90))
                                            .frame(width: 46, height: 46)
                                        
                                        VStack(spacing: 0) {
                                            Text(String(format: "%.0f%%", model.gpuLoadPct))
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(theme.text)
                                            if cfg.popoverRingShowTemp {
                                                Text(String(format: "%.0f°", model.gpuTempC))
                                                    .font(.system(size: 7.5, weight: .semibold))
                                                    .foregroundColor(theme.subtext)
                                            }
                                        }
                                    }
                                    if cfg.popoverRingShowLabels {
                                        Text("GPU")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(theme.subtext)
                                    }
                                }
                            } else if ring == "vram" && cfg.popoverShowVRAM && cfg.popoverGPUStyle == 0 {
                                // VRAM Ring
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                            .frame(width: 46, height: 46)
                                        let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                        let recommendedSize = MTLCreateSystemDefaultDevice()?.recommendedMaxWorkingSetSize
                                        let totalVramBytes = Double(recommendedSize ?? 17179869184)
                                        let totalVramGB = totalVramBytes / 1073741824.0
                                        let vramPct = (vramGB / totalVramGB) * 100.0
                                        Circle()
                                            .trim(from: 0, to: CGFloat(min(1.0, max(0.0, vramPct / 100.0))))
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [theme.accentPurple.opacity(0.9), theme.accentOrange.opacity(0.75)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                            )
                                            .rotationEffect(Angle(degrees: -90))
                                            .frame(width: 46, height: 46)
                                        
                                        VStack(spacing: 0) {
                                            Text(String(format: "%.0f%%", vramPct))
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(theme.text)
                                            if cfg.popoverRingShowTemp {
                                                Text(String(format: "%.0fG", vramGB))
                                                    .font(.system(size: 7.5, weight: .semibold))
                                                    .foregroundColor(theme.subtext)
                                            }
                                        }
                                    }
                                    if cfg.popoverRingShowLabels {
                                        Text("VRAM")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(theme.subtext)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 2. Render Vertical List for Bars and Sparklines (style > 0 or sparkline enabled)
                let vertItems = cfg.popoverVerticalOrder.split(separator: ",").map(String.init)
                let showLinearOrGraphs = vertItems.contains(where: { ring in
                    if ring == "cpu" && cfg.popoverShowCPU && (cfg.popoverCPUStyle == 1 || cfg.popoverShowCPUSparkline || cfg.popoverShowCores) { return true }
                    if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 1 { return true }
                    if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 1 { return true }
                    if ring == "gpu" && ((cfg.popoverShowGPURing && (cfg.popoverGPUStyle == 1 || cfg.popoverShowGPUSparkline)) || cfg.popoverShowGPU) { return true }
                    if ring == "vram" && cfg.popoverShowVRAM && cfg.popoverGPUStyle == 1 { return true }
                    if ring == "net" && cfg.popoverShowNetwork { return true }
                    if ring == "proc" && cfg.popoverShowProcesses { return true }
                    return false
                })
                
                if showLinearOrGraphs {
                    Divider().background(theme.cardBorder)
                    
                    VStack(spacing: 10) {
                        ForEach(vertItems, id: \.self) { ring in
                            if ring == "cpu" && cfg.popoverShowCPU {
                                if cfg.popoverCPUStyle == 1 {
                                    let cpuTempStr = cfg.popoverRingShowTemp ? String(format: " • %.0f°C", model.cpuTempC) : ""
                                    LinearProgressBar(
                                        label: "CPU",
                                        pct: model.cpuLoadAvg,
                                        detailText: String(format: "%.0f%%%@", model.cpuLoadAvg, cpuTempStr),
                                        color: theme.accentCyan
                                    )
                                }
                                if cfg.popoverShowCPUSparkline {
                                    MiniSparkline(
                                        label: "CPU Temp",
                                        currentVal: String(format: "%.0f°C", model.cpuTempC),
                                        color: theme.accentCyan,
                                        data: model.history,
                                        value: { $0.cpuTempC },
                                        filterZeros: true
                                    )
                                }
                                if cfg.popoverShowCores {
                                    PopoverCoreGridView(model: model)
                                        .padding(.top, 2)
                                }
                            } else if ring == "ram" && cfg.popoverShowRAM {
                                if cfg.popoverRAMStyle == 1 {
                                    let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                                    let ramStr = cfg.popoverRingShowTemp ? String(format: " • %.1fG", usedGB) : ""
                                    LinearProgressBar(
                                        label: "RAM",
                                        pct: model.ramUsagePct,
                                        detailText: String(format: "%.0f%%%@", model.ramUsagePct, ramStr),
                                        color: .orange
                                    )
                                }
                            } else if ring == "disk" && cfg.popoverShowDisk {
                                if cfg.popoverDiskStyle == 1 {
                                    let diskStr = cfg.popoverRingShowTemp ? " • SSD" : ""
                                    LinearProgressBar(
                                        label: "DISK",
                                        pct: model.diskUsagePct,
                                        detailText: String(format: "%.0f%%%@", model.diskUsagePct, diskStr),
                                        color: .blue
                                    )
                                }
                            } else if ring == "gpu" {
                                if cfg.popoverShowGPURing {
                                    if cfg.popoverGPUStyle == 1 {
                                        let gpuTempStr = cfg.popoverRingShowTemp ? String(format: " • %.0f°C", model.gpuTempC) : ""
                                        LinearProgressBar(
                                            label: "GPU",
                                            pct: model.gpuLoadPct,
                                            detailText: String(format: "%.0f%%%@", model.gpuLoadPct, gpuTempStr),
                                            color: theme.accentPurple
                                        )
                                    }
                                    if cfg.popoverShowGPUSparkline {
                                        MiniSparkline(
                                            label: "GPU Temp",
                                            currentVal: String(format: "%.0f°C", model.gpuTempC),
                                            color: theme.accentPurple,
                                            data: model.history,
                                            value: { $0.gpuTempC },
                                            filterZeros: true
                                        )
                                        .padding(.top, 2)
                                    }
                                }
                                if cfg.popoverShowGPU {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 10))
                                                .foregroundColor(theme.accentPurple)
                                                .frame(width: 14)
                                            Text(model.sysInfo.gpuModel.isEmpty || model.sysInfo.gpuModel == "Unknown" ? "Radeon GPU" : model.sysInfo.gpuModel)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(theme.text)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Spacer()
                                            if model.gpuTempC > 0 {
                                                Text(String(format: "%.0f°C • %.0fW", model.gpuTempC, model.gpuPowerW))
                                                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(theme.text.opacity(0.9))
                                            } else {
                                                Text("Inactive")
                                                    .font(.system(size: 9.5, weight: .semibold))
                                                    .foregroundColor(theme.subtext.opacity(0.9))
                                            }
                                        }
                                        if model.gpuTempC > 0 {
                                            HStack {
                                                Spacer()
                                                let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                                let fanRPMStr = model.gpuFanRPM > 0 ? String(format: " • %.0f RPM", model.gpuFanRPM) : ""
                                                Text(String(format: "VRAM: %.2fG%@", vramGB, fanRPMStr))
                                                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                                    .foregroundColor(theme.subtext)
                                            }
                                        }
                                    }
                                }
                            } else if ring == "vram" && cfg.popoverShowVRAM {
                                if cfg.popoverGPUStyle == 1 {
                                    let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                    let recommendedSize = MTLCreateSystemDefaultDevice()?.recommendedMaxWorkingSetSize
                                    let totalVramBytes = Double(recommendedSize ?? 17179869184)
                                    let totalVramGB = totalVramBytes / 1073741824.0
                                    let vramPct = (vramGB / totalVramGB) * 100.0
                                    let vramStr = cfg.popoverRingShowTemp ? String(format: " • %.2fG", vramGB) : ""
                                    LinearProgressBar(
                                        label: "VRAM",
                                        pct: vramPct,
                                        detailText: String(format: "%.0f%%%@", vramPct, vramStr),
                                        color: theme.accentPurple.opacity(0.8)
                                    )
                                }
                            } else if ring == "net" && cfg.popoverShowNetwork {
                                Button(action: {
                                    let task = Process()
                                    task.launchPath = "/usr/bin/open"
                                    task.arguments = ["/System/Library/PreferencePanes/Network.prefPane"]
                                    do {
                                        try task.run()
                                    } catch {
                                        NSLog("Failed to open Network preferences: \(error.localizedDescription)")
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.arrow.down")
                                                .font(.system(size: 9))
                                                .foregroundColor(.green)
                                                .frame(width: 14)
                                            Text("Network")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(theme.text)
                                            Spacer()
                                            Text("↓ \(formatSpeed(model.netDownloadMBps))  ↑ \(formatSpeed(model.netUploadMBps))")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundColor(theme.text.opacity(0.85))
                                        }
                                        
                                        if cfg.popoverShowNetSparkline {
                                            MiniSparkline(
                                                label: "Net Speed",
                                                currentVal: formatSpeed(model.netDownloadMBps + model.netUploadMBps),
                                                color: .green,
                                                data: model.history,
                                                value: { $0.netDownloadMBps + $0.netUploadMBps }
                                            )
                                            .padding(.top, 2)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            } else if ring == "proc" && cfg.popoverShowProcesses {
                                Button(action: {
                                    let task = Process()
                                    task.launchPath = "/usr/bin/open"
                                    task.arguments = ["-a", processApp]
                                    do {
                                        try task.run()
                                    } catch {
                                        NSLog("Failed to open \(processApp): \(error.localizedDescription)")
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("Top Processes")
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(theme.subtext)
                                            Spacer()
                                            Image(systemName: "list.bullet")
                                                .font(.system(size: 8))
                                                .foregroundColor(theme.subtext.opacity(0.9))
                                        }
                                        .padding(.bottom, 2)
                                        
                                        if model.topProcesses.isEmpty {
                                            HStack {
                                                Spacer()
                                                Text("Loading...")
                                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                                    .foregroundColor(theme.subtext.opacity(0.9))
                                                    .padding(.vertical, 4)
                                                Spacer()
                                            }
                                        } else {
                                            ForEach(model.topProcesses.prefix(5)) { proc in
                                                HStack {
                                                    Text(proc.name)
                                                        .font(.system(size: 9.5, weight: .semibold))
                                                        .foregroundColor(theme.text.opacity(0.9))
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    Spacer()
                                                    Text(String(format: "%.1f%%", proc.cpuUsage))
                                                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                                        .foregroundColor(proc.cpuUsage > 50 ? theme.accentOrange : theme.subtext)
                                                }
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .frame(height: 95)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
    }

    var body: some View {
        // Touch custom hex so body re-evaluates when editor changes tokens
        let _ = (themePreset, customCardHex, customCyanHex, customOrangeHex, customGreenHex, customPurpleHex)
        VStack(spacing: 12) {
            // Header Section — RTL-style glass chrome
            VStack(spacing: 4) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu.fill")
                            .foregroundColor(theme.accentCyan)
                            .font(.system(size: 13, weight: .bold))
                        HStack(spacing: 0) {
                            Text("AMD Power ")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(theme.text)
                            Text("Gadget")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(theme.accentCyan)
                        }
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .minimumScaleFactor(0.8)
                    }
                    Spacer()
                    
                    // Compact Uptime
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                        Text(model.systemUptimeFormatted)
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(theme.subtext)
                    .padding(.trailing, 4)
                    
                    // Compact Battery / AC
                    if model.hasBattery {
                        HStack(spacing: 2) {
                            Image(systemName: model.batteryIsCharging ? "battery.100.bolt" : "battery.100")
                            Text("\(model.batteryPercentage)%")
                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.subtext)
                        .padding(.trailing, 6)
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "powerplug")
                            Text("AC")
                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.subtext)
                        .padding(.trailing, 6)
                    }

                    Button(action: {
                        MenuBarConfig.shared.popoverPinOpen.toggle()
                        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
                    }) {
                        Image(systemName: MenuBarConfig.shared.popoverPinOpen ? "pin.fill" : "pin")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MenuBarConfig.shared.popoverPinOpen ? theme.accentGreen : theme.subtext)
                    }
                    .buttonStyle(.plain)
                    .help("Pin Popover Open")
                }
                
                HStack {
                    let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.17.0"
                    let kextVer = model.sysInfo.kextVersion.isEmpty ? "N/A" : model.sysInfo.kextVersion
                    
                    Text("App: v\(appVer) · \(theme.localizedName)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.subtext)
                    Spacer()
                    Text("Kext: v\(kextVer)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.subtext)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Custom Segmented Picker
            HStack(spacing: 0) {
                PopoverTabButton(title: "Telemetry", icon: "chart.xyaxis.line", tab: .telemetry, currentTab: $currentTab, theme: theme)
                PopoverTabButton(title: "Perfiles", icon: "bolt.fill", tab: .profiles, currentTab: $currentTab, theme: theme)
                PopoverTabButton(title: "Settings", icon: "gearshape.fill", tab: .settings, currentTab: $currentTab, theme: theme)
            }
            .padding(4)
            .background(theme.cardBorder.opacity(0.4))
            .cornerRadius(8)
            .padding(.horizontal, 12)

            if currentTab == .telemetry {
                telemetryTabContent()
            } else if currentTab == .profiles {
                PopoverProfilesView()
            } else if currentTab == .settings {
                PopoverSettingsView()
            }

            Divider().background(theme.cardBorder)

            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    ViewController.launch(forceFocus: true)
                    NotificationCenter.default.post(name: .init("CloseMenuBarPopover"), object: nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 9.5))
                        Text("Open Dashboard")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(theme.cardBorder.opacity(0.6))
                    .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 9.5))
                        Text("Quit")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(theme.accentRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(theme.accentRed.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(theme.accentRed.opacity(0.35), lineWidth: 1))
                    .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 340)
        .fixedSize(horizontal: true, vertical: true)
        .background(
            ZStack {
                theme.background.opacity(0.92)
                VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow, state: .active, cornerRadius: 14)
                    .opacity(theme.glassOpacity)
            }
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .edgesIgnoringSafeArea(.all)
        .id(themePreset) // force rebuild when theme changes
    }
}
