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
    case accessibility

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
            return NSImage(named: "testimony-icon")
        case .accessibility:
            return NSImage(named: "accessibility-icon")
        }
    }

    var selectedImage: NSImage? {
        switch self {
        case .split:
            return NSImage(named: "multiple-person-icon")
        case .map:
            return NSImage(named: "map-icon")?.tinted(with: style.menuSelectedColor)
        case .timeline:
            return NSImage(named: "timeline-icon")?.tinted(with: style.menuSelectedColor)
        case .information:
            return NSImage(named: "info-icon")?.tinted(with: style.menuSelectedColor)
        case .settings:
            return NSImage(named: "settings-icon")?.tinted(with: style.menuSelectedColor)
        case .search:
            return NSImage(named: "search-icon")?.tinted(with: style.menuSelectedColor)
        case .testimony:
            return NSImage(named: "testimony-icon")?.tinted(with: style.menuSelectedColor)
        case .accessibility:
            return NSImage(named: "accessibility-icon")?.tinted(with: style.menuSelectedColor)
        }
    }

    var applicationType: ApplicationType? {
        switch self {
        case .map:
            return .mapExplorer
        case .timeline:
            return .timeline
        default:
            return nil
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

    static func from(_ type: ApplicationType) -> MenuButtonType? {
        switch type {
        case .mapExplorer:
            return .map
        case .timeline:
            return .timeline
        case .nodeNetwork:
            return nil
        }
    }

    static var allValues: [MenuButtonType] {
        return [.split, .map, .timeline, .information, .settings, .search, .testimony]
    }
}
