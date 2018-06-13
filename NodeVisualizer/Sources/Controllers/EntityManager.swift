//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class EntityManager {

    private(set) var entities = Set<GKEntity>()
    private let scene: SKScene


    init(scene: SKScene) {
        self.scene = scene
    }


    func add(_ entity: GKEntity) {
        entities.insert(entity)

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





}
