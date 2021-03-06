//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum TimelineNotification: String {
    case rect
    case vertical
    case select
    case selection

    var name: Notification.Name {
        return Notification.Name(rawValue: "TimelineNotification_\(rawValue)")
    }

    static var allValues: [TimelineNotification] {
        return [.rect, .vertical, .select, .selection]
    }
}
