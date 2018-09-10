//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct InfoLabel {
    let title: String
    let description: String

    private struct Keys {
        static let title = "title"
        static let description = "content"
    }

    init?(json: JSON) {
        guard let title = json[Keys.title] as? String, let description = json[Keys.description] as? String else {
            return nil
        }

        self.title = title
        self.description = description
    }
}


struct InfoItem {
    let title: String
    let labels: [InfoLabel]
    let media: Media

    private struct Keys {
        static let title = "title"
        static let labels = "sections"
        static let video = "videoURL"
        static let localVideo = "localVideoURL"
        static let thumbnail = "thumbnailURL"
        static let localThumbnail = "localThumbnailURL"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let title = json[Keys.title] as? String, let labels = json[Keys.labels] as? [JSON] else {
            return nil
        }

        // Each item will have either a video or an image
        if let video = json[Keys.video] as? String, let localVideo = json[Keys.localVideo] as? String, !video.isEmpty, let url = URL.from(Configuration.serverURL + video) {
            let localURL = URL(fileURLWithPath: localVideo)
            self.media = Media(url: url, localURL: localURL, thumbnail: nil, localThumbnail: nil, title: nil, color: style.menuSelectedColor)
        } else if let thumbnail = json[Keys.thumbnail] as? String, let localThumbnail = json[Keys.localThumbnail] as? String, !thumbnail.isEmpty, let url = URL.from(Configuration.serverURL + thumbnail) {
            let localURL = URL(fileURLWithPath: localThumbnail)
            self.media = Media(url: url, localURL: localURL, thumbnail: nil, localThumbnail: nil, title: nil, color: style.menuSelectedColor)
        } else {
            return nil
        }

        self.title = title
        self.labels = labels.compactMap { InfoLabel(json: $0) }
    }
}
