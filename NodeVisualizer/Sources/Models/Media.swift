//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum MediaType {
    case image
    case video
    case pdf
    case unknown

    init(for url: URL) {
        if url.pathExtension.isEmpty {
            self = .unknown
        }

        switch url.pathExtension {
        case "jpg", "png", "tiff":
            self = .image
        case "m4v", "mov", "mp4":
            self = .video
        case "pdf":
            self = .pdf
        default:
            self = .unknown
        }
    }

    var icon: NSImage? {
        switch self {
        case .video:
            return NSImage(named: "play-icon")
        default:
            return nil
        }
    }
}


final class Media: Hashable {

    let type: MediaType
    let url: URL
    let localURL: URL
    let thumbnail: URL?
    let localThumbnail: URL?
    let title: String?
    var tintColor: NSColor

    var hashValue: Int {
        var hash = url.hashValue
        if let title = title {
            hash ^= title.hashValue
        }
        if let thumbnail = thumbnail {
            hash ^= thumbnail.hashValue
        }
        return hash
    }


    // MARK: Init

    init(url: URL, localURL: URL, thumbnail: URL?, localThumbnail: URL?, title: String?, color: NSColor) {
        self.type = MediaType(for: url)
        self.url = url
        self.localURL = localURL
        self.thumbnail = thumbnail
        self.localThumbnail = localThumbnail
        self.title = title
        self.tintColor = color
    }

    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.url == rhs.url && lhs.thumbnail == rhs.thumbnail && lhs.title == rhs.title && lhs.type == rhs.type
    }
}
