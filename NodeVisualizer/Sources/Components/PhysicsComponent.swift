//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A `GKComponent` that provides an `SKPhysicsBody` for an entity. This enables the entity to be represented in the SpriteKit physics world.
*/

import Foundation
import SpriteKit
import GameplayKit


class PhysicsComponent: GKComponent {

    private(set) var physicsBody: SKPhysicsBody

    private var recordEntity: RecordEntity {
        guard let recordEntity = entity as? RecordEntity else {
            fatalError("A PhysicsComponent's entity must be a RecordEntity")
        }
        return recordEntity
    }

    private var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("A PhysicsComponent's entity must have a RenderComponent")
        }
        return renderComponent
    }

    private struct Constants {
        static let resetBitMask: UInt32 = 0x1 << 0
    }


    // MARK: Initializer
    
    init(physicsBody: SKPhysicsBody) {
        self.physicsBody = physicsBody
        super.init()
        setupInitialPhysicsBodyProperties()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        let contactedBodies = physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let contactedEntity = contactedBody.node?.entity as? RecordEntity else {
                continue
            }

            if contactedEntity.hasCollidedWithBoundingNode && !recordEntity.hasCollidedWithBoundingNode {
                recordEntity.hasCollidedWithBoundingNode = true
                return
            }
        }
    }


    // MARK: API

    func setBitMasks(forLevel level: Int) {
        if let boundingNode = NodeBoundingManager.instance.nodeBoundingEntityForLevel[level]?.nodeBoundingRenderComponent.node,
            let boundingNodePhysicsBody = boundingNode.physicsBody {
            physicsBody.categoryBitMask = boundingNodePhysicsBody.categoryBitMask
            physicsBody.collisionBitMask = boundingNodePhysicsBody.collisionBitMask
            physicsBody.contactTestBitMask = boundingNodePhysicsBody.contactTestBitMask
        }
    }

    func setAvoidanceProperties() {
        physicsBody.categoryBitMask = 0x1 << 30
        physicsBody.collisionBitMask = 0x1 << 30
        physicsBody.contactTestBitMask = 0x1 << 30
        physicsBody.isDynamic = true
    }


    // MARK: Helpers

    private func setupInitialPhysicsBodyProperties() {
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0
        physicsBody.mass = NodeConfiguration.Record.physicsBodyMass
        physicsBody.fieldBitMask = 0x1 << 0
    }
}
