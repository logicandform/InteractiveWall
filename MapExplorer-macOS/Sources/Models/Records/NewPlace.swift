//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class NewPlace: CustomStringConvertible {

    let id: Int
    let name: String
    let type: String
    let relatedSchoolIDs: [Int]
    let relatedEntityIDs: [Int]
    let relatedOccuranceIDs: [Int]
    let relatedObjectIDs: [Int]

    var description: String {
        return "( [NewPlace] ID: \(id), Name: \(name), Type: \(type) )"
    }

    private struct Keys {
        static let id = "place_id"
        static let name = "name"
        static let type = "type"
        static let schoolIDs = "relatedSchoolIds"
        static let entityIDs = "relatedEntityIds"
        static let occuranceIDs = "relatedOccurrenceIds"
        static let objectIDs = "relatedObjectIds"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let id = json[Keys.id] as? Int, let name = json[Keys.name] as? String, let type = json[Keys.type] as? String else {
            return nil
        }

        self.id = id
        self.name = name
        self.type = type
        self.relatedSchoolIDs = json[Keys.schoolIDs] as? [Int] ?? []
        self.relatedEntityIDs = json[Keys.entityIDs] as? [Int] ?? []
        self.relatedOccuranceIDs = json[Keys.occuranceIDs] as? [Int] ?? []
        self.relatedObjectIDs = json[Keys.objectIDs] as? [Int] ?? []
    }
}
