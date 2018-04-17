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
            return style.recordWindowSize
        case .image:
            return style.imageWindowSize
        case .player:
            return style.playerWindowSize
        case .pdf:
            return Style().pdfWindowSize
        }
    }

    /// Used for checking if the specific media can be move above or below the record it was called from.
    var canAdjustOrigin: Bool {
        switch self {
        case .record:
            return false
        case .image, .player, .pdf:
            return true
        }
    }
}
