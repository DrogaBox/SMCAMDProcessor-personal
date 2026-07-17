//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct SparklineShape: Shape {
    let values: [Double]
    let minVal: Double
    let maxVal: Double
    var isFilled: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        
        let range = max(0.001, maxVal - minVal)
        let stepX = rect.width / CGFloat(values.count - 1)
        
        let points = values.enumerated().map { i, val in
            let normY = CGFloat((val - minVal) / range)
            let clampedY = max(0.0, min(1.0, normY))
            let y = rect.height * (1.0 - clampedY)
            let x = CGFloat(i) * stepX
            return CGPoint(x: x, y: y)
        }
        
        path.move(to: points[0])
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        
        if isFilled, let last = points.last {
            path.addLine(to: CGPoint(x: last.x, y: rect.height))
            path.addLine(to: CGPoint(x: points[0].x, y: rect.height))
            path.closeSubpath()
        }
        
        return path
    }
}

struct MiniSparkline: View {
    let label: String
    let currentVal: String
    let color: Color
    let data: [TelemetryPoint]
    let value: (TelemetryPoint) -> Double
    var filterZeros: Bool = false
    
    var body: some View {
        let rawVals = data.map(value)
        let vals = filterZeros ? rawVals.filter { $0 > 0 } : rawVals
        
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Text(currentVal)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 75, alignment: .leading)
            
            if vals.count > 1 {
                let mn = vals.min() ?? 0
                let mx = vals.max() ?? 100
                let diff = mx - mn
                let span = max(10.0, diff)
                let center = (mx + mn) / 2.0
                let yMin = center - span * 0.6
                let yMax = center + span * 0.6
                
                ZStack {
                    SparklineShape(values: vals, minVal: yMin, maxVal: yMax, isFilled: true)
                        .fill(LinearGradient(colors: [color.opacity(0.22), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                    
                    SparklineShape(values: vals, minVal: yMin, maxVal: yMax, isFilled: false)
                        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
                .frame(height: 24)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 24)
                    .overlay(Text("Loading...").font(.system(size: 8)).foregroundColor(.white.opacity(0.3)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

struct Sparkline: View {
    var history: MetricHistory
    var color: Color
    var maxValue: Double? = nil
    var fillOpacity: Double = 0.16
    var lineWidth: CGFloat = 1.5
    var showsZeroBaseline = false

    init(history: MetricHistory, accent: Color, maxValue: Double? = nil) {
        self.history = history
        self.color = accent
        self.maxValue = maxValue
    }

    var body: some View {
        GeometryReader { geometry in
            let baselineY = max(0.5, geometry.size.height - 0.5)
            let points = points(in: geometry.size, baselineY: baselineY)
            if points.count >= 2 {
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: baselineY))
                        points.forEach { path.addLine(to: $0) }
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: baselineY))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(colors: [color.opacity(fillOpacity), color.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    if showsZeroBaseline {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: baselineY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: baselineY))
                        }
                        .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                    }
                    Path { path in
                        path.move(to: points[0])
                        points.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    private func points(in size: CGSize, baselineY: CGFloat) -> [CGPoint] {
        let values = history.values
        guard values.count >= 2 else { return [] }
        let peak = max(maxValue ?? (values.max() ?? 1), 0.0001)
        let topY: CGFloat = 0.5
        let plotHeight = max(1, baselineY - topY)
        let lastIndex = values.count - 1
        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(lastIndex)
            let normalized = min(1, max(0, value / peak))
            let y = baselineY - plotHeight * CGFloat(normalized)
            return CGPoint(x: x, y: y)
        }
    }
}

