//
//  DesktopWidgetsViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Desktop Widgets Views
//

import SwiftUI

struct DesktopWidgetsConfigView: View {
    @ObservedObject var model: TelemetryModel
    @ObservedObject var manager = DesktopWidgetManager.shared
    
    @AppStorage("widget_enabled_CPU") private var widgetCpuEnabled = false
    @AppStorage("widget_enabled_GPU") private var widgetGpuEnabled = false
    @AppStorage("widget_enabled_RAM") private var widgetRamEnabled = false
    @AppStorage("widget_enabled_Disk") private var widgetDiskEnabled = false
    @AppStorage("widget_enabled_Net") private var widgetNetEnabled = false
    @AppStorage("widget_enabled_Fan") private var widgetFanEnabled = false
    @AppStorage("widget_enabled_Clock") private var widgetClockEnabled = false
    @AppStorage("widget_enabled_United") private var widgetUnitedEnabled = false
    
    @AppStorage("widget_united_show_cpu") private var unitedShowCpu = true
    @AppStorage("widget_united_show_gpu") private var unitedShowGpu = true
    @AppStorage("widget_united_show_ram") private var unitedShowRam = true
    @AppStorage("widget_united_show_disk") private var unitedShowDisk = true
    @AppStorage("widget_united_show_net") private var unitedShowNet = false
    @AppStorage("widget_united_show_fan") private var unitedShowFan = false
    
    @AppStorage("widget_auto_align") private var widgetAutoAlign = false
    @AppStorage("widget_align_corner") private var widgetAlignCorner = "topRight"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle("Desktop Widgets")
                Text("Show a floating, non-interactive widget on your desktop for live telemetry.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                
                TahoeCard(accent: Color.tahoeAccentBlue.opacity(0.15)) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Edit Widget Layout").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Unlock widgets to drag them around the screen").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Button(action: {
                                widgetCpuEnabled = false
                                widgetGpuEnabled = false
                                widgetRamEnabled = false
                                widgetDiskEnabled = false
                                widgetNetEnabled = false
                                widgetFanEnabled = false
                                widgetClockEnabled = false
                                widgetUnitedEnabled = false
                                DesktopWidgetManager.shared.refreshWidgets()
                                NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
                            }) {
                                Text(NSLocalizedString("Disable All Widgets", comment: ""))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                manager.isEditingWidgets.toggle()
                            }) {
                                Text(manager.isEditingWidgets ? "Done" : "Edit Layout")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(manager.isEditingWidgets ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(manager.isEditingWidgets ? Color.white : Color.tahoeAccentBlue)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            Text("Show CPU Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetCpuEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show GPU Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetGpuEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show RAM Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetRamEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Disk Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetDiskEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Network Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetNetEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Fan Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetFanEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Clock Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetClockEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show United Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetUnitedEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        if widgetUnitedEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Configure Combined Metrics").font(.system(size: 10, weight: .semibold)).foregroundColor(.tahoeSubtext)
                                    .padding(.top, 4)
                                
                                HStack {
                                    Text("Include CPU").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowCpu)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include GPU").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowGpu)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include RAM").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowRam)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include Disk").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowDisk)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include Network").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowNet)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include Fan").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowFan)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.leading, 12)
                            .padding(.bottom, 4)
                        }
                    }
                }
                
                Divider().background(Color.tahoeCardBorder)
                
                SectionTitle("Widget Options")
                Text("Customize the appearance and behavior of your desktop widgets.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                
                TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Right-click any widget directly on your desktop to change its style dynamically (Classic Glass, Pro Monitor, or Core Matrix).").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Align Active Widgets").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Automatically stack active widgets at a corner").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: $widgetAutoAlign)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan)).labelsHidden()
                        }
                        
                        if widgetAutoAlign {
                            HStack {
                                Text("Alignment Corner").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                Spacer()
                                Picker("", selection: $widgetAlignCorner) {
                                    Text("Top Right").tag("topRight")
                                    Text("Top Left").tag("topLeft")
                                    Text("Bottom Right").tag("bottomRight")
                                    Text("Bottom Left").tag("bottomLeft")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 20)
        }
        .onChange(of: widgetCpuEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetGpuEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetRamEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetDiskEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetNetEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetFanEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetClockEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetUnitedEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetAutoAlign) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetAlignCorner) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
    }
}

