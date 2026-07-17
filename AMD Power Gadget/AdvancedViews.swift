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
                    reasonText: LocalizedStringKey("CPB: Disabled by CPU architecture")
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
                    isSupported: model.legacyPStateSupported,
                    reasonText: LocalizedStringKey("P-States: Disabled for modern CPU")
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
// MARK: - Raw Field
