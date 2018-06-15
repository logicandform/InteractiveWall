//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum SettingsTypes: Int {
    case showLabels = 50
    case showMiniMap = 51
    case toggleSchools = 52
    case toggleEvents = 53
    case toggleOrganizations = 54
    case toggleArtifacts = 55

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
}
