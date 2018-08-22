//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum TimelineNotification: String {
    case rect
    case select
    case selection
    case highlight

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [TimelineNotification] {
        return [.rect, .select, .selection, .highlight]
    }
}
