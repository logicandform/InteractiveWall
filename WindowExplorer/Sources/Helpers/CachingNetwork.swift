//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Alamofire
import AlamofireImage
import PromiseKit
import MapKit


enum NetworkError: Error {
    case badRequest
    case unauthorized
    case notFound
    case serverError
    case badResponse
    case serializationError
}


final class CachingNetwork {

    private struct Endpoints {
        static let countForGroup = Configuration.serverURL + "/%@/count/group/%@"
        static let refresh = Configuration.serverURL + "/refresh"
        static let refreshStatus = Configuration.serverURL + "/refresh/status"
        static let places = Configuration.serverURL + "/places/all/%d"
        static let placeByID = Configuration.serverURL + "/places/find/%d"
        static let placesInGroup = Configuration.serverURL + "/places/group/%@/%d"
        static let organizations = Configuration.serverURL + "/organizations/all/%d"
        static let organizationByID = Configuration.serverURL + "/organizations/find/%d"
        static let organizationsInGroup = Configuration.serverURL + "/organizations/group/%@/%d"
        static let events = Configuration.serverURL + "/events/all/%d"
        static let eventByID = Configuration.serverURL + "/events/find/%d"
        static let eventsInGroup = Configuration.serverURL + "/events/group/%@/%d"
        static let artifacts = Configuration.serverURL + "/artifacts/all/%d"
        static let artifactByID = Configuration.serverURL + "/artifacts/find/%d"
        static let artifactsInGroup = Configuration.serverURL + "/artifacts/group/%@/%d"
        static let schools = Configuration.serverURL + "/schools/all/%d"
        static let schoolByID = Configuration.serverURL + "/schools/find/%d"
        static let schoolsInGroup = Configuration.serverURL + "/schools/group/%@/%d"
        static let themes = Configuration.serverURL + "/themes/all/%d"
        static let themeByID = Configuration.serverURL + "/themes/find/%d"
        static let themesInGroup = Configuration.serverURL + "/themes/group/%@/%d"
        static let collections = Configuration.serverURL + "/collections/all/%d"
        static let collectionsByID = Configuration.serverURL + "/collections/find/%d"
        static let individuals = Configuration.serverURL + "/individuals/all/%d"
        static let individualsByID = Configuration.serverURL + "/individuals/find/%d"
    }

    private struct Constants {
        static let batchSize = 20
    }


    // MARK: Generic

    static func refresh() throws -> Promise<DatabaseStatus> {
        let url = Endpoints.refresh

        return Alamofire.request(url).responseJSON().then { json in
            return try ResponseHandler.serializeDatabaseStatus(from: json)
        }
    }

    static func status() throws -> Promise<DatabaseStatus> {
        let url = Endpoints.refreshStatus

        return Alamofire.request(url).responseJSON().then { json in
            return try ResponseHandler.serializeDatabaseStatus(from: json)
        }
    }

    static func getCount(of type: RecordType, in group: LetterGroup) throws -> Promise<Int> {
        let url = String(format: Endpoints.countForGroup, type.title.lowercased(), group.rawValue)

        return Alamofire.request(url).responseJSON().then { json in
            return try ResponseHandler.serializeCount(from: json)
        }
    }

    /// Loads image for media using local or remote url depending on configuration settings
    static func getImage(for media: Media, completion: @escaping (NSImage?) -> Void) {
        guard media.type == .image else {
            completion(nil)
            return
        }

        if Configuration.localMediaURLs {
            let image = NSImage(contentsOf: media.localURL)
            completion(image)
        } else {
            Alamofire.request(media.url).responseImage { response in
                completion(response.value)
            }
        }
    }

    /// Loads thumbnail for media using local or remote url depending on configuration settings
    static func getThumbnail(for media: Media, completion: @escaping (NSImage?) -> Void) {
        if Configuration.localMediaURLs {
            if let localURL = media.localThumbnail {
                let image = NSImage(contentsOf: localURL)
                completion(image)
            } else {
                completion(nil)
            }
        } else {
            if let url = media.thumbnail {
                Alamofire.request(url).responseImage { response in
                    completion(response.value)
                }
            } else {
                completion(nil)
            }
        }
    }


    // MARK: Organizations

    static func getOrganizations(page: Int = 0, load: [Organization] = []) throws -> Promise<[Organization]> {
        let url = String(format: Endpoints.organizations, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let organizations = try? ResponseHandler.serializeOrganizations(from: json), !organizations.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + organizations
            return try getOrganizations(page: next, load: result)
        }
    }

    static func getOrganization(by id: Int) -> Promise<Organization> {
        let url = String(format: Endpoints.organizationByID, id)

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeOrganization(from: json)
        }
    }

    static func getOrganizations(in group: LetterGroup, page: Int = 0, load: [Organization] = []) throws -> Promise<[Organization]> {
        let url = String(format: Endpoints.organizationsInGroup, group.rawValue, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let organizations = try? ResponseHandler.serializeOrganizations(from: json), !organizations.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + organizations
            return try getOrganizations(in: group, page: next, load: result)
        }
    }


    // MARK: Events

    static func getEvents(page: Int = 0, load: [Event] = []) throws -> Promise<[Event]> {
        let url = String(format: Endpoints.events, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let events = try? ResponseHandler.serializeEvents(from: json), !events.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + events
            return try getEvents(page: next, load: result)
        }
    }

    static func getEvent(by id: Int) -> Promise<Event> {
        let url = String(format: Endpoints.eventByID, id)

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeEvent(from: json)
        }
    }

    static func getEvents(in group: LetterGroup, page: Int = 0, load: [Event] = []) throws -> Promise<[Event]> {
        let url = String(format: Endpoints.eventsInGroup, group.rawValue, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let events = try? ResponseHandler.serializeEvents(from: json), !events.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + events
            return try getEvents(in: group, page: next, load: result)
        }
    }


    // MARK: Artifacts

    static func getArtifacts(page: Int = 0, load: [Artifact] = []) throws -> Promise<[Artifact]> {
        let url = String(format: Endpoints.artifacts, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let artifacts = try? ResponseHandler.serializeArtifacts(from: json), !artifacts.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + artifacts
            return try getArtifacts(page: next, load: result)
        }
    }

    static func getArtifact(by id: Int) -> Promise<Artifact> {
        let url = String(format: Endpoints.artifactByID, id)

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeArtifact(from: json)
        }
    }

    static func getArtifacts(in group: LetterGroup, page: Int = 0, load: [Artifact] = []) throws -> Promise<[Artifact]> {
        let url = String(format: Endpoints.artifactsInGroup, group.rawValue, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let artifacts = try? ResponseHandler.serializeArtifacts(from: json), !artifacts.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + artifacts
            return try getArtifacts(in: group, page: next, load: result)
        }
    }


    // MARK: Schools

    static func getSchools(page: Int = 0, load: [School] = []) throws -> Promise<[School]> {
        let url = String(format: Endpoints.schools, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let schools = try? ResponseHandler.serializeSchools(from: json), !schools.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + schools
            return try getSchools(page: next, load: result)
        }
    }

    static func getSchool(by id: Int) -> Promise<School> {
        let url = String(format: Endpoints.schoolByID, id)

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeSchool(from: json)
        }
    }

    static func getSchools(in group: LetterGroup, page: Int = 0, load: [School] = []) throws -> Promise<[School]> {
        let url = String(format: Endpoints.schoolsInGroup, group.rawValue, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let schools = try? ResponseHandler.serializeSchools(from: json), !schools.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + schools
            return try getSchools(in: group, page: next, load: result)
        }
    }


    // MARK: Themes

    static func getThemes(page: Int = 0, load: [Theme] = []) throws -> Promise<[Theme]> {
        let url = String(format: Endpoints.themes, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let themes = try? ResponseHandler.serializeThemes(from: json), !themes.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + themes
            return try getThemes(page: next, load: result)
        }
    }

    static func getTheme(by id: Int) -> Promise<Theme> {
        let url = String(format: Endpoints.themeByID, id)

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeTheme(from: json)
        }
    }

    static func getThemes(in group: LetterGroup, page: Int = 0, load: [Theme] = []) throws -> Promise<[Theme]> {
        let url = String(format: Endpoints.themesInGroup, group.rawValue, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let themes = try? ResponseHandler.serializeThemes(from: json), !themes.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + themes
            return try getThemes(in: group, page: next, load: result)
        }
    }


    // MARK: Collections

    static func getCollections(page: Int = 0, load: [RecordCollection] = []) throws -> Promise<[RecordCollection]> {
        let url = String(format: Endpoints.collections, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let collections = try? ResponseHandler.serializeCollections(from: json), !collections.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + collections
            return try getCollections(page: next, load: result)
        }
    }

    static func getCollection(by id: Int) -> Promise<RecordCollection> {
        let url = String(format: Endpoints.collectionsByID, id)

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeCollection(from: json)
        }
    }


    // MARK: Individuals

    static func getIndividuals(page: Int = 0, load: [Individual] = []) throws -> Promise<[Individual]> {
        let url = String(format: Endpoints.individuals, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let individuals = try? ResponseHandler.serializeIndividuals(from: json), !individuals.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + individuals
            return try getIndividuals(page: next, load: result)
        }
    }

    static func getIndividual(by id: Int) -> Promise<Individual> {
        let url = String(format: Endpoints.individualsByID, id)

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeIndividual(from: json)
        }
    }
}
