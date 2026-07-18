//
//  BlockWindowDragView.swift
//  AMD Power Gadget
//
//  Prevents NSWindow dragging when interacting with its containing view.
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
