//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


class DataManager {

    private let persistence: Persistence


    // MARK: Init

    init(database: Persistence = .instance) {
        self.persistence = database
    }


    // MARK: API

    func loadPersistenceStore() {
        // load all models
    }

    func loadObjects(of type: RecordType, then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        if let records = persistence.recordsForType[type] {
            completion(records)
        } else {
            fetchRecords(of: type, then: { [weak self] records in
                self?.persistence.save(records, for: type)
                completion(records)
            })
        }
    }

    func loadObject(of type: RecordType, then completion: @escaping ((RecordDisplayable) -> Void)) {

    }


    // MARK: Helpers

    private func fetchRecords(of type: RecordType, then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        switch type {
        case .organization:
            fetchOrganization(then: completion)
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

    private func fetchOrganization(then completion: @escaping (([RecordDisplayable]?) -> Void)) {
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















