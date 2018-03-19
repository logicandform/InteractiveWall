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
        static let baseURL = "http://192.168.1.93:3000"
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
        let url = Endpoints.placesURL

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializePlaces(from: json)
        }
    }

    static func getPlace(by id: String) -> Promise<Place> {
        let url = Endpoints.placesURL + "/" + id

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializePlace(from: json)
        }
    }


    // MARK: Schools

    static func getSchools() throws -> Promise<[School]> {
        let url = Endpoints.schoolsURL

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeSchools(from: json)
        }
    }

    static func getSchool(by id: String) -> Promise<School> {
        let url = Endpoints.schoolsURL + "/" + id

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeSchool(from: json)
        }
    }
}
