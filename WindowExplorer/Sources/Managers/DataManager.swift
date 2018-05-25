//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


class DataManager {

    private let persistence: Persistence
    private var allRecordTypes = RecordType.allValues


    // MARK: Init

    init(database: Persistence = .instance) {
        self.persistence = database
    }


    // MARK: API

    func loadPersistenceStore() {
        next(completion: { records in
            print(records)
        })
    }

    func loadObjects(of type: RecordType, then completion: @escaping ([RecordDisplayable]?) -> Void) {
        if let records = persistence.recordsForType[type] {
            completion(records)
        } else {
            fetchRecords(of: type, then: { [weak self] records in
                if let records = records {
                    self?.persistence.save(records, for: type)
                }
                completion(records)
            })
        }
    }

    func loadObject(of type: RecordType, id: Int, then completion: @escaping (RecordDisplayable) -> Void) {

    }


    // MARK: Helpers

    private func next(results: [RecordDisplayable] = [], completion: @escaping ([RecordDisplayable]) -> Void) {
        guard let recordType = allRecordTypes.popLast() else {
            completion(results)
            return
        }

        loadObjects(of: recordType, then: { records in
            if let records = records {
                let updatedResults = records
                self.next(results: updatedResults, completion: completion)
            }
        })
    }

    // could break out into separate DataLoader type
    private func fetchRecords(of type: RecordType, then completion: @escaping ([RecordDisplayable]?) -> Void) {
        switch type {
        case .organization:
            fetchOrganizations(then: completion)
        case .event:
            break
        case .artifact:
            break
        case .school:
            break
        case .theme:
            break
        }
    }

    private func fetchOrganizations(then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        firstly {
            try CachingNetwork.getOrganizations()
        }.then { organizations in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }



}
