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

    static func priority(for event: Event) -> Int {
        var priority = 0

        if let date = event.date, !date.isEmpty {
            priority += Priority.date
        }
        if let description = event.description, !description.isEmpty {
            priority += Priority.description
        }
        if event.coordinate != nil {
            priority += Priority.coordinate
        }
        if !event.media.isEmpty {
            priority += Priority.media
        }
        if !event.relatedSchools.isEmpty {
            priority += Priority.relatedSchools
        }
        if !event.relatedOrganizations.isEmpty {
            priority += Priority.relatedOrganizations
        }
        if !event.relatedArtifacts.isEmpty {
            priority += Priority.relatedArtifacts
        }
        if !event.relatedEvents.isEmpty {
            priority += Priority.relatedEvents
        }

        return priority
    }

    static func priority(for artifact: Artifact) -> Int {
        var priority = 0

        if let date = artifact.date, !date.isEmpty {
            priority += Priority.date
        }
        if let description = artifact.description, !description.isEmpty {
            priority += Priority.description
        }
        if let comments = artifact.comments, !comments.isEmpty {
            priority += Priority.comment
        }
        if !artifact.media.isEmpty {
            priority += Priority.media
        }
        if !artifact.relatedSchools.isEmpty {
            priority += Priority.relatedSchools
        }
        if !artifact.relatedOrganizations.isEmpty {
            priority += Priority.relatedOrganizations
        }
        if !artifact.relatedArtifacts.isEmpty {
            priority += Priority.relatedArtifacts
        }
        if !artifact.relatedEvents.isEmpty {
            priority += Priority.relatedEvents
        }
        if !artifact.relatedThemes.isEmpty {
            priority += Priority.relatedTheme
        }

        return priority
    }

    static func priority(for organization: Organization) -> Int {
        var priority = 0

        if let description = organization.description, !description.isEmpty {
            priority += Priority.description
        }
        if !organization.media.isEmpty {
            priority += Priority.media
        }
        if !organization.relatedSchools.isEmpty {
            priority += Priority.relatedSchools
        }
        if !organization.relatedOrganizations.isEmpty {
            priority += Priority.relatedOrganizations
        }
        if !organization.relatedArtifacts.isEmpty {
            priority += Priority.relatedArtifacts
        }
        if !organization.relatedEvents.isEmpty {
            priority += Priority.relatedEvents
        }

        return priority
    }

    static func priority(for school: School) -> Int {
        var priority = 0

        if let date = school.date, !date.isEmpty {
            priority += Priority.date
        }
        if let description = school.description, !description.isEmpty {
            priority += Priority.description
        }
        if school.coordinate != nil {
            priority += Priority.coordinate
        }
        if !school.media.isEmpty {
            priority += Priority.media
        }
        if !school.relatedSchools.isEmpty {
            priority += Priority.relatedSchools
        }
        if !school.relatedOrganizations.isEmpty {
            priority += Priority.relatedOrganizations
        }
        if !school.relatedArtifacts.isEmpty {
            priority += Priority.relatedArtifacts
        }
        if !school.relatedEvents.isEmpty {
            priority += Priority.relatedEvents
        }
        if !school.relatedThemes.isEmpty {
            priority += Priority.relatedTheme
        }

        return priority
    }

    static func priority(for theme: Theme) -> Int {
        var priority = 0

        if let description = theme.description, !description.isEmpty {
            priority += Priority.description
        }
        if !theme.relatedSchools.isEmpty {
            priority += Priority.relatedSchools
        }
        if !theme.relatedOrganizations.isEmpty {
            priority += Priority.relatedOrganizations
        }
        if !theme.relatedArtifacts.isEmpty {
            priority += Priority.relatedArtifacts
        }
        if !theme.relatedEvents.isEmpty {
            priority += Priority.relatedEvents
        }

        return priority
    }
}
