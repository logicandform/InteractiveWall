//  Copyright © 2018 JABT. All rights reserved.

import Foundation


class PriorityOrder {

    struct Constants {
        static let datePriority = 1
        static let descriptionPriority = 1
        static let coordinatePriority = 1
        static let commentPriority = 1
        static let mediaPriority = 2
        static let relatedSchoolsPriority = 1
        static let relatedOrganizationsPriority = 1
        static let relatedArtifactsPriority = 1
        static let relatedEventsPriority = 1
        static let relatedThemePriority = 1
    }


    // MARK: API

    static func priority(for event: Event) -> Int {
        var priority = 0

        if let date = event.date, !date.isEmpty {
            priority += Constants.datePriority
        }
        if let description = event.description, !description.isEmpty {
            priority += Constants.descriptionPriority
        }
        if event.coordinate != nil {
            priority += Constants.coordinatePriority
        }

        if !event.media.isEmpty {
            priority += Constants.mediaPriority
        }
        if !event.relatedSchools.isEmpty {
            priority += Constants.relatedSchoolsPriority
        }
        if !event.relatedOrganizations.isEmpty {
            priority += Constants.relatedOrganizationsPriority
        }
        if !event.relatedArtifacts.isEmpty {
            priority += Constants.relatedArtifactsPriority
        }
        if !event.relatedEvents.isEmpty {
            priority += Constants.relatedEventsPriority
        }

        return priority
    }

    static func priority(for artifact: Artifact) -> Int {
        var priority = 0

        if let date = artifact.date, !date.isEmpty {
            priority += Constants.datePriority
        }
        if let description = artifact.description, !description.isEmpty {
            priority += Constants.descriptionPriority
        }
        if let comments = artifact.comments, !comments.isEmpty {
            priority += Constants.commentPriority
        }

        if !artifact.media.isEmpty {
            priority += Constants.mediaPriority
        }
        if !artifact.relatedSchools.isEmpty {
            priority += Constants.relatedSchoolsPriority
        }
        if !artifact.relatedOrganizations.isEmpty {
            priority += Constants.relatedOrganizationsPriority
        }
        if !artifact.relatedArtifacts.isEmpty {
            priority += Constants.relatedArtifactsPriority
        }
        if !artifact.relatedEvents.isEmpty {
            priority += Constants.relatedEventsPriority
        }
        if !artifact.relatedThemes.isEmpty {
            priority += Constants.relatedThemePriority
        }

        return priority
    }

    static func priority(for organization: Organization) -> Int {
        var priority = 0

        if let description = organization.description, !description.isEmpty {
            priority += Constants.descriptionPriority
        }

        if !organization.media.isEmpty {
            priority += Constants.mediaPriority
        }
        if !organization.relatedSchools.isEmpty {
            priority += Constants.relatedSchoolsPriority
        }
        if !organization.relatedOrganizations.isEmpty {
            priority += Constants.relatedOrganizationsPriority
        }
        if !organization.relatedArtifacts.isEmpty {
            priority += Constants.relatedArtifactsPriority
        }
        if !organization.relatedEvents.isEmpty {
            priority += Constants.relatedEventsPriority
        }

        return priority
    }

    static func priority(for school: School) -> Int {
        var priority = 0

        if let date = school.date, !date.isEmpty {
            priority += Constants.datePriority
        }
        if let description = school.description, !description.isEmpty {
            priority += Constants.descriptionPriority
        }
        if school.coordinate != nil {
            priority += Constants.coordinatePriority
        }

        if !school.media.isEmpty {
            priority += Constants.mediaPriority
        }
        if !school.relatedSchools.isEmpty {
            priority += Constants.relatedSchoolsPriority
        }
        if !school.relatedOrganizations.isEmpty {
            priority += Constants.relatedOrganizationsPriority
        }
        if !school.relatedArtifacts.isEmpty {
            priority += Constants.relatedArtifactsPriority
        }
        if !school.relatedEvents.isEmpty {
            priority += Constants.relatedEventsPriority
        }
        if !school.relatedThemes.isEmpty {
            priority += Constants.relatedThemePriority
        }

        return priority
    }

    static func priority(for theme: Theme) -> Int {
        var priority = 0

        if let description = theme.description, !description.isEmpty {
            priority += Constants.descriptionPriority
        }

        if !theme.relatedSchools.isEmpty {
            priority += Constants.relatedSchoolsPriority
        }
        if !theme.relatedOrganizations.isEmpty {
            priority += Constants.relatedOrganizationsPriority
        }
        if !theme.relatedArtifacts.isEmpty {
            priority += Constants.relatedArtifactsPriority
        }
        if !theme.relatedEvents.isEmpty {
            priority += Constants.relatedEventsPriority
        }

        return priority
    }
}
