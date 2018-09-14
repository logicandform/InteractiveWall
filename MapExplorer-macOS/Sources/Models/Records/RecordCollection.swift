//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


enum CollectionType {
    case map
    case timeline
    case themes

    init?(string: String) {
        switch string {
        case "Timeline":
            self = .timeline
        case "Map Explorer":
            self = .map
        default:
            return nil
        }
    }
}


final class RecordCollection: Record {

    let id: Int
    let type = RecordType.collection
    let collectionType: CollectionType
    let title: String
    let dates: TimelineRange?
    var thumbnail: URL?
    var coordinate: CLLocationCoordinate2D?

    var hashValue: Int {
        return id.hashValue
    }

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let presentation = "presentationType"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let date = "date"
        static let thumbnails = "thumbnailPaths"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int,
            let typeString = json[Keys.presentation] as? String,
            let collectionType = CollectionType(string: typeString),
            let title = json[Keys.title] as? String,
            let latitude = json[Keys.latitude] as? Double,
            let longitude = json[Keys.longitude] as? Double else {
                return nil
        }

        self.id = id
        self.title = title
        self.collectionType = collectionType
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let dateString = json[Keys.date] as? String
        self.dates = TimelineRange(from: dateString)
        if let thumbnailStrings = json[Keys.thumbnails] as? [String], let firstURLString = thumbnailStrings.first {
            self.thumbnail = URL.from(Configuration.serverURL + firstURLString)
        }
    }
}
