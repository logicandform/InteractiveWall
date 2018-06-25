//  Copyright © 2018 JABT. All rights reserved.

import Foundation


enum SettingsNotification: String {
    case sync
    case split
    case merge
    case filter
    case labels
    case miniMap
    case reset

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static func with(_ type: SettingType) -> SettingsNotification {
        switch type {
        case .schools, .events, .organizations, .artifacts:
            return .filter
        case .labels:
            return .labels
        case .miniMap:
            return .miniMap
        }
    }

    static var allValues: [SettingsNotification] {
        return [.sync, .split, .merge, .filter, .labels, .miniMap, .reset]
    }
}
