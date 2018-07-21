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

    private struct BitMasks {
        let categoryBitMask: UInt32
        let collisionBitMask: UInt32
        let contactTestBitMask: UInt32
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

    /// Sets the entity's bitMasks to interact with entities within its own level as well as its bounding node
    func setBitMasks(forLevel level: Int) {
        if let boundingNode = NodeBoundingManager.instance.nodeBoundingEntityForLevel[level]?.nodeBoundingRenderComponent.node,
            let boundingNodePhysicsBody = boundingNode.physicsBody {

            let levelBitMasks = bitMasks(forLevel: level)
            physicsBody.categoryBitMask = levelBitMasks.categoryBitMask | boundingNodePhysicsBody.categoryBitMask
            physicsBody.collisionBitMask = levelBitMasks.collisionBitMask | boundingNodePhysicsBody.collisionBitMask
            physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask | boundingNodePhysicsBody.contactTestBitMask
        }
    }

    /// Sets the entity's bitMask to only interact with entities within its own level
    func setLevelInteractingBitMasks(forLevel level: Int) {
        let levelBitMasks = bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask
    }

    /// Reset the entity's physics body to its initial state
    func reset() {
        // semi non-sticky collisions
        physicsBody.restitution = 0.5
        physicsBody.friction = 0.5
        physicsBody.linearDamping = 0.5

        // interactable with rest of physics world
        physicsBody.isDynamic = true

        // interactable with the repulsive radial force field
        physicsBody.fieldBitMask = 0x1 << 0

        // set bitMasks to interact with all entities
        resetBitMasks()
    }


    // MARK: Helpers

    private func setupInitialPhysicsBodyProperties() {
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0
        physicsBody.mass = NodeConfiguration.Record.physicsBodyMass
        physicsBody.fieldBitMask = 0x1 << 0
    }

    /// Returns the bitMasks for the entity's level
    private func bitMasks(forLevel level: Int) -> BitMasks {
        let categoryBitMask: UInt32 = 0x1 << level
        let collisionBitMask: UInt32 = 0x1 << level
        let contactTestBitMask: UInt32 = 0x1 << level

        return BitMasks(
            categoryBitMask: categoryBitMask,
            collisionBitMask: collisionBitMask,
            contactTestBitMask: contactTestBitMask
        )
    }

    /// Resets the entity's bitMask to be able to interact with all entities
    private func resetBitMasks() {
        physicsBody.categoryBitMask = 0xFFFFFFFF
        physicsBody.collisionBitMask = 0xFFFFFFFF
        physicsBody.contactTestBitMask = 0xFFFFFFFF
    }
}
