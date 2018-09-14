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
        static let places = Configuration.serverURL + "/places/all/%d"
        static let schools = Configuration.serverURL + "/schools/all/%d"
        static let events = Configuration.serverURL + "/events/all/%d"
        static let collections = Configuration.serverURL + "/collections/all/%d"
    }

    private struct Constants {
        static let batchSize = 20
    }

    private static let credentials: [String: String] = {
        let credentialData = "administrator:changeme".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }()


    // MARK: Places

    static func getPlaces(page: Int = 0, load: [Place] = []) throws -> Promise<[Place]> {
        let url = String(format: Endpoints.places, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let places = try? ResponseHandler.serializePlaces(from: json), !places.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + places
            return try getPlaces(page: next, load: result)
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

    static func getCollections(type: CollectionType, page: Int = 0, load: [RecordCollection] = []) throws -> Promise<[RecordCollection]> {
        let url = String(format: Endpoints.collections, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let collections = try? ResponseHandler.serializeCollections(from: json), !collections.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let filtered = collections.filter { $0.collectionType == type }
            let result = load + filtered
            return try getCollections(page: next, load: result)
        }
    }
}
