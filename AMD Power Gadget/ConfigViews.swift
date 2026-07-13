//
//  ConfigViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Config Views
//

import SwiftUI

struct PopoverConfigView: View {
    @ObservedObject var model: TelemetryModel
    @State private var cfg = MenuBarConfig.shared
    @State private var ringItems: [RingOrderItem] = []
    @State private var verticalItems: [RingOrderItem] = []
    @AppStorage("app_theme_preset") private var themePreset: String = AppTheme.tahoe.rawValue

    struct RingOrderItem: Identifiable, Equatable {
        let id: String
        let name: String
        let color: Color
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Popover Theme")
                Text("Same presets as RTL Wi-Fi Tahoe (and Themes & Appearance). Applies to the menu bar popover and main window.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)
                ThemeSelectorGrid()
                    .id(themePreset)

                SectionTitle("Popover General Settings")
                Text("Customize the behavior and visibility of the menu bar popover.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Enable Popover Menu", detail: "Left-click shows interactive popover instead of classic menu", isOn: .init(
                    get: { cfg.enablePopover }, set: { cfg.enablePopover = $0; notify(widthChanged: false) }
                ), accent: .tahoeAccentCyan) { _ in }

                if cfg.enablePopover {
                    Divider().background(Color.tahoeCardBorder)
                    
                    SectionTitle("Horizontal Rings Order")
                    Text("Arrange the order of circular rings displayed in the top row of the popover.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(ringItems) { item in
                            let index = ringItems.firstIndex(where: { $0.id == item.id }) ?? 0
                            HStack {
                                Circle().fill(item.color).frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                Button(action: { moveRingUp(index: index) }) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .disabled(index == 0)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(index == 0 ? .gray.opacity(0.3) : .tahoeAccentCyan)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(4)
                                
                                Button(action: { moveRingDown(index: index) }) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .disabled(index == ringItems.count - 1)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(index == ringItems.count - 1 ? .gray.opacity(0.3) : .tahoeAccentCyan)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(4)
                            }
                            .padding(.vertical, 6).padding(.horizontal, 12)
                            .background(Color.tahoeCard)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                            .cornerRadius(8)
                        }
                    }

                    Divider().background(Color.tahoeCardBorder)
                    
                    SectionTitle("Vertical Charts & Info Order")
                    Text("Arrange the vertical order of progress bars, sparklines, and list charts in the popover.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(verticalItems) { item in
                            let index = verticalItems.firstIndex(where: { $0.id == item.id }) ?? 0
                            HStack {
                                Circle().fill(item.color).frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                Button(action: { moveVerticalUp(index: index) }) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .disabled(index == 0)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(index == 0 ? .gray.opacity(0.3) : .tahoeAccentCyan)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(4)
                                
                                Button(action: { moveVerticalDown(index: index) }) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .disabled(index == verticalItems.count - 1)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(index == verticalItems.count - 1 ? .gray.opacity(0.3) : .tahoeAccentCyan)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(4)
                            }
                            .padding(.vertical, 6).padding(.horizontal, 12)
                            .background(Color.tahoeCard)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                            .cornerRadius(8)
                        }
                    }

                    Divider().background(Color.tahoeCardBorder)

                    SectionTitle("Widget Selection & Display Style")
                    Text("Select which metrics are shown and choose their visualization style.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    VStack(spacing: 12) {
                        // CPU style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowCPU },
                                    set: { cfg.popoverShowCPU = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("CPU Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowCPU {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverCPUStyle },
                                        set: { cfg.popoverCPUStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks CPU utilization average and core temperature.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                            if cfg.popoverShowCPU {
                                Divider().background(Color.white.opacity(0.1)).padding(.vertical, 2)
                                Toggle(isOn: .init(
                                    get: { cfg.popoverShowCPUSparkline },
                                    set: { cfg.popoverShowCPUSparkline = $0; notify(widthChanged: false) }
                                )) {
                                    Text("Show Temperature Sparkline Graph below")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.tahoeText)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan))
                                
                                Toggle(isOn: .init(
                                    get: { cfg.popoverShowCores },
                                    set: { cfg.popoverShowCores = $0; notify(widthChanged: false) }
                                )) {
                                    Text("Show Per-Core Utilization Grid below")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.tahoeText)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan))
                            }
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // RAM style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowRAM },
                                    set: { cfg.popoverShowRAM = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("RAM Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowRAM {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverRAMStyle },
                                        set: { cfg.popoverRAMStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks active memory usage and pressure.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // Disk style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowDisk },
                                    set: { cfg.popoverShowDisk = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("Disk Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowDisk {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverDiskStyle },
                                        set: { cfg.popoverDiskStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks primary storage capacity usage.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // GPU style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowGPURing },
                                    set: { cfg.popoverShowGPURing = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("GPU Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowGPURing {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverGPUStyle },
                                        set: { cfg.popoverGPUStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks graphics utilization and temperature.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                            if cfg.popoverShowGPURing {
                                Divider().background(Color.white.opacity(0.1)).padding(.vertical, 2)
                                Toggle(isOn: .init(
                                    get: { cfg.popoverShowGPUSparkline },
                                    set: { cfg.popoverShowGPUSparkline = $0; notify(widthChanged: false) }
                                )) {
                                    Text("Show Temperature Sparkline Graph below")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.tahoeText)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentPurple))
                            }
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // VRAM style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowVRAM },
                                    set: { cfg.popoverShowVRAM = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("VRAM Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowVRAM {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverGPUStyle },
                                        set: { cfg.popoverGPUStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks graphics memory (VRAM) utilization.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    }

                    Divider().background(Color.tahoeCardBorder)

                    SectionTitle("Style Options")
                    Text("Configure labels and layout details for widgets inside the popover.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    ToggleRow(label: "Show Ring Labels", detail: "Display text labels below rings (CPU, RAM, etc.)", isOn: .init(
                        get: { cfg.popoverRingShowLabels }, set: { cfg.popoverRingShowLabels = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentCyan) { _ in }

                    ToggleRow(label: "Show Ring Details", detail: "Display temperatures/GB usage inside rings", isOn: .init(
                        get: { cfg.popoverRingShowTemp }, set: { cfg.popoverRingShowTemp = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentOrange) { _ in }

                    ToggleRow(label: "Pin Popover Open", detail: "Prevent the popover from closing when clicking outside", isOn: .init(
                        get: { cfg.popoverPinOpen }, set: { cfg.popoverPinOpen = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentCyan) { _ in }

                    Divider().background(Color.tahoeCardBorder)

                    SectionTitle("Other Popover Widgets")
                    Text("Enable additional stats columns inside the popover.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    ToggleRow(label: "Show GPU Row", detail: "Display detailed text row with GPU model, temp, and power", isOn: .init(
                        get: { cfg.popoverShowGPU }, set: { cfg.popoverShowGPU = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentPurple) { _ in }

                    ToggleRow(label: "Show Network Row", detail: "Display live upload/download speed stats", isOn: .init(
                        get: { cfg.popoverShowNetwork }, set: { cfg.popoverShowNetwork = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentGreen) { _ in }

                    if cfg.popoverShowNetwork {
                        Toggle(isOn: .init(
                            get: { cfg.popoverShowNetSparkline },
                            set: { cfg.popoverShowNetSparkline = $0; notify(widthChanged: false) }
                        )) {
                            Text("Show Network Speed Sparkline Graph below")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.tahoeText)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentGreen))
                        .padding(.leading, 12).padding(.bottom, 6)
                    }

                    ToggleRow(label: "Show Top Processes", detail: "Display top 5 CPU-intensive processes list", isOn: .init(
                        get: { cfg.popoverShowProcesses }, set: { cfg.popoverShowProcesses = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentRed) { _ in }
                }
            }
            .padding(18)
        }
        .onAppear {
            loadOrder()
        }
    }

    private func loadOrder() {
        // Load Ring Items
        let ringOrderStr = cfg.popoverRingOrder
        let ringKeys = ringOrderStr.split(separator: ",").map(String.init)
        var loadedRings: [RingOrderItem] = []
        for key in ringKeys {
            if key == "cpu" { loadedRings.append(RingOrderItem(id: "cpu", name: "CPU Ring", color: .tahoeAccentCyan)) }
            if key == "ram" { loadedRings.append(RingOrderItem(id: "ram", name: "RAM Ring", color: .tahoeAccentOrange)) }
            if key == "disk" { loadedRings.append(RingOrderItem(id: "disk", name: "Disk Ring", color: .tahoeAccentBlue)) }
            if key == "gpu" { loadedRings.append(RingOrderItem(id: "gpu", name: "GPU Ring", color: .tahoeAccentPurple)) }
            if key == "vram" { loadedRings.append(RingOrderItem(id: "vram", name: "VRAM Ring", color: .tahoeAccentPurple.opacity(0.8))) }
        }
        self.ringItems = loadedRings

        // Load Vertical Items
        let vertOrderStr = cfg.popoverVerticalOrder
        let vertKeys = vertOrderStr.split(separator: ",").map(String.init)
        var loadedVerts: [RingOrderItem] = []
        for key in vertKeys {
            if key == "cpu" { loadedVerts.append(RingOrderItem(id: "cpu", name: "CPU Charts/Bars", color: .tahoeAccentCyan)) }
            if key == "ram" { loadedVerts.append(RingOrderItem(id: "ram", name: "RAM Bar", color: .tahoeAccentOrange)) }
            if key == "disk" { loadedVerts.append(RingOrderItem(id: "disk", name: "Disk Bar", color: .tahoeAccentBlue)) }
            if key == "gpu" { loadedVerts.append(RingOrderItem(id: "gpu", name: "GPU Info & Charts", color: .tahoeAccentPurple)) }
            if key == "vram" { loadedVerts.append(RingOrderItem(id: "vram", name: "VRAM Bar", color: .tahoeAccentPurple.opacity(0.8))) }
            if key == "net" { loadedVerts.append(RingOrderItem(id: "net", name: "Network Tracker", color: .tahoeAccentGreen)) }
            if key == "proc" { loadedVerts.append(RingOrderItem(id: "proc", name: "Top Processes", color: .gray)) }
        }
        self.verticalItems = loadedVerts
    }

    private func saveRingOrder() {
        let orderStr = ringItems.map { $0.id }.joined(separator: ",")
        cfg.popoverRingOrder = orderStr
        notify(widthChanged: false)
    }

    private func saveVerticalOrder() {
        let orderStr = verticalItems.map { $0.id }.joined(separator: ",")
        cfg.popoverVerticalOrder = orderStr
        notify(widthChanged: false)
    }

    private func moveRingUp(index: Int) {
        guard index > 0 else { return }
        ringItems.swapAt(index, index - 1)
        saveRingOrder()
    }

    private func moveRingDown(index: Int) {
        guard index < ringItems.count - 1 else { return }
        ringItems.swapAt(index, index + 1)
        saveRingOrder()
    }

    private func moveVerticalUp(index: Int) {
        guard index > 0 else { return }
        verticalItems.swapAt(index, index - 1)
        saveVerticalOrder()
    }

    private func moveVerticalDown(index: Int) {
        guard index < verticalItems.count - 1 else { return }
        verticalItems.swapAt(index, index + 1)
        saveVerticalOrder()
    }

    private func notify(widthChanged: Bool = true) {
        cfg = MenuBarConfig()
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
    }
}

// MARK: - Popover CPU Per-Core Thread Load Grid Widget
