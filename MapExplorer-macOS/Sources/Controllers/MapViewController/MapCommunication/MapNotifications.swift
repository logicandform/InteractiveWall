//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MapNotifications: String {
    case positionChanged
    case endedActivity

    var name: Notification.Name {
        switch self {
        case .positionChanged:
            return Notification.Name(rawValue: rawValue)
        case .endedActivity:
            return Notification.Name(rawValue: rawValue)
        }
    }

    static var allValues: [MapNotifications] {
        return [.positionChanged, .endedActivity]
    }
}
