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
        case "m4v", "mov":
            self = .video
        case "pdf":
            self = .pdf
        default:
            self = .unknown
        }
    }
}

struct Media: Equatable {
    let url: URL
    let thumbnail: URL
    let title: String?
    let type: MediaType
    let tintColor: NSColor

    init(url: URL, thumbnail: URL, title: String?, color: NSColor) {
        self.url = url
        self.thumbnail = thumbnail
        self.title = title
        self.type = MediaType(for: url)
        self.tintColor = color
    }

    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.url == rhs.url && lhs.thumbnail == rhs.thumbnail && lhs.title == rhs.title && lhs.type == rhs.type
    }
}