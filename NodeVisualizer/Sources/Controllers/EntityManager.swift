//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class EntityManager {

    private(set) var entities = Set<GKEntity>()
    private let scene: SKScene

    lazy var componentSystems: [GKComponentSystem] = {
        let moveSystem = GKComponentSystem(componentClass: MoveComponent.self)
        let agentSystem = GKComponentSystem(componentClass: AgentComponent.self)
        return [agentSystem, moveSystem]
    }()


    init(scene: SKScene) {
        self.scene = scene
    }


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

        if let spriteComponent = entity.component(ofType: SpriteComponent.self) {
            scene.addChild(spriteComponent.recordNode)
        }
    }

    func remove(_ entity: GKEntity) {
        entities.remove(entity)

        if let spriteComponent = entity.component(ofType: SpriteComponent.self) {
            spriteComponent.recordNode.removeFromParent()
        }
    }

    func entities(for records: [RecordDisplayable]) -> [GKEntity] {
        var recordEntities = [GKEntity]()

        for record in records {
            if let entity = entity(for: record) {
                recordEntities.append(entity)
            }
        }

        return recordEntities
    }

    func entity(for record: RecordDisplayable) -> GKEntity? {
        for entity in entities {
            if let spriteRecord = entity.component(ofType: SpriteComponent.self)?.recordNode.record, spriteRecord.id == record.id {
                return entity
            }
        }

        return nil
    }



}


















