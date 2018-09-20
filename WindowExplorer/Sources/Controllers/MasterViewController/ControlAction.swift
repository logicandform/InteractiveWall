//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ControlAction {
    case launch
    case close
    case restartServers

    init?(title: String) {
        switch title {
        case ControlAction.launch.title:
            self = .launch
        case ControlAction.close.title:
            self = .close
        case ControlAction.restartServers.title:
            self = .restartServers
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .launch:
            return "Launch Applications"
        case .close:
            return "Close Applications"
        case .restartServers:
            return "Restart Servers"
        }
    }

    static var menuSelectionActions: [ControlAction] {
        return [.launch, .close, .restartServers]
    }
}
