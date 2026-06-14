//
//  PStateEditorViewController.swift
//  AMD Power Gadget
//
//  Created by trulyspinach, modified by Droga (2026) on 3/10/20.
//

import Cocoa
import UniformTypeIdentifiers


class PStateEditorViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    var data : [[String: UInt32]] = []

    var changed = false

    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        tableView.dataSource = self
        tableView.delegate = self

        tableView.sizeToFit()

        data = ProcessorModel.shared.getPStateDef().map({value2Dict(v: $0)})
    }

    var isZen5: Bool {
        let id = ProcessorModel.shared.cpuidBasic
        return id.count > 0 && id[0] >= 0x1A
    }

    func value2Dict(v : UInt64) -> [String: UInt32]{
        var r = [String: UInt32]()

        r["enabled"] = UInt32(v >> 63)
        r["IddDiv"] = UInt32((v >> 30) & 0x3)
        r["IddValue"] = UInt32((v >> 22) & 0xff)
        r["CpuVid"] = UInt32((v >> 14) & 0xff)
        
        if isZen5 {
            r["CpuDfsId"] = 1
            r["CpuFid"] = UInt32(v & 0xfff)
        } else {
            r["CpuDfsId"] = UInt32((v >> 8) & 0x1f)
            r["CpuFid"] = UInt32(v & 0xff)
        }

        return r
    }

    func dict2Value(d : [String: UInt32]) -> UInt64 {
        var r : UInt64 = 0

        r |= UInt64(d["enabled"]!) << 63
        r |= (UInt64(d["IddDiv"]!) & 0x3) << 30
        r |= (UInt64(d["IddValue"]!) & 0xff) << 22
        r |= (UInt64(d["CpuVid"]!) & 0xff) << 14
        
        if isZen5 {
            r |= UInt64(d["CpuFid"]!) & 0xfff
        } else {
            r |= (UInt64(d["CpuDfsId"]!) & 0x1f) << 8
            r |= UInt64(d["CpuFid"]!) & 0xff
        }

        return r
    }

    func dict2Speed(v : [String: UInt32]) -> Float{
        if isZen5 {
            return Float(v["CpuFid"]!) * 5.0
        } else {
            return Float(v["CpuFid"]!) / Float(v["CpuDfsId"]!) * 200.0
        }
    }

    func speed2Dict(v : [String: UInt32], speed : UInt32) -> [String: UInt32] {
        var nd = v
        if isZen5 {
            let targetFid = Float(speed) / 5.0
            nd["CpuFid"] = UInt32(targetFid)
        } else {
            let targetFid = Float(speed) / 200.0 * Float(v["CpuDfsId"]!)
            nd["CpuFid"] = UInt32(targetFid)
        }

        return nd
    }

    func scale2Speed(scale : Float) -> UInt32 {
        return UInt32(dict2Speed(v: data[0]) * scale)
    }

    func dict2scale(v : [String: UInt32]) -> Float{
        return dict2Speed(v: v) / dict2Speed(v: data[0])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 8
    }

    @IBAction func apply(_ sender: Any) {
        let arr = data.map{ dict2Value(d: $0) }
        let err = ProcessorModel.shared.setPState(def: arr)
        if err != 0 {
            alertNoPrivilege()
        } else {
            changed = false
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 24
    }

    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        if isZen5 && tableColumn?.identifier.rawValue == "CpuDfsId" {
            return false
        }
        return true
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {

        if tableColumn!.identifier.rawValue == "id"{
            return row
        }

        if tableColumn!.identifier.rawValue == "speed"{
            return dict2Speed(v: data[row])
        }

        if tableColumn!.identifier.rawValue == "scale"{
            return dict2scale(v: data[row])
        }

        return String(format: "%X", data[row][tableColumn!.identifier.rawValue]!)
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if tableColumn!.identifier.rawValue == "enabled"{
            data[row]["enabled"] = (object as! UInt32)
            changed = true
        } else if tableColumn!.identifier.rawValue == "scale"{
            if row == 0 {
                return
            }
            data[row] = speed2Dict(v: data[row], speed: scale2Speed(scale: Float(truncating: object as! NSNumber)))
            changed = true
            tableView.reloadData(forRowIndexes: IndexSet(arrayLiteral: row), columnIndexes: IndexSet(6...8))

        } else {
            if let v = UInt32(object as! String, radix: 16){
                data[row][tableColumn!.identifier.rawValue] = v
                changed = true
            } else {
                alertInvaildInput()
            }
        }
    }

    func alertInvaildInput(){
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Invalid Input", comment: "")
        alert.informativeText = NSLocalizedString("Please type in numbers in hexadecimal.", comment: "")
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("Done", comment: ""))
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

    func alertNoPrivilege(){
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Unable to Set PStateDef", comment: "")
        alert.informativeText = NSLocalizedString("Action was denied as current user does not have enough privilege,\nor was canceled by current user.\n\nRun AMD Power Gadget as root user or disable privilege check with boot-arg '-amdpnopchk'\n\nOtherwise, click 'Once' in the warning message to allow this change.", comment: "")
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("Done", comment: ""))
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

    @IBAction func revert(_ sender: Any) {
        data = ProcessorModel.shared.getPStateDef().map({value2Dict(v: $0)})
        tableView.reloadData()
    }

    @IBAction func close(_ sender: Any) {
        if !changed{
            closeActually()
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Your changes will not be saved", comment: "")
        alert.informativeText = NSLocalizedString("Click apply to save changes before closing this windows.", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Close without saving", comment: ""))
        alert.beginSheetModal(for: view.window!) { (res) in
            if res == NSApplication.ModalResponse.alertSecondButtonReturn {
                self.closeActually()
            }
        }
    }

    func closeActually() {
        if let vc = presentingViewController as? PowerToolViewController{
            vc.updatePStateDef()
        }

        presentingViewController?.dismiss(self)
    }

    @IBAction func `import`(_ sender: Any) {
        let op = NSOpenPanel()
        op.allowedContentTypes = [UTType(filenameExtension: "pstate")].compactMap { $0 }
        op.allowsMultipleSelection = false

        let response = op.runModal()

        guard response == .OK, let url = op.url else {
            return
        }

        guard let arr = NSArray(contentsOf: url) as? [UInt64] else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Invalid File", comment: "")
            alert.informativeText = NSLocalizedString("The selected file could not be read or is not a valid pstate file.", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.beginSheetModal(for: view.window!, completionHandler: nil)
            return
        }

        data = arr.map({value2Dict(v: $0)})
        tableView.reloadData()
    }

    @IBAction func export(_ sender: Any) {
        let op = NSSavePanel()
        op.isExtensionHidden = false
        op.allowedContentTypes = [UTType(filenameExtension: "pstate")].compactMap { $0 }

        op.runModal()

        let arr = data.map{ dict2Value(d: $0) }
        (arr as NSArray).write(to: op.url!, atomically: true)
    }
}
