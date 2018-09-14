//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


protocol Record {
    var type: RecordType { get }
    var id: Int { get }
    var title: String { get }
    var coordinate: CLLocationCoordinate2D? { get set }
    var dates: TimelineRange? { get }
    var thumbnail: URL? { get }
}


enum RecordType: String {
    case school
    case event
    case organization
    case artifact
    case collection

    var color: NSColor {
        switch self {
        case .school:
            return style.schoolColor
        case .event:
            return style.eventColor
        case .organization:
            return style.organizationColor
        case .artifact:
            return style.artifactColor
        case .collection:
            return style.collectionColor
        }
    }

    var timelineSortOrder: Int {
        switch self {
        case .school:
            return 1
        case .event:
            return 2
        case .organization:
            return 3
        case .artifact:
            return 4
        case .collection:
            return 5
        }
    }

    static var allValues: [RecordType] {
        return [.school, .event, .organization, .artifact, .collection]
    }
}
