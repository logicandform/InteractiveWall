//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum WindowType: Equatable {
    case record(Record)
    case image(Media)
    case player(Media)
    case pdf(Media)
    case search
    case menu(app: Int)
    case settings(app: Int)
    case info(app: Int)
    case border
    case collection(Record)

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

    init?(for record: Record) {
        switch record.type {
        case .school, .artifact, .organization, .event, .theme:
            self = .record(record)
        case .collection:
            self = .collection(record)
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
            return style.pdfWindowSize
        case .search:
            return style.searchWindowFrame
        case .menu:
            return style.menuWindowSize
        case .settings:
            return style.settingsWindowSize
        case .info:
            return style.infoWindowSize
        case .border:
            return style.borderWindowSize
        case .collection:
            return style.collectionRecordWindowSize
        }
    }

    var level: NSWindow.Level {
        switch self {
        case .border:
            return style.borderWindowLevel
        case .record, .image, .player, .pdf, .search, .collection:
            return style.movingWindowLevel
        case .menu, .settings, .info:
            return style.staticWindowLevel
        }
    }

    static func == (lhs: WindowType, rhs: WindowType) -> Bool {
        switch (lhs, rhs) {
        case let (.record(lhsModel), .record(rhsModel)):
            return lhsModel.type == rhsModel.type && lhsModel.id == rhsModel.id
        case let (.image(lhsMedia), .image(rhsMedia)):
            return lhsMedia == rhsMedia
        case let (.player(lhsMedia), .player(rhsMedia)):
            return lhsMedia == rhsMedia
        case let (.pdf(lhsMedia), .pdf(rhsMedia)):
            return lhsMedia == rhsMedia
        case let (.collection(lhsModel), .collection(rhsModel)):
            return lhsModel == rhsModel
        default:
            return false
        }
    }
}
