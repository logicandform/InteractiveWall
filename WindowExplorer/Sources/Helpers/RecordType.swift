//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordType: String {
    case event
    case artifact
    case organization
    case school

    var title: String {
        switch self {
        case .event:
            return "EVENTS"
        case .artifact:
            return "ARTIFACTS"
        case .organization:
            return "ORGANIZATIONS"
        case .school:
            return "SCHOOLS"
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
        }
    }

    static var allValues: [RecordType] {
        return [.event, .artifact, .organization, .school]
    }
}
