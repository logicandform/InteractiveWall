//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum NodeNotification: String {
    case pair

    var name: Notification.Name {
        return Notification.Name(rawValue: "NodeNotification_\(rawValue)")
    }

    static var allValues: [NodeNotification] {
        return [.pair]
    }
}
