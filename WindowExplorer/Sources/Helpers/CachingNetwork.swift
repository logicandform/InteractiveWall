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
        static let baseURL = "localhost:3000"
        static let eventsURL = baseURL + "/events"
        static let placesURL = baseURL + "/places"
        static let artifactsURL = baseURL + "/artifacts"
        static let entitiesURL = baseURL + "/entities"
    }

    private static let credentials: [String: String] = {
        let credentialData = "tim:ph@wRaBa63Dr".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }()


    // MARK: API

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
}
