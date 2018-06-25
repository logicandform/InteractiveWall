//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MapNotification: String {
    case position
    case unpair
    case ungroup

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [MapNotification] {
        return [.position, .unpair, .ungroup]
    }
}
