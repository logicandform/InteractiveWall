//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum ApplicationNotification: String {
    case launchMapExplorer
    case launchTimeline
    case launchNodeNetwork

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [ApplicationNotification] {
        return [.launchMapExplorer, .launchTimeline, .launchNodeNetwork]
    }
}
