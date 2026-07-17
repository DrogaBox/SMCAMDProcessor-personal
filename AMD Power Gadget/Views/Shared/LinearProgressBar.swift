//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct LinearProgressBar: View {
    let label: String
    let pct: Double
    let detailText: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(detailText)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(1.0, max(0.0, pct / 100.0))), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 12)
    }
}

