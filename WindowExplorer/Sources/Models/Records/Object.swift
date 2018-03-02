//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class Object {

    let id: Int
    let title: String
    let shortTitle: String?
    let subtitle: String?
    let description: String?
    let mediaTitle: String?
    let mediaUrl: URL?
    let thumbnailUrl: URL?
    let comments: String?
    let themeIDs: [Int]
    let relatedSchoolIDs: [Int]
    let relatedOrganizationIDs: [Int]
    let relatedObjectsIDs: [Int]
    let relatedEventIDs: [Int]
    let mediaPath: String?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let shortTitle = "shortTitle"
        static let subtitle = "subtitle"
        static let description = "description"
        static let mediaTitle = "mediaTitle"
        static let mediaUrl = "mediaUrl"
        static let thumbnailUrl = "mediaThumbnailUrl"
        static let comments = "curatorialComments"
        static let themeIDs = "themeIDs"
        static let schoolIDs = "relatedSchoolIDs"
        static let organizationIDs = "relatedOrganizationIDs"
        static let objectIDs = "relatedObjectIDs"
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
        self.shortTitle = json[Keys.shortTitle] as? String
        self.subtitle = json[Keys.subtitle] as? String
        self.description = json[Keys.description] as? String
        self.mediaTitle = json[Keys.mediaTitle] as? String
        self.mediaUrl = URL.from(json[Keys.mediaUrl] as? String)
        self.thumbnailUrl = URL.from(json[Keys.thumbnailUrl] as? String)
        self.comments = json[Keys.comments] as? String
        self.themeIDs = json[Keys.themeIDs] as? [Int] ?? []
        self.relatedSchoolIDs = json[Keys.schoolIDs] as? [Int] ?? []
        self.relatedOrganizationIDs = json[Keys.organizationIDs] as? [Int] ?? []
        self.relatedObjectsIDs = json[Keys.objectIDs] as? [Int] ?? []
        self.relatedEventIDs = json[Keys.eventIDs] as? [Int] ?? []
        self.mediaPath = json[Keys.mediaPath] as? String
    }
}
