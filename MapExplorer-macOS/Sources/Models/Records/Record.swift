//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class Record: Hashable {

    let type: RecordType
    let id: Int
    let title: String
    let shortTitle: String
    var thumbnail: URL?
    var dates: DateRange?
    var coordinate: CLLocationCoordinate2D?
    let relatedSchoolIDs: [Int]
    let relatedEventIDs: [Int]
    var relatedSchools = [School]()
    var relatedEvents = [Event]()

    var hashValue: Int {
        return id.hashValue ^ type.hashValue
    }

    private struct Keys {
        static let id = "id"
        static let date = "date"
        static let title = "title"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let shortTitle = "shortTitle"
        static let thumbnails = "thumbnailPaths"
        static let schoolIDs = "relatedSchoolIDs"
        static let eventIDs = "relatedEventIDs"
    }


    // MARK: Init

    init?(type: RecordType, json: JSON) {
        guard let id = json[Keys.id] as? Int,
            let title = json[Keys.title] as? String,
            let shortTitle = json[Keys.shortTitle] as? String else {
                return nil
        }

        self.type = type
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.dates = DateRange(from: json[Keys.date] as? String)
        self.relatedSchoolIDs = json[Keys.schoolIDs] as? [Int] ?? []
        self.relatedEventIDs = json[Keys.eventIDs] as? [Int] ?? []
        if let latitude = json[Keys.latitude] as? Double, let longitude = json[Keys.longitude] as? Double {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        if let thumbnailStrings = json[Keys.thumbnails] as? [String], let firstURLString = thumbnailStrings.first {
            self.thumbnail = URL.from(Configuration.serverURL + firstURLString)
        }
    }


    // MARK: API

    func shortestTitle() -> String {
        if shortTitle.isEmpty {
            return title
        }

        return shortTitle.count < title.count ? shortTitle : title
    }


    // MARK: Hashable

    static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.id == rhs.id && lhs.type == rhs.type && lhs.title == rhs.title
    }
}
