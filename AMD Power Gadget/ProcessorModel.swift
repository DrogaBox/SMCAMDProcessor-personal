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
            alertAndQuit(message: NSLocalizedString("Please download AMDRyzenCPUPowerManagement from the release page.", comment: ""))
        }

        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 0

        let maxStrLength = 16
        var outputStr: [CChar] = [CChar](repeating: 0, count: maxStrLength)
        var outputStrCount: Int = maxStrLength
        let _ = IOConnectCallMethod(connect, 8, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)
        AMDRyzenCPUPowerManagementVersion = outputStrCount > 0 ? String(cString: Array(outputStr[0...min(outputStrCount - 1, outputStr.count - 1)])) : ""

        let compatVers = ["3.0.0", "3.1.0", "3.2.0", "3.3.0", "3.3.1", "3.4.0", "3.5.0", "3.6.0", "3.7.0", "3.8.0", "3.9.0", "3.10.0", "3.11.0", "3.12.0", "3.13.3"]

        var isCompatible = compatVers.contains(AMDRyzenCPUPowerManagementVersion)
        if !isCompatible {
            // Dynamically allow any version >= 3.0.0 for compatibility with 2026 standards
            if AMDRyzenCPUPowerManagementVersion.compare("3.0.0", options: .numeric) != .orderedAscending {
                isCompatible = true
            }
        }

        if !isCompatible {
            let fmt = NSLocalizedString("Your AMDRyzenCPUPowerManagement version (%@) is outdated and no longer API compatible. Please use version 3.0.0 or newer and start this application again.", comment: "")
            alertAndQuit(message: String(format: fmt, AMDRyzenCPUPowerManagementVersion))
        }

        loadCPUID()
        loadBaseBoardInfo()
        loadMetric()
        loadSystemConfig()
        loadPStateDef()
        loadPStateDefClock()


        if numberOfCores < 1{
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Error reading CPU data.", comment: "")
            alert.informativeText = NSLocalizedString("This application can not be launched due to AMDRyzenCPUPowerManagement is reporting incorrect data.", comment: "")
            alert.alertStyle = .critical
            alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
            NSApp.activate(ignoringOtherApps: true)
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
        IOObjectRelease(serviceObject) // Must be released whether open succeeds or fails

        if status != KERN_SUCCESS {
            // Distinguish "kext missing" from "connection refused" for diagnostics.
            NSLog("ProcessorModel: IOServiceOpen failed status=0x%08x (service was present)", status)
            return false
        }
        return true
    }

    func closeDriver() {
        IOServiceClose(connect)
    }

    func alertAndQuit(message : String){
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("No AMDRyzenCPUPowerManagement Found!", comment: "")
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Quit and Download", comment: ""))
        NSApp.activate(ignoringOtherApps: true)
        let res = alert.runModal()

        if res == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") {
                NSWorkspace.shared.open(url)
            }
        }

        NSApplication.shared.terminate(self)
    }

    func alertDontQuit(message : String){
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Kext Update Available", comment: "")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Download", comment: ""))
        NSApp.activate(ignoringOtherApps: true)
        let res = alert.runModal()

        if res == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") {
                NSWorkspace.shared.open(url)
            }
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

        let validElements = min(count, outputStrCount / 4)
        return Array(outputStr[0..<max(0, validElements)])
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

    /// IOKit `kIOReturnNotPrivileged` (0xe00002c1) — write selectors require root or `-amdpnopchk`.
    static let kIOReturnNotPrivilegedCode: kern_return_t = kern_return_t(bitPattern: 0xe00002c1)

    func kernelSetStruct(selector: UInt32, data: Data) -> kern_return_t {
        return data.withUnsafeBytes { rawBuffer -> kern_return_t in
            guard let baseAddress = rawBuffer.baseAddress else { return kIOReturnBadArgument }
            return IOConnectCallMethod(connect, selector, nil, 0, baseAddress, data.count, nil, nil, nil, nil)
        }
    }

    @discardableResult
    func kernelSetStructSuccess(selector: UInt32, data: Data) -> Bool {
        kernelSetStruct(selector: selector, data: data) == KERN_SUCCESS
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
        if res != KERN_SUCCESS || outbuffersize <= 0 {
            if res != KERN_SUCCESS { print(String(cString: mach_error_string(res))) }
            return ""
        }

        var validBytes = Array(outputStr.prefix(outbuffersize))
        if validBytes.isEmpty || validBytes.last != 0 {
            validBytes.append(0)
        }
        return String(cString: validBytes)
    }

    /// Returns the raw IOKit status (KERN_SUCCESS / kIOReturnNotPrivileged / …).
    @discardableResult
    func kernelSetUInt64Status(selector: UInt32, args: [UInt64]) -> kern_return_t {
        var argcpy = args
        return IOConnectCallMethod(connect, selector, &argcpy, UInt32(args.count), nil, 0,
                                   nil, nil, nil, nil)
    }

    func kernelSetUInt64(selector: UInt32, args: [UInt64]) -> Bool {
        kernelSetUInt64Status(selector: selector, args: args) == KERN_SUCCESS
    }

    /// Human-readable message for failed kernel write calls (localized).
    static func privilegeHint(for status: kern_return_t) -> String? {
        if status == kIOReturnNotPrivilegedCode {
            return NSLocalizedString(
                "This action requires administrator privileges. Run AMD Power Gadget as root, or add the boot argument -amdpnopchk for debugging.",
                comment: "Shown when a privileged kext write is denied"
            )
        }
        if status != KERN_SUCCESS {
            return String(cString: mach_error_string(status))
        }
        return nil
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
        let endIdx = min(numberOfCores + 2, outputStr.count - 1)
        cachedMetric = outputStr.count > 0 && endIdx >= 0 ? Array(outputStr[0...endIdx]) : []
        if outputStr.count > 2 { PStateCur = Int(outputStr[2]) }


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
        var i = 0
        while i < PStateDef.count {
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

    @discardableResult
    func setPState(state : Int) -> kern_return_t {
        // If we are in emulation mode (hardware reports only 1 P-state but we expose 5 in the GUI)
        if PStateDef.count > 1 && (PStateDef[1] & 0x8000000000000000) == 0 {
            // Smart mapping to real hardware controls in Zen 3 — surface first privilege failure
            var status: kern_return_t = KERN_SUCCESS
            switch state {
            case 0, 1: // Boost / High Performance
                status = setCPB(enabled: true)
                if status == KERN_SUCCESS { status = setLPM(enabled: false) }
                if status == KERN_SUCCESS { status = setPPM(enabled: true) }
            case 2: // Base Clock
                status = setCPB(enabled: false)
                if status == KERN_SUCCESS { status = setLPM(enabled: false) }
                if status == KERN_SUCCESS { status = setPPM(enabled: true) }
            case 3: // Balanced / Low-Medium
                status = setCPB(enabled: false)
                if status == KERN_SUCCESS { status = setLPM(enabled: false) }
                if status == KERN_SUCCESS { status = setPPM(enabled: true) }
            case 4: // LPM / Idle
                status = setCPB(enabled: false)
                if status == KERN_SUCCESS { status = setLPM(enabled: true) }
            default:
                break
            }
            if status == KERN_SUCCESS {
                emulatedPState = state
            } else {
                print(String(cString: mach_error_string(status)))
            }
            return status
        }

        var input: [UInt64] = [UInt64(state)]
        let res = IOConnectCallMethod(connect, 10, &input, 1, nil, 0,
                                      nil, nil,
                                      nil, nil)

        if res != KERN_SUCCESS {
            print(String(cString: mach_error_string(res)))
        }
        return res
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

    func setCPPCActiveMode(active: Bool) -> kern_return_t {
        var input: [UInt64] = [active ? 1 : 0]
        return IOConnectCallMethod(connect, 24, &input, 1, nil, 0, nil, nil, nil, nil)
    }

    func setCPPCEPPValue(epp: UInt8) -> kern_return_t {
        var input: [UInt64] = [UInt64(epp)]
        return IOConnectCallMethod(connect, 25, &input, 1, nil, 0, nil, nil, nil, nil)
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

    @discardableResult
    func setCPB(enabled: Bool) -> kern_return_t {
        var input: [UInt64] = [UInt64(enabled ? 1 : 0)]
        return IOConnectCallMethod(connect, 12, &input, 1, nil, 0, nil, nil, nil, nil)
    }

    func getPPM() -> Bool {
        let o = kernelGetUInt64(count: 2, selector: 13)
        return o.count > 0 && o[0] != 0
    }

    @discardableResult
    func setPPM(enabled: Bool) -> kern_return_t {
        var input: [UInt64] = [UInt64(enabled ? 1 : 0)]
        return IOConnectCallMethod(connect, 14, &input, 1, nil, 0, nil, nil, nil, nil)
    }

    func getLPM() -> Bool {
        let o = kernelGetUInt64(count: 1, selector: 18)
        return o.count > 0 && o[0] != 0
    }

    @discardableResult
    func setLPM(enabled: Bool) -> kern_return_t {
        var input: [UInt64] = [UInt64(enabled ? 1 : 0)]
        return IOConnectCallMethod(connect, 19, &input, 1, nil, 0, nil, nil, nil, nil)
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
        if let path = paths.last, let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: path) {
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
        if err != kIOReturnSuccess { return }
        defer { IOObjectRelease(iter) }
        while true {
            let reg = IOIteratorNext(iter)
            if reg == 0 { break }
            defer { IOObjectRelease(reg) }
            var serviceDictionary : Unmanaged<CFMutableDictionary>?
            let e = IORegistryEntryCreateCFProperties(reg, &serviceDictionary, kCFAllocatorDefault, .zero)

            if e != kIOReturnSuccess { continue }
            if let dic : NSDictionary = serviceDictionary?.takeRetainedValue() {
                if let type = dic.object(forKey: "IOName") as? String {
                    if type != "display" { continue }

                    if let model = dic.object(forKey: "model") as? Data {
                        let rawStr = String(data: model, encoding: .ascii) ?? String(data: model, encoding: .utf8) ?? "Unknown GPU"
                        systemConfig["gpu"] = rawStr
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
        let temp = getGPUTemp()
        if temp > 0 && temp < 50.0 {
            return 0
        }
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

    func getCurveOptimizerOffsets() -> [Int8] {
        var output = [Int8](repeating: 0, count: 64) // MaxCpus is typically 64
        var outputSize = output.count
        
        let res = IOConnectCallMethod(connect, 110, nil, 0, nil, 0,
                                      nil, nil,
                                      &output, &outputSize)
        
        if res == KERN_SUCCESS {
            return Array(output.prefix(Int(outputSize)))
        } else {
            print("getCurveOptimizerOffsets failed: \(String(cString: mach_error_string(res)))")
            return []
        }
    }
    
    @discardableResult
    func setCurveOptimizerOffset(core: UInt8, offset: Int8) -> kern_return_t {
        // cast offset to raw bit representation for transfer over 64-bit parameter
        let rawOffset = UInt64(bitPattern: Int64(offset))
        var input: [UInt64] = [UInt64(core), rawOffset]
        return IOConnectCallMethod(connect, 111, &input, 2, nil, 0, nil, nil, nil, nil)
    }
}