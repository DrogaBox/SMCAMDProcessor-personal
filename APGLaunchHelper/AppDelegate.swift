//
//  AppDelegate.swift
//  APGLaunchHelper
//
//  Created by trulyspinach, modified by Droga (2026) on 7/30/21.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == "wtf.spinach.AMD-Power-Gadget"
        }
        
        if !isRunning {
            guard let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "wtf.spinach.AMD-Power-Gadget") else {
                NSLog("APGLaunchHelper: AMD Power Gadget.app not found by bundle ID; exiting.")
                exit(1)
            }
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: path, configuration: config) { instance, e in
                if let e = e {
                    NSLog("APGLaunchHelper: failed to launch AMD Power Gadget: %@", e.localizedDescription)
                }
                exit(0)
            }
        }
        
    }

}

