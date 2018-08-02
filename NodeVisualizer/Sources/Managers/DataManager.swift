//  Copyright © 2018 JABT. All rights reserved.

import Foundation


struct RecordProxy: Hashable {
    let id: Int
    let type: RecordType
}


final class DataManager {
    static let instance = DataManager()

    private(set) var recordsForType = [RecordType: [RecordDisplayable]]()
    private(set) var relatedRecordsForProxy = [RecordProxy: [RecordDisplayable]]()


    // MARK: Init

    /// Use singleton
    private init() {}


    // MARK: API

    /// Loads and relates all records to their related descendant records
    func instantiate(completion: @escaping () -> Void) {
        var types = Set(RecordType.allValues)

        for type in types {
            RecordFactory.records(for: type, completion: { [weak self] records in
                // For testing, only use a subset of the records
                var subset = [RecordDisplayable]()
                if let records = records {
                    for (index, record) in records.enumerated() {
                        if index < 100 {
                            subset.append(record)
                        }
                    }
                }
                self?.recordsForType[type] = subset
                types.remove(type)
                if types.isEmpty {
                    self?.createAssociations {
                        EntityManager.instance.createEntityRelationships()
                        completion()
                    }
                }
            })
        }
    }


    // MARK: Helpers

    private func createAssociations(completion: @escaping () -> Void) {
        var proxies = Set(allRecords().map { RecordProxy(id: $0.id, type: $0.type) })

        for proxy in proxies {
            RecordFactory.record(for: proxy.type, id: proxy.id, completion: { [weak self] record in
                EntityManager.instance.createEntity(for: proxy, record: record)
                self?.relatedRecordsForProxy[proxy] = record?.relatedRecords
                proxies.remove(proxy)
                if proxies.isEmpty {
                    completion()
                }
            })
        }
    }

    private func allRecords() -> [RecordDisplayable] {
        var records = [RecordDisplayable]()
        for (_, results) in recordsForType {
            records.append(contentsOf: results)
        }

        return records
    }
}
