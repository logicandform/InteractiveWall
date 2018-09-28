//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum SettingType {
    case labels
    case miniMap
    case schools
    case events

    var color: NSColor {
        switch self {
        case .labels:
            return style.menuSelectedColor
        case .miniMap:
            return style.menuSelectedColor
        case .schools:
            return style.schoolColor
        case .events:
            return style.eventColor
        }
    }

    var secondaryColor: NSColor {
        switch self {
        case .labels:
            return style.menuSecondarySelectedColor
        case .miniMap:
            return style.menuSecondarySelectedColor
        case .schools:
            return style.schoolSecondarySelectedColor
        case .events:
            return style.eventSecondarySelectedColor
        }
    }

    var recordType: RecordType? {
        switch self {
        case .schools:
            return .school
        case .events:
            return .event
        case .labels, .miniMap:
            return nil
        }
    }

    static func from(recordType: RecordType) -> SettingType? {
        switch recordType {
        case .school:
            return .schools
        case .event:
            return .events
        case .theme, .artifact, .organization, .collection, .individual:
            return nil
        }
    }
}
