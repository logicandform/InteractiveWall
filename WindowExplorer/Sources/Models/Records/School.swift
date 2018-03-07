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
    let mediaPath: String?
    var relatedSchools: [School]?
    var relatedOrganizations: [Organization]?
    var relatedArtifacts: [Artifact]?
    var relatedEvents: [Event]?
    var themes: [Theme]?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let date = "date"
        static let description = "description"
        static let coordinate = "coordinate"
        static let mediaURL = "mediaURL"
        static let thumbnailURL = "mediaThumbnailURL"
        static let mediaTitle = "mediaTitle"
        static let mediaPath = "mediaPath"
        static let schools = "schools"
        static let organizations = "organizations"
        static let artifacts = "artifacts"
        static let events = "events"
        static let themes = "themes"
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
        self.coordinate = CLLocationCoordinate2D(string: json[Keys.coordinate] as? String)
        self.mediaTitle = json[Keys.mediaTitle] as? String
        self.mediaURL = URL.from(json[Keys.mediaURL] as? String)
        self.thumbnailURL = URL.from(json[Keys.thumbnailURL] as? String)
        self.mediaPath = json[Keys.mediaPath] as? String

        if let schoolsJSON = json[Keys.schools] as? [JSON] {
            let schools = schoolsJSON.flatMap { School(json: $0) }
            self.relatedSchools = schools
        }
        if let organizationsJSON = json[Keys.organizations] as? [JSON] {
            let organizations = organizationsJSON.flatMap { Organization(json: $0) }
            self.relatedOrganizations = organizations
        }
        if let artifactsJSON = json[Keys.artifacts] as? [JSON] {
            let artifacts = artifactsJSON.flatMap { Artifact(json: $0) }
            self.relatedArtifacts = artifacts
        }
        if let eventsJSON = json[Keys.events] as? [JSON] {
            let events = eventsJSON.flatMap { Event(json: $0) }
            self.relatedEvents = events
        }
        if let themesJSON = json[Keys.themes] as? [JSON] {
            let themes = themesJSON.flatMap { Theme(json: $0) }
            self.themes = themes
        }
    }
}
