//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

// MARK: - Sidebar
struct SidebarView: View {
    @Binding var selectedTab: DashboardTab
    @ObservedObject var model: TelemetryModel

    var body: some View {
        ZStack {
            // Glass effect like Finder sidebar in macOS Tahoe
            VisualEffectBackground(
                material: .sidebar,
                blendingMode: .behindWindow,
                state: .active,
                cornerRadius: 0
            )
            .ignoresSafeArea()

            // Subtle tint overlay to match the dark glass aesthetic
            Color.tahoeSidebar.opacity(0.15)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AMD Power").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.tahoeText)
                    Text("Gadget").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.tahoeAccentCyan)
                }
                .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 5) {
                    TinyStatRow(label: "CPU", value: String(format: "%.1f°C / %.0fW", model.cpuTempC, model.cpuWatts), color: .tahoeAccentCyan)
                    TinyStatRow(label: "GPU", value: String(format: "%.1f°C / %.0fW", model.gpuTempC, model.gpuPowerW), color: .tahoeAccentOrange)
                    TinyStatRow(label: "Freq", value: String(format: "%.2f GHz", model.cpuFreqMaxGHz), color: .tahoeAccentGreen)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .opacity(0.7)
                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tahoeCardBorder))
                .cornerRadius(10)
                .padding(.horizontal, 10).padding(.bottom, 12)

                ForEach(DashboardTab.allCases) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
                    }
                }
                Spacer()

                // Compact buttons stack
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Button(action: {
                            if let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "safari")
                                    .font(.system(size: 8))
                                Text("GitHub")
                            }
                        }
                        .buttonStyle(SidebarMiniButtonStyle(accent: .tahoeAccentCyan))

                        Button(action: {
                            Task { @MainActor in
                                if let url = Bundle.main.url(forResource: "bravo", withExtension: "mp3") {
                                    if let sound = NSSound(contentsOf: url, byReference: true) {
                                        sound.play()
                                    }
                                }
                            }
                            if let url = URL(string: "https://www.paypal.com/donate/?business=mrleisures@gmail.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                Text("Donate")
                            }
                        }
                        .buttonStyle(SidebarMiniButtonStyle(accent: .tahoeAccentOrange))
                    }

                    if model.isCheckingForUpdates {
                        HStack(spacing: 4) {
                            ProgressView().scaleEffect(0.5).frame(width: 10, height: 10)
                            Text("Checking for updates...").font(.system(size: 8.5)).foregroundColor(.tahoeSubtext)
                        }
                        .padding(.horizontal, 6)
                    } else {
                        Button(action: {
                            if model.updateAvailable {
                                if let u = URL(string: model.releaseURLString) { NSWorkspace.shared.open(u) }
                            } else {
                                model.checkForUpdates(manual: true)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: model.updateAvailable ? "arrow.down.circle" : "arrow.triangle.2.circlepath")
                                    .font(.system(size: 8))
                                Text(model.updateAvailable ? LocalizedStringKey("Download Update") : LocalizedStringKey("Check for Updates"))
                            }
                        }
                        .buttonStyle(SidebarMiniButtonStyle(accent: model.updateAvailable ? .tahoeAccentGreen : .tahoeAccentCyan))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

                Link(destination: URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") ?? URL(fileURLWithPath: "/")) {
                    let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.13.3"
                    let kextVer = model.sysInfo.kextVersion.isEmpty ? "N/A" : model.sysInfo.kextVersion
                    Text("App: v\(appVer) • Kext: v\(kextVer) · macOS Tahoe")
                        .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
            }
        }
    }
}

struct TinyStatRow: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(.tahoeSubtext).frame(width: 30, alignment: .leading)
            Text(value).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(color)
        }
    }
}

struct SidebarItem: View {
    let tab: DashboardTab; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(isSelected ? Color.tahoeAccentCyan : Color.clear).frame(width: 3, height: 20)
                Image(systemName: tab.icon).font(.system(size: 13, weight: .medium)).foregroundColor(isSelected ? .tahoeAccentCyan : .tahoeSubtext).frame(width: 18)
                Text(LocalizedStringKey(tab.rawValue)).font(.system(size: 13, weight: isSelected ? .semibold : .regular)).foregroundColor(isSelected ? .tahoeText : .tahoeSubtext)
                Spacer()
            }
            .padding(.vertical, 7).padding(.trailing, 12)
            .background(isSelected ? Color.tahoeSidebarActive : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

