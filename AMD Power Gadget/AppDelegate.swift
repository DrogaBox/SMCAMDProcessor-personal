//
//  AppDelegate.swift
//  AMD Power Gadget
//
//  Created by trulyspinach, modified by Droga (2026) on 2/22/20.
//

import Cocoa
import ServiceManagement
import Metal

@MainActor
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var mbController: StatusbarController?

    @IBOutlet weak var appearanceToggle: NSMenuItem!
    @IBOutlet weak var statusbarToggle: NSMenuItem!
    @IBOutlet weak var startAtLoginToggle: NSMenuItem!


    @IBAction func openPage(_ sender: Any) {
        if let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func orderFrontStandardAboutPanel(_ sender: Any) {
        guard let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") else { return }
        let attributedString = NSMutableAttributedString(string: "GitHub Repository\n\nSpecial thanks to the AMD OS X community!\n\nCopyright © 2020-2026 Droga. All rights reserved.")
        attributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: 17))
        
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .credits: attributedString,
            .applicationVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.2.0",
            .version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        ]
        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    @IBAction func gadget(_ sender: Any) {
        ViewController.launch()

    }

    @IBAction func tool(_ sender: Any) {
        ViewController.launch()
        TelemetryModel.shared.selectedTab = .advanced
    }

    static func launchGadget(){
        ViewController.launch()
    }

    static func haveActiveWindows() -> Bool {
        if !UserDefaults.standard.bool(forKey: "statusbarenabled") {return true}

        return ViewController.activeSelf != nil
    }

    static func updateDockIcon() {
        let active = haveActiveWindows()
        NSApplication.shared.setActivationPolicy(active ? .regular : .accessory)
        NotificationCenter.default.post(name: .init("AppActiveWindowsChanged"), object: active)
    }

    @IBAction func changeAppearance(_ sender: Any) {
        applyAppearanceSwitch(translucency: (appearanceToggle?.state ?? .off) == .off)
    }

    @IBAction func toggleStatusBar(_ sender: Any) {
        applyStatusBarSwitch(enabled: (statusbarToggle?.state ?? .off) == .off)
    }

    @IBAction func startAtLogin(_ sender: Any) {
        applyStartAtLogin(enabled: (startAtLoginToggle?.state ?? .off) == .off)
    }

    @IBAction func sysmonitor(_ sender: Any) {
        ViewController.launch()
        TelemetryModel.shared.selectedTab = .fanControl
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let keyDefaults: [String: Any] = [
            "usetranslucency" : false,
            "statusbarenabled": true,
            "startAtLogin": false,
            "startAtLoginAsked": false,
            "app_language_code": ""
        ]

        UserDefaults.standard.register(defaults: keyDefaults)

        // Apply in-app language override before any UI / localized strings load.
        AppLanguage.applyStoredPreference()

        // Chart style: rewrite legacy Spanish UserDefaults keys → stable English keys.
        AppChartStyle.migrateStoredPreference()

        let useTran = UserDefaults.standard.bool(forKey: "usetranslucency")
        let sb = UserDefaults.standard.bool(forKey: "statusbarenabled")
        let sl = UserDefaults.standard.bool(forKey: "startAtLogin")

        if !UserDefaults.standard.bool(forKey: "startAtLoginAsked") {
            UserDefaults.standard.set(true, forKey: "startAtLoginAsked")
            askStartup()
        } else { applyStartAtLogin(enabled: sl) }

        applyStatusBarSwitch(enabled: sb)
        applyAppearanceSwitch(translucency: useTran)


        if !sb {
            ViewController.launch()
        }

        // Initialize Desktop Widgets if enabled
        DesktopWidgetManager.shared.refreshWidgets()
        
        // Start background telemetry sampling for History
        _ = HistoryManager.shared
        
        // Fallback Mode Detection
        if !UserDefaults.standard.bool(forKey: "user_forced_low_performance") {
            let device = MTLCreateSystemDefaultDevice()
            if device == nil {
                print("No Metal acceleration detected. Enabling Low Performance Mode.")
                UserDefaults.standard.set(true, forKey: "low_performance_mode")
            } else {
                UserDefaults.standard.set(false, forKey: "low_performance_mode")
            }
        }
    }

    func askStartup() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Startup at login?", comment: "")
        alert.informativeText = NSLocalizedString("Do you want AMD Power Gadget to start in menu bar at login? \n\n This will only be asked once. You can change this setting later under Appearance menu.", comment: "")
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("Yes", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("No", comment: ""))
        NSApp.activate(ignoringOtherApps: true)
        let res = alert.runModal()

        if res == .alertFirstButtonReturn {
            applyStartAtLogin(enabled: true)
        }

        if res == .alertSecondButtonReturn {
            applyStartAtLogin(enabled: false)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        TelemetryModel.shared.commitPendingChanges()
        NetworkStats.shared.stop()
        ProcessorModel.shared.closeDriver()
    }

    func applyAppearanceSwitch(translucency : Bool) {
        appearanceToggle?.state = translucency ? .on : .off
        ViewController.activeSelf?.toggleTranslucency(enabled: translucency)

        UserDefaults.standard.set(translucency, forKey: "usetranslucency")
    }

    func applyStatusBarSwitch(enabled: Bool) {
        statusbarToggle?.state = enabled ? .on : .off
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
            let service = SMAppService.mainApp
            do {
                if enabled {
                    try service.register()
                    print("SMAppService: Registered main app successfully")
                } else {
                    try service.unregister()
                    print("SMAppService: Unregistered main app successfully")
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
