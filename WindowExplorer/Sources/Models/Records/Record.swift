//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MapKit


protocol Record: SearchItemDisplayable {
    var id: Int { get }
    var title: String { get }
    var type: RecordType { get }
    var description: String? { get }
    var comments: String? { get }
    var date: String? { get }
    var coordinate: CLLocationCoordinate2D? { get }
    var media: [Media] { get }
    var recordGroups: [RecordGroup] { get }
    var priority: Int { get }
}


struct RecordGroup {
    let type: RecordType
    let records: [Record]
}


extension Record {

    var relatedRecords: [Record] {
        return recordGroups.reduce([]) { $0 + $1.records }
    }

    func relatedRecords(type: RecordType) -> [Record] {
        if let recordGroup = recordGroups.first(where: { $0.type == type }) {
            return recordGroup.records
        }

        return []
    }

    func relatedRecords(filterType type: RecordFilterType) -> [Record] {
        if let recordType = type.recordType {
            return relatedRecords(type: recordType)
        } else if type == .all {
            return relatedRecords
        }

        switch type {
        case .image:
            return relatedRecordsContainingImages()
        default:
            return []
        }
    }

    func filterRelatedRecords(type: RecordFilterType, from records: [Record]) -> [Record] {
        if let recordType = type.recordType {
            return records.filter { $0.type == recordType }
        } else if type == .all {
            return records
        }

        switch type {
        case .image:
            return records.filter { $0.containsImages() }
        default:
            return []
        }
    }

    func relatedRecordsContainingImages() -> [Record] {
        return relatedRecords.filter { $0.containsImages() }
    }

    func containsImages() -> Bool {
        for item in media {
            if item.type == .image || item.type == .pdf {
                return true
            }
        }

        return false
    }
}


extension Event: Record {

    var comments: String? {
        return nil
    }

    var recordGroups: [RecordGroup] {
        let schoolGroup = RecordGroup(type: .school, records: relatedSchools)
        let organizationGroup = RecordGroup(type: .organization, records: relatedOrganizations)
        let artifactGroup = RecordGroup(type: .artifact, records: relatedArtifacts)
        let eventGroup = RecordGroup(type: .event, records: relatedEvents)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}


extension Artifact: Record {

    var coordinate: CLLocationCoordinate2D? {
        return nil
    }

    var recordGroups: [RecordGroup] {
        let schoolGroup = RecordGroup(type: .school, records: relatedSchools)
        let organizationGroup = RecordGroup(type: .organization, records: relatedOrganizations)
        let artifactGroup = RecordGroup(type: .artifact, records: relatedArtifacts)
        let eventGroup = RecordGroup(type: .event, records: relatedEvents)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}


extension Organization: Record {

    var date: String? {
        return nil
    }

    var comments: String? {
        return nil
    }

    var coordinate: CLLocationCoordinate2D? {
        return nil
    }

    var recordGroups: [RecordGroup] {
        let schoolGroup = RecordGroup(type: .school, records: relatedSchools)
        let organizationGroup = RecordGroup(type: .organization, records: relatedOrganizations)
        let artifactGroup = RecordGroup(type: .artifact, records: relatedArtifacts)
        let eventGroup = RecordGroup(type: .event, records: relatedEvents)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}


extension School: Record {

    var comments: String? {
        return nil
    }

    var recordGroups: [RecordGroup] {
        let schoolGroup = RecordGroup(type: .school, records: relatedSchools)
        let organizationGroup = RecordGroup(type: .organization, records: relatedOrganizations)
        let artifactGroup = RecordGroup(type: .artifact, records: relatedArtifacts)
        let eventGroup = RecordGroup(type: .event, records: relatedEvents)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}


extension Theme: Record {

    var date: String? {
        return nil
    }

    var coordinate: CLLocationCoordinate2D? {
        return nil
    }

    var media: [Media] {
        return []
    }

    var comments: String? {
        return nil
    }

    var recordGroups: [RecordGroup] {
        let schoolGroup = RecordGroup(type: .school, records: relatedSchools)
        let organizationGroup = RecordGroup(type: .organization, records: relatedOrganizations)
        let artifactGroup = RecordGroup(type: .artifact, records: relatedArtifacts)
        let eventGroup = RecordGroup(type: .event, records: relatedEvents)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}


extension RecordCollection: Record {

    var comments: String? {
        return nil
    }

    var recordGroups: [RecordGroup] {
        let schoolGroup = RecordGroup(type: .school, records: relatedSchools)
        let organizationGroup = RecordGroup(type: .organization, records: relatedOrganizations)
        let artifactGroup = RecordGroup(type: .artifact, records: relatedArtifacts)
        let eventGroup = RecordGroup(type: .event, records: relatedEvents)

        return [schoolGroup, organizationGroup, artifactGroup, eventGroup]
    }
}
