//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

class BorderlessWindow: NSWindow {

    init(frame: CGRect, controller: NSViewController) {
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true)
        self.contentViewController = controller
        self.level = .statusBar
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
