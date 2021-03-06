//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MapNotification: String {
    case mapRect

    var name: Notification.Name {
        return Notification.Name(rawValue: "MapNotification_\(rawValue)")
    }

    static var allValues: [MapNotification] {
        return [.mapRect]
    }
}
