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
    case accessibility

    var image: NSImage? {
        switch self {
        case .split:
            return NSImage(named: "split-icon")
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
        case .accessibility:
            return NSImage(named: "menu_arrow_down")
        }
    }

    var selectedImage: NSImage? {
        switch self {
        case .split:
            return NSImage(named: "merge-icon")
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
        case .accessibility:
            return NSImage(named: "menu_arrow_down")
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

    var unselectedBackgroundColor: NSColor? {
        return style.darkBackground
    }

    var selectedBackgroundColor: NSColor? {
        switch self {
        case .split, .accessibility:
            return style.menuSelectedColor
        case .map, .timeline, .information, .settings, .search:
            return style.darkBackground
        }
    }

    func title(selected: Bool, locked: Bool) -> String {
        switch self {
        case .split:
            let title = selected ? "Merge" : "Split"
            return locked ? "\(title) (Locked)" : title
        case .map:
            return "Map"
        case .timeline:
            return "Timeline"
        case .information:
            return "Information"
        case .settings:
            return "Settings"
        case .search:
            return "Browse"
        case .accessibility:
            return "Accessibility"
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

    static var itemsInMenu: [MenuButtonType] {
        return [.split, .map, .timeline, .information, .search]
    }
}
