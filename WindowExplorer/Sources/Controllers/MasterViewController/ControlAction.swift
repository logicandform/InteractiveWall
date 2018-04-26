//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ControlAction {
    case launchMapExplorer
    case launchTimeline
    case closeApplication

    init?(title: String) {
        switch title {
        case ControlAction.launchMapExplorer.title:
            self = .launchMapExplorer
        case ControlAction.launchTimeline.title:
            self = .launchTimeline
        case ControlAction.closeApplication.title:
            self = .closeApplication
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .launchMapExplorer:
            return "Launch MapExplorer"
        case .launchTimeline:
            return "Launch Timeline"
        case .closeApplication:
            return "Close Application"
        }
    }

    var image: NSImage? {
        switch self {
        case .launchMapExplorer:
            return NSImage(named: "map_background")
        case .launchTimeline:
            return NSImage(named: "timeline_background")
        case .closeApplication:
            return NSImage(named: "planar_background")
        }
    }

    static var allValues: [ControlAction] {
        return [.launchMapExplorer, .launchTimeline, .closeApplication]
    }
}
