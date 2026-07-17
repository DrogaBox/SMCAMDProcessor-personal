//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct PopoverSettingsView: View {
    @AppStorage("pop_showCPU") private var showCPU = true
    @AppStorage("pop_showGPU") private var showGPU = true
    @AppStorage("pop_showRAM") private var showRAM = true
    @AppStorage("pop_showDisk") private var showDisk = true
    @AppStorage("pop_showNetwork") private var showNetwork = true
    @AppStorage("pop_processApp") private var processApp: String = "Activity Monitor"
    
    @State private var selectedShortcutOption: String = "Activity Monitor"
    @State private var customShortcutPath: String = ""
    
    private var theme: AppTheme { AppTheme.current }
    private let presetApps = ["Activity Monitor", "Terminal", "System Information", "Console"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Section
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(theme.accentCyan)
                    .font(.system(size: 13, weight: .bold))
                Text("Popover Settings")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.text)
            }
            .padding(.bottom, 2)
            
            Divider().background(theme.cardBorder.opacity(0.8))
            
            // Section 1: Active Monitors
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Active Monitors"))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.subtext)
                    .tracking(1.0)
                    .textCase(.uppercase)
                
                VStack(spacing: 6) {
                    PopoverToggleRow(title: "CPU Tracker", icon: "cpu", isOn: $showCPU, activeColor: theme.accentCyan, theme: theme)
                    PopoverToggleRow(title: "GPU Tracker", icon: "square.grid.3x1.below.line.grid.1x2", isOn: $showGPU, activeColor: theme.accentGreen, theme: theme)
                    PopoverToggleRow(title: "RAM Tracker", icon: "memorychip", isOn: $showRAM, activeColor: theme.accentOrange, theme: theme)
                    PopoverToggleRow(title: "Disk Tracker", icon: "internaldrive", isOn: $showDisk, activeColor: theme.accentPurple, theme: theme)
                    PopoverToggleRow(title: "Network Tracker", icon: "network", isOn: $showNetwork, activeColor: theme.accentCyan, theme: theme)
                }
            }
            
            Divider().background(theme.cardBorder.opacity(0.8))
            
            // Section 2: Shortcut Application
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Shortcut Application"))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.subtext)
                    .tracking(1.0)
                    .textCase(.uppercase)
                
                Text("Launches when double-clicking resource metrics.")
                    .font(.system(size: 10))
                    .foregroundColor(theme.subtext)
                
                HStack(spacing: 8) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 11))
                        .foregroundColor(theme.accentCyan)
                        .frame(width: 16)
                    
                    Picker("", selection: $selectedShortcutOption) {
                        ForEach(presetApps, id: \.self) { app in
                            Text(app).tag(app)
                        }
                        Text("Custom...").tag("Custom")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.cardBorder.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.cardBorder.opacity(0.6), lineWidth: 0.8)
                )
                
                if selectedShortcutOption == "Custom" {
                    TextField("Enter application name or path...", text: $customShortcutPath)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.cardBorder.opacity(0.2))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.cardBorder.opacity(0.6), lineWidth: 0.8)
                        )
                        .padding(.top, 2)
                        .onChange(of: customShortcutPath) { newVal in
                            processApp = newVal
                        }
                }
            }
            .onChange(of: selectedShortcutOption) { newVal in
                if newVal != "Custom" {
                    processApp = newVal
                } else {
                    processApp = customShortcutPath
                }
            }
            .onAppear {
                if presetApps.contains(processApp) {
                    selectedShortcutOption = processApp
                } else {
                    selectedShortcutOption = "Custom"
                    customShortcutPath = processApp
                }
            }
            
            Divider().background(theme.cardBorder.opacity(0.8))
                .padding(.top, 2)
            
            // Section 3: Advanced Preferences Button
            Button(action: {
                ViewController.launch()
                TelemetryModel.shared.selectedTab = .popover
                NotificationCenter.default.post(name: .init("CloseMenuBarPopover"), object: nil)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                    Text("Advanced Preferences...")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [theme.accentCyan, theme.accentCyan.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
                .shadow(color: theme.accentCyan.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .foregroundColor(theme.text)
    }
}

// MARK: - PopoverToggleRow Helper
struct PopoverToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let activeColor: Color
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(isOn ? activeColor : theme.subtext)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.text)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: activeColor))
                .labelsHidden()
                .scaleEffect(0.8)
                .frame(height: 20)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.cardBorder.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.cardBorder.opacity(0.4), lineWidth: 0.6)
        )
    }
}

