//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Alamofire
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
        static let organizations = Configuration.serverURL + "/organizations/all/%d"
        static let events = Configuration.serverURL + "/events/all/%d"
        static let artifacts = Configuration.serverURL + "/artifacts/all/%d"
        static let schools = Configuration.serverURL + "/schools/all/%d"
        static let themes = Configuration.serverURL + "/themes/all/%d"
        static let collections = Configuration.serverURL + "/collections/all/%d"
        static let individuals = Configuration.serverURL + "/individuals/all/%d"
    }

    private struct Constants {
        static let batchSize = 20
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
}
