//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum WindowNotifications: String {
    case school

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [WindowNotifications] {
        return [.school]
    }
}
