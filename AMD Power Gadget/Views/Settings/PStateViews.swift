//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI
import Charts

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
                TahoeButton(label: "Revert", icon: "arrow.counterclockwise", accent: .tahoeAccentOrange) { Task { await model.loadPStateRows() } }
                    .disabled(!isUnlocked)
                TahoeButton(label: "Import", icon: "square.and.arrow.down", accent: .tahoeAccentGreen) {
                    let op = NSOpenPanel()
                    op.allowedContentTypes = [.init(filenameExtension: "pstate") ?? .data]
                    if op.runModal() == .OK, let url = op.url { Task { await model.importPStates(from: url) } }
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
            Button("Apply", role: .destructive) { Task { applyOK = await model.applyPStates() } }
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

