//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum TimelineNotification: String {
    case rect
    case select
    case highlight
    case sync

    var name: Notification.Name {
        return Notification.Name(rawValue: "TimelineNotification_\(rawValue)")
    }

    static var allValues: [TimelineNotification] {
        return [.rect, .select, .highlight, .sync]
    }
}
