//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


private struct Constants {
    static let titleFontSize: CGFloat = 24.0
    static let dateFontSize: CGFloat = 17.0
}


protocol RecordDisplayable {
    var id: Int { get }
    var title: String { get }
    var type: RecordType { get }
    var description: String? { get }
    var date: String? { get }
    var media: [Media] { get }
    var textFields: [NSTextField] { get }
    var recordGroups: [RecordGroup] { get }
}


struct RecordGroup {
    let type: RecordType
    let records: [RecordDisplayable]
}


extension RecordDisplayable {
    var relatedRecords: [RecordDisplayable] {
        return recordGroups.reduce([]) { $0 + $1.records }
    }
}


extension Event: RecordDisplayable {

    var textFields: [NSTextField] {
        var labels = [NSTextField]()

        let titleText = NSAttributedString(string: title)
        let label = NSTextField(labelWithAttributedString: titleText)
        label.textColor = NSColor.white
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        label.font = NSFont.systemFont(ofSize: Constants.titleFontSize, weight: .semibold)
        labels.append(label)

        if let date = date, let first = date.split(separator: "|").first?.description {
            let dateText = NSAttributedString(string: first)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.textColor = style.selectedColor
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.font = NSFont.systemFont(ofSize: Constants.dateFontSize)
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description)
            let label = NSTextField(labelWithAttributedString: descriptionText)
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

        let titleText = NSAttributedString(string: title)
        let label = NSTextField(labelWithAttributedString: titleText)
        label.textColor = NSColor.white
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        label.font = NSFont.systemFont(ofSize: Constants.titleFontSize, weight: .semibold)
        labels.append(label)

        if let date = date, let first = date.split(separator: "|").first?.description {
            let dateText = NSAttributedString(string: first)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.textColor = style.selectedColor
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.font = NSFont.systemFont(ofSize: Constants.dateFontSize)
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description)
            let label = NSTextField(labelWithAttributedString: descriptionText)
            label.textColor = .white
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.lineBreakMode = .byWordWrapping
            labels.append(label)
        }

        if let comments = comments {
            let commentText = NSAttributedString(string: comments)
            let label = NSTextField(labelWithAttributedString: commentText)
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

        let titleText = NSAttributedString(string: title)
        let label = NSTextField(labelWithAttributedString: titleText)
        label.textColor = NSColor.white
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        label.font = NSFont.systemFont(ofSize: Constants.titleFontSize, weight: .semibold)
        labels.append(label)

        if let date = date, let first = date.split(separator: "|").first?.description {
            let dateText = NSAttributedString(string: first)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.textColor = style.selectedColor
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.font = NSFont.systemFont(ofSize: Constants.dateFontSize)
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description)
            let label = NSTextField(labelWithAttributedString: descriptionText)
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

        let titleText = NSAttributedString(string: title)
        let label = NSTextField(labelWithAttributedString: titleText)
        label.textColor = NSColor.white
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        label.font = NSFont.systemFont(ofSize: Constants.titleFontSize, weight: .semibold)
        labels.append(label)

        if let date = date, let first = date.split(separator: "|").first?.description {
            let dateText = NSAttributedString(string: first)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.textColor = style.selectedColor
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            label.font = NSFont.systemFont(ofSize: Constants.dateFontSize)
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description)
            let label = NSTextField(labelWithAttributedString: descriptionText)
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
