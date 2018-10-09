//  Copyright © 2018 JABT. All rights reserved.

import Foundation


struct RecordProxy: Hashable {
    let id: Int
    let type: RecordType
}


typealias RelatedLevels = [Set<RecordProxy>]


final class RecordManager {
    static let instance = RecordManager()

    /// Type: [ID: Record]
    private var recordsForType: [RecordType: [Int: Record]] = [
        .school: [:],
        .artifact: [:],
        .organization: [:],
        .event: [:],
        .theme: [:]
    ]

    private(set) var relativesForProxy = [RecordProxy: Set<RecordProxy>]()
    private(set) var relatedLevelsForProxy = [RecordProxy: RelatedLevels]()

    private struct Constants {
        static let maxRelatedLevel = 4
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
                    self?.filterSingleArtifactConnections()
                    self?.createLevelsForProxies()
                    completion()
                }
            })
        }
    }

    func createEntities() {
        for (proxy, levels) in relatedLevelsForProxy {
            if let record = recordsForType[proxy.type]?[proxy.id] {
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
        for id in record.relatedSchoolIDs {
            if let school = recordsForType[.school]?[id] as? School {
                record.relatedSchools.append(school)
            }
        }
        for id in record.relatedArtifactIDs {
            if let artifact = recordsForType[.artifact]?[id] as? Artifact {
                record.relatedArtifacts.append(artifact)
            }
        }
        for id in record.relatedOrganizationIDs {
            if let organization = recordsForType[.organization]?[id] as? Organization {
                record.relatedOrganizations.append(organization)
            }
        }
        for id in record.relatedEventIDs {
            if let event = recordsForType[.event]?[id] as? Event {
                record.relatedEvents.append(event)
            }
        }
        for id in record.relatedThemeIDs {
            if let theme = recordsForType[.theme]?[id] as? Theme {
                record.relatedThemes.append(theme)
            }
        }
    }

    private func records(for type: RecordType) -> [Record] {
        guard let recordsForID = recordsForType[type] else {
            return []
        }

        return Array(recordsForID.values)
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

    private func createLevelsForProxies() {
        for proxy in relativesForProxy.keys {
            // Populate level 0
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
