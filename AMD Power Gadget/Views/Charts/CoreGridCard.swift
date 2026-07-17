//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI
import Charts

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

