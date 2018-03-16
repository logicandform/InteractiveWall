//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MapNotifications: String {
    case position
    case unpair
    case ungroup

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [MapNotifications] {
        return [.position, .unpair, .ungroup]
    }
}
