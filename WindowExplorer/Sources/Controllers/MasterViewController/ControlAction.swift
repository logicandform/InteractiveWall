//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ControlAction {
    case launchEverything
    case launchMaps
    case launchNodeNetwork
    case closeApplication
    case restartServers

    init?(title: String) {
        switch title {
        case ControlAction.launchEverything.title:
            self = .launchEverything
        case ControlAction.launchMaps.title:
            self = .launchMaps
        case ControlAction.launchNodeNetwork.title:
            self = .launchNodeNetwork
        case ControlAction.closeApplication.title:
            self = .closeApplication
        case ControlAction.restartServers.title:
            self = .restartServers
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .launchEverything:
            return "Launch All Applications"
        case .launchMaps:
            return "Launch Maps"
        case .launchNodeNetwork:
            return "Launch Node Network"
        case .closeApplication:
            return "Close Applications"
        case .restartServers:
            return "Restart Servers"
        }
    }

    static var menuSelectionActions: [ControlAction] {
        return [.launchEverything, .launchMaps, .launchNodeNetwork, .closeApplication, .restartServers]
    }
}
