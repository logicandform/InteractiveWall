//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// Class that manages all non-bounding node entities for the scene.
final class EntityManager {
    static let instance = EntityManager()

    /// Set of all entities for type and proxy
    private(set) var entitiesForType: [RecordType: [RecordProxy: [RecordEntity]]] = [
        .school: [:],
        .artifact: [:],
        .organization: [:],
        .event: [:],
        .theme: [:]
    ]

    /// The scene that record nodes are added to
    var scene: MainScene!

    /// List of all GKComponentSystems. The systems will be updated in order. The order is defined to match assumptions made within components.
    private lazy var componentSystems: [GKComponentSystem] = {
        let movementSystem = GKComponentSystem(componentClass: RecordMovementComponent.self)
        let physicsSystem = GKComponentSystem(componentClass: RecordPhysicsComponent.self)
        return [movementSystem, physicsSystem]
    }()

    private struct Constants {
        static let maxRelatedLevel = 4
        static let maxEntitiesPerLevel = 30
    }


    // MARK: Init

    /// Use singleton
    private init() { }


    // MARK: API

    /// Creates and stores record entities from all records from database
    func createEntity(record: Record, levels: RelatedLevels) {
        let entity = RecordEntity(record: record, levels: levels)
        store(entity)
        addComponents(to: entity)
    }

    func entities(of type: RecordType) -> [RecordEntity] {
        let entitiesForProxy = entitiesForType[type] ?? [:]
        return entitiesForProxy.reduce([]) { $0 + $1.value }
    }

    /// If entity is a duplicate it will be removed from the scene, else resets entity.
    func release(_ entity: RecordEntity) {
        guard let entities = entitiesForType[entity.record.type]?[entity.record.proxy] else {
            return
        }

        if entities.count > 1 {
            entity.set(state: .remove)
        } else {
            if entity.record.type == .theme {
                let dx = CGFloat.random(in: style.themeDxRange)
                entity.set(state: .drift(dx: dx))
            } else {
                entity.set(state: .reset)
            }
        }
    }

    /// Removes an entity from the scene and local cache
    func remove(_ entity: RecordEntity) {
        guard entity.state == .remove, let entities = entitiesForType[entity.record.type]?[entity.record.proxy] else {
            fatalError("Entity should be marked for removal. Call")
        }

        if let index = entities.index(where: { $0 === entity }) {
            removeComponents(from: entity)
            entity.node.removeFromParent()
            entitiesForType[entity.record.type]?[entity.record.proxy]?.remove(at: index)
            scene.gestureManager.remove(entity.node)
        }
    }

    func requestEntityLevels(for entity: RecordEntity, in cluster: NodeCluster) -> EntityLevels {
        let currentEntities = flatten(cluster.entitiesForLevel).union([cluster.selectedEntity])
        var result = EntityLevels()

        // Build levels for the new entity
        for (level, records) in entity.relatedRecordsForLevel.enumerated() {
            // Prioritize entities that already exist in the cluster
            var entitiesForLevel = entities(for: records, from: currentEntities, size: Constants.maxEntitiesPerLevel)

            // Request the remaining entities up to to allowed size per level
            let remainingSpace = Constants.maxEntitiesPerLevel - entitiesForLevel.count
            let requestedProxies = records.subtracting(proxies(for: entitiesForLevel))
            let requestedEntities = requestEntities(from: requestedProxies, size: remainingSpace, for: cluster, level: level)
            entitiesForLevel.formUnion(requestedEntities)

            // Don't insert empty levels
            if entitiesForLevel.isEmpty {
                break
            }
            result.insert(entitiesForLevel, at: level)
        }

        return result
    }

    /// Returns a subset of the given entities that exist in the set of proxies up to size
    private func entities(for proxies: Set<RecordProxy>, from entities: Set<RecordEntity>, size: Int) -> Set<RecordEntity> {
        let filtered = entities.filter { proxies.contains($0.record.proxy) }
        var result = Set<RecordEntity>()
        for (index, entity) in filtered.enumerated() {
            if index < size {
                result.insert(entity)
            }
        }
        return result
    }

    func createCopy(of entity: RecordEntity, level: Int) -> RecordEntity {
        let copy = entity.clone()
        store(copy)
        addComponents(to: copy)
        copy.initialPosition = entity.initialPosition
        copy.set(position: entity.position)
        copy.node.scale(to: entity.node.size)
        let showTitle = NodeCluster.showTitleFor(level: level)
        copy.node.titleNode.alpha = showTitle ? 1 : 0
        copy.previousCluster = entity.cluster
        scene.addChild(copy.node)
        scene.addGestures(to: copy.node)
        return copy
    }

    /// Updates all component systems that the EntityManager is responsible for
    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }


    // MARK: Helpers

    /// Returns a random subset of entities associated with the given proxies up to a given size, entities in another cluster will be duplicated.
    private func requestEntities(from proxies: Set<RecordProxy>, size: Int, for cluster: NodeCluster, level: Int) -> Set<RecordEntity> {
        let shuffled = proxies.shuffled()
        let max = min(size, shuffled.count)
        var result = Set<RecordEntity>()

        for index in (0 ..< max) {
            let proxy = shuffled[index]
            if let entityForProxy = getEntity(for: proxy) {
                if proxy.type == .theme {
                    let copy = createCopy(of: entityForProxy, level: level)
                    copy.cluster = cluster
                    result.insert(copy)
                } else if let current = entityForProxy.cluster, current != cluster {
                    let copy = createCopy(of: entityForProxy, level: level)
                    copy.cluster = cluster
                    result.insert(copy)
                } else {
                    entityForProxy.cluster = cluster
                    result.insert(entityForProxy)
                }
            }
        }
        return result
    }

    private func store(_ entity: RecordEntity) {
        let proxy = entity.record.proxy
        if entitiesForType[entity.record.type]?[proxy] == nil {
            entitiesForType[entity.record.type]?[proxy] = [entity]
        } else {
            entitiesForType[entity.record.type]?[proxy]!.append(entity)
        }
    }

    /// Returns entity for given record, prioritizing records that are not already clustered
    private func getEntity(for proxy: RecordProxy) -> RecordEntity? {
        guard let entities = entitiesForType[proxy.type]?[proxy] else {
            return nil
        }

        if let unclustered = entities.first(where: { $0.cluster == nil }) {
            return unclustered
        }

        return entities.first
    }

    private func addComponents(to entity: RecordEntity) {
        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    private func removeComponents(from entity: RecordEntity) {
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: entity)
        }
    }

    private func flatten(_ levels: EntityLevels) -> Set<RecordEntity> {
        return levels.reduce(Set<RecordEntity>()) { return $0.union($1) }
    }

    private func proxies(for entities: Set<RecordEntity>) -> Set<RecordProxy> {
        let proxies = entities.map { $0.record.proxy }
        return Set(proxies)
    }
}
