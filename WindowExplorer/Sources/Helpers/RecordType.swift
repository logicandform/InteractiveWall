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
    case individual

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
            return "Topics"
        case .individual:
            return "Individuals"
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
        case .collection:
            return style.collectionColor
        case .individual:
            return style.individualColor
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
            return NSImage(named: "topic-icon")!
        case .individual:
            return NSImage(named: "individual-icon")!
        }
    }

    var sortOrder: Int {
        switch self {
        case .event:
            return 5
        case .artifact:
            return 6
        case .organization:
            return 4
        case .school:
            return 3
        case .theme:
            return 7
        case .collection:
            return 1
        case .individual:
            return 2
        }
    }

    static var searchValues: [RecordType] {
        return [.event, .school, .collection]
    }

    static var allValues: [RecordType] {
        return [.theme, .event, .artifact, .organization, .school, .collection, .individual]
    }
}
