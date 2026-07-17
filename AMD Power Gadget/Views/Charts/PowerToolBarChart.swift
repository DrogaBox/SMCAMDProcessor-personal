//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI
import Charts

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

