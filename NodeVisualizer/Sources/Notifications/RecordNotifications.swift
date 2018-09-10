//  Copyright © 2018 JABT. All rights reserved.

import Foundation

/// Used to notify the WindowExplorer Application that a record window should be displayed for a given record.
enum RecordNotification: String {
    case display

    var name: Notification.Name {
        return Notification.Name(rawValue: "RecordNotification_\(rawValue)")
    }
}
