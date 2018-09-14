//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class School: Record {

    let id: Int
    let type = RecordType.school
    let title: String
    let shortTitle: String
    let dates: TimelineRange?
    var thumbnail: URL?
    var coordinate: CLLocationCoordinate2D?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let shortTitle = "shortTitle"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let date = "date"
        static let thumbnails = "thumbnailPaths"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int,
            let title = json[Keys.title] as? String,
            let shortTitle = json[Keys.shortTitle] as? String,
            let latitude = json[Keys.latitude] as? Double,
            let longitude = json[Keys.longitude] as? Double else {
            return nil
        }

        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let dateString = json[Keys.date] as? String
        self.dates = TimelineRange(from: dateString)
        if let thumbnailStrings = json[Keys.thumbnails] as? [String], let firstURLString = thumbnailStrings.first {
            self.thumbnail = URL.from(Configuration.serverURL + firstURLString)
        }
    }
}
