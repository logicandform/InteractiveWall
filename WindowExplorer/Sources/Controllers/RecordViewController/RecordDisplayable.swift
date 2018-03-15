//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

enum RecordType {
    case event
    case artifact
    case organization
    case school
}


struct RecordGroup {
    let type: RecordType
    let records: [RecordDisplayable]
}


protocol RecordDisplayable {
    var id: Int { get }
    var title: String { get }
    var type: RecordType { get }
    var description: String? { get }
    var date: String? { get }
    var mediaTitles: [String] { get }
    var media: [URL] { get }
    var thumbnails: [URL] { get }
    var textFields: [NSTextField] { get }
    var recordGroups: [RecordGroup] { get }
}

extension RecordDisplayable {
    var relatedRecords: [RecordDisplayable] {
        return recordGroups.reduce([]) { $0 + $1.records }
    }
}


extension Event: RecordDisplayable {

    var textFields: [NSTextField] {
        var labels = [NSTextField]()
        for _ in (1...15) {
            let text = NSAttributedString(string: "Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label.")
            let label = NSTextField(labelWithAttributedString: text)
            label.textColor = .white
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }
        return labels
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents else {
            return []
        }

        let schoolGroup = RecordGroup(type: .school, records: schools)
        let organizationGroup = RecordGroup(type: .organization, records: organizations)
        let artifactGroup = RecordGroup(type: .artifact, records: artifacts)
        let eventGroup = RecordGroup(type: .event, records: events)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}

extension Artifact: RecordDisplayable {

    var date: String? {
        return nil
    }

    var textFields: [NSTextField] {
        var labels = [NSTextField]()
        for _ in (1...15) {
            let text = NSAttributedString(string: "Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label.")
            let label = NSTextField(labelWithAttributedString: text)
            label.textColor = .white
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }
        return labels
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents else {
            return []
        }

        let schoolGroup = RecordGroup(type: .school, records: schools)
        let organizationGroup = RecordGroup(type: .organization, records: organizations)
        let artifactGroup = RecordGroup(type: .artifact, records: artifacts)
        let eventGroup = RecordGroup(type: .event, records: events)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}

extension Organization: RecordDisplayable {

    var date: String? {
        return nil
    }

    var textFields: [NSTextField] {
        var labels = [NSTextField]()
        for _ in (1...15) {
            let text = NSAttributedString(string: "Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label.")
            let label = NSTextField(labelWithAttributedString: text)
            label.textColor = .white
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }
        return labels
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents else {
            return []
        }

        let schoolGroup = RecordGroup(type: .school, records: schools)
        let organizationGroup = RecordGroup(type: .organization, records: organizations)
        let artifactGroup = RecordGroup(type: .artifact, records: artifacts)
        let eventGroup = RecordGroup(type: .event, records: events)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}

extension School: RecordDisplayable {

    var textFields: [NSTextField] {
        var labels = [NSTextField]()
        for _ in (1...15) {
            let text = NSAttributedString(string: "Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label.")
            let label = NSTextField(labelWithAttributedString: text)
            label.textColor = .white
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }
        return labels
    }

    var recordGroups: [RecordGroup] {
        guard let schools = relatedSchools, let organizations = relatedOrganizations, let artifacts = relatedArtifacts, let events = relatedEvents else {
            return []
        }

        let schoolGroup = RecordGroup(type: .school, records: schools)
        let organizationGroup = RecordGroup(type: .organization, records: organizations)
        let artifactGroup = RecordGroup(type: .artifact, records: artifacts)
        let eventGroup = RecordGroup(type: .event, records: events)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}
