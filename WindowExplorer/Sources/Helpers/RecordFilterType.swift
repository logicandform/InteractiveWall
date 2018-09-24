//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordFilterType {
    case image
    case video
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
        case .video:
            return "VIDEOS"
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
        case .video:
            return style.videoFilterTypeColor
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
        case .video:
            return NSImage(named: "video-icon")
        default:
            return nil
        }
    }

    var recordType: RecordType? {
        switch self {
        case .image, .video:
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

    var layout: RelatedItemViewLayout {
        switch self {
        case .image:
            return RelatedItemViewLayout.images
        case .video:
            return RelatedItemViewLayout.videos
        default:
            return RelatedItemViewLayout.list
        }
    }

    static var recordFilterValues: [RecordFilterType] {
        return [.image, .video, .school, .event, .organization, .artifact]
    }
}
