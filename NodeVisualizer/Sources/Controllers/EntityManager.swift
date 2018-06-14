//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class EntityManager {

    private(set) var entities = Set<GKEntity>()
    private let scene: SKScene

    lazy var componentSystems: [GKComponentSystem] = {
        let moveSystem = GKComponentSystem(componentClass: MoveComponent.self)
        return [moveSystem]
    }()


    init(scene: SKScene) {
        self.scene = scene
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

    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }





}


















