//
//  AnalysisViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Analysis Views
//

import SwiftUI
import Charts

struct AnalysisContentView: View {
    @ObservedObject var historyManager = HistoryManager.shared
    @State private var selectedTimeframe: Int = 1 // Hours
    @State private var displayData: [HistoryDataPoint] = []
    @State private var isLoadingData: Bool = false
    @AppStorage("analysis_show_cpuload") private var showCpuLoad: Bool = true
    @AppStorage("analysis_show_thermals") private var showThermals: Bool = true
    @AppStorage("analysis_show_ram") private var showRam: Bool = true
    @AppStorage("analysis_show_gpuload") private var showGpuLoad: Bool = true
    @AppStorage("analysis_show_cpuwatts") private var showCpuWatts: Bool = true
    @AppStorage("analysis_show_cpufreq") private var showCpuFreq: Bool = true

    private func loadChartData() {
        isLoadingData = true
        let tf = selectedTimeframe
        let rawData = historyManager.historyData
        Task.detached(priority: .userInitiated) {
            let pts = HistoryManager.performDownsample(data: rawData, hours: tf)
            await MainActor.run {
                self.displayData = pts
                self.isLoadingData = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header & Filters
            HStack {
                SectionTitle("History & Trends")
                Spacer()
                Picker("Timeframe", selection: $selectedTimeframe) {
                    Text("1h").tag(1)
                    Text("24h").tag(24)
                    Text("7d").tag(24 * 7)
                    Text("30d").tag(24 * 30)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 250)
                .onChange(of: selectedTimeframe) { _ in
                    loadChartData()
                }
            }
            .padding(.horizontal)

            // Dynamic Chart Selectors / Toggles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Text("Visible charts:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    
                    Button(action: { showCpuLoad.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCpuLoad ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showCpuLoad ? Color.tahoeAccentCyan : .tahoeSubtext)
                            Text("CPU Load")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showCpuLoad ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showCpuLoad ? Color.tahoeAccentCyan.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showCpuLoad ? Color.tahoeAccentCyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showThermals.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showThermals ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showThermals ? Color.tahoeAccentRed : .tahoeSubtext)
                            Text("Temperatures")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showThermals ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showThermals ? Color.tahoeAccentRed.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showThermals ? Color.tahoeAccentRed.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showRam.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showRam ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showRam ? Color.tahoeAccentGreen : .tahoeSubtext)
                            Text("RAM Usage")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showRam ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showRam ? Color.tahoeAccentGreen.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showRam ? Color.tahoeAccentGreen.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showGpuLoad.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showGpuLoad ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showGpuLoad ? Color.tahoeAccentPurple : .tahoeSubtext)
                            Text("GPU Load")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showGpuLoad ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showGpuLoad ? Color.tahoeAccentPurple.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showGpuLoad ? Color.tahoeAccentPurple.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showCpuWatts.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCpuWatts ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showCpuWatts ? Color.tahoeAccentOrange : .tahoeSubtext)
                            Text("CPU Power")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showCpuWatts ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showCpuWatts ? Color.tahoeAccentOrange.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showCpuWatts ? Color.tahoeAccentOrange.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showCpuFreq.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCpuFreq ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showCpuFreq ? Color.tahoeAccentCyan : .tahoeSubtext)
                            Text("CPU Frequency")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showCpuFreq ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showCpuFreq ? Color.tahoeAccentCyan.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showCpuFreq ? Color.tahoeAccentCyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    let data = displayData
                    
                    if isLoadingData {
                        VStack {
                            Spacer(minLength: 80)
                            ProgressView()
                                .scaleEffect(0.9)
                            Text(LocalizedStringKey("Loading telemetry trends..."))
                                .font(.system(size: 11))
                                .foregroundColor(Color.tahoeSubtext)
                                .padding(.top, 6)
                            Spacer()
                        }
                    } else if data.isEmpty {
                        VStack {
                            Spacer(minLength: 100)
                            Text(LocalizedStringKey("Not enough data collected yet."))
                               .foregroundColor(Color.tahoeSubtext)
                            Text(LocalizedStringKey("AMD Power Gadget collects data automatically every minute."))
                                .font(.system(size: 11))
                                .foregroundColor(Color.tahoeSubtext.opacity(0.7))
                            Spacer()
                        }
                    } else if !showCpuLoad && !showThermals && !showRam && !showGpuLoad && !showCpuWatts && !showCpuFreq {
                        VStack {
                            Spacer(minLength: 80)
                            Text(LocalizedStringKey("All charts are hidden."))
                                .foregroundColor(Color.tahoeSubtext)
                            Text(LocalizedStringKey("Select a chart in the panel above to view its history."))
                                .font(.system(size: 11))
                                .foregroundColor(Color.tahoeSubtext.opacity(0.7))
                            Spacer()
                        }
                    } else {
                        // CPU Load Chart
                        if showCpuLoad {
                            let maxVal = data.map { $0.cpuLoad }.max() ?? 0.0
                            let minVal = data.map { $0.cpuLoad }.min() ?? 0.0
                            HistoryCard(
                                title: "CPU Load",
                                subtitle: "Average utilization over time",
                                accent: Color.tahoeAccentCyan,
                                peakInfo: String(format: "%.1f%%", maxVal),
                                lowestInfo: String(format: "%.1f%%", minVal)
                            ) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Load %", point.cpuLoad)
                                        )
                                        .foregroundStyle(Color.tahoeAccentCyan)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Load %", point.cpuLoad)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentCyan.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .chartYScale(domain: 0...100)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }
                        
                        // Temperatures Chart (CPU & GPU)
                        if showThermals {
                            let maxCpuTemp = data.map { $0.cpuTemp }.max() ?? 0.0
                            let minCpuTemp = data.map { $0.cpuTemp }.min() ?? 0.0
                            let maxGpuTemp = data.map { $0.gpuTemp }.max() ?? 0.0
                            let minGpuTemp = data.map { $0.gpuTemp }.min() ?? 0.0
                            HistoryCard(
                                title: "Thermal History",
                                subtitle: "CPU and GPU temperatures",
                                accent: Color.tahoeAccentRed,
                                peakInfo: String(format: "CPU %.0f°C / GPU %.0f°C", maxCpuTemp, maxGpuTemp),
                                lowestInfo: String(format: "CPU %.0f°C / GPU %.0f°C", minCpuTemp, minGpuTemp)
                            ) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Temperature", point.cpuTemp)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(by: .value("Series", "CPU Temp"))
                                        
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Temperature", point.gpuTemp)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(by: .value("Series", "GPU Temp"))
                                    }
                                    .chartForegroundStyleScale([
                                        "CPU Temp": Color.tahoeAccentOrange,
                                        "GPU Temp": Color.tahoeAccentPurple
                                    ])
                                    .chartYScale(domain: 20...110)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }
                        
                        // RAM Usage Chart
                        if showRam {
                            let maxVal = data.map { $0.ramUsage }.max() ?? 0.0
                            let minVal = data.map { $0.ramUsage }.min() ?? 0.0
                            HistoryCard(
                                title: "Memory Usage",
                                subtitle: "RAM utilization percentage",
                                accent: Color.tahoeAccentGreen,
                                peakInfo: String(format: "%.1f%%", maxVal),
                                lowestInfo: String(format: "%.1f%%", minVal)
                            ) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("RAM %", point.ramUsage)
                                        )
                                        .foregroundStyle(Color.tahoeAccentGreen)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("RAM %", point.ramUsage)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentGreen.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .chartYScale(domain: 0...100)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }

                        // GPU Load Chart
                        if showGpuLoad {
                            let maxVal = data.map { $0.gpuLoad }.max() ?? 0.0
                            let minVal = data.map { $0.gpuLoad }.min() ?? 0.0
                            HistoryCard(
                                title: "GPU Load",
                                subtitle: "Radeon Graphics utilization percentage",
                                accent: Color.tahoeAccentPurple,
                                peakInfo: String(format: "%.1f%%", maxVal),
                                lowestInfo: String(format: "%.1f%%", minVal)
                            ) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GPU %", point.gpuLoad)
                                        )
                                        .foregroundStyle(Color.tahoeAccentPurple)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GPU %", point.gpuLoad)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentPurple.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .chartYScale(domain: 0...100)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }

                        // CPU Power Chart (Watts)
                        if showCpuWatts {
                            let maxVal = data.map { $0.safeCpuWatts }.max() ?? 0.0
                            let minVal = data.map { $0.safeCpuWatts }.min() ?? 0.0
                            HistoryCard(
                                title: "CPU Package Power",
                                subtitle: "Real-time energy consumption in Watts",
                                accent: Color.tahoeAccentOrange,
                                peakInfo: String(format: "%.1fW", maxVal),
                                lowestInfo: String(format: "%.1fW", minVal)
                            ) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Watts", point.safeCpuWatts)
                                        )
                                        .foregroundStyle(Color.tahoeAccentOrange)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Watts", point.safeCpuWatts)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentOrange.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }

                        // CPU Average Frequency Chart (GHz)
                        if showCpuFreq {
                            let maxVal = data.map { $0.safeCpuFreqAvg }.max() ?? 0.0
                            let minVal = data.map { $0.safeCpuFreqAvg }.min() ?? 0.0
                            HistoryCard(
                                title: "CPU Average Frequency",
                                subtitle: "Average core frequency in GHz",
                                accent: Color.tahoeAccentCyan,
                                peakInfo: String(format: "%.2f GHz", maxVal),
                                lowestInfo: String(format: "%.2f GHz", minVal)
                            ) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GHz", point.safeCpuFreqAvg)
                                        )
                                        .foregroundStyle(Color.tahoeAccentCyan)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GHz", point.safeCpuFreqAvg)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentCyan.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            historyManager.sampleCurrentTelemetry()
            loadChartData()
        }
    }
}

struct HistoryCard<Content: View>: View {
    let title: String
    let subtitle: String
    let accent: Color
    let peakInfo: String?
    let lowestInfo: String?
    let content: Content
    
    init(title: String, subtitle: String, accent: Color, peakInfo: String? = nil, lowestInfo: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.peakInfo = peakInfo
        self.lowestInfo = lowestInfo
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.tahoeText)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.tahoeSubtext)
                }
                Spacer()
                
                if let peak = peakInfo, let lowest = lowestInfo {
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Max:"))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.tahoeSubtext)
                                Text(peak)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(accent)
                            }
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("Min:"))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.tahoeSubtext)
                                Text(lowest)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }
            }
            
            content
        }
        .padding(20)
        .background(Color.tahoeCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.tahoeCardBorder, lineWidth: 1)
        )
    }
}

