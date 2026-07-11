// main.swift — APGLaunchHelper
// Entry point for the login-item helper process.
// Bootstraps NSApplication with AppDelegate.

import Cocoa

private let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
