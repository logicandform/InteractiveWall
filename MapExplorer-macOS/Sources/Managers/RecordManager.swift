//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class RecordManager {
    static let instance = RecordManager()

    /// Type: [ID: Record]
    private var recordsForType: [RecordType: [Int: Record]] = [
        .school: [:],
        .event: [:],
        .collection: [:]
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
                    completion()
                }
            })
        }
    }

    func record(for type: RecordType, id: Int) -> Record? {
        return recordsForType[type]?[id]
    }

    func records(for type: RecordType, ids: [Int]) -> [Record] {
        return ids.compactMap { recordsForType[type]?[$0] }
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
        for id in record.relatedSchoolIDs {
            if let school = recordsForType[.school]?[id] as? School {
                record.relatedSchools.append(school)
            }
        }
        for id in record.relatedEventIDs {
            if let event = recordsForType[.event]?[id] as? Event {
                record.relatedEvents.append(event)
            }
        }
    }
}
