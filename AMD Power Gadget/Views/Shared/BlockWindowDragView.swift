//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

struct BlockWindowDragView: NSViewRepresentable {
    class BlockDragNSView: NSView {
        override var mouseDownCanMoveWindow: Bool { false }
    }
    func makeNSView(context: Context) -> BlockDragNSView {
        BlockDragNSView()
    }
    func updateNSView(_ nsView: BlockDragNSView, context: Context) {}
}

/// A small history graph: a filled area under a smooth polyline. Hand-drawn with
/// `Path` so the app needs no charting framework.
///
/// `maxValue` fixes the vertical scale (CPU/memory use 1.0 for an absolute 0–100%
/// reading); when nil the graph auto-scales to its own peak (network, power).
