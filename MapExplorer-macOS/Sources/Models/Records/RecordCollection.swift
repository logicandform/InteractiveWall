//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


enum CollectionType {
    case map
    case timeline
    case themes
    case singular
    case testimony

    init?(string: String?) {
        switch string?.lowercased() {
        case "map":
            self = .map
        case "timeline":
            self = .timeline
        case "themes":
            self = .themes
        case "stand-alone":
            self = .singular
        case "survivors speak":
            self = .testimony
        default:
            return nil
        }
    }
}


final class RecordCollection: Record {

    let id: Int
    let type = RecordType.collection
    let collectionType: CollectionType?
    let title: String
    let shortTitle: String
    let dates: TimelineRange?
    var thumbnail: URL?
    var coordinate: CLLocationCoordinate2D?

    var hashValue: Int {
        return id.hashValue
    }

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let shortTitle = "shortTitle"
        static let presentation = "presentationType"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let date = "date"
        static let thumbnails = "thumbnailPaths"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int,
            let title = json[Keys.title] as? String,
            let shortTitle = json[Keys.shortTitle] as? String else {
                return nil
        }

        self.id = id
        self.collectionType = CollectionType(string: json[Keys.presentation] as? String)
        self.title = title
        self.shortTitle = shortTitle
        let dateString = json[Keys.date] as? String
        self.dates = TimelineRange(from: dateString)
        if let thumbnailStrings = json[Keys.thumbnails] as? [String], let firstURLString = thumbnailStrings.first {
            self.thumbnail = URL.from(Configuration.serverURL + firstURLString)
        }
        if let latitude = json[Keys.latitude] as? Double, let longitude = json[Keys.longitude] as? Double {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
