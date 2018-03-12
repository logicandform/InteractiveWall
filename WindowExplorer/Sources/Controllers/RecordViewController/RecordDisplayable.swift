//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

enum RecordType {
    case events
    case artifacts
    case organizations
    case schools
    case themes
}


struct RecordGroup {
    let type: RecordType
    let records: [RecordDisplayable]
}


protocol RecordDisplayable {
    var title: String { get }
    var description: String? { get }
    var date: String? { get }
    var thumbnail: URL? { get }
    var media: [URL] { get }
    var textFields: [NSTextField] { get }
    var recordGroups: [RecordGroup] { get }
}


extension Event: RecordDisplayable {

    var textFields: [NSTextField] {
        return []
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents else {
            return []
        }

        let schoolGroup = RecordGroup(type: .schools, records: schools)
        let organizationGroup = RecordGroup(type: .organizations, records: organizations)
        let artifactGroup = RecordGroup(type: .artifacts, records: artifacts)
        let eventGroup = RecordGroup(type: .events, records: events)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}

extension Artifact: RecordDisplayable {

    var date: String? {
        return nil
    }

    var textFields: [NSTextField] {
        return []
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents else {
            return []
        }

        let schoolGroup = RecordGroup(type: .schools, records: schools)
        let organizationGroup = RecordGroup(type: .organizations, records: organizations)
        let artifactGroup = RecordGroup(type: .artifacts, records: artifacts)
        let eventGroup = RecordGroup(type: .events, records: events)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}

extension Organization: RecordDisplayable {

    var date: String? {
        return nil
    }

    var textFields: [NSTextField] {
        return []
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents else {
            return []
        }

        let schoolGroup = RecordGroup(type: .schools, records: schools)
        let organizationGroup = RecordGroup(type: .organizations, records: organizations)
        let artifactGroup = RecordGroup(type: .artifacts, records: artifacts)
        let eventGroup = RecordGroup(type: .events, records: events)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}

extension School: RecordDisplayable {

    var textFields: [NSTextField] {
        return []
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents, let themes = relatedThemes else {
            return []
        }

        let schoolGroup = RecordGroup(type: .schools, records: schools)
        let organizationGroup = RecordGroup(type: .organizations, records: organizations)
        let artifactGroup = RecordGroup(type: .artifacts, records: artifacts)
        let eventGroup = RecordGroup(type: .events, records: events)
        let themeGroup = RecordGroup(type: .themes, records: themes)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup, themeGroup]
    }
}

extension Theme: RecordDisplayable {

    var date: String? {
        return nil
    }

    var textFields: [NSTextField] {
        return []
    }

    var recordGroups: [RecordGroup] {
        return []
    }
}
