//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum ScreenState {
    case connected
    case disconnected

    var image: NSImage? {
        switch self {
        case .connected:
            return NSImage(named: "connected_background")
        case .disconnected:
            return NSImage(named: "disconnected_background")
        }
    }
}
