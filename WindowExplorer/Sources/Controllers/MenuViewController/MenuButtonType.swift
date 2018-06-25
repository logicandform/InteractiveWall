//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum MenuButtonType {
    case split
    case map
    case timeline
    case information
    case settings
    case search
    case testimony

    var image: NSImage? {
        switch self {
        case .split:
            return NSImage(named: "single-person-icon")
        case .map:
            return NSImage(named: "map-icon")
        case .timeline:
            return NSImage(named: "timeline-icon")
        case .information:
            return NSImage(named: "info-icon")
        case .settings:
            return NSImage(named: "settings-icon")
        case .search:
            return NSImage(named: "search-icon")
        case .testimony:
            return NSImage(named: "timeline-icon")
        }
    }

    var selectedImage: NSImage? {
        switch self {
        case .split:
            return NSImage(named: "multiple-person-icon")
        case .map:
            return NSImage(named: "map-icon-active")
        case .timeline:
            return NSImage(named: "timeline-icon-active")
        case .information:
            return NSImage(named: "info-icon-active")
        case .settings:
            return NSImage(named: "settings-icon-active")
        case .search:
            return NSImage(named: "search-icon-active")
        case .testimony:
            return NSImage(named: "timeline-icon-active")
        }
    }

    var detailImage: NSImage? {
        switch self {
        case .split:
            return NSImage(named: "Lock Icon")
        default:
            return nil
        }
    }
}
