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

    var type: RecordType {
        switch self {
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

    static func with(_ name: Notification.Name) -> RecordNotification? {
        return RecordNotification(rawValue: name.rawValue)
    }

    static var allValues: [RecordNotification] {
        return [.school, .event, .organization, .artifact]
    }
}
