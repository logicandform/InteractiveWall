//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordType: String, SearchItemDisplayable {
    case event
    case artifact
    case organization
    case school
    case theme
    case collection

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
        case .collection:
            return "Collections"
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
            return style.selectedColor
        case .collection:
            return style.collectionColor
        }
    }

    var placeholder: NSImage {
        switch self {
        case .event:
            return NSImage(named: "event-icon")!
        case .artifact:
            return NSImage(named: "artifact-icon")!
        case .organization:
            return NSImage(named: "organization-icon")!
        case .school:
            return NSImage(named: "school-icon")!
        case .theme:
            return NSImage(named: "theme-icon")!
        case .collection:
            return NSImage(named: "theme-icon")!
        }
    }

    static var searchValues: [RecordType] {
        return [.event, .school, .theme]
    }

    static var allValues: [RecordType] {
        return [.event, .artifact, .organization, .school, .theme, .collection]
    }
}
