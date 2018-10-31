//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class RecordManager {
    static let instance = RecordManager()

    /// Type: [ID: Record]
    private var recordsForType: [RecordType: [Int: Record]] = [
        .school: [:],
        .artifact: [:],
        .organization: [:],
        .event: [:],
        .theme: [:],
        .collection: [:],
        .individual: [:]
    ]


    // MARK: Init

    /// Use singleton
    private init() { }


    // MARK: API

    func initialize(completion: @escaping () -> Void) {
        var types = Set(RecordType.allValues)

        for type in types {
            RecordNetwork.records(for: type, completion: { [weak self] records in
                self?.store(records: records, for: type)
                types.remove(type)
                if types.isEmpty {
                    self?.createRelationships()
                    GeocodeHelper.instance.associateSchoolsToProvinces()
                    completion()
                }
            })
        }
    }

    func record(for type: RecordType, id: Int) -> Record? {
        return recordsForType[type]?[id]
    }

    func records(for type: RecordType) -> [Record] {
        guard let recordsForID = recordsForType[type] else {
            return []
        }

        return Array(recordsForID.values)
    }


    // MARK: Helpers

    private func store(records: [Record]?, for type: RecordType) {
        if let records = records {
            for record in records {
                recordsForType[type]?[record.id] = record
            }
        }
    }

    private func createRelationships() {
        for (_, records) in recordsForType {
            for (_, record) in records {
                makeRelationships(for: record)
            }
        }
    }

    private func makeRelationships(for record: Record) {
        record.relatedRecordsForType[.school] = records(for: .school, ids: record.relatedSchoolIDs)
        record.relatedRecordsForType[.artifact] = records(for: .artifact, ids: record.relatedArtifactIDs)
        record.relatedRecordsForType[.organization] = records(for: .organization, ids: record.relatedOrganizationIDs)
        record.relatedRecordsForType[.event] = records(for: .event, ids: record.relatedEventIDs)
        record.relatedRecordsForType[.collection] = records(for: .collection, ids: record.relatedCollectionIDs)
        record.relatedRecordsForType[.individual] = records(for: .individual, ids: record.relatedIndividualIDs)

        let themes = records(for: .theme, ids: record.relatedThemeIDs)
        record.relatedRecordsForType[.theme] = themes

        // Apply the inverse relationship for theme records
        for theme in themes {
            theme.relate(to: record)
        }
    }

    /// Returns an array of records from the given ids, removing duplicates
    private func records(for type: RecordType, ids: [Int]) -> Set<Record> {
        return Set(ids.compactMap { recordsForType[type]?[$0] })
    }
}
