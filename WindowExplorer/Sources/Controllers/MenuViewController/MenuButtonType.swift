//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum MenuButtonType {
    case split
    case map
    case timeline
    case nodeNetwork
    case information
    case search
    case accessibility

    var image: NSImage {
        switch self {
        case .split:
            return NSImage(named: "split-icon")!
        case .map:
            return NSImage(named: "map-icon")!
        case .timeline:
            return NSImage(named: "timeline-icon")!
        case .nodeNetwork:
            return NSImage(named: "node-icon")!
        case .information:
            return NSImage(named: "info-icon")!
        case .search:
            return NSImage(named: "browse-icon")!
        case .accessibility:
            return NSImage(named: "drop-icon")!
        }
    }

    var selectedImage: NSImage? {
        return image.tinted(with: style.menuTintColor)
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
        return [.information, .search, .map, .timeline, .nodeNetwork, .split]
    }
}
