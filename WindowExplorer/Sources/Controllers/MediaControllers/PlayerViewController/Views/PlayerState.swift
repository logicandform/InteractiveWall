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
            return nil
        case .paused:
            return NSImage(named: "play-icon")
        case .finished:
            return NSImage(named: "backward-icon")
        }
    }

    var smallImage: NSImage? {
        switch self {
        case .playing:
            return NSImage(named: "pause-icon-small")
        case .paused:
            return NSImage(named: "play-icon-small")
        case .finished:
            return  nil
        }
    }
}
