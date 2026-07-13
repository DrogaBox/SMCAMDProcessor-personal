//
//  ChartComponents.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Reusable Chart Components
//

import SwiftUI

// MARK: - Resizable Chart Wrapper with Right-Click Menu
struct ResizableChart<Content: View>: View, Equatable {
    let chartId: String
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    @ViewBuilder let content: (CGFloat) -> Content

    @State private var currentHeight: CGFloat
    @State private var showMenu = false

    static func == (lhs: ResizableChart<Content>, rhs: ResizableChart<Content>) -> Bool {
        lhs.chartId == rhs.chartId &&
        lhs.small == rhs.small &&
        lhs.medium == rhs.medium &&
        lhs.large == rhs.large
    }

    init(chartId: String, small: CGFloat = 60, medium: CGFloat = 100, large: CGFloat = 160, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.chartId = chartId
        self.small = small
        self.medium = medium
        self.large = large
        self.content = content
        let saved = UserDefaults.standard.double(forKey: "chart_h_\(chartId)")
        _currentHeight = State(initialValue: saved > 0 ? CGFloat(saved) : medium)
    }

    var body: some View {
        content(currentHeight)
            .contextMenu { ChartContextMenu(chart: cleanChartName) }
            .onReceive(NotificationCenter.default.publisher(for: .init("DashboardLayoutChanged"))) { _ in
                let saved = UserDefaults.standard.double(forKey: "chart_h_\(chartId)")
                if saved > 0 {
                    currentHeight = CGFloat(saved)
                }
            }
    }

    private var cleanChartName: String {
        chartId
            .replacingOccurrences(of: "dash_", with: "")
            .replacingOccurrences(of: "_size", with: "")
            .replacingOccurrences(of: "mem", with: "memory")
            .replacingOccurrences(of: "net", with: "network")
    }

    private func setHeight(_ h: CGFloat) {
        currentHeight = h
        UserDefaults.standard.set(Double(h), forKey: "chart_h_\(chartId)")
    }
}

// MARK: - Chart Context Menu
struct ChartContextMenu: View {
    let chart: String
    
    @AppStorage("dash_showFreq") var showFrequency = true
    @AppStorage("dash_showTemp") var showTemperature = true
    @AppStorage("dash_showPwr") var showPower = true
    @AppStorage("dash_showCores") var showCores = true
    @AppStorage("mb_showNet") var showNetwork = false
    @AppStorage("mb_showMem") var showMemory = true
    
    @AppStorage("dash_chart_order") var chartOrder = "freq,temp,pwr"
    @AppStorage("dash_vertical_order") var verticalOrder = "charts,memory,network,cores"

    var body: some View {
        Menu("Size") {
            Button("Small") { setChartHeight(for: chart, heightType: "small") }
            Button("Medium") { setChartHeight(for: chart, heightType: "medium") }
            Button("Large") { setChartHeight(for: chart, heightType: "large") }
        }
        
        Button("Hide Chart") {
            setChartVisibility(for: chart, visible: false)
        }
        
        let hasHiddenCharts = !showFrequency || !showTemperature || !showPower || !showMemory || !showNetwork || !showCores
        if hasHiddenCharts {
            Menu("Show Chart") {
                if !showFrequency { Button("Frequency") { showFrequency = true } }
                if !showTemperature { Button("Temperature") { showTemperature = true } }
                if !showPower { Button("Power") { showPower = true } }
                if !showMemory { Button("Memory") { showMemory = true } }
                if !showNetwork { Button("Network") { showNetwork = true } }
                if !showCores { Button("Core Grid") { showCores = true } }
            }
        }
        
        Menu("Move Position") {
            if ["freq", "temp", "pwr"].contains(chart) {
                Button("Move Left") { moveChart(chart, direction: -1) }
                Button("Move Right") { moveChart(chart, direction: 1) }
            } else {
                Button("Move Up") { moveChart(chart, direction: -1) }
                Button("Move Down") { moveChart(chart, direction: 1) }
            }
        }
    }

    private func setChartHeight(for chart: String, heightType: String) {
        let mappedChart = (chart == "network") ? "net" : chart
        let key = "chart_h_dash_" + (mappedChart == "memory" ? "mem_size" : mappedChart == "cores" ? "cores_size" : mappedChart)
        let actualHeight: CGFloat
        switch chart {
        case "memory":
            actualHeight = (heightType == "small") ? 130 : (heightType == "medium") ? 160 : 220
        case "cores":
            actualHeight = (heightType == "small") ? 300 : (heightType == "medium") ? 400 : 500
        default:
            actualHeight = (heightType == "small") ? 70 : (heightType == "medium") ? 100 : 150
        }
        UserDefaults.standard.set(Double(actualHeight), forKey: key)
        NotificationCenter.default.post(name: .init("DashboardLayoutChanged"), object: nil)
    }

    private func setChartVisibility(for chart: String, visible: Bool) {
        switch chart {
        case "freq": showFrequency = visible
        case "temp": showTemperature = visible
        case "pwr": showPower = visible
        case "memory": showMemory = visible
        case "network": showNetwork = visible
        case "cores": showCores = visible
        default: break
        }
    }

    private func moveChart(_ chart: String, direction: Int) {
        let normalizedId = chart.replacingOccurrences(of: "dash_", with: "")
        
        if ["freq", "temp", "pwr"].contains(normalizedId) {
            var arr = chartOrder.split(separator: ",").map(String.init)
            if let idx = arr.firstIndex(of: normalizedId) {
                let newIdx = idx + direction
                if newIdx >= 0 && newIdx < arr.count {
                    arr.swapAt(idx, newIdx)
                    chartOrder = arr.joined(separator: ",")
                }
            }
        } else {
            let verticalId: String? = {
                if normalizedId.contains("mem") { return "memory" }
                if normalizedId.contains("net") { return "network" }
                if normalizedId.contains("cores") { return "cores" }
                return nil
            }()
            
            if let targetId = verticalId {
                var arr = verticalOrder.split(separator: ",").map(String.init)
                if let idx = arr.firstIndex(of: targetId) {
                    let newIdx = idx + direction
                    if newIdx >= 0 && newIdx < arr.count {
                        arr.swapAt(idx, newIdx)
                        verticalOrder = arr.joined(separator: ",")
                    }
                }
            }
        }
    }
}
