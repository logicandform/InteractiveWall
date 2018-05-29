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

    var color: NSColor {
        switch self {
        case .splitScreen:
            return style.artifactColor
        case .mapToggle:
            return style.eventColor
        case .timelineToggle:
            return style.schoolColor
        case .information:
            return style.organizationColor
        case .settings:
            return style.imageFilterTypeColor
        case .search:
            return style.schoolColor
        }
    }

    var placeholder: NSImage? {
        switch self {
        case .splitScreen:
            return NSImage(named: "image-icon")
        case .mapToggle:
            return NSImage(named: "event-icon")
        case .timelineToggle:
            return NSImage(named: "organization-icon")
        case .information:
            return NSImage(named: "school-icon")
        case .settings:
            return NSImage(named: "artifact-icon")
        case .search:
            return NSImage(named: "image-icon")
        }
    }
}
