//  Copyright © 2018 JABT. All rights reserved.

import Foundation


struct RecordProxy: Hashable {
    let id: Int
    let type: RecordType
}


typealias RelatedLevels = [Set<RecordProxy>]


final class RecordManager {
    static let instance = RecordManager()

    private(set) var relativesForProxy = [RecordProxy: Set<RecordProxy>]()
    private(set) var relatedLevelsForProxy = [RecordProxy: RelatedLevels]()
    private(set) var recordsForType: [RecordType: [Int: Record]] = [
        .school: [:],
        .artifact: [:],
        .organization: [:],
        .event: [:],
        .theme: [:]
    ]

    private struct Constants {
        static let minRelativeCount = 2
    }


    // MARK: Init

    /// Use singleton
    private init() {}


    // MARK: API

    func initialize(completion: @escaping () -> Void) {
        var types = Set(RecordType.allValues)

        for type in types {
            RecordNetwork.records(for: type, completion: { [weak self] records in
                self?.store(records: records, for: type)
                types.remove(type)
                if types.isEmpty {
                    self?.createRelationships()
                    self?.filterRecords()
                    self?.createLevelsForProxies()
                    completion()
                }
            })
        }
    }

    func createEntities() {
        for (proxy, levels) in relatedLevelsForProxy {
            if let record = RecordManager.instance.recordsForType[proxy.type]?[proxy.id] {
                EntityManager.instance.createEntity(record: record, levels: levels)
            }
        }
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
        let allRecords = RecordType.allValues.reduce([]) { $0 + records(for: $1) }

        // Fill records relationships
        for record in allRecords {
            makeRelationships(for: record)
        }

        // Store related proxies for record
        for record in allRecords {
            relativesForProxy[record.proxy] = proxies(for: record.relatedRecords)
        }
    }

    private func makeRelationships(for record: Record) {
        record.relatedRecordsForType[.school] = records(for: .school, ids: record.relatedSchoolIDs)
        record.relatedRecordsForType[.artifact] = records(for: .artifact, ids: record.relatedArtifactIDs)
        record.relatedRecordsForType[.organization] = records(for: .organization, ids: record.relatedOrganizationIDs)
        record.relatedRecordsForType[.event] = records(for: .event, ids: record.relatedEventIDs)

        let themes = records(for: .theme, ids: record.relatedThemeIDs)
        record.relatedRecordsForType[.theme] = themes

        // Apply the inverse relationship for theme records
        for theme in themes {
            theme.relate(to: record)
        }
    }

    /// Returns a set of records from the given ids
    private func records(for type: RecordType, ids: [Int]) -> Set<Record> {
        return Set(ids.compactMap { recordsForType[type]?[$0] })
    }

    private func records(for type: RecordType) -> [Record] {
        guard let recordsForID = recordsForType[type] else {
            return []
        }

        return Array(recordsForID.values)
    }

    /// Filters out records with only one related item or less
    private func filterRecords() {
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

    /// Returns true if the record for the proxy has less than minRelativeCount relatives
    private func shouldRemove(proxy: RecordProxy, from relativesForProxy: [RecordProxy: Set<RecordProxy>]) -> Bool {
        if let relatives = relativesForProxy[proxy], relatives.count < Constants.minRelativeCount {
            return true
        }

        return false
    }

    private func createLevelsForProxies() {
        for proxy in relativesForProxy.keys {
            // Populate level 0
            let relatives = relativesForProxy[proxy] ?? []
            var levelsForProxy = RelatedLevels()
            levelsForProxy.insert(relatives, at: 0)

            // Populate following levels based on the level 0 entities
            for level in (1 ..< NodeCluster.maxRelatedLevels) {
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

    private func levels(_ levels: RelatedLevels, contains proxy: RecordProxy) -> Bool {
        for level in levels {
            if level.contains(proxy) {
                return true
            }
        }
        return false
    }

    private func proxies(for records: [Record]?) -> Set<RecordProxy> {
        let proxies = records?.map { $0.proxy } ?? []
        return Set(proxies)
    }
}
