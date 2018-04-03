//  Copyright © 2018 JABT. All rights reserved.

import Foundation

final class ResponseHandler {


    // MARK: Places

    static func serializePlaces(from json: Any) throws -> [Place] {
        guard let placesJSON = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return placesJSON.compactMap { Place(json: $0) }
    }


    // MARK: Schools

    static func serializeSchools(from json: Any) throws -> [School] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { School(json: $0) }
    }


    // MARK: Events

    static func serializeEvents(from json: Any) throws -> [Event] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { Event(json: $0) }
    }
}
