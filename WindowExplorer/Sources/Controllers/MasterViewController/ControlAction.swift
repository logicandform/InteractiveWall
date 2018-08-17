//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum ControlAction {
    case launchApplication
    case closeApplication
    case reset

    init?(title: String) {
        switch title {
        case ControlAction.launchApplication.title:
            self = .launchApplication
        case ControlAction.closeApplication.title:
            self = .closeApplication
        case ControlAction.reset.title:
            self = .reset
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .launchApplication:
            return "Launch Application"
        case .reset:
            return "Reset"
        case .closeApplication:
            return "Close Application"
        }
    }

    static var menuSelectionActions: [ControlAction] {
        return [.launchApplication, .reset, .closeApplication]
    }
}
