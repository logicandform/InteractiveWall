//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum SettingType {
    case labels
    case miniMap
    case schools
    case events
    case organizations
    case artifacts

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
        case .organizations:
            return style.organizationColor
        case .artifacts:
            return style.artifactColor
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
        case .organizations:
            return style.organizationSecondarySelectedColor
        case .artifacts:
            return style.artifactSecondarySelectedColor
        }
    }

    var recordType: RecordType? {
        switch self {
        case .schools:
            return .school
        case .events:
            return .event
        case .organizations:
            return .organization
        case .artifacts:
            return .artifact
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
        case .organization:
            return .organizations
        case .artifact:
            return .artifacts
        case .theme:
            return nil
        }
    }
}
