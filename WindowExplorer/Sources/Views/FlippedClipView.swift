//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class FlippedClipView: NSClipView {

    override var isFlipped: Bool {
        return true
    }
}
