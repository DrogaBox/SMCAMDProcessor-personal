//
//  AdvancedViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Advanced & P-State Views
//

import SwiftUI
import Charts

// MARK: - Advanced Content View
struct AdvancedContentView: View {
    @ObservedObject var model: TelemetryModel
    @State private var showApplyConfirm = false
    @State private var applyOK: Bool? = nil
    
    @AppStorage("low_performance_mode") private var isLowPerformanceMode = false
    @AppStorage("user_forced_low_performance") private var userForced = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle("CPU Power Controls")
                UnsupportedFeatureOverlay(
                    isSupported: model.cpbSupported,
                    reasonText: "CPB: Desactivado por arquitectura de CPU"
                ) {
                    TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Core Performance Boost (CPB)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Allows dynamic clock frequency scaling").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(get: { model.cpbEnabled }, set: { model.setCPB(enabled: $0) }))
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan)).labelsHidden()
                        }
                    }
                }
                TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AMD Processor Power Manager (PPM)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text("Allows macOS to auto-manage CPU frequency").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(get: { model.ppmEnabled }, set: { model.setPPM(enabled: $0) }))
                            .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentOrange)).labelsHidden()
                    }
                }
                TahoeCard(accent: Color.tahoeAccentGreen.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Low Power Mode (LPM)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text("Forces CPU to lowest frequency for minimum power").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(get: { model.lpmEnabled }, set: { model.setLPM(enabled: $0) }))
                            .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentGreen)).labelsHidden()
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Refresh Rate")
                Text("Adjust how frequently telemetry data updates. Lower = more responsive, higher = less CPU usage.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                TahoeCard(accent: Color.tahoeAccentPurple.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Update Interval").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Spacer()
                            Text(String(format: "%.1f s", RefreshRateConfig.shared.interval))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentPurple)
                        }
                        Slider(value: .init(
                            get: { RefreshRateConfig.shared.interval },
                            set: { RefreshRateConfig.shared.interval = $0; model.restartTimer() }
                        ), in: 0.1...5.0, step: 0.1)
                        .tint(Color.tahoeAccentPurple)
                        HStack {
                            Text("0.1s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                            Spacer()
                            Text("5.0s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Performance & Fallback")
                Text("Disable heavy visual effects if your system lacks Metal graphics acceleration.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                TahoeCard(accent: Color.tahoeSubtext.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Low Performance Mode").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text("Replaces translucent blurs with solid colors to save CPU").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { isLowPerformanceMode },
                            set: { newValue in
                                isLowPerformanceMode = newValue
                                userForced = true
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .tahoeSubtext)).labelsHidden()
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("System Alert Notifications")
                Text("Receive native macOS alerts when the CPU exceeds configured thermal or power limits.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                TahoeCard(accent: Color.tahoeAccentRed.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable System Alerts").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Requests permission and enables hardware limit warnings").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: $model.notificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentRed)).labelsHidden()
                        }
                        
                        if model.notificationsEnabled {
                            Divider().background(Color.tahoeCardBorder)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Temperature Warning Threshold").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Spacer()
                                    Text("\(model.tempAlertThreshold) °C")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.tahoeAccentRed)
                                }
                                Slider(value: Binding(
                                    get: { Double(model.tempAlertThreshold) },
                                    set: { model.tempAlertThreshold = Int($0) }
                                ), in: 60...100, step: 1)
                                .tint(Color.tahoeAccentRed)
                                HStack {
                                    Text("60°C").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Text("100°C").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                }
                            }
                            
                            Divider().background(Color.tahoeCardBorder)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Power Warning Threshold (PPT)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Spacer()
                                    Text("\(model.powerAlertThreshold) W")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.tahoeAccentRed)
                                }
                                Slider(value: Binding(
                                    get: { Double(model.powerAlertThreshold) },
                                    set: { model.powerAlertThreshold = Int($0) }
                                ), in: 45...250, step: 5)
                                .tint(Color.tahoeAccentRed)
                                HStack {
                                    Text("45W").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Text("250W").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                }
                            }
                            
                            Divider().background(Color.tahoeCardBorder)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Sustained Duration").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Spacer()
                                    Text("\(model.powerAlertDuration) seconds")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.tahoeAccentRed)
                                }
                                Slider(value: Binding(
                                    get: { Double(model.powerAlertDuration) },
                                    set: { model.powerAlertDuration = Int($0) }
                                ), in: 1...60, step: 1)
                                .tint(Color.tahoeAccentRed)
                                HStack {
                                    Text("1s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Text("60s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                }
                            }
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                UnsupportedFeatureOverlay(
                    isSupported: ProcessorModel.shared.isLegacyPStateSupported,
                    reasonText: "P-States: Desactivado por ser CPU moderno"
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionTitle("P-State Editor")
                        Text("Directly edit raw P-State registers. Requires kext privilege check disabled via boot-arg or root.")
                            .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                            .padding(.bottom, 8)
                        PStateEditorView(model: model)
                    }
                }
                if model.smcDriverLoaded {
                    Divider().background(Color.tahoeCardBorder)
                    SectionTitle("Quick Fan Access")
                    HStack(spacing: 10) {
                        TahoeButton(label: "All Fans Auto", icon: "arrow.circlepath", accent: .tahoeAccentCyan) { model.setAllFansAuto() }
                        TahoeButton(label: "Max Speed", icon: "wind", accent: .tahoeAccentOrange) { model.setAllFansTakeOff() }
                    }
                }

                Text("DISCLAIMER: This software interacts directly with low-level hardware control registers. By using it, you agree that absolute responsibility for any system instability, hardware damage, or alien invasion lies entirely with the user.")
                    .font(.system(size: 9))
                    .foregroundColor(.tahoeSubtext)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .padding(18)
        }
    }
}

// MARK: - P-State Chart
struct PStateChartView: View {
    let pStateRows: [PStateRow]
    let isZen5: Bool
    
    var body: some View {
        let enabledRows = pStateRows.filter { $0.enabled == 1 }
            .sorted(by: { $0.computedSpeedMHz < $1.computedSpeedMHz })
            
        let step = isZen5 ? 0.005 : 0.00625
        
        Chart {
            if enabledRows.count >= 2 {
                ForEach(enabledRows) { row in
                    LineMark(
                        x: .value("Voltage (V)", 1.55 - Double(row.cpuVid) * step),
                        y: .value("Frequency (MHz)", Double(row.computedSpeedMHz))
                    )
                    .foregroundStyle(Color.tahoeAccentCyan)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
            }
            
            ForEach(pStateRows.filter { $0.computedSpeedMHz > 0 && $0.enabled == 1 }) { row in
                let volt = 1.55 - Double(row.cpuVid) * step
                let speed = Double(row.computedSpeedMHz)
                
                PointMark(
                    x: .value("Voltage (V)", volt),
                    y: .value("Frequency (MHz)", speed)
                )
                .foregroundStyle(Color.tahoeAccentCyan)
                .symbolSize(80)
                .annotation(position: .top, alignment: .center) {
                    Text("P\(row.id)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.tahoeText)
                        .padding(2)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.white.opacity(0.05))
                AxisValueLabel {
                    if let volt = value.as(Double.self) {
                        Text(String(format: "%.3f V", volt))
                            .font(.system(size: 8))
                            .foregroundColor(.tahoeSubtext)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.white.opacity(0.05))
                AxisValueLabel {
                    if let speed = value.as(Double.self) {
                        Text(String(format: "%.0f MHz", speed))
                            .font(.system(size: 8))
                            .foregroundColor(.tahoeSubtext)
                    }
                }
            }
        }
    }
}

// MARK: - P-State Editor View
struct PStateEditorView: View {
    @ObservedObject var model: TelemetryModel
    @State private var showApplyConfirm = false
    @State private var applyOK: Bool? = nil
    @State private var isUnlocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: isUnlocked ? "lock.open.trianglebadge.exclamationmark.fill" : "lock.fill")
                    .foregroundColor(isUnlocked ? .tahoeAccentCyan : .tahoeAccentOrange)
                    .font(.system(size: 14))
                
                Toggle("Unlock P-State Editor (DANGEROUS: incorrect settings can crash or damage hardware)", isOn: $isUnlocked)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isUnlocked ? .tahoeText : .tahoeAccentOrange)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isUnlocked ? Color.tahoeAccentCyan.opacity(0.06) : Color.tahoeAccentOrange.opacity(0.08))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isUnlocked ? Color.tahoeAccentCyan.opacity(0.2) : Color.tahoeAccentOrange.opacity(0.2), lineWidth: 1)
            )
            
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("V-F Operating Curve")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tahoeSubtext)
                    
                    PStateChartView(pStateRows: model.pStateRows, isZen5: model.pStateRows.first?.isZen5 ?? false)
                        .frame(height: 280)
                        .padding(12)
                        .background(Color.tahoeBackground.opacity(0.4))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tahoeCardBorder))
                }
                .frame(width: 320)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("P-States Configuration")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tahoeSubtext)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach($model.pStateRows) { $row in
                                PStateRowControlView(row: $row, isDirty: $model.pStateEditorDirty)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                    .frame(height: 280)
                }
            }
            .opacity(isUnlocked ? 1.0 : 0.4)
            .disabled(!isUnlocked)
            .animation(.easeInOut(duration: 0.25), value: isUnlocked)
            
            HStack(spacing: 8) {
                TahoeButton(label: "Apply", icon: "checkmark.circle", accent: .tahoeAccentCyan) { showApplyConfirm = true }
                    .disabled(!isUnlocked)
                TahoeButton(label: "Revert", icon: "arrow.counterclockwise", accent: .tahoeAccentOrange) { model.loadPStateRows() }
                    .disabled(!isUnlocked)
                TahoeButton(label: "Import", icon: "square.and.arrow.down", accent: .tahoeAccentGreen) {
                    let op = NSOpenPanel()
                    op.allowedContentTypes = [.init(filenameExtension: "pstate") ?? .data]
                    if op.runModal() == .OK, let url = op.url { model.importPStates(from: url) }
                }
                .disabled(!isUnlocked)
                TahoeButton(label: "Export", icon: "square.and.arrow.up", accent: .tahoeAccentPurple) {
                    let op = NSSavePanel()
                    op.isExtensionHidden = false
                    op.allowedContentTypes = [.init(filenameExtension: "pstate") ?? .data]
                    if op.runModal() == .OK, let url = op.url { model.exportPStates(to: url) }
                }
                .disabled(!isUnlocked)
            }
            
            if let ok = applyOK {
                Text(ok ? "P-States applied successfully." : "Failed — check kext privileges (-amdpnopchk).")
                    .font(.system(size: 11)).foregroundColor(ok ? .tahoeAccentGreen : .tahoeAccentRed)
            }
        }
        .padding(14)
        .background(Color.tahoeCard.opacity(0.85))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(model.pStateEditorDirty ? Color.tahoeAccentOrange.opacity(0.5) : Color.tahoeCardBorder))
        .cornerRadius(14)
        .confirmationDialog("Apply P-States?", isPresented: $showApplyConfirm, titleVisibility: .visible) {
            Button("Apply", role: .destructive) { applyOK = model.applyPStates() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will write the raw P-State definitions directly to the CPU. Proceed?") }
    }
}

// MARK: - P-State Row Control View
struct PStateRowControlView: View {
    @Binding var row: PStateRow
    @Binding var isDirty: Bool
    @State private var isExpanded = false
    
    var body: some View {
        let step = row.isZen5 ? 0.005 : 0.00625
        let currentVoltage = 1.55 - Double(row.cpuVid) * step
        let currentSpeed = Double(row.computedSpeedMHz)
        
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("P-State \(row.id)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(row.enabled == 1 ? .tahoeText : .tahoeSubtext)
                
                Spacer()
                
                Toggle(row.enabled == 1 ? "Active" : "Inactive", isOn: Binding(
                    get: { row.enabled == 1 },
                    set: { newValue in
                        row.enabled = newValue ? 1 : 0
                        if newValue {
                            if row.cpuFid == 0 {
                                if row.isZen5 {
                                    row.cpuFid = 440
                                } else {
                                    row.cpuFid = 88
                                    row.cpuDfsId = 8
                                }
                            }
                            if row.cpuVid == 0 || row.cpuVid > 255 {
                                row.cpuVid = 56
                            }
                        }
                        isDirty = true
                    }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.7)
                .labelsHidden()
                
                Text(row.enabled == 1 ? "Active" : "Inactive")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(row.enabled == 1 ? .tahoeAccentCyan : .tahoeSubtext)
                    .frame(width: 42, alignment: .trailing)
            }
            
            if row.enabled == 1 {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Text("Freq:")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.tahoeSubtext)
                            .frame(width: 32, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { max(800.0, min(6000.0, Double(row.computedSpeedMHz))) },
                            set: { newValue in
                                if row.isZen5 {
                                    row.cpuFid = UInt32(max(0, min(4095, round(newValue / 5.0))))
                                } else {
                                    let dfs = row.cpuDfsId > 0 ? Double(row.cpuDfsId) : 8.0
                                    row.cpuFid = UInt32(max(0, min(255, round((newValue / 200.0) * dfs))))
                                }
                                isDirty = true
                            }
                        ), in: 800...6000, step: 25)
                        .tint(Color.tahoeAccentCyan)
                        
                        Text(String(format: "%.0f MHz", currentSpeed))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.tahoeAccentCyan)
                            .frame(width: 65, alignment: .trailing)
                    }
                    
                    HStack(spacing: 10) {
                        Text("Volt:")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.tahoeSubtext)
                            .frame(width: 32, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { max(0.55, min(1.55, currentVoltage)) },
                            set: { newValue in
                                let rawVid = (1.55 - newValue) / step
                                row.cpuVid = UInt32(max(0, min(255, round(rawVid))))
                                isDirty = true
                            }
                        ), in: 0.55...1.55, step: step)
                        .tint(Color.tahoeAccentOrange)
                        
                        Text(String(format: "%.4f V", currentVoltage))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.tahoeAccentOrange)
                            .frame(width: 65, alignment: .trailing)
                    }
                }
                .padding(.vertical, 4)
                
                DisclosureGroup(isExpanded: $isExpanded) {
                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            RawField(label: "FID", value: Binding(
                                get: { String(format: "%X", row.cpuFid) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.cpuFid = v
                                        isDirty = true
                                    }
                                }
                            ))
                            
                            if !row.isZen5 {
                                RawField(label: "DID", value: Binding(
                                    get: { String(format: "%X", row.cpuDfsId) },
                                    set: { newValue in
                                        if let v = UInt32(newValue, radix: 16) {
                                            row.cpuDfsId = v
                                            isDirty = true
                                        }
                                    }
                                ))
                            }
                            
                            RawField(label: "VID", value: Binding(
                                get: { String(format: "%X", row.cpuVid) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.cpuVid = v
                                        isDirty = true
                                    }
                                }
                            ))
                        }
                        
                        HStack(spacing: 10) {
                            RawField(label: "IddDiv", value: Binding(
                                get: { String(format: "%X", row.iddDiv) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.iddDiv = v
                                        isDirty = true
                                    }
                                }
                            ))
                            
                            RawField(label: "IddVal", value: Binding(
                                get: { String(format: "%X", row.iddValue) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.iddValue = v
                                        isDirty = true
                                    }
                                }
                            ))
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Raw Register Details")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                }
                .accentColor(.tahoeSubtext)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
            }
        }
        .padding(10)
        .background(row.enabled == 1 ? Color.tahoeAccentCyan.opacity(0.04) : Color.tahoeBackground.opacity(0.2))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(row.enabled == 1 ? Color.white.opacity(0.06) : Color.clear, lineWidth: 0.5))
    }
}

// MARK: - Raw Field
struct RawField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 8, weight: .semibold)).foregroundColor(.tahoeSubtext)
            TextField("", text: $value)
                .textFieldStyle(.plain)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.tahoeText)
                .padding(4)
                .background(Color.tahoeBackground.opacity(0.3))
                .cornerRadius(4)
        }
    }
}
struct TempThresholdField: View {
    @Binding var value: Int
    @State private var text = ""
    
    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: $text, onEditingChanged: { editing in
                if !editing {
                    if let val = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        value = max(30, min(100, val))
                    }
                    text = "\(value)"
                }
            })
            .textFieldStyle(.plain)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.tahoeAccentOrange)
            .multilineTextAlignment(.trailing)
            .frame(width: 45)
            .onAppear {
                text = "\(value)"
            }
            .onChange(of: value) { newValue in
                text = "\(newValue)"
            }
            
            Text("°C")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.tahoeSubtext)
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(Color.tahoeBackground.opacity(0.4))
        .cornerRadius(6)
    }
}

struct VerticalLabelView: View {
    let text: String
    var body: some View {
        let chars = Array(text.map { String($0) })
        VStack(spacing: -1.5) {
            ForEach(0..<chars.count, id: \.self) { idx in
                Text(chars[idx])
                    .font(.system(size: 7.2, weight: .regular, design: .monospaced))
            }
        }
        .frame(width: 7)
        .foregroundColor(.white.opacity(0.8))
    }
}

struct MenuBarPreview: View {
    let cfg: MenuBarConfig
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    
    private func formatSpeed(_ mbps: Double) -> String {
        let absMbps = abs(mbps)
        let bytesPerSec = absMbps * 1024.0 * 1024.0
        if bytesPerSec >= 1024.0 * 1024.0 {
            let val = bytesPerSec / (1024.0 * 1024.0)
            return String(format: "%.1f MB/s", locale: Locale.current, val)
        } else if bytesPerSec >= 1024.0 {
            let val = bytesPerSec / 1024.0
            return String(format: "%.1f KB/s", locale: Locale.current, val)
        } else if bytesPerSec >= 1.0 {
            let val = bytesPerSec / 1024.0
            return String(format: "%.2f KB/s", locale: Locale.current, val)
        } else {
            return "0 KB/s"
        }
    }
    
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
                        Text("Límite de Temp de Alerta").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
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
                        Text("Opciones en Menú Bar").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
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
