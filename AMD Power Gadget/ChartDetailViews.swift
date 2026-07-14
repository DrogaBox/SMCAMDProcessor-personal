//
//  ChartDetailViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Detailed Chart Views
//

import SwiftUI
import Charts

struct OriginalLineChartCard: View {
    let title: LocalizedStringKey
    let accent: Color
    let unit: String
    let data: [TelemetryPoint]
    let line1: (TelemetryPoint) -> Double
    let line2: ((TelemetryPoint) -> Double)?
    let line1Label: LocalizedStringKey
    let line2Label: LocalizedStringKey?
    let height: CGFloat

    @AppStorage(AppChartStyle.storageKey) private var selectedChartStyleRaw: String = AppChartStyle.line.rawValue
    private var selectedChartStyle: AppChartStyle { AppChartStyle.normalized(selectedChartStyleRaw) }

    private var averageVal: Double {
        let vals = data.map(line1)
        guard !vals.isEmpty else { return 0.0 }
        return vals.reduce(0, +) / Double(vals.count)
    }
    
    private var maxVal: Double {
        if let l2 = line2 {
            return data.map(l2).max() ?? 0.0
        }
        return data.map(line1).max() ?? 0.0
    }
    
    private var minVal: Double {
        return data.map(line1).min() ?? 0.0
    }
    
    private var averageString: String {
        let fmt = (unit == "GHz") ? "%.2f" : "%.1f"
        return String(format: "\(NSLocalizedString("Prom.", comment: "")): \(fmt) %@", averageVal, unit)
    }
    private var maxString: String {
        let fmt = (unit == "GHz") ? "%.2f" : "%.1f"
        return String(format: "\(NSLocalizedString("Máx.", comment: "")): \(fmt) %@", maxVal, unit)
    }
    private var minString: String {
        let fmt = (unit == "GHz") ? "%.2f" : "%.1f"
        return String(format: "\(NSLocalizedString("Mín.", comment: "")): \(fmt) %@", minVal, unit)
    }

    private var yMin: Double {
        var vals = data.map(line1)
        if let l2 = line2 { vals.append(contentsOf: data.map(l2)) }
        let m = vals.min() ?? 0
        let mx = vals.max() ?? 1
        let pad = (mx - m) * 0.1
        return m - pad
    }
    private var yMax: Double {
        var vals = data.map(line1)
        if let l2 = line2 { vals.append(contentsOf: data.map(l2)) }
        let m = vals.max() ?? 1
        let mn = vals.min() ?? 0
        let pad = (m - mn) * 0.1
        return m + pad
    }

    var body: some View {
        TahoeCard(accent: accent.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.tahoeText)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(averageString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    Text(maxString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    Text(minString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                }
            }

            if data.count > 1 {
                // Use optimized lightweight components when selected
                if selectedChartStyle == .lightweightArea {
                    LightweightAreaChart(
                        data: data.map(line1),
                        color: accent,
                        minValue: yMin,
                        maxValue: yMax
                    )
                    .frame(height: height)
                } else if selectedChartStyle == .minimalistLine {
                    MinimalistSparkline(
                        values: data.map(line1),
                        color: accent,
                        lineWidth: 2.0
                    )
                    .frame(height: height)
                } else if selectedChartStyle == .gradientBar {
                    VStack(spacing: 8) {
                        CompactGradientBar(
                            value: averageVal,
                            maxValue: yMax,
                            colors: [accent.opacity(0.6), accent],
                            showPercentage: false
                        )
                        .frame(height: 20)
                        
                        HStack {
                            Text(String(format: "%.1f %@", averageVal, unit))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(accent)
                            Spacer()
                        }
                    }
                    .frame(height: height)
                } else if selectedChartStyle == .compactCard {
                    CompactLineChartCard(
                        title: title,
                        data: data.map(line1),
                        color: accent,
                        unit: unit,
                        height: height - 40
                    )
                } else {
                    // Classic chart styles using Swift Charts
                    let indexedData = Array(data.enumerated())
                    let maxIndex = Double(indexedData.count - 1)

                    Chart(indexedData, id: \.element.id) { index, pt in
                        if selectedChartStyle == .bar {
                        BarMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                    } else if selectedChartStyle == .filledArea {
                        AreaMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accent.opacity(0.65), accent.opacity(0.05)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    } else if selectedChartStyle == .steppedLine {
                        LineMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.stepCenter)
                    } else {
                        LineMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: yMin...yMax)
                .chartXScale(domain: 0...maxIndex)
                .chartYAxis {
                    let strideValue = (unit == "GHz") ? max(0.1, (yMax - yMin) / 3.0) : max(1.0, (yMax - yMin) / 3.0)
                    AxisMarks(position: .leading, values: .stride(by: strideValue)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                let fmt = (unit == "GHz") ? "%.2f" : ((unit == "W") ? "%.1f" : "%.0f")
                                Text(String(format: fmt, v))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: height)
                }
            } else {
                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03))
                    .frame(height: height)
                    .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
            }
        }
    }
}

struct SimpleLineChart: View {
    let title: String
    let unit: String
    let color: Color
    let data: [TelemetryPoint]
    let value: (TelemetryPoint) -> Double
    let height: CGFloat

    private var yMin: Double {
        let vals = data.map(value)
        let m = vals.min() ?? 0
        let mx = vals.max() ?? 1
        return m - (mx - m) * 0.1
    }
    private var yMax: Double {
        let vals = data.map(value)
        let m = vals.max() ?? 1
        let mn = vals.min() ?? 0
        return m + (m - mn) * 0.1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                Spacer()
                if let last = data.last {
                    Text(String(format: "%.1f %@", value(last), unit))
                        .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(color)
                }
            }
            if data.count > 1 {
                let indexedData = Array(data.enumerated())
                let maxIndex = Double(indexedData.count - 1)

                Chart(indexedData, id: \.element.id) { index, pt in
                    AreaMark(x: .value("Index", Double(index)), y: .value(title, value(pt)))
                        .foregroundStyle(LinearGradient(colors: [color.opacity(0.28), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Index", Double(index)), y: .value(title, value(pt)))
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: yMin...yMax)
                .chartXScale(domain: 0...maxIndex)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: max(1, (yMax - yMin) / 4))) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.07))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(String(format: "%.0f", v)).font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }
                .frame(height: height)
                .shadow(color: color.opacity(0.25), radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03)).frame(height: height)
                    .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
            }
        }
    }
}

// MARK: - Power Tool Style Bar Chart
struct PowerToolBarChart: View {
    @ObservedObject var model: TelemetryModel
    let height: CGFloat

    var body: some View {
        TahoeCard(accent: Color.tahoeCardBorder) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Frequency Max:").font(.system(size: 11)).foregroundColor(.tahoeAccentCyan)
                        Text(String(format: "%.1f Ghz", model.cpuFreqMaxGHz))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.tahoeText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inst(s) Retired:").font(.system(size: 11)).foregroundColor(.tahoeAccentRed)
                        Text(model.instRetiredFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.tahoeText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .frame(width: 140, alignment: .leading)

                if model.history.count > 1 {
                    let recent = Array(model.history.suffix(30))
                    let maxFreq = recent.map { $0.cpuFreqMaxGHz }.max() ?? 4.0
                    let maxInst = recent.map { Double($0.instRetired) }.max() ?? 1.0

                    GeometryReader { geo in
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(recent) { pt in
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color.tahoeAccentCyan.opacity(0.7))
                                        .frame(
                                            width: max(2, (geo.size.width / CGFloat(recent.count)) - 2),
                                            height: geo.size.height * CGFloat(pt.cpuFreqMaxGHz / max(maxFreq, 0.1))
                                        )
                                    Rectangle()
                                        .fill(Color.tahoeAccentRed.opacity(0.5))
                                        .frame(
                                            width: max(2, (geo.size.width / CGFloat(recent.count)) - 2),
                                            height: geo.size.height * CGFloat(min(Double(pt.instRetired) / max(maxInst, 1.0), 1.0))
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                    .frame(height: height)
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03)).frame(height: height)
                        .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
                }
            }
        }
    }
}

// MARK: - Network Line Chart Card
struct NetworkLineChartCard: View {
    let title: LocalizedStringKey
    @ObservedObject var model: TelemetryModel
    let height: CGFloat

    @AppStorage("net_chart_style") private var chartStyle: Int = 0 // 0: Bars, 1: Overlapping Areas, 2: Total & Average

    private func formatSpeed(_ mbps: Double) -> String {
        let absMbps = abs(mbps)
        let bytesPerSec = absMbps * 1024.0 * 1024.0
        if bytesPerSec >= 1024.0 * 1024.0 {
            let val = bytesPerSec / (1024.0 * 1024.0)
            return String(format: "%.2f MB/s", locale: Locale.current, val)
        } else if bytesPerSec >= 1024.0 {
            let val = bytesPerSec / 1024.0
            return String(format: "%.2f KB/s", locale: Locale.current, val)
        } else if bytesPerSec >= 1.0 {
            let val = bytesPerSec / 1024.0
            return String(format: "%.3f KB/s", locale: Locale.current, val)
        } else {
            return "0 KB/s"
        }
    }

    private var maxUpload: Double {
        model.history.map { $0.netUploadMBps }.max() ?? 0.05
    }

    private var maxDownload: Double {
        model.history.map { $0.netDownloadMBps }.max() ?? 0.05
    }

    private var yScaleLimit: Double {
        max(maxUpload, maxDownload, 0.05)
    }

    private var yMax: Double {
        yScaleLimit
    }

    private var yMin: Double {
        -yScaleLimit
    }

    private var yDomainMax: Double {
        yScaleLimit * 1.15
    }

    private var yDomainMin: Double {
        -yScaleLimit * 1.15
    }

    private var xMin: Double {
        model.history.first?.time ?? 0.0
    }

    private var xMax: Double {
        model.history.last?.time ?? 1.0
    }

    var body: some View {
        TahoeCard(accent: Color.tahoeAccentRed.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 8) {
                // Header (Title & Style Switcher & Upload Speed)
                HStack(alignment: .center) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.tahoeText)
                    
                    Spacer()
                    
                    // Segmented Switcher (Tab bar style)
                    HStack(spacing: 2) {
                        ForEach(0..<3) { styleIdx in
                            let label = styleIdx == 0 ? "Barras" : (styleIdx == 1 ? "Curvas" : "Total")
                            Text(label)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(chartStyle == styleIdx ? .white : .tahoeSubtext)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(chartStyle == styleIdx ? Color.tahoeSidebarActive : Color.clear)
                                .cornerRadius(5)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        chartStyle = styleIdx
                                    }
                                }
                        }
                    }
                    .padding(2)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)

                    Spacer().frame(width: 12)

                    // Upload Speed on far right of header (fixed width container prevents button jitter)
                    if let last = model.history.last {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.tahoeAccentPurple)
                            Text(formatSpeed(last.netUploadMBps))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentPurple)
                        }
                        .frame(minWidth: 95, alignment: .trailing)
                    }
                }

                // Chart in the middle (changes based on style selection)
                if model.history.count > 1 {
                    let indexedData = Array(model.history.enumerated())
                    let maxIndex = Double(max(1, indexedData.count - 1))

                    if chartStyle == 0 {
                        // Style 0: Bidirectional Bars (Quantitative X-axis)
                        Chart {
                            ForEach(indexedData, id: \.element.id) { index, pt in
                                BarMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Upload", pt.netUploadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentPurple)
                            }

                            ForEach(indexedData, id: \.element.id) { index, pt in
                                BarMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Download", -pt.netDownloadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentBlue)
                            }
                        }
                        .chartYScale(domain: yDomainMin...yDomainMax)
                        .chartXScale(domain: 0...maxIndex)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: [yMin, 0.0, yMax]) { val in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(formatSpeed(v))
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.tahoeSubtext)
                                    }
                                }
                            }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: height)
                    } else if chartStyle == 1 {
                        // Style 1: Overlapping Area Curves (Quantitative X-axis, smooth)
                        let maxVal = max(maxUpload, maxDownload, 0.05)
                        let yLimitMax = maxVal * 1.15
                        let yAxisVals = [0.0, maxVal / 2.0, maxVal]

                        Chart {
                            ForEach(indexedData, id: \.element.id) { index, pt in
                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Download"))
                                .opacity(0.25)
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Download"))
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netUploadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Upload"))
                                .opacity(0.20)
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netUploadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Upload"))
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartForegroundStyleScale([
                            "Download": Color.tahoeAccentBlue,
                            "Upload": Color.tahoeAccentPurple
                        ])
                        .chartYScale(domain: 0.0...yLimitMax)
                        .chartXScale(domain: 0...maxIndex)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: yAxisVals) { val in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(formatSpeed(v))
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.tahoeSubtext)
                                    }
                                }
                            }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: height)
                    } else {
                        // Style 2: Total & Split (Layered Download & Upload with Total Line)
                        let maxTotal = model.history.map { $0.netUploadMBps + $0.netDownloadMBps }.max() ?? 0.05
                        let yLimitMax = maxTotal * 1.15
                        let yAxisVals = [0.0, maxTotal / 2.0, maxTotal]
                        let averageTotal = model.history.map { $0.netUploadMBps + $0.netDownloadMBps }.reduce(0, +) / Double(max(1, model.history.count))

                        Chart {
                            ForEach(indexedData, id: \.element.id) { index, pt in
                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Download"))
                                .opacity(0.30)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps + pt.netUploadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Upload"))
                                .opacity(0.20)
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps + pt.netUploadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentOrange)
                                .lineStyle(StrokeStyle(lineWidth: 2.0))
                                .interpolationMethod(.catmullRom)
                            }

                            RuleMark(y: .value("Average", averageTotal))
                                .foregroundStyle(Color.tahoeSubtext.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Avg: \(formatSpeed(averageTotal))")
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundColor(.tahoeSubtext)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.tahoeBackground.opacity(0.75))
                                        .cornerRadius(4)
                                }
                        }
                        .chartForegroundStyleScale([
                            "Download": Color.tahoeAccentBlue,
                            "Upload": Color.tahoeAccentPurple
                        ])
                        .chartYScale(domain: 0.0...yLimitMax)
                        .chartXScale(domain: 0...maxIndex)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: yAxisVals) { val in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(formatSpeed(v))
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.tahoeSubtext)
                                    }
                                }
                            }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: height)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03))
                        .frame(height: height)
                        .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
                }

                // Footer (Download Speed, aligned down at the bottom of the card)
                if let last = model.history.last {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.tahoeAccentBlue)
                            Text(formatSpeed(last.netDownloadMBps))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentBlue)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Core Grid
struct CoreGridCard: View {
    @ObservedObject var model: TelemetryModel
    @AppStorage("sort_cores_by_ranking") private var sortCoresByRanking = false
    @AppStorage("grid_show_load") private var gridShowLoad = true
    @AppStorage("grid_show_freq") private var gridShowFreq = true
    @AppStorage("grid_show_temp") private var gridShowTemp = true
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    /// Badge is about **hardware CPPC ranking**, not the Profiles “Active Mode (EPP)” toggle.
    private var cppcBadgeLabel: String {
        if model.cppcActiveMode {
            return NSLocalizedString("CPPC: EPP On", comment: "Core grid badge — Active Mode enabled")
        }
        if model.cppcScoresEstimated {
            return NSLocalizedString("CPPC: Estimated", comment: "Core grid badge — ranking estimated")
        }
        return NSLocalizedString("CPPC: HW OK", comment: "Core grid badge — hardware CPPC scores present, EPP mode may still be off")
    }

    private var cppcBadgeHelp: String {
        if model.cppcActiveMode {
            return NSLocalizedString(
                "Native CPPC Active Mode (EPP) is ON. Cores scale autonomously; rankings come from the processor.",
                comment: ""
            )
        }
        if model.cppcScoresEstimated {
            return NSLocalizedString(
                "CPPC hardware scores could not be read. Rankings are estimated from observed clocks. This is not the Profiles EPP toggle.",
                comment: ""
            )
        }
        return NSLocalizedString(
            "The CPU reports CPPC rankings (HW OK). That does not mean Active Mode is on — enable “Native CPPC Active Mode (EPP)” under Profiles (needs -amdpnopchk or root).",
            comment: ""
        )
    }

    private var displayCores: [CoreSnapshot] {
        if sortCoresByRanking {
            return model.cores.sorted { (c1, c2) -> Bool in
                let r1 = c1.coreRank ?? 999
                let r2 = c2.coreRank ?? 999
                if r1 != r2 {
                    return r1 < r2
                }
                if c1.isLogical != c2.isLogical {
                    return !c1.isLogical
                }
                return c1.id < c2.id
            }
        } else {
            return model.cores
        }
    }

    /// Checkbox + single-line label that never compresses into per-character wrapping.
    @ViewBuilder
    private func gridHUDToggle(_ key: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(NSLocalizedString(key, comment: "Core grid HUD metric toggle"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.tahoeSubtext)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .toggleStyle(.checkbox)
        .fixedSize(horizontal: true, vertical: false)
    }

    var body: some View {
        TahoeCard {
            // Two-row header: title on top; controls on a single non-wrapping row.
            // (One cramped HStack was breaking ES labels into "Te mp ." / "Fr ec .")
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Current Utilization — \(model.sysInfo.logicalCores) Threads (\(model.sysInfo.physicalCores) Cores)")

                HStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 12) {
                        gridHUDToggle("Temp", isOn: $gridShowTemp)
                        gridHUDToggle("Freq", isOn: $gridShowFreq)
                        gridHUDToggle("Load", isOn: $gridShowLoad)
                    }

                    Spacer(minLength: 8)

                    Toggle(isOn: $sortCoresByRanking) {
                        Text(NSLocalizedString("Sort by Rank", comment: ""))
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue))
                    .fixedSize(horizontal: true, vertical: false)

                    if model.cppcSupported {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9))
                                .foregroundColor(model.cppcActiveMode ? .tahoeAccentGreen : (model.cppcScoresEstimated ? .tahoeAccentOrange : .tahoeAccentCyan))
                            Text(cppcBadgeLabel)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(model.cppcActiveMode ? .tahoeAccentGreen : (model.cppcScoresEstimated ? .tahoeAccentOrange : .tahoeAccentCyan))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            if model.cppcScoresEstimated {
                                Text("~")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.tahoeAccentOrange)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(4)
                        .help(cppcBadgeHelp)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .padding(.bottom, 4)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(displayCores) { core in
                    CoreCell(
                        core: core,
                        ccdTemperatures: model.ccdTemperatures,
                        physicalCoresCount: model.sysInfo.physicalCores,
                        showRanking: sortCoresByRanking,
                        showLoad: gridShowLoad,
                        showFreq: gridShowFreq,
                        showTemp: gridShowTemp
                    )
                }
            }
        }
    }
}

private struct CoreCell: View {
    let core: CoreSnapshot
    let ccdTemperatures: [Float]
    let physicalCoresCount: Int
    let showRanking: Bool
    let showLoad: Bool
    let showFreq: Bool
    let showTemp: Bool

    private var loadColor: Color {
        if core.loadPct > 80 { return Color(red: 1.0, green: 0.35, blue: 0.3) }
        if core.loadPct > 50 { return Color(red: 1.0, green: 0.75, blue: 0.1) }
        return Color.tahoeAccentGreen
    }

    private var labelText: String {
        let base = core.isLogical ? "T\(core.id + 1)" : "C\(core.id + 1)"
        var parts: [String] = []
        if showRanking, let rank = core.coreRank {
            parts.append("#\(rank)")
        }
        parts.append(base)
        if let score = core.cppcScore, score > 0 {
            let prefix = core.cppcScoreEstimated ? "~" : ""
            parts.append("[\(prefix)\(score)]")
        }
        return parts.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(labelText)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(core.isLogical ? Color.tahoeSubtext.opacity(0.7) : .tahoeSubtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if showLoad {
                    Spacer()
                    Text(String(format: "%.0f%%", core.loadPct))
                        .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(loadColor)
                }
            }

            if showLoad {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06)).frame(height: 3)
                        Capsule().fill(loadColor)
                            .frame(width: geo.size.width * CGFloat(core.loadPct / 100.0), height: 3)
                            .shadow(color: loadColor.opacity(0.7), radius: 2)
                    }
                }
                .frame(height: 3)
            }

            if showFreq || showTemp {
                HStack {
                    if showFreq {
                        Text(String(format: "%.0f MHz", core.freqMHz))
                            .font(.system(size: 8, design: .monospaced)).foregroundColor(.tahoeSubtext)
                    }
                    
                    let limitPhys = physicalCoresCount > 0 ? physicalCoresCount : 16
                    let ccdIdx = (core.id % limitPhys) / 8
                    
                    if showFreq && showTemp && ccdTemperatures.count > ccdIdx {
                        Spacer()
                    }
                    
                    if showTemp {
                        if ccdTemperatures.count > ccdIdx {
                            Text(String(format: "%.0f°C", ccdTemperatures[ccdIdx]))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentRed)
                        }
                    }
                }
            }
        }
        .padding(6)
        .background(Color.tahoeBackground.opacity(0.6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(loadColor.opacity(0.2)))
        .cornerRadius(6)
    }
}

// MARK: - Fan Control Tab


// MARK: - Advanced Tab

// MARK: - System Info Tab
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
