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

    var scene: MainScene?

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
    func createEntity(record: RecordDisplayable, levels: RelatedLevels) {
        let entity = RecordEntity(record: record, levels: levels)
        entities.insert(entity)
        addComponents(to: entity)
    }

    /// Removes an entity from its cache
    func remove(_ entity: RecordEntity) {
        entities.remove(entity)
    }

    /// Returns the entities associated with the given proxies, if a entity is already with another cluster, the entity will be duplicated
    func requestEntities(with proxies: Set<RecordProxy>, for cluster: NodeCluster) -> Set<RecordEntity> {
        var result = Set<RecordEntity>()
        for proxy in proxies {
            if let entityForProxy = getEntity(for: proxy) {
                // If entity for proxy already has a different cluster, duplicate the entity at the same position
                if let current = entityForProxy.cluster, current != cluster {
                    let copy = entityForProxy.clone()
                    entities.insert(copy)
                    addComponents(to: copy)
                    copy.renderComponent.recordNode.position = entityForProxy.renderComponent.recordNode.position
                    scene?.addChild(copy.renderComponent.recordNode)
                    result.insert(copy)
                } else {
                    result.insert(entityForProxy)
                }
            }
        }
        return result
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


    // MARK: Helpers

    /// Returns entity for given record, prioritizing records that are not already clustered
    private func getEntity(for proxy: RecordProxy) -> RecordEntity? {
        let unclustered = entities.filter { $0.cluster == nil }
        if let match = unclustered.first(where: { proxy == $0.record.proxy }) {
            return match
        }
        return entities.first(where: { proxy == $0.record.proxy })
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
