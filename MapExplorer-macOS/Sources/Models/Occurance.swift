//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class Occurance: CustomStringConvertible {

    let id: Int
    let name: String
    let type: String
    let relatedSchoolIDs: [Int]
    let relatedEntityIDs: [Int]
    let relatedObjectIDs: [Int]

    var description: String {
        return "( [Occurance] ID: \(id), Name: \(name), Type: \(type) )"
    }

    private struct Keys {
        static let id = "occurrence_id"
        static let name = "name"
        static let type = "type"
        static let schoolIDs = "relatedSchoolIds"
        static let entityIDs = "relatedEntityIds"
        static let objectIDs = "relatedObjectIds"
    }


    // MARK: Init

    init?(fromJSON json: [String: Any]) {
        guard let id = json[Keys.id] as? Int, let name = json[Keys.name] as? String, let type = json[Keys.type] as? String else {
            return nil
        }

        self.id = id
        self.name = name
        self.type = type
        self.relatedSchoolIDs = json[Keys.schoolIDs] as? [Int] ?? []
        self.relatedEntityIDs = json[Keys.entityIDs] as? [Int] ?? []
        self.relatedObjectIDs = json[Keys.objectIDs] as? [Int] ?? []
    }
}
