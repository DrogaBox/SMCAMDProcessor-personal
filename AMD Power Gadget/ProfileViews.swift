//
//  ProfileViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Profiles Views
//

import SwiftUI

// MARK: - Profiles Content View
struct ProfilesContentView: View {
    @ObservedObject var model: TelemetryModel
    @State private var isCurveOptimizerUnlocked = false
    private var stepLabels: [String] {
        model.speedStepClocks.enumerated().map { i, freq in
            let ghz = freq * 0.001
            switch i {
            case 0: return String(format: "Performance\n%.1f GHz", ghz)
            case 1: return String(format: "Balanced\n%.1f GHz", ghz)
            case 2: return String(format: "Base\n%.1f GHz", ghz)
            case 3: return String(format: "Efficient\n%.1f GHz", ghz)
            case 4: return String(format: "Low Power\n%.1f GHz", ghz)
            default: return String(format: "P%d\n%.1f GHz", i, ghz)
            }
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Power Management Mode")
                
                // 1. CPPC Mode Switch
                UnsupportedFeatureOverlay(
                    isSupported: model.cppcSupported,
                    reasonText: LocalizedStringKey("CPPC: Disabled by CPU architecture")
                ) {
                    TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Native CPPC Active Mode (EPP)", comment: ""))
                                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text(NSLocalizedString("Enables autonomous hardware frequency scaling (recommended)", comment: ""))
                                        .font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { model.cppcActiveMode },
                                    set: { model.setCPPCActiveMode(active: $0) }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan))
                                .labelsHidden()
                                .disabled(!model.smcDriverLoaded)
                            }
                            if !model.smcDriverLoaded {
                                Text(NSLocalizedString("AMDRyzenCPUPowerManagement kext not connected.", comment: ""))
                                    .font(.system(size: 10)).foregroundColor(.tahoeAccentOrange)
                            } else if !model.cppcSupported && !model.cppcActiveMode {
                                Text(NSLocalizedString("This CPU did not report CPPC support to the kext.", comment: ""))
                                    .font(.system(size: 10)).foregroundColor(.tahoeAccentOrange)
                            } else if !model.cppcActiveMode {
                                Text(NSLocalizedString(
                                    "If the switch snaps back to Off: enable writes with boot-arg -amdpnopchk (or run as root). With -amdcppcactive the kext enables Active Mode at boot after reboot.",
                                    comment: "CPPC Active Mode help"
                                ))
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            if let err = model.privilegeErrorMessage {
                                Text(err)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.tahoeAccentOrange)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                
                if model.cppcActiveMode {
                    // 2. Dynamic Auto-EPP Engine
                    TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dynamic Auto-EPP Workload Engine").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text("Automatically switches EPP profiles based on live CPU load").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                }
                                Spacer()
                                Toggle("", isOn: $model.autoEPPEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan)).labelsHidden()
                            }
                            if model.autoEPPEnabled {
                                Divider().background(Color.white.opacity(0.1))
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Idle Threshold (Power Save)").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                        Spacer()
                                        Text(String(format: "%.0f%%", model.autoEPPIdleThreshold))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.tahoeAccentCyan)
                                    }
                                    Slider(value: $model.autoEPPIdleThreshold, in: 5...30, step: 5)
                                        .accentColor(.tahoeAccentCyan)
                                    
                                    HStack {
                                        Text("High Load Threshold (Performance)").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                        Spacer()
                                        Text(String(format: "%.0f%%", model.autoEPPHighThreshold))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.tahoeAccentCyan)
                                    }
                                    Slider(value: $model.autoEPPHighThreshold, in: 40...90, step: 5)
                                        .accentColor(.tahoeAccentCyan)
                                }
                            }
                        }
                    }

                    // 3. CPPC EPP Picker
                    SectionTitle("Energy Preference (EPP)")
                    Text("Select a hardware autonomous profile. The CPU will scale frequency dynamically.")
                        .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                    TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                        Picker("", selection: Binding(get: {
                            if model.cppcEPPValue <= 0x1F { return 0 }
                            else if model.cppcEPPValue <= 0x5F { return 1 }
                            else if model.cppcEPPValue <= 0x9F { return 2 }
                            else { return 3 }
                                                }, set: { (val: Int) in
                            let eppBytes: [UInt8] = [0x00, 0x3F, 0x7F, 0xFF]
                            model.setCPPCEPPValue(epp: eppBytes[val])
                        })) {
                            Text("Performance").tag(0)
                            Text("Balanced Perf").tag(1)
                            Text("Balanced Power").tag(2)
                            Text("Power Save").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: .infinity)
                        .disabled(model.autoEPPEnabled)
                    }
                } else {
                    // 3. Legacy Speed Step Profiles
                    UnsupportedFeatureOverlay(
                        isSupported: ProcessorModel.shared.isLegacyPStateSupported,
                        reasonText: LocalizedStringKey("P-States: Disabled for modern CPU")
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionTitle("CPU Speed Profiles (Legacy)")
                            Text("Select a manual P-State override profile. Frequencies will be restricted to the selected step.")
                                .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                                .padding(.bottom, 6)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(Array(stepLabels.enumerated()), id: \.offset) { i, label in
                                    SpeedStepCard(label: label, isActive: model.selectedSpeedStep == i) { model.setSpeedStep(i) }
                                }
                            }
                        }
                    }
                }
                
                SectionTitle("Active Profile Status")
                TahoeCard {
                    if model.cppcActiveMode {
                        let eppLabels = ["Performance", "Balanced Perf", "Balanced Power", "Power Save"]
                        let activeIdx: Int = {
                            if model.cppcEPPValue <= 0x1F { return 0 }
                            else if model.cppcEPPValue <= 0x5F { return 1 }
                            else if model.cppcEPPValue <= 0x9F { return 2 }
                            else { return 3 }
                        }()
                        InfoRow(label: "Mode", value: "Native CPPC (EPP)")
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "EPP Profile", value: NSLocalizedString(eppLabels[activeIdx], comment: ""))
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "Auto-EPP Engine", value: model.autoEPPEnabled ? "Active (Dynamic Load)" : "Disabled")
                    } else if stepLabels.indices.contains(model.selectedSpeedStep) {
                        InfoRow(label: "Mode", value: "Legacy P-States")
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "Profile", value: stepLabels[model.selectedSpeedStep].replacingOccurrences(of: "\n", with: " — "))
                    }
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Avg Frequency", value: String(format: "%.3f GHz", model.cpuFreqAvgGHz))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Max Frequency", value: String(format: "%.3f GHz", model.cpuFreqMaxGHz))
                }
                
                SectionTitle("AMD Curve Optimizer (CO)")
                Text("Inject positive or negative voltage offsets per core. Center is 0 (no override). Limit: -30 (undervolt) to +30 (overvolt) counts.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                
                TahoeCard(accent: Color.tahoeAccentPurple.opacity(0.15)) {
                    if model.curveOptimizerOffsets.isEmpty {
                        Text("Curve Optimizer is only active when the AMDRyzenCPUPowerManagement kext supports Zen 3 SMU mailbox interface.")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(.tahoeSubtext)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 10) {
                                Image(systemName: isCurveOptimizerUnlocked ? "lock.open.trianglebadge.exclamationmark.fill" : "lock.fill")
                                    .foregroundColor(isCurveOptimizerUnlocked ? .tahoeAccentPurple : .tahoeAccentOrange)
                                    .font(.system(size: 14))
                                
                                Toggle("Unlock Curve Optimizer (DANGEROUS: unstable undervolting can cause kernel panic or instant reboot)", isOn: $isCurveOptimizerUnlocked)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(isCurveOptimizerUnlocked ? .tahoeText : .tahoeAccentOrange)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(isCurveOptimizerUnlocked ? Color.tahoeAccentPurple.opacity(0.06) : Color.tahoeAccentOrange.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCurveOptimizerUnlocked ? Color.tahoeAccentPurple.opacity(0.2) : Color.tahoeAccentOrange.opacity(0.2), lineWidth: 1)
                            )
                            
                            if isCurveOptimizerUnlocked {
                                let activeCoreCount = model.numPhysicalCores > 0 ? model.numPhysicalCores : (model.cores.isEmpty ? 16 : model.cores.count / 2)
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 12) {
                                    ForEach(0..<min(model.curveOptimizerOffsets.count, activeCoreCount), id: \.self) { idx in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("Core \(idx)").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                                Spacer()
                                                
                                                if let core = model.cores.first(where: { $0.id == idx }) {
                                                    HStack(spacing: 6) {
                                                        let freqGHz = Double(core.freqMHz) / 1000.0
                                                        Text(String(format: "%.2f GHz", freqGHz))
                                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(.tahoeAccentCyan)
                                                        
                                                        Text(String(format: "%.0f%%", core.loadPct))
                                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(.tahoeAccentOrange)
                                                        
                                                        let ccdIdx = idx / 8
                                                        if model.ccdTemperatures.count > ccdIdx {
                                                            Text(String(format: "%.0f°C", model.ccdTemperatures[ccdIdx]))
                                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                                .foregroundColor(.tahoeAccentRed)
                                                        }
                                                    }
                                                    .padding(.trailing, 8)
                                                }
                                                
                                                let currentOffset = idx < model.curveOptimizerOffsets.count ? model.curveOptimizerOffsets[idx] : 0
                                                Text(currentOffset > 0 ? "+\(currentOffset)" : "\(currentOffset)")
                                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                    .foregroundColor(currentOffset < 0 ? .tahoeAccentPurple : (currentOffset > 0 ? .tahoeAccentOrange : .tahoeSubtext))
                                            }
                                            
                                            let currentOffset = idx < model.curveOptimizerOffsets.count ? Double(model.curveOptimizerOffsets[idx]) : 0.0
                                            Slider(value: Binding(get: {
                                                return currentOffset
                                            }, set: { (val: Double) in
                                                let offsetInt = Int(round(val))
                                                let _ = model.setCurveOptimizerOffset(core: idx, offset: offsetInt)
                                            }), in: -30...30, step: 1)
                                            .accentColor(.tahoeAccentPurple)
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.02))
                                        .cornerRadius(6)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: isCurveOptimizerUnlocked)
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

// MARK: - Speed Step Card
struct SpeedStepCard: View {
    let label: String; let isActive: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isActive ? "bolt.fill" : "bolt").font(.system(size: 20))
                    .foregroundColor(isActive ? .tahoeAccentCyan : .tahoeSubtext)
                    .shadow(color: isActive ? Color.tahoeAccentCyan.opacity(0.8) : .clear, radius: 6)
                Text(label).font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .tahoeText : .tahoeSubtext).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(isActive ? Color.tahoeAccentCyan.opacity(0.12) : Color.tahoeCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isActive ? Color.tahoeAccentCyan.opacity(0.6) : Color.tahoeCardBorder, lineWidth: isActive ? 1.5 : 1))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
