//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

enum VolumeLevel {
    case mute
    case low
    case medium
    case high

    var gain: Double {
        switch self {
        case .mute:
            return 0
        case .low:
            return 0.3
        case .medium:
            return 0.6
        case .high:
            return 0.9
        }
    }

    var image: NSImage? {
        switch self {
        case .mute:
            return NSImage(named: "sound-0-icon")
        case .low:
            return NSImage(named: "sound-1-icon")
        case .medium:
            return NSImage(named: "sound-2-icon")
        case .high:
            return NSImage(named: "sound-3-icon")
        }
    }
}
