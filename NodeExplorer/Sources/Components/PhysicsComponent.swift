//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A `GKComponent` that provides an `SKPhysicsBody` for an entity. This enables the entity to be represented in the SpriteKit physics world.
class PhysicsComponent: GKComponent {

    private(set) var physicsBody: SKPhysicsBody


    // MARK: Initializer

    init(physicsBody: SKPhysicsBody) {
        self.physicsBody = physicsBody
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        guard let entity = entity as? RecordEntity, !entity.hasCollidedWithLayer, let level = entity.clusterLevel.currentLevel, let cluster = entity.cluster, cluster.selectedEntity.state != .dragging else {
            return
        }

        let contactedBodies = physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            if let layerNode = contactedBody.node as? ClusterLayerNode, layerNode.level == level {
                entity.hasCollidedWithLayer = true
                return
            } else if let siblingNode = contactedBody.node as? RecordNode, let siblingEntity = siblingNode.entity as? RecordEntity, siblingEntity.clusterLevel.currentLevel == level, siblingEntity.hasCollidedWithLayer {
                entity.hasCollidedWithLayer = true
                return
            }
        }
    }
}
