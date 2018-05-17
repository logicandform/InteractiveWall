//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class Event {

    let id: Int
    let title: String
    let type = RecordType.event
    let date: String?
    let description: String?
    var coordinate: CLLocationCoordinate2D? = nil
    var media = [Media]()
    var relatedSchools = [School]()
    var relatedOrganizations = [Organization]()
    var relatedArtifacts = [Artifact]()
    var relatedEvents = [Event]()
    lazy var priority = PriorityOrder.priority(for: self)

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let date = "date"
        static let description = "description"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let mediaTitles = "mediaTitles"
        static let media = "mediaPaths"
        static let thumbnails = "thumbnailPaths"
        static let schools = "schools"
        static let organizations = "organizations"
        static let artifacts = "artifacts"
        static let events = "events"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let title = json[Keys.title] as? String else {
            return nil
        }

        self.id = id
        self.title = title
        self.description = json[Keys.description] as? String

        if let latitude = json[Keys.latitude] as? Double, let longitude = json[Keys.longitude] as? Double {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        self.date = json[Keys.date] as? String

        if let urlStrings = json[Keys.media] as? [String], let thumbnailStrings = json[Keys.thumbnails] as? [String] {
            let urls = urlStrings.compactMap { URL.from(CachingNetwork.baseURL + $0) }
            let thumbnails = thumbnailStrings.compactMap { URL.from(CachingNetwork.baseURL + $0) }
            let titles = json[Keys.mediaTitles] as? [String] ?? []
            for (url, thumbnail) in zip(urls, thumbnails) {
                media.append(Media(url: url, thumbnail: thumbnail, title: titles.at(index: media.count), color: type.color))
            }
        }
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
}
