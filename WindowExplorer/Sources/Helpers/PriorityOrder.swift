//  Copyright © 2018 JABT. All rights reserved.

import Foundation


class PriorityOrder {

    struct Priority {
        static let date = 1
        static let description = 1
        static let coordinate = 1
        static let comment = 1
        static let media = 2
        static let relatedSchools = 1
        static let relatedOrganizations = 1
        static let relatedArtifacts = 1
        static let relatedEvents = 1
        static let relatedTheme = 1
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
        if let date = record.date, !date.isEmpty {
            priority += Priority.date
        }
        if record.coordinate != nil {
            priority += Priority.coordinate
        }
        if !record.media.isEmpty {
            priority += Priority.media
        }
        if !record.relatedRecords(type: .artifact).isEmpty {
            priority += Priority.relatedSchools
        }
        if !record.relatedRecords(type: .organization).isEmpty {
            priority += Priority.relatedOrganizations
        }
        if !record.relatedRecords(type: .artifact).isEmpty {
            priority += Priority.relatedArtifacts
        }
        if !record.relatedRecords(type: .event).isEmpty {
            priority += Priority.relatedEvents
        }

        return priority
    }
}
