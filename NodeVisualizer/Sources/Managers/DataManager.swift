//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class DataManager {

    struct RecordIdentifier: Hashable {
        let id: Int
        let type: RecordType
    }

    /// Local copy of all record types
    private var allRecordTypes = RecordType.allValues

    /// Local copy of all records retrieved for each record type
    private var allRecords = [RecordDisplayable]()

    /// Dictionary of the associated records for a particular record type
    private(set) var recordsForType = [RecordType: [RecordDisplayable]]()

    /// Dictionary of all related records for a record specified by its record identifier
    private(set) var relatedRecordsForIdentifier = [RecordIdentifier: [RecordDisplayable]]()


    // MARK: Singleton instance

    private init() {}
    static let instance = DataManager()


    // MARK: API

    /// Loads and relates all records to their related descendant records
    func createRecordRelationships(completion: @escaping () -> Void) {
        loadNextRecordTypeRecords { [weak self] records in
            EntityManager.instance.createRecordEntities(for: records)

            self?.allRecords = records
            self?.associateAllRecordsToRelatedRecords {
                EntityManager.instance.createRelationshipsForAllEntities()
                completion()
            }
        }
    }


    // MARK: Helpers

    /// Loads all records for all record types
    private func loadNextRecordTypeRecords(with results: [RecordDisplayable] = [], completion: @escaping ([RecordDisplayable]) -> Void) {
        guard let type = allRecordTypes.popLast() else {
            completion(results)
            return
        }

        loadRecords(of: type) { [weak self] records in
            var updatedResults = results
            if let records = records {
                updatedResults += records
            }
            self?.loadNextRecordTypeRecords(with: updatedResults, completion: completion)
        }
    }

    /// Loads all records for a specified record type
    private func loadRecords(of type: RecordType, completion: @escaping ([RecordDisplayable]?) -> Void) {
        RecordFactory.records(for: type, completion: { [weak self] records in
            self?.save(records, for: type)
            completion(records)
        })
    }

    /// Saves locally all records associated with a specified record type
    private func save(_ records: [RecordDisplayable]?, for type: RecordType) {
        if recordsForType[type] == nil, let records = records {
            recordsForType[type] = records
        }
    }

    /// Retrieves and creates relationship between all related records and each record in allRecords
    private func associateAllRecordsToRelatedRecords(completion: @escaping () -> Void) {
        guard let record = allRecords.popLast() else {
            completion()
            return
        }

        loadDetails(for: record) { [weak self] _ in
            self?.associateAllRecordsToRelatedRecords(completion: completion)
        }
    }

    /// Loads the details for a particular record
    private func loadDetails(for record: RecordDisplayable, completion: @escaping (RecordDisplayable?) -> Void) {
        RecordFactory.record(for: record.type, id: record.id, completion: { [weak self] recordDetails in
            let identifier = RecordIdentifier(id: record.id, type: record.type)
            self?.associateRelatedRecords(to: identifier, with: recordDetails)
            completion(recordDetails)
        })
    }

    /// Creates related records to record identifier relationship using the record's details
    private func associateRelatedRecords(to identifier: RecordIdentifier, with recordDetails: RecordDisplayable?) {
        if relatedRecordsForIdentifier[identifier] == nil, let recordDetails = recordDetails {
            relatedRecordsForIdentifier[identifier] = recordDetails.relatedRecords
        }
    }
}

