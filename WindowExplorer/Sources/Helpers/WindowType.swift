//  Copyright © 2018 JABT. All rights reserved.

import Foundation

enum WindowType {
    case record(RecordDisplayable)
    case image(URL)
    case player(URL)
    case pdf(URL)

    init(for type: MediaType) {
        switch type {
        case .image(let url):
            self = .image(url)
        case .video(let url):
            self = .player(url)
        case .pdf(let url):
            self = .pdf(url)
        }
    }

    var size: CGSize {
        switch self {
        case .record:
            return CGSize(width: 416, height: 600)
        case .image:
            return CGSize(width: 640, height: 410)
        default:
            return CGSize(width: 640, height: 600)
        }
    }
}
