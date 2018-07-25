//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


class BorderlessWindow: NSWindow {

    init(frame: CGRect, controller: NSViewController, level: NSWindow.Level) {
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true)
        self.contentViewController = controller
        self.level = level
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
