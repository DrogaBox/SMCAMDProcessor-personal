//
// Auto-extracted during Phase 2 restructure
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
    
    @StateObject private var interaction = ChartInteractionState()

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
                    // Classic chart styles using Swift Charts — with interactive tooltip
                    let indexedData = Array(data.enumerated())
                    let maxIndex = Double(indexedData.count - 1)
                    let totalCount = indexedData.count

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
                .chartXScale(domain: interaction.visibleRange.isEmpty ? 0...maxIndex : Double(interaction.visibleRange.lowerBound)...Double(interaction.visibleRange.upperBound))
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
                .chartHover(interaction: interaction, dataCount: totalCount)
                .frame(height: height)
                .overlay {
                    if let loc = interaction.hoveredLocation,
                       let idx = interaction.hoveredIndex, idx < data.count {
                        let pt = data[idx]
                        let v1 = line1(pt)
                        let fmt1 = (unit == "GHz") ? "%.2f" : "%.1f"
                        ChartTooltipView(
                            accent: accent,
                            line1Label: line1Label,
                            line1Value: String(format: fmt1, v1) + " " + unit,
                            line2Label: line2Label,
                            line2Value: line2.map { String(format: fmt1, $0(pt)) + " " + unit },
                            timestamp: Date(timeIntervalSinceReferenceDate: pt.time)
                        )
                        .position(x: loc.x + 10, y: loc.y - 20)
                    }
                }
                }
            } else {
                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03))
                    .frame(height: height)
                    .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
            }
        }
    }
}

