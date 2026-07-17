//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct HorizontalChartsContainer: View {
    @ObservedObject var model: TelemetryModel
    
    @AppStorage("dash_showFreq") var showFrequency = true
    @AppStorage("dash_showTemp") var showTemperature = true
    @AppStorage("dash_showPwr") var showPower = true
    @AppStorage("dash_showCores") var showCores = true
    @AppStorage("mb_showNet") var showNetwork = false
    @AppStorage("mb_showMem") var showMemory = true
    
    @AppStorage("dash_chart_order") var chartOrder = "freq,temp,pwr"
    
    var body: some View {
        let charts = chartOrder.split(separator: ",").map(String.init)
        HStack(alignment: .top, spacing: 12) {
            ForEach(charts, id: \.self) { chartId in
                if chartId == "freq" && showFrequency {
                    ResizableChart(chartId: "dash_freq", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Frequency",
                            accent: .tahoeAccentCyan,
                            unit: "GHz",
                            data: model.history,
                            line1: { $0.cpuFreqGHz },
                            line2: { $0.cpuFreqMaxGHz },
                            line1Label: "Avg",
                            line2Label: "Max",
                            height: height
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .layoutPriority(1)
                }
                if chartId == "temp" && showTemperature {
                    ResizableChart(chartId: "dash_temp", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Temperature",
                            accent: .tahoeAccentOrange,
                            unit: "°C",
                            data: model.history,
                            line1: { $0.cpuTempC },
                            line2: nil,
                            line1Label: "CPU",
                            line2Label: nil,
                            height: height
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .layoutPriority(1)
                }
                if chartId == "pwr" && showPower {
                    ResizableChart(chartId: "dash_pwr", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Power",
                            accent: .tahoeAccentGreen,
                            unit: "W",
                            data: model.history,
                            line1: { $0.cpuWatts },
                            line2: nil,
                            line1Label: "Package",
                            line2Label: nil,
                            height: height
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .layoutPriority(1)
                }
            }
        }
    }
}

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: LocalizedStringKey; let value: String; let accent: Color; let icon: String
    var history: MetricHistory? = nil
    
    var body: some View {
        TahoeCard(accent: accent.opacity(0.18)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon).font(.system(size: 12)).foregroundColor(accent)
                    Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.tahoeSubtext)
                }
                Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.tahoeText)
                
                if let h = history {
                    Sparkline(history: h, accent: accent)
                        .frame(height: 24)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Original-style Line Chart Card
