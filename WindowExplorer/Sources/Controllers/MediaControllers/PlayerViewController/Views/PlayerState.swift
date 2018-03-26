//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

enum PlayerState {
    case playing
    case paused
    case finished

    var image: NSImage? {
        switch self {
        case .playing:
            return NSImage(named: "")
        case .paused:
            return NSImage(named: "")
        case .finished:
            return NSImage(named: "")
        }
    }
}
