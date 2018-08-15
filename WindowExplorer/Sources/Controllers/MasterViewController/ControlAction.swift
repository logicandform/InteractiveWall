//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ControlAction {
    case launchMapExplorer
    case menuLaunchedMapExplorer
    case menuLaunchedTimeline
    case closeApplication
    case reset
    case disconnected

    init?(title: String) {
        switch title {
        case ControlAction.launchMapExplorer.title:
            self = .launchMapExplorer
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
        case .reset:
            return "Reset"
        case .closeApplication:
            return "Close Application"
        case .disconnected:
            return ""
        case .menuLaunchedTimeline:
            return ""
        case .menuLaunchedMapExplorer:
            return ""
        }
    }

    var image: NSImage? {
        switch self {
        case .closeApplication:
            return NSImage(named: "connected_background")
        case .reset:
            return NSImage(named: "connected_background")
        case .disconnected:
            return NSImage(named: "disconnected_background")
        case .launchMapExplorer:
            return NSImage(named: "connected_background")
        case .menuLaunchedTimeline, .menuLaunchedMapExplorer:
            return nil
        }
    }

    static var menuSelectionActions: [ControlAction] {
        return [.launchMapExplorer, .reset, .closeApplication]
    }
}
