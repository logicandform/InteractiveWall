//  Copyright © 2018 JABT. All rights reserved.

import Foundation

final class ResponseHandler {


    // MARK: Places

    static func serializePlaces(from json: Any) throws -> [Place] {
        guard let placesJSON = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return placesJSON.flatMap { Place(json: $0) }
    }


    // MARK: Schools

    static func serializeSchools(from json: Any) throws -> [School] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { School(json: $0) }
    }


    // MARK: Events

    static func serializeEvents(from json: Any) throws -> [Event] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { Event(json: $0) }
    }
}
