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

    private(set) var relatedRecordsForRecord = [DataManager.RecordIdentifier: Set<Record>]()

    private lazy var schoolRecord = Record(id: Constants.schoolId, type: .school)
    private lazy var organizationRecord = Record(id: Constants.organizationId, type: .organization)
    private lazy var eventRecord = Record(id: Constants.eventId, type: .event)

    private lazy var allRecords: [Record] = {
        var records = [schoolRecord, organizationRecord, eventRecord]
        records += relatedArtifactsForSchool
        records += relatedArtifactsForOrganization
        records += relatedArtifactsForEvent
        return records
    }()

    private var relatedArtifactsForSchool = [Record]()
    private var relatedArtifactsForOrganization = [Record]()
    private var relatedArtifactsForEvent = [Record]()

    private struct Constants {
        static let schoolId = -100
        static let organizationId = -200
        static let eventId = -300
        static let lowerLimitForSchool = 0
        static let lowerLimitForOrganization = 1001
        static let lowerLimitForEvent = 2001
    }


    // MARK: Singleton instance

    static let instance = TestingEnvironment()
    private init() { }


    // MARK: API

    func createTestEnvironmentRecordRelationships(completion: @escaping () -> Void) {
        // create all records and entities to EntityManager
        createArtifactRecords()
        EntityManager.instance.createRecordEntities(for: allRecords)

        // create associations between the records and create relationship to EntityManager
        createAssociations()
        EntityManager.instance.createRelationshipsForAllEntities()

        completion()
    }

    // MARK: Helpers

    private func createArtifactRecords() {
        // clamp upper limit to: 0 < upper limit < 1000
        createArtifactRecords(for: .school, lowerLimit: Constants.lowerLimitForSchool, upperLimit: 50)

        // clamp upper limit to: 1000 < upper limit < 2000
        createArtifactRecords(for: .organization, lowerLimit: Constants.lowerLimitForOrganization, upperLimit: 1050)

        // clamp upper limit to: 2000 < upper limit < 3000
        createArtifactRecords(for: .event, lowerLimit: Constants.lowerLimitForEvent, upperLimit: 2010)
    }

    private func createArtifactRecords(for type: RecordType, lowerLimit: Int, upperLimit: Int) {
        var artifactRecords = [Record]()

        for index in lowerLimit..<upperLimit {
            let record = Record(id: index, type: .artifact)
            artifactRecords.append(record)
        }

        switch type {
        case .school:
            relatedArtifactsForSchool += artifactRecords
        case .event:
            relatedArtifactsForEvent += artifactRecords
        case .organization:
            relatedArtifactsForOrganization += artifactRecords
        default:
            return
        }
    }

    private func createAssociations() {
        // associations for schoolRecord
        associate(records: relatedArtifactsForSchool, to: schoolRecord)
        associate(records: [organizationRecord], to: schoolRecord)

        // associations for organizationRecord
        associate(records: relatedArtifactsForOrganization, to: organizationRecord)
        associate(records: [schoolRecord], to: organizationRecord)
        associate(records: [eventRecord], to: organizationRecord)

        // associations for eventRecord
        associate(records: relatedArtifactsForEvent, to: eventRecord)

        // associations for artifacts
        relateMainRecord(schoolRecord, toArtifacts: relatedArtifactsForSchool)
        relateMainRecord(organizationRecord, toArtifacts: relatedArtifactsForOrganization)
        relateMainRecord(eventRecord, toArtifacts: relatedArtifactsForEvent)
    }

    private func relateMainRecord(_ record: Record, toArtifacts artifacts: [Record]) {
        for artifact in artifacts {
            associate(records: [record], to: artifact)
        }
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
