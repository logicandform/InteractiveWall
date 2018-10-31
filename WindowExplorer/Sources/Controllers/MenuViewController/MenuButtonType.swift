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

    func image(selected: Bool, side: MenuSide) -> NSImage {
        let color = selected ? style.menuTintColor : style.menuUnselectedColor

        switch self {
        case .split:
            if selected {
                switch side {
                case .left:
                    return NSImage(named: "split-left")!.tinted(with: color)
                case .right:
                    return NSImage(named: "split-right")!.tinted(with: color)
                }
            }
            return NSImage(named: "split-icon")!.tinted(with: color)
        case .map:
            return NSImage(named: "map-icon")!.tinted(with: color)
        case .timeline:
            return NSImage(named: "timeline-icon")!.tinted(with: color)
        case .nodeNetwork:
            return NSImage(named: "node-icon")!.tinted(with: color)
        case .information:
            return NSImage(named: "info-icon")!.tinted(with: color)
        case .search:
            return NSImage(named: "browse-icon")!.tinted(with: color)
        case .accessibility:
            return NSImage(named: "drop-icon")!.tinted(with: color)
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
