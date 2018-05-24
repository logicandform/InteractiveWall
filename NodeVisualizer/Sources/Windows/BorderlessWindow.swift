//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class BorderlessWindow: NSWindow {

    private struct Constants {
        static let windowLevelOverMap = NSWindow.Level(30)
    }

    init(frame: CGRect, controller: NSViewController) {
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true)
        self.contentViewController = controller
        self.level = Constants.windowLevelOverMap
        self.isReleasedWhenClosed = false
        self.backgroundColor = .clear
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
