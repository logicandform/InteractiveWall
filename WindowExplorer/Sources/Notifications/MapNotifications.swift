//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MapNotification: String {
    case mapRect

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [MapNotification] {
        return [.mapRect]
    }
}
