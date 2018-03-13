//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class RegularTableView: NSTableView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override var isFlipped: Bool {
        return false
    }
    
}
