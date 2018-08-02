//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    Class that manages all non-bounding node entities for the scene.
 */

import Foundation
import SpriteKit
import GameplayKit


final class EntityManager {
    static let instance = EntityManager()

    /// Set of all entities
    private(set) var entities = Set<RecordEntity>()

    /// List of all GKComponentSystems. The systems will be updated in order. The order is defined to match assumptions made within components.
    private lazy var componentSystems: [GKComponentSystem] = {
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        let physicsSystem = GKComponentSystem(componentClass: PhysicsComponent.self)
        return [intelligenceSystem, animationSystem, movementSystem, physicsSystem]
    }()

    private struct Constants {
        static let maxRelatedLevel = 5
    }


    // MARK: Init

    /// Use singleton
    private init() { }


    // MARK: API

    /// Creates and stores record entities from all records from database
    func createEntity(for proxy: RecordProxy, record: RecordDisplayable?) {
        if let record = record {
            let entity = RecordEntity(record: record)
            entities.insert(entity)
            addComponents(to: entity)
        }
    }

    /// Removes an entity from its cache
    func remove(_ entity: RecordEntity) {
        entities.remove(entity)
    }

    /// Updates all component systems that the EntityManager is responsible for
    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
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
            removeComponents(from: entity)
        }
    }

    /// Dynamically add a new component to an entity
    func add(component: GKComponent, to entity: RecordEntity) {
        entity.addComponent(component)
        addComponents(to: entity)
    }

    /// Creates and stores levelled relationships for all entities
    func createEntityRelationships() {
        var relativesForEntity = [RecordEntity: Set<RecordEntity>]()

        // Create local store of direct related entities
        for entity in entities {
            let records = entity.record.relatedRecords
            var relatedEntities = Set<RecordEntity>()
            for record in records {
                if let relatedEntity = getEntity(for: record) {
                    relatedEntities.insert(relatedEntity)
                }
            }
            relativesForEntity[entity] = relatedEntities
        }

        // Populate related entities set in each RecordEntity.
        for entity in entities {
            // Fill level 0
            let relatives = relativesForEntity[entity] ?? []
            entity.relatedEntitiesForLevel.insert(relatives, at: 0)

            // Populate following levels based on the level 0 entities
            for level in (1 ... Constants.maxRelatedLevel) {
                let entitiesForPreviousLevel = entity.relatedEntitiesForLevel.at(index: level - 1) ?? []
                var entitiesForLevel = Set<RecordEntity>()
                for previousEntity in entitiesForPreviousLevel {
                    let relatedEntities = relativesForEntity[previousEntity] ?? []
                    for relatedEntity in relatedEntities {
                        if !entity.related(to: relatedEntity) && relatedEntity != entity {
                            entitiesForLevel.insert(relatedEntity)
                        }
                    }
                }
                if entitiesForLevel.isEmpty {
                    break
                }
                entity.relatedEntitiesForLevel.insert(entitiesForLevel, at: level)
            }
        }
    }


    // MARK: Helpers

    private func getEntity(for record: RecordDisplayable) -> RecordEntity? {
        return entities.first(where: { record.id == $0.record.id && record.type == $0.record.type })
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
}
