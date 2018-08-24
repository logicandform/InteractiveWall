//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


struct ColliderType {
    static let panBoundingNode: UInt32 = 1 << 20
    static let clonedRecordNode: UInt32 = 1 << 21

    let categoryBitMask: UInt32
    let collisionBitMask: UInt32
    let contactTestBitMask: UInt32
}


/// A `GKComponent` that provides an `SKPhysicsBody` for an entity. This enables the entity to be represented in the SpriteKit physics world.
class PhysicsComponent: GKComponent {

    private(set) var physicsBody: SKPhysicsBody


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

        guard let entity = entity as? RecordEntity,
            !entity.hasCollidedWithBoundingNode,
            let cluster = entity.cluster,
            cluster.selectedEntity.state != .panning else {
            return
        }

        // Check if the contactedBodies belong to the same level, the same cluster, and the same bounding node
        let contactedBodies = physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            if let boundingNode = contactedBody.node, boundingNode.name == "boundingNode",
                let currentLevel = entity.clusterLevel.currentLevel,
                cluster.layerForLevel[currentLevel]?.nodeBoundingRenderComponent.node === boundingNode,
                !entity.hasCollidedWithBoundingNode {
                entity.hasCollidedWithBoundingNode = true
                return
            } else if let contactedEntity = contactedBody.node?.entity as? RecordEntity,
                let contactedEntityCluster = contactedEntity.cluster, cluster === contactedEntityCluster,
                contactedEntity.hasCollidedWithBoundingNode, !entity.hasCollidedWithBoundingNode {
                entity.hasCollidedWithBoundingNode = true
                return
            }
        }
    }


    // MARK: API

    func updateBitMasks() {
        guard let entity = entity as? RecordEntity,
            let cluster = entity.cluster,
            entity.previousCluster == nil else {
            return
        }

        if cluster.selectedEntity.state == .panning {
            setPanningBitMasks()
        } else {
            switch entity.state {
            case .seekLevel(let level):
                setSeekingLevelBitMasks(forLevel: level)
            case .seekEntity(_):
                setSeekingEntityBitMasks()
            default:
                return
            }
        }
    }

    /// Sets the cloned entity's bitMasks
    func setClonedNodeBitMasks() {
        physicsBody.categoryBitMask = ColliderType.clonedRecordNode
        physicsBody.collisionBitMask = ColliderType.clonedRecordNode
        physicsBody.contactTestBitMask = ColliderType.clonedRecordNode
    }

    /// Reset the entity's physics body to its initial state
    func reset() {
        // semi non-sticky collisions
        physicsBody.restitution = 0.5
        physicsBody.friction = 0.5
        physicsBody.linearDamping = 0.5

        // interactable with rest of physics world
        physicsBody.isDynamic = true

        // set bitMasks to interact with all entities
        resetBitMasks()
    }


    // MARK: Helpers

    private func setupInitialPhysicsBodyProperties() {
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0
        physicsBody.mass = style.nodePhysicsBodyMass
    }

    private func setPanningBitMasks() {
        guard let entity = entity as? RecordEntity,
            let level = entity.clusterLevel.currentLevel,
            let cluster = entity.cluster,
            let panBoundingPhysicsBody = cluster.layerForLevel[0]?.nodeBoundingRenderComponent.node?.physicsBody else {
            return
        }

        let levelBitMasks = bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask | panBoundingPhysicsBody.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask | panBoundingPhysicsBody.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask | panBoundingPhysicsBody.contactTestBitMask
    }

    private func setSeekingLevelBitMasks(forLevel level: Int) {
        let levelBitMasks = bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask
    }

    private func setSeekingEntityBitMasks() {
        guard let entity = entity as? RecordEntity,
            let level = entity.clusterLevel.currentLevel,
            let boundingNode = entity.cluster?.layerForLevel[level]?.nodeBoundingRenderComponent.node,
            let boundingNodePhysicsBody = boundingNode.physicsBody else {
            return
        }

        let levelBitMasks = bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask | boundingNodePhysicsBody.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask | boundingNodePhysicsBody.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask | boundingNodePhysicsBody.contactTestBitMask
    }

    /// Returns the bitMasks for the entity's level
    private func bitMasks(forLevel level: Int) -> ColliderType {
        let categoryBitMask: UInt32 = 1 << level
        let collisionBitMask: UInt32 = 1 << level
        let contactTestBitMask: UInt32 = 1 << level

        return ColliderType(
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
