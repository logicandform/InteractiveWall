//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


final class EntityManager {

    lazy var componentSystems: [GKComponentSystem] = {
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let agentSystem = GKComponentSystem(componentClass: RecordAgent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        return [intelligenceSystem, animationSystem, movementSystem]
    }()

    private(set) var entities = Set<GKEntity>()
    private(set) var entitiesInLevel = [[RecordEntity]]()
    private var entitiesInCurrentLevel = Set<RecordEntity>()

    private struct Constants {
        static let maxLevel = 5
    }


    // MARK: API

    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    func relatedEntities(for entities: [RecordEntity]?, toLevel level: Int = 0) {
        guard let entities = entities, !entities.isEmpty else {
            return
        }

        // all entities that belong past the maxLevel should just go inside maxLevel (i.e. clamp to maxLevel)
        let next = (level == Constants.maxLevel) ? Constants.maxLevel : level + 1

        for entity in entities {
            // store entity locally for fast access check
            entitiesInCurrentLevel.insert(entity)

            // add relatedEntities to the appropriate level
            let relatedEntities = getRelatedEntities(for: entity)

            if !relatedEntities.isEmpty {
                entitiesInLevel[level] += relatedEntities
            }
        }

        relatedEntities(for: entitiesInLevel[level], toLevel: next)
    }

    func getRelatedEntities(for entity: RecordEntity) -> [RecordEntity] {
        let record = entity.renderComponent.recordNode.record

        guard let relatedRecords = TestingEnvironment.instance.relatedRecordsForRecord[record] else {
            return []
        }

        let relatedEntities = entities(for: Array(relatedRecords)).compactMap({ $0 as? RecordEntity })
        return relatedEntities
    }


    func add(_ entity: GKEntity) {
        entities.insert(entity)

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    func remove(_ entity: GKEntity) {
        entities.remove(entity)
    }

    func entities(for records: [TestingEnvironment.Record]) -> [GKEntity] {
        var recordEntities = [GKEntity]()

        for record in records {
            if let entity = entity(for: record) {
                recordEntities.append(entity)
            }
        }

        return recordEntities
    }

    func entity(for record: TestingEnvironment.Record) -> GKEntity? {
        for entity in entities {
            if let recordEntity = entity as? RecordEntity,
                !entitiesInCurrentLevel.contains(recordEntity),
                recordEntity.renderComponent.recordNode.record.id == record.id {
                return entity
            }
        }

        return nil
    }

    func add(component: GKComponent, to entity: GKEntity) {
        entity.addComponent(component)

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }


    // MARK: Helpers


}
