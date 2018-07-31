//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class School: Record {

    let id: Int
    let type = RecordType.school
    let title: String
    var coordinate: CLLocationCoordinate2D
    let dates: TimelineRange?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let date = "date"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int,
            let title = json[Keys.title] as? String,
            let latitude = json[Keys.latitude] as? Double,
            let longitude = json[Keys.longitude] as? Double else {
            return nil
        }

        self.id = id
        self.title = title
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.dates = TimelineRange(json[Keys.date] as? String)
    }
}
