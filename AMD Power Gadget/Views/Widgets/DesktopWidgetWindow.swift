//
// Auto-extracted during Phase 2 restructure
//

import Cocoa
import SwiftUI

class DesktopWidgetWindow: NSWindow {
    let gridSize: CGFloat = 20.0
    
    override func setFrameOrigin(_ newOrigin: NSPoint) {
        let snappedX = round(newOrigin.x / gridSize) * gridSize
        let snappedY = round(newOrigin.y / gridSize) * gridSize
        super.setFrameOrigin(NSPoint(x: snappedX, y: snappedY))
    }
    
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        let snappedX = round(frameRect.origin.x / gridSize) * gridSize
        let snappedY = round(frameRect.origin.y / gridSize) * gridSize
        var newRect = frameRect
        newRect.origin = NSPoint(x: snappedX, y: snappedY)
        super.setFrame(newRect, display: flag)
    }
    
    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        let snappedX = round(frameRect.origin.x / gridSize) * gridSize
        let snappedY = round(frameRect.origin.y / gridSize) * gridSize
        var newRect = frameRect
        newRect.origin = NSPoint(x: snappedX, y: snappedY)
        super.setFrame(newRect, display: displayFlag, animate: animateFlag)
    }
}
