//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class School {

    let id: Int
    let title: String
    let date: String?
    let description: String?
    let coordinate: CLLocationCoordinate2D?
    let mediaTitle: String?
    let mediaURL: URL?
    let thumbnailURL: URL?
    let themeIDs: [Int]
    let relatedSchoolIDs: [Int]
    let relatedOrganizationIDs: [Int]
    let relatedArtifactsIDs: [Int]
    let relatedEventIDs: [Int]
    let mediaPath: String?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let date = "date"
        static let description = "description"
        static let coordinate = "coordinate"
        static let mediaURL = "mediaURL"
        static let thumbnailURL = "mediaThumbnailURL"
        static let mediaTitle = "mediaTitle"
        static let themeIDs = "themeIDs"
        static let schoolIDs = "relatedSchoolIDs"
        static let organizationIDs = "relatedOrganizationIDs"
        static let artifactIDs = "relatedArtifactIDs"
        static let eventIDs = "relatedEventIDs"
        static let mediaPath = "mediaPath"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let title = json[Keys.title] as? String else {
            return nil
        }

        self.id = id
        self.title = title
        self.date = json[Keys.date] as? String
        self.description = json[Keys.description] as? String
        self.coordinate = CLLocationCoordinate2D(geolocation: json[Keys.coordinate] as? String)
        self.mediaTitle = json[Keys.mediaTitle] as? String
        self.mediaURL = URL.from(json[Keys.mediaURL] as? String)
        self.thumbnailURL = URL.from(json[Keys.thumbnailURL] as? String)
        self.themeIDs = json[Keys.themeIDs] as? [Int] ?? []
        self.relatedSchoolIDs = json[Keys.schoolIDs] as? [Int] ?? []
        self.relatedOrganizationIDs = json[Keys.organizationIDs] as? [Int] ?? []
        self.relatedArtifactsIDs = json[Keys.artifactIDs] as? [Int] ?? []
        self.relatedEventIDs = json[Keys.eventIDs] as? [Int] ?? []
        self.mediaPath = json[Keys.mediaPath] as? String
    }
}
