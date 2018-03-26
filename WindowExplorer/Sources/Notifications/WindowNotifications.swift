//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum WindowNotification: String {
    case school
    case event

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    var type: RecordType {
        switch self {
        case .school:
            return .school
        case .event:
            return .event
        }
    }

    static func with(_ name: Notification.Name) -> WindowNotification? {
        return WindowNotification(rawValue: name.rawValue)
    }

    static var allValues: [WindowNotification] {
        return [.school, .event]
    }
}
