//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum MenuButtonType {
    case splitScreen
    case mapToggle
    case timelineToggle
    case information
    case settings
    case search

    var selectedPlaceholder: NSImage? {
        switch self {
        case .mapToggle:
            return NSImage(named: "map-icon-active")
        case .timelineToggle:
            return NSImage(named: "timeline-icon-active")
        case .information:
            return NSImage(named: "info-icon-active")
        case .settings:
            return NSImage(named: "settings-icon-active")
        case .search:
            return NSImage(named: "search-icon-active")
        default:
            return nil
        }
    }


    var primaryPlaceholder: NSImage? {
        switch self {
        case .splitScreen:
            return NSImage(named: "single-person-icon")
        case .mapToggle:
            return NSImage(named: "map-icon")
        case .timelineToggle:
            return NSImage(named: "timeline-icon")
        case .information:
            return NSImage(named: "info-icon")
        case .settings:
            return NSImage(named: "settings-icon")
        case .search:
            return NSImage(named: "search-icon")
        }
    }
}
