//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class EntityManager {

    private(set) var entities = Set<GKEntity>()

    lazy var componentSystems: [GKComponentSystem] = {
        let agentSystem = GKComponentSystem(componentClass: RecordAgent.self)
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        return [intelligenceSystem, movementSystem, agentSystem]
    }()


    // MARK: API

    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
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
            if let renderRecord = entity.component(ofType: RenderComponent.self)?.recordNode.record, renderRecord.id == record.id {
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
}
