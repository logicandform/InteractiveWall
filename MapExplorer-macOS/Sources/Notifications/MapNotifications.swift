//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MapNotifications: String {
    case positionChanged
    case endedActivity

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [MapNotifications] {
        return [.positionChanged, .endedActivity]
    }
}
