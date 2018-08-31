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

    var name: Notification.Name {
        return Notification.Name(rawValue: "SettingsNotification_\(rawValue)")
    }

    static func with(_ type: SettingType) -> SettingsNotification {
        switch type {
        case .schools, .events:
            return .filter
        case .labels:
            return .labels
        case .miniMap:
            return .miniMap
        }
    }

    static var allValues: [SettingsNotification] {
        return [.transition, .unpair, .ungroup, .sync, .split, .merge, .filter, .labels, .miniMap, .reset]
    }
}
