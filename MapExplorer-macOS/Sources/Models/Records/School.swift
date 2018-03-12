//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class School {

    let id: Int
    let title: String
    let date: String?
    let description: String?
    let coordinate: CLLocationCoordinate2D
    let mediaTitle: String?
    let thumbnail: URL?
    var media = [URL]()

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let date = "date"
        static let description = "description"
        static let coordinate = "coordinate"
        static let thumbnail = "mediaThumbnailUrl"
        static let mediaTitle = "mediaTitle"
        static let media = "mediaPaths"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let title = json[Keys.title] as? String, let coordinateString = json[Keys.coordinate] as? String, let coordinate = CLLocationCoordinate2D(string: coordinateString) else {
            return nil
        }

        self.id = id
        self.title = title
        self.date = json[Keys.date] as? String
        self.description = json[Keys.description] as? String
        self.coordinate = coordinate
        self.mediaTitle = json[Keys.mediaTitle] as? String
        self.thumbnail = URL.from(json[Keys.thumbnail] as? String)

        if let mediaStrings = json[Keys.media] as? [String] {
            self.media = mediaStrings.flatMap { URL.from($0) }
        }
    }
}
