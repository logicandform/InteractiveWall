//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class Event {

    let id: Int
    let title: String
    let date: String?
    let description: String?
    let coordinate: CLLocationCoordinate2D?
    let mediaTitle: String?
    let mediaUrl: URL?
    let mediaThumbnailUrl: URL?
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
        static let mediaTitle = "mediaTitle"
        static let mediaUrl = "mediaUrl"
        static let mediaThumbnailUrl = "mediaThumbnailUrl"
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
        self.description = json[Keys.description] as? String
        self.date = json[Keys.date] as? String
        self.coordinate = CLLocationCoordinate2D(geolocation: json[Keys.coordinate] as? String)
        self.mediaTitle = json[Keys.mediaTitle] as? String
        self.mediaUrl = URL.from(json[Keys.mediaUrl] as? String)
        self.mediaThumbnailUrl = URL.from(json[Keys.mediaThumbnailUrl] as? String)
        self.relatedSchoolIDs = json[Keys.schoolIDs] as? [Int] ?? []
        self.relatedOrganizationIDs = json[Keys.organizationIDs] as? [Int] ?? []
        self.relatedArtifactsIDs = json[Keys.artifactIDs] as? [Int] ?? []
        self.relatedEventIDs = json[Keys.eventIDs] as? [Int] ?? []
        self.mediaPath = json[Keys.mediaPath] as? String
    }
}
