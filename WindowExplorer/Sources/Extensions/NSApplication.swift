//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

extension NSScreen {

    /// Returns index of screen based on origin location; low -> high
    var orderedIndex: Int? {
        let screens = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }
        return screens.index(of: self)
    }

    static func at(position index: Int) -> NSScreen {
        let screen = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }.dropFirst().at(index: index)
        return screen ?? NSScreen.main!
    }

    static func at(appID index: Int) -> NSScreen {
        let screen = (index / Configuration.appsPerScreen) + 1
        return at(position: screen)
    }

    /// Returns the screen for a given x-position.
    static func containing(x: CGFloat) -> NSScreen? {
        return NSScreen.screens.first(where: { $0.frame.contains(CGPoint(x: x, y: 0)) })
    }

    static var mainScreen: NSScreen {
        return NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }.first!
    }
}
