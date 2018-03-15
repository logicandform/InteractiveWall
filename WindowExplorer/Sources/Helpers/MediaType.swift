//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum MediaType {
    case image(URL)
    case video(URL)
    case pdf(URL)

    init?(for url: URL) {
        if url.pathExtension.isEmpty {
            return nil
        }

        switch url.pathExtension {
        case "jpg", "png", "tiff":
            self = .image(url)
        case "m4v":
            self = .video(url)
        case "pdf":
            self = .pdf(url)
        default:
            return nil
        }
    }
}
