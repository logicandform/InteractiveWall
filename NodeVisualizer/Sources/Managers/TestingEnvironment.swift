//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    'TestingEnvironment' provides a mock environment for debug and feature development purposes without having to make network requests every build run.
*/

import Foundation
import AppKit


class TestingEnvironment {

    struct Record: Hashable, RecordDisplayable {
        let id: Int
        let type: RecordType

        let title: String = ""
        let description: String? = ""
        let date: String? = ""
        let media: [Media] = []
        let recordGroups: [RecordGroup] = []
        let priority: Int = 0

        var hashValue: Int {
            return id.hashValue
        }

        static func == (lhs: TestingEnvironment.Record, rhs: TestingEnvironment.Record) -> Bool {
            return lhs.id == rhs.id
        }
    }

    static let instance = TestingEnvironment()
    private init() { }

    private(set) var relatedRecordsForRecord = [DataManager.RecordIdentifier: Set<Record>]()
    private(set) lazy var allRecords: [Record] = {
        var records = [schoolRecord, organizationRecord, eventRecord]
        records += relatedRecordsForSchool
        records += relatedRecordsForOrganization
        records += relatedRecordsForEvent
        return records
    }()

    private lazy var schoolRecord = {
        return Record(id: 100, type: .school)
    }()

    private lazy var organizationRecord = {
        return Record(id: 200, type: .organization)
    }()

    private lazy var eventRecord = {
        return Record(id: 300, type: .event)
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
        for index in -50..<50 {
            let relatedRecord = Record(id: index, type: .artifact)
            relatedRecordsForSchool.append(relatedRecord)
            associate(records: [schoolRecord], to: relatedRecord)
        }
        associate(records: relatedRecordsForSchool, to: schoolRecord)
        associate(records: [organizationRecord], to: schoolRecord)
    }

    private func makeRelatedRecordsForOrganization() {
        for index in 51..<61 {
            let relatedRecord = Record(id: index, type: .artifact)
            relatedRecordsForOrganization.append(relatedRecord)
            associate(records: [organizationRecord], to: relatedRecord)
        }
        associate(records: relatedRecordsForOrganization, to: organizationRecord)
        associate(records: [schoolRecord], to: organizationRecord)
        associate(records: [eventRecord], to: organizationRecord)
    }

    private func makeRelatedRecordsForEvent() {
        for index in 152..<154 {
            let relatedRecord = Record(id: index, type: .artifact)
            relatedRecordsForEvent.append(relatedRecord)
            associate(records: [eventRecord], to: relatedRecord)
        }
        associate(records: relatedRecordsForEvent, to: eventRecord)
        associate(records: [organizationRecord], to: eventRecord)
    }

    private func associate(records: [Record], to key: Record) {
        let identifier = DataManager.RecordIdentifier(id: key.id, type: key.type)

        if relatedRecordsForRecord[identifier] != nil {
            for record in records {
                relatedRecordsForRecord[identifier]?.insert(record)
            }
        } else {
            relatedRecordsForRecord[identifier] = Set(records)
        }
    }
}
