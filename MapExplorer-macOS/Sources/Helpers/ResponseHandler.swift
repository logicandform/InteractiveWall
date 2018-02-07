//  Copyright © 2018 JABT. All rights reserved.

import Foundation

final class ResponseHandler {

    static func serializePlaces(from json: Any) throws -> [Place] {
        guard let json = json as? [[String: Any]] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { Place(fromJSON: $0) }
    }
}
