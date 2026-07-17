//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct StatCardsHeaderRow: View {
    @ObservedObject var model: TelemetryModel
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(label: "CPU Temp",  value: String(format: "%.1f°C",   model.cpuTempC),     accent: PanelMetricColor.cyan(for: colorScheme),   icon: "thermometer.medium", history: model.cpuTempHistory)
            StatCard(label: "CPU Power", value: String(format: "%.1fW",    model.cpuWatts),     accent: PanelMetricColor.orange(for: colorScheme), icon: "bolt.fill", history: model.cpuPowerHistory)
            StatCard(label: "GPU Temp",  value: String(format: "%.1f°C",   model.gpuTempC),     accent: PanelMetricColor.green(for: colorScheme),  icon: "cpu.fill", history: model.gpuTempHistory)
            StatCard(label: "GPU Power", value: String(format: "%.1fW",    model.gpuPowerW),    accent: PanelMetricColor.pink(for: colorScheme),   icon: "bolt.square.fill", history: model.gpuPowerHistory)
        }
    }
}

struct CPUProfileBadgeView: View {
    @ObservedObject var model: TelemetryModel
    
    var body: some View {
        if model.isSystemInfoLoaded && !model.processorCPUProfile.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.tahoeAccentCyan)
                
                Text(model.processorCPUProfile)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.tahoeSubtext)
                
                if !model.processorCPUProfileFeatures.isEmpty {
                    Text(model.processorCPUProfileFeatures)
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(.tahoeAccentCyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.tahoeAccentCyan.opacity(0.12))
                        .cornerRadius(3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.tahoeCard.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.tahoeCardBorder, lineWidth: 0.5)
            )
        }
    }
}

struct MemoryCard: View {
    @ObservedObject var model: TelemetryModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TahoeCard(accent: Color.tahoeCardBorder) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Memory")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.tahoeText)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.tahoeSubtext)
                        Text("Pressure")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.tahoeSubtext)
                        
                        // Green dot + Normal badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(model.memoryPressureColor)
                                .frame(width: 5, height: 5)
                            Text(model.memoryPressure)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(model.memoryPressureColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(model.memoryPressureColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                    let totalRAM = Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0)
                    Text(String(format: "%.2f GB / %.0f GB", usedGB, totalRAM))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.tahoeText)
                }
                
                Sparkline(history: model.ramHistory, accent: .orange, maxValue: Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                    .frame(maxHeight: .infinity)
                    .frame(minHeight: 20)
                    .padding(.top, 4)
                
                Divider().background(Color.tahoeCardBorder)
                
                HStack(spacing: 12) {
                    // Uptime
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.tahoeSubtext)
                        Text("Up for \(model.systemUptimeFormatted)")
                            .font(.system(size: 10))
                            .foregroundColor(.tahoeSubtext)
                    }
                    
                    Spacer()
                    
                    // Battery (if present)
                    if model.hasBattery {
                        HStack(spacing: 4) {
                            Image(systemName: model.batteryIsCharging ? "battery.100.bolt" : "battery.100")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                            Text("Battery: \(model.batteryPercentage)%")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "powerplug")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                            Text("AC Power")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}
