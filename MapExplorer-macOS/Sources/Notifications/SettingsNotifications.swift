//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum SettingsNotification: String {
    case transition
    case unpair
    case ungroup
    case sync
    case split
    case merge
    case filter
    case labels
    case miniMap
    case reset
    case accessibility

    var name: Notification.Name {
        return Notification.Name(rawValue: "SettingsNotification_\(rawValue)")
    }

    static var allValues: [SettingsNotification] {
        return [.transition, .unpair, .ungroup, .sync, .split, .merge, .filter, .labels, .miniMap, .reset, .accessibility]
    }
}
