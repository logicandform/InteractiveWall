//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordType: String {
    case school
    case event
    case collection

    var color: NSColor {
        switch self {
        case .school:
            return style.schoolColor
        case .event:
            return style.eventColor
        case .collection:
            return style.collectionColor
        }
    }

    var timelineSortOrder: Int {
        switch self {
        case .school:
            return 2
        case .event:
            return 3
        case .collection:
            return 1
        }
    }

    static var allValues: [RecordType] {
        return [.school, .event, .collection]
    }
}
