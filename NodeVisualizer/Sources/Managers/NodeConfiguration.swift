//  Copyright © 2018 JABT. All rights reserved.

import Foundation


class NodeConfiguration {

    struct Record {
        static let physicsBodyRadius: CGFloat = 15
        static let physicsBodyMass: CGFloat = 0.25
        static let agentMaxSpeed: Float = 200
        static let agentMaxAcceleration: Float = 100
        static let agentRadius = Float(physicsBodyRadius)
    }

    /// Returns all related records for a given identifier depending on the configuration environment
    static func relatedRecords(for proxy: RecordProxy) -> [RecordDisplayable]? {
        if Configuration.env == .testing, let relatedRecords = TestingEnvironment.instance.relatedRecordsForIdentifier[proxy] {
            return Array(relatedRecords)
        }

        return DataManager.instance.relatedRecordsForProxy[proxy]
    }
}
