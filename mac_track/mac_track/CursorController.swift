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
}
