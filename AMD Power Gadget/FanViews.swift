//
//  FanViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Fan Control Views
//

import SwiftUI

// MARK: - Fan Control Content View
struct FanControlContentView: View {
    @ObservedObject var model: TelemetryModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !model.smcDriverLoaded {
                    SMCNotAvailableView()
                } else if model.fans.isEmpty {
                    Text("No fans detected.").foregroundColor(.tahoeSubtext).frame(maxWidth: .infinity).padding(32)
                } else {
                    HStack {
                        SectionTitle("SMC Fan Control")
                        Spacer()
                        if !model.hiddenFanIDs.isEmpty {
                            Button(action: {
                                model.hiddenFanIDs.removeAll()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.fill")
                                    Text(String(format: NSLocalizedString("Show All (%d hidden)", comment: ""), model.hiddenFanIDs.count))
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.tahoeAccentCyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    ForEach(model.fans.filter { !model.hiddenFanIDs.contains($0.id) }) { fan in
                        FanControlCard(fan: fan, model: model)
                    }
                    HStack(spacing: 10) {
                        TahoeButton(label: "All Auto", icon: "arrow.circlepath", accent: .tahoeAccentCyan) { model.setAllFansAuto() }
                        TahoeButton(label: "Max Speed", icon: "wind", accent: .tahoeAccentOrange) { model.setAllFansTakeOff() }
                    }
                    
                    Divider().background(Color.tahoeCardBorder)
                    
                    SectionTitle("Closed-Loop Custom Fan Curves & Protection")
                    TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.2)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dynamic Next-Gen Fan Curves").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text("Evaluated in the kernel with 256-step LUT interpolation, hysteresis, and smooth ramping.").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                }
                                Spacer()
                                Toggle("", isOn: $model.autoFanCurveEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentOrange)).labelsHidden()
                            }
                            if model.autoFanCurveEnabled {
                                Divider().background(Color.white.opacity(0.1))
                                InteractiveFanCurveEditor(model: model)
                            }
                        }
                    }
                }
                
                Divider().background(Color.tahoeCardBorder)
                
                GPUFanControlGuideView()
            }
            .padding(18)
        }
    }
}

// MARK: - GPU Fan Control Guide
struct GPUFanControlGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("GPU Fan Control (Zero RPM / Curves)")
            TahoeCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.tahoeAccentCyan)
                            .font(.system(size: 16))
                        Text("macOS Hardware Limitation")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.tahoeText)
                    }
                    Text("Direct software-based GPU fan speed overrides (such as zero-rpm toggle or drawing fan curves in macOS) are not supported by the macOS kernel/IOKit driver for AMD GPUs. The GPU's onboard firmware (vBIOS) manages the fans.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.tahoeSubtext)
                        .lineSpacing(4)
                    
                    Text("Standard Hackintosh Solution:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tahoeText)
                        .padding(.top, 4)
                    Text("The only way to modify this behavior (like forcing fans to spin at lower temperatures or disabling Zero RPM) is by exporting the vBIOS, creating a Soft PowerPlay Table (SPPT), and injecting it via OpenCore's config.plist under DeviceProperties.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.tahoeSubtext)
                        .lineSpacing(4)
                    
                    HStack(spacing: 10) {
                        TahoeButton(label: "Open SPPT Guide", icon: "safari", accent: .tahoeAccentCyan) {
                            if let url = URL(string: "https://github.com/perez987/6600XT-on-macOS-with-softPowerPlayTable") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        TahoeButton(label: "MorePowerTool", icon: "arrow.down.circle", accent: .tahoeAccentOrange) {
                            if let url = URL(string: "https://www.igorslab.de/en/red-bios-editor-and-morepowertool-adjust-and-optimize-your-radeon-rx-5700-xt-and-radeon-vii-bios-instructions-and-downloads/") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
    }
}

// MARK: - SMC Not Available View
struct SMCNotAvailableView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 32)).foregroundColor(.tahoeAccentOrange)
            Text("SMC driver not available").font(.system(size: 14, weight: .semibold)).foregroundColor(.tahoeText)
            Text("Your SMC chip may not be supported.").font(.system(size: 12)).foregroundColor(.tahoeSubtext)
        }
        .frame(maxWidth: .infinity).padding(32)
    }
}

// MARK: - Fan Control Card
struct FanControlCard: View {
    let fan: FanSnapshot; @ObservedObject var model: TelemetryModel
    @State private var sliderValue: Double = 0
    var body: some View {
        let isMappedToCurve = (model.fanMappings[fan.id] ?? -1) != -1
        let mappedCurveIdx = model.fanMappings[fan.id] ?? -1
        let curveName = mappedCurveIdx >= 0 && mappedCurveIdx < model.customCurves.count ? model.customCurves[mappedCurveIdx].name : "Unknown"
        
        TahoeCard(accent: fan.isOverrided ? Color.tahoeAccentOrange.opacity(0.4) : Color.tahoeCardBorder) {
            HStack {
                Image(systemName: "fan").foregroundColor(.tahoeAccentCyan).font(.system(size: 14))
                TextField("", text: Binding(
                    get: { model.customFanNames[fan.id] ?? (fan.name.isEmpty ? "Fan \(fan.id + 1)" : fan.name) },
                    set: { newVal in
                        var updated = model.customFanNames
                        updated[fan.id] = newVal
                        model.customFanNames = updated
                    }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.tahoeText)
                .frame(width: 150)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(fan.rpm) RPM").font(.system(size: 11, design: .monospaced)).foregroundColor(.tahoeAccentCyan)
                    Text("·").foregroundColor(.tahoeSubtext)
                    Text(String(format: "%.0f%%", Double(fan.throttle) / 255.0 * 100.0))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(fan.isOverrided ? .tahoeAccentOrange : .tahoeSubtext)
                    Text("·").foregroundColor(.tahoeSubtext)
                    Button(action: {
                        model.hiddenFanIDs.insert(fan.id)
                    }) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.tahoeSubtext)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Hide this fan")
                }
            }
            HStack {
                Text("Control Mode").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                Spacer()
                Picker("", selection: Binding(
                    get: { model.fanMappings[fan.id] ?? -1 },
                    set: { newVal in
                        var updated = model.fanMappings
                        updated[fan.id] = newVal
                        model.fanMappings = updated
                    }
                )) {
                    Text("BIOS / Auto").tag(-1)
                    ForEach(0..<model.customCurves.count, id: \.self) { idx in
                        Text(model.customCurves[idx].name).tag(idx)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            if isMappedToCurve {
                HStack {
                    Spacer()
                    Text("Controlled by Curve: \(curveName)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.tahoeAccentOrange)
                }
            } else {
                HStack(spacing: 12) {
                    Text("Manual Override").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                    Slider(value: $sliderValue, in: 0...255, step: 1) { editing in
                        if !editing { model.setFanThrottle(fanIndex: fan.id, throttle: UInt8(sliderValue)) }
                    }
                    .tint(Color.tahoeAccentCyan)
                    Text(String(format: "%.0f%%", sliderValue / 255.0 * 100.0))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.tahoeAccentCyan)
                        .frame(width: 36, alignment: .trailing)
                }
                if fan.isOverrided {
                    Button("↩ Reset to Auto") { model.setFanOverride(fanIndex: fan.id, overrideEnabled: false) }
                        .font(.system(size: 11)).foregroundColor(.tahoeAccentOrange).buttonStyle(.plain)
                }
            }
        }
        .onAppear { sliderValue = Double(fan.throttle) }
        .onChange(of: fan.throttle) { newVal in sliderValue = Double(newVal) }
    }
}
