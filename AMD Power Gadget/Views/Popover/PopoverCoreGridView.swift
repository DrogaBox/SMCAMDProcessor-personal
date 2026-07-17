//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

enum PopoverTab: Int, CaseIterable {
    case telemetry = 0
    case profiles = 1
    case settings = 2
}


// MARK: - Popover Config Tab
struct PopoverCoreGridView: View {
    @ObservedObject var model: TelemetryModel
    
    private var colCount: Int {
        let count = model.cores.count
        if count > 64 { return 12 }
        if count > 32 { return 10 }
        if count > 16 { return 8 }
        if count > 8  { return 6 }
        return 4
    }
    
    private var columns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 3), count: colCount)
    }
    
    private var cellHeight: CGFloat {
        let count = model.cores.count
        if count > 64 { return 14 }
        if count > 32 { return 18 }
        return 24
    }
    
    private var showTextLabels: Bool {
        return model.cores.count <= 32
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CPU Per-Core Thread Load")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(model.cores) { core in
                    GeometryReader { geo in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(Color.black.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3.5)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                                )
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.tahoeAccentCyan.opacity(0.85), Color.tahoeAccentPurple.opacity(0.9)]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .frame(height: geo.size.height * CGFloat(core.loadPct / 100.0))
                            
                            // Labels (adaptive visibility for dense core layouts)
                            if showTextLabels {
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("\(core.id)")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundColor(.white.opacity(0.35))
                                            .padding(.leading, 3)
                                            .padding(.top, 1)
                                        Spacer()
                                    }
                                    Spacer()
                                    Text(String(format: "%.0f%%", core.loadPct))
                                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(.bottom, 1.5)
                                }
                            }
                        }
                    }
                    .frame(height: cellHeight)
                    .help(String(format: "Thread %d: %.1f%%", core.id, core.loadPct))
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }
}

