//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

extension NSScreen {

    var index: Int {
        return NSScreen.screens.index(of: self) ?? 0
    }

    static func at(position index: Int) -> NSScreen {
        let screen = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }.dropFirst().at(index: index)
        return screen ?? NSScreen.main!
    }

    /// Returns the screen for a given x-position.
    static func containing(x: CGFloat) -> NSScreen? {
        return NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: x, y: 0)) })
    }
}
