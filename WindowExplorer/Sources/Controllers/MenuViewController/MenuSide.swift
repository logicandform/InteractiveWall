//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum MenuSide {
    case left
    case right

    var arrow: NSImage {
        switch self {
        case .left:
            return NSImage(named: "menu_arrow_right")!
        case .right:
            return NSImage(named: "menu_arrow_left")!
        }
    }

    func image(toggled: Bool) -> NSImage {
        switch self {
        case .left:
            return toggled ? MenuSide.right.arrow : arrow
        case .right:
            return toggled ? MenuSide.left.arrow : arrow
        }
    }
}
