//  Copyright © 2018 JABT. All rights reserved.

import Foundation


class DataManager {

    private let persistence: Persistence
    private let dataLoader: DataLoader
    private var allRecordTypes = RecordType.allValues


    // MARK: Init

    init(database: Persistence = .instance, dataLoader: DataLoader = DataLoader()) {
        self.persistence = database
        self.dataLoader = dataLoader
    }


    // MARK: API

    func loadPersistenceStore(then completion: @escaping ([RecordDisplayable]) -> Void) {
        load(then: completion)
    }

    func loadRecords(of type: RecordType, then completion: @escaping ([RecordDisplayable]?) -> Void) {
        if let records = persistence.recordsForType[type] {
            completion(records)
        } else {
            fetchRecords(of: type, completion: completion)
        }
    }

    func loadRecord(of type: RecordType, id: Int, then completion: @escaping (RecordDisplayable) -> Void) {
        // implement later when necessary
    }


    // MARK: Helpers

    private func load(with results: [RecordDisplayable] = [], then completion: @escaping ([RecordDisplayable]) -> Void) {
        guard let recordType = allRecordTypes.popLast() else {
            completion(results)
            return
        }

        loadRecords(of: recordType, then: { [weak self] records in
            if let records = records {
                let updatedResults = records
                self?.load(with: updatedResults, then: completion)
            }
        })
    }

    private func fetchRecords(of type: RecordType, completion: @escaping ([RecordDisplayable]?) -> Void) {
        dataLoader.fetchRecords(of: type, then: { [weak self] records in
            if let records = records {
                self?.persistence.save(records, for: type)
            }
            completion(records)
        })
    }
}
