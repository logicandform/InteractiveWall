//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class School: CustomStringConvertible {

    let id: Int
    let name: String
    let thumbnailURL: URL?
    let imageURL: URL?
    let coordinate: CLLocationCoordinate2D?
    let placeName: String?
    let dates: String?
    let denomination: String?
    let narrativeThreads: String?
    let themes: String?
    let relatedOrganizationsEntityIds: [Int]
    let relatedReligousOrganizationsEntityIDs: [Int]
    let relatedIndigenousOrganizationsEntityIDs: [Int]
    let relatedCommunitiesEntityIds: [Int]
    let relatedIndividualsEntityIDs: [Int]
    let relatedObjectIDs: [Int]

    var description: String {
        return "( [School] ID: \(id), Name: \(name) )"
    }

    private struct Keys {
        static let id = "entity_id"
        static let name = "name"
        static let thumbnail = "thumb"
        static let image = "large"
        static let coordinate = "geolocation"
        static let placeName = "placeName"
        static let dates = "datesOfOperation"
        static let denomination = "denomination"
        static let narrative = "narrativeThreads"
        static let themes = "themes"
        static let organizationIDs = "relatedEntitiesOrganizationsEntityIds"
        static let religousOrgIDs = "relatedEntitiesReligousOrganizationsEntityIds"
        static let indigenousOrgIDs = "relatedEntitiesIndigenousOrganizationsEntityIds"
        static let communitiyIDs = "relatedEntitiesCommunitiesEntityIds"
        static let individualEntityIDs = "relatedEntitiesIndividualsEntityIds"
        static let objectIDs = "relatedObjectIds"
    }


    // MARK: Init

    init?(fromJSON json: [String: Any]) {
        guard let id = json[Keys.id] as? Int, let name = json[Keys.name] as? String else {
            return nil
        }

        self.id = id
        self.name = name
        self.thumbnailURL = URL.from(json[Keys.thumbnail] as? String)
        self.imageURL = URL.from(json[Keys.image] as? String)
        self.coordinate = CLLocationCoordinate2D(geolocation: json[Keys.coordinate] as? String)
        self.placeName = json[Keys.placeName] as? String
        self.dates = json[Keys.dates] as? String
        self.denomination = json[Keys.denomination] as? String
        self.narrativeThreads = json[Keys.narrative] as? String
        self.themes = json[Keys.themes] as? String
        self.relatedOrganizationsEntityIds = json[Keys.organizationIDs] as? [Int] ?? []
        self.relatedReligousOrganizationsEntityIDs = json[Keys.religousOrgIDs] as? [Int] ?? []
        self.relatedIndigenousOrganizationsEntityIDs = json[Keys.indigenousOrgIDs] as? [Int] ?? []
        self.relatedCommunitiesEntityIds = json[Keys.communitiyIDs] as? [Int] ?? []
        self.relatedIndividualsEntityIDs = json[Keys.individualEntityIDs] as? [Int] ?? []
        self.relatedObjectIDs = json[Keys.objectIDs] as? [Int] ?? []
    }

}
