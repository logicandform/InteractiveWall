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

    static func serializePlace(from json: Any) throws -> Place {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let place = Place(json: json) else {
            throw NetworkError.serializationError
        }

        return place
    }


    // MARK: Schools

    static func serializeSchools(from json: Any) throws -> [School] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { School(json: $0) }
    }

    static func serializeSchool(from json: Any) throws -> School {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let school = School(json: json) else {
            throw NetworkError.serializationError
        }

        return school
    }
}
