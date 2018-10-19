//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordType: String {
    case event
    case artifact
    case organization
    case school
    case theme

    var title: String {
        switch self {
        case .event:
            return "Events"
        case .artifact:
            return "Artifacts"
        case .organization:
            return "Organizations"
        case .school:
            return "Schools"
        case .theme:
            return "Themes"
        }
    }

    var color: NSColor {
        switch self {
        case .event:
            return style.eventColor
        case .artifact:
            return style.artifactColor
        case .organization:
            return style.organizationColor
        case .school:
            return style.schoolColor
        case .theme:
            return style.themeColor
        }
    }

    var imageName: String {
        switch self {
        case .event:
            return "event-icon-colored"
        case .artifact:
            return "artifact-icon-colored"
        case .organization:
            return "organization-icon-colored"
        case .school:
            return "school-icon-colored"
        case .theme:
            return "school-icon-colored"
        }
    }

    static var allValues: [RecordType] {
        return [.event, .artifact, .organization, .school, .theme]
    }
}
