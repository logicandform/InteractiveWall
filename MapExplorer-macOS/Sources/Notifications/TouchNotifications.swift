//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum TouchNotifications: String {
    case touchEvent

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [TouchNotifications] {
        return [.touchEvent]
    }
}
