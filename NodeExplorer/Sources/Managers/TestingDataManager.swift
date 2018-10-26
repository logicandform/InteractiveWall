//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


/// Provides test data for debug and feature development purposes without having to make network requests every build run.
class TestingDataManager {
    static let instance = TestingDataManager()

    private var records = [Record]()
    private(set) var relativesForProxy = [RecordProxy: Set<RecordProxy>]()
    private(set) var relatedLevelsForProxy = [RecordProxy: RelatedLevels]()

    private struct Constants {
        static let maxRelatedLevel = 4
    }


    // MARK: Init

    private init() { }


    // MARK: API

    func instantiate() {
        // Setup testing nodes
        testSelectedNodeWithMaxRelatedLevels()

        // Store directly related records in dictionary
        for record in records {
            relativesForProxy[record.proxy] = proxies(for: record.relatedRecords)
        }

        // Create relationship levels in dictionary
        createLevelsForRecords()
    }

    func createEntities() {
        for record in records {
            let proxy = RecordProxy(id: record.id, type: record.type)
            let levelsForProxy = relatedLevelsForProxy[proxy] ?? []
            EntityManager.instance.createEntity(record: record, levels: levelsForProxy)
        }
    }


    // MARK: Tests

    /// After a school, org or event is selected. Selecting another one should duplicate nodes from the first cluster.
    private func testDuplicatingNodes() {
        let artifacts = createRecords(of: .artifact, count: 2)
        records.append(contentsOf: artifacts)
        let schools = createRecords(of: .school, count: 1)
        records.append(contentsOf: schools)
        let organizations = createRecords(of: .organization, count: 1)
        records.append(contentsOf: organizations)
        let events = createRecords(of: .event, count: 1)
        records.append(contentsOf: events)

        // Associate school, org, event to the same artifacts
        associate(records: artifacts, to: schools.first!)
        associate(records: artifacts, to: organizations.first!)
        associate(records: artifacts, to: events.first!)
    }

    /// When the school is selected, then selecting artifact #7, everything else in the cluster should be removed
    private func testUnconnectedNodesRemovingFromCluster() {
        let schools = createRecords(of: .school, count: 1)
        records.append(contentsOf: schools)
        let organizations = createRecords(of: .organization, count: 1)
        records.append(contentsOf: organizations)
        let events = createRecords(of: .event, count: 1)
        records.append(contentsOf: events)

        let themes = createRecords(of: .theme, count: 5)
        records.append(contentsOf: themes)
        associate(records: [themes.first!], to: schools.first!)
        for index in (1 ..< themes.count) {
            let previousTheme = themes[index - 1]
            let theme = themes[index]
            associate(records: [theme], to: previousTheme)
        }
    }

    /// To see the visual representation of the cluster when a node with a maximum related level is selected
    private func testSelectedNodeWithMaxRelatedLevels() {
        let schoolArtifacts = createRecords(of: .artifact, count: 5)
        records.append(contentsOf: schoolArtifacts)
        let organizationArtifacts = createRecords(of: .artifact, count: 10)
        records.append(contentsOf: organizationArtifacts)
        let eventArtifacts = createRecords(of: .artifact, count: 10)
        records.append(contentsOf: eventArtifacts)
        let schoolOrganizations = createRecords(of: .organization, count: 10)
        records.append(contentsOf: schoolOrganizations)
        let schoolOrganizationArtifacts = createRecords(of: .artifact, count: 10)
        records.append(contentsOf: schoolOrganizationArtifacts)

        let schools = createRecords(of: .school, count: 2)
        records.append(contentsOf: schools)
        let organizations = createRecords(of: .organization, count: 2)
        records.append(contentsOf: organizations)
        let events = createRecords(of: .event, count: 1)
        records.append(contentsOf: events)

        associate(records: schoolArtifacts, to: schools.first!)
        associate(records: [organizations.first!], to: schools.first!)
        associate(records: [organizations[1]], to: organizations.first!)
        associate(records: events, to: organizations[1])
        associate(records: organizationArtifacts, to: organizations.first!)
        associate(records: eventArtifacts, to: events.first!)
        associate(records: [schools[1]], to: events.first!)
        associate(records: schoolOrganizations, to: schools[1])
        associate(records: schoolOrganizationArtifacts, to: schoolOrganizations.first!)
    }


    // MARK: Helpers

    private func createRecords(of type: RecordType, count: Int) -> [Record] {
        var result = [Record]()
        let min = records.count
        let max = min + count

        for index in min ..< max {
            if let record = testRecord(id: index, type: type) {
                result.append(record)
            }
        }
        return result
    }


    /// Relates records to a specified record and stores it locally in dictionary
    private func associate(records: [Record], to record: Record) {
        let filtered = records.filter { $0.proxy != record.proxy }
        record.relatedOrganizations = filtered.compactMap { $0 as? Organization }
        record.relatedArtifacts = filtered.compactMap { $0 as? Artifact }
        record.relatedSchools = filtered.compactMap { $0 as? School }
        record.relatedEvents = filtered.compactMap { $0 as? Event }
        record.relatedThemes = filtered.compactMap { $0 as? Theme }
    }

    private func createLevelsForRecords() {
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

    private func proxies(for records: [Record]?) -> Set<RecordProxy> {
        let proxies = records?.map { $0.proxy } ?? []
        return Set(proxies)
    }

    private func levels(_ levels: RelatedLevels, contains proxy: RecordProxy) -> Bool {
        for level in levels {
            if level.contains(proxy) {
                return true
            }
        }
        return false
    }

    func testRecord(id: Int, type: RecordType) -> Record? {
        let json: JSON = [
            "id": id,
            "title": "\(id)",
            "shortTitle": "\(id)",
        ]

        switch type {
        case .school:
            return School(json: json)
        case .artifact:
            return Artifact(json: json)
        case .organization:
            return Organization(json: json)
        case .event:
            return Event(json: json)
        case .theme:
            return Theme(json: json)
        }
    }
}
