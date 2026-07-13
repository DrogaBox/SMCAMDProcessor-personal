//
//  SystemInfoViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — System Info Views
//

import SwiftUI

// MARK: - System Info Content View
struct SystemInfoContentView: View {
    @ObservedObject var model: TelemetryModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle("Processor")
                TahoeCard {
                    InfoRow(label: "CPU Model",      value: model.sysInfo.cpuBrand)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Family",          value: model.sysInfo.cpuFamily)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Model ID",        value: model.sysInfo.cpuModel)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Physical Cores",  value: "\(model.sysInfo.physicalCores)")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Logical Cores",   value: "\(model.sysInfo.logicalCores)")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "L1 Cache (Total)",value: "\(model.sysInfo.l1KB) KB")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "L2 Cache (Total)",value: "\(model.sysInfo.l2MB) MB")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "L3 Cache (Shared)",value: "\(model.sysInfo.l3MB) MB")
                }

                if !model.rankedPhysicalCores.isEmpty {
                    Divider().background(Color.tahoeCardBorder)
                    SectionTitle(model.rankedPhysicalCores.first?.isEstimated == true ? "Core Rankings (Estimated by Freq)" : "CPPC Preferred Cores (Silicon Quality)")
                    CPPCCoreGrid(items: model.rankedPhysicalCores)
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Platform")
                TahoeCard {
                    if !model.sysInfo.boardName.isEmpty {
                        InfoRow(label: "Motherboard", value: model.sysInfo.boardName)
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "Manufacturer", value: model.sysInfo.boardVendor)
                        Divider().background(Color.tahoeCardBorder)
                    }
                    InfoRow(label: "Graphics", value: model.sysInfo.gpuModel.isEmpty ? "Unknown" : model.sysInfo.gpuModel)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Memory",   value: "\(model.sysInfo.ramGB) GB")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Storage",  value: "\(model.sysInfo.storageGB) GB")
                }
                if model.sysInfo.boardName.isEmpty {
                    TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.3)) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle").foregroundColor(.tahoeAccentOrange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Motherboard info not available").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Enable in OC: Misc → Security → ExposeSensitiveData = 0x08").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Software")
                TahoeCard {
                    InfoRow(label: "macOS Version",   value: model.sysInfo.macOSVersion)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Kext Version",    value: model.sysInfo.kextVersion)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "CPU Supported",   value: model.sysInfo.kextSupported ? "Yes" : "Not yet")
                }
            }
            .padding(18)
        }
    }
}
