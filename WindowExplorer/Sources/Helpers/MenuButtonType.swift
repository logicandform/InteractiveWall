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

    var color: NSColor? {
        switch self {
        case .mapToggle, .timelineToggle, .information, .settings, .search:
            return style.menuSelectedColor
        default:
            return nil
        }
    }


    var placeholder: NSImage? {
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
