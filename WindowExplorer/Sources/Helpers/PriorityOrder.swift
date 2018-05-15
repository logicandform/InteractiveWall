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

        if let date = event.date {
            if !date.isEmpty {
                priority += Constants.datePriority
            }
        }
        if let description = event.description {
            if !description.isEmpty {
                priority += Constants.descriptionPriority
            }
        }
        if event.coordinate != nil {
            priority += Constants.coordinatePriority
        }

        if event.media.count > 0 {
            priority += Constants.mediaPriority
        }
        if event.relatedSchools.count > 0 {
            priority += Constants.relatedSchoolsPriority
        }
        if event.relatedOrganizations.count > 0 {
            priority += Constants.relatedOrganizationsPriority
        }
        if event.relatedArtifacts.count > 0 {
            priority += Constants.relatedArtifactsPriority
        }
        if event.relatedEvents.count > 0 {
            priority += Constants.relatedEventsPriority
        }

        return priority
    }

    static func priority(for artifact: Artifact) -> Int {
        var priority = 0

        if let date = artifact.date {
            if !date.isEmpty {
                priority += Constants.datePriority
            }
        }
        if let description = artifact.description {
            if !description.isEmpty {
                priority += Constants.descriptionPriority
            }
        }
        if let comments = artifact.comments {
            if !comments.isEmpty {
                priority += Constants.commentPriority
            }
        }

        if artifact.media.count > 0 {
            priority += Constants.mediaPriority
        }
        if artifact.relatedSchools.count > 0 {
            priority += Constants.relatedSchoolsPriority
        }
        if artifact.relatedOrganizations.count > 0 {
            priority += Constants.relatedOrganizationsPriority
        }
        if artifact.relatedArtifacts.count > 0 {
            priority += Constants.relatedArtifactsPriority
        }
        if artifact.relatedEvents.count > 0 {
            priority += Constants.relatedEventsPriority
        }
        if artifact.relatedThemes.count > 0 {
            priority += Constants.relatedThemePriority
        }

        return priority
    }

    static func priority(for organization: Organization) -> Int {
        var priority = 0

        if let description = organization.description {
            if !description.isEmpty {
                priority += Constants.descriptionPriority
            }
        }

        if organization.media.count > 0 {
            priority += Constants.mediaPriority
        }
        if organization.relatedSchools.count > 0 {
            priority += Constants.relatedSchoolsPriority
        }
        if organization.relatedOrganizations.count > 0 {
            priority += Constants.relatedOrganizationsPriority
        }
        if organization.relatedArtifacts.count > 0 {
            priority += Constants.relatedArtifactsPriority
        }
        if organization.relatedEvents.count > 0 {
            priority += Constants.relatedEventsPriority
        }

        return priority
    }

    static func priority(for school: School) -> Int {
        var priority = 0

        if let date = school.date {
            if !date.isEmpty {
                priority += Constants.datePriority
            }
        }
        if let description = school.description {
            if !description.isEmpty {
                priority += Constants.descriptionPriority
            }
        }
        if school.coordinate != nil {
            priority += Constants.coordinatePriority
        }

        if school.media.count > 0 {
            priority += Constants.mediaPriority
        }
        if school.relatedSchools.count > 0 {
            priority += Constants.relatedSchoolsPriority
        }
        if school.relatedOrganizations.count > 0 {
            priority += Constants.relatedOrganizationsPriority
        }
        if school.relatedArtifacts.count > 0 {
            priority += Constants.relatedArtifactsPriority
        }
        if school.relatedEvents.count > 0 {
            priority += Constants.relatedEventsPriority
        }
        if school.relatedThemes.count > 0 {
            priority += Constants.relatedThemePriority
        }

        return priority
    }

    static func priority(for theme: Theme) -> Int {
        var priority = 0

        if let description = theme.description {
            if !description.isEmpty {
                priority += Constants.descriptionPriority
            }
        }

        if theme.relatedSchools.count > 0 {
            priority += Constants.relatedSchoolsPriority
        }
        if theme.relatedOrganizations.count > 0 {
            priority += Constants.relatedOrganizationsPriority
        }
        if theme.relatedArtifacts.count > 0 {
            priority += Constants.relatedArtifactsPriority
        }
        if theme.relatedEvents.count > 0 {
            priority += Constants.relatedEventsPriority
        }

        return priority
    }
}
