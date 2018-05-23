//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class Place: Hashable {

    let id: Int
    let title: String
    let coordinate: CLLocationCoordinate2D
    var relatedSchools = [School]()
    var relatedOrganizations = [Organization]()
    var relatedArtifacts = [Artifact]()
    var relatedEvents = [Event]()

    var hashValue: Int {
        return id.hashValue
    }

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let schools = "schools"
        static let organizations = "organizations"
        static let artifacts = "artifacts"
        static let events = "events"
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

        if let schoolsJSON = json[Keys.schools] as? [JSON] {
            let schools = schoolsJSON.compactMap { School(json: $0) }
            self.relatedSchools = schools
        }
        if let organizationsJSON = json[Keys.organizations] as? [JSON] {
            let organizations = organizationsJSON.compactMap { Organization(json: $0) }
            self.relatedOrganizations = organizations
        }
        if let artifactsJSON = json[Keys.artifacts] as? [JSON] {
            let artifacts = artifactsJSON.compactMap { Artifact(json: $0) }
            self.relatedArtifacts = artifacts
        }
        if let eventsJSON = json[Keys.events] as? [JSON] {
            let events = eventsJSON.compactMap { Event(json: $0) }
            self.relatedEvents = events
        }
    }

    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.id == rhs.id
    }
}
