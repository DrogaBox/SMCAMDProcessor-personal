//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct MenuBarPreview: View {
    let cfg: MenuBarConfig
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                // CPU Column
                if cfg.showCPU {
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "CPU")
                        
                        let maxFr = String(format: "%.1f", model.cpuFreqMaxGHz)
                        let avgFr = String(format: "%.1f", model.cpuFreqAvgGHz)
                        
                        if cfg.showMaxFreqOnly {
                            Text("\(maxFr)G")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(maxFr)Ghz").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("\(avgFr)Ghz").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: cfg.showMaxFreqOnly ? 48 : 56, alignment: .leading)
                }
                
                // Temp Column
                if cfg.showTemp {
                    let tempVal = model.cpuTempC
                    let cTemp = cfg.useFahrenheit ? (tempVal * 9.0 / 5.0 + 32.0) : tempVal
                    let isAlert = cfg.enableColorAlerts && tempVal >= Double(cfg.tempThreshold)
                    let tempColor = isAlert ? getSwiftUIColor(index: cfg.tempColorIdx) : Color.white
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "TMP")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(String(format: "C:%.0f\(cfg.useFahrenheit ? "F" : "º")", cTemp))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(tempColor)
                            
                            if cfg.showGPU && cfg.showGPUtemp {
                                let gpuTemp = model.gpuTempC
                                let gTemp = cfg.useFahrenheit ? (gpuTemp * 9.0 / 5.0 + 32.0) : gpuTemp
                                let gpuIsAlert = cfg.enableColorAlerts && gpuTemp >= Double(cfg.tempThreshold)
                                let gpuColor = gpuIsAlert ? getSwiftUIColor(index: cfg.tempColorIdx) : Color.white
                                Text(String(format: "G:%.0f\(cfg.useFahrenheit ? "F" : "º")", gTemp))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(gpuColor)
                            } else {
                                Text("—")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Power Column
                if cfg.showPower {
                    let cPwr = String(format: "C:%.0fW", model.cpuWatts)
                    let gPwr = cfg.showGPU && cfg.showGPUpwr ? String(format: "G:%.0fW", model.gpuPowerW) : ""
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "PWR")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(cPwr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            if !gPwr.isEmpty {
                                Text(gPwr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text("—").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Fan Column
                if cfg.showFanRPM {
                    let fanVal = model.fans.first?.rpm ?? 0
                    let fan = String(fanVal)
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "FAN")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if cfg.showGPU && cfg.showGPUfan {
                                let gFanStr = String(format: "G:%.0f", model.gpuFanRPM)
                                Text("C:\(fan)").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text(gFanStr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text(fan).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("RPM").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Memory Column
                if cfg.showMemory {
                    let memoryUsed = Double(model.sysInfo.ramGB) * model.ramUsagePct / 100.0
                    let used = String(format: "%.1fG", memoryUsed)
                    let totalMem = "\(model.sysInfo.ramGB)G"
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "MEM")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if cfg.showGPU && cfg.showGPUvram {
                                let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                let vramStr = String(format: "G:%.1fG", vramGB)
                                Text("S:\(used)").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text(vramStr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text(used).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text(totalMem).font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Network Column
                if cfg.showNetwork {
                    let arrowColor = getSwiftUIColor(index: cfg.netColorIdx)
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "NET")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 1) {
                                Text("↑").font(.system(size: 9, weight: .bold)).foregroundColor(arrowColor)
                                Text(formatSpeed(model.netUploadMBps)).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            }
                            HStack(spacing: 1) {
                                Text("↓").font(.system(size: 9, weight: .bold)).foregroundColor(arrowColor)
                                Text(formatSpeed(model.netDownloadMBps)).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 68, alignment: .leading)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Color.black.opacity(0.35))
            .cornerRadius(4)
        }
    }
    
    private func getSwiftUIColor(index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return .blue
        case 2: return .orange
        case 3: return .red
        case 4: return .purple
        case 5: return .pink
        case 6: return Color(red: 0.18, green: 0.80, blue: 0.80) // Teal
        default: return .green
        }
    }
}

// MARK: - Menu Bar Config Tab
struct MenuBarConfigView: View {
    @ObservedObject var model: TelemetryModel
    @State private var cfg = MenuBarConfig.shared
    @State private var needsRestart = false
    @State private var refreshToggle = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Menu Bar Layout")
                Text("Choose which items appear in the menu bar. Changes apply immediately.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Show CPU", detail: "Frequency column (max/avg GHz)", isOn: .init(
                    get: { cfg.showCPU }, set: { cfg.showCPU = $0; notify() }
                ), accent: .tahoeAccentCyan) { _ in }

                if cfg.showCPU {
                    ToggleRow(label: "Show Max Freq Only", detail: "Single large value instead of max/avg stack", isOn: .init(
                        get: { cfg.showMaxFreqOnly }, set: { cfg.showMaxFreqOnly = $0; notify() }
                    ), accent: .tahoeAccentCyan.opacity(0.8), indented: true) { _ in }
                }

                ToggleRow(label: "Show Temperature", detail: "CPU temp + optional GPU temp", isOn: .init(
                    get: { cfg.showTemp }, set: { cfg.showTemp = $0; notify() }
                ), accent: .tahoeAccentOrange) { _ in }

                if cfg.showTemp {
                    ToggleRow(label: "Use Fahrenheit", detail: "Convert temperature values from Celsius to Fahrenheit", isOn: .init(
                        get: { cfg.useFahrenheit }, set: { cfg.useFahrenheit = $0; notify() }
                    ), accent: .tahoeAccentOrange.opacity(0.8), indented: true) { _ in }
                }

                ToggleRow(label: "Show Power", detail: "CPU watts + optional GPU watts", isOn: .init(
                    get: { cfg.showPower }, set: { cfg.showPower = $0; notify() }
                ), accent: .tahoeAccentGreen) { _ in }

                Divider().background(Color.tahoeCardBorder)

                SectionTitle("Extra Items")
                Text("Additional telemetry for the menu bar.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Show Fan RPM", detail: "First fan speed in RPM", isOn: .init(
                    get: { cfg.showFanRPM }, set: { cfg.showFanRPM = $0; notify() }
                ), accent: .tahoeAccentBlue) { _ in }

                if cfg.showFanRPM {
                    HStack {
                        Text("Fan Number").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.fanIndex },
                            set: { cfg.fanIndex = $0; notify() }
                        )) {
                            ForEach(0..<max(1, model.fans.count), id: \.self) { idx in
                                Text(LocalizedStringKey("Fan \(idx + 1)")).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                }

                ToggleRow(label: "Show Memory", detail: "Used memory in GB", isOn: .init(
                    get: { cfg.showMemory }, set: { cfg.showMemory = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show Network", detail: "Real-time upload / download speed (↑/↓)", isOn: .init(
                    get: { cfg.showNetwork }, set: { cfg.showNetwork = $0; notify() }
                ), accent: .tahoeAccentRed) { _ in }

                if cfg.showNetwork {
                    HStack {
                        Text("Arrow Color").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.netColorIdx },
                            set: { cfg.netColorIdx = $0; notify() }
                        )) {
                            Text("Green").tag(0)
                            Text("Blue").tag(1)
                            Text("Orange").tag(2)
                            Text("Red").tag(3)
                            Text("Purple").tag(4)
                            Text("Pink").tag(5)
                            Text("Teal").tag(6)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("GPU Items")
                Text("GPU data is shown inside Temp, Power, Memory and Fan columns when enabled.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Show GPU Temp", detail: "G:XX°C in Temp column", isOn: .init(
                    get: { cfg.showGPUtemp }, set: { cfg.showGPUtemp = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show GPU Power", detail: "G:XXW in Power column", isOn: .init(
                    get: { cfg.showGPUpwr }, set: { cfg.showGPUpwr = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show GPU VRAM", detail: "G:X.XG in Memory column", isOn: .init(
                    get: { cfg.showGPUvram }, set: { cfg.showGPUvram = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show GPU Fan Speed", detail: "G:XXXX in Fan column", isOn: .init(
                    get: { cfg.showGPUfan }, set: { cfg.showGPUfan = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Styles & Themes")
                Text("Customize the visual appearance of the menu bar items.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Dynamic Color Alerts", detail: "Color values based on temperature and load status", isOn: .init(
                    get: { cfg.enableColorAlerts }, set: { cfg.enableColorAlerts = $0; notify() }
                ), accent: .tahoeAccentRed) { _ in }

                if cfg.enableColorAlerts {
                    HStack {
                        Text("Temp Alert Color").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.tempColorIdx },
                            set: { cfg.tempColorIdx = $0; notify() }
                        )) {
                            Text("Green").tag(0)
                            Text("Blue").tag(1)
                            Text("Orange").tag(2)
                            Text("Red").tag(3)
                            Text("Purple").tag(4)
                            Text("Pink").tag(5)
                            Text("Teal").tag(6)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                    
                    HStack {
                        Text(LocalizedStringKey("Temperature Alert Limit")).font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        TempThresholdField(value: .init(
                            get: { cfg.tempThreshold },
                            set: { cfg.tempThreshold = $0; notify() }
                        ))
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)

                    HStack {
                        Text(LocalizedStringKey("Menu Bar Temperature Presets")).font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        TextField("Ej: 30, 40, 50...", text: .init(
                            get: { cfg.tempPresetList },
                            set: { cfg.tempPresetList = $0; notify() }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.tahoeAccentCyan)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 250)
                        .padding(.vertical, 4).padding(.horizontal, 8)
                        .background(Color.tahoeBackground.opacity(0.4))
                        .cornerRadius(6)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                }



                if needsRestart {
                    TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.3)) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.circle").foregroundColor(.tahoeAccentOrange)
                            Text("Restart the app to fully apply width changes.").font(.system(size: 12)).foregroundColor(.tahoeText)
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Preview")
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Menu Bar Preview:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tahoeSubtext)
                    
                    MenuBarPreview(cfg: cfg, model: model)
                        .id(refreshToggle)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.tahoeBackground.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                        )
                    
                    Text("Estimated Width: \(Int(cfg.totalWidth))pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.tahoeSubtext)
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
    }

    private func notify(widthChanged: Bool = true) {
        cfg = MenuBarConfig()
        refreshToggle.toggle()
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
        if widthChanged {
            needsRestart = true
        }
    }
}
