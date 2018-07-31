//  Copyright © 2018 JABT. All rights reserved.

import Foundation


class NodeConfiguration {

    struct Environment {
        static let debug: Bool = false
    }

    struct Record {
        static let physicsBodyRadius: CGFloat = 15.0
        static let physicsBodyMass: CGFloat = 0.25
        static let agentMaxSpeed: Float = 200.0
        static let agentMaxAcceleration: Float = 100.0
        static let agentRadius = Float(physicsBodyRadius)
    }

    /// Returns all related records for a given identifier depending on the configuration environment
    static func relatedRecords(for identifier: DataManager.RecordIdentifier) -> [RecordDisplayable]? {
        if NodeConfiguration.Environment.debug {
            if let relatedRecords = TestingEnvironment.instance.relatedRecordsForIdentifier[identifier] {
                return Array(relatedRecords)
            }
        } else {
            if let relatedRecords = DataManager.instance.relatedRecordsForIdentifier[identifier] {
                return relatedRecords
            }
        }

        return nil
    }
}
