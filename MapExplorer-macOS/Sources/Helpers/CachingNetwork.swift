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
}

final class CachingNetwork {

    private struct Endpoints {
        static let baseURL = "http://34.216.252.157:3000"
        static let eventsURL = baseURL + "/events"
        static let placesURL = baseURL + "/places"
    }

    private static let credentials: [String: String] = {
        let credentialData = "administrator:changeme".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }()


    // MARK: API

    static func getPlaces() throws -> Promise<[Place]> {
        return Alamofire.request(Endpoints.placesURL, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializePlaces(from: json)
        }
    }
}
