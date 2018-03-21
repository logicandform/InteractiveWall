//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

extension NSScreen {

    var index: Int {
        return NSScreen.screens.index(of: self) ?? 0
    }

    /// Returns the screen for a given x-position.
    static func containing(x: CGFloat) -> NSScreen? {
        return NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: x, y: 0)) })
    }
}

