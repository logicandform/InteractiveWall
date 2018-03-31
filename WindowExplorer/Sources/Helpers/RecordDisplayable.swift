//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


private struct Constants {
    static let titleFontSize: CGFloat = 28.0
    static let titleLineSpacing: CGFloat = 0.0
    static let titleMaximumLineheight: CGFloat = titleFontSize + 2.0
    static let titleForegroundColor: NSColor = NSColor.white
    static let dateFontSize: CGFloat = 14.0
    static let dateLineSpacing: CGFloat = 0.0
    static let dateParagraphSpacingBefore: CGFloat = 0.0
    static let dateForegroundColor: NSColor = style.selectedColor
    static let descriptionFontSize: CGFloat = 16.0
    static let descriptionLineSpacing: CGFloat = 0.0
    static let descriptionMaximumLineHeight: CGFloat = descriptionFontSize + 5.0
    static let descriptionParagraphSpacing: CGFloat = 8.0
    static let descriptionForegroundColor: NSColor = NSColor.white
    static let commentsFontSize: CGFloat = 16.0
    static let commentsLineSpacing: CGFloat = 0.0
    static let commentsMaximumLineHeight: CGFloat = commentsFontSize + 5.0
    static let commentsParagraphSpacing: CGFloat = 8.0
    static let commentsForegroundColor: NSColor = NSColor.white
    static let smallHeaderFontSize: CGFloat = 12.0
    static let smallHeaderLineSpacing: CGFloat = 0.0
    static let smallHeaderForegroundColor: NSColor = NSColor.white
    static let smallHeaderParagraphSpacing: CGFloat = 0.0
    static let smallHeaderParagraphSpacingBefore: CGFloat = 20.0
    static let fontName: String = "Soleil"
    static let kern: CGFloat = 0.5
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
    
    var titleAttributes: [NSAttributedStringKey:Any] {
        let font = NSFont(name: Constants.fontName, size: Constants.titleFontSize) ?? NSFont.systemFont(ofSize: Constants.titleFontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.titleLineSpacing
        paragraphStyle.maximumLineHeight = Constants.titleMaximumLineheight
        
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.titleForegroundColor,
                .kern : Constants.kern
        ]
    }
    
    var dateAttributes: [NSAttributedStringKey:Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.dateLineSpacing
        paragraphStyle.paragraphSpacingBefore = Constants.dateParagraphSpacingBefore
        let font = NSFont(name: Constants.fontName, size: Constants.dateFontSize) ?? NSFont.systemFont(ofSize: Constants.dateFontSize)
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.dateForegroundColor,
                .kern : Constants.kern
        ]
    }
    
    var descriptionAttributes: [NSAttributedStringKey:Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.descriptionLineSpacing
        paragraphStyle.paragraphSpacing = Constants.descriptionParagraphSpacing
        paragraphStyle.maximumLineHeight = Constants.descriptionMaximumLineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        let font = NSFont(name: Constants.fontName, size: Constants.descriptionFontSize) ?? NSFont.systemFont(ofSize: Constants.descriptionFontSize)
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.descriptionForegroundColor,
                .kern : Constants.kern
        ]
    }
    
    var commentAttributes: [NSAttributedStringKey:Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.commentsLineSpacing
        paragraphStyle.paragraphSpacing = Constants.commentsParagraphSpacing
        paragraphStyle.maximumLineHeight = Constants.commentsMaximumLineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping
        let font = NSFont(name: Constants.fontName, size: Constants.commentsFontSize) ?? NSFont.systemFont(ofSize: Constants.commentsFontSize)
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.commentsForegroundColor,
                .kern : Constants.kern
        ]
    }
    
    var smallHeaderAttributes: [NSAttributedStringKey:Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Constants.smallHeaderLineSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.paragraphSpacing = Constants.smallHeaderParagraphSpacing
        paragraphStyle.paragraphSpacingBefore = Constants.smallHeaderParagraphSpacingBefore
        let font = NSFont(name: Constants.fontName, size: Constants.smallHeaderFontSize) ?? NSFont.systemFont(ofSize: Constants.smallHeaderFontSize)
        return [.paragraphStyle : paragraphStyle,
                .font : font,
                .foregroundColor : Constants.smallHeaderForegroundColor,
                .kern : Constants.kern
        ]
    }
    
    func smallHeader(named headerName: String) -> NSTextField {
        let header = NSMutableAttributedString(string: "\n"+headerName, attributes: smallHeaderAttributes)
        let label = NSTextField(labelWithAttributedString: header)
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        label.sizeToFit()
        return label
    }
}


extension Event: RecordDisplayable {

    var textFields: [NSTextField] {
        var labels = [NSTextField]()

        let titleText = NSAttributedString(string: title)
        let label = NSTextField(labelWithAttributedString: titleText)
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        labels.append(label)

        if let date = date, let first = date.split(separator: "|").first?.description {
            let dateText = NSMutableAttributedString(string: first, attributes: dateAttributes)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description, attributes: descriptionAttributes)
            let label = NSTextField(labelWithAttributedString: descriptionText)
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
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

        let titleText = NSAttributedString(string: title, attributes: titleAttributes)
        let label = NSTextField(labelWithAttributedString: titleText)
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        labels.append(label)

        if let date = date, let first = date.split(separator: "|").first?.description {
            let dateText = NSAttributedString(string: first, attributes: dateAttributes)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description, attributes: descriptionAttributes)
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
            let dateText = NSAttributedString(string: first, attributes: dateAttributes)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description, attributes: descriptionAttributes)
            let label = NSTextField(labelWithAttributedString: descriptionText)
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
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

        let titleText = NSAttributedString(string: title, attributes: titleAttributes)
        let label = NSTextField(labelWithAttributedString: titleText)
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        labels.append(label)

        if let date = date, let first = date.split(separator: "|").first?.description {
            let dateText = NSAttributedString(string: first, attributes: dateAttributes)
            let label = NSTextField(labelWithAttributedString: dateText)
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
            labels.append(label)
        }

        if let description = description {
            let descriptionText = NSAttributedString(string: description, attributes: descriptionAttributes)
            let label = NSTextField(labelWithAttributedString: descriptionText)
            label.drawsBackground = false
            label.isBordered = false
            label.isSelectable = false
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
