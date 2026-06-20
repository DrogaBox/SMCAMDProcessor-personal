//
//  AppDelegate.swift
//  AMD Power Gadget
//
//  Created by trulyspinach, modified by Droga (2026) on 2/22/20.
//

import Cocoa
import ServiceManagement

@MainActor
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var mbController: StatusbarController?

    @IBOutlet weak var appearanceToggle: NSMenuItem!
    @IBOutlet weak var statusbarToggle: NSMenuItem!
    @IBOutlet weak var startAtLoginToggle: NSMenuItem!


    @IBAction func openPage(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal")!)
    }

    @IBAction func orderFrontStandardAboutPanel(_ sender: Any) {
        let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal")!
        let attributedString = NSMutableAttributedString(string: "GitHub Repository\n\nCopyright © 2020-2026 Droga. All rights reserved.")
        attributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: 17))
        
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .credits: attributedString,
            .applicationVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.4",
            .version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        ]
        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    @IBAction func gadget(_ sender: Any) {
        ViewController.launch()

    }

    @IBAction func tool(_ sender: Any) {
        PowerToolViewController.launch()
    }

    static func launchGadget(){
        ViewController.launch()
    }

    static func haveActiveWindows() -> Bool {
        if !UserDefaults.standard.bool(forKey: "statusbarenabled") {return true}

        return ViewController.activeSelf != nil
            || PowerToolViewController.activeSelf != nil
            || SystemMonitorViewController.activeSelf != nil
    }

    static func updateDockIcon() {
        let active = haveActiveWindows()
        NSApplication.shared.setActivationPolicy(active ? .regular : .accessory)
        NotificationCenter.default.post(name: .init("AppActiveWindowsChanged"), object: active)
    }

    @IBAction func changeAppearance(_ sender: Any) {
        applyAppearanceSwitch(translucency: appearanceToggle.state == .off)
    }

    @IBAction func toggleStatusBar(_ sender: Any) {
        applyStatusBarSwitch(enabled: statusbarToggle.state == .off)
    }

    @IBAction func startAtLogin(_ sender: Any) {
        applyStartAtLogin(enabled: startAtLoginToggle.state == .off)
    }

    @IBAction func sysmonitor(_ sender: Any) {
        SystemMonitorViewController.launch()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let keyDefaults = [
            "usetranslucency" : false,
            "statusbarenabled": true,
            "startAtLogin": false,
            "startAtLoginAsked": false
        ]

        UserDefaults.standard.register(defaults: keyDefaults)

        let useTran = UserDefaults.standard.bool(forKey: "usetranslucency")
        let sb = UserDefaults.standard.bool(forKey: "statusbarenabled")
        let sl = UserDefaults.standard.bool(forKey: "startAtLogin")

        if !UserDefaults.standard.bool(forKey: "startAtLoginAsked") {
            askStartup()
            UserDefaults.standard.set(true, forKey: "startAtLoginAsked")
        } else { applyStartAtLogin(enabled: sl) }

        applyStatusBarSwitch(enabled: sb)
        applyAppearanceSwitch(translucency: useTran)


        if !sb {
            ViewController.launch()
        }

    }

    func askStartup() {
        let alert = NSAlert()
        alert.messageText = "Startup at login?"
        alert.informativeText = "Do you want AMD Power Gadget to start in menu bar at login? \n\n This will only be asked once. You can change this setting later under Appearance menu."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        let res = alert.runModal()

        if res == .alertFirstButtonReturn {
            applyStartAtLogin(enabled: true)
        }

        if res == .alertSecondButtonReturn {
            applyStartAtLogin(enabled: false)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        NetworkStats.shared.stop()
        ProcessorModel.shared.closeDriver()
    }

    func applyAppearanceSwitch(translucency : Bool) {
        appearanceToggle.state = translucency ? .on : .off
        ViewController.activeSelf?.toggleTranslucency(enabled: translucency)
        PowerToolViewController.activeSelf?.toggleTranslucency(enabled: translucency)

        UserDefaults.standard.set(translucency, forKey: "usetranslucency")
    }

    func applyStatusBarSwitch(enabled: Bool) {
        statusbarToggle.state = enabled ? .on : .off
        if enabled {
            if mbController == nil {
                mbController = StatusbarController()
                AppDelegate.updateDockIcon()
            }
        } else {
            mbController?.dismiss()
            mbController = nil
        }

        UserDefaults.standard.set(enabled, forKey: "statusbarenabled")
    }

    func applyStartAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.loginItem(identifier: "wtf.spinach.APGLaunchHelper")
            do {
                if enabled {
                    try service.register()
                    print("SMAppService: Registered wtf.spinach.APGLaunchHelper successfully")
                } else {
                    try service.unregister()
                    print("SMAppService: Unregistered wtf.spinach.APGLaunchHelper successfully")
                }
            } catch {
                print("SMAppService failed to update status: \(error)")
            }
        } else {
            // Fallback for legacy macOS versions below 13.0
            SMLoginItemSetEnabled("wtf.spinach.APGLaunchHelper" as CFString, enabled)
        }
    }
}
