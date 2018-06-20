//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


class TestingEnvironment {

    static let instance = TestingEnvironment()
    private init() { }

    private(set) var relatedRecordsForRecord = [Record: Set<Record>]()
    private(set) lazy var allRecords: [Record] = {
        var records = [schoolRecord, organizationRecord, eventRecord]
        records += relatedRecordsForSchool
        records += relatedRecordsForOrganization
        records += relatedRecordsForEvent
        return records
    }()


    struct Record: Hashable {
        let id: Int
        let color: NSColor
    }

    lazy private var schoolRecord = {
        return Record(id: 100, color: .blue)
    }()

    lazy private var organizationRecord = {
        return Record(id: 200, color: .orange)
    }()

    lazy private var eventRecord = {
        return Record(id: 300, color: .gray)
    }()

    private var relatedRecordsForSchool = [Record]()
    private var relatedRecordsForOrganization = [Record]()
    private var relatedRecordsForEvent = [Record]()


    // MARK: API

    func createTestingEnvironment(completion: @escaping () -> Void) {
        makeRelatedRecordsForSchool()
        makeRelatedRecordsForOrganization()
        makeRelatedRecordsForEvent()
        completion()
    }


    // MARK: Helpers

    private func makeRelatedRecordsForSchool() {
        for index in 0..<50 {
            let relatedRecord = Record(id: index, color: .brown)
            relatedRecordsForSchool.append(relatedRecord)
            associate(records: [schoolRecord], to: relatedRecord)
        }
        associate(records: relatedRecordsForSchool, to: schoolRecord)
        associate(records: [organizationRecord], to: schoolRecord)
    }

    private func makeRelatedRecordsForOrganization() {
        for index in 51..<61 {
            let relatedRecord = Record(id: index, color: .brown)
            relatedRecordsForOrganization.append(relatedRecord)
            associate(records: [organizationRecord], to: relatedRecord)
        }
        associate(records: relatedRecordsForOrganization, to: organizationRecord)
        associate(records: [schoolRecord], to: organizationRecord)
    }

    private func makeRelatedRecordsForEvent() {
        for index in 62..<64 {
            let relatedRecord = Record(id: index, color: .brown)
            relatedRecordsForEvent.append(relatedRecord)
            associate(records: [eventRecord], to: relatedRecord)
        }
        associate(records: relatedRecordsForEvent, to: eventRecord)
    }

    private func associate(records: [Record], to record: Record) {
        if relatedRecordsForRecord[record] != nil {
            for record in records {
                relatedRecordsForRecord[record]?.insert(record)
            }
        } else {
            relatedRecordsForRecord[record] = Set(records)
        }
    }
}
