//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum WindowType {
    case record(RecordDisplayable)
    case image(Media)
    case player(Media)
    case pdf(Media)

    init?(for media: Media) {
        switch media.type {
        case .image:
            self = .image(media)
        case .video:
            self = .player(media)
        case .pdf:
            self = .pdf(media)
        case .unknown:
            return nil
        }
    }

    var size: CGSize {
        switch self {
        case .record:
            return CGSize(width: 416, height: 640)
        case .image:
            return CGSize(width: 640, height: 410)
        case .player:
            return CGSize(width: 640, height: 600)
        case .pdf:
            return CGSize(width: 600, height: 640)
        }
    }
}
