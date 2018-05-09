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
        static let baseURL = "http://10.58.73.164:3000"
        static let places = baseURL + "/places"
        static let schools = baseURL + "/schools/all/%d"
        static let events = baseURL + "/events"
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

    static func getPlaces() throws -> Promise<[Place]> {
        let url = Endpoints.places

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializePlaces(from: json)
        }
    }


    // MARK: Schools

    static func getSchools(page: Int = 0, load: [School] = []) throws -> Promise<[Record]> {
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

    static func getEvents() throws -> Promise<[Record]> {
        let url = Endpoints.events

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeEvents(from: json)
        }
    }
}
