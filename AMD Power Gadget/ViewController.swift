//
//  ViewController.swift
//  AMD Power Gadget
//
//  Created by trulyspinach, modified by Droga (2026) — SwiftUI Tahoe Redesign
//

import Cocoa
import SwiftUI

class ViewController: NSViewController, NSWindowDelegate {

    static var activeSelf: ViewController?

    private var telemetryModel: TelemetryModel?
    private var hasAdjustedInitialSize = false

    // MARK: - Launch

    static func launch(forceFocus: Bool = false) {
        if let vc = ViewController.activeSelf {
            vc.view.window?.orderFrontRegardless()
        } else {
            let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
            let controller = mainStoryboard.instantiateController(
                withIdentifier: NSStoryboard.SceneIdentifier("AMDPowerGadget")
            ) as! NSWindowController
            controller.showWindow(self)
            if forceFocus { controller.window?.orderFrontRegardless() }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Build the ViewModel and embed SwiftUI dashboard
        let model = TelemetryModel()
        telemetryModel = model

        let dashboardView = MainDashboardView(model: model)
        let hostingView = NSHostingView(rootView: dashboardView)
        hostingView.frame = view.bounds
        hostingView.autoresizingMask = [.width, .height]
        view.addSubview(hostingView)

        ViewController.activeSelf = self
        AppDelegate.updateDockIcon()
    }

    override func viewWillAppear() {
        guard let window = view.window else { return }
        window.delegate = self
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Make window resizable in all directions
        var style = window.styleMask
        style.insert(.resizable)
        style.insert(.fullSizeContentView)
        window.styleMask = style

        // Adjust the initial window size to show all dashboard info without scrolling
        if !hasAdjustedInitialSize {
            hasAdjustedInitialSize = true
            let targetSize = NSSize(width: 950, height: 830)
            var frame = window.frame
            
            // Symmetrically adjust origin so the window resizes outwards from its center
            let diffW = targetSize.width - frame.size.width
            let diffH = targetSize.height - frame.size.height
            frame.origin.x -= diffW / 2
            frame.origin.y -= diffH / 2
            frame.size = targetSize
            
            window.setFrame(frame, display: true)
        }

        // Set min/max size constraints
        window.minSize = NSSize(width: 850, height: 750)
        window.maxSize = NSSize(width: 3840, height: 2160)

    }

    // MARK: - AppDelegate hooks

    func toggleTranslucency(enabled: Bool) {
        // Translucency is now handled by SwiftUI materials
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        ViewController.activeSelf = nil
        AppDelegate.updateDockIcon()
    }
}
