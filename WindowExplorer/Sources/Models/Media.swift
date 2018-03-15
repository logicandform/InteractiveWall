//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MediaType {
    case image
    case video
    case pdf

    init?(for url: URL) {
        if url.pathExtension.isEmpty {
            return nil
        }

        switch url.pathExtension {
        case "jpg", "png", "tiff":
            self = .image
        case "m4v":
            self = .video
        case "pdf":
            self = .pdf
        default:
            return nil
        }
    }
}

struct Media {
    let title: String?
    let url: URL
    let type: MediaType


    init?(url: URL, title: String?) {
        guard let type = MediaType(for: url) else {
            return nil
        }

        self.url = url
        self.title = title
        self.type = type
    }
}
