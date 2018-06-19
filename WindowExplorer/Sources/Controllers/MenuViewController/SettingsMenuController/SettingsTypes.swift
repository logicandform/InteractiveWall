//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum SettingsType {
    case showLabels
    case showMiniMap
    case toggleSchools
    case toggleEvents
    case toggleOrganizations
    case toggleArtifacts

    var color: NSColor {
        switch self {
        case .showLabels:
            return style.menuSelectedColor
        case .showMiniMap:
            return style.menuSelectedColor
        case .toggleSchools:
            return style.schoolColor
        case .toggleEvents:
            return style.eventColor
        case .toggleOrganizations:
            return style.organizationColor
        case .toggleArtifacts:
            return style.artifactColor
        }
    }

    var secondaryColor: NSColor {
        switch self {
        case .showLabels:
            return style.menuSecondarySelectedColor
        case .showMiniMap:
            return style.menuSecondarySelectedColor
        case .toggleSchools:
            return style.schoolSecondarySelectedColor
        case .toggleEvents:
            return style.eventSecondarySelectedColor
        case .toggleOrganizations:
            return style.organizationSecondarySelectedColor
        case .toggleArtifacts:
            return style.artifactSecondarySelectedColor
        }
    }

    var recordType: RecordType? {
        switch self {
        case .toggleSchools:
            return .school
        case .toggleEvents:
            return .event
        case .toggleOrganizations:
            return .organization
        case .toggleArtifacts:
            return .artifact
        case .showLabels, .showMiniMap:
            return nil
        }
    }

    static func from(recordType: RecordType) -> SettingsType? {
        switch recordType {
        case .school:
            return .toggleSchools
        case .event:
            return .toggleEvents
        case .organization:
            return .toggleOrganizations
        case .artifact:
            return .toggleArtifacts
        case .theme:
            return nil
        }
    }
}
