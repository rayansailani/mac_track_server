import Foundation
import CoreGraphics
import AppKit

class CursorController {
    private static var lastPosition: CGPoint? = nil

    static func moveCursorBy(dx: Double, dy: Double) {
        let screenFrame = NSScreen.main?.frame ?? .zero
        // Sensitivity factor: lower = smoother, less jumpy
        let sensitivity: CGFloat = 0.7 // Try 0.2–0.7 for more/less smoothing
        // If this is the first move, use the current mouse location
        if lastPosition == nil {
            lastPosition = NSEvent.mouseLocation
        }
        guard var pos = lastPosition else { return }
        pos.x += CGFloat(dx) * sensitivity
        pos.y += CGFloat(dy) * sensitivity
        // Clamp to screen bounds
        pos.x = max(0, min(pos.x, screenFrame.width - 1))
        pos.y = max(0, min(pos.y, screenFrame.height - 1))
//        print(pos)
        CGWarpMouseCursorPosition(pos)
        lastPosition = pos
    }
    static func emulateClick(button: String) {
        let loc = lastPosition ?? NSEvent.mouseLocation
        let mouseButton: CGMouseButton = (button == "right") ? .right : .left
        let mouseDownType: CGEventType = (button == "right") ? .rightMouseDown : .leftMouseDown
        let mouseUpType: CGEventType = (button == "right") ? .rightMouseUp : .leftMouseUp
        if let mouseDown = CGEvent(mouseEventSource: nil, mouseType: mouseDownType, mouseCursorPosition: loc, mouseButton: mouseButton),
           let mouseUp = CGEvent(mouseEventSource: nil, mouseType: mouseUpType, mouseCursorPosition: loc, mouseButton: mouseButton) {
            mouseDown.post(tap: .cghidEventTap)
            mouseUp.post(tap: .cghidEventTap)
        }
    }
}
