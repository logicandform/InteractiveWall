//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ControlAction {
    case launch
    case close
    case restartServers
    case refreshDatabase
    case databaseStatus

    init?(title: String) {
        switch title {
        case ControlAction.launch.title:
            self = .launch
        case ControlAction.close.title:
            self = .close
        case ControlAction.restartServers.title:
            self = .restartServers
        case ControlAction.refreshDatabase.title:
            self = .refreshDatabase
        case ControlAction.databaseStatus.title:
            self = .databaseStatus
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .launch:
            return "Run Application"
        case .close:
            return "Stop Application"
        case .restartServers:
            return "Restart Servers"
        case .refreshDatabase:
            return "Refresh Local Database"
        case .databaseStatus:
            return "Check Database Status"
        }
    }

    static var menuSelectionActions: [ControlAction] {
        return [.launch, .close, .restartServers, .refreshDatabase, .databaseStatus]
    }
}
