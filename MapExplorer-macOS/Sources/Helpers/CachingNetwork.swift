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
        static let baseURL = "http://localhost:3000"
        static let placesURL = baseURL + "/places"
        static let schoolsURL = baseURL + "/schools"
    }

    private static let credentials: [String: String] = {
        let credentialData = "administrator:changeme".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }()


    // MARK: Places

    static func getPlaces() throws -> Promise<[Place]> {
        let url = Endpoints.places

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializePlaces(from: json)
        }
    }


    // MARK: Schools

    static func getSchools() throws -> Promise<[School]> {
        let url = Endpoints.schools

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeSchools(from: json)
        }
    }


    // MARK: Events

    static func getEvents() throws -> Promise<[Event]> {
        let url = Endpoints.events

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeEvents(from: json)
        }
    }
}
