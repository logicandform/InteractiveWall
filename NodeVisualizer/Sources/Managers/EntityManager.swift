//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    Class that manages all non-bounding node entities for the scene.
 */

import Foundation
import SpriteKit
import GameplayKit


final class EntityManager {

    /// List of all GKComponentSystems. The systems will be updated in order. The order is defined to match assumptions made within components.
    private lazy var componentSystems: [GKComponentSystem] = {
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        let physicsSystem = GKComponentSystem(componentClass: PhysicsComponent.self)
        return [intelligenceSystem, animationSystem, movementSystem, physicsSystem]
    }()

    /// Set of all entities in the scene
    private(set) var entities = Set<GKEntity>()

    /// Dictionary of 2D array of related entities that belong to a particular level for a given record entity
    private(set) var relatedEntitiesInLevelForRecordEntity = [RecordEntity: [Set<RecordEntity>]]()

    /// 2D array of related entities that belong to a particular level
    private(set) var entitiesInLevel = [Set<RecordEntity>]()

    /// Set of all entities that currently belong to any level. Used as a cache check to make sure that all levels only contain unique entities
    private(set) var allLevelEntities = Set<RecordEntity>()

    /// Set of all entities that are currently in a formed state
    private(set) var entitiesInFormedState = Set<RecordEntity>()

    /// Local dictionary to access a record entity for its RecordDisplayable record identifier
    private var recordEntityForIdentifier = [DataManager.RecordIdentifier: RecordEntity]()

    /// Local copy of the entities that are associated with the current level
    private var entitiesInCurrentLevel = Set<RecordEntity>()

    private struct Constants {
        static let maxLevel = 5
    }


    // MARK: Singleton instance

    private init() { }
    static let instance = EntityManager()


    // MARK: API

    /// Updates all component systems that the EntityManager is responsible for
    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    /// Adds an entity to its global cache
    func add(_ entity: GKEntity) {
        entities.insert(entity)

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    /// Removes an entity from its cache
    func remove(_ entity: GKEntity) {
        entities.remove(entity)
    }

    /// Adds each entity's components to the component system to allow updates to occur
    func addToComponentSystems(for entities: [RecordEntity]) {
        for entity in entities {
            for componentSystem in componentSystems {
                componentSystem.addComponent(foundIn: entity)
            }
        }
    }

    /// Removes each entity's components from the component system so that unnecessary updates do not happen
    func removeFromComponentSystems(for entities: [RecordEntity]) {
        for entity in entities {
            for componentSystem in componentSystems {
                componentSystem.removeComponent(foundIn: entity)
            }
        }
    }

    /// Dynamically add a new component to an entity
    func add(component: GKComponent, to entity: GKEntity) {
        entity.addComponent(component)

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    /// Creates and stores record entities from all records from database
    func createRecordEntities(for records: [RecordDisplayable]) {
        for record in records {
            let identifier = DataManager.RecordIdentifier(id: record.id, type: record.type)
            let recordEntity = RecordEntity(record: record)
            add(recordEntity)
            add(recordEntity, to: identifier)
        }
    }

    /// Creates and stores levelled relationships for all entities
    func createRelationshipsForAllEntities() {
        for case let entity as RecordEntity in entities {
            // create all related entities organized into levels and store it locally for fast access
            associateRelatedEntities(for: [entity])
            relatedEntitiesInLevelForRecordEntity[entity] = entitiesInLevel

            // remove levelled related entities elements for the next entity in queue
            entitiesInLevel.removeAll()
            allLevelEntities.removeAll()
        }
    }

    /// Retrieves all related entities organized into their respective levels for a specified entity
    func levelledRelatedEntities(for entity: RecordEntity) {
//        addToComponentSystems(for: [entity])
        allLevelEntities.formUnion([entity])
        entitiesInFormedState.formUnion([entity])

        if let relatedEntitiesInLevel = relatedEntitiesInLevelForRecordEntity[entity] {
            entitiesInLevel = relatedEntitiesInLevel

            for (_, entities) in relatedEntitiesInLevel.enumerated() {
//                addToComponentSystems(for: Array(entities))
                allLevelEntities.formUnion(entities)
                entitiesInFormedState.formUnion(entities)
            }
        }
    }

    /// Removes all elements in sets associated with levelled entities
    func clearLevelEntities() {
        entitiesInLevel.removeAll()
        allLevelEntities.removeAll()
    }

    /// Resets all entities that are current formed (i.e. that are currently in their levels) to their initial state
    func resetAll() {
        let entitiesToReset = allLevelEntities.union(entitiesInFormedState)
//        removeFromComponentSystems(for: Array(entitiesToReset))

        for entity in entitiesToReset {
            entity.reset()
        }

        entitiesInFormedState.removeAll()
        clearLevelEntities()
    }


    // MARK: Helpers

    private func add(_ entity: RecordEntity, to identifier: DataManager.RecordIdentifier) {
        if recordEntityForIdentifier[identifier] == nil {
            recordEntityForIdentifier[identifier] = entity
        }
    }

    /// Organizes all related descendant entities to the appropriate hierarchial level
    private func associateRelatedEntities(for entities: Set<RecordEntity>?, toLevel level: Int = 0) {
        guard let entities = entities, !entities.isEmpty else {
            entitiesInLevel = entitiesInLevel.filter { !($0.isEmpty) }
            return
        }

        // reset the previous level entities
        entitiesInCurrentLevel.removeAll()

        // padding for 2D array
        padEntitiesForLevel(level)

        // add the new entities that are about to be related to a level to levelledEntities
        allLevelEntities.formUnion(entities)

        for entity in entities {
            // add relatedEntities to the appropriate level
            let relatedEntities = getRelatedEntities(for: entity)
            if !relatedEntities.isEmpty {
                entitiesInLevel[level].formUnion(relatedEntities)
                entitiesInCurrentLevel.formUnion(relatedEntities)
            }
        }

        // all entities that belong past the maxLevel should just go inside maxLevel (i.e. clamp to maxLevel)
        let next = (level == Constants.maxLevel) ? Constants.maxLevel : level + 1

        associateRelatedEntities(for: entitiesInCurrentLevel, toLevel: next)
    }

    private func getRelatedEntities(for entity: RecordEntity) -> [RecordEntity] {
        let record = entity.renderComponent.recordNode.record
        let identifier = DataManager.RecordIdentifier(id: record.id, type: record.type)

        guard let relatedRecords = NodeConfiguration.relatedRecords(for: identifier) else {
            return []
        }

        let relatedEntities = entities(for: relatedRecords)
        return relatedEntities
    }

    private func entities(for records: [RecordDisplayable]) -> [RecordEntity] {
        var recordEntities = [RecordEntity]()

        for record in records {
            if let entity = entity(for: record) {
                recordEntities.append(entity)
            }
        }

        return recordEntities
    }

    private func entity(for record: RecordDisplayable) -> RecordEntity? {
        let identifier = DataManager.RecordIdentifier(id: record.id, type: record.type)

        guard let recordEntity = recordEntityForIdentifier[identifier], !allLevelEntities.contains(recordEntity) else {
            return nil
        }

        return recordEntity
    }

    private func padEntitiesForLevel(_ level: Int) {
        guard entitiesInLevel.count <= level else {
            return
        }

        (entitiesInLevel.count...level).forEach { _ in
            entitiesInLevel.append([])
        }
    }
}
