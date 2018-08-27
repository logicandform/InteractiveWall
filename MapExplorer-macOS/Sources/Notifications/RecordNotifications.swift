//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum RecordNotification: String {
    case display

    var name: Notification.Name {
        return Notification.Name(rawValue: "RecordNotification_\(rawValue)")
    }
}
