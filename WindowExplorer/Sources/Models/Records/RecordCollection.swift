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


final class RecordCollection: Hashable {

    let id: Int
    let type = RecordType.collection
    let collectionType: CollectionType?
    let title: String
    let shortTitle: String
    let date: String?
    let description: String?
    var coordinate: CLLocationCoordinate2D?
    var media = [Media]()
    var relatedSchools = [School]()
    var relatedOrganizations = [Organization]()
    var relatedArtifacts = [Artifact]()
    var relatedEvents = [Event]()
    var relatedThemes = [Theme]()
    lazy var priority = PriorityOrder.priority(for: self)

    var hashValue: Int {
        return id.hashValue
    }

    private struct Keys {
        static let id = "id"
        static let title = "title"
        static let shortTitle = "shortTitle"
        static let presentation = "presentationType"
        static let date = "date"
        static let description = "description"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let mediaTitles = "mediaTitles"
        static let media = "mediaPaths"
        static let localMedia = "fullMediaPaths"
        static let thumbnails = "thumbnailPaths"
        static let localThumbnails = "fullThumbnailPaths"
        static let schools = "schools"
        static let organizations = "organizations"
        static let artifacts = "artifacts"
        static let events = "events"
        static let themes = "themes"
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
        self.date = json[Keys.date] as? String
        self.description = json[Keys.description] as? String

        if let latitude = json[Keys.latitude] as? Double, let longitude = json[Keys.longitude] as? Double {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        if let urlStrings = json[Keys.media] as? [String], let localURLStrings = json[Keys.localMedia] as? [String], let thumbnailStrings = json[Keys.thumbnails] as? [String], let localThumbnailStrings = json[Keys.localThumbnails] as? [String] {
            let urls = urlStrings.compactMap { URL.from(Configuration.serverURL + $0) }
            let localURLs = localURLStrings.map { URL(fileURLWithPath: $0) }
            let thumbnails = thumbnailStrings.compactMap { URL.from(Configuration.serverURL + $0) }
            let localThumbnails = localThumbnailStrings.map { URL(fileURLWithPath: $0) }
            let titles = json[Keys.mediaTitles] as? [String] ?? []
            for (url, localURL, thumbnail, localThumbnail) in zip(seq1: urls, seq2: localURLs, seq3: thumbnails, seq4: localThumbnails) {
                media.append(Media(url: url, localURL: localURL, thumbnail: thumbnail, localThumbnail: localThumbnail, title: titles.at(index: media.count), color: type.color))
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
        if let themesJSON = json[Keys.themes] as? [JSON] {
            let themes = themesJSON.compactMap { Theme(json: $0) }
            self.relatedThemes = themes
        }
    }

    static func == (lhs: RecordCollection, rhs: RecordCollection) -> Bool {
        return lhs.id == rhs.id
    }
}
