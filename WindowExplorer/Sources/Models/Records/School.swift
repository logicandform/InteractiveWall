//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class School {

    let id: Int
    let title: String
    let date: String?
    let description: String?
    let coordinate: CLLocationCoordinate2D?
    let mediaTitles: [String]
    var media = [URL]()
    var thumbnails = [URL]()
    var relatedSchools: [School]?
    var relatedOrganizations: [Organization]?
    var relatedArtifacts: [Artifact]?
    var relatedEvents: [Event]?
    var relatedThemes: [Theme]?

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let date = "date"
        static let description = "description"
        static let coordinate = "coordinate"
        static let mediaTitles = "mediaTitles"
        static let media = "mediaPaths"
        static let thumbnails = "thumbnailPaths"
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
        self.mediaTitles = json[Keys.mediaTitles] as? [String] ?? []

        if let mediaStrings = json[Keys.media] as? [String] {
            self.media = mediaStrings.flatMap { URL.from(CachingNetwork.baseURL + $0) }
        }
        if let thumbnailStrings = json[Keys.thumbnails] as? [String] {
            self.thumbnails = thumbnailStrings.flatMap { URL.from(CachingNetwork.baseURL + $0) }
        }
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
            self.relatedThemes = themes
        }
    }
}
