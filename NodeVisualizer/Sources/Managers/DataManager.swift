//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class DataManager {

    static let instance = DataManager()

    struct RecordIdentifier: Hashable {
        let id: Int
        let type: RecordType
    }

    private var allRecordTypes = RecordType.allValues
    private var allRecords = [RecordDisplayable]()
    private var recordsForType = [RecordType: [RecordDisplayable]]()
    private var relatedRecordsForIdentifier = [RecordIdentifier: [RecordDisplayable]]()


    // Use singleton instance
    private init() {}


    // MARK: API

    func associateRecordsToRelatedRecords(then completion: @escaping ([RecordDisplayable]) -> Void) {
        loadAllRecords(then: { [weak self] allRecords in
            self?.allRecords = allRecords
//            completion(allRecords)

            self?.associateAllRecordsToRelatedRecords(completion: {
                completion(allRecords)
            })
        })
    }

    func records(for type: RecordType) -> [RecordDisplayable] {
        guard let records = recordsForType[type] else {
            return []
        }

        return records
    }

    func relatedRecords(for identifier: RecordIdentifier) -> [RecordDisplayable] {
        guard let relatedRecords = relatedRecordsForIdentifier[identifier] else {
            return []
        }

        return relatedRecords
    }


    // MARK: Helpers

    private func loadAllRecords(then completion: @escaping ([RecordDisplayable]) -> Void) {
        loadNextRecords(completion: completion)
    }

    private func loadNextRecords(with results: [RecordDisplayable] = [], completion: @escaping ([RecordDisplayable]) -> Void) {
        guard let recordType = allRecordTypes.popLast() else {
            completion(results)
            return
        }

        loadRecords(of: recordType, then: { [weak self] records in
            var updatedResults = results
            if let records = records {
                updatedResults += records
            }
            self?.loadNextRecords(with: updatedResults, completion: completion)
        })
    }

    private func loadRecords(of type: RecordType, then completion: @escaping ([RecordDisplayable]?) -> Void) {
        RecordFactory.records(for: type, completion: { [weak self] records in
            self?.save(records, for: type)
            completion(records)
        })
    }

    private func save(_ records: [RecordDisplayable]?, for type: RecordType) {
        if recordsForType[type] == nil, let records = records {
            recordsForType[type] = records
        }
    }

    private func associateAllRecordsToRelatedRecords(completion: @escaping () -> Void) {
        guard let record = allRecords.popLast() else {
            completion()
            return
        }

        loadDetails(of: record, then: { [weak self] _ in
            self?.associateAllRecordsToRelatedRecords(completion: completion)
        })
    }

    private func loadDetails(of record: RecordDisplayable, then completion: @escaping (RecordDisplayable?) -> Void) {
        RecordFactory.record(for: record.type, id: record.id, completion: { [weak self] recordDetails in
            let identifier = RecordIdentifier(id: record.id, type: record.type)
            self?.associateRelatedRecords(to: identifier, with: recordDetails)
            completion(recordDetails)
        })
    }

    private func associateRelatedRecords(to identifier: RecordIdentifier, with recordDetails: RecordDisplayable?) {
        if relatedRecordsForIdentifier[identifier] == nil, let recordDetails = recordDetails {
            relatedRecordsForIdentifier[identifier] = recordDetails.relatedRecords
        }
    }
}

