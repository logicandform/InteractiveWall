//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class Entity: CustomStringConvertible {

    let id: Int
    let name: String
    let type: EntityType
    let relatedObjectsIDs: [Int]

    var description: String {
        return "( [Entity] ID: \(id), Name: \(name), Type: \(type.description) )"
    }

    private struct Keys {
        static let id = "entity_id"
        static let name = "name"
        static let type = "type"
        static let objectIDs = "relatedObjectIds"
    }


    // MARK: Init

    init?(fromJSON json: [String: Any]) {
        guard let id = json[Keys.id] as? Int, let name = json[Keys.name] as? String, let type = EntityType.from(json[Keys.type] as? String) else {
            return nil
        }

        self.id = id
        self.name = name
        self.type = type
        self.relatedObjectsIDs = json[Keys.objectIDs] as? [Int] ?? []
    }

}
