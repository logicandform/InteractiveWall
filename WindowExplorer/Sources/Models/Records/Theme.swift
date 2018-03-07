//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class Theme {

    let id: Int
    let title: String
    let description: String?
    let mediaTitle: String?
    let mediaURL: URL?
    let thumbnailURL: URL?
    let mediaPath: String?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let description = "description"
        static let mediaTitle = "mediaTitle"
        static let mediaURL = "mediaURL"
        static let thumbnailURL = "mediaThumbnailURL"
        static let mediaPath = "mediaPath"
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
        self.mediaURL = URL.from(json[Keys.mediaURL] as? String)
        self.thumbnailURL = URL.from(json[Keys.thumbnailURL] as? String)
        self.mediaPath = json[Keys.mediaPath] as? String
    }
}
