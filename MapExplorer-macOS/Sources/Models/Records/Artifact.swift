//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class Artifact: CustomStringConvertible {

    let id: Int
    let name: String
    let type: String
    let relatedSchoolIDs: [Int]
    let relatedEntityIDs: [Int]

    var description: String {
        return "( [Artifact] ID: \(id), Name: \(name) )"
    }

    private struct Keys {
        static let id = "object_id"
        static let name = "name"
        static let type = "type"
        static let schoolIDs = "relatedSchoolIds"
        static let entityIDs = "relatedEntityIds"
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
    }
}
