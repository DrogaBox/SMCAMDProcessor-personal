//
//  ProcessorModel.swift
//  AMD Power Gadget
//
//  Created by trulyspinach, modified by Droga (2026) on 3/3/20.
//

import Cocoa
import Darwin


class ProcessorModel {
    static let shared = ProcessorModel()

    private var connect: io_connect_t = 0

    private var cachedMetric : [Float] = []
    private var numberOfCores : Int = 0
    private var lastMLoad : Double = 0

    private var PStateDef : [UInt64] = []
    private var PStateCur : Int = 0
    private var instructionDelta : [UInt64] = []
    private var loadIndex : [Float] = []
    private var previousCpuLoadInfo : [processor_cpu_load_info] = []
    private var PStateDefClock : [Float] = []
    private var validPStateLength : Int = 0
    private var emulatedPState : Int = 0
    private var isEmulatingPStates : Bool = false
    private var emulatedPStateDefClock : [Float] = []

    private var cpuListedAsSupported : Bool = false

    var systemConfig : [String : String] = [:]

    var AMDRyzenCPUPowerManagementVersion : String = ""
    var cpuidBasic : [UInt64] = []
    var boardValid = false
    var boardName : String = "Unknown"
    var boardVendor : String = "Unknown"

    var fetchRetry : Int = 10
    var fetchRetry2 : Int = 10
    var retryTimer : Timer?

    init() {
        if !initDriver() {
            alertAndQuit(message: "Please download AMDRyzenCPUPowerManagement from the release page.")
        }

        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 0

        let maxStrLength = 16
        var outputStr: [CChar] = [CChar](repeating: 0, count: maxStrLength)
        var outputStrCount: Int = maxStrLength
        let _ = IOConnectCallMethod(connect, 8, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)
        AMDRyzenCPUPowerManagementVersion = String(cString: Array(outputStr[0...outputStrCount-1]))

        let compatVers = ["0.6.3", "0.6.4", "0.6.5", "0.6.6", "0.7", "0.7.1", "0.7.2"]

        var isCompatible = compatVers.contains(AMDRyzenCPUPowerManagementVersion)
        if !isCompatible {
            // Dynamically allow any version >= 0.7.2 for compatibility with 2026 standards
            if AMDRyzenCPUPowerManagementVersion.compare("0.7.2", options: .numeric) != .orderedAscending {
                isCompatible = true
            }
        }

        if !isCompatible {
            alertAndQuit(message: "Your AMDRyzenCPUPowerManagement version (\(AMDRyzenCPUPowerManagementVersion)) is outdated and no longer API compatible. Please use version 0.7.2 or newer and start this application again.")
        }

        loadCPUID()
        loadBaseBoardInfo()
        loadMetric()
        loadSystemConfig()
        loadPStateDef()
        loadPStateDefClock()


        if numberOfCores < 1{
            let alert = NSAlert()
            alert.messageText = "Error reading CPU data."
            alert.informativeText = "This application can not be launched due to AMDRyzenCPUPowerManagement is reporting incorrect data."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Quit")
            alert.runModal()
            NSApplication.shared.terminate(self)
        }

//        fetchSupportedProcessor()
    }

    func initDriver() -> Bool {
        let serviceObject = IOServiceGetMatchingService(kIOMainPortDefault,
                                                        IOServiceMatching("AMDRyzenCPUPowerManagement"))
        if serviceObject == 0 {
            return false
        }

        let status = IOServiceOpen(serviceObject, mach_task_self_, 0, &connect)
        print(status)

        return status == KERN_SUCCESS
    }

    func closeDriver() {
        IOServiceClose(connect)
    }

    func alertAndQuit(message : String){
        let alert = NSAlert()
        alert.messageText = "No AMDRyzenCPUPowerManagement Found!"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Quit and Download")
        let res = alert.runModal()

        if res == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal")!)
        }

        NSApplication.shared.terminate(self)
    }

    func alertDontQuit(message : String){
        let alert = NSAlert()
        alert.messageText = "Kext Update Available"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Later")
        alert.addButton(withTitle: "Download")
        let res = alert.runModal()

        if res == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal")!)
        }
    }

    func kernelGetFloats(count : Int, selector : UInt32) -> [Float] {
        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 1

        let maxStrLength = count //MaxCpu + 3
        var outputStr: [Float] = [Float](repeating: 0, count: maxStrLength)
        var outputStrCount: Int = 4/*sizeof(float)*/ * maxStrLength
        let res = IOConnectCallMethod(connect, selector, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return []
        }

        return outputStr
    }

    func kernelGetUInt64(count : Int, selector : UInt32) -> [UInt64] {
        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 1

        let maxStrLength = count //MaxCpu + 3
        var outputStr: [UInt64] = [UInt64](repeating: 0, count: maxStrLength)
        var outputStrCount: Int = 8/*sizeof(uint64_t)*/ * maxStrLength
        let res = IOConnectCallMethod(connect, selector, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return []
        }

        return outputStr
    }

    func kernelGetString(selector : UInt32, args : [UInt64]) -> String {

        var argcpy = args
        var outbuffersize = 16
        var outputStr: [CChar] = [CChar](repeating: 0, count: outbuffersize)

        var res = IOConnectCallMethod(connect, selector, &argcpy, UInt32(args.count), nil, 0,
                                      nil, nil,
                                      &outputStr, &outbuffersize)

        if res == MIG_ARRAY_TOO_LARGE{
            outputStr = [CChar](repeating: 0, count: outbuffersize)
            res = IOConnectCallMethod(connect, selector, &argcpy, UInt32(args.count), nil, 0,
                                      nil, nil,
                                      &outputStr, &outbuffersize)
        }
        else if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return ""
        }


        return String(String(cString: Array(outputStr[0...outbuffersize-1])).prefix(outbuffersize))
    }

    func kernelSetUInt64(selector : UInt32, args : [UInt64]) -> Bool {
        var argcpy = args
        let res = IOConnectCallMethod(connect, selector, &argcpy, UInt32(args.count), nil, 0,
                                      nil, nil,
                                      nil, nil)

        return res == KERN_SUCCESS
    }

    private func loadMetric(){
        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 1

        let maxStrLength = 67 //MaxCpu + 3
        var outputStr: [Float] = [Float](repeating: 0, count: maxStrLength)
        var outputStrCount: Int = 4/*sizeof(float)*/ * maxStrLength
        let res = IOConnectCallMethod(connect, 4, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return
        }

        numberOfCores = Int(scalerOut)
        cachedMetric = Array(outputStr[0...numberOfCores + 2])
        PStateCur = Int(outputStr[2])


        lastMLoad = NSDate().timeIntervalSince1970
    }

    private func loadLoadIndex(){
        var numCPUs: mach_msg_type_number_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        
        let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &infoArray, &infoCount)
        guard kr == KERN_SUCCESS, let info = infoArray else {
            return
        }
        
        let count = Int(numCPUs)
        var newLoads = [Float](repeating: 0.0, count: count)
        
        let cpuLoadData = info.withMemoryRebound(to: processor_cpu_load_info.self, capacity: count) { $0 }
        
        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }
        
        if previousCpuLoadInfo.count == count {
            for i in 0..<count {
                let prev = previousCpuLoadInfo[i]
                let curr = cpuLoadData[i]
                
                let userDiff   = max(0.0, Double(curr.cpu_ticks.0 &- prev.cpu_ticks.0))
                let systemDiff = max(0.0, Double(curr.cpu_ticks.1 &- prev.cpu_ticks.1))
                let idleDiff   = max(0.0, Double(curr.cpu_ticks.2 &- prev.cpu_ticks.2))
                let niceDiff   = max(0.0, Double(curr.cpu_ticks.3 &- prev.cpu_ticks.3))
                
                let total = userDiff + systemDiff + idleDiff + niceDiff
                if total > 0 {
                    newLoads[i] = Float(userDiff + systemDiff + niceDiff) / Float(total)
                } else {
                    newLoads[i] = 0.0
                }
            }
        }
        
        previousCpuLoadInfo.removeAll(keepingCapacity: true)
        for i in 0..<count {
            previousCpuLoadInfo.append(cpuLoadData[i])
        }
        
        loadIndex = newLoads
    }

    private func loadPStateDef(){

        PStateDef = kernelGetUInt64(count: 8, selector: 0)
        print(PStateDef)
        var i = 0
        while i < 8 {
            if (PStateDef[i] & 0x8000000000000000) == 0 { //LOL Swift
                break
            }
            i += 1
        }
        validPStateLength = i

    }

    private func loadCPUID(){
        cpuidBasic = kernelGetUInt64(count: 8, selector: 7)
    }

    private func loadBaseBoardInfo(){
        var scalerOut: [UInt64] = [UInt64](repeating: 0, count: 1)
        var outputCount: UInt32 = 1

        let maxStrLength = 128
        var outputStr: [CChar] = [CChar](repeating: 0, count: maxStrLength)
        var outputStrCount: Int = maxStrLength
        let _ = IOConnectCallMethod(connect, 16, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)

        if scalerOut[0] == 1 {
            boardValid = true
            boardVendor = String(cString: Array(outputStr[0...64-1]))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .controlCharacters)
            boardName = String(cString: Array(outputStr[64...128-1]))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .controlCharacters)
        }

    }

    private func loadPStateDefClock(){
        // Si ya estamos en modo de emulación, no volver a leer del kernel.
        // Los valores emulados son estáticos y correctos para toda la sesión.
        if isEmulatingPStates {
            PStateDefClock = emulatedPStateDefClock
            return
        }

        PStateDefClock = kernelGetFloats(count: 10, selector: 1)

        // Sanitizar valores NaN/Inf del kernel (CpuDfsId=0 produce NaN en la división)
        for i in 0..<PStateDefClock.count {
            if PStateDefClock[i].isNaN || PStateDefClock[i].isInfinite {
                PStateDefClock[i] = 0.0
            }
        }

        // If we detect only one (or zero) legacy P-states due to UEFI/BIOS behavior on Zen 3,
        // activate permanent emulation mode for this session.
        if validPStateLength <= 1 {
            var baseClock: Float = 0.0
            if PStateDefClock.count > 0 && PStateDefClock[0] > 1000.0 {
                baseClock = PStateDefClock[0]
            }

            // If baseClock is invalid, derive it from the CPU brand string
            if baseClock < 1000.0 {
                let cpuBrand = ProcessorModel.sysctlString(key: "machdep.cpu.brand_string").lowercased()
                if let range = cpuBrand.range(of: #"(\d+\.\d+)\s*ghz"#, options: .regularExpression) {
                    let ghzStr = cpuBrand[range].replacingOccurrences(of: "ghz", with: "").trimmingCharacters(in: .whitespaces)
                    if let ghz = Float(ghzStr) {
                        baseClock = ghz * 1000.0
                    }
                }
                if baseClock < 1000.0 {
                    if cpuBrand.contains("5900xt") { baseClock = 3300.0 }
                    else if cpuBrand.contains("5950x") { baseClock = 3400.0 }
                    else if cpuBrand.contains("5900x") { baseClock = 3700.0 }
                    else if cpuBrand.contains("5800x") { baseClock = 3800.0 }
                    else if cpuBrand.contains("5600x") { baseClock = 3700.0 }
                    else { baseClock = 3300.0 }
                }
            }

            var maxBoost: Float = baseClock + 1000.0
            let cpuBrand = ProcessorModel.sysctlString(key: "machdep.cpu.brand_string").lowercased()
            if cpuBrand.contains("5900xt") || cpuBrand.contains("5950x") {
                maxBoost = 4900.0
            } else if cpuBrand.contains("5900x") || cpuBrand.contains("5800x") || cpuBrand.contains("5700x") {
                maxBoost = 4800.0
            } else if cpuBrand.contains("5600x") || cpuBrand.contains("5600g") {
                maxBoost = 4600.0
            } else if cpuBrand.contains("3900x") || cpuBrand.contains("3950x") {
                maxBoost = 4600.0
            } else if cpuBrand.contains("3800x") || cpuBrand.contains("3700x") {
                maxBoost = 4500.0
            } else if cpuBrand.contains("3600") {
                maxBoost = 4200.0
            }

            if maxBoost <= baseClock {
                maxBoost = baseClock + 1000.0
            }

            let step5 = maxBoost
            let step4 = baseClock + (maxBoost - baseClock) * 0.5
            let step3 = baseClock
            let step2 = Float(2800.0)
            let step1 = Float(2200.0)

            PStateDefClock = [step5, step4, step3, step2, step1, 0.0, 0.0, 0.0, 0.0, 0.0]
            emulatedPStateDefClock = PStateDefClock
            validPStateLength = 5
            isEmulatingPStates = true
        }
    }

    func refreshPStateDef() {
        loadPStateDefClock()
    }

    func getHPCpus() -> Int{
        let o = kernelGetUInt64(count: 1, selector: 17)
        return o.count > 0 ? Int(o[0]) : 0
    }

    func setPState(state : Int) {
        // If we are in emulation mode (hardware reports only 1 P-state but we expose 5 in the GUI)
        if PStateDef.count > 1 && (PStateDef[1] & 0x8000000000000000) == 0 {
            emulatedPState = state

            // Smart mapping to real hardware controls in Zen 3:
            switch state {
            case 0, 1: // Boost / High Performance (4900 MHz / 4100 MHz)
                setCPB(enabled: true)
                setLPM(enabled: false)
                setPPM(enabled: true)
            case 2: // Base Clock (3300 MHz)
                setCPB(enabled: false) // Cap to base frequency for optimal thermal control
                setLPM(enabled: false)
                setPPM(enabled: true)
            case 3: // Balanced / Low-Medium (2800 MHz)
                setCPB(enabled: false)
                setLPM(enabled: false)
                setPPM(enabled: true)
            case 4: // LPM / Idle (2200 MHz)
                setCPB(enabled: false)
                setLPM(enabled: true) // Activate Low Power Mode directly
            default:
                break
            }
            return
        }

        var input: [UInt64] = [UInt64(state)]
        let res = IOConnectCallMethod(connect, 10, &input, 1, nil, 0,
                                      nil, nil,
                                      nil, nil)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return
        }
    }

    func getPState() -> Int {
        if PStateDef.count > 1 && (PStateDef[1] & 0x8000000000000000) == 0 {
            let lpm = getLPM()
            let cpb = getCPB() // devuelve [cpbSupported, cpbEnabled]

            if lpm {
                return 4 // LPM / Idle
            } else if cpb.count > 1 && !cpb[1] {
                return 2 // Base Clock (CPB desactivado)
            } else {
                // If CPB is active, return the last emulated selection (0, 1, or 3)
                // otherwise default to 0 (Boost)
                return emulatedPState == 4 || emulatedPState == 2 ? 0 : emulatedPState
            }
        }
        return PStateCur
    }

    func getCPPCActiveMode() -> (active: Bool, epp: UInt8) {
        var output: [UInt64] = [0, 0]
        var outputCount: UInt32 = 2
        let res = IOConnectCallMethod(connect, 23, nil, 0, nil, 0, &output, &outputCount, nil, nil)
        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return (false, 0x3F)
        }
        return (output[0] == 1, UInt8(output[1]))
    }

    func setCPPCActiveMode(active: Bool) -> Bool {
        var input: [UInt64] = [active ? 1 : 0]
        let res = IOConnectCallMethod(connect, 24, &input, 1, nil, 0, nil, nil, nil, nil)
        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return false
        }
        return true
    }

    func setCPPCEPPValue(epp: UInt8) -> Bool {
        var input: [UInt64] = [UInt64(epp)]
        let res = IOConnectCallMethod(connect, 25, &input, 1, nil, 0, nil, nil, nil, nil)
        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return false
        }
        return true
    }

    func getPStateDef() -> [UInt64]{
        return PStateDef
    }

    func getValidPStateClocks() -> [Float] {
        if validPStateLength <= 0 || PStateDefClock.isEmpty {
            return [3300.0] // Safe fallback: return at least one valid value
        }
        let len = min(validPStateLength, PStateDefClock.count)
        return Array(PStateDefClock[0...len-1])
    }

    func getMetric(forced : Bool) -> [Float] {
        if forced || (NSDate().timeIntervalSince1970 - lastMLoad >= 1.0) {
            loadMetric()
        }
        return cachedMetric
    }

    func getNumOfCore() -> Int {
        return numberOfCores
    }

    func getLoadIndex() -> [Float] {
        loadLoadIndex()
        return loadIndex
    }

    func getCPB() -> [Bool] {
        let o = kernelGetUInt64(count: 2, selector: 11)
        return o.map{ $0 == 0 ? false : true }
    }

    func setCPB(enabled : Bool){
        var input: [UInt64] = [UInt64(enabled ? 1 : 0)]
        let res = IOConnectCallMethod(connect, 12, &input, 1, nil, 0,
                                      nil, nil,
                                      nil, nil)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return
        }
    }

    func getPPM() -> Bool {
        let o = kernelGetUInt64(count: 2, selector: 13)
        return o.count > 0 && o[0] != 0
    }

    func setPPM(enabled : Bool){
        var input: [UInt64] = [UInt64(enabled ? 1 : 0)]
        let res = IOConnectCallMethod(connect, 14, &input, 1, nil, 0,
                                      nil, nil,
                                      nil, nil)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return
        }
    }

    func getLPM() -> Bool {
        let o = kernelGetUInt64(count: 1, selector: 18)
        return o.count > 0 && o[0] != 0
    }

    func setLPM(enabled : Bool){
        var input: [UInt64] = [UInt64(enabled ? 1 : 0)]
        let res = IOConnectCallMethod(connect, 19, &input, 1, nil, 0,
                                      nil, nil,
                                      nil, nil)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return
        }
    }

    func getInstructionDelta() -> [UInt64]{
        let o = kernelGetUInt64(count: 1, selector: 5)
        return o.count > 0 ? [o[0]] : [0]
    }

    func setPState(def : [UInt64]) -> Int{
        if def.count != 8 {
            return -1
        }

        var input: [UInt64] = def
        let res = IOConnectCallMethod(connect, 15, &input, 8, nil, 0,
                                      nil, nil,
                                      nil, nil)


        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
            return Int(res)
        }

        loadPStateDef()
        loadPStateDefClock()
        return 0
    }

    static func sysctlString(key : String) -> String {
        var size = 0
        sysctlbyname(key, nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname(key, &machine, &size, nil, 0)
        return String(cString: machine)
    }

    static func sysctlInt64(key : String) -> Int64 {
        var v: Int64 = 0
        var size = MemoryLayout<Int64>.size
        sysctlbyname(key, &v, &size, nil, 0)
        return v
    }

    func loadSystemConfig() {
        systemConfig["ver"] = AMDRyzenCPUPowerManagementVersion
        systemConfig["cpu"] = ProcessorModel.sysctlString(key: "machdep.cpu.brand_string")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        systemConfig["os"] = ProcessorModel.sysctlString(key: "kern.osproductversion")
        systemConfig["mem"] = "\(Int(ProcessorModel.sysctlInt64(key: "hw.memsize") / 1024 / 1024))"


        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: paths.last!) {
            if let size = dictionary[FileAttributeKey.systemSize] as? NSNumber {
                systemConfig["rs"] = "\(Int(Int(truncating: size) / 1024 / 1024))"
            }
        }

        if boardValid {
            systemConfig["mb"] = "\(boardName) \(boardVendor)"
        }

        var iter : io_iterator_t = 0
        let err = IOServiceGetMatchingServices(kIOMainPortDefault,
                                               IOServiceMatching("IOPCIDevice"), &iter)
        if err != kIOReturnSuccess {return}
        while true {
            let reg = IOIteratorNext(iter)
            if reg == 0 { break}
            var serviceDictionary : Unmanaged<CFMutableDictionary>?
            let e = IORegistryEntryCreateCFProperties(reg, &serviceDictionary, kCFAllocatorDefault, .zero)

            if e != kIOReturnSuccess {continue}
            if let dic : NSDictionary = serviceDictionary?.takeRetainedValue(){
                if let type = dic.object(forKey: "IOName") as? String {
                    if type != "display" {continue}

                    if let model = dic.object(forKey: "model") as? Data {
                        systemConfig["gpu"] = String(data: model, encoding: .ascii)!
                            .trimmingCharacters(in: .controlCharacters)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        systemConfig["gpu"] = "Unknown"
                    }
                }
            }
        }
    }

    func fetchSupportedProcessor() {
        // Desactivado para optimización de red, privacidad y duración de batería en 2026.
    }

    func fetchSMCChipSupport(chipIntel : Int, working : Bool) {
        // Desactivado para evitar telemetría a servidores obsoletos en 2026.
    }

    // MARK: - GPU Statistics (from IOAccelerator PerformanceStatistics)

    /// Reads a numeric value from the IOAccelerator PerformanceStatistics dictionary.
    private func getIOAcceleratorStat(key: String) -> Float {
        var iter: io_iterator_t = 0
        let err = IOServiceGetMatchingServices(kIOMainPortDefault,
                                              IOServiceMatching("IOAccelerator"), &iter)
        if err != kIOReturnSuccess { return 0 }
        defer { IOObjectRelease(iter) }

        while true {
            let reg = IOIteratorNext(iter)
            if reg == 0 { break }
            defer { IOObjectRelease(reg) }

            if let dict = IORegistryEntryCreateCFProperty(reg, "PerformanceStatistics" as CFString,
                                                         kCFAllocatorDefault, 0)?.takeRetainedValue() as? [String: Any] {
                if let v = dict[key] as? NSNumber { return v.floatValue }
                if let v = dict[key] as? Int      { return Float(v) }
            }
        }
        return 0
    }

    func getGPUTemp() -> Float {
        return getIOAcceleratorStat(key: "Temperature(C)")
    }

    func getGPUPower() -> Float {
        return getIOAcceleratorStat(key: "Total Power(W)")
    }

    func getGPUUtilization() -> Float {
        return getIOAcceleratorStat(key: "Device Utilization %")
    }

    func getGPUVramUsed() -> Float {
        return getIOAcceleratorStat(key: "inUseVidMemoryBytes")
    }

    func getGPUFanRPM() -> Float {
        return getIOAcceleratorStat(key: "Fan Speed(RPM)")
    }

    func getCCDTemperatures() -> [Float] {
        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 1
        let maxCCDs = 16
        var outputStr: [Float] = [Float](repeating: 0.0, count: maxCCDs)
        var outputStrCount: Int = MemoryLayout<Float>.size * maxCCDs
        
        let res = IOConnectCallMethod(connect, 20, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)
                                      
        if res != KERN_SUCCESS {
            return []
        }
        
        let actualCCDCount = Int(scalerOut)
        if actualCCDCount <= 0 {
            return []
        }
        
        return Array(outputStr[0..<min(actualCCDCount, maxCCDs)])
    }

    func getCPPCScore() -> (supported: Bool, scores: [UInt8]) {
        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 1
        let maxLogicalCores = 64
        var outputStr: [UInt8] = [UInt8](repeating: 0, count: maxLogicalCores)
        var outputStrCount: Int = MemoryLayout<UInt8>.size * maxLogicalCores
        
        let res = IOConnectCallMethod(connect, 21, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)
                                      
        if res != KERN_SUCCESS {
            return (false, [])
        }
        
        let supported = scalerOut == 1
        return (supported, Array(outputStr[0..<maxLogicalCores]))
    }

    func getCStateAddress() -> UInt64 {
        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 1
        
        let res = IOConnectCallMethod(connect, 22, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      nil, nil)
                                      
        if res != KERN_SUCCESS {
            return 0
        }
        return scalerOut
    }
}