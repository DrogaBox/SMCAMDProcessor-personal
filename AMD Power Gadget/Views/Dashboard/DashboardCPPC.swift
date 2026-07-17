//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct PhysicalCoreCPPC: Identifiable {
    let id: Int
    let score: UInt8
    let isEstimated: Bool
    var rank: Int = 0
    
    var rankText: String {
        return "\(rank)."
    }
    
    var scoreText: String {
        return (isEstimated ? "~" : "") + String(score)
    }
}

// Dedicated row view for CPPC grid to avoid Swift WMO type-checker timeouts inside generic TahoeCard closures
struct CPPCCoreGridRow: View {
    let item: RankedPhysicalCore
    
    @ViewBuilder private var rankIcon: some View {
        if item.rank == 1 {
            Image(systemName: "crown.fill").foregroundColor(Color.tahoeAccentOrange)
        } else if item.rank == 2 {
            Image(systemName: "star.fill").foregroundColor(Color.tahoeAccentCyan)
        } else if item.rank == 3 {
            Image(systemName: "star.fill").foregroundColor(Color.white.opacity(0.5))
        } else {
            Image(systemName: "cpu").foregroundColor(Color.white.opacity(0.2))
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(item.rankText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.white.opacity(0.4))
                .frame(width: 22, alignment: .trailing)
            rankIcon
            Text("Core \(item.id)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white)
            Spacer()
            Text(item.scoreText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(item.score > 200 ? Color.tahoeAccentGreen : (item.score > 150 ? Color.tahoeAccentOrange : Color.tahoeSubtext))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.04))
                .cornerRadius(4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .cornerRadius(6)
    }
}

struct CPPCCoreGrid: View {
    let items: [RankedPhysicalCore]
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items, id: \.id) { item in
                    CPPCCoreGridRow(item: item)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.tahoeCard)
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tahoeCardBorder, lineWidth: 1))
        .cornerRadius(14)
    }
}


