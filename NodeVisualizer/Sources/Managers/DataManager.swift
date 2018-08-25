//  Copyright © 2018 JABT. All rights reserved.

import Foundation


struct RecordProxy: Hashable {
    let id: Int
    let type: RecordType
}


typealias RelatedLevels = [Set<RecordProxy>]


final class DataManager {
    static let instance = DataManager()

    private(set) var records = [RecordDisplayable]()
    private(set) var recordForProxy = [RecordProxy: RecordDisplayable]()
    private(set) var relativesForProxy = [RecordProxy: Set<RecordProxy>]()
    private(set) var relatedLevelsForProxy = [RecordProxy: RelatedLevels]()

    private struct Constants {
        static let maxRelatedLevel = 4
    }


    // MARK: Init

    /// Use singleton
    private init() {}


    // MARK: API

    /// Loads and relates all records to their related descendant records
    func instantiate(completion: @escaping () -> Void) {
        var types = Set(RecordType.allValues)

        for type in types {
            RecordFactory.records(for: type, completion: { [weak self] records in
                self?.store(records)
                types.remove(type)
                if types.isEmpty {
                    self?.createAssociations {
                        completion()
                    }
                }
            })
        }
    }


    // MARK: Helpers

    private func store(_ records: [RecordDisplayable]?) {
        if let records = records {
            self.records.append(contentsOf: records)
            for record in records {
                let proxy = RecordProxy(id: record.id, type: record.type)
                recordForProxy[proxy] = record
            }
        }
    }

    private func createAssociations(completion: @escaping () -> Void) {
        var proxies = Set(records.map { RecordProxy(id: $0.id, type: $0.type) })

        for proxy in proxies {
            RecordFactory.record(for: proxy.type, id: proxy.id, completion: { [weak self] record in
                self?.relativesForProxy[proxy] = self?.proxies(for: record?.relatedRecords)
                proxies.remove(proxy)
                if proxies.isEmpty {
                    self?.filterSingleArtifactConnections()
                    self?.createLevels()
                    self?.createEntities()
                    completion()
                }
            })
        }
    }

    private func filterSingleArtifactConnections() {
        let unfilteredRelativesForProxy = relativesForProxy
        for (proxy, relatives) in relativesForProxy {
            if shouldRemove(proxy: proxy, from: unfilteredRelativesForProxy) {
                relativesForProxy.removeValue(forKey: proxy)
            } else {
                for relative in relatives {
                    if shouldRemove(proxy: relative, from: unfilteredRelativesForProxy) {
                        relativesForProxy[proxy]?.remove(relative)
                    }
                }

                if let relatives = relativesForProxy[proxy], relatives.isEmpty {
                    relativesForProxy.removeValue(forKey: proxy)
                }
            }
        }
    }

    private func shouldRemove(proxy: RecordProxy, from relativesForProxy: [RecordProxy: Set<RecordProxy>]) -> Bool {
        if proxy.type == .artifact, let relatives = relativesForProxy[proxy], relatives.count == 1 {
            return true
        }

        return false
    }

    private func createLevels() {
        let proxies = relativesForProxy.keys

        // Populate related entities set in each RecordEntity.
        for proxy in proxies {
            // Fill level 0
            let relatives = relativesForProxy[proxy] ?? []
            var levelsForProxy = RelatedLevels()
            levelsForProxy.insert(relatives, at: 0)

            // Populate following levels based on the level 0 entities
            for level in (1 ... Constants.maxRelatedLevel) {
                let proxiesForPreviousLevel = levelsForProxy.at(index: level - 1) ?? []
                var proxiesForLevel = Set<RecordProxy>()
                for recordProxy in proxiesForPreviousLevel {
                    let relatedProxies = relativesForProxy[recordProxy] ?? []
                    for relatedProxy in relatedProxies {
                        if !levels(levelsForProxy, contains: relatedProxy) && relatedProxy != proxy {
                            proxiesForLevel.insert(relatedProxy)
                        }
                    }
                }
                if proxiesForLevel.isEmpty {
                    break
                }
                levelsForProxy.insert(proxiesForLevel, at: level)
            }
            relatedLevelsForProxy[proxy] = levelsForProxy
        }
    }

    private func createEntities() {
        for (proxy, levels) in relatedLevelsForProxy {
            if let record = recordForProxy[proxy] {
                EntityManager.instance.createEntity(record: record, levels: levels)
            }
        }
    }

    private func levels(_ levels: RelatedLevels, contains proxy: RecordProxy) -> Bool {
        for level in levels {
            if level.contains(proxy) {
                return true
            }
        }
        return false
    }

    private func proxies(for records: [RecordDisplayable]?) -> Set<RecordProxy> {
        let proxies = records?.map { $0.proxy } ?? []
        return Set(proxies)
    }
}
