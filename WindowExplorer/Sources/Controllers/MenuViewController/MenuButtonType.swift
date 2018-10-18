//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum MenuButtonType {
    case split
    case map
    case timeline
    case nodeNetwork
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
        case .nodeNetwork:
            return NSImage(named: "node-icon")
        case .information:
            return NSImage(named: "info-icon")
        case .settings:
            return NSImage(named: "settings-icon")
        case .search:
            return NSImage(named: "search-icon")
        case .accessibility:
            return NSImage(named: "accessibility-icon")
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
        case .nodeNetwork:
            return NSImage(named: "node-icon-active")
        case .information:
            return NSImage(named: "info-icon-active")
        case .settings:
            return NSImage(named: "settings-icon-active")
        case .search:
            return NSImage(named: "search-icon-active")
        case .accessibility:
            return NSImage(named: "accessibility-icon-active")
        }
    }

    var applicationType: ApplicationType? {
        switch self {
        case .map:
            return .mapExplorer
        case .timeline:
            return .timeline
        case .nodeNetwork:
            return .nodeNetwork
        default:
            return nil
        }
    }

    var selectedBackgroundColor: NSColor? {
        switch self {
        case .split, .map, .timeline, .nodeNetwork, .information, .settings, .search:
            return style.darkBackground
        case .accessibility:
            return style.menuSelectedColor
        }
    }

    func title(selected: Bool, locked: Bool) -> String {
        switch self {
        case .split:
            let title = selected ? "Merge" : "Split"
            return locked ? "Locked" : title
        case .map:
            return "Map"
        case .timeline:
            return "Timeline"
        case .nodeNetwork:
            return "Nodes"
        case .information:
            return "Info"
        case .settings:
            return "Settings"
        case .search:
            return "Browse"
        case .accessibility:
            return "Drop"
        }
    }

    static func from(_ type: ApplicationType) -> MenuButtonType? {
        switch type {
        case .mapExplorer:
            return .map
        case .timeline:
            return .timeline
        case .nodeNetwork:
            return .nodeNetwork
        }
    }

    static var itemsInMenu: [MenuButtonType] {
        return [.split, .map, .timeline, .search, .information]
    }
}
