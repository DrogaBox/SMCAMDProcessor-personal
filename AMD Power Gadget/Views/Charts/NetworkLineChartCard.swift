//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI
import Charts

struct NetworkLineChartCard: View {
    let title: LocalizedStringKey
    @ObservedObject var model: TelemetryModel
    let height: CGFloat

    @AppStorage("net_chart_style") private var chartStyle: Int = 0 // 0: Bars, 1: Overlapping Areas, 2: Total & Average


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

