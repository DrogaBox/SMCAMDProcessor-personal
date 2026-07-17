//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI
import Charts

struct TelemetryContentView: View {
    @ObservedObject var model: TelemetryModel

    @AppStorage("tele_show_cputemp") private var showCpuTemp = true
    @AppStorage("tele_show_gputemp") private var showGpuTemp = true
    @AppStorage("tele_show_cpupwr") private var showCpuPwr = true
    @AppStorage("tele_show_gpupwr") private var showGpuPwr = true
    @AppStorage("tele_show_ram") private var showRam = true
    @AppStorage("tele_show_disk") private var showDisk = true
    @AppStorage("tele_show_net") private var showNet = true
    @AppStorage("tele_show_fan") private var showFan = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("CPU Frequency & Demand")
                ResizableChart(chartId: "tele_bar", small: 100, medium: 140, large: 200) { height in
                    PowerToolBarChart(model: model, height: height)
                }

                HStack {
                    SectionTitle("Live Telemetry History")
                    Spacer()
                    Menu {
                        Toggle("CPU Temperature", isOn: $showCpuTemp)
                        Toggle("GPU Temperature", isOn: $showGpuTemp)
                        Toggle("CPU Package Power", isOn: $showCpuPwr)
                        Toggle("GPU Power", isOn: $showGpuPwr)
                        Toggle("RAM Utilization", isOn: $showRam)
                        Toggle("Disk Activity", isOn: $showDisk)
                        Toggle("Network Speed", isOn: $showNet)
                        Toggle("Fan Speed", isOn: $showFan)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11))
                            Text("Configure Charts")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.tahoeText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }

                if showCpuTemp {
                    ResizableChart(chartId: "tele_cputemp", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "CPU Temperature", unit: "°C", color: .tahoeAccentOrange, data: model.history, value: { $0.cpuTempC }, height: height)
                        }
                    }
                }
                if showGpuTemp {
                    ResizableChart(chartId: "tele_gputemp", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "GPU Temperature", unit: "°C", color: Color(red: 0.8, green: 0.5, blue: 1.0), data: model.history, value: { $0.gpuTempC }, height: height)
                        }
                    }
                }
                if showCpuPwr {
                    ResizableChart(chartId: "tele_cpupwr", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "CPU Package Power", unit: "W", color: .tahoeAccentGreen, data: model.history, value: { $0.cpuWatts }, height: height)
                        }
                    }
                }
                if showGpuPwr {
                    ResizableChart(chartId: "tele_gpupwr", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "GPU Power", unit: "W", color: .tahoeAccentPurple, data: model.history, value: { $0.gpuWatts }, height: height)
                        }
                    }
                }
                if showRam {
                    ResizableChart(chartId: "tele_ram", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "RAM Utilization", unit: "%", color: .tahoeAccentYellow, data: model.history, value: { $0.ramUsagePct }, height: height)
                        }
                    }
                }
                if showDisk {
                    ResizableChart(chartId: "tele_disk", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "Disk Activity (Read+Write)", unit: "MB/s", color: .tahoeAccentBlue, data: model.history, value: { $0.diskReadMBps + $0.diskWriteMBps }, height: height)
                        }
                    }
                }
                if showNet {
                    ResizableChart(chartId: "tele_net", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "Network Total Speed", unit: "MB/s", color: .tahoeAccentCyan, data: model.history, value: { $0.netDownloadMBps + $0.netUploadMBps }, height: height)
                        }
                    }
                }
                if showFan {
                    ResizableChart(chartId: "tele_fan", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "Fan Speed", unit: "RPM", color: Color(red: 0.2, green: 0.8, blue: 0.6), data: model.history, value: { $0.fanRPM }, height: height)
                        }
                    }
                }

                SectionTitle("Current Values")
                TahoeCard {
                    InfoRow(label: "CPU Model",       value: model.sysInfo.cpuBrand)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Avg Frequency",   value: String(format: "%.3f GHz", model.cpuFreqAvgGHz))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Max Frequency",   value: String(format: "%.3f GHz", model.cpuFreqMaxGHz))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "CPU Temperature", value: String(format: "%.2f °C",  model.cpuTempC))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Package Power",   value: String(format: "%.2f W",   model.cpuWatts))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Model",       value: model.sysInfo.gpuModel.isEmpty || model.sysInfo.gpuModel == "Unknown" ? "Radeon GPU" : model.sysInfo.gpuModel)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Metal Version",   value: model.sysInfo.metalVersion)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Temperature", value: String(format: "%.2f °C",  model.gpuTempC))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Power",       value: String(format: "%.2f W",   model.gpuPowerW))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Fan Speed",   value: model.gpuFanRPM > 0 ? String(format: "%.0f RPM", model.gpuFanRPM) : "0 RPM (Zero RPM Mode)")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU VRAM Used",   value: String(format: "%.2f GB",  model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Utilization", value: String(format: "%.1f %%",  model.gpuLoadPct))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "VDA Decoder",     value: model.sysInfo.vdaAcceleration)
                }

                SectionTitle("Diagnostics & CSV Logging")
                TahoeCard(accent: Color.tahoeAccentGreen.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Export Telemetry History").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Export the history of samples currently in memory to a CSV file").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            TahoeButton(label: "Export CSV", icon: "square.and.arrow.up", accent: .tahoeAccentGreen) {
                                let op = NSSavePanel()
                                op.allowedContentTypes = [.init(filenameExtension: "csv") ?? .data]
                                if op.runModal() == .OK, let url = op.url {
                                    model.exportHistoryToCSV(url: url)
                                }
                            }
                        }
                        
                        Divider().background(Color.tahoeCardBorder)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Continuous Background Logging").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Continuously write telemetry samples to a CSV file in the background").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: $model.isLoggingEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentGreen)).labelsHidden()
                        }
                        
                        if model.isLoggingEnabled || !model.logFilePath.isEmpty {
                            Divider().background(Color.tahoeCardBorder)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Log File Location").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text(model.logFilePath.isEmpty ? "No location selected" : model.logFilePath)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(model.logFilePath.isEmpty ? .tahoeAccentOrange : .tahoeSubtext)
                                        .lineLimit(1)
                                }
                                Spacer()
                                TahoeButton(label: "Select File...", icon: "folder", accent: .tahoeAccentGreen) {
                                    let op = NSSavePanel()
                                    op.allowedContentTypes = [.init(filenameExtension: "csv") ?? .data]
                                    if op.runModal() == .OK, let url = op.url {
                                        model.logFilePath = url.path
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Simple Line Chart (for telemetry secondary charts)
