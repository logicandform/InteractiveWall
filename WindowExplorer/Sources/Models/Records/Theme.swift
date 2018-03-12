//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class Theme {

    let id: Int
    let title: String
    let description: String?
    let mediaTitle: String?
    let thumbnail: URL?
    var media = [URL]()

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let description = "description"
        static let mediaTitle = "mediaTitle"
        static let thumbnail = "mediaThumbnailUrl"
        static let media = "mediaPaths"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let title = json[Keys.title] as? String else {
            return nil
        }

        self.id = id
        self.title = title
        self.description = json[Keys.description] as? String
        self.mediaTitle = json[Keys.mediaTitle] as? String
        self.thumbnail = URL.from(json[Keys.thumbnail] as? String)
        if let mediaStrings = json[Keys.media] as? [String] {
            self.media = mediaStrings.flatMap { URL.from($0) }
        }
    }
}
