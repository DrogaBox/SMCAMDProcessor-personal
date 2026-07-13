//
//  MenuBarConfig.swift
//  AMD Power Gadget
//
//  Extracted from StatusbarController.swift (2026) — Menu Bar Configuration
//

import Cocoa
import SwiftUI
import Combine

struct MenuBarConfig {
    static var shared = MenuBarConfig()

    var showCPU:    Bool { get { ud.bool(forKey: "mb_showCPU")    } set { ud.set(newValue, forKey: "mb_showCPU")    } }
    var showTemp:   Bool { get { ud.bool(forKey: "mb_showTemp")   } set { ud.set(newValue, forKey: "mb_showTemp")   } }
    var showPower:  Bool { get { ud.bool(forKey: "mb_showPower")  } set { ud.set(newValue, forKey: "mb_showPower")  } }
    var showGPU:    Bool { get { ud.bool(forKey: "mb_showGPU")    } set { ud.set(newValue, forKey: "mb_showGPU")    } }
    var showGPUtemp:Bool { get { ud.bool(forKey: "mb_showGPUtemp")} set { ud.set(newValue, forKey: "mb_showGPUtemp")} }
    var showGPUpwr: Bool { get { ud.bool(forKey: "mb_showGPUpwr") } set { ud.set(newValue, forKey: "mb_showGPUpwr") } }
    var showGPUvram:Bool { get { ud.bool(forKey: "mb_showGPUvram")} set { ud.set(newValue, forKey: "mb_showGPUvram")} }
    var showGPUfan: Bool { get { ud.bool(forKey: "mb_showGPUfan") } set { ud.set(newValue, forKey: "mb_showGPUfan") } }

    var showFanRPM:  Bool { get { ud.bool(forKey: "mb_showFanRPM") } set { ud.set(newValue, forKey: "mb_showFanRPM") } }
    var fanIndex:    Int  { get { ud.integer(forKey: "mb_fanIdx")   } set { ud.set(newValue, forKey: "mb_fanIdx")   } }
    var showMemory:  Bool { get { ud.bool(forKey: "mb_showMem")    } set { ud.set(newValue, forKey: "mb_showMem")    } }
    var showNetwork: Bool { get { ud.bool(forKey: "mb_showNet")    } set { ud.set(newValue, forKey: "mb_showNet")    } }
    var netColorIdx: Int  { get { ud.integer(forKey: "mb_netColorIdx") } set { ud.set(newValue, forKey: "mb_netColorIdx") } }

    // Creative features
    var enableColorAlerts: Bool { get { ud.bool(forKey: "mb_enableColorAlerts") } set { ud.set(newValue, forKey: "mb_enableColorAlerts") } }
    var showMaxFreqOnly:  Bool { get { ud.bool(forKey: "mb_showMaxFreqOnly")  } set { ud.set(newValue, forKey: "mb_showMaxFreqOnly")  } }
    var useFahrenheit:    Bool { get { ud.bool(forKey: "mb_useFahrenheit")    } set { ud.set(newValue, forKey: "mb_useFahrenheit")    } }
    
    var tempThreshold: Int { get { ud.integer(forKey: "mb_tempThreshold") } set { ud.set(newValue, forKey: "mb_tempThreshold") } }
    var tempColorIdx:  Int { get { ud.integer(forKey: "mb_tempColorIdx")  } set { ud.set(newValue, forKey: "mb_tempColorIdx")  } }
    var tempPresetList: String { get { ud.string(forKey: "mb_tempPresetList") ?? "30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95" } set { ud.set(newValue, forKey: "mb_tempPresetList") } }
    var enablePopover: Bool { get { ud.bool(forKey: "mb_enablePopover") } set { ud.set(newValue, forKey: "mb_enablePopover") } }

    var popoverShowCPU:       Bool { get { ud.bool(forKey: "pop_showCPU")       } set { ud.set(newValue, forKey: "pop_showCPU")       } }
    var popoverShowRAM:       Bool { get { ud.bool(forKey: "pop_showRAM")       } set { ud.set(newValue, forKey: "pop_showRAM")       } }
    var popoverShowDisk:      Bool { get { ud.bool(forKey: "pop_showDisk")      } set { ud.set(newValue, forKey: "pop_showDisk")      } }
    var popoverShowGPU:       Bool { get { ud.bool(forKey: "pop_showGPU")       } set { ud.set(newValue, forKey: "pop_showGPU")       } }
    var popoverShowGPURing:   Bool { get { ud.bool(forKey: "pop_showGPURing")   } set { ud.set(newValue, forKey: "pop_showGPURing")   } }
    var popoverShowVRAM:      Bool { get { ud.bool(forKey: "pop_showVRAM")      } set { ud.set(newValue, forKey: "pop_showVRAM")      } }
    var popoverShowCores:     Bool { get { ud.bool(forKey: "pop_showCores")     } set { ud.set(newValue, forKey: "pop_showCores")     } }
    var popoverShowNetwork:   Bool { get { ud.bool(forKey: "pop_showNetwork")   } set { ud.set(newValue, forKey: "pop_showNetwork")   } }
    var popoverShowProcesses: Bool { get { ud.bool(forKey: "pop_showProcesses") } set { ud.set(newValue, forKey: "pop_showProcesses") } }
    var popoverRingShowLabels:Bool { get { ud.bool(forKey: "pop_ringShowLabels") } set { ud.set(newValue, forKey: "pop_ringShowLabels") } }
    var popoverRingShowTemp:  Bool { get { ud.bool(forKey: "pop_ringShowTemp")   } set { ud.set(newValue, forKey: "pop_ringShowTemp")   } }
    var popoverCPUStyle:  Int { get { ud.integer(forKey: "pop_cpuStyle")  } set { ud.set(newValue, forKey: "pop_cpuStyle")  } }
    var popoverRAMStyle:  Int { get { ud.integer(forKey: "pop_ramStyle")  } set { ud.set(newValue, forKey: "pop_ramStyle")  } }
    var popoverDiskStyle: Int { get { ud.integer(forKey: "pop_diskStyle") } set { ud.set(newValue, forKey: "pop_diskStyle") } }
    var popoverGPUStyle:  Int { get { ud.integer(forKey: "pop_gpuStyle")  } set { ud.set(newValue, forKey: "pop_gpuStyle")  } }
    var popoverRingOrder: String {
        get {
            let order = ud.string(forKey: "pop_ringOrder") ?? "cpu,ram,gpu,vram,disk"
            var keys = order.split(separator: ",").map(String.init)
            let allKeys = ["cpu", "ram", "gpu", "vram", "disk"]
            var migrated = false
            for key in allKeys {
                if !keys.contains(key) {
                    keys.append(key)
                    migrated = true
                }
            }
            let migratedStr = keys.joined(separator: ",")
            if migrated {
                ud.set(migratedStr, forKey: "pop_ringOrder")
            }
            return migratedStr
        }
        set {
            ud.set(newValue, forKey: "pop_ringOrder")
        }
    }

    var popoverVerticalOrder: String {
        get {
            let order = ud.string(forKey: "pop_verticalOrder") ?? "cpu,ram,gpu,vram,disk,net,proc"
            var keys = order.split(separator: ",").map(String.init)
            let allKeys = ["cpu", "ram", "gpu", "vram", "disk", "net", "proc"]
            var migrated = false
            for key in allKeys {
                if !keys.contains(key) {
                    keys.append(key)
                    migrated = true
                }
            }
            let migratedStr = keys.joined(separator: ",")
            if migrated {
                ud.set(migratedStr, forKey: "pop_verticalOrder")
            }
            return migratedStr
        }
        set {
            ud.set(newValue, forKey: "pop_verticalOrder")
        }
    }

    var popoverShowCPUSparkline: Bool { get { ud.bool(forKey: "pop_showCPUSparkline") } set { ud.set(newValue, forKey: "pop_showCPUSparkline") } }
    var popoverShowGPUSparkline: Bool { get { ud.bool(forKey: "pop_showGPUSparkline") } set { ud.set(newValue, forKey: "pop_showGPUSparkline") } }
    var popoverShowNetSparkline: Bool { get { ud.bool(forKey: "pop_showNetSparkline") } set { ud.set(newValue, forKey: "pop_showNetSparkline") } }
    var popoverPinOpen:          Bool { get { ud.bool(forKey: "pop_pinOpen")          } set { ud.set(newValue, forKey: "pop_pinOpen")          } }

    private let ud = UserDefaults.standard

    init() {
        // Dictionary-driven UserDefaults initialization for better maintainability
        let defaults: [String: Any] = [
            // Menu bar display options
            "mb_showCPU": true,
            "mb_showTemp": true,
            "mb_showPower": true,
            "mb_showGPU": true,
            "mb_showGPUtemp": true,
            "mb_showGPUpwr": true,
            "mb_showGPUvram": false,
            "mb_showGPUfan": false,
            "mb_showFanRPM": false,
            "mb_fanIdx": 0,
            "mb_showMem": false,
            "mb_showNet": false,
            "mb_netColorIdx": 0,
            
            // Menu bar features
            "mb_enableColorAlerts": false,
            "mb_showMaxFreqOnly": false,
            "mb_useFahrenheit": false,
            "mb_tempThreshold": 80,
            "mb_tempColorIdx": 3, // Red
            "mb_tempPresetList": "30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95",
            "mb_enablePopover": true,
            
            // Popover display options
            "pop_showCPU": true,
            "pop_showRAM": true,
            "pop_showDisk": true,
            "pop_showGPU": true,
            "pop_showGPURing": true,
            "pop_showVRAM": true,
            "pop_showCores": false,
            "pop_pinOpen": false,
            "pop_showNetwork": true,
            "pop_showProcesses": true,
            "pop_ringShowLabels": true,
            "pop_ringShowTemp": true,
            "pop_cpuStyle": 0,
            "pop_ramStyle": 0,
            "pop_diskStyle": 0,
            "pop_gpuStyle": 0
        ]
        
        // Apply defaults only if key doesn't exist
        defaults.forEach { key, value in
            if ud.object(forKey: key) == nil {
                ud.set(value, forKey: key)
            }
        }
        
        // Handle sparkline migrations with special logic
        if ud.object(forKey: "pop_showCPUSparkline") == nil {
            let style = ud.integer(forKey: "pop_cpuStyle")
            if style == 2 {
                ud.set(true, forKey: "pop_showCPUSparkline")
                ud.set(0, forKey: "pop_cpuStyle")
            } else {
                ud.set(false, forKey: "pop_showCPUSparkline")
            }
        }
        if ud.object(forKey: "pop_showGPUSparkline") == nil {
            let style = ud.integer(forKey: "pop_gpuStyle")
            if style == 2 {
                ud.set(true, forKey: "pop_showGPUSparkline")
                ud.set(0, forKey: "pop_gpuStyle")
            } else {
                ud.set(false, forKey: "pop_showGPUSparkline")
            }
        }
        if ud.object(forKey: "pop_showNetSparkline") == nil {
            ud.set(false, forKey: "pop_showNetSparkline")
        }
        
        // Force migration to CPU, RAM, GPU, VRAM, DISK layout
        let currentOrder = ud.string(forKey: "pop_ringOrder") ?? ""
        if !currentOrder.contains("vram") {
            ud.set("cpu,ram,gpu,vram,disk", forKey: "pop_ringOrder")
        }
    }

    var totalWidth: CGFloat {
        var w: CGFloat = 0
        if showCPU     { w += showMaxFreqOnly ? 48 : 56 }
        if showTemp    { w += 56 }
        if showPower   { w += 56 }
        if showFanRPM  { w += 56 }
        if showMemory  { w += 56 }
        if showNetwork { w += 68 }
        return max(w, 110)
    }
}

