//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct InteractiveFanCurveEditor: View {
    @ObservedObject var model: TelemetryModel
    @State private var selectedCurveIndex: Int = 0
    @State private var hoveredPointIndex: Int? = nil
    
    var body: some View {
        guard selectedCurveIndex < model.customCurves.count else {
            return AnyView(Text("No curves configured."))
        }
        
        let curve = model.customCurves[selectedCurveIndex]
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // Curve Selector and Controls
                HStack(spacing: 8) {
                    Text("Curve").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeSubtext)
                    Picker("", selection: $selectedCurveIndex) {
                        ForEach(0..<model.customCurves.count, id: \.self) { idx in
                            Text(model.customCurves[idx].name).tag(idx)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 160)
                    
                    TextField("Name", text: Binding(
                        get: { curve.name },
                        set: { newVal in
                            var updated = model.customCurves
                            updated[selectedCurveIndex].name = newVal
                            model.customCurves = updated
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temp Source").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        Picker("", selection: Binding(
                            get: { curve.sourceSensor },
                            set: { newVal in
                                var updated = model.customCurves
                                updated[selectedCurveIndex].sourceSensor = newVal
                                model.customCurves = updated
                            }
                        )) {
                            Text("CPU Temp").tag(FanSensor.cpu)
                            Text("GPU Temp").tag(FanSensor.gpu)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Hysteresis").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            Spacer()
                            Text("\(Int(curve.hysteresis))°C").font(.system(size: 10, weight: .bold)).foregroundColor(.tahoeAccentOrange)
                        }
                        Slider(value: Binding(
                            get: { curve.hysteresis },
                            set: { newVal in
                                var updated = model.customCurves
                                updated[selectedCurveIndex].hysteresis = newVal
                                model.customCurves = updated
                            }
                        ), in: 1...5, step: 1)
                        .accentColor(.tahoeAccentOrange)
                        .frame(width: 120)
                    }
                    .frame(width: 120)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Ramp Rate").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            Spacer()
                            Text("\(Int(curve.rampRate))%/s").font(.system(size: 10, weight: .bold)).foregroundColor(.tahoeAccentOrange)
                        }
                        Slider(value: Binding(
                            get: { curve.rampRate },
                            set: { newVal in
                                var updated = model.customCurves
                                updated[selectedCurveIndex].rampRate = newVal
                                model.customCurves = updated
                            }
                        ), in: 1...20, step: 1)
                        .accentColor(.tahoeAccentOrange)
                        .frame(width: 120)
                    }
                    .frame(width: 120)
                }
                
                // 2D Graph Area
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    ZStack {
                        // Background Grid
                        Canvas { context, size in
                            let gridColor = Color.tahoeCardBorder.opacity(0.6)
                            
                            // Horizontal lines (PWM)
                            for i in 0...5 {
                                let y = CGFloat(i) * size.height / 5
                                var path = Path()
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                                context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                
                                // PWM Labels
                                let pwmPct = 100 - i * 20
                                if pwmPct > 0 {
                                    context.draw(Text("\(pwmPct)%").font(.system(size: 8)).foregroundColor(.tahoeSubtext), at: CGPoint(x: 12, y: y - 6), anchor: .leading)
                                }
                            }
                            
                            // Vertical lines (Temp)
                            for i in 0...5 {
                                let x = CGFloat(i) * size.width / 5
                                var path = Path()
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                                context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                
                                // Temp Labels
                                let tempC = i * 20
                                if tempC > 0 {
                                    context.draw(Text("\(tempC)°C").font(.system(size: 8)).foregroundColor(.tahoeSubtext), at: CGPoint(x: x + 2, y: size.height - 10), anchor: .leading)
                                }
                            }
                        }
                        
                        // Line Path connecting points
                        Path { path in
                            let sorted = curve.points.sorted { $0.temp < $1.temp }
                            guard let firstPt = sorted.first else { return }
                            
                            path.move(to: CGPoint(x: CGFloat(firstPt.temp / 100.0) * w, y: h - CGFloat(firstPt.pwm / 100.0) * h))
                            
                            for pt in sorted.dropFirst() {
                                path.addLine(to: CGPoint(x: CGFloat(pt.temp / 100.0) * w, y: h - CGFloat(pt.pwm / 100.0) * h))
                            }
                        }
                        .stroke(Color.tahoeAccentOrange, lineWidth: 2)
                        
                        // Interactive points
                        ForEach(curve.points.indices, id: \.self) { ptIdx in
                            let pt = curve.points[ptIdx]
                            let ptX = CGFloat(pt.temp / 100.0) * w
                            let ptY = h - CGFloat(pt.pwm / 100.0) * h
                            
                            Circle()
                                .fill(hoveredPointIndex == ptIdx ? Color.tahoeAccentCyan : Color.tahoeAccentOrange)
                                .frame(width: 10, height: 10)
                                .position(x: ptX, y: ptY)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { val in
                                            let newX = max(0, min(w, val.location.x))
                                            let newY = max(0, min(h, val.location.y))
                                            
                                            var updated = model.customCurves
                                            updated[selectedCurveIndex].points[ptIdx].temp = Double(newX / w) * 100.0
                                            updated[selectedCurveIndex].points[ptIdx].pwm = Double((h - newY) / h) * 100.0
                                            model.customCurves = updated
                                        }
                                )
                                .onTapGesture(count: 2) {
                                    if curve.points.count > 2 {
                                        var updated = model.customCurves
                                        updated[selectedCurveIndex].points.remove(at: ptIdx)
                                        model.customCurves = updated
                                    }
                                }
                                .onHover { hovering in
                                    hoveredPointIndex = hovering ? ptIdx : nil
                                }
                                .contextMenu {
                                    Button("Delete Point") {
                                        if curve.points.count > 2 {
                                            var updated = model.customCurves
                                            updated[selectedCurveIndex].points.remove(at: ptIdx)
                                            model.customCurves = updated
                                        }
                                    }
                                }
                        }
                    }
                    .background(BlockWindowDragView())
                    .background(Color.tahoeCardBorder.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.tahoeCardBorder, lineWidth: 1)
                    )
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { val in
                                let tapX = val.location.x
                                let tapY = val.location.y
                                
                                let tooClose = curve.points.contains { pt in
                                    let ptX = CGFloat(pt.temp / 100.0) * w
                                    let ptY = h - CGFloat(pt.pwm / 100.0) * h
                                    let dist = sqrt(pow(tapX - ptX, 2) + pow(tapY - ptY, 2))
                                    return dist < 12
                                }
                                
                                if !tooClose && curve.points.count < 8 {
                                    let newTemp = Double(tapX / w) * 100.0
                                    let newPWM = Double((h - tapY) / h) * 100.0
                                    var updated = model.customCurves
                                    updated[selectedCurveIndex].points.append(FanCurvePoint(temp: newTemp, pwm: newPWM))
                                    updated[selectedCurveIndex].points.sort { $0.temp < $1.temp }
                                    model.customCurves = updated
                                }
                            }
                    )
                }
                .frame(height: 180)
                
                Text("Drag control points to edit curve. Double-click empty space to add (max 8). Double-click a point or right-click to delete.")
                    .font(.system(size: 9)).foregroundColor(.tahoeSubtext)
            }
        )
    }
}

