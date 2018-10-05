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
    case border(app: Int)
    case collection(Record)
    case indicator
    case master

    init?(for media: Media) {
        switch media.type {
        case .image:
            self = .image(media)
        case .video:
            self = .player(media)
        case .pdf, .rg10:
            self = .pdf(media)
        case .unknown:
            return nil
        }
    }

    init?(for record: Record) {
        switch record.type {
        case .school, .artifact, .organization, .event, .theme, .individual:
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
            return CGSize(width: style.menuWindowWidth, height: Configuration.touchScreen.frameSize.height)
        case .settings:
            return style.settingsWindowSize
        case .info:
            return style.infoWindowSize
        case let .border(appID):
            let width = appID.isEven ? style.borderWindowWidth : style.borderWindowWidth * 2
            return CGSize(width: width, height: Configuration.touchScreen.frameSize.height)
        case .collection:
            return style.collectionRecordWindowSize
        case .indicator:
            return CGSize(width: Configuration.touchScreen.frameSize.width * CGFloat(Configuration.numberOfScreens), height: Configuration.touchScreen.frameSize.height)
        case .master:
            return style.masterWindowSize
        }
    }

    var level: NSWindow.Level {
        switch self {
        case .border:
            return style.borderWindowLevel
        case .record, .image, .player, .pdf, .search, .collection:
            return style.recordWindowLevel
        case .menu, .settings, .info:
            return style.menuWindowLevel
        case .indicator:
            return style.touchIndicatorWindowLevel
        case .master:
            return style.masterWindowLevel
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
