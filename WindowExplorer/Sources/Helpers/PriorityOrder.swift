//  Copyright © 2018 JABT. All rights reserved.

import Foundation


class PriorityOrder {

    struct Priority {
        static let date = 2
        static let media = 3
        static let comment = 2
        static let coordinate = 1
        static let description = 2
        static let relatedRecordType = 1
    }


    // MARK: API

    static func priority(for record: Record) -> Int {
        var priority = 0

        if let description = record.description, !description.isEmpty {
            priority += Priority.description
        }
        if let comments = record.comments, !comments.isEmpty {
            priority += Priority.comment
        }
        if record.dates != nil {
            priority += Priority.date
        }
        if record.coordinate != nil {
            priority += Priority.coordinate
        }
        if !record.media.isEmpty {
            if let artifact = record as? Artifact {
                if artifact.artifactType != .rg10 {
                    priority += Priority.media
                }
            } else {
                priority += Priority.media
            }
        }
        for type in RecordType.allValues {
            if !record.relatedRecords(type: type, prioritized: false).isEmpty {
                priority += Priority.relatedRecordType
            }
        }
        return priority
    }
}
