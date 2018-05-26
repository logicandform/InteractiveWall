//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import AppKit

enum RecordFilterType {
    case image
    case school
    case artifact
    case event
    case organization
    case theme
    case all
    
    var title: String? {
        if let recordType = recordType {
            return recordType.title
        }

        switch self {
        case .image:
            return "IMAGES"
        default:
            return nil
        }
    }

    var color: NSColor {
        if let recordType = recordType {
            return recordType.color
        }

        switch self {
        case .image:
            return style.imageFilterTypeColor
        default:
            return style.unselectedRecordIcon
        }
    }

    var placeholder: NSImage? {
        if let recordType = recordType {
            return recordType.placeholder
        }

        switch self {
        case .image:
            return NSImage(named: "image-icon")
        default:
            return nil
        }
    }

    var recordType: RecordType? {
        switch self {
        case .image:
            return nil
        case .school:
            return .school
        case .event:
            return .event
        case .organization:
            return .organization
        case .artifact:
            return .artifact
        case .theme:
            return .theme
        case .all:
            return nil
        }
    }

//    var layout: RelatedItemViewLayout {
//        switch self {
//        case .image:
//            return RelatedItemViewLayout.grid
//        default:
//            return RelatedItemViewLayout.list
//        }
//    }

    static var allValues: [RecordFilterType] {
        return [.image, .school, .event, .organization, .artifact]
    }
}
