//  Copyright © 2018 JABT. All rights reserved.

import Foundation

/// Used to notify the WindowExplorer Application that a record window should be displayed for a given record.
enum RecordNotification: String {
    case school
    case event
    case organization
    case artifact

    var name: Notification.Name {
        return Notification.Name(rawValue: "RecordNotification_\(rawValue)")
    }

    static func with(_ type: RecordType) -> RecordNotification {
        switch type {
        case .school:
            return .school
        case .event:
            return .event
        case .organization:
            return .organization
        case .artifact:
            return .artifact
        }
    }
}
