//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class BorderlessWindow: NSWindow {

    init(frame: CGRect, controller: NSViewController) {
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true)
        self.contentViewController = controller
        self.styleMask = .borderless
        self.level = .statusBar
        self.isReleasedWhenClosed = false
        self.backgroundColor = .clear
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
